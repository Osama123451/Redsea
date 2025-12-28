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
  final RxBool isLoading = false.obs;
  final RxInt pendingOrdersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  /// تحميل الطلبات
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
          if (order['status'] == 'pending_verification') {
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

  /// إنشاء طلب جديد
  Future<String?> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String paymentMethod,
    String? address,
    String? notes,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final orderId = _ordersRef.push().key;
      if (orderId == null) return null;

      final orderData = {
        'userId': userId,
        'items': items,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'address': address ?? '',
        'notes': notes ?? '',
        'status': 'pending_verification',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

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
      case 'pending_verification':
        return 'قيد المراجعة';
      case 'verified':
        return 'تم التأكيد';
      case 'processing':
        return 'قيد التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
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
        // إذا لم يكن المتحكم موجوداً، نقوم بإنشائه مؤقتاً أو نستخدمه مباشرة
        // نستخدم Put لضمان وجوده
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
