import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/login.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/theme_controller.dart';
import 'package:redsea/auth/mfa_enrollment_page.dart';
import 'package:redsea/services/mfa_service.dart';

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
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
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
                foregroundColor: Colors.red,
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
        title: Text(
          'REDSEA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
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
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.green),
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
                          color: Colors.green,
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
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.green, size: 24),
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
              foregroundColor: Colors.red,
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
                    backgroundColor: Colors.green, colorText: Colors.white);
                _checkMfaStatus();
              } else {
                Get.snackbar('خطأ', 'حدث خطأ أثناء إلغاء المصادقة',
                    backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.red),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: Colors.red),
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
