import 'package:get/get.dart';
import 'package:redsea/app/controllers/orders_controller.dart';

/// Binding لصفحة الطلبات
class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrdersController>(() => OrdersController());
  }
}
