import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';

/// شاشة التحقق من المصادقة - تستبدل شاشة البداية المتحركة
/// تقوم فقط بفحص حالة المستخدم وتوجيهه للصفحة المناسبة دون تأخير
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // تشغيل الـ WidgetsBinding لضمان أن الواجهة جاهزة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _navigate();
    });
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final currentUser = FirebaseAuth.instance.currentUser;
    final authController =
        Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    if (!hasSeenOnboarding) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (currentUser != null) {
      // التحقق من الحظر
      try {
        final userRef = FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid);
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>?;
          if (userData?['is_blocked'] == true) {
            await FirebaseAuth.instance.signOut();
            if (authController != null) {
              authController.isGuestMode.value = true;
            }
            Get.offAllNamed('/main');
            Get.snackbar(
              '⛔ تم حظر الحساب',
              'تم حظر حسابك من قبل الإدارة.',
              backgroundColor: Colors.red.shade600,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking block status: $e');
      }

      if (authController != null) {
        authController.isGuestMode.value = false;
        await authController.loadUserData();
      }
      Get.offAllNamed('/main');
    } else {
      if (authController != null) {
        authController.isGuestMode.value = true;
      }
      Get.offAllNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    // شاشة بيضاء بسيطة أثناء التحقق (أجزاء من الثانية)
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
