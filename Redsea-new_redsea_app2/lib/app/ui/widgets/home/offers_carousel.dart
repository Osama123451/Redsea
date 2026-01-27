import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// سلايدر الإعلانات والعروض الترويجية
/// يعرض صور بحواف دائرية مع مؤشر نقاط في الأسفل
class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _currentIndex = 0;

  // صور الإعلانات - يمكن استبدالها ببيانات ديناميكية من Firebase
  final List<Map<String, dynamic>> _banners = [
    {
      'image':
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800',
      'title': 'عروض مميزة',
      'subtitle': 'خصم يصل إلى 50%',
      'color': Colors.blue,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
      'title': 'تسوق الآن',
      'subtitle': 'أفضل المنتجات',
      'color': Colors.green,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
      'title': 'جديدنا',
      'subtitle': 'منتجات وصلت حديثاً',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // الكاروسيل
        CarouselSlider.builder(
          itemCount: _banners.length,
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final banner = _banners[index];
            return _buildBannerItem(banner);
          },
        ),
        const SizedBox(height: 12),
        // مؤشر النقاط
        _buildDotsIndicator(),
      ],
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (banner['color'] as Color).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // صورة الخلفية
            CachedNetworkImage(
              imageUrl: banner['image'] as String,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: banner['color'] as Color,
                child: const Icon(Icons.image, color: Colors.white, size: 50),
              ),
            ),
            // التدرج اللوني
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    (banner['color'] as Color).withValues(alpha: 0.9),
                    (banner['color'] as Color).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // النص
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    banner['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['subtitle'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? Colors.blue : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
