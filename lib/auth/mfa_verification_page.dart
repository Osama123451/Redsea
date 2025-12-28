import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/services/mfa_service.dart';
import 'package:redsea/app/routes/app_routes.dart';

class MfaVerificationPage extends StatefulWidget {
  final String userId;
  final String email;
  final String password;

  const MfaVerificationPage({
    super.key,
    required this.userId,
    required this.email,
    required this.password,
  });

  @override
  State<MfaVerificationPage> createState() => _MfaVerificationPageState();
}

class _MfaVerificationPageState extends State<MfaVerificationPage> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _sendingCode = true;
  int _attempts = 0;
  String? _mfaEmail;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _sendOtpCode();
  }

  Future<void> _sendOtpCode() async {
    setState(() => _sendingCode = true);

    try {
      // الحصول على الإيميل المحفوظ
      final email = await MfaService.getMfaEmail(widget.userId);
      if (email != null) {
        _mfaEmail = email;

        // إرسال كود OTP
        final sent = await MfaService.sendLoginOtp(widget.userId);
        if (sent) {
          Get.snackbar('تم الإرسال', 'تم إرسال كود التحقق إلى بريدك',
              backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          Get.snackbar('خطأ', 'فشل إرسال الكود',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      Get.snackbar('تنبيه', 'الرجاء إدخال الكود المكون من 6 أرقام',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await MfaService.verifyLoginCode(widget.userId, code);

      if (success) {
        // إعادة تسجيل الدخول بعد نجاح التحقق
        await _auth.signInWithEmailAndPassword(
          email: widget.email,
          password: widget.password,
        );

        Get.offAllNamed(AppRoutes.home);
        Get.snackbar('نجاح', 'تم تسجيل الدخول بنجاح ✅',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        _attempts++;
        _codeController.clear();

        if (_attempts >= _maxAttempts) {
          Get.snackbar('تحذير', 'تجاوزت عدد المحاولات المسموحة. حاول لاحقاً.',
              backgroundColor: Colors.red, colorText: Colors.white);
          Get.offAllNamed(AppRoutes.login);
        } else {
          Get.snackbar('خطأ',
              'الكود غير صحيح أو منتهي. المحاولات المتبقية: ${_maxAttempts - _attempts}',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء التحقق',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return '***@***.***';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name@$domain';
    return '${name[0]}***${name[name.length - 1]}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق بخطوتين'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed(AppRoutes.login),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة البريد
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read,
                  size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 30),

            // العنوان
            const Text(
              'تحقق من بريدك الإلكتروني',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // الوصف
            Text(
              'تم إرسال كود تحقق إلى',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _maskEmail(_mfaEmail),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),

            if (_sendingCode)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري إرسال الكود...'),
                ],
              )
            else ...[
              // حقل إدخال الكود
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 10,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 30),

              // زر التأكيد
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تأكيد الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // إعادة الإرسال
              TextButton.icon(
                onPressed: _sendingCode ? null : _sendOtpCode,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة إرسال الكود'),
              ),

              // عداد المحاولات
              if (_attempts > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'المحاولات المتبقية: ${_maxAttempts - _attempts}',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
