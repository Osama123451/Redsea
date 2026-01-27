import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/add_product_page.dart';
import 'product_horizontal_card.dart';

/// قسم أحدث المنتجات
/// يعرض قائمة أفقية من أحدث المنتجات المضافة
class LatestProductsSection extends StatelessWidget {
  final VoidCallback onShowAllProducts;

  const LatestProductsSection({
    super.key,
    required this.onShowAllProducts,
  });

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();

    // استبعاد العروض الخاصة من قسم أحدث المنتجات
    final latestProducts = productController.filteredProducts
        .where((p) => !p.isSpecialOffer)
        .take(10)
        .toList();

    if (latestProducts.isEmpty) {
      return _buildEmptyState(productController);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: latestProducts.length,
            itemBuilder: (context, index) {
              return ProductHorizontalCard(product: latestProducts[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onShowAllProducts,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios,
                      size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Row(
            children: [
              Icon(Icons.new_releases, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text(
                'أحدث المنتجات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ProductController productController) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد منتجات متاحة',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.to(() => const AddProductPage())
                ?.then((_) => productController.loadProducts()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('أضف أول منتج'),
          ),
        ],
      ),
    );
  }
}
