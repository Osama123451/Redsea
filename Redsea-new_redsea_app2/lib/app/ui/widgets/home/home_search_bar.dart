import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/search_view_page.dart';

/// شريط البحث الرئيسي للصفحة الرئيسية
/// تصميم نظيف بحواف دائرية كاملة (Stadium Border) وأيقونة بحث في مربع أزرق
class HomeSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool isAdvancedSearch;
  final VoidCallback onToggleSearchType;

  const HomeSearchBar({
    super.key,
    required this.searchController,
    required this.isAdvancedSearch,
    required this.onToggleSearchType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildSearchField(),
    );
  }

  Widget _buildSearchField() {
    final productController = Get.find<ProductController>();

    return GestureDetector(
      // فتح صفحة البحث المتقدمة دائماً عند الضغط على حقل البحث
      onTap: () => Get.to(() => const SearchViewPage()),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(25), // Stadium Border
        ),
        child: Row(
          children: [
            // محتوى البحث
            Expanded(
              child: isAdvancedSearch
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'اضغط للبحث المتقدم...',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    )
                  : TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن منتج...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      ),
                      textAlign: TextAlign.right,
                    ),
            ),
            // زر المسح إن وجد نص
            if (!isAdvancedSearch)
              Obx(() {
                if (productController.searchQuery.value.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      searchController.clear();
                      productController.clearSearch();
                    },
                  );
                }
                return const SizedBox.shrink();
              }),
            // أيقونة البحث في مربع أزرق على اليسار
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
