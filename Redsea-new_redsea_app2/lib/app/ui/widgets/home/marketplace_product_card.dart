import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';

/// بطاقة منتج بتصميم Marketplace
class MarketplaceProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBarterTap;
  final bool showBarter;

  const MarketplaceProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onChatTap,
    this.onAddToCart,
    this.onBarterTap,
    this.showBarter = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة مع السعر والمفضلة
            _buildImageSection(),

            // المحتوى تحت الصورة
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // تفاصيل المنتج (الاسم)
                  _buildTitle(),
                  const SizedBox(height: 6),

                  // موقع المنتج
                  _buildLocation(),
                  const SizedBox(height: 8),

                  // حالة المنتج (Tag) والتاريخ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildConditionTag(),
                      _buildDate(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // أزرار الإجراءات
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // الصورة
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 1.1,
            child: _buildProductImage(),
          ),
        ),

        // زر المفضلة (أعلى اليسار)
        Positioned(
          top: 8,
          left: 8,
          child: _buildFavoriteButton(),
        ),

        // السعر (داخل الصورة - أسفل اليمين)
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${product.price} ر.ي',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // شارة المقايضة (أعلى اليمين إذا وجد)
        if (showBarter || product.isSwappable)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'مقايضة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductImage() {
    final imageUrl = product.imageUrl;

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: Colors.grey.shade300,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return GetBuilder<FavoritesController>(
      builder: (controller) {
        final isFavorite = controller.isFavorite(product.id);
        return GestureDetector(
          onTap: () {
            if (onFavoriteTap != null) {
              onFavoriteTap!();
            } else {
              final authController = Get.find<AuthController>();
              if (authController.requireLogin(
                  message: 'سجّل دخولك لإضافة للمفضلة')) {
                controller.toggleFavorite(product);
              }
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey.shade700,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      product.name,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            product.location ?? 'اليمن',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionTag() {
    final conditionText = product.conditionText;
    Color conditionColor = Colors.grey;

    switch (product.condition) {
      case ProductCondition.newProduct:
        conditionColor = Colors.green;
        break;
      case ProductCondition.usedGood:
        conditionColor = Colors.blue;
        break;
      case ProductCondition.usedFair:
        conditionColor = Colors.orange;
        break;
      default:
        conditionColor = Colors.grey;
    }

    // إذا كانت حالة "غير محدد" فلا داعي لعرض الـ Tag
    if (conditionText == 'غير محدد') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: conditionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: conditionColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        conditionText,
        style: TextStyle(
          color: conditionColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDate() {
    return Text(
      _formatDate(product.dateAdded),
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSwappable = product.isSwappable;

    return Row(
      children: [
        // زر أضف للسلة (الأساسي)
        Expanded(
          flex: 2,
          child: _buildButton(
            label: 'سلة',
            icon: Icons.add_shopping_cart,
            color: Colors.blue.shade600,
            onTap: onAddToCart ??
                () {
                  // منطق افتراضي للإضافة للسلة
                },
          ),
        ),
        const SizedBox(width: 4),

        // زر مقايضة (يظهر فقط إذا كان قابل للمقايضة)
        if (isSwappable) ...[
          Expanded(
            flex: 2,
            child: _buildButton(
              label: 'مقايضة',
              icon: Icons.swap_horiz,
              color: Colors.green.shade600,
              onTap: onBarterTap ??
                  () {
                    // منطق افتراضي للمقايضة
                  },
            ),
          ),
          const SizedBox(width: 4),
        ],

        // زر دردش
        Expanded(
          flex: 2,
          child: _buildButton(
            label: 'دردش',
            icon: Icons.chat_bubble_outline,
            color: Colors.orange.shade700,
            onTap: onChatTap ??
                () {
                  // منطق الدردشة الافتراضي
                },
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}
