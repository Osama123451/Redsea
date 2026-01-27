import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/ui/pages/profile/public_profile_page.dart';

/// صفحة إدارة طلبات الخدمات (الواردة والصادرة)
class ServiceOrdersPage extends StatefulWidget {
  const ServiceOrdersPage({super.key});

  @override
  State<ServiceOrdersPage> createState() => _ServiceOrdersPageState();
}

class _ServiceOrdersPageState extends State<ServiceOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServiceController _controller = Get.find<ServiceController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.loadServiceOrders();
    _controller.loadSellerServiceOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('طلبات الشراء (خدمات)'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Obx(() => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('طلبات واردة'),
                      if (_controller.sellerServiceOrders
                          .where((o) => o['status'] == 'pending_payment')
                          .isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_controller.sellerServiceOrders.where((o) => o['status'] == 'pending_payment').length}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  )),
            ),
            const Tab(text: 'طلباتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              _buildDeleteAllHeader(isSeller: true),
              Expanded(child: _buildOrdersList(isSeller: true)),
            ],
          ),
          Column(
            children: [
              _buildDeleteAllHeader(isSeller: false),
              Expanded(child: _buildOrdersList(isSeller: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList({required bool isSeller}) {
    return Obx(() {
      final orders = isSeller
          ? _controller.sellerServiceOrders
          : _controller.serviceOrders;

      if (orders.isEmpty) {
        return _buildEmptyState(isSeller);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _controller.loadServiceOrders();
          await _controller.loadSellerServiceOrders();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(orders[index], isSeller);
          },
        ),
      );
    });
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isSeller) {
    final status = order['status'] ?? 'pending_payment';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);
    final createdAt = order['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(order['createdAt'])
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'completed' || status == 'cancelled')
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => _confirmDeleteOrder(order['id']),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const Spacer(),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    if (isSeller && order['buyerId'] != null) {
                      Get.to(() => PublicProfilePage(userId: order['buyerId']));
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: AppColors.primary),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isSeller ? (order['buyerName'] ?? 'مشتري') : 'أنت',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          Text(
                            isSeller ? 'قام بشراء خدمتك' : 'قمت بشراء خدمة',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          isSeller ? (order['buyerName']?[0] ?? 'م') : 'أ',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Text(
                  order['serviceTitle'] ?? 'خدمة',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Text(
                  'السعر: ${order['price']} ريال',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                if (status == 'pending_payment' && isSeller) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmPayment(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تأكيد استلام المبلغ'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSeller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSeller ? Icons.inbox : Icons.shopping_basket,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSeller ? 'لا توجد طلبات واردة' : 'لم تقم بأي طلبات شراء',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_payment':
        return Colors.orange;
      case 'payment_confirmed':
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'في انتظار الدفع';
      case 'payment_confirmed':
        return 'تمت عملية الدفع';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'الآن';
    }
  }

  Future<void> _confirmPayment(String orderId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد استلام المبلغ'),
        content: const Text('هل أنت متأكد من استلام المبلغ بالكامل؟'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('لا')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('نعم، تأكيد'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _controller.confirmServicePayment(orderId);
    }
  }

  Widget _buildDeleteAllHeader({required bool isSeller}) {
    return Obx(() {
      final list = isSeller
          ? _controller.sellerServiceOrders
          : _controller.serviceOrders;
      final hasCompleted = list.any((o) =>
          o['status'] == 'completed' ||
          o['status'] == 'cancelled' ||
          o['status'] == 'rejected');

      if (!hasCompleted) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _confirmClearAll(isSeller),
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('حذف الكل المنتهي',
                  style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _confirmDeleteOrder(String id) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب من القائمة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.deleteServiceOrder(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(bool isSeller) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الجميع'),
        content: const Text('هل أنت متأكد من حذف جميع الطلبات المنتهية؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _controller.clearServiceOrders(isSeller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
