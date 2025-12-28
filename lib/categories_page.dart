import 'package:flutter/material.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/core/app_theme.dart';

class CategoriesPage extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesPage({super.key, required this.onCategorySelected});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref().child('products');

  // استخدام ألوان موحدة من AppColors
  static const List<Color> _defaultGradient = [
    AppColors.primaryLight,
    AppColors.primaryDark
  ];

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'الكل',
      'icon': Icons.all_inclusive,
    },
    {
      'name': 'الكترونيات',
      'icon': Icons.computer,
    },
    {
      'name': 'أجهزة منزلية',
      'icon': Icons.kitchen,
    },
    {
      'name': 'ملابس',
      'icon': Icons.checkroom,
    },
    {
      'name': 'عطور',
      'icon': Icons.spa,
    },
    {
      'name': 'ساعات',
      'icon': Icons.watch,
    },
    {
      'name': 'سيارات',
      'icon': Icons.directions_car,
    },
    {
      'name': 'أثاث',
      'icon': Icons.chair,
    },
    {
      'name': 'خدمات',
      'icon': Icons.design_services,
    },
    {
      'name': 'أخرى',
      'icon': Icons.category,
    },
  ];

  Map<String, int> categoryProductCounts = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCategoryCounts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final snapshot = await _productsRef.once();
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        Map<String, int> counts = {};

        for (var category in categories) {
          counts[category['name']] = 0;
        }

        data.forEach((key, value) {
          final productData = Map<String, dynamic>.from(value);
          final category = productData['category'] ?? 'أخرى';
          counts[category] = (counts[category] ?? 0) + 1;
          // زيادة العداد لـ "الكل"
          counts['الكل'] = (counts['الكل'] ?? 0) + 1;
        });

        setState(() {
          categoryProductCounts = counts;
        });
      }
    } catch (e) {
      debugPrint('Error loading category counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'تصفح حسب القسم',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${categories.length} تصنيفات متاحة',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      final animationValue = Curves.easeOutBack.transform(
                        (((_animationController.value - delay) / 0.4)
                            .clamp(0.0, 1.0)),
                      );
                      return Transform.scale(
                        scale: animationValue,
                        child: Opacity(
                          opacity: animationValue.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCategoryCard(categories[index]),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final productCount = categoryProductCounts[category['name']] ?? 0;

    return GestureDetector(
      onTap: () => widget.onCategorySelected(category['name']),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _defaultGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // خلفية زخرفية
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // المحتوى
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الأيقونة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // اسم التصنيف
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // عدد المنتجات
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$productCount منتج',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
}
