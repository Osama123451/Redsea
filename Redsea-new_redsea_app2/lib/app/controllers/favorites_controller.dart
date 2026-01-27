import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'dart:async';

/// متحكم المفضلة - يدير المنتجات المفضلة للمستخدم
class FavoritesController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // قائمة المنتجات المفضلة
  final RxList<Product> favorites = <Product>[].obs;

  // معرفات المنتجات المفضلة للتحقق السريع
  final RxSet<String> favoriteIds = <String>{}.obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;

  StreamSubscription? _authSubscription;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // الاستماع لتغيرات حالة المصادقة
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadFavorites();
      } else {
        clearLocal();
      }
    });
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  /// تحميل المفضلات من Firebase
  Future<void> loadFavorites() async {
    if (userId == null) return;

    try {
      isLoading.value = true;
      debugPrint('📥 Loading favorites for user: $userId');

      // الحصول على معرفات المفضلات
      final favSnapshot =
          await _dbRef.child('favorites').child(userId!).once().timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw Exception('Timeout'),
              );

      if (favSnapshot.snapshot.value != null) {
        final favData =
            Map<dynamic, dynamic>.from(favSnapshot.snapshot.value as Map);
        debugPrint('📥 Found ${favData.length} favorites');
        favoriteIds.assignAll(favData.keys.cast<String>());

        // تحميل تفاصيل المنتجات
        List<Product> loadedFavorites = [];
        for (String productId in favoriteIds) {
          try {
            final productSnapshot =
                await _dbRef.child('products').child(productId).once().timeout(
                      const Duration(seconds: 5),
                      onTimeout: () => throw Exception('Product timeout'),
                    );

            if (productSnapshot.snapshot.value != null) {
              final productData = Map<String, dynamic>.from(
                  productSnapshot.snapshot.value as Map);
              loadedFavorites.add(Product(
                id: productId,
                name: productData['name']?.toString() ?? '',
                price: productData['price']?.toString() ?? '0',
                description: productData['description']?.toString() ?? '',
                imageUrl: productData['imageUrl']?.toString() ?? '',
                category: productData['category']?.toString() ?? 'أخرى',
                negotiable: productData['isNegotiable'] ??
                    productData['negotiable'] ??
                    false,
                dateAdded: productData['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        int.tryParse(productData['createdAt'].toString()) ?? 0)
                    : DateTime.now(),
                ownerId: productData['userId']?.toString() ?? '',
              ));
            }
          } catch (e) {
            debugPrint('Error loading product $productId: $e');
          }
        }
        favorites.value = loadedFavorites;
        debugPrint('✅ Loaded ${loadedFavorites.length} favorite products');
      } else {
        debugPrint('📥 No favorites found for user');
        favorites.clear();
        favoriteIds.clear();
      }
    } catch (e) {
      debugPrint('❌ Error loading favorites: $e');
      favorites.clear();
      favoriteIds.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// التحقق هل المنتج في المفضلة
  bool isFavorite(String productId) {
    return favoriteIds.contains(productId);
  }

  /// إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(Product product) async {
    if (userId == null) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      if (isFavorite(product.id)) {
        // إزالة من المفضلة
        await _dbRef
            .child('favorites')
            .child(userId!)
            .child(product.id)
            .remove();

        favoriteIds.remove(product.id);
        favorites.removeWhere((p) => p.id == product.id);

        Get.snackbar(
          'تمت الإزالة',
          'تم إزالة ${product.name} من المفضلة',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        // إضافة للمفضلة
        await _dbRef.child('favorites').child(userId!).child(product.id).set({
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        });

        favoriteIds.add(product.id);
        favorites.add(product);

        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة ${product.name} للمفضلة ⭐',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (e.toString().contains('permission')) {
        Get.snackbar(
          'خطأ في الصلاحيات',
          'يرجى تحديث قواعد Firebase (Rules) للسماح بالكتابة',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('خطأ', 'حدث خطأ: $e');
      }
    }
  }

  /// مسح كل المفضلات
  Future<void> clearAllFavorites() async {
    if (userId == null) return;

    try {
      await _dbRef.child('favorites').child(userId!).remove();
      favorites.clear();
      favoriteIds.clear();
      Get.snackbar('تم', 'تم مسح جميع المفضلات');
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ: $e');
    }
  }

  /// مسح الحالة المحلية (عند تسجيل الخروج)
  void clearLocal() {
    favorites.clear();
    favoriteIds.clear();
  }

  /// عدد المفضلات
  int get favoritesCount => favorites.length;
}
