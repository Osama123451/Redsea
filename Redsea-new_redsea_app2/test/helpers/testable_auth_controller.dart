import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// نسخة قابلة للاختبار من AuthController
/// تحتوي على منطق التحقق فقط بدون الاعتماد على Firebase
/// تُستخدم في الاختبارات لتجنب مشاكل تهيئة Firebase
class TestableAuthController extends GetxController {
  // متحكمات حقول الإدخال
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // الحالة المرصودة
  final RxBool isLoading = false.obs;
  final RxBool hidePassword = true.obs;
  final RxBool isGuestMode = false.obs;

  // أخطاء التحقق
  final RxString phoneError = ''.obs;
  final RxString passwordError = ''.obs;

  // معلومات المستخدم (للاختبار)
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  // حالة المستخدم الحالي (للاختبار)
  final RxBool isLoggedIn = false.obs;
  String? currentUserId;

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// التحقق من صحة رقم الهاتف اليمني
  /// يجب أن يبدأ بـ 7 ويتكون من 9 أرقام
  bool validatePhone() {
    final phone = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.isEmpty) {
      phoneError.value = 'يرجى إدخال رقم الهاتف';
      return false;
    }

    if (phone.length != 9) {
      phoneError.value = 'رقم الهاتف يجب أن يتكون من 9 أرقام';
      return false;
    }

    if (!phone.startsWith('7')) {
      phoneError.value = 'رقم الهاتف اليمني يجب أن يبدأ بـ 7';
      return false;
    }

    // التحقق من أن الرقم الثاني صحيح (0, 1, 3, 4, 5, 7, 8)
    final validSecondDigits = ['0', '1', '3', '4', '5', '7', '8'];
    if (!validSecondDigits.contains(phone[1])) {
      phoneError.value = 'رقم الهاتف غير صحيح';
      return false;
    }

    phoneError.value = '';
    return true;
  }

  /// التحقق من قوة كلمة المرور
  /// يجب أن تكون 6 أحرف على الأقل
  bool validatePassword() {
    final password = passwordController.text;

    if (password.isEmpty) {
      passwordError.value = 'يرجى إدخال كلمة المرور';
      return false;
    }

    if (password.length < 6) {
      passwordError.value = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      return false;
    }

    passwordError.value = '';
    return true;
  }

  /// التحقق من جميع المدخلات
  bool validateInputs() {
    final isPhoneValid = validatePhone();
    final isPasswordValid = validatePassword();
    return isPhoneValid && isPasswordValid;
  }

  /// مسح أخطاء التحقق
  void clearErrors() {
    phoneError.value = '';
    passwordError.value = '';
  }

  /// مسح حقول الإدخال
  void clearInputs() {
    phoneController.clear();
    passwordController.clear();
    clearErrors();
  }

  /// تبديل إظهار/إخفاء كلمة المرور
  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  /// هل المستخدم زائر؟
  bool get isGuest => isGuestMode.value || !isLoggedIn.value;

  /// هل يمكن للمستخدم القيام بإجراءات؟
  bool get canPerformActions => !isGuestMode.value && isLoggedIn.value;

  // ===================== نظام الأدوار =====================

  /// رقم هاتف الأدمن الرئيسي
  static const String adminPhone = '775378412';

  /// أرقام هواتف المسؤولين
  static const List<String> adminPhones = [
    adminPhone,
  ];

  /// هل المستخدم مسؤول (أدمن)؟
  bool get isAdmin {
    if (userData['role'] == 'admin') return true;
    final userPhone = userData['phone']?.toString() ?? '';
    return adminPhones.contains(userPhone);
  }

  /// الحصول على دور المستخدم
  String get userRole => isAdmin ? 'مسؤول' : 'مستخدم';
}
