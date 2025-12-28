import 'package:get/get.dart';
import 'package:redsea/app/controllers/swap_controller.dart';

/// Binding لصفحات المقايضة
class SwapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SwapController>(() => SwapController());
  }
}
