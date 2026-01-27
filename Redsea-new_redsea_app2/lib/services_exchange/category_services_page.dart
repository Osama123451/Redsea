import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services_exchange/service_details_page.dart';
import 'package:redsea/services_exchange/add_service_page.dart';

/// صفحة عرض الخدمات حسب الفئة
class CategoryServicesPage extends StatefulWidget {
  final String categoryName;

  const CategoryServicesPage({super.key, required this.categoryName});

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage> {
  final ServiceController _serviceController = Get.find<ServiceController>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _sortBy = 'newest'; // newest, rating, price_low, price_high
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set category filter after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceController.selectedCategory.value = widget.categoryName;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Service> get _filteredServices {
    List<Service> services = widget.categoryName == 'الكل'
        ? _serviceController.allServices.toList()
        : _serviceController.allServices
            .where((s) => s.category == widget.categoryName)
            .toList();

    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      services = services
          .where((s) =>
              s.title.contains(_searchQuery) ||
              s.description.contains(_searchQuery) ||
              s.ownerName.contains(_searchQuery))
          .toList();
    }

    // تطبيق الترتيب
    switch (_sortBy) {
      case 'rating':
        services.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price_low':
        services.sort((a, b) => a.estimatedValue.compareTo(b.estimatedValue));
        break;
      case 'price_high':
        services.sort((a, b) => b.estimatedValue.compareTo(a.estimatedValue));
        break;
      default: // newest
        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return services;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          _buildSliverAppBar(),

          // Search and Filter
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(),
          ),

          // Services Grid
          Obx(() {
            final services = _filteredServices;

            if (_serviceController.isLoading.value) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (services.isEmpty) {
              return SliverToBoxAdapter(
                child: _buildEmptyState(),
              );
            }

            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${services.length} خدمة متاحة',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.miscellaneous_services,
                            color: Colors.grey.shade600, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: services.length,
                      itemBuilder: (context, index) =>
                          _buildHorizontalServiceCard(services[index]),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }),
        ],
      ),
      // زر إضافة خدمة في الفئة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddService,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'أضف خدمتك',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 18,
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
          child: Stack(
            children: [
              // زخرفة خلفية
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
              // أيقونة الفئة
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ServiceCategory.getIcon(widget.categoryName),
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // شريط البحث
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'ابحث في ${widget.categoryName}...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // شريط الفلاتر
          Row(
            children: [
              // عدد النتائج
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filteredServices.length} خدمة',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )),

              const Spacer(),

              // قائمة الترتيب
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
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('الأحدث'),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: Text('الأعلى تقييماً'),
                      ),
                      DropdownMenuItem(
                        value: 'price_low',
                        child: Text('السعر: الأقل'),
                      ),
                      DropdownMenuItem(
                        value: 'price_high',
                        child: Text('السعر: الأعلى'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بطاقة الخدمة للعرض الأفقي
  Widget _buildHorizontalServiceCard(Service service) {
    return GestureDetector(
      onTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(
            message: 'سجّل دخولك لعرض تفاصيل الخدمة')) {
          return;
        }
        Get.to(() => ServiceDetailsPage(service: service));
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // صورة الخدمة
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: ServiceCategory.getColor(service.category)
                    .withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: service.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(service.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (service.images.isEmpty)
                    Center(
                      child: Icon(
                        ServiceCategory.getIcon(service.category),
                        size: 40,
                        color: ServiceCategory.getColor(service.category),
                      ),
                    ),
                  // شارات
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Wrap(
                      spacing: 4,
                      children: [
                        if (service.ownerId == _serviceController.currentUserId)
                          _buildMiniBadge('خدمتك', AppColors.primary),
                        if (service.isFeatured)
                          _buildMiniBadge('مميز', Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // المعلومات
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // العنوان
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // اسم المقدم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            service.ownerName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade500),
                      ],
                    ),
                    const Spacer(),
                    // التقييم والسعر
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // التقييم
                        if (service.rating > 0)
                          Row(
                            children: [
                              Text(
                                service.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        // السعر
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${service.estimatedValue.toStringAsFixed(0)} ر.ي',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
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

  /// شارة صغيرة
  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () {
        final authController = Get.find<AuthController>();
        if (!authController.requireLogin(
            message: 'سجّل دخولك لعرض تفاصيل الخدمة')) {
          return;
        }
        Get.to(() => ServiceDetailsPage(service: service));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الخدمة
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ServiceCategory.getColor(service.category)
                        .withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    image: service.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(service.images.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: service.images.isEmpty
                      ? Center(
                          child: Icon(
                            ServiceCategory.getIcon(service.category),
                            size: 50,
                            color: ServiceCategory.getColor(service.category),
                          ),
                        )
                      : null,
                ),

                // شارات
                Positioned(
                  top: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      // شارة "خدمتك" للخدمات الخاصة بالمستخدم
                      if (service.ownerId == _serviceController.currentUserId)
                        _buildBadge('خدمتك', AppColors.primary, Icons.person),
                      if (service.isFeatured)
                        _buildBadge('مميز', Colors.orange, Icons.star),
                      if (service.swapPreferences.isNotEmpty)
                        _buildBadge(
                            'قابل للمقايضة', Colors.green, Icons.swap_horiz),
                    ],
                  ),
                ),

                // مستوى البائع
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: service.sellerLevel.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          service.sellerLevel.icon,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.sellerLevel.arabicName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // معلومات الخدمة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // اسم المقدم
                  Row(
                    children: [
                      // التقييم
                      Row(
                        children: [
                          Text(
                            '(${service.reviewsCount})',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                      const Spacer(),
                      // اسم المقدم
                      Text(
                        service.ownerName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          service.ownerName.isNotEmpty
                              ? service.ownerName[0]
                              : '؟',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // عنوان الخدمة
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // الوصف المختصر
                  Text(
                    service.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // السعر والمدة
                  Row(
                    children: [
                      // المدة
                      Row(
                        children: [
                          Text(
                            service.duration,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.timer_outlined,
                              size: 16, color: Colors.grey.shade500),
                        ],
                      ),
                      const Spacer(),
                      // السعر
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'يبدأ من ${service.estimatedValue.toStringAsFixed(0)} ر.ي',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
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
              ServiceCategory.getIcon(widget.categoryName),
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد خدمات في هذه الفئة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات مختلفة'
                : 'كن أول من يضيف خدمة في ${widget.categoryName}',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة للفئات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// الانتقال لصفحة إضافة خدمة مع تحديد الفئة مسبقاً
  void _navigateToAddService() {
    final authController = Get.find<AuthController>();
    if (!authController.requireLogin(message: 'سجّل دخولك لإضافة خدمة جديدة')) {
      return;
    }
    Get.to(() => AddServicePage(initialCategory: widget.categoryName));
  }
}
