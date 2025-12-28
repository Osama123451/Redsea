import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// متحكم لوحة تحكم المسؤول - يدير إحصائيات وعمليات المسؤول
class AdminController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // الإحصائيات
  final RxInt usersCount = 0.obs;
  final RxInt productsCount = 0.obs;
  final RxInt ordersCount = 0.obs;
  final RxInt pendingOrdersCount = 0.obs;

  // قوائم البيانات
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  /// تحميل الإحصائيات
  Future<void> loadStats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // تحميل عدد المستخدمين
      final usersSnapshot = await _dbRef.child('users').once();
      if (usersSnapshot.snapshot.value != null) {
        final usersMap = usersSnapshot.snapshot.value as Map;
        usersCount.value = usersMap.length;
      }

      // تحميل عدد المنتجات
      final productsSnapshot = await _dbRef.child('products').once();
      if (productsSnapshot.snapshot.value != null) {
        final productsMap = productsSnapshot.snapshot.value as Map;
        productsCount.value = productsMap.length;
      }

      // تحميل عدد الطلبات
      final ordersSnapshot = await _dbRef.child('orders').once();
      if (ordersSnapshot.snapshot.value != null) {
        final ordersMap = ordersSnapshot.snapshot.value as Map;
        ordersCount.value = ordersMap.length;

        // حساب الطلبات المعلقة
        int pending = 0;
        ordersMap.forEach((key, value) {
          if (value['status'] == 'pending' ||
              value['status'] == 'pending_verification') {
            pending++;
          }
        });
        pendingOrdersCount.value = pending;
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      errorMessage.value = 'خطأ في تحميل الإحصائيات';
    } finally {
      isLoading.value = false;
    }
  }

  /// تحميل قائمة المستخدمين
  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final snapshot = await _dbRef.child('users').once();

      if (snapshot.snapshot.value != null) {
        final usersMap = snapshot.snapshot.value as Map;
        users.clear();

        usersMap.forEach((key, value) {
          // استبعاد المستخدم الحالي (الأدمن)
          if (key != currentUserId) {
            users.add({
              'id': key,
              ...Map<String, dynamic>.from(value as Map),
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// حظر/إلغاء حظر مستخدم
  Future<void> toggleUserBan(String userId, bool ban) async {
    try {
      await _dbRef.child('users/$userId').update({
        'isBanned': ban,
        'bannedAt': ban ? ServerValue.timestamp : null,
      });

      // تحديث القائمة المحلية
      final index = users.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        users[index]['isBanned'] = ban;
        users.refresh();
      }

      Get.snackbar(
        'تم',
        ban ? 'تم حظر المستخدم' : 'تم إلغاء حظر المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error toggling user ban: $e');
      Get.snackbar('خطأ', 'فشل في تحديث حالة المستخدم');
    }
  }

  /// حذف منتج
  Future<void> deleteProduct(String productId) async {
    try {
      await _dbRef.child('products/$productId').remove();
      products.removeWhere((p) => p['id'] == productId);
      productsCount.value--;

      Get.snackbar('تم', 'تم حذف المنتج بنجاح');
    } catch (e) {
      debugPrint('Error deleting product: $e');
      Get.snackbar('خطأ', 'فشل في حذف المنتج');
    }
  }

  /// إرسال إشعار عام لجميع المستخدمين
  Future<void> sendGeneralNotification(String title, String body) async {
    try {
      final usersSnapshot = await _dbRef.child('users').once();

      if (usersSnapshot.snapshot.value != null) {
        final usersMap = usersSnapshot.snapshot.value as Map;

        for (var userId in usersMap.keys) {
          await _dbRef.child('notifications/$userId').push().set({
            'title': title,
            'body': body,
            'type': 'general',
            'isRead': false,
            'createdAt': ServerValue.timestamp,
          });
        }

        Get.snackbar('تم', 'تم إرسال الإشعار لجميع المستخدمين');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      Get.snackbar('خطأ', 'فشل في إرسال الإشعار');
    }
  }

  /// تحديث حالة طلب
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _dbRef.child('orders/$orderId').update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });

      Get.snackbar('تم', 'تم تحديث حالة الطلب');
      await loadStats(); // إعادة تحميل الإحصائيات
    } catch (e) {
      debugPrint('Error updating order status: $e');
      Get.snackbar('خطأ', 'فشل في تحديث حالة الطلب');
    }
  }
}
