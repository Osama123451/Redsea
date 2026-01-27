import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/services/search_service.dart';

/// متحكم الفلترة المتقدمة
/// يدير جميع خيارات الفلترة والنتائج
class FilterController extends GetxController {
  // القسم المختار
  final RxString selectedCategory = ''.obs;

  // الموقع
  final RxString selectedCity = ''.obs;
  final RxString selectedArea = ''.obs;

  // نطاق السعر
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 0.0.obs;
  final RxString currency = 'ريال'.obs;

  // الخيارات الإضافية
  final RxBool hasImages = false.obs;
  final RxBool hasVideo = false.obs;
  final RxBool isFeatured = false.obs;
  final RxBool hasDelivery = false.obs;
  final RxBool isBarterOnly = false.obs; // للمقايضة
  final RxBool isOfferOnly = false.obs; // للعروض الخاصة

  // التقييم
  final RxInt minRating = 0.obs; // 0 = أي تقييم، 3 = 3+، 4 = 4+

  // نتائج البحث
  final RxList<Product> filteredResults = <Product>[].obs;
  final RxBool isLoading = false.obs;

  // نص البحث
  final RxString searchQuery = ''.obs;

  // قائمة المدن اليمنية
  final List<String> cities = [
    'الكل',
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'ذمار',
    'المكلا',
    'سيئون',
    'عمران',
    'صعدة',
    'حجة',
    'مأرب',
    'البيضاء',
    'لحج',
    'أبين',
    'شبوة',
    'المهرة',
    'سقطرى',
  ];

  // قائمة الأقسام
  final List<Map<String, dynamic>> categories = [
    {'name': 'الكل', 'icon': Icons.apps, 'color': Colors.blue},
    {'name': 'سيارات', 'icon': Icons.directions_car, 'color': Colors.red},
    {'name': 'عقارات', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'موبايلات', 'icon': Icons.phone_android, 'color': Colors.blue},
    {'name': 'الكترونيات', 'icon': Icons.computer, 'color': Colors.indigo},
    {'name': 'وظائف', 'icon': Icons.work, 'color': Colors.teal},
    {'name': 'خدمات', 'icon': Icons.build, 'color': Colors.orange},
    {'name': 'أثاث', 'icon': Icons.chair, 'color': Colors.brown},
    {'name': 'ملابس', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'ساعات', 'icon': Icons.watch, 'color': Colors.amber},
    {'name': 'عطور', 'icon': Icons.spa, 'color': Colors.purple},
    {'name': 'خبرات', 'icon': Icons.psychology, 'color': Colors.deepPurple},
  ];

  // عدد الفلاتر النشطة
  int get activeFiltersCount {
    int count = 0;
    if (selectedCategory.value.isNotEmpty && selectedCategory.value != 'الكل')
      count++;
    if (selectedCity.value.isNotEmpty && selectedCity.value != 'الكل') count++;
    if (minPrice.value > 0) count++;
    if (maxPrice.value > 0) count++;
    if (hasImages.value) count++;
    if (hasVideo.value) count++;
    if (isFeatured.value) count++;
    if (hasDelivery.value) count++;
    if (minRating.value > 0) count++;
    if (isBarterOnly.value) count++;
    if (isOfferOnly.value) count++;
    return count;
  }

  /// تحديث القسم
  void setCategory(String category) {
    selectedCategory.value = category == 'الكل' ? '' : category;
    // إعادة تعيين الأنماط الخاصة عند اختيار قسم عادي
    isBarterOnly.value = false;
    isOfferOnly.value = false;
  }

  /// تفعيل وضع المقايضة
  void setBarterMode() {
    clearAllFilters();
    isBarterOnly.value = true;
    selectedCategory.value = 'مقايضة';
    applyFilters();
  }

  /// تفعيل وضع العروض
  void setOffersMode() {
    clearAllFilters();
    isOfferOnly.value = true;
    selectedCategory.value = 'عروض خاصة';
    applyFilters();
  }

