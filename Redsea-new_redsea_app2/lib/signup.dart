import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى ملء جميع الحقول',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return;
    }

    if (phone.length < 8) {
      Get.snackbar('تنبيه', 'رقم الهاتف يجب أن يكون 8 أرقام على الأقل',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return;
    }

    if (password.length < 6) {
      Get.snackbar('تنبيه', 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      DataSnapshot lookupSnapshot = await _userLookupRef.child(phone).get();

      if (lookupSnapshot.exists) {
        Get.snackbar('تنبيه', 'رقم الهاتف مستخدم مسبقًا',
            backgroundColor: Colors.red.shade600, colorText: Colors.white);
        setState(() => _loading = false);
        return;
      }

      String tempEmail =
          '${phone}_${DateTime.now().millisecondsSinceEpoch}@redsea-app.com';

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: tempEmail,
        password: password,
      );

      await userCredential.user!.updateDisplayName('$firstName $lastName');

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

      await _userLookupRef.child(phone).set({
        'email': tempEmail,
        'uid': userCredential.user!.uid,
      });

      Get.snackbar('نجاح', 'تم إنشاء الحساب بنجاح ✓',
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء التسجيل.';
      if (e.code == 'email-already-in-use') {
        msg = 'الحساب موجود مسبقاً. حاول تسجيل الدخول.';
      } else if (e.code == 'weak-password') {
        msg = 'كلمة المرور ضعيفة.';
      }
      Get.snackbar('تنبيه', msg,
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('تنبيه', 'خطأ غير متوقع: $e',
          backgroundColor: Colors.red.shade600, colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // الشعار
              _buildLogo(),

              const SizedBox(height: 30),

              // التابات
              _buildTabs(),

              const SizedBox(height: 30),

              // حقل الاسم الأول
              _buildTextField(
                controller: _firstNameController,
                hint: 'الاسم الأول',
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              // حقل اللقب
              _buildTextField(
                controller: _lastNameController,
                hint: 'اللقب',
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              // حقل رقم الهاتف
              _buildTextField(
                controller: _phoneController,
                hint: 'رقم الهاتف',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isPhone: true,
              ),

              const SizedBox(height: 16),

              // حقل كلمة المرور
              _buildPasswordField(),

              const SizedBox(height: 30),

              // زر إنشاء حساب
              _buildSignUpButton(),

              const SizedBox(height: 24),

              // رابط تسجيل الدخول
              _buildLoginLink(),

              const SizedBox(height: 40),
            ],
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

  Widget _buildTabs() {
    return Row(
      children: [
        // تسجيل الدخول
        Expanded(
          child: GestureDetector(
            onTap: () => Get.offNamed(AppRoutes.login),
            child: Column(
              children: [
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 3,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        // إنشاء حساب (نشط)
        Expanded(
          child: Column(
            children: [
              Text(
                'إنشاء حساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPhone = false,
  }) {
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
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.blue.shade400),
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
          hintText: 'كلمة المرور',
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

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _signUp,
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
                'إنشاء حساب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => Get.offNamed(AppRoutes.login),
          child: Text(
            'تسجيل الدخول',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          'لدي حساب.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
