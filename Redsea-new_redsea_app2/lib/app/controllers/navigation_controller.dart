import 'package:get/get.dart';

/// NavigationController - إدارة التنقل بين الصفحات الرئيسية
/// يستخدم GetX للتفاعل مع التغييرات في الفهرس الحالي
class NavigationController extends GetxController {
  /// الفهرس الحالي للصفحة المحددة
  /// 0: الرئيسية
  /// 1: الفئات
  /// 2: الطلبات
  /// 3: حسابي
  final currentIndex = 0.obs;

  /// تغيير الصفحة الحالية
  void changePage(int index) {
    if (index >= 0 && index <= 3) {
      currentIndex.value = index;
    }
  }

  /// الانتقال للصفحة الرئيسية
  void goToHome() => changePage(0);

  /// الانتقال لصفحة الفئات
  void goToCategories() => changePage(1);

  /// الانتقال لصفحة الطلبات
  void goToOrders() => changePage(2);

  /// الانتقال لصفحة الحساب
  void goToProfile() => changePage(3);

  /// التحقق من الصفحة المحددة
  bool isSelected(int index) => currentIndex.value == index;
}
