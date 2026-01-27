import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/theme_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/auth/mfa_enrollment_page.dart';
import 'package:redsea/services/mfa_service.dart';
import 'package:redsea/reports/reports_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeController themeController = Get.find<ThemeController>();
  bool _showNotifications = true;
  bool _isMfaEnabled = false;
  bool _loadingMfa = true;

  @override
  void initState() {
    super.initState();
    _checkMfaStatus();
  }

  Future<void> _checkMfaStatus() async {
    final enabled = await MfaService.isMfaEnabled();
    if (mounted) {
      setState(() {
        _isMfaEnabled = enabled;
        _loadingMfa = false;
      });
    }
  }

  void _logout() async {
    await Get.find<AuthController>().logout();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
              ),
              child: const Text('تسجيل خروج'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'RED',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              TextSpan(
                text: 'SEA',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // العنوان
            Center(
              child: Text(
                'الإعدادات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // الوضع الداكن
            Obx(() => _buildSettingItem(
                  title: 'الوضع الداكن',
                  icon: Icons.dark_mode,
                  trailing: Switch(
                    value: themeController.isDarkMode.value,
                    onChanged: (value) {
                      themeController.toggleTheme(value);
                    },
                    activeThumbColor: Colors.blue,
                  ),
                )),

            // إظهار الإشعارات
            _buildSettingItem(
              title: 'إظهار الإشعارات على شريط الإشعارات',
              icon: Icons.notifications,
              trailing: Switch(
                value: _showNotifications,
                onChanged: (value) {
                  setState(() {
                    _showNotifications = value;
                  });
                },
                activeThumbColor: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            // قسم الأمان
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'الأمان والخصوصية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.security, color: Colors.grey.shade700, size: 20),
                ],
              ),
            ),

            // التحقق بخطوتين
            _loadingMfa
                ? Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _isMfaEnabled
                    ? _buildMfaEnabledItem()
                    : _buildSecurityItem(
                        title: 'تفعيل التحقق بخطوتين (MFA)',
                        subtitle: 'تأمين إضافي عبر رمز OTP',
                        icon: Icons.verified_user,
                        onTap: () async {
                          final result =
                              await Get.to(() => const MfaEnrollmentPage());
                          if (result == true) {
                            _checkMfaStatus();
                          }
                        },
                      ),

            const SizedBox(height: 20),
            const Divider(),

            // صفحات المعلومات
            _buildNavigationItem(
              title: 'طلباتي 📦',
              icon: Icons.shopping_bag,
              onTap: () => Get.toNamed('/orders'),
            ),
            _buildNavigationItem(
              title: 'تقاريري 📊',
              icon: Icons.bar_chart,
              onTap: () => Get.to(() => ReportsPage()),
            ),
            _buildNavigationItem(
              title: 'من نحن',
              icon: Icons.info_outline,
              onTap: () => _showInfoDialog(context, 'من نحن',
                  'تطبيق RedSea هو منصة التجارة الإلكترونية الرائدة...'),
            ),
            _buildNavigationItem(
              title: 'سياسة الخصوصية',
              icon: Icons.privacy_tip_outlined,
              onTap: () => _showInfoDialog(
                  context, 'سياسة الخصوصية', 'نحن نهتم بخصوصيتك...'),
            ),
            _buildNavigationItem(
              title: 'الشروط والأحكام',
              icon: Icons.gavel,
              onTap: () => _showInfoDialog(context, 'الشروط والأحكام',
                  'باستخدامك للتطبيق فإنك توافق على...'),
            ),

            const SizedBox(height: 20),
            const Divider(),

            // تسجيل الخروج
            _buildDangerSettingItem(
              title: 'تسجيل الخروج',
              icon: Icons.logout,
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryExtraLight, Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios_new,
                size: 16, color: AppColors.primary),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMfaEnabledItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر إلغاء التفعيل
          TextButton(
            onPressed: _showDisableMfaDialog,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('إلغاء التفعيل'),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'التحقق بخطوتين مُفعّل ✅',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'حسابك محمي بالمصادقة الثنائية',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user,
                      color: Colors.blue, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisableMfaDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء التحقق بخطوتين'),
        content: const Text(
            'هل أنت متأكد من إلغاء المصادقة الثنائية؟ هذا سيجعل حسابك أقل أماناً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await MfaService.disableMfa();
              if (success) {
                Get.snackbar('نجاح', 'تم إلغاء المصادقة الثنائية',
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white);
                _checkMfaStatus();
              } else {
                Get.snackbar('تنبيه', 'حدث خطأ أثناء إلغاء المصادقة',
                    backgroundColor: AppColors.primaryDark,
                    colorText: Colors.white);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          trailing,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 12),
                Icon(icon, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryExtraLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios_new,
                size: 16, color: AppColors.primaryDark),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: AppColors.primaryDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Text(content, textAlign: TextAlign.right),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
