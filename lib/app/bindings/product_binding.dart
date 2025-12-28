import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';

/// Binding لصفحات المنتجات
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(() => ProductController());
  }
}
