import 'package:get/get.dart';
import 'package:redsea/app/controllers/settings_controller.dart';
import 'package:redsea/app/controllers/theme_controller.dart';

/// Binding لصفحة الإعدادات
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());

    // التأكد من وجود ThemeController
    if (!Get.isRegistered<ThemeController>()) {
      Get.lazyPut<ThemeController>(() => ThemeController());
    }
  }
}
