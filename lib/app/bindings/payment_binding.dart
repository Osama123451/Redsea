import 'package:get/get.dart';
import 'package:redsea/app/controllers/payment_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/orders_controller.dart';

/// Binding لصفحة الدفع
class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentController>(() => PaymentController());

    // التأكد من وجود CartController و OrdersController
    if (!Get.isRegistered<CartController>()) {
      Get.lazyPut<CartController>(() => CartController());
    }
    if (!Get.isRegistered<OrdersController>()) {
      Get.lazyPut<OrdersController>(() => OrdersController());
    }
  }
}
