import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/search_results_page.dart';
import 'package:redsea/search_page.dart';
import 'package:redsea/experiences/experiences_page.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/app/controllers/product_controller.dart';

/// صفحة الرؤى والاستكشاف - Insights Page
class InsightsPage extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const InsightsPage({super.key, this.onCategorySelected});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref().child('products');

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _featuresController =
      PageController(viewportFraction: 0.85);

  int _currentFeaturePage = 0;
  bool _isLoading = false;

  // التصنيفات الرئيسية (مع استبدال خدمات بـ منتجات للمقايضة)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'خبرات', 'icon': Icons.psychology, 'color': Colors.purple},
    {
      'name': 'منتجات للمقايضة',
      'icon': Icons.swap_horiz,
      'color': Colors.orange
    },
    {'name': 'سيارات', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': 'عقارات', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'إلكترونيات', 'icon': Icons.computer, 'color': Colors.indigo},
    {'name': 'ملابس', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'أثاث', 'icon': Icons.chair, 'color': Colors.brown},
    {'name': 'وظائف', 'icon': Icons.work, 'color': Colors.teal},
  ];

  // المميزات
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'المقايضة الذكية',
      'subtitle': 'بادل منتجاتك بما تريد',
      'icon': Icons.swap_calls,
      'gradient': [Colors.orange.shade600, Colors.deepOrange.shade400],
    },
    {
      'title': 'تبادل الخبرات',
      'subtitle': 'شارك معرفتك واستفد من خبرات الآخرين',
      'icon': Icons.psychology,
      'gradient': [Colors.purple.shade600, Colors.purple.shade400],
    },
    {
      'title': 'تسوق آمن',
      'subtitle': 'دفع مضمون وتوصيل سريع',
      'icon': Icons.security,
      'gradient': [Colors.green.shade600, Colors.green.shade400],
    },
  ];

  // البيانات
  List<Product> barterProducts = [];
  List<Product> latestProducts = [];
  Map<String, dynamic> experiencesData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // تحميل منتجات المقايضة
      final productController = Get.find<ProductController>();
      barterProducts =
          productController.products.where((p) => p.negotiable).toList();

      // تحميل أحدث المنتجات
      final snapshot = await _productsRef.limitToLast(10).get();
      if (snapshot.exists) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        List<Product> products = [];

        data.forEach((key, value) {
          try {
            final productData = Map<String, dynamic>.from(value);
            products.add(Product.fromMap(productData));
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        });

        latestProducts = products.reversed.toList();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // شريط البحث
            SliverToBoxAdapter(child: _buildSearchBar()),

            // بطاقات المميزات
            SliverToBoxAdapter(child: _buildFeaturesSlider()),

            // التصنيفات
            SliverToBoxAdapter(
              child: _buildSectionHeader('التصنيفات', onMoreTap: () {}),
            ),
            SliverToBoxAdapter(child: _buildCategoriesGrid()),

            // منتجات للمقايضة
            SliverToBoxAdapter(
              child: _buildSectionHeader('منتجات للمقايضة', onMoreTap: () {
                Get.to(() => const SearchResultsPage());
              }),
            ),
            SliverToBoxAdapter(child: _buildBarterProductsList()),

            // تبادل الخبرات
            SliverToBoxAdapter(
              child: _buildSectionHeader('تبادل الخبرات', onMoreTap: () {
                Get.to(() => const ExperiencesPage());
              }),
            ),
            SliverToBoxAdapter(child: _buildExperiencesList()),

            // أحدث المنتجات
            SliverToBoxAdapter(
              child: _buildSectionHeader('أحدث المنتجات', onMoreTap: () {
                Get.to(() => const SearchResultsPage());
              }),
            ),
            SliverToBoxAdapter(child: _buildLatestProductsList()),

            // مساحة فارغة
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  /// شريط البحث
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
      color: Colors.white,
      child: GestureDetector(
        onTap: () => Get.to(() => const SearchPage()),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.tune, color: Colors.grey.shade500, size: 20),
              Expanded(
                child: Text(
                  'ابحث عن منتجات...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  textAlign: TextAlign.right,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child:
                    Icon(Icons.search, color: Colors.grey.shade500, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقات المميزات
  Widget _buildFeaturesSlider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _featuresController,
              onPageChanged: (index) {
                setState(() => _currentFeaturePage = index);
              },
              itemCount: (_features.length / 2).ceil(),
              itemBuilder: (context, pageIndex) {
                return Row(
                  children: [
                    for (int i = 0; i < 2; i++)
                      if (pageIndex * 2 + i < _features.length)
                        Expanded(
                          child:
                              _buildFeatureCard(_features[pageIndex * 2 + i]),
                        ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              (_features.length / 2).ceil(),
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentFeaturePage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentFeaturePage == index
                      ? Colors.blue.shade600
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: feature['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature['icon'] as IconData, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              feature['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(
              feature['subtitle'] as String,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
            ),
          ],
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

  /// شبكة التصنيفات
  Widget _buildCategoriesGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () => _onCategoryTap(category['name']),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          (category['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCategoryTap(String categoryName) {
    if (categoryName == 'خبرات') {
      Get.to(() => const ExperiencesPage());
    } else if (categoryName == 'منتجات للمقايضة') {
      Get.to(() => const SearchResultsPage());
    } else {
      final filterController = Get.find<FilterController>();
      filterController.setCategory(categoryName);
      filterController.applyFilters();
      Get.to(() => const SearchResultsPage());
    }
    widget.onCategorySelected?.call(categoryName);
  }

  /// قائمة منتجات المقايضة
  Widget _buildBarterProductsList() {
    if (barterProducts.isEmpty) {
      return _buildEmptySection('لا توجد منتجات للمقايضة');
    }
    return _buildHorizontalProductList(barterProducts, showSwapBadge: true);
  }

  /// قائمة تبادل الخبرات
  Widget _buildExperiencesList() {
    final expController = Get.find<ExperiencesController>();
    final experiences = expController.allExperiences.take(5).toList();

    if (experiences.isEmpty) {
      return _buildEmptySection('لا توجد خبرات للمشاركة حالياً');
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: experiences.length,
        itemBuilder: (context, index) {
          final exp = experiences[index];
          return GestureDetector(
            onTap: () => Get.to(() => const ExperiencesPage()),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: exp.imageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(exp.imageUrl,
                                  fit: BoxFit.cover, width: 40, height: 40))
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      exp.expertName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      exp.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          exp.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// قائمة أحدث المنتجات
  Widget _buildLatestProductsList() {
    if (latestProducts.isEmpty) {
      return _buildEmptySection('لا توجد منتجات حديثة');
    }
    return _buildHorizontalProductList(latestProducts);
  }

  /// قائمة منتجات أفقية
  Widget _buildHorizontalProductList(
    List<Product> products, {
    bool showSwapBadge = false,
    bool showOfferBadge = false,
  }) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(
            products[index],
            showSwapBadge: showSwapBadge,
            showOfferBadge: showOfferBadge,
          );
        },
      ),
    );
  }

  /// بطاقة المنتج
  Widget _buildProductCard(
    Product product, {
    bool showSwapBadge = false,
    bool showOfferBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(message: 'سجّل دخولك لعرض التفاصيل')) {
          return;
        }
        final cartController = Get.find<CartController>();
        Get.to(() => ProductDetailsPage(
              product: product,
              cartItems: cartController.cartItems.toList(),
              onAddToCart: (p) => cartController.addToCart(p),
              onRemoveFromCart: (id) => cartController.removeFromCart(id),
              onUpdateQuantity: (id, qty) =>
                  cartController.updateQuantity(id, qty),
            ));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة المنتج
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? Center(
                            child: Icon(Icons.image,
                                color: Colors.grey.shade400, size: 36),
                          )
                        : null,
                  ),
                ),
                // معلومات المنتج
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                        const Spacer(),
                        Text(
                          '${product.price} ر.ي',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Badge المقايضة
            if (showSwapBadge || product.isSwappable)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, color: Colors.white, size: 12),
                      SizedBox(width: 2),
                      Text(
                        'مقايضة',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            // Badge العرض
            if (showOfferBadge && product.isSpecialOffer)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'عرض',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
