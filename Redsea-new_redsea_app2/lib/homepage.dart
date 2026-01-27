import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/controllers/categories_controller.dart';
import 'package:redsea/app/controllers/navigation_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/add_product_page.dart';
import 'package:redsea/categories_page.dart';
import 'package:redsea/notifications_page.dart';
import 'package:redsea/services/profile_page.dart';
import 'package:redsea/services/settings_page.dart';
import 'package:redsea/chat/chat_list_page.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/basket_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/app/ui/widgets/shimmer_loading.dart';
import 'package:redsea/experiences/experiences_page.dart';
import 'package:redsea/experiences/add_experience_page.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/search_results_page.dart';
import 'package:redsea/search/search_page.dart' as new_search;
import 'package:redsea/swap_selection_page.dart';
// Marketplace Widgets الجديدة
import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/app/ui/widgets/home/banner_slider.dart';
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/app/ui/widgets/home/latest_products_grid.dart';
import 'package:redsea/app/core/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // استخدام GetX Controllers - يتم تهيئتها في initState
  late ProductController productController;
  late CartController cartController;
  late FavoritesController favoritesController;
  late CategoriesController categoriesController;
  late NavigationController navigationController;
  late ExperiencesController experiencesController;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScrollingDown = false;

  @override
  void initState() {
    super.initState();
    // التأكد من تسجيل الـ Controllers قبل استخدامها
    if (!Get.isRegistered<ProductController>()) Get.put(ProductController());
    if (!Get.isRegistered<CartController>()) Get.put(CartController());
    if (!Get.isRegistered<FavoritesController>())
      Get.put(FavoritesController());
    if (!Get.isRegistered<CategoriesController>())
      Get.put(CategoriesController());
    if (!Get.isRegistered<NavigationController>())
      Get.put(NavigationController());
    if (!Get.isRegistered<ExperiencesController>())
      Get.put(ExperiencesController());

    productController = Get.find<ProductController>();
    cartController = Get.find<CartController>();
    favoritesController = Get.find<FavoritesController>();
    categoriesController = Get.find<CategoriesController>();
    navigationController = Get.find<NavigationController>();
    experiencesController = Get.find<ExperiencesController>();

    // التحقق من وجود تبويب مستهدف (بعد تسجيل الدخول)
    if (Get.arguments != null && Get.arguments['tab'] != null) {
      navigationController.currentIndex.value = Get.arguments['tab'];
    }

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection
        .toString()
        .contains('reverse')) {
      if (!_isScrollingDown) {
        setState(() => _isScrollingDown = true);
      }
    } else {
      if (_isScrollingDown) {
        setState(() => _isScrollingDown = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    productController.updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = navigationController.currentIndex.value;

      String pageTitle = '';
      if (currentIndex == 2) pageTitle = 'دردشاتي';
      if (currentIndex == 3) pageTitle = 'حسابي';

      return Scaffold(
        appBar: null,
        body: Column(
          children: [
            if (currentIndex == 2)
              CustomMarketplaceHeader(
                title: pageTitle,
                showSearchBar: currentIndex ==
                    2, // Search enabled only for Chats if desired, else false
                searchHint: currentIndex == 2 ? 'ابحث في الدردشات...' : null,
                showSearchFilter: false,
                showBackButton: true,
                onBackTap: () => navigationController.changePage(0),
                actions: currentIndex == 2
                    ? [
                        IconButton(
                          icon: const Icon(Icons.call_outlined,
                              color: Colors.white),
                          onPressed: () {
                            // منطق الاتصال
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune_outlined,
                              color: Colors.white),
                          onPressed: () {
                            // إعدادات الدردشة
                          },
                        ),
                      ]
                    : currentIndex == 3
                        ? [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined,
                                  color: Colors.white),
                              onPressed: () {
                                final authController =
                                    Get.find<AuthController>();
                                if (authController.requireLogin(
                                    message: 'سجّل دخولك للوصول للإعدادات')) {
                                  Get.to(() => SettingsPage());
                                }
                              },
                            ),
                          ]
                        : null,
                notificationCount:
                    Get.find<NotificationsController>().unreadCount.value,
                favoriteCount: favoritesController.favorites.length,
                cartCount: cartController.totalItems,
              ),
            Expanded(child: _buildCurrentPage()),
          ],
        ),
        floatingActionButton: _buildCenterAddButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomAppBar(),
      );
    });
  }

  Widget _buildCurrentPage() {
    switch (navigationController.currentIndex.value) {
      case 0:
        return _buildHomeContent();
      case 1:
        return CategoriesPage(
          onCategorySelected: (category) {
            final filterController = Get.find<FilterController>();
            filterController.setCategory(category);
            filterController.applyFilters();
            Get.to(() => SearchResultsPage());
          },
        );
      case 2:
        // صفحة الدردشات
        final authController = Get.find<AuthController>();
        if (authController.isGuest) {
          return _buildLoginRequiredPage('الدردشات');
        }
        return ChatListPage();
      case 3:
        // صفحة الحساب
        final authController = Get.find<AuthController>();
        if (authController.isGuest) {
          return _buildLoginRequiredPage('حسابي');
        }
        return ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  /// صفحة تطلب تسجيل الدخول
  Widget _buildLoginRequiredPage(String pageName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'سجّل دخولك للوصول إلى $pageName',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // مسح حالة التصفح كزائر والانتقال لتسجيل الدخول مع تمرير التبويب الحالي
              final authController = Get.find<AuthController>();
              authController.isGuestMode.value = false;
              Get.toNamed('/login',
                  arguments: {'tab': navigationController.currentIndex.value});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.login_rounded),
            label: const Text(
              'تسجيل الدخول',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: productController.loadProducts,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header مخصص
            SliverToBoxAdapter(
              child: CustomMarketplaceHeader(
                notificationCount:
                    Get.find<NotificationsController>().unreadCount.value,
                favoriteCount: favoritesController.favorites.length,
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
                  Get.to(() =>
                      BasketPage(cartItems: cartController.cartItems.toList()));
                },
                cartCount: cartController.totalItems,
                onSearchTap: () => Get.to(() => const new_search.SearchPage()),
              ),
            ),

            // البانر Slider
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: BannerSlider(),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // التصنيفات
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildSectionHeader('التصنيفات', onMoreTap: () {
                    navigationController.changePage(1);
                  }),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCategoriesGrid(),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // قسم منتجات للمقايضة
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildSectionHeader('منتجات للمقايضة', onMoreTap: () {
                    Get.to(() => const SearchResultsPage());
                  }),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildBarterSection(),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // قسم تبادل الخبرات
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildSectionHeader('تبادل الخبرات', onMoreTap: () {
                    Get.to(() => const ExperiencesPage());
                  }),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildExperiencesSection(),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // قسم أحدث المنتجات
            Obx(() {
              if (productController.searchQuery.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: LatestProductsGrid(
                    onViewAllTap: () => navigationController.changePage(1),
                    onProductTap: (product) {
                      final authController = Get.find<AuthController>();
                      if (!authController.requireLogin(
                          message: 'سجّل دخولك لعرض التفاصيل')) return;
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
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // نتائج البحث
            Obx(() {
              if (productController.searchQuery.value.isNotEmpty) {
                if (productController.isLoading.value) {
                  return SliverToBoxAdapter(child: ProductGridSkeleton());
                }

                if (productController.filteredProducts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج للبحث عن "${productController.searchQuery.value}"',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: LatestProductsGrid(
                    title:
                        'نتائج البحث (${productController.filteredProducts.length})',
                    products: productController.filteredProducts,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),

            // مساحة فارغة للـ BottomAppBar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  /// عنوان القسم الموحد - RTL
  Widget _buildSectionHeader(String title, {VoidCallback? onMoreTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // عرض الكل (يسار الشاشة)
          GestureDetector(
            onTap: onMoreTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // العنوان (يمين الشاشة)
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

  /// بطاقات المميزات - Features Slider
  Widget _buildFeaturesSlider() {
    final features = [
      {
        'title': 'المقايضة الذكية',
        'subtitle': 'بادل منتجاتك بما تريد',
        'icon': Icons.swap_calls,
        'gradient': [Colors.orange.shade600, Colors.deepOrange.shade400],
      },
      {
        'title': 'تبادل الخبرات',
        'subtitle': 'شارك معرفتك واستفد',
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

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SizedBox(
        height: 120,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.9),
          itemCount: (features.length / 2).ceil(),
          itemBuilder: (context, pageIndex) {
            return Row(
              children: [
                for (int i = 0; i < 2; i++)
                  if (pageIndex * 2 + i < features.length)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: features[pageIndex * 2 + i]['gradient']
                                as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  features[pageIndex * 2 + i]['icon']
                                      as IconData,
                                  color: Colors.white,
                                  size: 28),
                              const SizedBox(height: 6),
                              Text(
                                features[pageIndex * 2 + i]['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                features[pageIndex * 2 + i]['subtitle']
                                    as String,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// التصنيفات الافقية - دوائر
  Widget _buildCategoriesGrid() {
    final categories = [
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
      {'name': 'المزيد', 'icon': Icons.grid_view, 'color': Colors.grey},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              if (category['name'] == 'خبرات') {
                Get.to(() => const ExperiencesPage());
              } else if (category['name'] == 'المزيد') {
                navigationController.changePage(1);
              } else {
                final filterController = Get.find<FilterController>();
                filterController.setCategory(category['name'] as String);
                filterController.applyFilters();
                Get.to(() => const SearchResultsPage());
              }
            },
            child: Container(
              width: 75,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الأيقونة في دائرة
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (category['color'] as Color).withValues(alpha: 0.2),
                          (category['color'] as Color).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            (category['color'] as Color).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: category['color'] as Color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // اسم الفئة
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// قسم منتجات المقايضة
  Widget _buildBarterSection() {
    final barterProducts =
        productController.products.where((p) => p.negotiable).take(10).toList();

    if (barterProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 330,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: barterProducts.length,
            itemBuilder: (context, index) {
              final product = barterProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  width: 175,
                  child: MarketplaceProductCard(
                    product: product,
                    showBarter: true,
                    onTap: () {
                      final authController = Get.find<AuthController>();
                      if (!authController.requireLogin(
                          message: 'سجّل دخولك لعرض التفاصيل')) return;
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
                    onBarterTap: () {
                      final authController = Get.find<AuthController>();
                      if (!authController.requireLogin(
                          message: 'سجّل دخولك للمقايضة')) return;
                      Get.to(() => SwapSelectionPage(targetProduct: product));
                    },
                    onChatTap: () {
                      // منطق الدردشة
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// قسم الخبرات المطور
  Widget _buildExperiencesSection() {
    return Obx(() {
      final experiences =
          experiencesController.allExperiences.take(10).toList();

      if (experiences.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 250, // زيادة الارتفاع للبطاقات الأعرض
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: experiences.length,
          itemBuilder: (context, index) {
            final exp = experiences[index];
            return _buildWideExperienceCard(exp);
          },
        ),
      );
    });
  }

  /// بطاقة الخبرة العريضة الجديدة
  Widget _buildWideExperienceCard(Experience exp) {
    return Container(
      width: 300, // عرض أكبر كما طلب المستخدم
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // الجزء العلوي: الصورة والمعلومات
          Expanded(
            child: Row(
              children: [
                // معلومات الخبير
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          exp.expertName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          exp.title,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              exp.experienceText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.history,
                                size: 14, color: Colors.grey.shade600),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              exp.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '(${exp.reviewsCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // صورة الخبير مع زر المفضلة
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: exp.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(exp.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade100,
                      ),
                      child: exp.imageUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                    // زر المفضلة المدمج في الصورة
                    Positioned(
                      top: 18,
                      right: 18,
                      child: Obx(() {
                        final isFav = favoritesController.isFavorite(exp.id);
                        return GestureDetector(
                          onTap: () => _toggleExperienceFavorite(exp),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // أزرار الإجراءات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // زر الاستشارة
                Expanded(
                  child: _buildExpAction(
                    icon: Icons.psychology_outlined,
                    label: 'استشارة',
                    color: Colors.blue.shade600,
                    onTap: () => _startConsultation(exp),
                  ),
                ),
                const SizedBox(width: 8),
                // زر المقايضة
                Expanded(
                  child: _buildExpAction(
                    icon: Icons.swap_horiz,
                    label: 'مقايضة',
                    color: Colors.green.shade600,
                    onTap: () => _startExchange(exp),
                  ),
                ),
                const SizedBox(width: 8),
                // زر التفاصيل
                Expanded(
                  child: _buildExpAction(
                    icon: Icons.remove_red_eye_outlined,
                    label: 'عرض',
                    color: Colors.orange.shade700,
                    onTap: () => Get.to(() => const ExperiencesPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startConsultation(Experience exp) async {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لطلب استشارة')) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (exp.expertId == null || exp.expertId == currentUserId) {
      Get.snackbar(
        'تنبيه',
        'هذه خبرتك الخاصة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    final chatController = Get.find<ChatController>();
    final chatId =
        await chatController.createOrGetChat(exp.expertId!, 'exp_${exp.id}');

    if (chatId != null) {
      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: exp.expertId!,
            otherUserName: exp.expertName,
          ));
    } else {
      Get.snackbar(
        'خطأ',
        'فشل فتح المحادثة، يرجى المحاولة لاحقاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _startExchange(Experience exp) {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لمقايضة خدماتك')) return;

    // تحويل الخبرة لمنتج مؤقت لاستخدام نظام المقايضة الحالي
    final targetProduct = Product(
      id: exp.id,
      name: exp.title,
      price: '${exp.experiencePrice ?? exp.consultationPrice ?? 0}',
      negotiable: true,
      imageUrl: exp.imageUrl,
      description: exp.description,
      category: exp.category,
      dateAdded: exp.createdAt,
      ownerId: exp.expertId,
      isSwappable: true,
      isService: true,
    );

    Get.to(() => SwapSelectionPage(targetProduct: targetProduct));
  }

  void _toggleExperienceFavorite(Experience exp) {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لحفظ الخبرة')) return;

    // تحويل الخبرة لمنتج مؤقت لاستخدام المفضلات
    final product = Product(
      id: exp.id,
      name: exp.title,
      price: '${exp.experiencePrice ?? exp.consultationPrice ?? 0}',
      negotiable: true,
      imageUrl: exp.imageUrl,
      description: exp.description,
      category: exp.category,
      dateAdded: exp.createdAt,
      ownerId: exp.expertId,
    );

    favoritesController.toggleFavorite(product);
  }

  // بطاقة منتج أفقية
  Widget _buildHorizontalProductCard(Product product) {
    return GestureDetector(
      onTap: () {
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
              onUpdateQuantity: (id, qty) =>
                  cartController.updateQuantity(id, qty),
            ));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
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
                                color: Colors.grey.shade400, size: 40))
                        : null,
                  ),
                  // شارة المقايضة
                  if (product.negotiable)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz,
                            color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            // معلومات المنتج
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product.price} ر.ي',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
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

  // قسم المنتجات المميزة (Carousel)
  // ignore: unused_element
  Widget _buildFeaturedSection() {
    // استخدام المنتجات المميزة بناءً على التقييم والمبيعات والمشاهدات
    final featuredProducts = productController.featuredProducts;

    if (featuredProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'منتجات مميزة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: featuredProducts.length,
            itemBuilder: (context, index) {
              final product = featuredProducts[index];
              return _buildFeaturedCard(product);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFeaturedCard(Product product) {
    return GestureDetector(
      onTap: () {
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
              onUpdateQuantity: (id, qty) =>
                  cartController.updateQuantity(id, qty),
            ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: product.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          color: Colors.grey.shade200,
        ),
        child: Stack(
          children: [
            // تدرج لوني للنص
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            if (product.imageUrl.isEmpty)
              const Center(
                  child: Icon(Icons.image, color: Colors.grey, size: 48)),

            // شارة "مميز"
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'مميز',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // معلومات المنتج
            Positioned(
              bottom: 12,
              right: 12,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.price} ر.ي',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildProductItem(Product product) {
    return Obx(() {
      bool isInCart = cartController.isInCart(product.id);
      int currentQuantity = cartController.getQuantity(product.id);

      return GestureDetector(
        onTap: () {
          // الزائر لا يستطيع الدخول لتفاصيل المنتج
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
                onUpdateQuantity: (id, qty) =>
                    cartController.updateQuantity(id, qty),
              ));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
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
                                  color: Colors.grey.shade400, size: 48))
                          : null,
                    ),
                    // شارة المقايضة
                    if (product.negotiable)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.swap_horiz,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    // شارة الكمية في السلة
                    if (isInCart)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$currentQuantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // معلومات المنتج
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // التصنيف
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // السعر وزر الإضافة
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product.price} ر.ي',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildMiniAddButton(product, isInCart),
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
    });
  }

  Widget _buildMiniAddButton(Product product, bool isInCart) {
    final authController = Get.find<AuthController>();
    if (authController.isGuest) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (!isInCart) {
          cartController.addToCart(product);
        } else {
          cartController.incrementQuantity(product.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isInCart ? Colors.blue : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isInCart ? Icons.add : Icons.add_shopping_cart,
          size: 16,
          color: isInCart ? Colors.white : Colors.blue,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQuantityControls(
      Product product, bool isInCart, int currentQuantity) {
    // الزائر لا يرى أزرار التحكم
    final authController = Get.find<AuthController>();
    if (authController.isGuest) {
      return const SizedBox.shrink();
    }

    if (!isInCart) {
      return ElevatedButton.icon(
        onPressed: () => cartController.addToCart(product),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
        ),
        icon: const Icon(Icons.add_shopping_cart, size: 16),
        label: const Text('أضف'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => cartController.decrementQuantity(product.id),
            icon: const Icon(Icons.remove, size: 16),
            color: Colors.red,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$currentQuantity',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          IconButton(
            onPressed: () => cartController.incrementQuantity(product.id),
            icon: const Icon(Icons.add, size: 16),
            color: Colors.green,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    final authController = Get.find<AuthController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // هيدر الدراور - قابل للنقر للذهاب للحساب
          GestureDetector(
            onTap: () {
              Get.back();
              if (authController.requireLogin(
                  message: 'سجّل دخولك لعرض حسابك')) {
                navigationController.changePage(3);
              }
            },
            child: Obx(() => Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // صورة المستخدم
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: user?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoURL!,
                                  fit: BoxFit.cover,
                                  width: 86,
                                  height: 86,
                                ),
                              )
                            : const Icon(Icons.person,
                                color: Colors.blue, size: 45),
                      ),
                      const SizedBox(height: 14),
                      // اسم المستخدم - من قاعدة البيانات
                      Text(
                        authController.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
          const Divider(),
          Obx(() {
            final chatController = Get.find<ChatController>();
            final unreadCount = chatController.unreadChatsCount.value;
            return ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat, color: Colors.blue),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('المحادثات'),
              trailing: unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Get.back();
                final authController = Get.find<AuthController>();
                if (authController.requireLogin(
                    message: 'سجّل دخولك للوصول للمحادثات')) {
                  Get.to(() => ChatListPage());
                }
              },
            );
          }),
          // المفضلة
          Obx(() {
            final count = favoritesController.favoritesCount;
            return ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.favorite, color: Colors.red),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('المفضلة'),
              trailing: count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count منتج',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Get.back();
                final authController = Get.find<AuthController>();
                if (authController.requireLogin(
                    message: 'سجّل دخولك لعرض المفضلة')) {
                  Get.to(() => FavoritesPage());
                }
              },
            );
          }),
          // الإشعارات
          Obx(() {
            final notificationsController = Get.find<NotificationsController>();
            final unreadCount = notificationsController.unreadCount.value;
            return ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, color: Colors.orange),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('الإشعارات'),
              trailing: unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount جديد',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Get.back();
                final authController = Get.find<AuthController>();
                if (authController.requireLogin(
                    message: 'سجّل دخولك لعرض الإشعارات')) {
                  Get.to(() => NotificationPage());
                }
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.orange),
            title: const Text('الإعدادات'),
            onTap: () {
              Get.back();
              final authController = Get.find<AuthController>();
              if (authController.requireLogin(
                  message: 'سجّل دخولك للوصول للإعدادات')) {
                Get.to(() => SettingsPage());
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.purple),
            title: const Text('المساعدة والدعم'),
            onTap: () => _showHelpDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.teal),
            title: const Text('عن التطبيق'),
            onTap: () => _showAboutDialog(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج'),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('المساعدة والدعم'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('للمساعدة يمكنك التواصل معنا عبر:'),
            SizedBox(height: 8),
            Text('📧 البريد: osamammm018@gmail.com'),
            SizedBox(height: 8),
            Text('ساعات العمل: 9 ص - 5 م'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('عن التطبيق'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تطبيق REDSEA'),
            SizedBox(height: 8),
            Text('منصة بيع وشراء ومقايضة المنتجات او الخدمات.'),
            SizedBox(height: 8),
            Text('الإصدار: 1.0.0'),
            Text('التحديث الأخير: 2026'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _logout();
            },
            child:
                const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/first');
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  /// زر إضافة منتج المركزي - دائري ومرتفع (Floating)
  Widget _buildCenterAddButton() {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          final authController = Get.find<AuthController>();
          if (!authController.requireLogin(message: 'سجّل دخولك للإضافة')) {
            return;
          }
          _showAddOptions();
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  void _showAddOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'ماذا تريد أن تضيف؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOptionItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'إضافة منتج',
                  color: Colors.blue,
                  onTap: () {
                    Get.back();
                    Get.to(() => const AddProductPage())
                        ?.then((_) => productController.loadProducts());
                  },
                ),
                _buildAddOptionItem(
                  icon: Icons.psychology_outlined,
                  label: 'إضافة خبرة',
                  color: Colors.orange,
                  onTap: () {
                    Get.back();
                    Get.to(() => const AddExperiencePage());
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAddOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  /// شريط التنقل السفلي الجديد مع الشكل المحفور
  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 12,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // الجانب الأيمن - الرئيسية والفئات
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    outlineIcon: Icons.home_outlined,
                    filledIcon: Icons.home_filled,
                    label: 'الرئيسية',
                    index: 0,
                  ),
                  _buildNavItem(
                    outlineIcon: Icons.grid_view_outlined,
                    filledIcon: Icons.grid_view_rounded,
                    label: 'الفئات',
                    index: 1,
                  ),
                ],
              ),
            ),
            // مساحة للزر المركزي
            const SizedBox(width: 80),
            // الجانب الأيسر - الدردشات وحسابي
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItemWithBadge(
                    outlineIcon: Icons.chat_outlined,
                    filledIcon: Icons.chat,
                    label: 'دردشاتي',
                    index: 2,
                  ),
                  _buildNavItem(
                    outlineIcon: Icons.person_outline,
                    filledIcon: Icons.person,
                    label: 'حسابي',
                    index: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر تنقل في الشريط السفلي
  Widget _buildNavItem({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    final isSelected = navigationController.currentIndex.value == index;
    final color = isSelected ? Colors.blue.shade600 : Colors.grey.shade500;

    return InkWell(
      onTap: () => navigationController.changePage(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عنصر تنقل مع شارة (للدردشات)
  Widget _buildNavItemWithBadge({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    final isSelected = navigationController.currentIndex.value == index;
    final color = isSelected ? Colors.blue.shade600 : Colors.grey.shade500;

    return InkWell(
      onTap: () => navigationController.changePage(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final chatController = Get.find<ChatController>();
              final unreadCount = chatController.unreadChatsCount.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? filledIcon : outlineIcon,
                    color: color,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
