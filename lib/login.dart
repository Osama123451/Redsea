import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/core/app_theme.dart';
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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userLookupRef =
      FirebaseDatabase.instance.ref().child('user_lookup');

  Future<void> _login() async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    // تنظيف رقم الهاتف (إزالة المسافات والرموز)
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    setState(() => _loading = true);

    try {
      // البحث عن البريد الإلكتروني في جدول user_lookup
      // هذا الجدول متاح للقراءة بدون مصادقة
      DataSnapshot snapshot = await _userLookupRef.child(phone).get();

      if (!snapshot.exists) {
        _showError('رقم الهاتف غير مسجل');
        return;
      }

      // استخراج البريد الإلكتروني من user_lookup
      Map<dynamic, dynamic> lookupData =
          snapshot.value as Map<dynamic, dynamic>;
      String userEmail = lookupData['email']?.toString() ?? '';

      if (userEmail.isEmpty) {
        _showError('خطأ في بيانات المستخدم');
        return;
      }

      // تسجيل الدخول باستخدام Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId == null) {
        _showError('خطأ في تسجيل الدخول');
        return;
      }

      // التحقق من حالة MFA
      final isMfaEnabled = await MfaService.isMfaEnabledForUser(userId);

      if (isMfaEnabled) {
        // تسجيل الخروج مؤقتاً حتى يتم التحقق من MFA
        await _auth.signOut();

        // الانتقال لصفحة التحقق مع تمرير بيانات الدخول
        Get.off(() => MfaVerificationPage(
              userId: userId,
              email: userEmail,
              password: password,
            ));
        return;
      }

      // لا يوجد MFA - دخول مباشر
      Get.snackbar('نجاح', 'تم تسجيل الدخول بنجاح ✓',
          backgroundColor: AppColors.primary, colorText: Colors.white);
      Get.offAllNamed(AppRoutes.home);
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
      _showError('خطأ غير متوقع: $e');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    Get.snackbar('تنبيه', message,
        backgroundColor: AppColors.primaryDark,
        colorText: Colors.white,
        duration: const Duration(seconds: 3));
  }

  void _navigateToSignUp() {
    Get.offNamed(AppRoutes.signup);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 60),

                // شعار REDSEA
                _buildLogo(),

                const SizedBox(height: 40),

                // عنوان تسجيل الدخول
                _buildTitle(),

                const SizedBox(height: 40),

                // حقل رقم الهاتف
                _buildPhoneField(),

                const SizedBox(height: 20),

                // حقل كلمة المرور
                _buildPasswordField(),

                const SizedBox(height: 10),

                const SizedBox(height: 10),

                // زر نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
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
                              'osamammm018@gmail.com', // بريد الدعم الفني
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('سيقوم الفريق بمساعدتك في استعادة حسابك.'),
                          ],
                        ),
                        textCancel: 'إغلاق',
                        buttonColor: Colors.blue,
                        cancelTextColor: Colors.blue,
                      );
                    },
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),

                const SizedBox(height: 20),

                // زر تسجيل الدخول
                _buildLoginButton(),

                const SizedBox(height: 20),

                // رابط إنشاء حساب
                _buildSignUpLink(),

                const SizedBox(height: 40),

                // معلومات الدعم الفني
                Center(
                  child: Column(
                    children: [
                      Text(
                        'تواجه مشكلة؟ تواصل معنا',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      const SelectableText(
                        'osamammm018@gmail.com',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade300.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'REDSEA',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: const Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Text(
              'رقم الهاتف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: '773468112',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Text(
              'كلمة المرور',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _hidePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
                Container(
                  width: 50,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.lock,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: 'ادخل كلمة المرور',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return _loading
        ? Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'جاري تسجيل الدخول...',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade300.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _navigateToSignUp,
              child: const Text(
                'لا تملك حساب؟ إنشاء حساب',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_back, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
