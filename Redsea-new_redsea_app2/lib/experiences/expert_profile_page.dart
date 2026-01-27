import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';

class ExpertProfilePage extends StatelessWidget {
  final Map<String, dynamic>? expertData;

  const ExpertProfilePage({super.key, this.expertData});

  @override
  Widget build(BuildContext context) {
    // Demo data if expertData is null
    final String name = expertData?['name'] ?? 'أحمد محمد';
    final String bio = expertData?['bio'] ??
        'خبير في صيانة وإصلاح كافة أنواع السيارات الحديثة والقديمة خبرة أكثر من 10 سنوات في السوق اليمني.';
    final String specialty = expertData?['specialty'] ?? 'ميكانيكا سيارات';
    final int experienceYears = expertData?['experienceYears'] ?? 12;
    final double rating = expertData?['rating'] ?? 4.8;
    final String imageUrl = expertData?['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text('ملف الخبير',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Text(name[0],
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(specialty,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(rating.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            // Stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('سنوات الخبرة', experienceYears.toString()),
                  _buildStatItem('الاستشارات', '150+'),
                  _buildStatItem('التقييمات', '85'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Bio Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('السيرة الذاتية',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Logic to start chat
                    Get.snackbar('قريباً', 'بدء محادثة استشارية');
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('طلب استشارة الآن',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
