import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // طلب الأذونات
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // الحصول على رمز الجهاز وحفظه
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // الاستماع لتحديث الرمز
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // التعامل مع الرسائل أثناء تشغيل التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');
        // هنا يمكنك عرض إشعار محلي باستخدام Get.snackbar أو flutter_local_notifications
        // لكن بما أن لدينا InAppNotificationService، يمكننا استخدامه
        // أو دمج المنطق هنا. للتوافق مع الطلب، سنستخدم Get.snackbar بسيط الآن
        // أو نربطه بالخدمة الموجودة إذا كانت متوفرة.

        Get.snackbar(
          message.notification?.title ?? 'إشعار جديد',
          message.notification?.body ?? '',
          duration: const Duration(seconds: 4),
          onTap: (_) {
            _handleMessage(message);
          },
        );
      }
    });

    // التعامل مع فتح التطبيق من الإشعار (Background/Terminated -> Opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // التحقق مما إذا كان التطبيق قد فتح بسبب إشعار (Initial Message)
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseDatabase.instance.ref('user_devices/$userId/$token').set({
      'token': token,
      'platform': Platform.operatingSystem,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'message') {
      final chatId = message.data['chatId'];
      if (chatId != null) {
        Get.toNamed(AppRoutes.chat, arguments: chatId);
      }
    } else if (message.data['chatId'] != null) {
      // Fallback logic if type is missing but chatId exists
      Get.toNamed(AppRoutes.chat, arguments: message.data['chatId']);
    }
  }
}
