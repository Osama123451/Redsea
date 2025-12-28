import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/app/controllers/theme_controller.dart';

/// الربط الأولي - يُحمّل عند بداية التطبيق
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers دائمة (permanent) - لا يتم حذفها
    try {
      Get.put(AuthController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing AuthController: $e');
    }

    try {
      Get.put(CartController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing CartController: $e');
    }

    try {
      Get.put(FavoritesController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing FavoritesController: $e');
    }

    try {
      Get.put(NotificationsController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing NotificationsController: $e');
    }

    try {
      Get.put(ChatController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing ChatController: $e');
    }

    try {
      Get.put(ThemeController(), permanent: true);
    } catch (e) {
      debugPrint('Error initializing ThemeController: $e');
    }
  }
}
