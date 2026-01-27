import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/advanced_filter_page.dart';
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/search/search_page.dart' as new_search;

/// صفحة نتائج البحث والفلترة
/// تعرض المنتجات في شكل Grid مع أزرار التواصل
class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late FilterController filterController;
  late CartController cartController;
  late FavoritesController favoritesController;
  late NotificationsController notificationsController;

  @override
  void initState() {
    super.initState();
    filterController = Get.find<FilterController>();
    cartController = Get.find<CartController>();
    favoritesController = Get.find<FavoritesController>();
    notificationsController = Get.find<NotificationsController>();
  }

  void _openProductDetails(Product product) {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(
        message: 'سجّل دخولك لعرض تفاصيل المنتج')) {
      return;
    }
    Get.to(() => ProductDetailsPage(
          product: product,
          cartItems: cartController.cartItems.toList(),
          onAddToCart: (p) => cartController.addToCart(p),
          onRemoveFromCart: (id) => cartController.removeFromCart(id),
          onUpdateQuantity: (id, qty) => cartController.updateQuantity(id, qty),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Obx(() => CustomMarketplaceHeader(
                title: 'نتائج البحث',
                showBackButton: true,
                searchHint: 'تعديل البحث...',
                notificationCount:
                    Get.find<NotificationsController>().unreadCount.value,
                favoriteCount: favoritesController.favorites.length,
                cartCount: cartController.totalItems,
                onSearchTap: () => Get.off(() => const new_search.SearchPage()),
                onBackTap: () => Get.back(),
              )),
          _buildCategoryHeader(),
          _buildFiltersRow(),
          _buildSubCategoriesRow(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                filterController.setSearchQuery('');
                filterController.applyFilters();
              },
              child: Obx(() {
                if (filterController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filterController.filteredResults.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildResultsGrid();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(() => Text(
                '(${filterController.filteredResults.length}) ${filterController.selectedCategory.value}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: Colors.grey),
            onPressed: () => Get.to(() => const AdvancedFilterPage()),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard_arrow_down, size: 18),
                const SizedBox(width: 4),
                Obx(() => Text(
                      filterController.selectedCity.value.isEmpty
                          ? 'كل المدن'
                          : filterController.selectedCity.value,
                      style: const TextStyle(fontSize: 13),
                    )),
                const SizedBox(width: 4),
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesRow() {
    final subCats = _getSubCategories(filterController.selectedCategory.value);

    if (subCats.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subCats.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              filterController.setSearchQuery(subCats[index]);
              filterController.applyFilters();
            },
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                subCats[index],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getSubCategories(String mainCat) {
    switch (mainCat) {
      case 'الكترونيات':
      case 'الالكترونيات':
        return [
          'موبايل',
          'تابلت',
          'لابتوب',
          'ساعات ذكية',
          'سماعات',
          'كاميرات',
          'ألعاب فيديو'
        ];
      case 'سيارات':
      case 'سيارات ومركبات':
        return [
          'سيارات للبيع',
          'قطع غيار',
          'دراجات نارية',
          'شاحنات',
          'لوحات مميزة'
        ];
      case 'أجهزة منزلية':
        return ['ثلاجات', 'غسالات', 'أفران', 'مكيفات', 'مكانس كهربائية'];
      case 'ملابس':
        return ['رجالي', 'نسائي', 'أطفال', 'أحذية', 'حقائب'];
      case 'عقارات':
        return ['شقق للبيع', 'اراضي', 'بيوت', 'ايجار', 'تجاري'];
      default:
        return ['الكل', 'مستعمل', 'جديد', 'بضمان'];
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرّب تعديل خيارات الفلترة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const AdvancedFilterPage()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.tune),
            label: const Text('تعديل الفلترة'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.50,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filterController.filteredResults.length,
      itemBuilder: (context, index) {
        return _buildProductCard(filterController.filteredResults[index]);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return MarketplaceProductCard(
      product: product,
      onTap: () => _openProductDetails(product),
      onAddToCart: () {
        final cartController = Get.find<CartController>();
        cartController.addToCart(product);
        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة ${product.name} إلى السلة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onBarterTap: () => _openProductDetails(product),
      onChatTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(message: 'سجّل دخولك للدردشة')) return;
        Get.toNamed(AppRoutes.chat,
            arguments: {'peerId': product.ownerId, 'product': product});
      },
    );
  }
}
