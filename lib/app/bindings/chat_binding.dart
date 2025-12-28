import 'package:get/get.dart';
import 'package:redsea/app/controllers/chat_controller.dart';

/// Binding للمحادثات
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}
