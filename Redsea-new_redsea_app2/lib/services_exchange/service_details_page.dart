import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/add_service_page.dart';
import 'package:redsea/services_exchange/edit_service_page.dart';
import 'package:redsea/services_exchange/service_provider_profile_page.dart';
import 'package:redsea/services_exchange/service_reviews_page.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:redsea/chat/chat_page.dart';

/// صفحة تفاصيل الخدمة - تصميم احترافي
class ServiceDetailsPage extends StatefulWidget {
  final Service service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  late ServiceController controller;
  int selectedPackageIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ServiceController>();
    // زيادة عدد المشاهدات
    controller.incrementViews(widget.service.id);
    // تحميل التقييمات
    controller.loadServiceReviews(widget.service.id);
    // تحميل المفضلة
    controller.loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header مع التصميم
          _buildSliverAppBar(),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // العنوان والتصنيف ومستوى البائع
                  _buildTitleSection(),

                  const SizedBox(height: 20),

                  // معلومات صاحب الخدمة
                  _buildSellerInfoCard(),

                  const SizedBox(height: 20),

                  // الباقات (إن وجدت)
                  if (widget.service.packages.isNotEmpty)
                    _buildPackagesSection(),

                  const SizedBox(height: 20),

                  // الوصف
                  _buildInfoCard(
                    title: 'وصف الخدمة',
                    icon: Icons.description,
                    child: Text(
                      widget.service.description,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // القيمة والمدة
                  _buildValueDurationRow(),

                  const SizedBox(height: 16),

                  // معرض الأعمال
                  if (widget.service.portfolio.isNotEmpty)
                    _buildPortfolioSection(),

                  const SizedBox(height: 16),

                  // الخدمات المفضلة للتبادل
                  if (widget.service.swapPreferences.isNotEmpty) ...[
                    _buildInfoCard(
                      title: 'يفضّل التبادل مع',
                      icon: Icons.swap_horiz,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: widget.service.swapPreferences
                            .map((pref) => Chip(
                                  label: Text(pref,
                                      style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.grey.shade100,
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // قسم التقييمات والمراجعات
                  _buildReviewsSection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // زر طلب التبادل
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: ServiceCategory.getColor(widget.service.category),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      actions: [
        // زر الحذف (للمالك فقط)
        if (widget.service.ownerId == controller.currentUserId)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'حذف الخدمة',
            onPressed: () => _showDeleteServiceDialog(),
          ),
        // زر المفضلة
        Obx(() => IconButton(
              icon: Icon(
                controller.isFavorite(widget.service.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: () => controller.toggleFavorite(widget.service.id),
            )),
        // زر المشاركة
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            Get.snackbar('قريباً', 'ميزة المشاركة قادمة قريباً');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                ServiceCategory.getColor(widget.service.category),
                ServiceCategory.getColor(widget.service.category)
                    .withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // خلفية ديكورية
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // أيقونة التصنيف
              Center(
                child: Icon(
                  ServiceCategory.getIcon(widget.service.category),
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              // شارة مميز
              if (widget.service.isFeatured)
                Positioned(
                  left: 16,
                  top: 80,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'خدمة مميزة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // مستوى البائع
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.service.sellerLevel.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.service.sellerLevel.color,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.service.sellerLevel.arabicName,
                    style: TextStyle(
                      color: widget.service.sellerLevel.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.service.sellerLevel.icon,
                    size: 16,
                    color: widget.service.sellerLevel.color,
                  ),
                ],
              ),
            ),
            // التصنيف
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ServiceCategory.getColor(widget.service.category)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.service.category,
                    style: TextStyle(
                      color: ServiceCategory.getColor(widget.service.category),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    ServiceCategory.getIcon(widget.service.category),
                    size: 16,
                    color: ServiceCategory.getColor(widget.service.category),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildSellerInfoCard() {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceProviderProfilePage(
            providerId: widget.service.ownerId,
            providerName: widget.service.ownerName,
          )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
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
            Row(
              children: [
                // إحصائيات سريعة
                if (widget.service.rating > 0)
                  _buildMiniStat(
                    icon: Icons.star,
                    value: widget.service.rating.toStringAsFixed(1),
                    label: '(${widget.service.reviewsCount})',
                    color: Colors.amber,
                  ),
                if (widget.service.completedOrders > 0)
                  _buildMiniStat(
                    icon: Icons.check_circle,
                    value: '${widget.service.completedOrders}',
                    label: 'مكتمل',
                    color: Colors.green,
                  ),
                const Spacer(),
                // معلومات البائع
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.service.ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'مقدم الخدمة',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.service.ownerName.isNotEmpty
                            ? widget.service.ownerName[0]
                            : '؟',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    // شارة المستوى
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.service.sellerLevel.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          widget.service.sellerLevel.icon,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // إحصائيات إضافية
            if (widget.service.responseRate > 0 ||
                widget.service.responseTime.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (widget.service.responseTime.isNotEmpty)
                    _buildStatItem(
                      icon: Icons.timer,
                      label: 'وقت الاستجابة',
                      value: widget.service.responseTime,
                    ),
                  if (widget.service.responseRate > 0)
                    _buildStatItem(
                      icon: Icons.reply,
                      label: 'معدل الاستجابة',
                      value: '${(widget.service.responseRate * 100).toInt()}%',
                    ),
                  if (widget.service.viewsCount > 0)
                    _buildStatItem(
                      icon: Icons.visibility,
                      label: 'المشاهدات',
                      value: '${widget.service.viewsCount}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'الباقات المتاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.inventory_2, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: widget.service.packages.length,
            itemBuilder: (context, index) {
              final package = widget.service.packages[index];
              final isSelected = selectedPackageIndex == index;
              return GestureDetector(
                onTap: () => setState(() => selectedPackageIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        package.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            package.duration,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11),
                          ),
                          Text(
                            '${package.price.toStringAsFixed(0)} ر.س',
                            style: TextStyle(
                              color:
                                  isSelected ? AppColors.primary : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildValueDurationRow() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'مدة التنفيذ',
            icon: Icons.timer,
            child: Text(
              widget.service.duration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            title: 'القيمة التقديرية',
            icon: Icons.attach_money,
            child: widget.service.isSpecialOffer &&
                    widget.service.oldEstimatedValue != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${(((widget.service.oldEstimatedValue! - widget.service.estimatedValue) / widget.service.oldEstimatedValue!) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'عرض خاص!',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.service.oldEstimatedValue!.toStringAsFixed(0)} ريال',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '${widget.service.estimatedValue.toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '${widget.service.estimatedValue.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'معرض الأعمال',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.collections, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: widget.service.portfolio.length,
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(widget.service.portfolio[index]),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                ),
                child: widget.service.portfolio[index].isEmpty
                    ? Center(
                        child: Icon(Icons.image,
                            color: Colors.grey.shade400, size: 40),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAddReviewDialog(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('تقييم', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.to(() => ServiceReviewsPage(
                          serviceId: widget.service.id,
                          serviceTitle: widget.service.title,
                          initialRating: widget.service.rating,
                          reviewsCount: widget.service.reviewsCount,
                        )),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('الكل', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      'التقييمات والمراجعات',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.isLoadingReviews.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.serviceReviews.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.rate_review,
                      color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'كن أول من يقيّم هذه الخدمة!',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.serviceReviews.length,
            itemBuilder: (context, index) {
              final review = controller.serviceReviews[index];
              return _buildReviewCard(review);
            },
          );
        }),
      ],
    );
  }

  Widget _buildReviewCard(ServiceReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '؟',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(height: 1.5),
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
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

  void _showAddReviewDialog() {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(message: 'سجّل دخولك لإضافة تقييم')) {
      return;
    }

    final commentController = TextEditingController();
    final rating = 5.0.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('أضف تقييمك', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('كيف تقيّم هذه الخدمة؟'),
            const SizedBox(height: 16),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      onPressed: () => rating.value = i + 1.0,
                      icon: Icon(
                        i < rating.value ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              textAlign: TextAlign.right,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا...',
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
            onPressed: () async {
              final success = await controller.addReview(
                serviceId: widget.service.id,
                rating: rating.value,
                comment: commentController.text.trim(),
              );
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  /// نافذة تأكيد حذف الخدمة
  void _showDeleteServiceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('حذف الخدمة'),
            SizedBox(width: 8),
            Icon(Icons.warning, color: Colors.red),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الخدمة؟\n\nلا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteService(widget.service.id);
              if (success) {
                Get.back(result: true);
                Get.snackbar(
                  'تم الحذف',
                  'تم حذف الخدمة بنجاح',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isOwnService = widget.service.ownerId == controller.currentUserId;
    final cartController = Get.find<CartController>();

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: isOwnService
          ? // إذا كانت خدمة المستخدم الحالي - إظهار زر التعديل
          Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => EditServicePage(service: widget.service));
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'تعديل الخدمة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : // إذا كانت خدمة شخص آخر - إظهار أزرار السلة والتواصل والتبادل
          Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الصف الأول: زر إضافة للسلة
                Obx(() {
                  final isInCart =
                      cartController.isServiceInCart(widget.service.id);
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final authController = Get.find<AuthController>();
                        if (!authController.requireLogin(
                            message: 'سجّل دخولك لإضافة الخدمة للسلة')) {
                          return;
                        }
                        if (isInCart) {
                          cartController
                              .removeServiceFromCart(widget.service.id);
                        } else {
                          cartController.addServiceToCart(widget.service);
                        }
                      },
                      icon: Icon(isInCart
                          ? Icons.remove_shopping_cart
                          : Icons.add_shopping_cart),
                      label: Text(
                        isInCart
                            ? 'إزالة من السلة'
                            : 'أضف للسلة - ${widget.service.estimatedValue.toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                // الصف الثاني: زر التواصل وطلب التبادل
                Row(
                  children: [
                    // زر المحادثة
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final authController = Get.find<AuthController>();
                          if (!authController.requireLogin(
                              message: 'سجّل دخولك للتواصل مع مقدم الخدمة')) {
                            return;
                          }
                          try {
                            Get.snackbar(
                              'جاري التحميل...',
                              'يتم فتح المحادثة',
                              showProgressIndicator: true,
                              duration: const Duration(seconds: 2),
                            );
                            String chatId = await ChatService().createOrGetChat(
                              widget.service.ownerId,
                              'service_${widget.service.id}', // استخدام معرف الخدمة بدلاً من اسم المالك
                            );
                            Get.to(() => ChatPage(
                                  chatId: chatId,
                                  otherUserId: widget.service.ownerId,
                                  otherUserName: widget.service.ownerName,
                                ));
                          } catch (e) {
                            Get.snackbar(
                              'خطأ',
                              'فشل فتح المحادثة: $e',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label:
                            const Text('تواصل', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر طلب التبادل
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showSwapRequestDialog(context),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('طلب تبادل',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showSwapRequestDialog(BuildContext context) {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(message: 'سجّل دخولك لطلب تبادل')) {
      return;
    }

    if (controller.myServices.isEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('لا توجد خدمات', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'يجب أن تضيف خدمة أولاً لتتمكن من طلب التبادل',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                // الانتقال لصفحة إضافة خدمة مع اقتراح الفئة
                Get.to(() => AddServicePage(
                      initialCategory: widget.service.swapPreferences.isNotEmpty
                          ? widget.service.swapPreferences.first
                          : null,
                    ));
              },
              icon: const Icon(Icons.add),
              label: const Text('أضف خدمة الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
      return;
    }

    final messageController = TextEditingController();
    final selectedService = Rxn<Service>();

    Get.bottomSheet(
      ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'طلب تبادل خدمة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر خدمة من خدماتك للتبادل مقابل "${widget.service.title}"',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('خدماتي:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: Obx(() => ListView.builder(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        itemCount: controller.myServices.length,
                        itemBuilder: (context, index) {
                          final myService = controller.myServices[index];
                          return Obx(() => GestureDetector(
                                onTap: () => selectedService.value = myService,
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(left: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: selectedService.value?.id ==
                                            myService.id
                                        ? AppColors.primary
                                            .withValues(alpha: 0.1)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedService.value?.id ==
                                              myService.id
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(
                                        ServiceCategory.getIcon(
                                            myService.category),
                                        color: ServiceCategory.getColor(
                                            myService.category),
                                      ),
                                      const Spacer(),
                                      Text(
                                        myService.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ],
                                  ),
                                ),
                              ));
                        },
                      )),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'رسالة إضافية (اختياري)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                            onPressed: selectedService.value == null
                                ? null
                                : () async {
                                    final success =
                                        await controller.sendSwapRequest(
                                      targetService: widget.service,
                                      offeredService: selectedService.value!,
                                      message: messageController.text.trim(),
                                    );
                                    if (success) {
                                      Get.back();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('إرسال الطلب'),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
