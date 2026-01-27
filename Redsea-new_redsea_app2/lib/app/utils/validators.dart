import 'package:redsea/app/core/app_constants.dart';

/// دوال التحقق من صحة البيانات
class Validators {
  /// التحقق من أن الحقل غير فارغ
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName مطلوب'
          : AppMessages.validationRequired;
    }
    return null;
  }

  /// التحقق من صحة رقم الهاتف
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    // إزالة المسافات والرموز
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');

    // التحقق من الطول
    if (cleanPhone.length != AppConstants.phoneLength &&
        cleanPhone.length != AppConstants.phoneLength + 3) {
      return AppMessages.validationInvalidPhone;
    }

    return null;
  }

  /// التحقق من صحة البريد الإلكتروني
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppMessages.validationInvalidEmail;
    }

    return null;
  }

  /// التحقق من صحة كلمة المرور
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    if (value.length < AppConstants.minPasswordLength) {
      return AppMessages.validationPasswordTooShort;
    }

    return null;
  }

  /// التحقق من تطابق كلمات المرور
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    if (value != password) {
      return AppMessages.validationPasswordsNotMatch;
    }

    return null;
  }

  /// التحقق من صحة الاسم
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    if (value.length > AppConstants.maxNameLength) {
      return 'الاسم طويل جداً (الحد الأقصى ${AppConstants.maxNameLength} حرف)';
    }

    return null;
  }

  /// التحقق من صحة السعر
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.validationRequired;
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'السعر يجب أن يكون رقماً موجباً';
    }

    return null;
  }

  /// التحقق من صحة الوصف
  static String? description(String? value) {
    if (value != null && value.length > AppConstants.maxDescriptionLength) {
      return 'الوصف طويل جداً (الحد الأقصى ${AppConstants.maxDescriptionLength} حرف)';
    }

    return null;
  }
}
