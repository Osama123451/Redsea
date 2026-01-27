import 'package:flutter/material.dart';
import 'dart:async';
import 'package:redsea/app/core/app_theme.dart';

/// Carousel للعروض الترويجية
class BannerSlider extends StatefulWidget {
  final List<BannerItem>? banners;
  final double height;
  final Duration autoPlayDuration;
  final Function(BannerItem)? onBannerTap;

  const BannerSlider({
    super.key,
    this.banners,
    this.height = 160,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.onBannerTap,
  });

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  // بيانات افتراضية للبانرات
  late List<BannerItem> _banners;

  @override
  void initState() {
    super.initState();
    // Start at a large index to allow infinite scrolling in both directions
    _pageController = PageController(initialPage: 5000, viewportFraction: 0.92);
    _banners = widget.banners ?? _defaultBanners;
    _startAutoPlay();
  }

  List<BannerItem> get _defaultBanners => [
        BannerItem(
          id: '1',
          imageUrl:
              'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800',
          title: 'عروض حصرية',
          subtitle: 'خصم يصل إلى 50%',
          gradient: [AppColors.primary, AppColors.primaryDark],
        ),
        BannerItem(
          id: '2',
          imageUrl:
              'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
          title: 'منتجات جديدة',
          subtitle: 'اكتشف أحدث المنتجات',
          gradient: [Colors.orange.shade600, Colors.deepOrange],
        ),
        BannerItem(
          id: '3',
          imageUrl:
              'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=800',
          title: 'مقايضة ذكية',
          subtitle: 'بادل منتجاتك بسهولة',
          gradient: [Colors.green.shade600, Colors.teal],
        ),
      ];

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (timer) {
      if (_banners.isNotEmpty && mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index % _banners.length);
              },
              // Infinite items
              itemBuilder: (context, index) {
                final bannerIndex = index % _banners.length;
                return _buildBannerCard(_banners[bannerIndex]);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // مؤشرات النقاط
        _buildIndicators(),
      ],
    );
  }

  Widget _buildBannerCard(BannerItem banner) {
    return GestureDetector(
      onTap: () => widget.onBannerTap?.call(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors:
                banner.gradient ?? [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (banner.gradient?.first ?? AppColors.primary)
                  .withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // صورة الخلفية
            if (banner.imageUrl != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.network(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'تسوق الآن',
                      style: TextStyle(
                        color: banner.gradient?.first ?? AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // أيقونة ديكورية
            Positioned(
              left: -20,
              top: -20,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// نموذج بيانات البانر
class BannerItem {
  final String id;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final List<Color>? gradient;
  final String? actionUrl;

  BannerItem({
    required this.id,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    this.gradient,
    this.actionUrl,
  });
}
