import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/app/controllers/cart_controller.dart';

/// قسم منتجات المقايضة
class BarterProductsSection extends StatelessWidget {
  final List<Product>? products;
  final Function(Product)? onProductTap;
  final VoidCallback? onViewAllTap;

  const BarterProductsSection({
    super.key,
    this.products,
    this.onProductTap,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        _buildHeader(),
        const SizedBox(height: 12),
        // قائمة المنتجات
        _buildProductsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.teal],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'منتجات للمقايضة',
                    style: AppTextStyles.headline3,
                  ),
                  Text(
                    'بادل منتجاتك بسهولة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: onViewAllTap ??
                () {
                  Get.toNamed(AppRoutes.categories,
                      arguments: {'filter': 'barter'});
                },
            child: Row(
              children: [
                Text(
                  'عرض الكل',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_back_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return SizedBox(
      height: 330,
      child: GetBuilder<ProductController>(
        builder: (controller) {
          // جلب منتجات المقايضة
          final barterProducts = products ??
              controller.products.where((p) => p.isSwappable).take(10).toList();

          if (barterProducts.isEmpty) {
            return Center(
              child: Text(
                'لا توجد منتجات للمقايضة حالياً',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: barterProducts.length,
            itemBuilder: (context, index) {
              final product = barterProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 170,
                  child: MarketplaceProductCard(
                    product: product,
                    showBarter: true,
                    onTap: () {
                      if (onProductTap != null) {
                        onProductTap!(product);
                      } else {
                        Get.toNamed(AppRoutes.productDetails,
                            arguments: product);
                      }
                    },
                    onAddToCart: () {
                      final cartController = Get.find<CartController>();
                      cartController.addToCart(product);
                      Get.snackbar(
                        'تمت الإضافة',
                        'تم إضافة ${product.name} إلى السلة',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.withOpacity(0.8),
                        colorText: Colors.white,
                      );
                    },
                    onBarterTap: () {
                      Get.toNamed(AppRoutes.productDetails, arguments: product);
                    },
                    onChatTap: () {
                      // منطق الدردشة
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
