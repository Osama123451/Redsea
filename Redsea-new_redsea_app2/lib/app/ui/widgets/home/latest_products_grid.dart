import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/ui/widgets/home/marketplace_product_card.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/swap_selection_page.dart';

/// قسم أحدث المنتجات
class LatestProductsGrid extends StatelessWidget {
  final List<Product>? products;
  final String title;
  final Function(Product)? onProductTap;
  final VoidCallback? onViewAllTap;
  final int crossAxisCount;
  final bool shrinkWrap;

  const LatestProductsGrid({
    super.key,
    this.products,
    this.title = 'أحدث المنتجات',
    this.onProductTap,
    this.onViewAllTap,
    this.crossAxisCount = 2,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        _buildHeader(),
        const SizedBox(height: 12),
        // شبكة المنتجات
        _buildProductsGrid(),
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
                  color: AppColors.primaryExtraLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.new_releases_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.headline3,
              ),
            ],
          ),
          TextButton(
            onPressed: onViewAllTap ??
                () {
                  Get.toNamed(AppRoutes.categories);
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

  Widget _buildProductsGrid() {
    return GetBuilder<ProductController>(
      builder: (controller) {
        // جلب أحدث المنتجات
        final latestProducts =
            products ?? controller.products.take(10).toList();

        if (latestProducts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات حالياً',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        if (shrinkWrap) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: latestProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(latestProducts[index]);
              },
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.52,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCard(latestProducts[index]),
              childCount: latestProducts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return MarketplaceProductCard(
      product: product,
      onTap: () {
        if (onProductTap != null) {
          onProductTap!(product);
        } else {
          Get.toNamed(AppRoutes.productDetails, arguments: product);
        }
      },
      onAddToCart: () {
        final cartController = Get.find<CartController>();
        cartController.addToCart(product);
        Get.snackbar(
          'تمت الإضافة',
          'تم إضافة ${product.name} إلى السلة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
      onBarterTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(message: 'سجّل دخولك للمقايضة'))
          return;
        Get.to(() => SwapSelectionPage(targetProduct: product));
      },
      onChatTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(message: 'سجّل دخولك للدردشة')) return;
        Get.toNamed(AppRoutes.chat,
            arguments: {'peerId': product.ownerId, 'product': product});
      },
    );
  }
}

/// قسم أحدث المنتجات كـ Sliver للاستخدام في CustomScrollView
class LatestProductsSliverGrid extends StatelessWidget {
  final List<Product>? products;
  final String title;
  final Function(Product)? onProductTap;
  final VoidCallback? onViewAllTap;
  final int crossAxisCount;

  const LatestProductsSliverGrid({
    super.key,
    this.products,
    this.title = 'أحدث المنتجات',
    this.onProductTap,
    this.onViewAllTap,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProductController>(
      builder: (controller) {
        final latestProducts =
            products ?? controller.products.take(20).toList();

        return SliverMainAxisGroup(
          slivers: [
            // العنوان
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryExtraLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.new_releases_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(title, style: AppTextStyles.headline3),
                      ],
                    ),
                    TextButton(
                      onPressed: onViewAllTap ??
                          () => Get.toNamed(AppRoutes.categories),
                      child: Row(
                        children: [
                          Text(
                            'عرض الكل',
                            style: TextStyle(
                                color: AppColors.primary, fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_back_ios,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // الشبكة
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = latestProducts[index];
                    return MarketplaceProductCard(
                      product: product,
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
                          backgroundColor: Colors.green.withValues(alpha: 0.8),
                          colorText: Colors.white,
                        );
                      },
                      onBarterTap: () {
                        final authController = Get.find<AuthController>();
                        if (!authController.requireLogin(
                            message: 'سجّل دخولك للمقايضة')) return;
                        Get.to(() => SwapSelectionPage(targetProduct: product));
                      },
                      onChatTap: () {
                        final authController = Get.find<AuthController>();
                        if (!authController.requireLogin(
                            message: 'سجّل دخولك للدردشة')) return;
                        Get.toNamed(AppRoutes.chat, arguments: {
                          'peerId': product.ownerId,
                          'product': product
                        });
                      },
                    );
                  },
                  childCount: latestProducts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
