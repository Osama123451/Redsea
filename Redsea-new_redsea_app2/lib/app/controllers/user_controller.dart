import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// متحكم المستخدم - يدير بيانات الملف الشخصي
class UserController extends GetxController {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');

  // الحالة المرصودة
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  /// تحميل بيانات المستخدم
  Future<void> loadUserData() async {
    if (currentUser != null) {
      try {
        isLoading.value = true;
        DatabaseEvent event = await _dbRef.child(currentUser!.uid).once();
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          userData.value = Map<String, dynamic>.from(snapshot.value as Map);
        } else {
          await createUserData();
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// إنشاء بيانات مستخدم جديد
  Future<void> createUserData() async {
    if (currentUser != null) {
      try {
        await _dbRef.child(currentUser!.uid).set({
          'name': currentUser?.displayName ?? 'مستخدم جديد',
          'phone': currentUser?.phoneNumber ?? 'لم يضف رقم',
          'email': currentUser?.email ?? 'لم يضف بريد',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        await loadUserData();
      } catch (e) {
        debugPrint('Error creating user data: $e');
      }
    }
  }

  /// تحديث اسم المستخدم
  Future<void> updateUserName(String newName) async {
    if (currentUser != null && newName.trim().isNotEmpty) {
      try {
        await _dbRef.child(currentUser!.uid).update({
          'name': newName.trim(),
        });
        userData['name'] = newName.trim();
        Get.snackbar('نجاح', 'تم تحديث الاسم بنجاح');
      } catch (e) {
        Get.snackbar('خطأ', 'خطأ في التحديث: $e');
      }
    }
  }

  /// تغيير كلمة المرور
  Future<void> changePassword() async {
    try {
      if (currentUser?.email != null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: currentUser!.email!,
        );
        Get.snackbar('نجاح', 'تم إرسال رابط إعادة تعيين كلمة المرور');
      } else {
        Get.snackbar('خطأ', 'لا يوجد بريد إلكتروني مرتبط بحسابك');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ: $e');
    }
  }

  /// حذف الحساب
  Future<bool> deleteAccount() async {
    try {
      if (currentUser != null) {
        await _dbRef.child(currentUser!.uid).remove();
        await currentUser!.delete();
        Get.snackbar('نجاح', 'تم حذف الحساب بنجاح');
        return true;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في حذف الحساب: $e');
    }
    return false;
  }

  /// الحصول على اسم المستخدم
  String get userName => userData['name'] ?? 'مستخدم';

  /// الحصول على البريد الإلكتروني
  String get userEmail => userData['email'] ?? 'لا يوجد بريد';

  /// الحصول على رقم الهاتف
  String get userPhone => userData['phone'] ?? 'لا يوجد رقم';

  /// الحصول على الحرف الأول من الاسم
  String get userInitial => (userData['name']?[0] ?? 'م').toUpperCase();
}
