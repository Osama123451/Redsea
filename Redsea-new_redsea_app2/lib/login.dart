import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/auth/mfa_verification_page.dart';
import 'package:redsea/services/mfa_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;
  bool _rememberMe = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userLookupRef =
      FirebaseDatabase.instance.ref().child('user_lookup');

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    setState(() => _loading = true);

    try {
      DataSnapshot snapshot = await _userLookupRef.child(phone).get().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال - تأكد من اتصالك بالإنترنت');
        },
      );

      if (!snapshot.exists) {
        _showError('رقم الهاتف غير مسجل');
        return;
      }

      Map<dynamic, dynamic> lookupData =
          snapshot.value as Map<dynamic, dynamic>;
      String userEmail = lookupData['email']?.toString() ?? '';

      if (userEmail.isEmpty) {
        _showError('خطأ في بيانات المستخدم');
        return;
      }

      final userCredential = await _auth
          .signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('انتهت مهلة تسجيل الدخول');
        },
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        _showError('خطأ في تسجيل الدخول');
        return;
      }

      // التحقق من حالة الحظر
      final userRef =
          FirebaseDatabase.instance.ref().child('users').child(userId);
      final userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>?;
        final isBlocked = userData?['is_blocked'] == true;
        if (isBlocked) {
          await _auth.signOut();
          _showError('تم حظر هذا الحساب. تواصل مع الدعم الفني.');
          return;
        }
      }

      bool isMfaEnabled = false;
      try {
        isMfaEnabled = await MfaService.isMfaEnabledForUser(userId).timeout(
          const Duration(seconds: 10),
          onTimeout: () => false,
        );
      } catch (e) {
        debugPrint('MFA check failed, proceeding without MFA: $e');
        isMfaEnabled = false;
      }

      if (isMfaEnabled) {
        await _auth.signOut();
        Get.off(() => MfaVerificationPage(
              userId: userId,
              email: userEmail,
              password: password,
            ));
        return;
      }

      Get.snackbar('نجاح', 'تم تسجيل الدخول بنجاح ✓',
          backgroundColor: Colors.green, colorText: Colors.white);

      final arguments = Get.arguments;
      final targetTab = arguments is Map ? arguments['tab'] : null;

      Get.offAllNamed('/main', arguments: {
        'tab': targetTab,
        'fromLogin': true,
      });
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ في المصادقة! حاول مرة أخرى.';
      if (e.code == 'user-not-found') msg = 'الحساب غير موجود.';
      if (e.code == 'wrong-password') msg = 'كلمة المرور غير صحيحة.';
      if (e.code == 'invalid-email') msg = 'صيغة الإيميل غير صحيحة.';
      if (e.code == 'user-disabled') msg = 'هذا الحساب معطل.';
      if (e.code == 'too-many-requests') msg = 'محاولات كثيرة، حاول لاحقاً.';
      if (e.code == 'invalid-credential') msg = 'كلمة المرور غير صحيحة.';
      _showError(msg);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('انتهت مهلة')) {
        _showError(errorMessage.replaceAll('Exception: ', ''));
      } else {
        _showError('خطأ غير متوقع: تأكد من اتصالك بالإنترنت');
      }
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar('تنبيه', message,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // إذا كان هناك صفحات سابقة، ارجع إليها
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          // إذا لم يكن هناك صفحات سابقة، اذهب للصفحة الرئيسية كزائر
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().enterGuestMode();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // الشعار
                _buildLogo(),

                const SizedBox(height: 20),

                // عنوان الصفحة
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 40),

                // حقل رقم الهاتف
                _buildPhoneField(),

                const SizedBox(height: 20),

                // حقل كلمة المرور
                _buildPasswordField(),

                const SizedBox(height: 16),

                // تذكرني ونسيت كلمة المرور
                _buildRememberAndForgot(),

                const SizedBox(height: 30),

                // زر تسجيل الدخول
                _buildLoginButton(),

                const SizedBox(height: 24),

                // رابط إنشاء حساب
                _buildSignUpLink(),

                const SizedBox(height: 16),

                // رابط التصفح كزائر
                _buildGuestModeLink(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'RED',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          TextSpan(
            text: 'SEA',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          hintText: 'أدخل رقم الهاتف',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.phone, color: Colors.red.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _hidePassword,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'أدخل كلمة المرور',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.lock, color: Colors.blue.shade400),
          suffixIcon: IconButton(
            icon: Icon(
              _hidePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500,
            ),
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // نسيت كلمة المرور
        TextButton(
          onPressed: () {
            Get.defaultDialog(
              title: 'نسيت كلمة المرور؟',
              content: const Column(
                children: [
                  Text(
                    'لإعادة تعيين كلمة المرور، يرجى التواصل مع الدعم الفني:',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  SelectableText(
                    'osamammm018@gmail.com',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              textCancel: 'إغلاق',
            );
          },
          child: Text(
            'نسيت كلمة المرور',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 14,
            ),
          ),
        ),
        // تذكرني
        Row(
          children: [
            Text(
              'تذكرني',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            Checkbox(
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? false),
              activeColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => Get.offNamed(AppRoutes.signup),
          child: Text(
            'إنشاء حساب',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          'ليس لدي حساب.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestModeLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextButton.icon(
        onPressed: () {
          // التصفح كزائر - بدون صلاحيات
          if (Get.isRegistered<AuthController>()) {
            Get.find<AuthController>().enterGuestMode();
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        },
        icon: Icon(
          Icons.visibility,
          color: Colors.grey.shade700,
          size: 18,
        ),
        label: Text(
          'أريد التصفح فقط',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
