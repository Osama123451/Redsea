import 'package:get/get.dart';
import 'package:redsea/app/controllers/cart_controller.dart';

/// Binding لصفحة السلة
class BasketBinding extends Bindings {
  @override
  void dependencies() {
    // CartController يتم تحميله في InitialBinding بشكل permanent
    // لذا نتحقق أولاً إذا كان موجوداً
    if (!Get.isRegistered<CartController>()) {
      Get.lazyPut<CartController>(() => CartController());
    }
  }
}
