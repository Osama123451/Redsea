import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';

/// صفحة طلبات تبادل الخدمات
class ServiceRequestsPage extends StatefulWidget {
  const ServiceRequestsPage({super.key});

  @override
  State<ServiceRequestsPage> createState() => _ServiceRequestsPageState();
}

class _ServiceRequestsPageState extends State<ServiceRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ServiceController controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller = Get.find<ServiceController>();
    controller.loadSwapRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التبادل'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Obx(() => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox, size: 18),
                      const SizedBox(width: 8),
                      const Text('الواردة'),
                      if (controller.pendingRequestsCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${controller.pendingRequestsCount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.outbox, size: 18),
                  SizedBox(width: 8),
                  Text('المرسلة'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(isIncoming: true),
          _buildRequestsList(isIncoming: false),
        ],
      ),
    );
  }

  Widget _buildRequestsList({required bool isIncoming}) {
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
                isIncoming ? Icons.inbox_outlined : Icons.outbox_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                isIncoming ? 'لا توجد طلبات واردة' : 'لا توجد طلبات مرسلة',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadSwapRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index], isIncoming: isIncoming);
          },
        ),
      );
    });
  }

  Widget _buildRequestCard(ServiceSwapRequest request,
      {required bool isIncoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: request.statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // العنوان والحالة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: request.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.statusText,
                  style: TextStyle(
                    color: request.statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // تفاصيل التبادل
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildServiceRow(
                  label: isIncoming ? 'يعرض عليك' : 'تعرض',
                  serviceName: request.requesterServiceTitle,
                  icon: Icons.build_circle,
                  color: Colors.orange,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.swap_vert, color: Colors.grey),
                ),
                _buildServiceRow(
                  label: isIncoming ? 'مقابل خدمتك' : 'مقابل',
                  serviceName: request.targetServiceTitle,
                  icon: Icons.miscellaneous_services,
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // الرسالة
          if (request.message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${request.message}"',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // الوقت والمرسل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(request.timestamp),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              if (isIncoming)
                Text(
                  'من: ${request.requesterName}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
            ],
          ),

          // أزرار الإجراءات
          if (request.status == 'pending') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (isIncoming)
              _buildIncomingActions(request)
            else
              _buildOutgoingActions(request),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceRow({
    required String label,
    required String serviceName,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(
                serviceName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ],
    );
  }

  Widget _buildIncomingActions(ServiceSwapRequest request) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectDialog(request),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('رفض'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _acceptRequest(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('قبول'),
          ),
        ),
      ],
    );
  }

  Widget _buildOutgoingActions(ServiceSwapRequest request) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelRequest(request),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        icon: const Icon(Icons.cancel, size: 18),
        label: const Text('إلغاء الطلب'),
      ),
    );
  }

  void _acceptRequest(ServiceSwapRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('قبول الطلب', textAlign: TextAlign.center),
        content: const Text('هل تريد قبول طلب التبادل هذا؟',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('قبول', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.acceptSwapRequest(request);
    }
  }

  void _showRejectDialog(ServiceSwapRequest request) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('رفض الطلب', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سبب الرفض (اختياري):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب السبب هنا...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectSwapRequest(
                request,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelRequest(ServiceSwapRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء الطلب', textAlign: TextAlign.center),
        content: const Text('هل أنت متأكد من إلغاء الطلب؟',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('لا')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الطلب',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.cancelSwapRequest(request);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
