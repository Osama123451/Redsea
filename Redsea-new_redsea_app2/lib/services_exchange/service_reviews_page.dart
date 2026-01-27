import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';

/// صفحة عرض جميع تقييمات خدمة معينة
class ServiceReviewsPage extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final double initialRating;
  final int reviewsCount;

  const ServiceReviewsPage({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    this.initialRating = 0,
    this.reviewsCount = 0,
  });

  @override
  State<ServiceReviewsPage> createState() => _ServiceReviewsPageState();
}

class _ServiceReviewsPageState extends State<ServiceReviewsPage> {
  final ServiceController _controller = Get.find<ServiceController>();
  String _sortBy = 'newest'; // newest, highest, lowest
  int _filterRating = 0; // 0 = all, 1-5 = specific rating

  @override
  void initState() {
    super.initState();
    _controller.loadServiceReviews(widget.serviceId);
  }

  List<ServiceReview> get _filteredReviews {
    List<ServiceReview> reviews = _controller.serviceReviews.toList();

    // فلترة حسب التقييم
    if (_filterRating > 0) {
      reviews =
          reviews.where((r) => r.rating.round() == _filterRating).toList();
    }

    // ترتيب
    switch (_sortBy) {
      case 'highest':
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      default: // newest
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return reviews;
  }

  Map<int, int> get _ratingDistribution {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _controller.serviceReviews) {
      int rating = review.rating.round().clamp(1, 5);
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildStatsSection(),
          ),
          SliverToBoxAdapter(
            child: _buildFiltersSection(),
          ),
          Obx(() {
            if (_controller.isLoadingReviews.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reviews = _filteredReviews;
            if (reviews.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyState(),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildReviewCard(reviews[index]),
                  childCount: reviews.length,
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text(
          'أضف تقييمك',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'التقييمات والمراجعات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          // اسم الخدمة
          Text(
            widget.serviceTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // توزيع التقييمات
              Expanded(
                flex: 2,
                child: Obx(() => Column(
                      children: List.generate(5, (index) {
                        int rating = 5 - index;
                        int count = _ratingDistribution[rating] ?? 0;
                        int total = _controller.serviceReviews.length;
                        double percentage = total > 0 ? count / total : 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                '$rating',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      rating >= 4
                                          ? Colors.green
                                          : rating >= 3
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    )),
              ),

              const SizedBox(width: 20),

              // المتوسط العام
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.initialRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < widget.initialRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              )),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          '${_controller.serviceReviews.length} تقييم',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // فلتر التقييم
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _buildRatingChip(0, 'الكل'),
                ...List.generate(
                    5, (i) => _buildRatingChip(5 - i, '${5 - i} ⭐')),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // الترتيب
          Row(
            children: [
              Obx(() => Text(
                    '${_filteredReviews.length} تقييم',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                      DropdownMenuItem(
                          value: 'highest', child: Text('الأعلى تقييماً')),
                      DropdownMenuItem(
                          value: 'lowest', child: Text('الأقل تقييماً')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sortBy = value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRatingChip(int rating, String label) {
    final isSelected = _filterRating == rating;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        onSelected: (selected) {
          setState(() => _filterRating = selected ? rating : 0);
        },
      ),
    );
  }

  Widget _buildReviewCard(ServiceReview review) {
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // معلومات المقيّم
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
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            )),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
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

          // التعليق
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment,
                style: const TextStyle(height: 1.5),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                Icons.rate_review,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _filterRating > 0
                  ? 'لا توجد تقييمات بـ $_filterRating نجوم'
                  : 'لا توجد تقييمات بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'كن أول من يقيّم هذه الخدمة!',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
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
                          )),
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
              final success = await _controller.addReview(
                serviceId: widget.serviceId,
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
}
