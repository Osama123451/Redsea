import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/add_service_page.dart';
import 'package:redsea/services_exchange/service_details_page.dart';
import 'package:redsea/services_exchange/my_services_page.dart';
import 'package:redsea/services_exchange/service_requests_page.dart';
import 'package:redsea/services_exchange/service_categories_page.dart';

/// الصفحة الرئيسية لتبادل الخدمات - تصميم احترافي مشابه لـ Fiverr
class ServicesExchangePage extends StatefulWidget {
  const ServicesExchangePage({super.key});

  @override
  State<ServicesExchangePage> createState() => _ServicesExchangePageState();
}

class _ServicesExchangePageState extends State<ServicesExchangePage> {
  late ServiceController controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ServiceController>()) {
      Get.put(ServiceController());
    }
    controller = Get.find<ServiceController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadServices();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero Section مع AppBar
            _buildHeroSection(),

            // شريط البحث
            SliverToBoxAdapter(child: _buildSearchBar()),

            // إحصائيات سريعة
            SliverToBoxAdapter(child: _buildQuickStats()),

            // فئات الخدمات
            SliverToBoxAdapter(child: _buildCategoriesSection()),

            // الخدمات المميزة
            SliverToBoxAdapter(child: _buildFeaturedSection()),

            // عنوان جميع الخدمات
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                          '${controller.filteredServices.length} خدمة',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        )),
                    const Text(
                      'جميع الخدمات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // قائمة الخدمات
            _buildServicesGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // زر إضافة خدمة
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildHeroSection() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
        tooltip: 'رجوع',
      ),
      actions: [
        // زر خدماتي
        IconButton(
          icon: const Icon(Icons.folder_special, color: Colors.white),
          onPressed: () => Get.to(() => const MyServicesPage()),
          tooltip: 'خدماتي',
        ),
        // زر الطلبات
        Obx(() => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.inbox, color: Colors.white),
                  onPressed: () => Get.to(() => const ServiceRequestsPage()),
                  tooltip: 'الطلبات',
                ),
                if (controller.pendingRequestsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${controller.pendingRequestsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            )),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF0D47A1),
              ],
            ),
          ),
          child: Stack(
            children: [
              // خلفية ديكورية
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 0,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // المحتوى
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'منصة تبادل الخدمات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'بادل مهاراتك واحصل على ما تحتاجه',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => controller.searchQuery.value = value,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن خدمة...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    controller.searchQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Obx(() {
      final completedOrders = controller.totalCompletedOrders.value;
      final providers = controller.totalServiceProviders.value;
      final services = controller.totalAvailableServices.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'طلبات مكتملة',
                    completedOrders > 0 ? '$completedOrders' : '-',
                    Icons.check_circle,
                    Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'مقدم خدمة',
                    providers > 0 ? '$providers' : '-',
                    Icons.person,
                    Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'خدمة متاحة',
                    services > 0 ? '$services' : '-',
                    Icons.category,
                    Colors.orange)),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Get.to(() => const ServiceCategoriesPage());
                },
                icon: const Icon(Icons.grid_view, size: 18),
                label: const Text('عرض الكل'),
              ),
              const Text(
                'التصنيفات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount:
                ServiceCategory.categories.where((c) => c != 'الكل').length,
            itemBuilder: (context, index) {
              final categories =
                  ServiceCategory.categories.where((c) => c != 'الكل').toList();
              final category = categories[index];
              return Obx(() {
                final isSelected =
                    controller.selectedCategory.value == category;
                return GestureDetector(
                  onTap: () => controller.selectedCategory.value = category,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 85,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ServiceCategory.getColor(category)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? ServiceCategory.getColor(category)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: ServiceCategory.getColor(category)
                                    .withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          ServiceCategory.getIcon(category),
                          color: isSelected
                              ? Colors.white
                              : ServiceCategory.getColor(category),
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Obx(() {
      final featuredServices =
          controller.allServices.where((s) => s.isFeatured).toList();
      if (featuredServices.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'خدمات مميزة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: featuredServices.length,
              itemBuilder: (context, index) {
                return _buildFeaturedCard(featuredServices[index]);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFeaturedCard(Service service) {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceDetailsPage(service: service)),
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
        child: Stack(
          children: [
            // خلفية ملونة
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ServiceCategory.getColor(service.category),
                      ServiceCategory.getColor(service.category)
                          .withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    ServiceCategory.getIcon(service.category),
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            // شارة مميز
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'مميز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 90, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${service.estimatedValue.toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            service.ownerName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              service.ownerName.isNotEmpty
                                  ? service.ownerName[0]
                                  : '؟',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final services = controller.filteredServices;

      if (services.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search_off,
                      size: 48, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد خدمات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'كن أول من يضيف خدمة في هذا التصنيف!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      }

      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: services.length,
            itemBuilder: (context, index) => _buildServiceCard(services[index]),
          ),
        ),
      );
    });
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => Get.to(() => ServiceDetailsPage(service: service)),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
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
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      ServiceCategory.getIcon(service.category),
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  // شارة التصنيف
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        service.category,
                        style: TextStyle(
                          color: ServiceCategory.getColor(service.category),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // شارة مستوى البائع
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: service.sellerLevel.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service.sellerLevel.icon,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // تفاصيل الخدمة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    // صاحب الخدمة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            service.ownerName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            service.ownerName.isNotEmpty
                                ? service.ownerName[0]
                                : '؟',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // التقييم والسعر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.estimatedValue.toStringAsFixed(0),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (service.rating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  color: Colors.amber, size: 12),
                            ],
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

  Widget _buildFloatingButtons() {
    return FloatingActionButton(
      heroTag: 'add_service',
      onPressed: () {
        final authController = Get.find<AuthController>();
        if (authController.requireLogin(message: 'سجّل دخولك لإضافة خدمة')) {
          Get.to(() => const AddServicePage())?.then((_) {
            controller.loadServices();
            controller.loadMyServices();
          });
        }
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }
}
