import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for consultations
    final List<Map<String, dynamic>> consultations = [
      {
        'name': 'خبير سيارات - أحمد',
        'type': 'فحص محرك',
        'date': '2024-05-20',
        'status': 'مكتملة',
        'statusColor': Colors.green,
      },
      {
        'name': 'مهندس ديكور - سارة',
        'type': 'تصميم صالة',
        'date': '2024-05-18',
        'status': 'قيد التنفيذ',
        'statusColor': Colors.orange,
      },
      {
        'name': 'خبير تقني - علي',
        'type': 'استشارة برمجة',
        'date': '2024-05-15',
        'status': 'ملغاة',
        'statusColor': Colors.red,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text('استشاراتي',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final item = consultations[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (item['statusColor'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['status'],
                    style: TextStyle(
                        color: item['statusColor'],
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(item['name'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('نوع الاستشارة: ${item['type']}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(item['date'],
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(width: 12),
                // Icon/Avatar placeholder
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.assignment,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
