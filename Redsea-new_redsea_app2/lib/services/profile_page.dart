import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/reports/reports_page.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/my_products_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/admin/fix_products_page.dart';
import 'package:redsea/admin/admin_dashboard_page.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/experiences/my_cv_page.dart';
import 'package:redsea/experiences/experience_exchange_page.dart'; // Added this import
import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/search/search_page.dart' as new_search;
import 'package:redsea/services/settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  // إحصائيات
  int _myProductsCount = 0;
  int _myOrdersCount = 0;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      try {
        DatabaseEvent event = await _dbRef.child(_user!.uid).once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          setState(() {
            _userData = Map<String, dynamic>.from(snapshot.value as Map);
            _isLoading = false;
          });
        } else {
          await _createUserData();
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    if (_user == null) return;

    try {
      // عدد منتجاتي
      final productsSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('products')
          .orderByChild('userId')
          .equalTo(_user!.uid)
          .once();
      if (productsSnapshot.snapshot.value != null) {
        _myProductsCount = (productsSnapshot.snapshot.value as Map).length;
      }

      // عدد طلباتي
      final ordersSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('orders')
          .orderByChild('userId')
          .equalTo(_user!.uid)
          .once();
      if (ordersSnapshot.snapshot.value != null) {
        _myOrdersCount = (ordersSnapshot.snapshot.value as Map).length;
      }

      // عدد المفضلات - استخدام FavoritesController للحصول على العدد الدقيق
      if (Get.isRegistered<FavoritesController>()) {
        _favoritesCount = Get.find<FavoritesController>().favoritesCount;
      } else {
        // احتياطي في حال لم يتم حقن المتحكم
        final favoritesSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('favorites')
            .child(_user!.uid)
            .once();
        if (favoritesSnapshot.snapshot.value != null) {
          _favoritesCount = (favoritesSnapshot.snapshot.value as Map).length;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _createUserData() async {
    if (_user != null) {
      try {
        await _dbRef.child(_user!.uid).set({
          'name': _user?.displayName ?? 'مستخدم جديد',
          'phone': _user?.phoneNumber ?? 'لم يضف رقم',
          'email': _user?.email ?? 'لم يضف بريد',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        await _loadUserData();
      } catch (e) {
        debugPrint('Error creating user data: $e');
      }
    }
  }

  Future<void> _updateUserName(String newName) async {
    if (_user != null && newName.trim().isNotEmpty) {
      try {
        final parts = newName.trim().split(' ');
        final firstName = parts.first;
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        await _dbRef.child(_user!.uid).update({
          'name': newName.trim(),
          'firstName': firstName,
          'lastName': lastName,
        });
        setState(() {
          _userData['name'] = newName.trim();
          _userData['firstName'] = firstName;
          _userData['lastName'] = lastName;
        });
        Get.snackbar('نجاح', 'تم تحديث الاسم بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar('خطأ', 'خطأ في التحديث: $e',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CustomMarketplaceHeader(
                    showSearchBar: false,
                    onSearchTap: () =>
                        Get.to(() => const new_search.SearchPage()),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white),
                        onPressed: () {
                          final authController = Get.find<AuthController>();
                          if (authController.requireLogin(
                              message: 'سجّل دخولك للوصول للإعدادات')) {
                            Get.to(() => const SettingsPage());
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // قسم معلومات المستخدم (مبسط)
                SliverToBoxAdapter(
                  child: _buildUserInfoSection(),
                ),

                // الإحصائيات
                SliverToBoxAdapter(
                  child: _buildStatsSection(),
                ),

                // القائمة الرئيسية
                SliverToBoxAdapter(
                  child: _buildMenuSection(),
                ),

                // الإعدادات
                SliverToBoxAdapter(
                  child: _buildSettingsSection(),
                ),

                // أدوات الإدارة (للأدمن فقط)
                if (Get.find<AuthController>().isAdmin)
                  SliverToBoxAdapter(
                    child: _buildAdminSection(),
                  ),

                // زر تسجيل الخروج
                SliverToBoxAdapter(
                  child: _buildLogoutButton(),
                ),

                // مساحة في الأسفل
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
    );
  }

  Widget _buildUserInfoSection() {
    String name = '';
    if (_userData['firstName'] != null) {
      name = '${_userData['firstName']} ${_userData['lastName'] ?? ''}'.trim();
    }
    if (name.isEmpty || name == 'مستخدم') {
      name = _userData['name'] ?? '';
    }
    final String phone = _userData['phone'] ?? 'لم يضف رقم';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'م';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          // صورة الملف الشخصي
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryExtraLight.withValues(alpha: 0.5),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // الاسم
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // رقم الهاتف
          Text(
            phone,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          // زر تعديل الملف
          OutlinedButton.icon(
            onPressed: () => _showEditNameDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('تعديل الملف'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'منتجاتي',
              '$_myProductsCount',
              Icons.inventory_2,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'طلباتي',
              '$_myOrdersCount',
              Icons.shopping_bag,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'المفضلة',
              '$_favoritesCount',
              Icons.favorite,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          Container(
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
              children: [
                _buildMenuItem(
                  icon: Icons.inventory_2,
                  title: 'منتجاتي',
                  subtitle: 'إدارة المنتجات التي أضفتها',
                  color: AppColors.primary,
                  onTap: () => Get.to(() => const MyProductsPage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.swap_horiz,
                  title: 'طلبات المقايضة',
                  subtitle: 'متابعة الطلبات الواردة والمرسلة',
                  color: Colors.green,
                  onTap: () => Get.toNamed(AppRoutes.swapRequests),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.favorite,
                  title: 'المفضلة',
                  subtitle: 'المنتجات التي أعجبتك',
                  color: Colors.red,
                  onTap: () => Get.to(() => const FavoritesPage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.bar_chart,
                  title: 'تقاريري',
                  subtitle: 'إحصائيات وتقارير نشاطك',
                  color: Colors.deepPurple,
                  onTap: () => Get.to(() => ReportsPage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.swap_calls_outlined,
                  title: 'تبادل الخبرات',
                  subtitle: 'طلبات مبادلة خبرة بخبرة',
                  color: Colors.orange,
                  onTap: () => Get.to(() => const ExperienceExchangePage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.psychology_outlined,
                  title: 'خبراتي',
                  subtitle: 'الخبرات التي أضفتها واستشاراتي',
                  color: Colors.teal,
                  onTap: () => Get.to(() => const MyCVPage()),
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
              children: [
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  subtitle: 'إعدادات التطبيق والتفضيلات',
                  color: Colors.blueGrey,
                  onTap: () => Get.to(() => const SettingsPage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  subtitle: 'إدارة تفضيلات الإشعارات',
                  color: Colors.teal,
                  onTap: () {},
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'المساعدة والدعم',
                  subtitle: 'تواصل معنا',
                  color: Colors.indigo,
                  onTap: _showHelpDialog,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          Container(
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
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'لوحة التحكم',
                  subtitle: 'إحصائيات وأدوات الإدارة',
                  color: Colors.indigo,
                  onTap: () => Get.to(() => const AdminDashboardPage()),
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.admin_panel_settings,
                  title: 'تعييني كمسؤول',
                  subtitle: 'ترقية الحساب الحالي لصلاحيات كاملة',
                  color: Colors.red,
                  onTap: _makeMeAdmin,
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.move_up,
                  title: 'نقل كورس التسويق',
                  subtitle: 'نقل المنتج من "أخرى" إلى "خدمات"',
                  color: Colors.blue,
                  onTap: _fixMarketingCourse,
                  context: context,
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Icons.build,
                  title: 'إصلاح المنتجات',
                  subtitle: 'إضافة userId للمنتجات القديمة',
                  color: Colors.orange,
                  onTap: () => Get.to(() => const FixProductsPage()),
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeMeAdmin() async {
    if (_user == null) return;
    try {
      await _dbRef.child(_user!.uid).update({'role': 'admin'});
      Get.snackbar('نجاح', 'أنت الآن مسؤول! (Admin)',
          backgroundColor: Colors.green, colorText: Colors.white);
      setState(() {
        _userData['role'] = 'admin';
      });
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الترقية: $e');
    }
  }

  Future<void> _fixMarketingCourse() async {
    try {
      // البحث عن منتج "كورس تسويق"
      final productsRef = FirebaseDatabase.instance.ref().child('products');
      final snapshot = await productsRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        int updatedCount = 0;

        data.forEach((key, value) async {
          final productData = Map<String, dynamic>.from(value);
          final String name = productData['name'] ?? '';

          if (name.contains('كورس') || name.contains('تسويق')) {
            await productsRef.child(key).update({'category': 'خدمات'});
            updatedCount++;
          }
        });

        Get.snackbar('نجاح', 'تم تحديث $updatedCount منتج ونقلهم إلى خدمات',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('تنبيه', 'لم يتم العثور على منتجات',
            backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء التحديث: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        textAlign: TextAlign.right,
      ),
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.right,
        style: TextStyle(
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.7)),
      ),
      trailing: Icon(Icons.arrow_back_ios,
          size: 16, color: Theme.of(context).iconTheme.color),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, color: Colors.grey.shade200);
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'تسجيل الخروج',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(
      text: _userData['firstName'] != null
          ? '${_userData['firstName']} ${_userData['lastName'] ?? ''}'
          : _userData['name'],
    );

    Get.dialog(
      AlertDialog(
        title: const Text('تعديل الاسم'),
        scrollable: true,
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'أدخل اسمك الجديد',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _updateUserName(controller.text);
            },
            child: const Text('حفظ'),
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
          children: [
            ListTile(
              leading: Icon(Icons.email, color: AppColors.primary),
              title:
                  Text('osamammm018@gmail.com', style: TextStyle(fontSize: 14)),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppColors.primary),
              title: Text('+967 775378412', style: TextStyle(fontSize: 14)),
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: AppColors.primary),
              title: Text('9 ص - 10 م'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await FirebaseAuth.instance.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
