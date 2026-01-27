import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/models/service_model.dart';
import 'dart:async';

/// متحكم السلة - يدير إضافة وحذف وتحديث المنتجات والخدمات في السلة مع Firebase
class CartController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // قائمة المنتجات في السلة
  final RxList<Product> cartItems = <Product>[].obs;

  // قائمة الخدمات في السلة
  final RxList<Service> serviceCartItems = <Service>[].obs;

  final RxBool isLoading = false.obs;

  // اشتراك حالة المصادقة
  StreamSubscription? _authSubscription;

  /// الحصول على معرف المستخدم الحالي
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // الاستماع لتغيرات حالة المصادقة
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadCart();
        loadServiceCart();
      } else {
        cartItems.clear();
        serviceCartItems.clear();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  /// تحميل سلة المنتجات من Firebase
  Future<void> loadCart() async {
    if (_userId == null) return;

    try {
      isLoading.value = true;
      final snapshot = await _dbRef.child('carts/$_userId').once().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout'),
          );

      if (snapshot.snapshot.value != null) {
        final cartData =
            Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Product> loadedItems = [];

        for (var entry in cartData.entries) {
          try {
            final productId = entry.key.toString();
            final itemData = Map<String, dynamic>.from(entry.value as Map);

            // جلب تفاصيل المنتج من قاعدة البيانات
            final productSnapshot =
                await _dbRef.child('products/$productId').once().timeout(
                      const Duration(seconds: 5),
                      onTimeout: () => throw Exception('Product timeout'),
                    );
            if (productSnapshot.snapshot.value != null) {
              final productData = Map<String, dynamic>.from(
                  productSnapshot.snapshot.value as Map);

              loadedItems.add(Product(
                id: productId,
                name: productData['name']?.toString() ?? '',
                price: productData['price']?.toString() ?? '0',
                negotiable: productData['isNegotiable'] ?? false,
                description: productData['description']?.toString() ?? '',
                category: productData['category']?.toString() ?? 'أخرى',
                imageUrl: productData['imageUrl']?.toString() ?? '',
                dateAdded: DateTime.now(),
                ownerId: productData['userId'],
                quantity: itemData['quantity'] ?? 1,
              ));
            }
          } catch (e) {
            debugPrint('Error loading cart item: $e');
          }
        }

        cartItems.value = loadedItems;
      } else {
        cartItems.clear();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل سلة الخدمات من Firebase
  Future<void> loadServiceCart() async {
    if (_userId == null) return;

    try {
      final snapshot =
          await _dbRef.child('service_carts/$_userId').once().timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw Exception('Timeout'),
              );

      if (snapshot.snapshot.value != null) {
        final cartData =
            Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Service> loadedItems = [];

        for (var entry in cartData.entries) {
          try {
            final serviceId = entry.key.toString();

            // جلب تفاصيل الخدمة من قاعدة البيانات
            final serviceSnapshot =
                await _dbRef.child('services/$serviceId').once().timeout(
                      const Duration(seconds: 5),
                      onTimeout: () => throw Exception('Service timeout'),
                    );
            if (serviceSnapshot.snapshot.value != null) {
              final serviceData = Map<dynamic, dynamic>.from(
                  serviceSnapshot.snapshot.value as Map);

              loadedItems.add(Service.fromMap(serviceId, serviceData));
            }
          } catch (e) {
            debugPrint('Error loading service cart item: $e');
          }
        }

        serviceCartItems.value = loadedItems;
      } else {
        serviceCartItems.clear();
      }
    } catch (e) {
      debugPrint('Error loading service cart: $e');
    }
  }

  /// الحصول على السعر الإجمالي للمنتجات
  double get totalProductPrice {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// الحصول على السعر الإجمالي للخدمات
  double get totalServicePrice {
    return serviceCartItems.fold(0, (sum, item) => sum + item.estimatedValue);
  }

  /// الحصول على السعر الإجمالي الكلي (منتجات + خدمات)
  double get totalPrice {
    return totalProductPrice + totalServicePrice;
  }

  /// الحصول على عدد القطع الإجمالي للمنتجات
  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// الحصول على عدد الخدمات في السلة
  int get totalServiceItems {
    return serviceCartItems.length;
  }

  /// الحصول على العدد الإجمالي (منتجات + خدمات)
  int get totalAllItems {
    return totalItems + totalServiceItems;
  }

  /// التحقق مما إذا كان المنتج في السلة
  bool isInCart(String productId) {
    return cartItems.any((item) => item.id == productId);
  }

  /// التحقق مما إذا كانت الخدمة في السلة
  bool isServiceInCart(String serviceId) {
    return serviceCartItems.any((item) => item.id == serviceId);
  }

  /// الحصول على المنتج من السلة
  Product? getCartItem(String productId) {
    try {
      return cartItems.firstWhere((item) => item.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على الخدمة من السلة
  Service? getServiceCartItem(String serviceId) {
    try {
      return serviceCartItems.firstWhere((item) => item.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على كمية المنتج في السلة
  int getQuantity(String productId) {
    return getCartItem(productId)?.quantity ?? 0;
  }

  /// إضافة منتج للسلة
  Future<void> addToCart(Product product) async {
    if (_userId == null) {
      Get.snackbar('خطأ', 'يرجى تسجيل الدخول أولاً');
      return;
    }

    // التحقق من أن المستخدم ليس صاحب المنتج
    if (product.ownerId == _userId) {
      Get.snackbar(
        'غير مسموح',
        'لا يمكنك إضافة منتجك الخاص إلى السلة',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      int index = cartItems.indexWhere((item) => item.id == product.id);
      int newQuantity = 1;

      if (index != -1) {
        // إذا كان المنتج موجود، زيادة الكمية
        newQuantity = cartItems[index].quantity + 1;
        cartItems[index] = cartItems[index].copyWith(quantity: newQuantity);
      } else {
        // إضافة منتج جديد
        cartItems.add(product.copyWith(quantity: 1));
      }

      // حفظ في Firebase
      await _dbRef.child('carts/$_userId/${product.id}').set({
        'quantity': newQuantity,
        'addedAt': ServerValue.timestamp,
      });

      Get.snackbar(
        'تمت الإضافة',
        'تم إضافة ${product.name} إلى السلة',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error adding to cart: $e');
    }
  }

  /// إضافة خدمة للسلة
  Future<void> addServiceToCart(Service service) async {
    if (_userId == null) {
      Get.snackbar('خطأ', 'يرجى تسجيل الدخول أولاً');
      return;
    }

    // التحقق من أن المستخدم ليس صاحب الخدمة
    if (service.ownerId == _userId) {
      Get.snackbar(
        'غير مسموح',
        'لا يمكنك إضافة خدمتك الخاصة إلى السلة',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // لا يمكن إضافة نفس الخدمة مرتين
    if (isServiceInCart(service.id)) {
      Get.snackbar(
        'موجودة مسبقاً',
        'هذه الخدمة موجودة في السلة بالفعل',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      // إضافة الخدمة للسلة المحلية
      serviceCartItems.add(service);

      // حفظ في Firebase
      await _dbRef.child('service_carts/$_userId/${service.id}').set({
        'addedAt': ServerValue.timestamp,
      });

      Get.snackbar(
        'تمت الإضافة',
        'تم إضافة "${service.title}" إلى السلة',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error adding service to cart: $e');
      // إزالة من السلة المحلية في حالة الفشل
      serviceCartItems.removeWhere((item) => item.id == service.id);
    }
  }

  /// إزالة منتج من السلة
  Future<void> removeFromCart(String productId) async {
    if (_userId == null) return;

    try {
      cartItems.removeWhere((item) => item.id == productId);
      await _dbRef.child('carts/$_userId/$productId').remove();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  /// إزالة خدمة من السلة
  Future<void> removeServiceFromCart(String serviceId) async {
    if (_userId == null) return;

    try {
      serviceCartItems.removeWhere((item) => item.id == serviceId);
      await _dbRef.child('service_carts/$_userId/$serviceId').remove();

      Get.snackbar(
        'تمت الإزالة',
        'تم إزالة الخدمة من السلة',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error removing service from cart: $e');
    }
  }

  /// تحديث كمية المنتج
  Future<void> updateQuantity(String productId, int quantity) async {
    if (_userId == null) return;

    try {
      int index = cartItems.indexWhere((item) => item.id == productId);

      if (index != -1) {
        if (quantity <= 0) {
          cartItems.removeAt(index);
          await _dbRef.child('carts/$_userId/$productId').remove();
        } else {
          cartItems[index] = cartItems[index].copyWith(quantity: quantity);
          await _dbRef.child('carts/$_userId/$productId').update({
            'quantity': quantity,
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  /// زيادة الكمية بواحد
  Future<void> incrementQuantity(String productId) async {
    int index = cartItems.indexWhere((item) => item.id == productId);
    if (index != -1) {
      await updateQuantity(productId, cartItems[index].quantity + 1);
    }
  }

  /// نقص الكمية بواحد
  Future<void> decrementQuantity(String productId) async {
    int index = cartItems.indexWhere((item) => item.id == productId);
    if (index != -1) {
      await updateQuantity(productId, cartItems[index].quantity - 1);
    }
  }

  /// إفراغ سلة المنتجات
  Future<void> clearCart() async {
    if (_userId != null) {
      try {
        await _dbRef.child('carts/$_userId').remove();
      } catch (e) {
        debugPrint('Error clearing cart in Firebase: $e');
      }
    }
    cartItems.clear();
  }

  /// إفراغ سلة الخدمات
  Future<void> clearServiceCart() async {
    if (_userId != null) {
      try {
        await _dbRef.child('service_carts/$_userId').remove();
      } catch (e) {
        debugPrint('Error clearing service cart in Firebase: $e');
      }
    }
    serviceCartItems.clear();
  }

  /// إفراغ السلة بالكامل (منتجات + خدمات)
  Future<void> clearAllCarts() async {
    await clearCart();
    await clearServiceCart();
  }
}
