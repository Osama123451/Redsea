import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/service_details_page.dart';
import 'package:redsea/chat/chat_page.dart';

/// صفحة ملف مقدم الخدمة
class ServiceProviderProfilePage extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ServiceProviderProfilePage({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ServiceProviderProfilePage> createState() =>
      _ServiceProviderProfilePageState();
}

class _ServiceProviderProfilePageState
    extends State<ServiceProviderProfilePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final RxBool _isLoading = true.obs;
  final RxList<Service> _providerServices = <Service>[].obs;
  final RxMap<String, dynamic> _providerStats = <String, dynamic>{}.obs;
  final RxString _providerBio = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    _isLoading.value = true;
    try {
      // تحميل خدمات مقدم الخدمة
      final servicesSnapshot = await _dbRef
          .child('services')
          .orderByChild('ownerId')
          .equalTo(widget.providerId)
          .get();

      if (servicesSnapshot.exists && servicesSnapshot.value != null) {
        List<Service> services = [];
        Map<dynamic, dynamic> data =
            servicesSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            services
                .add(Service.fromMap(key, Map<dynamic, dynamic>.from(value)));
          }
        });
        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _providerServices.value = services;

        // حساب الإحصائيات
        double totalRating = 0;
        int totalReviews = 0;
        int totalCompleted = 0;
        for (var service in services) {
          totalRating += service.rating * service.reviewsCount;
          totalReviews += service.reviewsCount;
          totalCompleted += service.completedOrders;
        }

        _providerStats.value = {
          'servicesCount': services.length,
          'averageRating': totalReviews > 0 ? totalRating / totalReviews : 0.0,
          'totalReviews': totalReviews,
          'completedOrders': totalCompleted,
          'sellerLevel': services.isNotEmpty
              ? services.first.sellerLevel
              : SellerLevel.beginner,
        };
      }

      // تحميل معلومات المستخدم
      final userSnapshot =
          await _dbRef.child('users/${widget.providerId}').get();

      if (userSnapshot.exists && userSnapshot.value != null) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        _providerBio.value = userData['bio']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadProviderData,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildProfileHeader()),
              SliverToBoxAdapter(child: _buildStatsSection()),
              if (_providerBio.value.isNotEmpty)
                SliverToBoxAdapter(child: _buildBioSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_providerServices.length} خدمة',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      const Text(
                        'خدمات مقدم الخدمة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildServicesList(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      }),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
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
                left: -30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final sellerLevel = _providerStats['sellerLevel'] ?? SellerLevel.beginner;

    return Transform.translate(
      offset: const Offset(0, -40),
      child: Column(
        children: [
          // صورة البروفايل
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    widget.providerName.isNotEmpty
                        ? widget.providerName[0]
                        : '؟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: sellerLevel.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    sellerLevel.icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الاسم
          Text(
            widget.providerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // مستوى البائع
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: sellerLevel.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(sellerLevel.icon, size: 16, color: sellerLevel.color),
                const SizedBox(width: 4),
                Text(
                  sellerLevel.arabicName,
                  style: TextStyle(
                    color: sellerLevel.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.work,
                value: '${_providerStats['servicesCount'] ?? 0}',
                label: 'خدمة',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.star,
                value:
                    (_providerStats['averageRating'] ?? 0.0).toStringAsFixed(1),
                label: 'التقييم',
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: '${_providerStats['completedOrders'] ?? 0}',
                label: 'مكتمل',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.rate_review,
                value: '${_providerStats['totalReviews'] ?? 0}',
                label: 'تقييم',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'نبذة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.person, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _providerBio.value,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    if (_providerServices.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.work_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'لا توجد خدمات',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildServiceCard(_providerServices[index]),
          childCount: _providerServices.length,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceDetailsPage(service: service)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // صورة الخدمة
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ServiceCategory.getColor(service.category),
                    ServiceCategory.getColor(service.category)
                        .withValues(alpha: 0.6),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  ServiceCategory.getIcon(service.category),
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),

            // المحتوى
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              service.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                          ],
                        ),
                        Text(
                          '${service.estimatedValue.toStringAsFixed(0)} ر.ي',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final authController = Get.find<AuthController>();

    // لا تظهر الشريط لنفس المستخدم
    if (authController.userId == widget.providerId) {
      return const SizedBox.shrink();
    }

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
      child: ElevatedButton.icon(
        onPressed: _startChat,
        icon: const Icon(Icons.chat_bubble),
        label: const Text(
          'محادثة مع مقدم الخدمة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }

  Future<void> _startChat() async {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(message: 'سجّل دخولك للتواصل')) {
      return;
    }

    // إنشاء أو فتح محادثة
    final currentUserId = authController.userId!;
    final chatId = _generateChatId(currentUserId, widget.providerId);

    Get.to(() => ChatPage(
          chatId: chatId,
          otherUserId: widget.providerId,
          otherUserName: widget.providerName,
        ));
  }

  String _generateChatId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
