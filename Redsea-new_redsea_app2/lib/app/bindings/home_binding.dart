import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/user_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/categories_controller.dart';
import 'package:redsea/app/controllers/navigation_controller.dart';

/// ربط الصفحة الرئيسية
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers للصفحة الرئيسية
    Get.lazyPut(() => ProductController());
    Get.lazyPut(() => UserController());
    Get.lazyPut(() => FavoritesController());
    Get.lazyPut(() => CartController());
    Get.lazyPut(() => CategoriesController());
    Get.lazyPut(() => NavigationController());
  }
}
