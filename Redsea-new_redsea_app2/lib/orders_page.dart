import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/orders_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:intl/intl.dart';

/// صفحة الطلبات - تبويب للمشتري وتبويب للبائع
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OrdersController _ordersController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ensure controller is registered
    if (Get.isRegistered<OrdersController>()) {
      _ordersController = Get.find<OrdersController>();
    } else {
      _ordersController = Get.put(OrdersController());
    }
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    await _ordersController.loadOrders();
    await _ordersController.loadSellerOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusText(String status) {
    return _ordersController.getStatusText(status);
  }

  Color _getStatusColor(String status) {
    return Color(_ordersController.getStatusColorValue(status));
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'kuraimi':
        return 'الكريمي';
      case 'jawali':
        return 'محفظة جوالي';
      case 'cashu':
        return 'كاش يو';
      case 'bank':
        return 'تحويل بنكي';
      case 'cod':
        return 'الدفع عند الاستلام';
      default:
        return method ?? 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Obx(() => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag),
                      const SizedBox(width: 8),
                      const Text('طلباتي'),
                      if (_ordersController.pendingOrdersCount.value > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_ordersController.pendingOrdersCount.value}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
            Obx(() => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store),
                      const SizedBox(width: 8),
                      const Text('طلبات واردة'),
                      if (_ordersController.pendingPaymentConfirmCount.value >
                          0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_ordersController.pendingPaymentConfirmCount.value}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب طلباتي (كمشتري)
          _buildBuyerOrdersTab(),
          // تبويب طلبات واردة (كبائع)
          _buildSellerOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildBuyerOrdersTab() {
    return Obx(() {
      if (_ordersController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_ordersController.orders.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('لم تقم بأي طلبات بعد',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ordersController.orders.length,
          itemBuilder: (context, index) {
            final order = _ordersController.orders[index];
            return _buildBuyerOrderCard(order);
          },
        ),
      );
    });
  }

  Widget _buildSellerOrdersTab() {
    return Obx(() {
      if (_ordersController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_ordersController.sellerOrders.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('لا توجد طلبات واردة',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _ordersController.sellerOrders.length,
          itemBuilder: (context, index) {
            final order = _ordersController.sellerOrders[index];
            return _buildSellerOrderCard(order);
          },
        ),
      );
    });
  }

  Widget _buildBuyerOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    final status = order['status'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          'طلب #${order['id'].toString().substring(1, 6)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy hh:mm a').format(
                  DateTime.fromMillisecondsSinceEpoch(order['timestamp'] ?? 0)),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          '${order['totalPrice']} ر.ي',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المنتجات:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('- ${item['name']} (x${item['quantity'] ?? 1})'),
                          Text('${item['price']} ر.ي'),
                        ],
                      ),
                    )),
                const Divider(),
                Text(
                    'طريقة الدفع: ${_getPaymentMethodName(order['paymentMethod'])}'),
                if (order['transactionNumber'] != null)
                  Text('رقم العملية: ${order['transactionNumber']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerOrderCard(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    final status = order['status'] ?? '';
    final isPaymentSubmitted = status == 'payment_submitted';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isPaymentSubmitted ? 4 : 2,
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPaymentSubmitted
                  ? Colors.orange.shade50
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      'طلب #${order['id'].toString().substring(1, 6)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              order['timestamp'] ?? 0)),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${order['totalPrice']} ر.ي',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // تفاصيل الطلب
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('المنتجات:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('- ${item['name']} (x${item['quantity'] ?? 1})'),
                          Text('${item['price']} ر.ي'),
                        ],
                      ),
                    )),
                const Divider(),
                Text(
                    'طريقة الدفع: ${_getPaymentMethodName(order['paymentMethod'])}'),
                if (order['address'] != null &&
                    order['address'].toString().isNotEmpty)
                  Text('العنوان: ${order['address']}'),
              ],
            ),
          ),

          // معلومات إثبات الدفع
          if (order['transactionNumber'] != null ||
              order['paymentReceiptUrl'] != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'إثبات الدفع',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.receipt, size: 18, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (order['transactionNumber'] != null)
                    Text('رقم العملية: ${order['transactionNumber']}'),
                  if (order['paymentReceiptUrl'] != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          _showReceiptImage(order['paymentReceiptUrl']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'عرض صورة الإيصال',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // أزرار تأكيد/رفض الدفع
          if (isPaymentSubmitted) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectPayment(order['id']),
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmPayment(order['id']),
                      icon: const Icon(Icons.check),
                      label: const Text('تأكيد استلام المبلغ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showReceiptImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'صورة الإيصال',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 8),
                            Text('فشل تحميل الصورة'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد استلام المبلغ'),
        content: const Text('هل تأكد أنك استلمت المبلغ في حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('نعم، تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _ordersController.confirmPayment(orderId);
      if (success) {
        Get.snackbar(
          'تم ✅',
          'تم تأكيد استلام المبلغ بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _rejectPayment(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('رفض الدفع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل أنت متأكد أن المبلغ لم يصل إلى حسابك؟'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, reasonController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('رفض'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      final success = await _ordersController.rejectPayment(
        orderId,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (success) {
        Get.snackbar(
          'تم',
          'تم رفض الدفع',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}
