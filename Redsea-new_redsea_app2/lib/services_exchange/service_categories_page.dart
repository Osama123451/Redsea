import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/category_services_page.dart';

/// صفحة فئات الخدمات - عرض شبكي احترافي
class ServiceCategoriesPage extends StatefulWidget {
  const ServiceCategoriesPage({super.key});

  @override
  State<ServiceCategoriesPage> createState() => _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends State<ServiceCategoriesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final DatabaseReference _servicesRef =
      FirebaseDatabase.instance.ref().child('services');

  Map<String, int> categoryServiceCounts = {};
  bool _isLoading = true;

  // بيانات الفئات مع الأيقونات - نستخدم الألوان من ServiceCategory
  List<Map<String, dynamic>> get categories => [
        {
          'name': 'الكل',
          'icon': Icons.apps,
        },
        {
          'name': 'تصميم',
          'icon': Icons.brush,
        },
        {
          'name': 'برمجة',
          'icon': Icons.code,
        },
        {
          'name': 'تصوير',
          'icon': Icons.camera_alt,
        },
        {
          'name': 'كتابة وترجمة',
          'icon': Icons.edit_note,
        },
        {
          'name': 'تسويق رقمي',
          'icon': Icons.trending_up,
        },
        {
          'name': 'صيانة وإصلاح',
          'icon': Icons.build,
        },
        {
          'name': 'تدريس وتعليم',
          'icon': Icons.school,
        },
        {
          'name': 'إنتاج صوتي ومرئي',
          'icon': Icons.music_note,
        },
        {
          'name': 'أخرى',
          'icon': Icons.more_horiz,
        },
      ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadCategoryCounts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final snapshot = await _servicesRef.once();
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        Map<String, int> counts = {};
        int totalCount = 0;

        for (var category in categories) {
          counts[category['name']] = 0;
        }

        data.forEach((key, value) {
          final serviceData = Map<String, dynamic>.from(value);

          // إظهار جميع الخدمات المتاحة (بما فيها خدمات المستخدم)
          // سيتم تمييز خدمات المستخدم ومنع التفاعل معها في صفحة التفاصيل
          final bool isAvailable = serviceData['isAvailable'] ?? true;

          if (isAvailable) {
            final category = serviceData['category'] ?? 'أخرى';
            counts[category] = (counts[category] ?? 0) + 1;
            totalCount++;
          }
        });

        counts['الكل'] = totalCount;

        setState(() {
          categoryServiceCounts = counts;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading category counts: $e');
      setState(() => _isLoading = false);
      _animationController.forward();
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
            child: _buildHeader(),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),

          // Loading or Grid
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
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
                        final delay = index * 0.08;
                        final animationValue = Curves.easeOutBack.transform(
                          (((_animationController.value - delay) / 0.5)
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // زر الرجوع والعنوان
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'فئات الخدمات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // للتوازن
            ],
          ),
          const SizedBox(height: 16),
          // إحصائيات
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${categories.length - 1} تصنيف متاح',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.design_services,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${categoryServiceCounts['الكل'] ?? 0} خدمة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'ابحث عن فئة...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final String categoryName = category['name'];
    final serviceCount = categoryServiceCounts[categoryName] ?? 0;
    final gradientColors = ServiceCategory.getGradient(categoryName);

    return GestureDetector(
      onTap: () {
        // تجاوز الفئات التي لا تحتوي على خدمات (ما عدا 'الكل')
        if (serviceCount == 0 && categoryName != 'الكل') {
          Get.snackbar(
            'لا توجد خدمات',
            'لا توجد خدمات متاحة في هذه الفئة حالياً',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
          return;
        }
        Get.to(
          () => CategoryServicesPage(categoryName: categoryName),
          transition: Transition.rightToLeftWithFade,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // زخرفة خلفية
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
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الأيقونة
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // اسم الفئة
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // عدد الخدمات
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$serviceCount خدمة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // سهم للدخول
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
