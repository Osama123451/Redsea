import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/services/mfa_service.dart';
import 'package:redsea/app/core/app_theme.dart';

class MfaEnrollmentPage extends StatefulWidget {
  const MfaEnrollmentPage({super.key});

  @override
  State<MfaEnrollmentPage> createState() => _MfaEnrollmentPageState();
}

class _MfaEnrollmentPageState extends State<MfaEnrollmentPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _loading = false;
  bool _codeSent = false;
  String? _errorMessage;

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar('تنبيه', 'الرجاء إدخال بريد إلكتروني صحيح',
          backgroundColor: AppColors.primaryLight, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً',
            backgroundColor: AppColors.primaryDark, colorText: Colors.white);
        return;
      }

      // إنشاء وحفظ كود OTP
      final otp = await MfaService.createAndSaveOtp(user.uid);
      if (otp == null) {
        Get.snackbar('تنبيه', 'حدث خطأ أثناء إنشاء الكود',
            backgroundColor: AppColors.primaryDark, colorText: Colors.white);
        return;
      }

      // إرسال الكود
      final sent = await MfaService.sendOtpEmail(email, otp);
      if (sent) {
        setState(() => _codeSent = true);
        Get.snackbar('تم الإرسال', 'تم إرسال كود التحقق إلى $email',
            backgroundColor: AppColors.primary, colorText: Colors.white);
      } else {
        Get.snackbar('تنبيه', 'فشل إرسال الكود',
            backgroundColor: AppColors.primaryDark, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('تنبيه', 'حدث خطأ: $e',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndEnroll() async {
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();

    if (code.length != 6) {
      Get.snackbar('تنبيه', 'الرجاء إدخال الكود المكون من 6 أرقام',
          backgroundColor: AppColors.primaryLight, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await MfaService.enableMfa(email, code);

      if (success) {
        Get.back(result: true);
        Get.snackbar('نجاح', 'تم تفعيل التحقق بخطوتين بنجاح ✓',
            backgroundColor: AppColors.primary, colorText: Colors.white);
      } else {
        Get.snackbar('تنبيه', 'الكود غير صحيح أو منتهي الصلاحية',
            backgroundColor: AppColors.primaryDark, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('تنبيه', 'حدث خطأ: $e',
          backgroundColor: AppColors.primaryDark, colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('تفعيل التحقق بخطوتين'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // أيقونة الأمان
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined,
                  size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 24),

            // العنوان
            Text(
              _codeSent ? 'أدخل كود التحقق' : 'أدخل بريدك الإلكتروني',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // الوصف
            Text(
              _codeSent
                  ? 'تم إرسال كود من 6 أرقام إلى بريدك'
                  : 'سيتم إرسال كود التحقق إلى بريدك الإلكتروني عند كل تسجيل دخول',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 30),

            if (!_codeSent) ...[
              // حقل الإيميل
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // زر إرسال الكود
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال كود التحقق',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ] else ...[
              // عرض الإيميل المُرسل إليه
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryExtraLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _emailController.text,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // حقل إدخال الكود
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _verifyAndEnroll(),
              ),
              const SizedBox(height: 24),

              // زر التفعيل
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verifyAndEnroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تفعيل التحقق بخطوتين',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // زر إعادة الإرسال
              TextButton.icon(
                onPressed: _loading ? null : _sendCode,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة إرسال الكود'),
              ),

              // زر تغيير الإيميل
              TextButton(
                onPressed: () => setState(() => _codeSent = false),
                child: const Text('تغيير البريد الإلكتروني'),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 30),

            // ملاحظة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryExtraLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'سيتم إرسال كود تحقق إلى هذا البريد عند كل تسجيل دخول',
                      style:
                          TextStyle(color: AppColors.primaryDark, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