  /// تحديث المدينة
  void setCity(String city) {
    selectedCity.value = city == 'الكل' ? '' : city;
    selectedArea.value = ''; // إعادة تعيين المنطقة
  }

  /// تحديث نطاق السعر
  void setPriceRange(double min, double max) {
    minPrice.value = min;
    maxPrice.value = max;
  }

  /// تحديث العملة
  void setCurrency(String curr) {
    currency.value = curr;
  }

  /// تحديث التقييم
  void setMinRating(int rating) {
    minRating.value = rating;
  }

  /// تحديث نص البحث
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  @override
  void onInit() {
    super.onInit();
    // استماع للتحديثات من ProductController لتطبيق الفلترة تلقائياً
    if (Get.isRegistered<ProductController>()) {
      ever(Get.find<ProductController>().products, (_) => applyFilters());
    }
  }

  /// مسح جميع الفلاتر
  void clearAllFilters() {
    selectedCategory.value = '';
    selectedCity.value = '';
    selectedArea.value = '';
    minPrice.value = 0;
    maxPrice.value = 0;
    currency.value = 'ريال';
    hasImages.value = false;
    hasVideo.value = false;
    isFeatured.value = false;
    hasDelivery.value = false;
    minRating.value = 0;
    searchQuery.value = '';
    isBarterOnly.value = false;
    isOfferOnly.value = false;
  }

  /// تطبيق الفلترة والحصول على النتائج
  Future<void> applyFilters() async {
    isLoading.value = true;

    try {
      // الحصول على جميع المنتجات
      final productController = Get.find<ProductController>();
      List<Product> results = productController.allProducts.toList();

      // فلترة حسب نص البحث (استخدام البحث الذكي الخوارزمي)
      if (searchQuery.value.isNotEmpty) {
        results = SearchService.smartSearch(results, searchQuery.value);
      }

      // فلترة حسب المقايضة
      if (isBarterOnly.value) {
        results = results.where((p) => p.negotiable).toList();
      }

      // فلترة حسب العروض الخاصة
      if (isOfferOnly.value) {
        results = results.where((p) => p.isSpecialOffer).toList();
      }

      // فلترة حسب القسم (إذا لم نكن في وضع خاص)
      if (selectedCategory.value.isNotEmpty &&
          !isBarterOnly.value &&
          !isOfferOnly.value) {
        results =
            results.where((p) => p.category == selectedCategory.value).toList();
      }

      // فلترة حسب المدينة
      if (selectedCity.value.isNotEmpty) {
        results = results
            .where((p) => p.location?.contains(selectedCity.value) ?? false)
            .toList();
      }

      // فلترة حسب السعر الأدنى
      if (minPrice.value > 0) {
        results =
            results.where((p) => p.priceAsDouble >= minPrice.value).toList();
      }

      // فلترة حسب السعر الأعلى
      if (maxPrice.value > 0) {
        results =
            results.where((p) => p.priceAsDouble <= maxPrice.value).toList();
      }

      // فلترة حسب وجود صور
      if (hasImages.value) {
        results = results.where((p) => p.imageUrl.isNotEmpty).toList();
      }

      // فلترة حسب المنتجات المميزة
      if (isFeatured.value) {
        results = results.where((p) => p.isSpecialOffer).toList();
      }

      // ترتيب حسب الأحدث
      results.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      filteredResults.value = results;
    } catch (e) {
      debugPrint('Error applying filters: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// الحصول على أيقونة القسم
  IconData getCategoryIcon(String categoryName) {
    final cat = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'icon': Icons.category},
    );
    return cat['icon'] as IconData;
  }

  /// الحصول على لون القسم
  Color getCategoryColor(String categoryName) {
    final cat = categories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => {'color': Colors.grey},
    );
    return cat['color'] as Color;
  }
}
