import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/app/core/app_theme.dart';

class SelectExperienceToOfferPage extends StatelessWidget {
  final Experience targetExperience;

  const SelectExperienceToOfferPage(
      {super.key, required this.targetExperience});

  @override
  Widget build(BuildContext context) {
    final ExperiencesController controller = Get.find<ExperiencesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر خبرتك للمبادلة'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final myExperiences = controller.myExperiences;

        if (myExperiences.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('ليس لديك خبرات مضافة بعد'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('إضافة خبرة أولاً'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myExperiences.length,
          itemBuilder: (context, index) {
            final exp = myExperiences[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(ExperienceCategory.getIcon(exp.category),
                      color: AppColors.primary),
                ),
                title: Text(exp.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(exp.category),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Get.back(result: exp);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
