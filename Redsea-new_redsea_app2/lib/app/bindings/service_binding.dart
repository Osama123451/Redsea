import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';

/// Binding لتبادل الخدمات
class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceController>(() => ServiceController());
  }
}
