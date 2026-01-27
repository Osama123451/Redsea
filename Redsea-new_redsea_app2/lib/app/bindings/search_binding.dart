import 'package:get/get.dart';
import 'package:redsea/app/controllers/search_controller.dart';

/// Binding لصفحة البحث
class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppSearchController>(() => AppSearchController());
  }
}
