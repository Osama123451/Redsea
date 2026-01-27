import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/product_model.dart';

/// متحكم الدفع - يدير عمليات الدفع وإنشاء الطلبات
class PaymentController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // طريقة الدفع المحددة
  final RxString selectedPaymentMethod = ''.obs;

  // بيانات الشحن
  final RxString shippingAddress = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString notes = ''.obs;

  // حالة العملية
  final RxBool isProcessing = false.obs;
  final RxBool orderSuccess = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString orderId = ''.obs;

  // طرق الدفع المتاحة
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'cash',
      'name': 'الدفع عند الاستلام',
      'icon': '💵',
      'description': 'ادفع نقداً عند استلام الطلب'
    },
    {
      'id': 'bank_transfer',
      'name': 'تحويل بنكي',
      'icon': '🏦',
      'description': 'تحويل إلى الحساب البنكي'
    },
    {
      'id': 'wallet',
      'name': 'المحفظة الإلكترونية',
      'icon': '📱',
      'description': 'الدفع عبر المحفظة الإلكترونية'
    },
  ];

  /// الحصول على معرف المستخدم الحالي
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadUserDetails();
  }

  /// تحميل بيانات المستخدم
  Future<void> _loadUserDetails() async {
    if (_userId == null) return;

    try {
      final snapshot = await _dbRef.child('users/$_userId').once();

      if (snapshot.snapshot.value != null) {
        final userData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        shippingAddress.value = userData['address'] ?? '';
        phoneNumber.value = userData['phone'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  /// اختيار طريقة الدفع
  void selectPaymentMethod(String methodId) {
    selectedPaymentMethod.value = methodId;
  }

  /// التحقق من صحة البيانات
  bool validateOrder() {
    if (selectedPaymentMethod.value.isEmpty) {
      errorMessage.value = 'يرجى اختيار طريقة الدفع';
      return false;
    }

    if (shippingAddress.value.isEmpty) {
      errorMessage.value = 'يرجى إدخال عنوان الشحن';
      return false;
    }

    if (phoneNumber.value.isEmpty) {
      errorMessage.value = 'يرجى إدخال رقم الهاتف';
      return false;
    }

    errorMessage.value = '';
    return true;
  }

  /// إنشاء الطلب
  Future<bool> createOrder(List<Product> cartItems) async {
    if (_userId == null) {
      errorMessage.value = 'يرجى تسجيل الدخول أولاً';
      return false;
    }

    if (!validateOrder()) return false;

    try {
      isProcessing.value = true;
      errorMessage.value = '';

      // حساب المجموع
      double total = cartItems.fold(0, (sum, item) => sum + item.totalPrice);

      // إنشاء بيانات الطلب
      final orderData = {
        'userId': _userId,
        'items': cartItems
            .map((item) => {
                  'productId': item.id,
                  'name': item.name,
                  'price': item.price,
                  'quantity': item.quantity,
                  'imageUrl': item.imageUrl,
                })
            .toList(),
        'totalAmount': total,
        'paymentMethod': selectedPaymentMethod.value,
        'shippingAddress': shippingAddress.value,
        'phoneNumber': phoneNumber.value,
        'notes': notes.value,
        'status': 'pending_verification',
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      };

      // حفظ الطلب
      final newOrderRef = _dbRef.child('orders').push();
      await newOrderRef.set(orderData);

      orderId.value = newOrderRef.key ?? '';

      // إنشاء إشعار للمستخدم
      await _dbRef.child('notifications/$_userId').push().set({
        'title': 'طلب جديد',
        'body': 'تم إنشاء طلبك بنجاح برقم ${orderId.value}',
        'type': 'order',
        'orderId': orderId.value,
        'isRead': false,
        'createdAt': ServerValue.timestamp,
      });

      // مسح السلة
      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().clearCart();
      }

      orderSuccess.value = true;
      return true;
    } catch (e) {
      debugPrint('Error creating order: $e');
      errorMessage.value = 'حدث خطأ أثناء إنشاء الطلب';
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// إعادة تعيين
  void reset() {
    selectedPaymentMethod.value = '';
    notes.value = '';
    orderSuccess.value = false;
    orderId.value = '';
    errorMessage.value = '';
  }
}
