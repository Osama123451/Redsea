import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/theme_controller.dart';

/// متحكم الإعدادات - يدير إعدادات التطبيق والمستخدم
class SettingsController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // إعدادات الإشعارات
  final RxBool notificationsEnabled = true.obs;
  final RxBool orderNotifications = true.obs;
  final RxBool chatNotifications = true.obs;
  final RxBool promotionNotifications = true.obs;

  // إعدادات الخصوصية
  final RxBool profilePublic = true.obs;
  final RxBool showOnlineStatus = true.obs;

  // إعدادات العرض
  final RxBool darkMode = false.obs;
  final RxString language = 'ar'.obs;

  // إعدادات MFA
  final RxBool mfaEnabled = false.obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;

  /// الحصول على معرف المستخدم الحالي
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    _syncWithThemeController();
  }

  /// مزامنة مع ThemeController
  void _syncWithThemeController() {
    if (Get.isRegistered<ThemeController>()) {
      final themeController = Get.find<ThemeController>();
      darkMode.value = themeController.isDarkMode.value;

      // الاستماع لتغييرات الثيم
      ever(themeController.isDarkMode, (isDark) {
        darkMode.value = isDark;
      });
    }
  }

  /// تحميل الإعدادات من Firebase
  Future<void> loadSettings() async {
    if (_userId == null) return;

    try {
      isLoading.value = true;

      final snapshot = await _dbRef.child('users/$_userId/settings').once();

      if (snapshot.snapshot.value != null) {
        final settings =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        // إعدادات الإشعارات
        notificationsEnabled.value = settings['notificationsEnabled'] ?? true;
        orderNotifications.value = settings['orderNotifications'] ?? true;
        chatNotifications.value = settings['chatNotifications'] ?? true;
        promotionNotifications.value =
            settings['promotionNotifications'] ?? true;

        // إعدادات الخصوصية
        profilePublic.value = settings['profilePublic'] ?? true;
        showOnlineStatus.value = settings['showOnlineStatus'] ?? true;

        // إعدادات MFA
        mfaEnabled.value = settings['mfaEnabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ الإعدادات
  Future<void> saveSettings() async {
    if (_userId == null) return;

    try {
      await _dbRef.child('users/$_userId/settings').update({
        'notificationsEnabled': notificationsEnabled.value,
        'orderNotifications': orderNotifications.value,
        'chatNotifications': chatNotifications.value,
        'promotionNotifications': promotionNotifications.value,
        'profilePublic': profilePublic.value,
        'showOnlineStatus': showOnlineStatus.value,
        'mfaEnabled': mfaEnabled.value,
        'updatedAt': ServerValue.timestamp,
      });

      Get.snackbar('تم', 'تم حفظ الإعدادات بنجاح',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Error saving settings: $e');
      Get.snackbar('خطأ', 'فشل في حفظ الإعدادات');
    }
  }

  /// تبديل الوضع الداكن
  void toggleDarkMode() {
    darkMode.value = !darkMode.value;

    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().toggleTheme(darkMode.value);
    } else {
      Get.changeThemeMode(darkMode.value ? ThemeMode.dark : ThemeMode.light);
    }
  }

  /// تبديل إعداد معين
  void toggleSetting(RxBool setting) {
    setting.value = !setting.value;
    saveSettings();
  }

  /// تغيير اللغة
  void changeLanguage(String lang) {
    language.value = lang;
    Get.updateLocale(Locale(lang));
  }

  /// تبديل MFA
  Future<void> toggleMFA() async {
    mfaEnabled.value = !mfaEnabled.value;
    await saveSettings();
  }
}
