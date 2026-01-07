import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/services/search_service.dart';

/// متحكم المنتجات - يدير تحميل وعرض وفلترة المنتجات
class ProductController extends GetxController {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('products');

  // الحالة المرصودة
  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'أخر المنتجات'.obs;
  final RxString searchQuery = ''.obs;

  // قائمة الفلاتر المتاحة
  final List<String> filters = [
    'أخر المنتجات',
    'قابل للمقايضة',
    'الأقل سعراً',
    'الكل'
  ];

  // متغيرات البحث المتقدم
  double? _minPrice;
  double? _maxPrice;
  bool _negotiableOnly = false;
  String _advancedSortBy = 'الأحدث';

  /// Getter لكل المنتجات (للبحث المتقدم)
  List<Product> get allProducts => products.toList();

  /// تطبيق الفلاتر المتقدمة
  void applyAdvancedFilters({
    double? minPrice,
    double? maxPrice,
    bool negotiableOnly = false,
    String sortBy = 'الأحدث',
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _negotiableOnly = negotiableOnly;
    _advancedSortBy = sortBy;
    applyFilters();
  }

  /// مسح الفلاتر المتقدمة
  void clearAdvancedFilters() {
    _minPrice = null;
    _maxPrice = null;
    _negotiableOnly = false;
    _advancedSortBy = 'الأحدث';
    applyFilters();
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  /// تحميل المنتجات من قاعدة البيانات
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      DatabaseEvent event = await _dbRef.orderByChild('createdAt').once();
      DataSnapshot snapshot = event.snapshot;

      List<Product> loadedProducts = [];

      if (snapshot.value != null) {
        Map<dynamic, dynamic> productsMap =
            snapshot.value as Map<dynamic, dynamic>;

        productsMap.forEach((key, value) {
          try {
            Map<String, dynamic> productData = Map<String, dynamic>.from(value);

            Product product = Product(
              id: productData['id']?.toString() ?? key.toString(),
              name: productData['name']?.toString() ?? '',
              price: productData['price']?.toString() ?? '0',
              negotiable: productData['isNegotiable'] ?? false,
              description: productData['description']?.toString() ?? '',
              category: productData['category']?.toString() ?? 'أخرى',
              imageUrl: productData['imageUrl']?.toString() ?? '',
              dateAdded: productData['createdAt'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      int.parse(productData['createdAt'].toString()))
                  : DateTime.now(),
              ownerId: productData['sellerId'] ??
                  productData['userId'] ??
                  productData['ownerId'],
            );
            loadedProducts.add(product);
          } catch (e) {
            debugPrint('Error parsing product $key: $e');
          }
        });

        loadedProducts.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      }

      products.value = loadedProducts;
      applyFilters();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تطبيق الفلاتر على المنتجات
  void applyFilters() {
    List<Product> filtered = List.from(products);

    // تطبيق البحث أولاً
    if (searchQuery.value.isNotEmpty) {
      filtered = SearchService.smartSearch(filtered, searchQuery.value);
    }

    // تطبيق فلتر السعر الأدنى
    if (_minPrice != null) {
      filtered = filtered.where((p) {
        double productPrice =
            double.tryParse(p.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return productPrice >= _minPrice!;
      }).toList();
    }

    // تطبيق فلتر السعر الأعلى
    if (_maxPrice != null) {
      filtered = filtered.where((p) {
        double productPrice =
            double.tryParse(p.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return productPrice <= _maxPrice!;
      }).toList();
    }

    // تطبيق فلتر القابل للتفاوض
    if (_negotiableOnly) {
      filtered = filtered.where((p) => p.negotiable).toList();
    }

    // ثم تطبيق الفلتر المحدد (التصنيفات)
    switch (selectedFilter.value) {
      case 'قابل للمقايضة':
        filtered = filtered.where((product) => product.negotiable).toList();
        break;
      case 'الأقل سعراً':
        filtered.sort((a, b) {
          double priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0.0;
          double priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'أخر المنتجات':
        // سيتم ترتيبه لاحقاً
        break;
      case 'الكل':
        break;
      default:
        // إذا لم يكن من الفلاتر الثابتة، نعتبره اسم تصنيف ونفلتر بناءً عليه
        if (selectedFilter.value != 'أخر المنتجات' &&
            selectedFilter.value != 'قابل للمقايضة' &&
            selectedFilter.value != 'الأقل سعراً') {
          filtered = filtered
              .where((product) => product.category == selectedFilter.value)
              .toList();
        }
        break;
    }

    // تطبيق الترتيب المتقدم
    switch (_advancedSortBy) {
      case 'الأحدث':
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'الأقدم':
        filtered.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case 'السعر: الأقل':
        filtered.sort((a, b) {
          double priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          double priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'السعر: الأعلى':
        filtered.sort((a, b) {
          double priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          double priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'أبجدياً':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    filteredProducts.value = filtered;
  }

  /// تغيير الفلتر المحدد
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  /// تحديث نص البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  /// مسح البحث
  void clearSearch() {
    searchQuery.value = '';
    applyFilters();
  }

  /// تنسيق التاريخ
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'قبل ${(difference.inDays / 7).floor()} أسابيع';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
