import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/core/app_theme.dart';

/// خدمة الإشعارات داخل التطبيق
/// تعرض إشعارات منبثقة (Snackbar/Banner) للمستخدم
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  /// عرض إشعار رسالة جديدة مع إمكانية الرد
  static void showChatNotification({
    required String senderName,
    required String message,
    String? chatId,
    String? senderId,
    VoidCallback? onTap,
    VoidCallback? onReply,
  }) {
    Get.snackbar(
      '💬 رسالة جديدة من $senderName',
      message.length > 50 ? '${message.substring(0, 50)}...' : message,
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.blue.shade600,
      colorText: Colors.white,
      icon: const Icon(Icons.chat_bubble, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: (_) {
        // الضغط على الإشعار يفتح المحادثة
        if (onTap != null) onTap();
      },
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          // زر الرد ينقل للمحادثة مباشرة
          if (onReply != null) {
            onReply();
          } else if (onTap != null) {
            onTap();
          }
        },
        child: const Text(
          'رد 💬',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// عرض إشعار تحديث طلب
  static void showOrderNotification({
    required String title,
    required String message,
    required String status,
    String? orderId,
    VoidCallback? onTap,
  }) {
    Color bgColor;
    IconData icon;

    switch (status) {
      case 'delivered':
      case 'completed':
        bgColor = AppColors.primary;
        icon = Icons.check_circle;
        break;
      case 'pending_verification':
        bgColor = AppColors.primaryLight;
        icon = Icons.hourglass_empty;
        break;
      case 'cancelled':
        bgColor = AppColors.primaryDark;
        icon = Icons.cancel;
        break;
      case 'shipped':
        bgColor = AppColors.primary;
        icon = Icons.local_shipping;
        break;
      default:
        bgColor = AppColors.primaryDark;
        icon = Icons.inventory;
    }

    Get.snackbar(
      title,
      message,
      duration: const Duration(seconds: 5),
      backgroundColor: bgColor,
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: (_) {
        if (onTap != null) onTap();
      },
    );
  }

  /// عرض إشعار من الإدارة
  static void showAdminNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      '📢 $title',
      message,
      duration: const Duration(seconds: 6),
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      icon: const Icon(Icons.campaign, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: (_) {
        if (onTap != null) onTap();
      },
    );
  }

  /// عرض إشعار تحديث النظام
  static void showSystemUpdateNotification({
    required String version,
    required String features,
    VoidCallback? onUpdate,
  }) {
    Get.snackbar(
      '🆕 إصدار جديد متاح v$version',
      features,
      duration: const Duration(seconds: 8),
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white,
      icon: const Icon(Icons.system_update, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          if (onUpdate != null) onUpdate();
        },
        child: const Text('تحديث', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// عرض إشعار عام داخل التطبيق
  static void showGeneralNotification({
    required String title,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    Get.snackbar(
      title,
      message,
      duration: duration,
      backgroundColor: backgroundColor ?? AppColors.primary,
      colorText: Colors.white,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      onTap: (_) {
        if (onTap != null) onTap();
      },
    );
  }

  /// عرض banner ثابت في أعلى الشاشة (للإشعارات المهمة جداً)
  static void showPersistentBanner({
    required BuildContext context,
    required String title,
    required String message,
    Color? backgroundColor,
    List<Widget>? actions,
  }) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.right),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.primaryExtraLight,
        actions: actions ??
            [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: const Text('إغلاق'),
              ),
            ],
      ),
    );
  }

  /// إرسال وعرض إشعار (يحفظ في قاعدة البيانات ويعرض أيضاً)
  static Future<void> sendAndShowChatNotification({
    required String toUserId,
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    // حفظ في قاعدة البيانات
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().sendChatNotification(
        toUserId: toUserId,
        senderName: senderName,
        message: message,
        chatId: chatId,
      );
    }
  }

  /// إرسال وعرض إشعار طلب
  static Future<void> sendAndShowOrderNotification({
    required String toUserId,
    required String orderId,
    required String status,
    required String message,
  }) async {
    // حفظ في قاعدة البيانات
    if (Get.isRegistered<NotificationsController>()) {
      await Get.find<NotificationsController>().sendOrderNotification(
        toUserId: toUserId,
        orderId: orderId,
        status: status,
        message: message,
      );
    }
  }
}
