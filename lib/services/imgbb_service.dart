import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ImgBBService {
  // 🔑 ضع API Key الخاص بك هنا - هذا مفتاحك الشخصي
  static const String apiKey = '5fc2622b097fcd07fb1a03eca1daf3d3';

  static Future<String?> uploadImage(File image) async {
    try {
      debugPrint('🟢 بدأ رفع الصورة إلى ImgBB...');

      // تحويل الصورة إلى نص (base64)
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      debugPrint('🟢 تم تحويل الصورة، الحجم: ${base64Image.length} حرف');

      // إرسال الصورة إلى ImgBB
      var response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
        body: {
          'image': base64Image,
        },
      );

      debugPrint('🟢 رد ImgBB: ${response.statusCode}');

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String imageUrl = jsonResponse['data']['url'];
        debugPrint('✅ تم رفع الصورة بنجاح: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ فشل الرفع: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');
      return null;
    }
  }
}
