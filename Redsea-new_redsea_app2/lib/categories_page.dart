import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/experiences/experiences_page.dart';
import 'package:redsea/notifications_page.dart';
import 'package:redsea/search/search_page.dart' as new_search;
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/basket_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/search_results_page.dart';

class CategoriesPage extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesPage({super.key, required this.onCategorySelected});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref().child('products');

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  // التصنيفات السريعة للشريط الأفقي
  final List<Map<String, dynamic>> _quickCategories = [
    {'name': 'خبرات', 'icon': Icons.psychology},
    {'name': 'سيارات', 'icon': Icons.directions_car},
    {'name': 'موبايلات', 'icon': Icons.phone_android},
    {'name': 'عقارات', 'icon': Icons.home},
    {'name': 'خدمات', 'icon': Icons.build},
    {'name': 'وظائف', 'icon': Icons.work},
  ];

  // التصنيفات الرئيسية
  final List<Map<String, dynamic>> _mainCategories = [
    {'name': 'خبرات', 'icon': Icons.psychology, 'image': null},
    {'name': 'الكترونيات', 'icon': Icons.computer, 'image': null},
    {'name': 'سيارات', 'icon': Icons.directions_car, 'image': null},
    {'name': 'عقارات', 'icon': Icons.home, 'image': null},
    {'name': 'أجهزة منزلية', 'icon': Icons.kitchen, 'image': null},
    {'name': 'ملابس', 'icon': Icons.checkroom, 'image': null},
    {'name': 'أثاث', 'icon': Icons.chair, 'image': null},
    {'name': 'خدمات', 'icon': Icons.design_services, 'image': null},
    {'name': 'وظائف', 'icon': Icons.work, 'image': null},
    {'name': 'ساعات', 'icon': Icons.watch, 'image': null},
    {'name': 'عطور', 'icon': Icons.spa, 'image': null},
    {'name': 'منزل وحديقة', 'icon': Icons.yard, 'image': null},
  ];

  Map<String, int> categoryProductCounts = {};
  List<Product> suggestedProducts = [];
  bool _isLoadingProducts = false;

  late FavoritesController favoritesController;
  late NotificationsController notificationsController;
  late CartController cartController;

  @override
  void initState() {
    super.initState();
    favoritesController = Get.find<FavoritesController>();
    notificationsController = Get.find<NotificationsController>();
    cartController = Get.find<CartController>();
    _loadCategoryCounts();
    _loadSuggestedProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection
        .toString()
        .contains('reverse')) {
      if (_showFab) setState(() => _showFab = false);
    } else {
      if (!_showFab) setState(() => _showFab = true);
    }
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final snapshot = await _productsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        Map<String, int> counts = {};

        for (var category in _mainCategories) {
          counts[category['name']] = 0;
        }

        data.forEach((key, value) {
          final productData = Map<String, dynamic>.from(value);
          final category = productData['category'] ?? 'أخرى';
          counts[category] = (counts[category] ?? 0) + 1;
        });

        if (mounted) {
          setState(() {
            categoryProductCounts = counts;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading category counts: $e');
    }
  }

  Future<void> _loadSuggestedProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final snapshot = await _productsRef.limitToLast(10).once();
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        List<Product> products = [];

        data.forEach((key, value) {
          try {
            final productData = Map<String, dynamic>.from(value);
            products.add(Product.fromMap(productData));
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        });

        if (mounted) {
          setState(() {
            suggestedProducts = products.reversed.toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading suggested products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header مخصص
          SliverToBoxAdapter(
            child: Obx(() => CustomMarketplaceHeader(
                  showBackButton: false,
                  searchHint: 'ابحث في الفئات...',
                  notificationCount: notificationsController.unreadCount.value,
                  favoriteCount: favoritesController.favorites.length,
                  cartCount: cartController.totalItems,
                  onSearchTap: () =>
                      Get.to(() => const new_search.SearchPage()),
                  onBackTap: () => Get.back(),
                  onNotificationTap: () {
                    final authController = Get.find<AuthController>();
                    if (!authController.requireLogin(
                        message: 'سجّل دخولك لعرض الإشعارات')) return;
                    Get.to(() => NotificationPage());
                  },
                  onFavoriteTap: () {
                    final authController = Get.find<AuthController>();
                    if (!authController.requireLogin(
                        message: 'سجّل دخولك لعرض المفضلة')) return;
                    Get.to(() => FavoritesPage());
                  },
                  onCartTap: () {
                    final authController = Get.find<AuthController>();
                    if (!authController.requireLogin(
                        message: 'سجّل دخولك لعرض السلة')) return;
                    Get.to(() => BasketPage(
                        cartItems: cartController.cartItems.toList()));
                  },
                )),
          ),

          // شريط التصنيفات السريعة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildQuickCategoriesBar(),
            ),
          ),

          // عنوان الأقسام
          SliverToBoxAdapter(
            child: _buildSectionHeader('الأقسام', onMoreTap: () {}),
          ),

          // شبكة الأقسام الرئيسية
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCategoryCard(_mainCategories[index]),
                childCount: _mainCategories.length,
              ),
            ),
          ),

          // قسم الإعلانات المقترحة
          SliverToBoxAdapter(
            child: _buildSectionHeader('إعلانات مقترحة', onMoreTap: () {}),
          ),

          // قائمة المنتجات المقترحة
          SliverToBoxAdapter(
            child: _buildSuggestedProducts(),
          ),

          // مساحة فارغة للـ FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// شريط التصنيفات السريعة
  Widget _buildQuickCategoriesBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _quickCategories.length,
          itemBuilder: (context, index) {
            final category = _quickCategories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  // معالجة خاصة لقسم الخبرات
                  if (category['name'] == 'خبرات') {
                    Get.to(() => const ExperiencesPage());
                  } else {
                    final filterController = Get.find<FilterController>();
                    filterController.setCategory(category['name']);
                    filterController.applyFilters();
                    Get.to(() => const SearchResultsPage());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(category['icon'],
                          size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionHeader(String title, {VoidCallback? onMoreTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onMoreTap,
            child: Row(
              children: [
                Text(
                  'المزيد',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_back_ios,
                    size: 14, color: Colors.blue.shade600),
              ],
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الفئة
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final productCount = categoryProductCounts[category['name']] ?? 0;

    return GestureDetector(
      onTap: () {
        // معالجة خاصة لقسم الخبرات
        if (category['name'] == 'خبرات') {
          Get.to(() => const ExperiencesPage());
        } else {
          final filterController = Get.find<FilterController>();
          filterController.setCategory(category['name']);
          filterController.applyFilters();
          Get.to(() => const SearchResultsPage());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الأيقونة
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 28,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 10),
            // اسم الفئة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category['name'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // عدد المنتجات
            if (productCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$productCount',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// قائمة المنتجات المقترحة
  Widget _buildSuggestedProducts() {
    if (_isLoadingProducts) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Colors.blue.shade600),
        ),
      );
    }

    if (suggestedProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'لا توجد إعلانات حالياً',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 330,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestedProducts.length,
        itemBuilder: (context, index) {
          final product = suggestedProducts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 175,
              child: MarketplaceProductCard(
                product: product,
                onTap: () {
                  final authController = Get.find<AuthController>();
                  if (!authController.requireLogin(
                      message: 'سجّل دخولك لعرض التفاصيل')) {
                    return;
                  }
                  final cartController = Get.find<CartController>();
                  Get.to(() => ProductDetailsPage(
                        product: product,
                        cartItems: cartController.cartItems.toList(),
                        onAddToCart: (p) => cartController.addToCart(p),
                        onRemoveFromCart: (id) =>
                            cartController.removeFromCart(id),
                        onUpdateQuantity: (id, qty) =>
                            cartController.updateQuantity(id, qty),
                      ));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
