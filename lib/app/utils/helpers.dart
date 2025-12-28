import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:redsea/app/core/app_theme.dart';

/// دوال مساعدة
class Helpers {
  /// تنسيق التاريخ
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format, 'ar').format(date);
  }

  /// تنسيق التاريخ والوقت
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm a', 'ar').format(date);
  }

  /// تنسيق الوقت النسبي (منذ...)
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return formatDate(date);
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  /// تنسيق السعر
  static String formatPrice(dynamic price) {
    if (price == null) return '0 ريال';
    final numPrice =
        price is num ? price : double.tryParse(price.toString()) ?? 0;
    return '${numPrice.toStringAsFixed(numPrice.truncateToDouble() == numPrice ? 0 : 2)} ريال';
  }

  /// تنسيق الأرقام مع الفواصل
  static String formatNumber(num number) {
    return NumberFormat('#,##0', 'ar').format(number);
  }

  /// إظهار snackbar نجاح - أزرق
  static void showSuccessSnackbar(String message) {
    Get.snackbar(
      'نجاح ✓',
      message,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// إظهار snackbar خطأ - أزرق غامق
  static void showErrorSnackbar(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  /// إظهار snackbar تحذير - أزرق فاتح
  static void showWarningSnackbar(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      backgroundColor: AppColors.primaryLight,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber, color: Colors.white),
    );
  }

  /// إظهار snackbar معلومات - أزرق
  static void showInfoSnackbar(String message) {
    Get.snackbar(
      'معلومات',
      message,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  /// إظهار dialog تأكيد - أزرق
  static Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// إظهار dialog تحميل
  static void showLoadingDialog({String? message}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// إخفاء dialog التحميل
  static void hideLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// تنظيف رقم الهاتف
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// فحص صلاحية الاتصال بالإنترنت
  static Future<bool> hasInternetConnection() async {
    // يمكن إضافة منطق فحص الاتصال هنا
    return true;
  }
}
