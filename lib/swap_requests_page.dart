import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/swap_controller.dart';
import 'package:redsea/app/core/app_theme.dart';

/// صفحة طلبات المقايضة الواردة والصادرة
class SwapRequestsPage extends StatefulWidget {
  const SwapRequestsPage({super.key});

  @override
  State<SwapRequestsPage> createState() => _SwapRequestsPageState();
}

class _SwapRequestsPageState extends State<SwapRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SwapController swapController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // تأكد من وجود SwapController
    if (!Get.isRegistered<SwapController>()) {
      Get.put(SwapController());
    }
    swapController = Get.find<SwapController>();
    swapController.loadSwapRequests();
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
        title: const Text('طلبات المقايضة'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Obx(() => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox),
                      const SizedBox(width: 8),
                      const Text('الواردة'),
                      if (swapController.pendingRequestsCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${swapController.pendingRequestsCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
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
                  Icon(Icons.outbox),
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
          // الطلبات الواردة
          _buildRequestsList(isIncoming: true),
          // الطلبات المرسلة
          _buildRequestsList(isIncoming: false),
        ],
      ),
    );
  }

  Widget _buildRequestsList({required bool isIncoming}) {
    return Obx(() {
      final requests = isIncoming
          ? swapController.incomingRequests
          : swapController.outgoingRequests;

      if (swapController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: swapController.loadSwapRequests,
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

  Widget _buildRequestCard(SwapRequest request, {required bool isIncoming}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              // حالة الطلب
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
              // أيقونة المقايضة
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

          // تفاصيل المقايضة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // المنتج المعروض
                _buildProductRow(
                  label: isIncoming ? 'يعرض عليك' : 'تعرض',
                  productName: request.offeredProductName,
                  icon: Icons.sell,
                  color: Colors.orange,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.swap_vert, color: Colors.grey),
                ),
                // المنتج المطلوب
                _buildProductRow(
                  label: isIncoming ? 'مقابل منتجك' : 'مقابل',
                  productName: request.targetProductName,
                  icon: Icons.shopping_bag,
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // المبلغ الإضافي
          if (request.additionalMoney > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '+ ${request.additionalMoney.toStringAsFixed(0)} ريال',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.attach_money,
                      color: Colors.green.shade700, size: 20),
                ],
              ),
            ),
          ],

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

          // معلومات المرسل والوقت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(request.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              if (isIncoming)
                Text(
                  'من: ${request.requesterName}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
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

  Widget _buildProductRow({
    required String label,
    required String productName,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
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

  Widget _buildIncomingActions(SwapRequest request) {
    return Row(
      children: [
        // رفض
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
        // قبول
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

  Widget _buildOutgoingActions(SwapRequest request) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelRequest(request),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
        ),
        icon: const Icon(Icons.cancel, size: 18),
        label: const Text('إلغاء الطلب'),
      ),
    );
  }

  void _acceptRequest(SwapRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('قبول الطلب', textAlign: TextAlign.center),
        content: const Text(
          'هل تريد قبول طلب المقايضة هذا؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('قبول'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await swapController.acceptSwapRequest(request);
    }
  }

  void _showRejectDialog(SwapRequest request) {
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
              decoration: InputDecoration(
                hintText: 'اكتب السبب هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              swapController.rejectSwapRequest(
                request,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _cancelRequest(SwapRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء الطلب', textAlign: TextAlign.center),
        content: const Text(
          'هل أنت متأكد من إلغاء طلب المقايضة؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await swapController.cancelSwapRequest(request);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
