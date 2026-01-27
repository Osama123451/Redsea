import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/orders_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    // التحقق من التبويب المبدئي (من الإشعارات)
    int initialTab = 0;
    if (Get.arguments != null && Get.arguments is Map) {
      initialTab = Get.arguments['initialTab'] ?? 0;
    }

    _tabController =
        TabController(length: 2, vsync: this, initialIndex: initialTab);
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
          Column(
            children: [
              _buildDeleteAllHeader(false),
              Expanded(child: _buildBuyerOrdersTab()),
            ],
          ),
          // تبويب طلبات واردة (كبائع)
          Column(
            children: [
              _buildDeleteAllHeader(true),
              Expanded(child: _buildSellerOrdersTab()),
            ],
          ),
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
          _buildDeleteAllHeader(false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map(
                    (item) => _buildItemRow(Map<String, dynamic>.from(item))),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'طريقة الدفع: ${_getPaymentMethodName(order['paymentMethod'])}'),
                    if (status == 'delivered' ||
                        status == 'cancelled' ||
                        status == 'payment_rejected' ||
                        status == 'refunded')
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteOrder(order['id']),
                        tooltip: 'حذف الطلب',
                      ),
                  ],
                ),
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
                    Row(
                      children: [
                        if (status == 'delivered' ||
                            status == 'cancelled' ||
                            status == 'payment_rejected' ||
                            status == 'refunded')
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => _confirmDeleteOrder(order['id']),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          'طلب #${order['id'].toString().substring(1, 6)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
                ...items.map(
                    (item) => _buildItemRow(Map<String, dynamic>.from(item))),
                const Divider(),
                Text(
                    'طريقة الدفع: ${_getPaymentMethodName(order['paymentMethod'])}'),
                if (order['address'] != null &&
                    order['address'].toString().isNotEmpty)
                  Text('العنوان: ${order['address']}'),
              ],
            ),
          ),

          // معلومات المشتري (للبائع فقط)
          _buildBuyerInfoSection(order),

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

  Widget _buildItemRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade100,
              child: item['imageUrl'] != null &&
                      item['imageUrl'].toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 20),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // اسم المنتج والكمية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'منتج',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'الكمية: ${item['quantity'] ?? 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // السعر
          Text(
            '${item['price']} ر.ي',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerInfoSection(Map<String, dynamic> order) {
    final buyerName = order['buyerName'] ?? 'مشتري';
    final buyerPhone = order['buyerPhone'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'بيانات المشتري',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  buyerName.isNotEmpty ? buyerName[0].toUpperCase() : 'M',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (buyerPhone.isNotEmpty)
                      Text(
                        buyerPhone,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              // أزرار التواصل
              Row(
                children: [
                  _buildContactButton(
                    icon: Icons.chat_outlined,
                    color: Colors.blue,
                    onTap: () => _startChatWithBuyer(order),
                  ),
                  const SizedBox(width: 8),
                  if (buyerPhone.isNotEmpty)
                    _buildContactButton(
                      icon: Icons.phone_outlined,
                      color: Colors.green,
                      onTap: () {
                        // نحن بحاجة لـ url_launcher لإجراء المكالمات
                        Get.snackbar('تنبيه', 'جاري طلب الرقم: $buyerPhone');
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAllHeader(bool isSeller) {
    return Obx(() {
      final list =
          isSeller ? _ordersController.sellerOrders : _ordersController.orders;
      final hasCompleted = list.any((o) =>
          o['status'] == 'delivered' ||
          o['status'] == 'cancelled' ||
          o['status'] == 'payment_rejected' ||
          o['status'] == 'refunded');

      if (!hasCompleted) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _confirmClearAll(isSeller),
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('حذف الكل المكتمل',
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

  void _confirmDeleteOrder(String orderId) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب من السجل؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _ordersController.deleteOrder(orderId);
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
        content:
            const Text('هل أنت متأكد من حذف جميع الطلبات المكتملة والملغاة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _ordersController.clearOrders(isSeller);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _startChatWithBuyer(Map<String, dynamic> order) {
    final buyerId = order['userId'];
    final buyerName = order['buyerName'] ?? 'مشتري';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (buyerId != null && currentUserId != null) {
      final String chatId = _ordersController.getChatId(currentUserId, buyerId);
      Get.toNamed('/chat', arguments: {
        'chatId': chatId,
        'otherUserId': buyerId,
        'otherUserName': buyerName,
      });
    }
  }
}
