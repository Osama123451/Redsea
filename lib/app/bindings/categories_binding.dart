import 'package:get/get.dart';
import 'package:redsea/app/controllers/categories_controller.dart';

/// Binding لصفحة التصنيفات
class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoriesController>(() => CategoriesController());
  }
}
