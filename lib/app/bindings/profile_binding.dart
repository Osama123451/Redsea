import 'package:get/get.dart';
import 'package:redsea/app/controllers/user_controller.dart';

/// Binding للملف الشخصي
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
  }
}
