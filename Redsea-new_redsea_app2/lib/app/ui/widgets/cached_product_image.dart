import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget لعرض صور المنتجات مع التخزين المؤقت
/// يحسّن أداء التطبيق بتخزين الصور في الذاكرة المؤقتة
class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildError(),
        // خيارات التخزين المؤقت
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey.shade400,
          size: 40,
        ),
      ),
    );
  }
}

/// امتداد للـ BoxDecoration لاستخدام CachedNetworkImageProvider
/// يُستخدم في Container decoration
class CachedDecorationImage {
  /// إنشاء DecorationImage مع التخزين المؤقت
  static DecorationImage? create({
    required String imageUrl,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.isEmpty) return null;

    return DecorationImage(
      image: CachedNetworkImageProvider(imageUrl),
      fit: fit,
    );
  }
}
