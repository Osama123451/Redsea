import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/add_product_page.dart';
import 'package:redsea/services_exchange/add_service_page.dart';
import 'package:redsea/experiences/add_experience_page.dart';

/// صفحة إضافة إعلان - اختيار نوع الإعلان
class AddListingPage extends StatelessWidget {
  const AddListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text(
            'إضافة إعلان جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header مع Illustration
              _buildHeader(),

              const SizedBox(height: 24),

              // خيارات الإضافة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ماذا تريد إضافته؟',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر نوع الإعلان الذي تريد نشره',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // خيار 1: منتج أو سلعة
                    _buildOptionCard(
                      icon: Icons.inventory_2,
                      title: 'منتج أو سلعة',
                      subtitle: 'بيع أو مقايضة منتجاتك مع الآخرين',
                      color: AppColors.primary,
                      features: [
                        'إضافة صور متعددة',
                        'تحديد السعر والعملة',
                        'إمكانية المقايضة',
                      ],
                      onTap: () => _goToAddProduct(),
                    ),

                    const SizedBox(height: 16),

                    // خيار 2: خبرة أو خدمة
                    _buildOptionCard(
                      icon: Icons.psychology,
                      title: 'خبرة أو خدمة',
                      subtitle: 'شارك خبراتك وقدم خدماتك للآخرين',
                      color: Colors.purple,
                      features: [
                        'عرض تخصصك ومهاراتك',
                        'تحديد سنوات الخبرة',
                        'تبادل الخبرات',
                      ],
                      onTap: () => _goToAddExperience(),
                    ),

                    const SizedBox(height: 16),

                    // خيار 3: خدمة مهنية
                    _buildOptionCard(
                      icon: Icons.work,
                      title: 'خدمة مهنية',
                      subtitle: 'اعرض خدماتك المهنية للعملاء',
                      color: Colors.teal,
                      features: [
                        'إنشاء باقات للخدمة',
                        'تحديد مدة التنفيذ',
                        'تبادل الخدمات',
                      ],
                      onTap: () => _goToAddService(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_circle_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'أضف إعلانك الآن',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'وابدأ رحلتك في عالم التبادل والتجارة',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () => _checkLoginAndGo(onTap),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // المميزات
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        feature,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _checkLoginAndGo(VoidCallback action) {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لإضافة إعلان')) return;
    action();
  }

  void _goToAddProduct() {
    Get.to(() => const AddProductPage());
  }

  void _goToAddExperience() {
    // محاولة فتح صفحة إضافة خبرة
    try {
      Get.to(() => const AddExperiencePage());
    } catch (_) {
      Get.snackbar(
        'قريباً',
        'صفحة إضافة الخبرات قيد التطوير',
        backgroundColor: Colors.purple,
        colorText: Colors.white,
      );
    }
  }

  void _goToAddService() {
    try {
      Get.to(() => const AddServicePage());
    } catch (_) {
      Get.snackbar(
        'قريباً',
        'صفحة إضافة الخدمات قيد التطوير',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    }
  }
}
