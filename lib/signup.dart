import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');
  final DatabaseReference _userLookupRef =
      FirebaseDatabase.instance.ref().child('user_lookup');

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    // التحقق من الحقول
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى ملء جميع الحقول',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
      return;
    }

    if (phone.length < 8) {
      Get.snackbar('تنبيه', 'رقم الهاتف يجب أن يكون 8 أرقام على الأقل',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
      return;
    }

    if (password.length < 6) {
      Get.snackbar('تنبيه', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      // التحقق من أن رقم الهاتف غير مستخدم مسبقًا في user_lookup
      DataSnapshot lookupSnapshot = await _userLookupRef.child(phone).get();

      if (lookupSnapshot.exists) {
        Get.snackbar('تنبيه', 'رقم الهاتف مستخدم مسبقًا',
            backgroundColor: AppColors.primaryDark, colorText: Colors.white);
        setState(() => _loading = false);
        return;
      }

      // إنشاء إيميل مؤقت فريد باستخدام الطابع الزمني
      String tempEmail =
          '${phone}_${DateTime.now().millisecondsSinceEpoch}@redsea-app.com';

      // إنشاء مستخدم Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: tempEmail,
        password: password,
      );

      // تحديث اسم المستخدم في Firebase Auth
      await userCredential.user!.updateDisplayName('$firstName $lastName');

      // حفظ البيانات في قاعدة البيانات users
      await _dbRef.child(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'name': '$firstName $lastName',
        'phone': phone,
        'password': base64Encode(utf8.encode(password)),
        'uid': userCredential.user!.uid,
        'email': tempEmail,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // إضافة إدخال في user_lookup (متاح للقراءة بدون مصادقة)
      await _userLookupRef.child(phone).set({
        'email': tempEmail,
        'uid': userCredential.user!.uid,
      });

      Get.snackbar('نجاح', 'تم إنشاء الحساب بنجاح ✓',
          backgroundColor: AppColors.primary, colorText: Colors.white);
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء التسجيل.';
      if (e.code == 'email-already-in-use') {
        msg = 'الحساب موجود مسبقاً. حاول تسجيل الدخول.';
      } else if (e.code == 'weak-password') {
        msg = 'كلمة المرور ضعيفة.';
      }
      Get.snackbar('تنبيه', msg,
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('تنبيه', 'خطأ غير متوقع: $e',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 70),

              // العنوان REDSEA مع تأثيرات
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'RED',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: AppColors.primaryLight,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        TextSpan(
                          text: 'SEA',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.blueAccent,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // عنوان إنشاء حساب
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: const Text(
                    'إنشاء حساب',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // حقل الاسم الأول
              _buildTextField(
                controller: _firstNameController,
                label: 'الاسم الأول',
                hint: 'ادخل اسمك الأول',
                icon: Icons.person,
              ),

              const SizedBox(height: 20),

              // حقل اللقب
              _buildTextField(
                controller: _lastNameController,
                label: 'اللقب',
                hint: 'ادخل لقبك',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 20),

              // حقل رقم الهاتف
              _buildTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                hint: 'أدخل رقم هاتفك',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildPasswordField(),

              const SizedBox(height: 40),

              // زر إنشاء حساب
              _loading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
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
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 25),

              // رابط تسجيل الدخول
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Get.offNamed(AppRoutes.login);
                    },
                    child: const Text(
                      'لديك حساب؟ تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
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
              label,
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
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
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
                    icon,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
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
                    decoration: InputDecoration(
                      hintText: 'أنشئ كلمة مرور',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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
}
