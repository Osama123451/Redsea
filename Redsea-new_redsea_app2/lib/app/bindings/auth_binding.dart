import 'package:get/get.dart';
import 'package:redsea/app/controllers/auth_controller.dart';

/// ربط صفحات المصادقة
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // التأكد من وجود AuthController
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
  }
}
