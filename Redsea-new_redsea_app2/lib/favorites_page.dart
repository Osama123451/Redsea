import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // التأكد من وجود الـ Controllers
    final FavoritesController favoritesController =
        Get.find<FavoritesController>();
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              'المفضلة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (favoritesController.favorites.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showClearDialog(favoritesController),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (favoritesController.isLoading.value) {
          return AppWidgets.loadingIndicator();
        }

        if (favoritesController.favorites.isEmpty) {
          return AppWidgets.emptyState(
            icon: Icons.favorite_border,
            title: 'لا توجد منتجات في المفضلة',
            subtitle: 'أضف المنتجات التي تعجبك للمفضلة للوصول إليها بسهولة',
          );
        }

        return RefreshIndicator(
          onRefresh: favoritesController.loadFavorites,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritesController.favorites.length,
            itemBuilder: (context, index) {
              final product = favoritesController.favorites[index];
              return _buildFavoriteItem(
                product,
                favoritesController,
                cartController,
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildFavoriteItem(
    Product product,
    FavoritesController favoritesController,
    CartController cartController,
  ) {
    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (_) {
        favoritesController.toggleFavorite(product);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppDecorations.cardDecoration,
        child: InkWell(
          onTap: () {
            Get.to(() => ProductDetailsPage(
                  product: product,
                  cartItems: cartController.cartItems.toList(),
                  onAddToCart: (p) => cartController.addToCart(p),
                  onRemoveFromCart: (id) => cartController.removeFromCart(id),
                  onUpdateQuantity: (id, qty) =>
                      cartController.updateQuantity(id, qty),
                ));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // صورة المنتج
                Hero(
                  tag: 'favorite_${product.id}',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrl.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // تفاصيل المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${product.price} ريال',
                        style: AppTextStyles.price,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (product.negotiable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'قابل للمقايضة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // أزرار الإجراءات
                Column(
                  children: [
                    // زر إزالة من المفضلة
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () =>
                          favoritesController.toggleFavorite(product),
                    ),
                    // زر إضافة للسلة
                    Obx(() {
                      final isInCart = cartController.isInCart(product.id);
                      return IconButton(
                        icon: Icon(
                          isInCart
                              ? Icons.shopping_cart
                              : Icons.add_shopping_cart,
                          color: isInCart ? Colors.green : AppColors.primary,
                        ),
                        onPressed: () {
                          if (isInCart) {
                            cartController.removeFromCart(product.id);
                          } else {
                            cartController.addToCart(product);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(FavoritesController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('مسح المفضلة'),
        content: const Text('هل تريد إزالة جميع المنتجات من المفضلة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearAllFavorites();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }
}
