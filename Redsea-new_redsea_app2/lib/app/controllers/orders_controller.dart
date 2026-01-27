import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notifications_controller.dart';

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

  @override
  void onInit() {
    super.onInit();
    loadOrders();
    loadSellerOrders();
  }

  /// تحميل الطلبات (كمشتري)
  Future<void> loadOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;
    try {
      final snapshot =
          await _ordersRef.orderByChild('userId').equalTo(userId).once();

      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Map<String, dynamic>> loadedOrders = [];
        int pending = 0;

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

        orders.value = loadedOrders;
        pendingOrdersCount.value = pending;
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل طلبات البائع (الطلبات الواردة)
  Future<void> loadSellerOrders() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot =
          await _ordersRef.orderByChild('sellerId').equalTo(userId).once();

      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Map<String, dynamic>> loadedOrders = [];
        int pendingConfirm = 0;

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

        sellerOrders.value = loadedOrders;
        pendingPaymentConfirmCount.value = pendingConfirm;
      }
    } catch (e) {
      debugPrint('Error loading seller orders: $e');
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

      final Map<String, dynamic> orderData = {
        'userId': userId,
        'sellerId': sellerId,
        'items': items,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'address': address ?? '',
        'notes': notes ?? '',
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
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
      );

      return orderId;
    } catch (e) {
      debugPrint('Error creating order: $e');
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
        'تم تأكيد استلام المبلغ للطلب',
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
        'لم يتم استلام المبلغ. يرجى التواصل مع البائع.',
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
        );
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

  /// إرسال إشعار (Helper)
  void _sendNotification(String title, String message) {
    try {
      if (Get.isRegistered<NotificationsController>()) {
        Get.find<NotificationsController>().sendNotification(
          title: title,
          message: message,
        );
      } else {
        final notifController = Get.put(NotificationsController());
        notifController.sendNotification(
          title: title,
          message: message,
        );
      }
    } catch (e) {
      debugPrint('Error triggering notification: $e');
    }
  }
}
