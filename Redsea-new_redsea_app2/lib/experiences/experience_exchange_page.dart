import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/experience_swap_controller.dart';
import 'package:redsea/models/experience_swap_model.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:intl/intl.dart';

class ExperienceExchangePage extends StatelessWidget {
  const ExperienceExchangePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ExperienceSwapController controller =
        Get.put(ExperienceSwapController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تبادل الخبرات'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الطلبات الواردة'),
              Tab(text: 'الطلبات المرسلة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsList(controller, isIncoming: true),
            _buildRequestsList(controller, isIncoming: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(ExperienceSwapController controller,
      {required bool isIncoming}) {
    return Obx(() {
      final requests = isIncoming
          ? controller.incomingRequests
          : controller.outgoingRequests;

      if (requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isIncoming ? Icons.call_received : Icons.call_made,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                isIncoming
                    ? 'لا يوجد طلبات واردة حالياً'
                    : 'لم تقم بإرسال أي طلبات بعد',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request, isIncoming, controller);
        },
      );
    });
  }

  Widget _buildRequestCard(ExperienceSwapRequest request, bool isIncoming,
      ExperienceSwapController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.statusText,
                    style: TextStyle(
                        color: request.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(request.timestamp),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildExpMiniInfo(
                      'خبرتك',
                      isIncoming
                          ? request.targetExperienceTitle
                          : request.offeredExperienceTitle),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, color: AppColors.primary),
                ),
                Expanded(
                  child: _buildExpMiniInfo(
                    isIncoming
                        ? 'خبرة ${request.requesterName}'
                        : 'خبرة الطرف الآخر',
                    isIncoming
                        ? request.offeredExperienceTitle
                        : request.targetExperienceTitle,
                  ),
                ),
              ],
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  request.message,
                  style: const TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (isIncoming && request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.updateRequestStatus(
                          request.id, 'rejected', request.requesterId),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.updateRequestStatus(
                          request.id, 'accepted', request.requesterId),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                      child: const Text('قبول'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpMiniInfo(String label, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
