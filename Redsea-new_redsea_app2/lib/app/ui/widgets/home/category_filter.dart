import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/categories_controller.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/search_results_page.dart';
import 'package:redsea/services_exchange/services_exchange_page.dart';

/// فلتر التصنيفات الأفقي
/// يعرض قائمة التصنيفات مع أيقونات ملونة
class CategoryFilter extends StatelessWidget {
  final VoidCallback onShowAllCategories;

  const CategoryFilter({
    super.key,
    required this.onShowAllCategories,
  });

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final categoriesController = Get.find<CategoriesController>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // رأس القسم مع زر عرض الكل
          _buildSectionHeader(),
          const SizedBox(height: 8),
          // التصنيفات الأفقية
          _buildCategoriesList(productController, categoriesController),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر عرض الكل (على اليسار)
          GestureDetector(
            onTap: onShowAllCategories,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios,
                      size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // العنوان (على اليمين) - الأيقونة قبل النص
          Row(
            children: [
              Icon(Icons.category, color: Colors.blue.shade600, size: 22),
              const SizedBox(width: 8),
              Text(
                'التصنيفات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(
    ProductController productController,
    CategoriesController categoriesController,
  ) {
    final categories = categoriesController.categories.map((name) {
      final style = _getCategoryStyle(name);
      return {
        'name': name,
        'icon': style['icon'],
        'color': style['color'],
      };
    }).toList();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryItem(category, productController);
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    Map<String, dynamic> category,
    ProductController productController,
  ) {
    return Obx(() {
      final isSelected =
          productController.selectedFilter.value == category['name'];
      return GestureDetector(
        onTap: () =>
            _handleCategoryTap(category['name'] as String, productController),
        child: Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      (category['color'] as Color).withValues(alpha: 0.8),
                      category['color'] as Color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color:
                          (category['color'] as Color).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : (category['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: isSelected ? Colors.white : category['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category['name'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }

  void _handleCategoryTap(
      String categoryName, ProductController productController) {
    if (categoryName == 'الكل') {
      // التوجيه مباشرة لصفحة الفئات
      onShowAllCategories();
    } else if (categoryName == 'خدمات') {
      final authController = Get.find<AuthController>();
      if (authController.requireLogin(
          message: 'سجّل دخولك للوصول لتبادل الخدمات')) {
        Get.to(() => const ServicesExchangePage());
      }
    } else {
      final filterController = Get.find<FilterController>();
      filterController.setCategory(categoryName);
      filterController.applyFilters();
      Get.to(() => const SearchResultsPage());
    }
  }

  Map<String, dynamic> _getCategoryStyle(String name) {
    switch (name) {
      case 'الكل':
        return {'icon': Icons.apps, 'color': Colors.blue};
      case 'الكترونيات':
        return {'icon': Icons.computer, 'color': Colors.indigo};
      case 'أجهزة منزلية':
        return {'icon': Icons.kitchen, 'color': Colors.teal};
      case 'ملابس':
        return {'icon': Icons.checkroom, 'color': Colors.pink};
      case 'عطور':
        return {'icon': Icons.spa, 'color': Colors.purple};
      case 'ساعات':
        return {'icon': Icons.watch, 'color': Colors.amber};
      case 'سيارات':
        return {'icon': Icons.directions_car, 'color': Colors.red};
      case 'أثاث':
        return {'icon': Icons.chair, 'color': Colors.brown};
      case 'خدمات':
        return {'icon': Icons.design_services, 'color': Colors.green};
      default:
        return {'icon': Icons.label, 'color': Colors.teal};
    }
  }
}
