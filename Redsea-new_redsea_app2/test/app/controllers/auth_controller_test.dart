import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../helpers/testable_auth_controller.dart';

/// اختبارات وحدة لـ AuthController
/// تختبر دوال التحقق من صحة المدخلات بدون الحاجة لـ Firebase
void main() {
  late TestableAuthController authController;

  setUp(() {
    // تهيئة GetX
    Get.testMode = true;
    authController = TestableAuthController();
  });

  tearDown(() {
    authController.onClose();
    Get.reset();
  });

  group('validatePhone - التحقق من رقم الهاتف اليمني', () {
    test('يجب أن يُرجع false عند ترك الحقل فارغاً', () {
      authController.phoneController.text = '';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value, 'يرجى إدخال رقم الهاتف');
    });

    test('يجب أن يُرجع false إذا كان الرقم أقل من 9 أرقام', () {
      authController.phoneController.text = '77537841';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value,
          'رقم الهاتف يجب أن يتكون من 9 أرقام');
    });

    test('يجب أن يُرجع false إذا كان الرقم أكثر من 9 أرقام', () {
      authController.phoneController.text = '7753784123';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value,
          'رقم الهاتف يجب أن يتكون من 9 أرقام');
    });

    test('يجب أن يُرجع false إذا لم يبدأ الرقم بـ 7', () {
      authController.phoneController.text = '975378412';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value,
          'رقم الهاتف اليمني يجب أن يبدأ بـ 7');
    });

    test('يجب أن يُرجع false إذا كان الرقم الثاني غير صحيح (مثل 72)', () {
      authController.phoneController.text = '725378412';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value, 'رقم الهاتف غير صحيح');
    });

    test('يجب أن يُرجع true لرقم يمني صحيح يبدأ بـ 77', () {
      authController.phoneController.text = '775378412';

      final result = authController.validatePhone();

      expect(result, true);
      expect(authController.phoneError.value, '');
    });

    test('يجب أن يُرجع true لرقم يمني صحيح يبدأ بـ 73', () {
      authController.phoneController.text = '735378412';

      final result = authController.validatePhone();

      expect(result, true);
      expect(authController.phoneError.value, '');
    });

    test('يجب أن يُرجع true لرقم يمني صحيح يبدأ بـ 71', () {
      authController.phoneController.text = '711234567';

      final result = authController.validatePhone();

      expect(result, true);
      expect(authController.phoneError.value, '');
    });

    test('يجب أن يتجاهل المسافات والحروف الخاصة', () {
      authController.phoneController.text = '77 537 8412';

      final result = authController.validatePhone();

      expect(result, true);
      expect(authController.phoneError.value, '');
    });

    test('يجب أن يقبل أرقام تبدأ بـ 70', () {
      authController.phoneController.text = '701234567';

      final result = authController.validatePhone();

      expect(result, true);
    });

    test('يجب أن يقبل أرقام تبدأ بـ 74', () {
      authController.phoneController.text = '741234567';

      final result = authController.validatePhone();

      expect(result, true);
    });

    test('يجب أن يقبل أرقام تبدأ بـ 78', () {
      authController.phoneController.text = '781234567';

      final result = authController.validatePhone();

      expect(result, true);
    });

    test('يجب أن يرفض أرقام تبدأ بـ 76', () {
      authController.phoneController.text = '761234567';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value, 'رقم الهاتف غير صحيح');
    });

    test('يجب أن يرفض أرقام تبدأ بـ 79', () {
      authController.phoneController.text = '791234567';

      final result = authController.validatePhone();

      expect(result, false);
      expect(authController.phoneError.value, 'رقم الهاتف غير صحيح');
    });
  });

  group('validatePassword - التحقق من كلمة المرور', () {
    test('يجب أن يُرجع false عند ترك كلمة المرور فارغة', () {
      authController.passwordController.text = '';

      final result = authController.validatePassword();

      expect(result, false);
      expect(authController.passwordError.value, 'يرجى إدخال كلمة المرور');
    });

    test('يجب أن يُرجع false إذا كانت كلمة المرور أقل من 6 أحرف', () {
      authController.passwordController.text = '12345';

      final result = authController.validatePassword();

      expect(result, false);
      expect(authController.passwordError.value,
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    });

    test('يجب أن يُرجع true إذا كانت كلمة المرور 6 أحرف بالضبط', () {
      authController.passwordController.text = '123456';

      final result = authController.validatePassword();

      expect(result, true);
      expect(authController.passwordError.value, '');
    });

    test('يجب أن يُرجع true إذا كانت كلمة المرور أكثر من 6 أحرف', () {
      authController.passwordController.text = 'password123';

      final result = authController.validatePassword();

      expect(result, true);
      expect(authController.passwordError.value, '');
    });

    test('يجب أن يقبل كلمات مرور مع رموز خاصة', () {
      authController.passwordController.text = 'P@ss!2';

      final result = authController.validatePassword();

      expect(result, true);
    });
  });

  group('validateInputs - التحقق من جميع المدخلات', () {
    test('يجب أن يُرجع false إذا كان رقم الهاتف فارغاً وكلمة المرور صحيحة', () {
      authController.phoneController.text = '';
      authController.passwordController.text = 'password123';

      final result = authController.validateInputs();

      expect(result, false);
    });

    test('يجب أن يُرجع false إذا كان رقم الهاتف صحيحاً وكلمة المرور فارغة', () {
      authController.phoneController.text = '775378412';
      authController.passwordController.text = '';

      final result = authController.validateInputs();

      expect(result, false);
    });

    test('يجب أن يُرجع false إذا كان كلاهما غير صحيح', () {
      authController.phoneController.text = '123';
      authController.passwordController.text = '123';

      final result = authController.validateInputs();

      expect(result, false);
    });

    test('يجب أن يُرجع true إذا كان كلاهما صحيحاً', () {
      authController.phoneController.text = '775378412';
      authController.passwordController.text = 'password123';

      final result = authController.validateInputs();

      expect(result, true);
    });

    test('يجب أن يُرجع false إذا كان الهاتف صحيحاً وكلمة المرور قصيرة', () {
      authController.phoneController.text = '775378412';
      authController.passwordController.text = '12345';

      final result = authController.validateInputs();

      expect(result, false);
    });
  });

  group('clearErrors - مسح أخطاء التحقق', () {
    test('يجب أن يمسح جميع رسائل الخطأ', () {
      authController.phoneError.value = 'خطأ ما';
      authController.passwordError.value = 'خطأ آخر';

      authController.clearErrors();

      expect(authController.phoneError.value, '');
      expect(authController.passwordError.value, '');
    });

    test('يجب أن يعمل حتى لو كانت الأخطاء فارغة أصلاً', () {
      authController.phoneError.value = '';
      authController.passwordError.value = '';

      authController.clearErrors();

      expect(authController.phoneError.value, '');
      expect(authController.passwordError.value, '');
    });
  });

  group('clearInputs - مسح حقول الإدخال', () {
    test('يجب أن يمسح جميع الحقول ورسائل الخطأ', () {
      authController.phoneController.text = '775378412';
      authController.passwordController.text = 'password123';
      authController.phoneError.value = 'خطأ';
      authController.passwordError.value = 'خطأ';

      authController.clearInputs();

      expect(authController.phoneController.text, '');
      expect(authController.passwordController.text, '');
      expect(authController.phoneError.value, '');
      expect(authController.passwordError.value, '');
    });
  });

  group('togglePasswordVisibility - تبديل إظهار كلمة المرور', () {
    test('يجب أن يبدأ بإخفاء كلمة المرور', () {
      expect(authController.hidePassword.value, true);
    });

    test('يجب أن يُبدّل حالة إخفاء كلمة المرور', () {
      expect(authController.hidePassword.value, true);

      authController.togglePasswordVisibility();
      expect(authController.hidePassword.value, false);

      authController.togglePasswordVisibility();
      expect(authController.hidePassword.value, true);
    });
  });

  group('Guest Mode - وضع الزائر', () {
    test('يجب أن يكون وضع الزائر معطلاً بشكل افتراضي', () {
      expect(authController.isGuestMode.value, false);
    });

    test('isGuest يجب أن يُرجع true إذا كان في وضع الزائر', () {
      authController.isGuestMode.value = true;

      expect(authController.isGuest, true);
    });

    test('isGuest يجب أن يُرجع true إذا لم يكن مسجل الدخول', () {
      authController.isLoggedIn.value = false;

      expect(authController.isGuest, true);
    });

    test('isGuest يجب أن يُرجع false إذا كان مسجل الدخول وليس زائراً', () {
      authController.isLoggedIn.value = true;
      authController.isGuestMode.value = false;

      expect(authController.isGuest, false);
    });

    test(
        'canPerformActions يجب أن يُرجع true فقط إذا كان مسجل الدخول وليس زائراً',
        () {
      authController.isLoggedIn.value = true;
      authController.isGuestMode.value = false;

      expect(authController.canPerformActions, true);
    });

    test('canPerformActions يجب أن يُرجع false إذا كان زائراً', () {
      authController.isLoggedIn.value = true;
      authController.isGuestMode.value = true;

      expect(authController.canPerformActions, false);
    });
  });

  group('Admin Check - التحقق من صلاحيات المسؤول', () {
    test('يجب أن يتعرف على رقم هاتف الأدمن', () {
      authController.userData['phone'] = '775378412';

      expect(authController.isAdmin, true);
    });

    test('يجب أن يتعرف على دور admin', () {
      authController.userData['role'] = 'admin';

      expect(authController.isAdmin, true);
    });

    test('المستخدم العادي ليس أدمن', () {
      authController.userData['phone'] = '777123456';
      authController.userData['role'] = 'user';

      expect(authController.isAdmin, false);
    });

    test('userRole يجب أن يُرجع مسؤول للأدمن', () {
      authController.userData['role'] = 'admin';

      expect(authController.userRole, 'مسؤول');
    });

    test('userRole يجب أن يُرجع مستخدم للمستخدم العادي', () {
      authController.userData['phone'] = '777123456';
      authController.userData['role'] = 'user';

      expect(authController.userRole, 'مستخدم');
    });
  });

  group('Loading State - حالة التحميل', () {
    test('يجب أن يبدأ بحالة عدم التحميل', () {
      expect(authController.isLoading.value, false);
    });

    test('يجب أن يسمح بتغيير حالة التحميل', () {
      authController.isLoading.value = true;
      expect(authController.isLoading.value, true);

      authController.isLoading.value = false;
      expect(authController.isLoading.value, false);
    });
  });
}
