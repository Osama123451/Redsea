import 'package:get/get.dart';
import 'package:redsea/app/controllers/admin_controller.dart';

/// Binding لوحة تحكم المسؤول
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
  }
}
