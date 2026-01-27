import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/add_service_page.dart';
import 'package:redsea/services_exchange/edit_service_page.dart';

/// صفحة خدماتي
class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late ServiceController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ServiceController>();
    controller.loadMyServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدماتي'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // زر تحديث
          IconButton(
            onPressed: () {
              controller.loadMyServices();
              setState(() {}); // تحديث الواجهة
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Obx(() {
        final services = controller.myServices;
        debugPrint('=== MyServicesPage Obx rebuild ===');
        debugPrint('myServices length: ${services.length}');

        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_special_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'لا توجد خدمات مضافة',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () =>
                      Get.to(() => const AddServicePage())?.then((_) {
                    controller.loadMyServices();
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('أضف خدمة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index]);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddServicePage())?.then((_) {
          controller.loadMyServices();
        }),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ServiceCategory.getColor(service.category)
                      .withValues(alpha: 0.8),
                  ServiceCategory.getColor(service.category)
                      .withValues(alpha: 0.4),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // زر الحذف
                IconButton(
                  onPressed: () => _confirmDelete(service),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // زر التعديل
                IconButton(
                  onPressed: () =>
                      Get.to(() => EditServicePage(service: service))
                          ?.then((_) {
                    controller.loadMyServices();
                  }),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    service.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  ServiceCategory.getIcon(service.category),
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // الحالة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: service.isAvailable
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        service.isAvailable ? 'متاحة' : 'غير متاحة',
                        style: TextStyle(
                          color:
                              service.isAvailable ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // القيمة والمدة
                    Row(
                      children: [
                        Text(
                          '${service.estimatedValue.toStringAsFixed(0)} ريال',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '⏱ ${service.duration}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Service service) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الخدمة', textAlign: TextAlign.center),
        content: Text('هل تريد حذف "${service.title}"؟',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteService(service.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
