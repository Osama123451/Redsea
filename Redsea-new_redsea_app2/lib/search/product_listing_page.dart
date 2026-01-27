import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:redsea/search/search_page.dart' as new_search;

import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/swap_selection_page.dart';

/// صفحة عرض المنتجات بشكل شبكي
class ProductListingPage extends StatefulWidget {
  final String title;
  final String? searchQuery;
  final String? category;

  const ProductListingPage({
    super.key,
    required this.title,
    this.searchQuery,
    this.category,
  });

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  late ProductController productController;
  late CartController cartController;
  late FavoritesController favoritesController;
  late NotificationsController notificationsController;
  String _sortBy = 'newest';

  // 0: Grid, 1: List (Full), 2: Compact
  int _viewMode = 0;

  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    productController = Get.find<ProductController>();
    cartController = Get.find<CartController>();
    favoritesController = Get.find<FavoritesController>();
    notificationsController = Get.find<NotificationsController>();

    // تطبيق الفلاتر
    _applyInitialFilters();
  }

  void _applyInitialFilters() {
    final filterController = Get.find<FilterController>();

    if (widget.searchQuery != null) {
      filterController.setSearchQuery(widget.searchQuery!);
    }
    if (widget.category != null) {
      filterController.setCategory(widget.category!);
    }

    filterController.applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من وجود FilterController
    final filterController = Get.find<FilterController>();

    // إذا لم يكن هناك بحث نشط، نقوم بتحديث الفلتر بالبيانات الأولية
    if (filterController.searchQuery.value.isEmpty &&
        widget.searchQuery != null) {
      filterController.setSearchQuery(widget.searchQuery!);
      filterController.applyFilters();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Obx(() => CustomMarketplaceHeader(
                  title: '', // Moved to sort bar
                  showBackButton: true,
                  searchHint: 'ابحث في ${widget.title}...',
                  notificationCount: notificationsController.unreadCount.value,
                  favoriteCount: favoritesController.favorites.length,
                  cartCount: cartController.totalItems,
                  onSearchTap: () =>
                      Get.to(() => const new_search.SearchPage()),
                  onBackTap: () => Get.back(),
                  bottom: _buildListingControls(),
                )),
            // شبكة المنتجات
            Expanded(
              child: _buildProductsGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingControls() {
    IconData viewIcon;
    switch (_viewMode) {
      case 0:
        viewIcon = Icons.grid_view;
        break;
      case 1:
        viewIcon = Icons.view_list;
        break;
      case 2:
        viewIcon = Icons.view_headline;
        break;
      default:
        viewIcon = Icons.grid_view;
    }

    return Row(
      children: [
        IconButton(
          icon: Icon(viewIcon, color: Colors.white),
          onPressed: () {
            setState(() {
              _viewMode = (_viewMode + 1) % 3;
            });
          },
          tooltip: 'تغيير العرض',
        ),

        // العنوان (نتائج البحث)
        if (widget.title.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Result Count
                GetX<FilterController>(
                  builder: (controller) => Text(
                    '(${controller.filteredResults.length})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),
        _buildSortBarContent(),
      ],
    );
  }

  Widget _buildSortBarContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isDense: true,
          dropdownColor: AppColors.primary,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
            DropdownMenuItem(
                value: 'price_low', child: Text('السعر: من الأقل')),
            DropdownMenuItem(
                value: 'price_high', child: Text('السعر: من الأعلى')),
            DropdownMenuItem(value: 'popular', child: Text('الأكثر شعبية')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _sortBy = value);
              _sortProducts(value);
            }
          },
        ),
      ),
    );
  }

  void _sortProducts(String sortBy) {
    // الفرز المحلي
    productController.filteredProducts.sort((a, b) {
      switch (sortBy) {
        case 'price_low':
          return a.priceAsDouble.compareTo(b.priceAsDouble);
        case 'price_high':
          return b.priceAsDouble.compareTo(a.priceAsDouble);
        case 'popular':
          return 0; // يمكن إضافة حساب الشعبية لاحقاً
        default: // newest
          return b.dateAdded.compareTo(a.dateAdded);
      }
    });
    productController.update();
  }

  Widget _buildProductsGrid() {
    return GetX<FilterController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.filteredResults.isEmpty) {
          return _buildEmptyState();
        }

        if (_viewMode == 0) {
          // Grid View
          return GridView.builder(
            padding: const EdgeInsets.all(10), // Light margin
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.52,
              crossAxisSpacing: 10, // Light gap
              mainAxisSpacing: 10, // Light gap
            ),
            itemCount: controller.filteredResults.length,
            itemBuilder: (context, index) {
              return _buildProductCard(controller.filteredResults[index]);
            },
          );
        } else if (_viewMode == 1) {
          // List View (Full Cards)
          return ListView.builder(
            padding: const EdgeInsets.all(10), // Light margin
            itemCount: controller.filteredResults.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10), // Light gap
                child: _buildProductCard(controller.filteredResults[index]),
              );
            },
          );
        } else {
          // Compact List View
          return ListView.builder(
            padding: const EdgeInsets.all(10), // Light margin
            itemCount: controller.filteredResults.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8), // Light gap
                child:
                    _buildCompactProductCard(controller.filteredResults[index]),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير معايير البحث',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return MarketplaceProductCard(
      product: product,
      showBarter: product.isSwappable,
      onTap: () => _navigateToDetails(product),
      onAddToCart: () {
        cartController.addToCart(product);
        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة ${product.name} إلى السلة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onChatTap: () => _chatWithSeller(product),
      onBarterTap: () {
        final auth = Get.find<AuthController>();
        if (auth.requireLogin(message: 'سجّل دخولك للمقايضة')) {
          Get.to(() => SwapSelectionPage(targetProduct: product));
        }
      },
    );
  }

  // --- COMPACT VIEW CARD ---
  Widget _buildCompactProductCard(Product product) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(product),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Builder(builder: (context) {
                        if (product.imageUrl.isEmpty) {
                          return Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image, color: Colors.grey));
                        }
                        return Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      }),
                    ),
                    if (product.isSwappable)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle),
                          child: const Icon(Icons.swap_horiz,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Title & Options
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        // Favorite Icon Small
                        GetBuilder<FavoritesController>(builder: (c) {
                          final isFav = c.isFavorite(product.id);
                          return InkWell(
                            onTap: () => c.toggleFavorite(product),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFav ? Colors.red : Colors.grey,
                            ),
                          );
                        }),
                      ],
                    ),

                    // Middle: Location & Condition
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 60),
                          child: Text(
                            product.location ?? 'اليمن',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        if (product.conditionText != 'غير محدد')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(product.conditionText,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54)),
                          ),
                      ],
                    ),

                    // Bottom: Price & Quick Actions
                    Row(
                      children: [
                        Text(
                          '${product.price} ر.ي',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const Spacer(),
                        // Swap Button (if swappable)
                        if (product.isSwappable) ...[
                          InkWell(
                            onTap: () {
                              final auth = Get.find<AuthController>();
                              if (auth.requireLogin(
                                  message: 'سجّل دخولك للمقايضة')) {
                                Get.to(() =>
                                    SwapSelectionPage(targetProduct: product));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Icons.swap_horiz,
                                  size: 20, color: Colors.green.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Chat Button
                        InkWell(
                          onTap: () => _chatWithSeller(product),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.chat_bubble_outline,
                                size: 18, color: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to Cart Button
                        InkWell(
                          onTap: () {
                            cartController.addToCart(product);
                            Get.snackbar('تم', 'أضيف للسلة',
                                duration: const Duration(seconds: 1),
                                snackPosition: SnackPosition.BOTTOM);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.add_shopping_cart,
                                size: 18, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(Product product) {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لعرض التفاصيل')) return;

    Get.to(() => ProductDetailsPage(
          product: product,
          cartItems: cartController.cartItems.toList(),
          onAddToCart: (p) => cartController.addToCart(p),
          onRemoveFromCart: (id) => cartController.removeFromCart(id),
          onUpdateQuantity: (id, qty) => cartController.updateQuantity(id, qty),
        ));
  }

  void _chatWithSeller(Product product) async {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك للدردشة')) return;

    // الحصول على معرّف البائع من المنتج
    final sellerId = product.ownerId ?? '';
    final sellerName = 'البائع'; // يمكن جلب الاسم لاحقاً

    if (sellerId.isEmpty) {
      Get.snackbar('تنبيه', 'لا يمكن بدء المحادثة');
      return;
    }

    // إنشاء أو جلب المحادثة
    try {
      final chatId = await _chatService.createOrGetChat(sellerId, product.id);

      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: sellerId,
            otherUserName: sellerName,
          ));
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في بدء المحادثة');
    }
  }
}
