import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';

/// بطاقة المنتج الأفقية
/// تُستخدم في قوائم المنتجات الأفقية (أحدث المنتجات، نتائج البحث)
class ProductHorizontalCard extends StatelessWidget {
  final Product product;

  const ProductHorizontalCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            _buildProductImage(),
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

  Widget _buildProductImage() {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          Container(
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
                    child: Icon(Icons.image,
                        color: Colors.grey.shade400, size: 40))
                : null,
          ),
          // شارة المقايضة
          if (product.negotiable)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.swap_horiz, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${product.price} ر.ي',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
