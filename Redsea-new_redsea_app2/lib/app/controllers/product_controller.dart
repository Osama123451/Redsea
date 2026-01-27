import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/services/search_service.dart';

/// متحكم المنتجات - يدير تحميل وعرض وفلترة المنتجات
class ProductController extends GetxController {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('products');
  StreamSubscription<DatabaseEvent>? _productsSubscription;

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

  /// جلب المنتجات المميزة (أعلى featuredScore)
  List<Product> get featuredProducts {
    final sorted = products.toList()
      ..sort((a, b) => b.featuredScore.compareTo(a.featuredScore));
    // فلترة المنتجات التي لديها درجة تميز > 0 أو أخذ الأحدث
    final featured = sorted.where((p) => p.featuredScore > 0).take(5).toList();
    // إذا لم يكن هناك منتجات بدرجة تميز، نأخذ الأحدث
    if (featured.isEmpty) {
      return products.take(5).toList();
    }
    return featured;
  }

  /// جلب المنتجات الأكثر مشاهدة
  List<Product> get mostViewedProducts {
    final sorted = products.toList()
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    return sorted.take(10).toList();
  }

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
    startProductsListener();
  }

  @override
  void onClose() {
    _productsSubscription?.cancel();
    super.onClose();
  }

  /// بدء مستمع المنتجات لمزامنة البيانات في الوقت الحقيقي
  void startProductsListener() {
    try {
      isLoading.value = true;
      _productsSubscription?.cancel();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      _productsSubscription = _dbRef.onValue.listen((event) {
        DataSnapshot snapshot = event.snapshot;
        List<Product> loadedProducts = [];

        if (snapshot.value != null) {
          Map<dynamic, dynamic> productsMap =
              snapshot.value as Map<dynamic, dynamic>;

          productsMap.forEach((key, value) {
            try {
              Map<String, dynamic> productData =
                  Map<String, dynamic>.from(value);
              Product product =
                  Product.fromMap({...productData, 'id': key.toString()});

              // نظام الموافقة
              if (shouldShowProduct(product, currentUserId)) {
                loadedProducts.add(product);
              }
            } catch (e) {
              debugPrint('Error parsing product $key: $e');
            }
          });

          loadedProducts.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        }

        products.value = loadedProducts;
        applyFilters();
        isLoading.value = false;
      }, onError: (error) {
        debugPrint('Error in products stream: $error');
        isLoading.value = false;
      });
    } catch (e) {
      debugPrint('Error starting products listener: $e');
      isLoading.value = false;
    }
  }

  /// هل يجب عرض المنتج للمستخدم الحالي؟
  bool shouldShowProduct(Product product, String? currentUserId) {
    bool isAdmin = false;
    try {
      if (Get.isRegistered<AuthController>()) {
        isAdmin = Get.find<AuthController>().isAdmin;
      }
    } catch (e) {
      debugPrint('Error getting isAdmin: $e');
    }

    bool isOwner = currentUserId != null && product.ownerId == currentUserId;

    return isAdmin || isOwner || (product.isApproved && product.isPublic);
  }

  /// تحميل المنتجات (للتوافق مع الكود القديم)
  Future<void> loadProducts() async {
    startProductsListener();
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

    // تطبيق فلتر القابل للمقايضة
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
