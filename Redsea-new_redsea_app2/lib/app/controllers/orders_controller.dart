import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';

/// Controller لإدارة الطلبات
class OrdersController extends GetxController {
  final DatabaseReference _ordersRef =
      FirebaseDatabase.instance.ref().child('orders');

  // المتغيرات
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> sellerOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt pendingOrdersCount = 0.obs;
  final RxInt pendingPaymentConfirmCount = 0.obs;

  StreamSubscription? _ordersSub;
  StreamSubscription? _sellerOrdersSub;
  StreamSubscription? _authSub;

  @override
  void onInit() {
    super.onInit();
    // _startListeners() will be called by the authStateChanges listener below if user is logged in
    // Listen for auth changes to restart listeners
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListeners();
      } else {
        _stopListeners();
      }
    });
  }

  @override
  void onClose() {
    _stopListeners();
    _authSub?.cancel();
    super.onClose();
  }

  void _startListeners() {
    _stopListeners(); // Cancel any existing ones
    loadOrders();
    loadSellerOrders();
  }

  void _stopListeners() {
    _ordersSub?.cancel();
    _ordersSub = null;
    _sellerOrdersSub?.cancel();
    _sellerOrdersSub = null;
    orders.clear();
    sellerOrders.clear();
    pendingOrdersCount.value = 0;
    pendingPaymentConfirmCount.value = 0;
  }

  /// تحميل الطلبات (كمشتري) - يعمل الآن بشكل Real-time
  Future<void> loadOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      _ordersSub?.cancel();
      _ordersSub = _ordersRef
          .orderByChild('userId')
          .equalTo(userId)
          .onValue
          .listen((event) {
        final List<Map<String, dynamic>> loadedOrders = [];
        int pending = 0;

        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            final order = Map<String, dynamic>.from(value);
            order['id'] = key;
            loadedOrders.add(order);
            if (order['status'] == 'pending_verification' ||
                order['status'] == 'payment_submitted') {
              pending++;
            }
          });

          // ترتيب حسب الوقت (الأحدث أولاً)
          loadedOrders.sort(
              (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        }

        orders.value = loadedOrders;
        pendingOrdersCount.value = pending;
        isLoading.value = false;
      }, onError: (e) {
        debugPrint('Error in orders stream: $e');
        isLoading.value = false;
      });
    } catch (e) {
      debugPrint('Error starting orders listener: $e');
      isLoading.value = false;
    }
  }

  /// تحميل طلبات البائع (الطلبات الواردة) - يعمل الآن بشكل Real-time
  Future<void> loadSellerOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      _sellerOrdersSub?.cancel();
      _sellerOrdersSub = _ordersRef
          .orderByChild('sellerId')
          .equalTo(userId)
          .onValue
          .listen((event) {
        final List<Map<String, dynamic>> loadedOrders = [];
        int pendingConfirm = 0;

        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            final order = Map<String, dynamic>.from(value);
            order['id'] = key;
            loadedOrders.add(order);
            if (order['status'] == 'payment_submitted') {
              pendingConfirm++;
            }
          });

          // ترتيب حسب الوقت (الأحدث أولاً)
          loadedOrders.sort(
              (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        }

        sellerOrders.value = loadedOrders;
        pendingPaymentConfirmCount.value = pendingConfirm;
      }, onError: (e) {
        debugPrint('Error in seller orders stream: $e');
      });
    } catch (e) {
      debugPrint('Error starting seller orders listener: $e');
    }
  }

  /// إنشاء طلب جديد
  Future<String?> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String paymentMethod,
    String? address,
    String? notes,
    String? transactionNumber,
    String? paymentReceiptUrl,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final orderId = _ordersRef.push().key;
      if (orderId == null) return null;

      // تحديد الحالة بناءً على طريقة الدفع
      String status;
      if (paymentMethod == 'cod') {
        status = 'pending_verification';
      } else if (transactionNumber != null && paymentReceiptUrl != null) {
        status = 'payment_submitted';
      } else {
        status = 'pending_payment';
      }

      // استخراج معرف البائع من العنصر الأول
      final sellerId = items.isNotEmpty ? items.first['sellerId'] : null;

      // جلب بيانات المشتري (المستخدم الحالي)
      String buyerName = 'مستخدم';
      String buyerPhone = '';
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .once();
        if (userSnapshot.snapshot.value != null) {
          final userData =
              Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
          buyerName = userData['name'] ?? userData['firstName'] ?? 'مستخدم';
          buyerPhone = userData['phone'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching buyer details: $e');
      }

      final Map<String, dynamic> orderData = {
        'userId': userId,
        'buyerId': userId, // إضافة للتوافق مع الفلاتر الأخرى
        'sellerId': sellerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'items': items,
        'totalPrice': totalPrice,
        'totalAmount': totalPrice, // إضافة للتوافق مع الفلاتر الأخرى
        'paymentMethod': paymentMethod,
        'address': address ?? '',
        'notes': notes ?? '',
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': ServerValue.timestamp, // إضافة للتوافق مع الفلاتر الأخرى
      };

      // حقول إثبات الدفع
      if (transactionNumber != null) {
        orderData['transactionNumber'] = transactionNumber;
        orderData['paymentSubmittedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
      if (paymentReceiptUrl != null) {
        orderData['paymentReceiptUrl'] = paymentReceiptUrl;
      }

      await _ordersRef.child(orderId).set(orderData);

      // إضافة للقائمة المحلية
      orderData['id'] = orderId;
      orders.insert(0, orderData);
      pendingOrdersCount.value++;

      _sendNotification(
        'تم استلام طلبك',
        'تم استلام طلبك رقم $orderId وهو قيد المراجعة',
        userId: userId,
        orderId: orderId,
      );

      // إشعار للبائع
      if (sellerId != null) {
        _sendNotification(
          'طلب جديد 📦',
          'لقد وصلك طلب جديد رقم $orderId من $buyerName',
          userId: sellerId,
          orderId: orderId,
        );
      }

      return orderId;
    } catch (e) {
      debugPrint('Error creating order: $e');
      Get.snackbar(
        'خطأ في إنشاء الطلب',
        'التفاصيل: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      return null;
    }
  }

  /// تحديث حالة الطلب
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersRef.child(orderId).update({'status': status});

      final index = orders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        final oldStatus = orders[index]['status'];
        orders[index]['status'] = status;
        orders.refresh();

        // تحديث عداد الطلبات المعلقة
        if (oldStatus == 'pending_verification' &&
            status != 'pending_verification') {
          pendingOrdersCount.value--;
        } else if (oldStatus != 'pending_verification' &&
            status == 'pending_verification') {
          pendingOrdersCount.value++;
        }

        _sendNotification(
          'تحديث حالة الطلب',
          'تغيرت حالة الطلب رقم $orderId إلى ${getStatusText(status)}',
          userId: orders[index]['userId'],
        );
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  /// تأكيد استلام الدفع (للبائع)
  Future<bool> confirmPayment(String orderId) async {
    try {
      await _ordersRef.child(orderId).update({
        'status': 'payment_confirmed',
        'paymentConfirmedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // تحديث القائمة المحلية
      final index = sellerOrders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        sellerOrders[index]['status'] = 'payment_confirmed';
        sellerOrders[index]['paymentConfirmedAt'] =
            DateTime.now().millisecondsSinceEpoch;
        sellerOrders.refresh();
        pendingPaymentConfirmCount.value--;
      }

      _sendNotification(
        'تم تأكيد الدفع ✅',
        'تم تأكيد استلام المبلغ للطلب رقم $orderId',
        userId: sellerOrders[index]['userId'],
      );

      return true;
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      return false;
    }
  }

  /// رفض الدفع (للبائع)
  Future<bool> rejectPayment(String orderId, {String? reason}) async {
    try {
      await _ordersRef.child(orderId).update({
        'status': 'payment_rejected',
        'rejectionReason': reason ?? 'لم يصل المبلغ',
      });

      // تحديث القائمة المحلية
      final index = sellerOrders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        sellerOrders[index]['status'] = 'payment_rejected';
        sellerOrders.refresh();
        pendingPaymentConfirmCount.value--;
      }

      _sendNotification(
        'تم رفض الدفع ❌',
        'لم يتم استلام المبلغ للطلب $orderId. السبب: ${reason ?? "لم يصل المبلغ"}',
        userId: sellerOrders[index]['userId'],
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      return false;
    }
  }

  /// إلغاء طلب
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _ordersRef.child(orderId).update({'status': 'cancelled'});

      final index = orders.indexWhere((o) => o['id'] == orderId);
      if (index != -1) {
        if (orders[index]['status'] == 'pending_verification') {
          pendingOrdersCount.value--;
        }
        orders[index]['status'] = 'cancelled';
        orders.refresh();

        _sendNotification(
          'إلغاء الطلب',
          'تم إلغاء طلبك رقم $orderId بنجاح',
          userId: orders[index]['userId'],
        );

        // إشعار للبائع
        final sellerId = orders[index]['sellerId'];
        if (sellerId != null) {
          _sendNotification(
            'تم إلغاء طلب',
            'قام المشتري بإلغاء الطلب رقم $orderId',
            userId: sellerId,
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  /// الحصول على طلب بالـ ID
  Map<String, dynamic>? getOrderById(String orderId) {
    final index = orders.indexWhere((o) => o['id'] == orderId);
    return index != -1 ? orders[index] : null;
  }

  /// تنسيق حالة الطلب
  String getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'بانتظار الدفع';
      case 'payment_submitted':
        return 'بانتظار تأكيد الدفع';
      case 'payment_confirmed':
        return 'تم تأكيد الدفع';
      case 'payment_rejected':
        return 'تم رفض الدفع';
      case 'pending_verification':
        return 'قيد المراجعة';
      case 'verified':
        return 'تم التأكيد';
      case 'processing':
        return 'جاري التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      case 'refunded':
        return 'مسترجع';
      default:
        return status;
    }
  }

  /// لون حالة الطلب
  int getStatusColorValue(String status) {
    switch (status) {
      case 'pending_payment':
        return 0xFFFF9800; // برتقالي
      case 'payment_submitted':
        return 0xFF2196F3; // أزرق
      case 'payment_confirmed':
        return 0xFF4CAF50; // أخضر
      case 'payment_rejected':
        return 0xFFF44336; // أحمر
      case 'pending_verification':
        return 0xFF9E9E9E; // رمادي
      case 'processing':
        return 0xFF03A9F4; // أزرق فاتح
      case 'shipped':
        return 0xFF673AB7; // بنفسجي
      case 'delivered':
        return 0xFF4CAF50; // أخضر
      case 'cancelled':
        return 0xFF757575; // رمادي غامق
      default:
        return 0xFF9E9E9E;
    }
  }

  /// الحصول على معرف المحادثة بين مستخدمين
  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  /// حذف طلب معين
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _ordersRef.child(orderId).remove();

      // إزالة من القوائم المحلية
      orders.removeWhere((o) => o['id'] == orderId);
      sellerOrders.removeWhere((o) => o['id'] == orderId);

      return true;
    } catch (e) {
      debugPrint('Error deleting order: $e');
      return false;
    }
  }

  /// حذف جميع الطلبات المكتملة أو الملغاة
  Future<void> clearOrders(bool isSeller) async {
    try {
      final list = isSeller ? sellerOrders : orders;
      final toDelete = list
          .where((o) =>
              o['status'] == 'delivered' ||
              o['status'] == 'cancelled' ||
              o['status'] == 'payment_rejected' ||
              o['status'] == 'refunded')
          .toList();

      for (var order in toDelete) {
        await _ordersRef.child(order['id']).remove();
      }

      // التحديث المحلي
      if (isSeller) {
        sellerOrders
            .removeWhere((o) => toDelete.any((t) => t['id'] == o['id']));
      } else {
        orders.removeWhere((o) => toDelete.any((t) => t['id'] == o['id']));
      }

      Get.snackbar('نجاح', 'تم تنظيف قائمة الطلبات');
    } catch (e) {
      debugPrint('Error clearing orders: $e');
      Get.snackbar('خطأ', 'فشل في تنظيف القائمة');
    }
  }

  /// إرسال إشعار (Helper)
  void _sendNotification(String title, String message,
      {String? userId, String? orderId}) {
    try {
      final data = orderId != null ? {'orderId': orderId} : null;

      if (Get.isRegistered<NotificationsController>()) {
        final notifController = Get.find<NotificationsController>();
        notifController.sendNotification(
          title: title,
          message: message,
          type: 'order',
          toUserId: userId,
          data: data,
        );
      } else {
        final notifController = Get.put(NotificationsController());
        notifController.sendNotification(
          title: title,
          message: message,
          type: 'order',
          toUserId: userId,
          data: data,
        );
      }
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }
}
