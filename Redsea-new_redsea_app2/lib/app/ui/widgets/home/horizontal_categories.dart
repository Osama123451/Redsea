import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/routes/app_routes.dart';

/// قائمة الفئات الأفقية
class HorizontalCategories extends StatelessWidget {
  final List<CategoryItem>? categories;
  final Function(CategoryItem)? onCategoryTap;

  const HorizontalCategories({
    super.key,
    this.categories,
    this.onCategoryTap,
  });

  // الفئات الافتراضية - "خبرات" أولاً
  List<CategoryItem> get _defaultCategories => [
        CategoryItem(
          id: 'experiences',
          name: 'خبرات',
          icon: Icons.psychology,
          color: Colors.purple,
          route: AppRoutes.experiences,
        ),
        CategoryItem(
          id: 'barter',
          name: 'منتجات للمقايضة',
          icon: Icons.swap_horiz,
          color: Colors.orange,
        ),
        CategoryItem(
          id: 'electronics',
          name: 'إلكترونيات',
          icon: Icons.phone_android,
          color: AppColors.primary,
        ),
        CategoryItem(
          id: 'cars',
          name: 'سيارات',
          icon: Icons.directions_car,
          color: Colors.orange,
        ),
        CategoryItem(
          id: 'realestate',
          name: 'عقارات',
          icon: Icons.home_work,
          color: Colors.brown,
        ),
        CategoryItem(
          id: 'fashion',
          name: 'أزياء',
          icon: Icons.checkroom,
          color: Colors.pink,
        ),
        CategoryItem(
          id: 'furniture',
          name: 'أثاث',
          icon: Icons.chair,
          color: Colors.amber.shade700,
        ),
        CategoryItem(
          id: 'sports',
          name: 'رياضة',
          icon: Icons.sports_soccer,
          color: Colors.green,
        ),
        CategoryItem(
          id: 'more',
          name: 'المزيد',
          icon: Icons.grid_view,
          color: Colors.grey,
          route: AppRoutes.categories,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = categories ?? _defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التصنيفات',
                style: AppTextStyles.headline3,
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.categories),
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
        ),
        const SizedBox(height: 12),
        // قائمة الفئات
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    return GestureDetector(
      onTap: () {
        if (onCategoryTap != null) {
          onCategoryTap!(category);
        } else if (category.route != null) {
          Get.toNamed(category.route!);
        } else {
          // التنقل للفئة
          Get.toNamed(AppRoutes.searchResults, arguments: category.name);
        }
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الأيقونة في دائرة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    category.color.withValues(alpha: 0.2),
                    category.color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: category.color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            // اسم الفئة
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// نموذج بيانات الفئة
class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? route;
  final String? imageUrl;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.route,
    this.imageUrl,
  });
}
