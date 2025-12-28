import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:redsea/app/routes/app_routes.dart';
import 'cart_controller.dart';
import 'favorites_controller.dart';

/// متحكم المصادقة - يدير تسجيل الدخول والخروج وحالة المستخدم
class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');

  // الحالة المرصودة
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hidePassword = true.obs;
  final RxBool isGuestMode = false.obs; // وضع الزائر

  // معلومات المستخدم
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // مراقبة تغيرات حالة المصادقة
    currentUser.bindStream(_auth.authStateChanges());
    ever(currentUser, _handleAuthStateChange);
  }

  void _handleAuthStateChange(User? user) {
    if (user != null) {
      loadUserData();
    } else {
      userData.clear();
    }
  }

  /// تحميل بيانات المستخدم من قاعدة البيانات
  Future<void> loadUserData() async {
    if (currentUser.value != null) {
      try {
        DatabaseEvent event = await _dbRef.child(currentUser.value!.uid).once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          userData.value = data;

          // التحقق من الحظر أثناء تحميل البيانات
          if (data['isBanned'] == true) {
            await logout();
            Get.defaultDialog(
              title: 'تم حظر الحساب',
              middleText:
                  'تم حظر حسابك من قبل الإدارة. لا يمكنك الوصول للتطبيق.',
              textConfirm: 'حسناً',
              confirmTextColor: Colors.white,
              onConfirm: () => Get.back(),
              barrierDismissible: false,
            );
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  /// تسجيل الدخول بالهاتف وكلمة المرور
  Future<bool> login(String phone, String password) async {
    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رقم الهاتف وكلمة المرور',
          backgroundColor: Get.theme.colorScheme.error);
      return false;
    }

    // تنظيف رقم الهاتف
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    isLoading.value = true;

    try {
      // البحث عن المستخدم بالرقم
      DataSnapshot snapshot =
          await _dbRef.orderByChild('phone').equalTo(phone).get();

      if (!snapshot.exists) {
        Get.snackbar('خطأ', 'رقم الهاتف غير موجود');
        return false;
      }

      Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
      String userEmail = '';
      String userId = '';
      bool passwordCorrect = false;

      users.forEach((key, value) {
        try {
          if (value['password'] != null) {
            String storedPassword =
                utf8.decode(base64Decode(value['password']));
            if (storedPassword == password) {
              passwordCorrect = true;
              userEmail = value['email']?.toString() ?? '';
              userId = key.toString();
            }
          }
        } catch (e) {
          debugPrint('Error decoding password: $e');
        }
      });

      if (!passwordCorrect) {
        Get.snackbar('خطأ', 'كلمة المرور غير صحيحة');
        return false;
      }

      if (userEmail.isEmpty) {
        Get.snackbar('خطأ', 'خطأ في بيانات المستخدم');
        return false;
      }

      await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );

      await _dbRef.child(userId).update({
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
      });

      Get.snackbar('نجاح', 'تم تسجيل الدخول بنجاح ✅');
      Get.offAllNamed(AppRoutes.home);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ في المصادقة!';
      if (e.code == 'user-not-found') msg = 'الحساب غير موجود.';
      if (e.code == 'wrong-password') msg = 'كلمة المرور غير صحيحة.';
      if (e.code == 'invalid-email') msg = 'صيغة الإيميل غير صحيحة.';
      if (e.code == 'user-disabled') msg = 'هذا الحساب معطل.';
      if (e.code == 'too-many-requests') msg = 'محاولات كثيرة، حاول لاحقاً.';
      Get.snackbar('خطأ', msg);
      return false;
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ غير متوقع: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _auth.signOut();
      userData.clear();

      try {
        if (Get.isRegistered<CartController>()) {
          Get.find<CartController>().clearCart();
        }
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().clearLocal();
        }
        // ChatController و NotificationsController يتعاملان مع التنظيف تلقائياً
        // عبر authStateChanges listener
      } catch (e) {
        debugPrint('Error clearing controllers: $e');
      }

      // تأخير قصير للسماح بتنظيف الـ subscriptions قبل الانتقال
      await Future.delayed(const Duration(milliseconds: 100));

      Get.offAllNamed(AppRoutes.first);
      Get.snackbar('نجاح', 'تم تسجيل الخروج');
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في تسجيل الخروج: $e');
    }
  }

  /// تبديل إظهار/إخفاء كلمة المرور
  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  /// التحقق من تسجيل الدخول
  bool get isLoggedIn => currentUser.value != null;

  /// الحصول على معرف المستخدم الحالي
  String? get userId => currentUser.value?.uid;

  /// الحصول على اسم المستخدم
  String get userName =>
      userData['name'] ?? currentUser.value?.displayName ?? 'زائر';

  /// الحصول على البريد الإلكتروني
  String get userEmail => userData['email'] ?? currentUser.value?.email ?? '';

  /// الدخول كزائر (التصفح فقط)
  void enterGuestMode() {
    isGuestMode.value = true;
    Get.offAllNamed(AppRoutes.home);
  }

  /// الخروج من وضع الزائر
  void exitGuestMode() {
    isGuestMode.value = false;
    Get.offAllNamed(AppRoutes.first);
  }

  /// التحقق من تسجيل الدخول وعرض رسالة للزائر
  /// يُستخدم قبل أي إجراء يتطلب تسجيل الدخول
  bool requireLogin({String message = 'يجب تسجيل الدخول للقيام بهذا الإجراء'}) {
    if (isGuestMode.value || currentUser.value == null) {
      Get.dialog(
        AlertDialog(
          title: const Text('تسجيل الدخول مطلوب', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                isGuestMode.value = false;
                Get.offAllNamed(AppRoutes.login);
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  /// هل المستخدم زائر؟
  bool get isGuest => isGuestMode.value || currentUser.value == null;

  /// هل يمكن للمستخدم القيام بإجراءات؟
  bool get canPerformActions => !isGuestMode.value && currentUser.value != null;

  // ===================== نظام الأدوار =====================

  /// رقم هاتف الأدمن الرئيسي
  static const String adminPhone = '775378412';

  /// أرقام هواتف المسؤولين
  static const List<String> adminPhones = [
    adminPhone,
  ];

  /// هل المستخدم مسؤول (أدمن)؟
  bool get isAdmin {
    if (userData['role'] == 'admin') return true;
    final userPhone = userData['phone']?.toString() ?? '';
    return adminPhones.contains(userPhone);
  }

  /// الحصول على دور المستخدم
  String get userRole => isAdmin ? 'مسؤول' : 'مستخدم';

  // ==================== صلاحيات المستخدمين ====================

  /// إضافة منتج
  bool get canAddProduct => canPerformActions;

  /// تعديل منتج (الأدمن = أي منتج، المستخدم = منتجاته فقط)
  bool canEditProduct(String productOwnerId) {
    if (!canPerformActions) return false;
    if (isAdmin) return true;
    return userId == productOwnerId;
  }

  /// حذف منتج (الأدمن = أي منتج، المستخدم = منتجاته فقط)
  bool canDeleteProduct(String productOwnerId) {
    if (!canPerformActions) return false;
    if (isAdmin) return true;
    return userId == productOwnerId;
  }

  /// المفضلة والسلة والتعليقات
  bool get canAddToFavorites => canPerformActions;
  bool get canAddToCart => canPerformActions;
  bool get canComment => canPerformActions;

  /// حذف تعليق (الأدمن = أي تعليق، المستخدم = تعليقاته فقط)
  bool canDeleteComment(String commentOwnerId) {
    if (!canPerformActions) return false;
    if (isAdmin) return true;
    return userId == commentOwnerId;
  }

  /// صلاحيات الأدمن فقط
  bool get canViewAllUsers => isAdmin;
  bool get canViewAllOrders => isAdmin;
  bool get canManageUsers => isAdmin;
  bool get canViewStats => isAdmin;
  bool get canBanUsers => isAdmin;
  bool get canDeleteAnyProduct => isAdmin;
  bool get canDeleteAnyComment => isAdmin;

  /// التحقق من صلاحية الأدمن
  bool requireAdmin({String message = 'هذه الميزة متاحة للمسؤولين فقط'}) {
    if (!isAdmin) {
      Get.snackbar('غير مصرح', message,
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  /// رسالة عدم الصلاحية
  void showNoPermission([String? msg]) {
    Get.snackbar('غير مصرح', msg ?? 'ليس لديك صلاحية',
        backgroundColor: Colors.orange, colorText: Colors.white);
  }
}
