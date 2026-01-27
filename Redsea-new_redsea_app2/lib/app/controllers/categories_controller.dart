import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:redsea/app/core/app_constants.dart';
import 'package:firebase_database/firebase_database.dart';

/// متحكم التصنيفات - يدير عرض واختيار التصنيفات
class CategoriesController extends GetxController {
  // التصنيف المحدد حالياً
  final RxString selectedCategory = ''.obs;

  // قائمة التصنيفات
  final RxList<String> categories = <String>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;

  final DatabaseReference _categoriesRef =
      FirebaseDatabase.instance.ref().child('categories');

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// تحميل التصنيفات (الثابتة + المخصصة من Firebase)
  Future<void> loadCategories() async {
    isLoading.value = true;

    // البدء بالتصنيفات الأساسية (بدون "الكل" لأنها موجودة في زر "عرض الكل")
    List<String> allCategories = [...AppConstants.categories];

    try {
      // تحميل التصنيفات المخصصة من Firebase
      final snapshot = await _categoriesRef.get();
      if (snapshot.exists && snapshot.value != null) {
        List<String> customCategories = [];

        if (snapshot.value is Map) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          data.forEach((key, value) {
            String categoryName = '';

            // دعم الحالتين: نص مباشر أو Map مع 'name'
            if (value is String) {
              categoryName = value;
            } else if (value is Map) {
              final catData = Map<String, dynamic>.from(value);
              categoryName = catData['name']?.toString() ?? '';
            }

            // التحقق من أن التصنيف غير موجود في القائمة الأساسية
            if (categoryName.isNotEmpty &&
                !AppConstants.categories.contains(categoryName) &&
                categoryName != 'الكل' &&
                !customCategories.contains(categoryName)) {
              customCategories.add(categoryName);
            }
          });
        } else if (snapshot.value is List) {
          final list = snapshot.value as List<dynamic>;
          for (var item in list) {
            if (item != null) {
              String categoryName = item.toString();
              if (categoryName.isNotEmpty &&
                  !AppConstants.categories.contains(categoryName) &&
                  categoryName != 'الكل' &&
                  !customCategories.contains(categoryName)) {
                customCategories.add(categoryName);
              }
            }
          }
        }

        // إضافة التصنيفات المخصصة قبل "أخرى"
        if (customCategories.isNotEmpty) {
          final otherIndex = allCategories.indexOf('أخرى');
          if (otherIndex != -1) {
            allCategories.insertAll(otherIndex, customCategories);
          } else {
            allCategories.addAll(customCategories);
          }
        }
      }
    } catch (e) {
      // في حالة الخطأ، نستخدم التصنيفات الأساسية فقط
      debugPrint('Error loading custom categories: $e');
    }

    categories.value = allCategories;
    isLoading.value = false;
  }

  /// إعادة تحميل التصنيفات
  Future<void> refreshCategories() async {
    await loadCategories();
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
      case 'خدمات':
        return '🔧';
      case 'أخرى':
        return '📦';
      case 'الكل':
        return '🔍';
      default:
        return '📦'; // أيقونة افتراضية للتصنيفات المخصصة
    }
  }
}
