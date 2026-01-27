import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/services/search_service.dart';
import 'package:redsea/app/controllers/product_controller.dart';

/// متحكم البحث المتقدم - يدير عمليات البحث والفلترة
/// ملاحظة: تم تسميته AppSearchController لتجنب التعارض مع SearchController من Flutter
class AppSearchController extends GetxController {
  // نتائج البحث
  final RxList<Product> searchResults = <Product>[].obs;

  // حالة البحث
  final RxBool isSearching = false.obs;
  final RxBool hasSearched = false.obs;
  final RxString searchQuery = ''.obs;

  // الفلاتر
  final RxString selectedCategory = ''.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = double.infinity.obs;
  final RxBool onlyNegotiable = false.obs;
  final RxString sortBy = 'newest'.obs; // newest, oldest, priceAsc, priceDesc
  final RxString selectedLocation = ''.obs; // فلتر الموقع الجديد

  // قائمة التصنيفات
  final List<String> categories = [
    'الكل',
    'الكترونيات',
    'أجهزة منزلية',
    'ملابس',
    'عطور',
    'ساعات',
    'سيارات',
    'أثاث',
    'أخرى',
  ];

  // خيارات الترتيب
  final Map<String, String> sortOptions = {
    'newest': 'الأحدث',
    'oldest': 'الأقدم',
    'priceAsc': 'السعر: من الأقل للأعلى',
    'priceDesc': 'السعر: من الأعلى للأقل',
  };

  // قائمة المدن اليمنية للفلترة
  final List<String> locations = [
    'الكل',
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'ذمار',
    'المكلا',
    'سيئون',
    'مأرب',
    'صعدة',
    'حجة',
    'البيضاء',
    'لحج',
    'أبين',
    'شبوة',
    'المهرة',
  ];

  /// البحث في المنتجات
  void search(String query) {
    searchQuery.value = query;
    _performSearch();
  }

  /// تطبيق الفلاتر
  void applyFilters() {
    _performSearch();
  }

  /// مسح الفلاتر
  void clearFilters() {
    selectedCategory.value = '';
    selectedLocation.value = ''; // مسح فلتر الموقع
    minPrice.value = 0.0;
    maxPrice.value = double.infinity;
    onlyNegotiable.value = false;
    sortBy.value = 'newest';
    _performSearch();
  }

  /// تنفيذ البحث
  void _performSearch() {
    try {
      isSearching.value = true;
      hasSearched.value = true;

      // الحصول على كل المنتجات من ProductController
      List<Product> allProducts = [];
      if (Get.isRegistered<ProductController>()) {
        allProducts = Get.find<ProductController>().allProducts;
      }

      List<Product> results = List.from(allProducts);

      // تطبيق البحث النصي
      if (searchQuery.value.isNotEmpty) {
        results = SearchService.smartSearch(results, searchQuery.value);
      }

      // تصفية حسب التصنيف
      if (selectedCategory.value.isNotEmpty &&
          selectedCategory.value != 'الكل') {
        results =
            results.where((p) => p.category == selectedCategory.value).toList();
      }

      // تصفية حسب السعر
      results = results.where((p) {
        final price =
            double.tryParse(p.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return price >= minPrice.value &&
            (maxPrice.value == double.infinity || price <= maxPrice.value);
      }).toList();

      // تصفية قابل للمقايضة فقط
      if (onlyNegotiable.value) {
        results = results.where((p) => p.negotiable).toList();
      }

      // تصفية حسب الموقع (فلتر جديد)
      if (selectedLocation.value.isNotEmpty &&
          selectedLocation.value != 'الكل') {
        results = results
            .where((p) => p.location?.contains(selectedLocation.value) ?? false)
            .toList();
      }

      // الترتيب
      switch (sortBy.value) {
        case 'newest':
          results.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
          break;
        case 'oldest':
          results.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
          break;
        case 'priceAsc':
          results.sort((a, b) {
            final priceA =
                double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0;
            final priceB =
                double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0;
            return priceA.compareTo(priceB);
          });
          break;
        case 'priceDesc':
          results.sort((a, b) {
            final priceA =
                double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0;
            final priceB =
                double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0;
            return priceB.compareTo(priceA);
          });
          break;
      }

      searchResults.value = results;
    } catch (e) {
      debugPrint('Error performing search: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// عدد النتائج
  int get resultsCount => searchResults.length;

  /// هل يوجد فلاتر مفعلة
  bool get hasActiveFilters =>
      selectedCategory.value.isNotEmpty ||
      selectedLocation.value.isNotEmpty || // فلتر الموقع
      minPrice.value > 0 ||
      maxPrice.value != double.infinity ||
      onlyNegotiable.value ||
      sortBy.value != 'newest';
}
