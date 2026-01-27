import 'package:get/get.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';

/// Binding لصفحة الإشعارات
class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}
