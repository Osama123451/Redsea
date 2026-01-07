import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/my_products_page.dart';
import 'package:redsea/orders_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/services/settings_page.dart';
import 'package:redsea/admin/fix_products_page.dart';
import 'package:redsea/admin/admin_dashboard_page.dart';
import 'package:redsea/app/controllers/auth_controller.dart';

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

      // عدد المفضلات
      final favoritesSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('favorites')
          .child(_user!.uid)
          .once();
      if (favoritesSnapshot.snapshot.value != null) {
        _favoritesCount = (favoritesSnapshot.snapshot.value as Map).length;
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
        await _dbRef.child(_user!.uid).update({
          'name': newName.trim(),
        });
        setState(() {
          _userData['name'] = newName.trim();
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
                // الهيدر مع صورة الملف الشخصي
                SliverToBoxAdapter(
                  child: _buildProfileHeader(),
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

  Widget _buildProfileHeader() {
    String name = '';
    if (_userData['firstName'] != null) {
      name = '${_userData['firstName']} ${_userData['lastName'] ?? ''}'.trim();
    }

    if (name.isEmpty || name == 'مستخدم') {
      name = _userData['name'] ?? '';
    }

    // تم إزالة عرض رقم الهاتف كبديل احترماً للخصوصية

    final String phone = _userData['phone'] ?? 'لم يضف رقم';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'م';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // عنوان الصفحة
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ملفي الشخصي',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // صورة الملف الشخصي
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // رقم الهاتف
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // زر تعديل الملف
              OutlinedButton.icon(
                onPressed: () => _showEditNameDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('تعديل الملف'),
              ),
            ],
          ),
        ),
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
          Text('حسابي', style: Theme.of(context).textTheme.headlineSmall),
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
                  icon: Icons.shopping_bag,
                  title: 'طلباتي',
                  subtitle: 'متابعة حالة طلباتك',
                  color: Colors.orange,
                  onTap: () => Get.to(() => const OrdersPage()),
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
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  subtitle: 'إعدادات التطبيق والتفضيلات',
                  color: Colors.blueGrey,
                  onTap: () => Get.to(() => const SettingsPage()),
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
          Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall),
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
                  icon: Icons.lock_outline,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث كلمة المرور',
                  color: Colors.purple,
                  onTap: _showChangePasswordDialog,
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
          Text('أدوات الإدارة',
              style: Theme.of(context).textTheme.headlineSmall),
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
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'أدخل اسمك الجديد',
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

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // متغيرات الحالة المحلية للدايلوج
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isProcessing = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('تغيير كلمة المرور',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            scrollable: true,
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // كلمة المرور الحالية
                  TextFormField(
                    controller: oldPassController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureOld
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () {
                          setDialogState(() => obscureOld = !obscureOld);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // كلمة المرور الجديدة
                  TextFormField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () {
                          setDialogState(() => obscureNew = !obscureNew);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // تأكيد الجديدة
                  TextFormField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20),
                        onPressed: () {
                          setDialogState(
                              () => obscureConfirm = !obscureConfirm);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value != newPassController.text) {
                        return 'كلمات المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isProcessing = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null && user.email != null) {
                              // 1. إعادة التوثيق
                              final credential = EmailAuthProvider.credential(
                                email: user.email!,
                                password: oldPassController.text,
                              );
                              await user
                                  .reauthenticateWithCredential(credential);

                              // 2. تحديث كلمة المرور
                              await user.updatePassword(newPassController.text);

                              // 3. تحديث كلمة المرور في Realtime Database (لتشفر وتحفظ لغرض التوافق)
                              try {
                                final dbRef = FirebaseDatabase.instance
                                    .ref()
                                    .child('users')
                                    .child(user.uid);
                                String encodedPass = base64Encode(
                                    utf8.encode(newPassController.text));
                                await dbRef.update({'password': encodedPass});
                              } catch (e) {
                                debugPrint('خطأ في تحديث قاعدة البيانات: $e');
                              }

                              Get.back();
                              Get.snackbar(
                                'تم بنجاح',
                                'تم تغيير كلمة المرور بنجاح ✅',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String message = 'حدث خطأ غير معروف';
                            if (e.code == 'wrong-password') {
                              message = 'كلمة المرور الحالية غير صحيحة';
                            } else if (e.code == 'weak-password') {
                              message = 'كلمة المرور الجديدة ضعيفة';
                            }
                            Get.snackbar('خطأ', message,
                                backgroundColor: Colors.red,
                                colorText: Colors.white);
                          } catch (e) {
                            Get.snackbar('خطأ', 'حدث خطأ: $e');
                          } finally {
                            if (Get.isDialogOpen ?? false) {
                              // تحقق بسيط
                              setDialogState(() => isProcessing = false);
                            }
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('حفظ التغييرات'),
              ),
            ],
          );
        },
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
              Get.offAllNamed(AppRoutes.first);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
