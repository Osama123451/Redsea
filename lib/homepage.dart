import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/add_product_page.dart';
import 'package:redsea/categories_page.dart';
import 'package:redsea/notifications_page.dart';
import 'package:redsea/services/profile_page.dart';
import 'package:redsea/services/settings_page.dart';
import 'package:redsea/chat/chat_list_page.dart';
import 'package:redsea/basket_page.dart';
import 'package:redsea/search_page.dart';
import 'package:redsea/favorites_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // استخدام GetX Controllers
  final ProductController productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();
  final FavoritesController favoritesController =
      Get.find<FavoritesController>();

  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    productController.updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'REDSEA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          // زر البحث المتقدم
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () => Get.to(() => const SearchPage()),
          ),
          // زر المفضلة
          Obx(() => Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.red),
                    onPressed: () {
                      final authController = Get.find<AuthController>();
                      if (authController.requireLogin(
                          message: 'سجّل دخولك لعرض المفضلة')) {
                        Get.to(() => const FavoritesPage());
                      }
                    },
                  ),
                  if (favoritesController.favoritesCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${favoritesController.favoritesCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )),
          _buildCartIcon(),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
      floatingActionButton: _currentIndex == 0 ? _buildAddProductFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCartIcon() {
    return Obx(() {
      int totalItems = cartController.totalItems;
      return Stack(
        children: [
          IconButton(
            icon:
                const Icon(Icons.shopping_cart, color: Colors.black, size: 24),
            onPressed: () {
              final authController = Get.find<AuthController>();
              if (!authController.requireLogin(
                  message: 'سجّل دخولك لعرض السلة')) {
                return;
              }
              Get.to(() =>
                      BasketPage(cartItems: cartController.cartItems.toList()))
                  ?.then((result) {
                if (result != null && result is List<Product>) {
                  cartController.cartItems.value = result;
                }
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
          if (totalItems > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$totalItems',
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
      );
    });
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return CategoriesPage(
          onCategorySelected: (category) {
            setState(() {
              productController.changeFilter(category);
              _currentIndex = 0;
            });
          },
        );
      case 2:
        return const NotificationPage();
      case 3:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterBar(),
        Expanded(
          child: Obx(() {
            if (productController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: productController.loadProducts,
              child: _buildProductsList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Obx(() {
              if (productController.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    productController.clearSearch();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'جميع التصنيفات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                      '(${productController.filteredProducts.length} منتج)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: productController.filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(filter),
                        selected:
                            productController.selectedFilter.value == filter,
                        onSelected: (selected) =>
                            productController.changeFilter(filter),
                        selectedColor: Colors.blue,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color:
                              productController.selectedFilter.value == filter
                                  ? Colors.white
                                  : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Obx(() {
      if (productController.filteredProducts.isEmpty) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  productController.searchQuery.value.isEmpty
                      ? 'لا توجد منتجات متاحة'
                      : 'لا توجد نتائج للبحث عن "${productController.searchQuery.value}"',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (productController.searchQuery.value.isEmpty)
                  ElevatedButton(
                    onPressed: () => Get.to(() => const AddProductPage())
                        ?.then((_) => productController.loadProducts()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('أضف أول منتج'),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: productController.filteredProducts.length,
        itemBuilder: (context, index) {
          return _buildProductItem(productController.filteredProducts[index]);
        },
      );
    });
  }

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
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey, size: 30)
                        : null,
                  ),
                  if (product.negotiable)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  if (isInCart)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product.price} ريال',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          productController.formatDate(product.dateAdded),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildQuantityControls(
                            product, isInCart, currentQuantity),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

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

  Widget _buildAddProductFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () {
          final authController = Get.find<AuthController>();
          if (!authController.requireLogin(message: 'سجّل دخولك لإضافة منتج')) {
            return;
          }
          Get.to(() => const AddProductPage())
              ?.then((_) => productController.loadProducts());
        },
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'أضف منتج',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? "زائر"),
            accountEmail: Text(user?.email ?? "لم يتم تسجيل الدخول"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDrawerStat('منتجاتي', '0'),
                _buildDrawerStat('مبيعات', '0'),
                _buildDrawerStat('تقييم', '4.5'),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text('الرئيسية'),
            trailing: _currentIndex == 0
                ? const Icon(Icons.check, color: Colors.green, size: 16)
                : null,
            onTap: () {
              setState(() => _currentIndex = 0);
              Get.back();
            },
          ),
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
                  Get.to(() => const ChatListPage());
                }
              },
            );
          }),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.blue),
            title: const Text('التصنيفات'),
            trailing: _currentIndex == 1
                ? const Icon(Icons.check, color: Colors.green, size: 16)
                : null,
            onTap: () {
              setState(() => _currentIndex = 1);
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.blue),
            title: const Text('طلبات المقايضة'),
            onTap: () {
              Get.back();
              final authController = Get.find<AuthController>();
              if (authController.requireLogin(
                  message: 'سجّل دخولك للوصول لطلبات المقايضة')) {
                Get.toNamed(AppRoutes.swapRequests);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text('الإشعارات'),
            trailing: _currentIndex == 2
                ? const Icon(Icons.check, color: Colors.green, size: 16)
                : null,
            onTap: () {
              final authController = Get.find<AuthController>();
              if (!authController.requireLogin(
                  message: 'سجّل دخولك لعرض الإشعارات')) {
                return;
              }
              setState(() => _currentIndex = 2);
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('حسابي'),
            trailing: _currentIndex == 3
                ? const Icon(Icons.check, color: Colors.green, size: 16)
                : null,
            onTap: () {
              final authController = Get.find<AuthController>();
              if (!authController.requireLogin(
                  message: 'سجّل دخولك لعرض حسابك')) {
                return;
              }
              setState(() => _currentIndex = 3);
              Get.back();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.orange),
            title: const Text('الإعدادات'),
            onTap: () {
              Get.back();
              final authController = Get.find<AuthController>();
              if (authController.requireLogin(
                  message: 'سجّل دخولك للوصول للإعدادات')) {
                Get.to(() => const SettingsPage());
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

  Widget _buildDrawerStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
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
            Text('📧 البريد: support@redsea.com'),
            Text('📞 الهاتف: +966500000000'),
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
            Text('منصة لبيع وشراء المنتجات المستعملة والجديدة.'),
            SizedBox(height: 8),
            Text('الإصدار: 1.0.0'),
            Text('التحديث الأخير: 2024'),
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
      Get.offAllNamed(AppRoutes.first);
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        // الزائر يمكنه فقط البقاء في الرئيسية والتصنيفات
        if (index == 2 || index == 3) {
          final authController = Get.find<AuthController>();
          String msg = index == 2
              ? 'سجّل دخولك لعرض الإشعارات'
              : 'سجّل دخولك لعرض حسابك';
          if (!authController.requireLogin(message: msg)) return;
        }
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'التصنيفات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'الإشعارات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'حسابي',
        ),
      ],
    );
  }
}
