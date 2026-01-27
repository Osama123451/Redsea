import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/swap_controller.dart';
import 'package:redsea/app/controllers/experience_swap_controller.dart';
import 'package:redsea/models/experience_swap_model.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/services/chat_service.dart';

/// صفحة طلبات المقايضة الواردة والصادرة
class SwapRequestsPage extends StatefulWidget {
  final int initialTabIndex;

  const SwapRequestsPage({super.key, this.initialTabIndex = 0});

  @override
  State<SwapRequestsPage> createState() => _SwapRequestsPageState();
}

class _SwapRequestsPageState extends State<SwapRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SwapController get swapController => Get.find<SwapController>();
  ExperienceSwapController get experienceSwapController =>
      Get.find<ExperienceSwapController>();
  String _selectedCategory = 'products'; // 'products' or 'experiences'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    // Controllers are now registered in InitialBinding
    // Just ensure they are loaded
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildCategoryToggle(),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Obx(() {
                    int count = _selectedCategory == 'products'
                        ? swapController.pendingRequestsCount
                        : experienceSwapController.incomingRequests
                            .where((r) => r.status == 'pending')
                            .length;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox),
                          const SizedBox(width: 8),
                          const Text('الواردة'),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$count',
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
                    );
                  }),
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
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // الطلبات الواردة
          Column(
            children: [
              _buildDeleteAllHeader(isIncoming: true),
              Expanded(child: _buildRequestsList(isIncoming: true)),
            ],
          ),
          // الطلبات المرسلة
          Column(
            children: [
              _buildDeleteAllHeader(isIncoming: false),
              Expanded(child: _buildRequestsList(isIncoming: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList({required bool isIncoming}) {
    return Obx(() {
      if (_selectedCategory == 'products') {
        final requests = isIncoming
            ? swapController.incomingRequests
            : swapController.outgoingRequests;

        if (swapController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (requests.isEmpty) {
          return _buildEmptyState(isIncoming);
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
      } else {
        // Experience Exchanges
        final requests = isIncoming
            ? experienceSwapController.incomingRequests
            : experienceSwapController.outgoingRequests;

        if (experienceSwapController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (requests.isEmpty) {
          return _buildEmptyState(isIncoming);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildExperienceRequestCard(requests[index],
                isIncoming: isIncoming);
          },
        );
      }
    });
  }

  Widget _buildEmptyState(bool isIncoming) {
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
          if (_selectedCategory == 'products') ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                swapController.loadSwapRequests();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleItem(
            label: 'المنتجات',
            icon: Icons.inventory_2_outlined,
            isSelected: _selectedCategory == 'products',
            onTap: () => setState(() => _selectedCategory = 'products'),
          ),
          const SizedBox(width: 12),
          _buildToggleItem(
            label: 'الخبرات',
            icon: Icons.psychology_outlined,
            isSelected: _selectedCategory == 'experiences',
            onTap: () => setState(() => _selectedCategory = 'experiences'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceRequestCard(ExperienceSwapRequest request,
      {required bool isIncoming}) {
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
                if (request.status == 'accepted' ||
                    request.status == 'rejected' ||
                    request.status == 'cancelled')
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 20),
                    onPressed: () =>
                        _confirmDeleteExperienceRequest(request.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showExperienceDetailsById(
                    isIncoming
                        ? request.offeredExperienceId
                        : request.targetExperienceId,
                  ),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('عرض التفاصيل',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.psychology, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text('نوع التبادل: خبرات مهنية',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            if (request.status == 'accepted') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openExperienceChat(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('بدء المحادثة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            if (isIncoming && request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          experienceSwapController.updateRequestStatus(
                              request.id, 'rejected', request.requesterId),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('رفض'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAcceptExperience(request),
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
              Row(
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
                  if (request.status == 'completed' ||
                      request.status == 'rejected' ||
                      request.status == 'cancelled')
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () => _confirmDeleteSwapRequest(
                          request.id, request.status == 'completed'),
                    ),
                ],
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
                  productId: request.offeredProductId,
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
                  productId: request.targetProductId,
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
    required String productId,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showProductDetailsById(productId),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      '(عرض التفاصيل)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      final success = await swapController.acceptSwapRequest(request);
      if (success) {
        // بعد القبول، نسأل المستخدم عن حالة العرض في المتجر
        _showPostSwapListingDialog(
          itemId: request.targetProductId,
          isExperience: false,
          title: request.targetProductName,
        );
      }
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

  void _showProductDetailsById(String productId) async {
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('products/$productId')
          .get();
      Get.back(); // Close loading

      if (snapshot.value != null) {
        final productData = Map<String, dynamic>.from(snapshot.value as Map);
        final product = Product.fromMap({...productData, 'id': productId});
        Get.to(() => ProductDetailsPage(product: product, isViewOnly: true));
      } else {
        Get.snackbar('تنبيه', 'لم يتم العثور على المنتج');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'فشل في تحميل تفاصيل المنتج');
    }
  }

  void _showExperienceDetailsById(String? experienceId) async {
    if (experienceId == null) return;
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('experiences/$experienceId')
          .get();
      Get.back(); // Close loading

      if (snapshot.value != null) {
        final expData = Map<String, dynamic>.from(snapshot.value as Map);
        final exp = Experience.fromMap(experienceId, expData);
        _showExperienceBottomSheet(exp);
      } else {
        Get.snackbar('تنبيه', 'لم يتم العثور على الخبرة');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'فشل في تحميل تفاصيل الخبرة');
    }
  }

  void _showExperienceBottomSheet(Experience exp) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40, height: 4, color: Colors.grey.shade300)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(exp.expertName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  CircleAvatar(
                      backgroundImage: NetworkImage(exp.imageUrl), radius: 30),
                ],
              ),
              const SizedBox(height: 10),
              Text(exp.title,
                  style: TextStyle(color: AppColors.primary, fontSize: 16)),
              const SizedBox(height: 20),
              const Text('نبذة', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(exp.description,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              if (exp.skills.isNotEmpty) ...[
                const Text('المهارات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: exp.skills
                      .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade100))
                      .toList(),
                )
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openExperienceChat(ExperienceSwapRequest request) async {
    final chatService = ChatService();
    final otherUserId = Get.find<ExperienceSwapController>().currentUserId ==
            request.requesterId
        ? request.targetExpertId
        : request.requesterId;

    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);
    try {
      final chatId = await chatService.createOrGetExperienceChat(
        otherUserId,
        request.targetExperienceId,
      );
      final otherUserName = await chatService.getUserName(otherUserId);

      Get.back(); // Close loading
      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ));
    } catch (e) {
      Get.back();
      Get.snackbar('خطأ', 'فشل في فتح المحادثة');
    }
  }

  void _handleAcceptExperience(ExperienceSwapRequest request) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('قبول طلب التبادل', textAlign: TextAlign.center),
        content: const Text(
          'هل تريد قبول طلب تبادل الخبرات هذا؟',
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
      await experienceSwapController.updateRequestStatus(
          request.id, 'accepted', request.requesterId);
      // بعد القبول، نسأل عن الرؤية
      _showPostSwapListingDialog(
        itemId: request.targetExperienceId,
        isExperience: true,
        title: request.targetExperienceTitle,
      );
    }
  }

  void _showPostSwapListingDialog({
    required String itemId,
    required bool isExperience,
    required String title,
  }) {
    Get.dialog(
      AlertDialog(
        title:
            const Text('مبروك! تمت المقايضة 🎉', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('لقد حصلت على: $title',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'هل تريد عرض هذا الصنف في المتجر للبيع أو المقايضة مرة أخرى، أم تفضل الاحتفاظ به خاصاً بك؟',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isExperience) {
                      experienceSwapController.updateExperienceVisibility(
                          itemId, true);
                    } else {
                      swapController.updateProductVisibility(itemId, true);
                    }
                    Get.back();
                    Get.snackbar('تم', 'تم عرض الصنف في المتجر');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('عرض للبيع والمقايضة 🛒'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (isExperience) {
                      experienceSwapController.updateExperienceVisibility(
                          itemId, false);
                    } else {
                      swapController.updateProductVisibility(itemId, false);
                    }
                    Get.back();
                    Get.snackbar('تم', 'تم حفظ الصنف كمنتج خاص');
                  },
                  child: const Text('حفظ كصنف خاص (مخفي) 🔒'),
                ),
              ),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDeleteAllHeader({required bool isIncoming}) {
    return Obx(() {
      bool hasCompleted = false;
      if (_selectedCategory == 'products') {
        final list = isIncoming
            ? swapController.incomingRequests
            : swapController.outgoingRequests;
        hasCompleted = list.any((r) =>
            r.status == 'completed' ||
            r.status == 'rejected' ||
            r.status == 'cancelled');
      } else {
        final list = isIncoming
            ? experienceSwapController.incomingRequests
            : experienceSwapController.outgoingRequests;
        hasCompleted = list.any((r) =>
            r.status == 'accepted' ||
            r.status == 'rejected' ||
            r.status == 'cancelled');
      }

      if (!hasCompleted) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _confirmClearAll(isIncoming),
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

  void _confirmDeleteExperienceRequest(String requestId) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا طلب تبادل الخبرات؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              experienceSwapController.deleteRequest(requestId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSwapRequest(String id, bool isArchived) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الطلب'),
        content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              swapController.deleteSwapRequest(id, isArchived: isArchived);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(bool isIncoming) {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف الجميع'),
        content: const Text('هل أنت متأكد من حذف جميع الطلبات المنتهية؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (_selectedCategory == 'products') {
                swapController.clearSwapRequests(isIncoming);
              } else {
                experienceSwapController.clearRequests(isIncoming);
              }
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
