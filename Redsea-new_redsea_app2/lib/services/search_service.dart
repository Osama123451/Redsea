import 'package:redsea/product_model.dart';

class SearchService {
  // دالة البحث الذكي (محاكاة)
  // تقوم بتقسيم نص البحث ومطابقة الكلمات مع الاسم والوصف والتصنيف
  static List<Product> smartSearch(List<Product> allProducts, String query) {
    if (query.trim().isEmpty) return allProducts;

    final queryWords =
        query.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList();

    return allProducts.where((product) {
      int matchScore = 0;
      String pName = product.name.toLowerCase();
      String pDesc = product.description.toLowerCase();
      String pCat = product.category.toLowerCase();
      String pLoc = (product.location ?? '').toLowerCase(); // إضافة الموقع

      for (var word in queryWords) {
        if (pName.contains(word)) matchScore += 3; // الاسم أهم
        if (pCat.contains(word)) matchScore += 2;
        if (pLoc.contains(word)) matchScore += 2; // الموقع مهم أيضاً
        if (pDesc.contains(word)) matchScore += 1;

        // معالجة الأخطاء الإملائية البسيطة (مبدئياً عبر الاحتواء)
      }

      return matchScore > 0;
    }).toList()
      ..sort((a, b) {
        // ترتيب حسب الصلة (اختياري، هنا سنبسط الأمر بترتيب التاريخ كما هو)
        return b.dateAdded.compareTo(a.dateAdded);
      });
  }
}
