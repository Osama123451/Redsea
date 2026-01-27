import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';

/// قسم العروض الخاصة
/// يعرض قائمة أفقية من المنتجات ذات الخصومات
class OffersSection extends StatelessWidget {
  const OffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();

    // فلترة المنتجات ذات العروض الخاصة
    final offerProducts = productController.allProducts
        .where((p) => p.isSpecialOffer && p.oldPrice != null)
        .take(10)
        .toList();

    if (offerProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // رأس القسم
        _buildSectionHeader(offerProducts.length),
        // قائمة العروض
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: offerProducts.length,
            itemBuilder: (context, index) {
              return _OfferCard(product: offerProducts[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // عرض الكل (على اليسار)
          TextButton(
            onPressed: () {
              final filterController = Get.find<FilterController>();
              filterController.setOffersMode();
              Get.toNamed('/search-results');
            },
            child: Text(
              'عرض الكل',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // العنوان مع الأيقونة (على اليمين) - الأيقونة يسار النص
          Row(
            children: [
              const Text(
                'العروض الخاصة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_offer,
                    color: Colors.orange, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// بطاقة العرض الخاص
class _OfferCard extends StatelessWidget {
  final Product product;

  const _OfferCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    // حساب نسبة الخصم
    final oldPrice = double.tryParse(
            product.oldPrice?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ??
        0;
    final newPrice = product.priceAsDouble;
    final discountPercent =
        oldPrice > 0 ? ((oldPrice - newPrice) / oldPrice * 100).round() : 0;

    return GestureDetector(
      onTap: () => _navigateToDetails(cartController),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج مع شارة الخصم
            _buildProductImage(discountPercent),
            // معلومات المنتج
            _buildProductInfo(),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(CartController cartController) {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(
        message: 'سجّل دخولك لعرض تفاصيل المنتج')) {
      return;
    }
    Get.to(() => ProductDetailsPage(
          product: product,
          cartItems: cartController.cartItems.toList(),
          onAddToCart: (p) => cartController.addToCart(p),
          onRemoveFromCart: (id) => cartController.removeFromCart(id),
          onUpdateQuantity: (id, qty) => cartController.updateQuantity(id, qty),
        ));
  }

  Widget _buildProductImage(int discountPercent) {
    return Stack(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            image: product.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(product.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: product.imageUrl.isEmpty
              ? Center(
                  child:
                      Icon(Icons.image, color: Colors.grey.shade400, size: 40))
              : null,
        ),
        // شارة الخصم
        if (discountPercent > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '-$discountPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // أيقونة العرض
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // اسم المنتج
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
            const Spacer(),
            // السعر القديم (مشطوب)
            if (product.oldPrice != null)
              Text(
                '${product.oldPrice} ر.ي',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.red.shade300,
                  decorationThickness: 2,
                ),
                textAlign: TextAlign.right,
              ),
            const SizedBox(height: 2),
            // السعر الجديد
            Text(
              '${product.price} ر.ي',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
