import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:redsea/services/encryption_service.dart';

/// خدمة التحقق بخطوتين عبر البريد الإلكتروني
/// نظام بسيط يشبه واتساب وتليجرام
class MfaService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // مدة صلاحية الكود (5 دقائق)
  static const int _otpValidityMinutes = 5;

  /// إنشاء كود عشوائي من 6 أرقام
  static String generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// تفعيل MFA وحفظ الإيميل
  static Future<bool> enableMfa(String email, String verificationCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // التحقق من الكود المُرسل
      final isValid = await verifyOtp(user.uid, verificationCode);
      if (!isValid) return false;

      // تشفير الإيميل قبل الحفظ
      final encryptedEmail = EncryptionService.encrypt(email);

      // حفظ بيانات MFA في قاعدة البيانات
      await _database.child('users/${user.uid}/mfa').set({
        'enabled': true,
        'email': encryptedEmail,
        'enabledAt': ServerValue.timestamp,
      });

      debugPrint('✅ MFA enabled successfully for user: ${user.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ Error enabling MFA: $e');
      return false;
    }
  }

  /// إلغاء تفعيل MFA
  static Future<bool> disableMfa() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database.child('users/${user.uid}/mfa').remove();

      debugPrint('✅ MFA disabled for user: ${user.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ Error disabling MFA: $e');
      return false;
    }
  }

  /// التحقق من حالة MFA للمستخدم الحالي
  static Future<bool> isMfaEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot =
          await _database.child('users/${user.uid}/mfa/enabled').get();
      return snapshot.exists && snapshot.value == true;
    } catch (e) {
      debugPrint('Error checking MFA status: $e');
      return false;
    }
  }

  /// التحقق من حالة MFA لمستخدم معين (عند تسجيل الدخول)
  static Future<bool> isMfaEnabledForUser(String uid) async {
    try {
      final snapshot = await _database.child('users/$uid/mfa/enabled').get();
      return snapshot.exists && snapshot.value == true;
    } catch (e) {
      debugPrint('Error checking MFA status for user: $e');
      return false;
    }
  }

  /// الحصول على الإيميل المشفر للمستخدم
  static Future<String?> getMfaEmail(String uid) async {
    try {
      final snapshot = await _database.child('users/$uid/mfa/email').get();
      if (snapshot.exists) {
        final encryptedEmail = snapshot.value as String?;
        if (encryptedEmail != null) {
          return EncryptionService.decrypt(encryptedEmail);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting MFA email: $e');
      return null;
    }
  }

  /// إنشاء وحفظ كود OTP جديد
  static Future<String?> createAndSaveOtp(String uid) async {
    try {
      final otp = generateOtp();
      final expiresAt = DateTime.now()
          .add(const Duration(minutes: _otpValidityMinutes))
          .millisecondsSinceEpoch;

      // تشفير الكود قبل الحفظ
      final encryptedOtp = EncryptionService.encrypt(otp);

      await _database.child('mfa_codes/$uid').set({
        'code': encryptedOtp,
        'expiresAt': expiresAt,
        'createdAt': ServerValue.timestamp,
      });

      return otp;
    } catch (e) {
      debugPrint('Error creating OTP: $e');
      return null;
    }
  }

  /// التحقق من صحة كود OTP
  static Future<bool> verifyOtp(String uid, String inputCode) async {
    try {
      final snapshot = await _database.child('mfa_codes/$uid').get();
      if (!snapshot.exists) return false;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final encryptedCode = data['code'] as String?;
      final expiresAt = data['expiresAt'] as int?;

      if (encryptedCode == null || expiresAt == null) return false;

      // التحقق من انتهاء الصلاحية
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        debugPrint('OTP expired');
        await _database.child('mfa_codes/$uid').remove();
        return false;
      }

      // فك تشفير ومقارنة الكود
      final storedCode = EncryptionService.decrypt(encryptedCode);
      if (storedCode == inputCode) {
        // حذف الكود بعد الاستخدام
        await _database.child('mfa_codes/$uid').remove();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  /// إرسال كود OTP عبر البريد الإلكتروني
  /// يستخدم مكتبة mailer لإرسال البريد مباشرة من التطبيق
  static Future<bool> sendOtpEmail(String email, String otp) async {
    try {
      // إعدادات خادم Gmail
      // ملاحظة: هذا الحل مناسب للتطبيقات الصغيرة أو الشخصية.
      // للتطبيقات الكبيرة، يُفضل استخدام خادم backend لتجنب وضع كلمات المرور في الكود.
      const username = 'osamammm018@gmail.com';
      const password = 'pnjcjcygnskuziqa'; // App Password

      final smtpServer = gmail(username, password);

      // إنشاء الرسالة
      final message = Message()
        ..from = Address(username, 'RedSea App')
        ..recipients.add(email)
        ..subject = 'RedSea Verification Code'
        ..text =
            'Your verification code is: $otp\n\nThis code is valid for $_otpValidityMinutes minutes.'
        ..html = '''
          <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px; max-width: 500px;">
            <h2 style="color: #1a73e8;">RedSea Verification</h2>
            <p>Your One-Time Password (OTP) for RedSea is:</p>
            <div style="background-color: #f1f3f4; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
              <span style="font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #333;">$otp</span>
            </div>
            <p style="color: #666; font-size: 12px;">This code is valid for $_otpValidityMinutes minutes. Do not share this code with anyone.</p>
          </div>
        ''';

      // إرسال الرسالة
      final sendReport = await send(message, smtpServer);

      debugPrint('✅ OTP email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending OTP email: $e');
      // طباعة الكود للتصحيح في حالة الفشل
      debugPrint('📧 ==============================');
      debugPrint('📧 OTP Code (fallback): $otp');
      debugPrint('📧 ==============================');
      return false;
    }
  }

  /// إرسال كود OTP لمستخدم معين عند تسجيل الدخول
  static Future<bool> sendLoginOtp(String uid) async {
    try {
      // الحصول على الإيميل المحفوظ
      final email = await getMfaEmail(uid);
      if (email == null) return false;

      // إنشاء كود جديد
      final otp = await createAndSaveOtp(uid);
      if (otp == null) return false;

      // إرسال الكود
      return await sendOtpEmail(email, otp);
    } catch (e) {
      debugPrint('Error sending login OTP: $e');
      return false;
    }
  }

  /// التحقق من كود تسجيل الدخول
  static Future<bool> verifyLoginCode(String uid, String code) async {
    return await verifyOtp(uid, code);
  }
}
