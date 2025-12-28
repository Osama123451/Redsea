import 'package:get/get.dart';
import 'package:redsea/app/core/app_constants.dart';

/// متحكم التصنيفات - يدير عرض واختيار التصنيفات
class CategoriesController extends GetxController {
  // التصنيف المحدد حالياً
  final RxString selectedCategory = ''.obs;

  // قائمة التصنيفات
  final RxList<String> categories = <String>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// تحميل التصنيفات
  void loadCategories() {
    // استخدام التصنيفات من الثوابت
    categories.value = ['الكل', ...AppConstants.categories];
  }

  /// اختيار تصنيف
  void selectCategory(String category) {
    if (category == 'الكل') {
      selectedCategory.value = '';
    } else {
      selectedCategory.value = category;
    }
  }

  /// مسح الاختيار
  void clearSelection() {
    selectedCategory.value = '';
  }

  /// التحقق إذا كان التصنيف محدد
  bool isSelected(String category) {
    if (category == 'الكل' && selectedCategory.value.isEmpty) {
      return true;
    }
    return selectedCategory.value == category;
  }

  /// الحصول على أيقونة التصنيف
  String getCategoryIcon(String category) {
    switch (category) {
      case 'الكترونيات':
        return '📱';
      case 'أجهزة منزلية':
        return '🏠';
      case 'ملابس':
        return '👕';
      case 'عطور':
        return '🧴';
      case 'ساعات':
        return '⌚';
      case 'سيارات':
        return '🚗';
      case 'أثاث':
        return '🛋️';
      case 'أخرى':
        return '📦';
      case 'الكل':
        return '🔍';
      default:
        return '📦';
    }
  }
}
