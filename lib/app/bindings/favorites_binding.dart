import 'package:get/get.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';

/// Binding لصفحة المفضلة
class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    // FavoritesController يتم تحميله في InitialBinding بشكل permanent
    // لذا نتحقق أولاً إذا كان موجوداً
    if (!Get.isRegistered<FavoritesController>()) {
      Get.lazyPut<FavoritesController>(() => FavoritesController());
    }
  }
}
