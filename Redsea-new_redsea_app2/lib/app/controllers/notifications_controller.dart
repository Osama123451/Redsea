import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// أنواع الإشعارات
enum NotificationType {
  chat, // رسالة جديدة في المحادثة
  order, // تحديث حالة الطلب
  orderComplete, // طلب مكتمل
  orderPending, // طلب معلق
  admin, // رسالة من الإدارة
  system, // إشعار النظام (تحديث، صيانة، إلخ)
  promotion, // عروض وخصومات
  general, // إشعار عام
}

/// Controller لإدارة الإشعارات
class NotificationsController extends GetxController {
  final DatabaseReference _notificationsRef =
      FirebaseDatabase.instance.ref().child('notifications');
  final DatabaseReference _adminNotificationsRef =
      FirebaseDatabase.instance.ref().child('admin_notifications');

  // المتغيرات
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadCount = 0.obs;

  // عداد لكل نوع من الإشعارات
  final RxInt unreadChatCount = 0.obs;
  final RxInt unreadOrderCount = 0.obs;
  final RxInt unreadAdminCount = 0.obs;

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _adminSubscription;
  StreamSubscription? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    // الاستماع لتغيرات حالة المصادقة
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListening();
      } else {
        _stopListening();
      }
    });
  }

  @override
  void onClose() {
    _stopListening();
    _authSubscription?.cancel();
    super.onClose();
  }

  /// إيقاف الاستماع
  void _stopListening() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    _adminSubscription?.cancel();
    _adminSubscription = null;
    notifications.clear();
    unreadCount.value = 0;
    unreadChatCount.value = 0;
    unreadOrderCount.value = 0;
    unreadAdminCount.value = 0;
  }

  /// بدء الاستماع للإشعارات في الوقت الفعلي
  void _startListening() {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // إلغاء أي اشتراكات سابقة
      _notificationsSubscription?.cancel();
      _adminSubscription?.cancel();

      // الاستماع لإشعارات المستخدم
      _notificationsSubscription = _notificationsRef
          .child(userId)
          .orderByChild('timestamp')
          .onValue
          .listen((event) {
        try {
          _processNotifications(event.snapshot);
        } catch (e) {
          debugPrint('Error processing notifications: $e');
        }
      }, onError: (e) {
        debugPrint('Notifications stream error: $e');
      });

      // الاستماع لإشعارات الإدارة العامة
      _adminSubscription = _adminNotificationsRef.onValue.listen((event) {
        try {
          _processAdminNotifications(event.snapshot);
        } catch (e) {
          debugPrint('Error processing admin notifications: $e');
        }
      }, onError: (e) {
        debugPrint('Admin notifications stream error: $e');
      });
    } catch (e) {
      debugPrint('Error starting notification listeners: $e');
    }
  }

  /// معالجة إشعارات المستخدم
  void _processNotifications(DataSnapshot snapshot) {
    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> loadedNotifications = [];
      int chatUnread = 0;
      int orderUnread = 0;

      data.forEach((key, value) {
        final notification = Map<String, dynamic>.from(value);
        notification['id'] = key;
        notification['isAdmin'] = false;
        loadedNotifications.add(notification);

        if (notification['isRead'] != true) {
          final type = notification['type'] ?? 'general';
          if (type == 'chat') chatUnread++;
          if (type == 'order' ||
              type == 'orderComplete' ||
              type == 'orderPending') {
            orderUnread++;
          }
        }
      });

      // ترتيب حسب الوقت (الأحدث أولاً)
      loadedNotifications
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      // دمج مع إشعارات الإدارة الموجودة
      final adminNotifs =
          notifications.where((n) => n['isAdmin'] == true).toList();
      notifications.value = [...adminNotifs, ...loadedNotifications];
      _sortAllNotifications();

      unreadChatCount.value = chatUnread;
      unreadOrderCount.value = orderUnread;
      _updateTotalUnreadCount();
    }
  }

  /// معالجة إشعارات الإدارة
  void _processAdminNotifications(DataSnapshot snapshot) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> adminNotifications = [];
      int adminUnread = 0;

      data.forEach((key, value) {
        final notification = Map<String, dynamic>.from(value);
        notification['id'] = key;
        notification['isAdmin'] = true;
        notification['type'] = notification['type'] ?? 'admin';

        // التحقق من أن المستخدم لم يقرأ هذا الإشعار
        final readBy = notification['readBy'] as Map?;
        notification['isRead'] = readBy != null && readBy[userId] == true;

        adminNotifications.add(notification);

        if (notification['isRead'] != true) {
          adminUnread++;
        }
      });

      // دمج مع إشعارات المستخدم
      final userNotifs =
          notifications.where((n) => n['isAdmin'] != true).toList();
      notifications.value = [...adminNotifications, ...userNotifs];
      _sortAllNotifications();

      unreadAdminCount.value = adminUnread;
      _updateTotalUnreadCount();
    }
  }

  /// ترتيب جميع الإشعارات
  void _sortAllNotifications() {
    notifications
        .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
  }

  /// تحديث إجمالي عدد الإشعارات غير المقروءة
  void _updateTotalUnreadCount() {
    unreadCount.value =
        unreadChatCount.value + unreadOrderCount.value + unreadAdminCount.value;
  }

  /// تحميل الإشعارات (للتحديث اليدوي)
  Future<void> loadNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final snapshot = await _notificationsRef
          .child(userId)
          .orderByChild('timestamp')
          .once();

      _processNotifications(snapshot.snapshot);

      // تحميل إشعارات الإدارة أيضاً
      final adminSnapshot = await _adminNotificationsRef.once();
      _processAdminNotifications(adminSnapshot.snapshot);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// إرسال إشعار جديد
  Future<void> sendNotification({
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final newRef = _notificationsRef.child(userId).push();
      await newRef.set({
        'title': title,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'type': type,
        if (data != null) ...data,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// إرسال إشعار رسالة جديدة
  Future<void> sendChatNotification({
    required String toUserId,
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    try {
      final newRef = _notificationsRef.child(toUserId).push();
      await newRef.set({
        'title': 'رسالة جديدة من $senderName',
        'message':
            message.length > 50 ? '${message.substring(0, 50)}...' : message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'type': 'chat',
        'chatId': chatId,
        'senderId': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('Error sending chat notification: $e');
    }
  }

  /// إرسال إشعار تحديث طلب
  Future<void> sendOrderNotification({
    required String toUserId,
    required String orderId,
    required String status,
    required String message,
  }) async {
    try {
      final newRef = _notificationsRef.child(toUserId).push();
      String type = 'order';
      String title = 'تحديث الطلب';

      if (status == 'delivered' || status == 'completed') {
        type = 'orderComplete';
        title = '✅ تم التوصيل';
      } else if (status == 'pending_verification') {
        type = 'orderPending';
        title = '⏳ طلب قيد المراجعة';
      } else if (status == 'cancelled') {
        title = '❌ تم إلغاء الطلب';
      }

      await newRef.set({
        'title': title,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'type': type,
        'orderId': orderId,
        'status': status,
      });
    } catch (e) {
      debugPrint('Error sending order notification: $e');
    }
  }

  /// إرسال إشعار رفض (منتج، توثيق، بلاغ)
  Future<void> sendRejectionNotification({
    required String toUserId,
    required String itemName,
    required String reason,
    required String
        type, // 'product_rejection', 'verification_rejection', 'report_rejection'
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final newRef = _notificationsRef.child(toUserId).push();
      String title = '❌ تم رفض طلبك';
      String message = 'تم رفض "$itemName". السبب: $reason';

      if (type == 'product_rejection') {
        title = '❌ رفض المنتج';
      } else if (type == 'verification_rejection') {
        title = '❌ رفض توثيق الحساب';
        message = 'تم رفض طلب توثيق حسابك. السبب: $reason';
      } else if (type == 'report_rejection') {
        title = '❌ رفض البلاغ';
        message =
            'تمت مراجعة بلاغك بخصوص "$itemName" وتقرر رفضه. السبب: $reason';
      }

      await newRef.set({
        'title': title,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'type': type,
        'rejectionReason': reason,
        'itemName': itemName,
        if (extraData != null) ...extraData,
      });
    } catch (e) {
      debugPrint('Error sending rejection notification: $e');
    }
  }

  /// إرسال إشعار من الإدارة (للجميع)
  Future<void> sendAdminNotification({
    required String title,
    required String message,
    String type = 'admin',
  }) async {
    try {
      final newRef = _adminNotificationsRef.push();
      await newRef.set({
        'title': title,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'type': type,
        'readBy': {},
      });
    } catch (e) {
      debugPrint('Error sending admin notification: $e');
    }
  }

  /// إرسال إشعار تحديث النظام
  Future<void> sendSystemUpdateNotification({
    required String version,
    required String features,
  }) async {
    await sendAdminNotification(
      title: '🆕 إصدار جديد متاح v$version',
      message: features,
      type: 'system',
    );
  }

  /// تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final notification =
          notifications.firstWhereOrNull((n) => n['id'] == notificationId);
      if (notification == null) return;

      if (notification['isAdmin'] == true) {
        // إشعار الإدارة - تحديث readBy
        await _adminNotificationsRef
            .child(notificationId)
            .child('readBy')
            .update({userId: true});
      } else {
        // إشعار المستخدم العادي
        await _notificationsRef
            .child(userId)
            .child(notificationId)
            .update({'isRead': true});
      }

      // تحديث محلي
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        final type = notifications[index]['type'] ?? 'general';
        notifications[index]['isRead'] = true;
        notifications.refresh();

        // تحديث العدادات
        if (type == 'chat') {
          unreadChatCount.value = (unreadChatCount.value - 1).clamp(0, 9999);
        } else if (type.toString().contains('order')) {
          unreadOrderCount.value = (unreadOrderCount.value - 1).clamp(0, 9999);
        } else if (notifications[index]['isAdmin'] == true) {
          unreadAdminCount.value = (unreadAdminCount.value - 1).clamp(0, 9999);
        }
        _updateTotalUnreadCount();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// تحديد جميع إشعارات محادثة معينة كمقروءة
  Future<void> markChatNotificationsAsRead(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // البحث عن جميع الإشعارات التي تخص هذه المحادثة
      final chatNotifications = notifications
          .where((n) =>
              n['type'] == 'chat' &&
              n['chatId'] == chatId &&
              n['isRead'] != true)
          .toList();

      for (var notification in chatNotifications) {
        await _notificationsRef
            .child(userId)
            .child(notification['id'])
            .update({'isRead': true});

        // تحديث محلي
        notification['isRead'] = true;
      }

      if (chatNotifications.isNotEmpty) {
        notifications.refresh();
        unreadChatCount.value =
            (unreadChatCount.value - chatNotifications.length).clamp(0, 9999);
        _updateTotalUnreadCount();
      }
    } catch (e) {
      debugPrint('Error marking chat notifications as read: $e');
    }
  }

  /// تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      for (var notification in notifications) {
        if (notification['isRead'] != true) {
          if (notification['isAdmin'] == true) {
            await _adminNotificationsRef
                .child(notification['id'])
                .child('readBy')
                .update({userId: true});
          } else {
            await _notificationsRef
                .child(userId)
                .child(notification['id'])
                .update({'isRead': true});
          }
        }
      }

      // تحديث محلي
      for (var notification in notifications) {
        notification['isRead'] = true;
      }
      notifications.refresh();
      unreadCount.value = 0;
      unreadChatCount.value = 0;
      unreadOrderCount.value = 0;
      unreadAdminCount.value = 0;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final notification =
          notifications.firstWhereOrNull((n) => n['id'] == notificationId);
      if (notification != null && notification['isAdmin'] != true) {
        await _notificationsRef.child(userId).child(notificationId).remove();
      }
      notifications.removeWhere((n) => n['id'] == notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// حذف جميع الإشعارات
  Future<void> clearAllNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationsRef.child(userId).remove();
      notifications.removeWhere((n) => n['isAdmin'] != true);
      unreadCount.value = unreadAdminCount.value;
      unreadChatCount.value = 0;
      unreadOrderCount.value = 0;
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// الحصول على الإشعارات حسب النوع
  List<Map<String, dynamic>> getNotificationsByType(String type) {
    return notifications.where((n) => n['type'] == type).toList();
  }

  /// الحصول على أيقونة النوع
  static String getTypeIcon(String? type) {
    switch (type) {
      case 'chat':
        return '💬';
      case 'order':
        return '📦';
      case 'orderComplete':
        return '✅';
      case 'orderPending':
        return '⏳';
      case 'admin':
        return '📢';
      case 'system':
        return '🔔';
      case 'promotion':
        return '🎉';
      default:
        return '📌';
    }
  }
}
