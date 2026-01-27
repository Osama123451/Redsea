import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التشفير AES-256
/// تستخدم لتشفير وفك تشفير الرسائل والبيانات الحساسة
class EncryptionService {
  // مفتاح التشفير - 32 حرف = 256 bit
  static const String _defaultKey = 'RedSeaApp2024SecureKey32Chars!!';

  // متجه التهيئة IV - 16 حرف
  static const String _defaultIV = 'RedSeaIV16Chars!';

  static Key? _key;
  static IV? _iv;
  static Encrypter? _encrypter;

  /// تهيئة خدمة التشفير
  static Future<void> initialize() async {
    try {
      // محاولة تحميل المفتاح المخزن أو استخدام الافتراضي
      final prefs = await SharedPreferences.getInstance();
      String storedKey = prefs.getString('encryption_key') ?? _defaultKey;

      // التأكد من أن المفتاح 32 حرف بالضبط
      if (storedKey.length < 32) {
        storedKey = storedKey.padRight(32, '0');
      } else if (storedKey.length > 32) {
        storedKey = storedKey.substring(0, 32);
      }

      _key = Key.fromUtf8(storedKey);
      _iv = IV.fromUtf8(_defaultIV);
      _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));

      debugPrint('🔐 EncryptionService initialized successfully');
    } catch (e) {
      debugPrint('❌ EncryptionService initialization error: $e');
      // استخدام المفتاح الافتراضي في حالة الخطأ
      _key = Key.fromUtf8(_defaultKey);
      _iv = IV.fromUtf8(_defaultIV);
      _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    }
  }

  /// تشفير نص
  /// [plainText] النص المراد تشفيره
  /// يرجع النص المشفر بصيغة Base64
  static String encrypt(String plainText) {
    try {
      if (_encrypter == null) {
        // تهيئة سريعة إذا لم تتم التهيئة
        _key = Key.fromUtf8(_defaultKey);
        _iv = IV.fromUtf8(_defaultIV);
        _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
      }

      if (plainText.isEmpty) return '';

      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('❌ Encryption error: $e');
      return plainText; // إرجاع النص الأصلي في حالة الخطأ
    }
  }

  /// فك تشفير نص
  /// [encryptedText] النص المشفر بصيغة Base64
  /// يرجع النص الأصلي
  static String decrypt(String encryptedText) {
    try {
      if (_encrypter == null) {
        // تهيئة سريعة إذا لم تتم التهيئة
        _key = Key.fromUtf8(_defaultKey);
        _iv = IV.fromUtf8(_defaultIV);
        _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
      }

      if (encryptedText.isEmpty) return '';

      // التحقق من أن النص مشفر (Base64 صالح)
      if (!_isValidBase64(encryptedText)) {
        return encryptedText; // إرجاع كما هو إذا لم يكن مشفراً
      }

      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('❌ Decryption error: $e');
      return encryptedText; // إرجاع النص كما هو في حالة الخطأ
    }
  }

  /// التحقق من أن النص Base64 صالح
  static bool _isValidBase64(String text) {
    try {
      if (text.isEmpty) return false;
      // التحقق من أن الطول صحيح لـ Base64
      if (text.length % 4 != 0) return false;
      base64.decode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من أن النص مشفر
  static bool isEncrypted(String text) {
    if (text.isEmpty) return false;
    return _isValidBase64(text) && text.length >= 24;
  }

  /// تشفير Map (للبيانات المعقدة)
  static Map<String, dynamic> encryptMap(
      Map<String, dynamic> data, List<String> fieldsToEncrypt) {
    final result = Map<String, dynamic>.from(data);
    for (final field in fieldsToEncrypt) {
      if (result.containsKey(field) && result[field] is String) {
        result[field] = encrypt(result[field] as String);
      }
    }
    return result;
  }

  /// فك تشفير Map
  static Map<String, dynamic> decryptMap(
      Map<String, dynamic> data, List<String> fieldsToDecrypt) {
    final result = Map<String, dynamic>.from(data);
    for (final field in fieldsToDecrypt) {
      if (result.containsKey(field) && result[field] is String) {
        result[field] = decrypt(result[field] as String);
      }
    }
    return result;
  }
}
