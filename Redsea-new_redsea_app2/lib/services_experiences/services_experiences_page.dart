import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/services/chat_service.dart';

/// صفحة الخبرات والخدمات الموحدة
class ServicesExperiencesPage extends StatefulWidget {
  final String? initialFilter; // الفلتر المبدئي (خبرات/خدمات)

  const ServicesExperiencesPage({super.key, this.initialFilter});

  @override
  State<ServicesExperiencesPage> createState() =>
      _ServicesExperiencesPageState();
}

class _ServicesExperiencesPageState extends State<ServicesExperiencesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  // الفئات الموحدة
  final List<Map<String, dynamic>> _categories = [
    {'name': 'الكل', 'icon': Icons.apps, 'color': AppColors.primary},
    {'name': 'خبرات تعليمية', 'icon': Icons.school, 'color': Colors.purple},
    {'name': 'خدمات مهنية', 'icon': Icons.work, 'color': Colors.teal},
    {'name': 'استشارات تقنية', 'icon': Icons.code, 'color': Colors.indigo},
    {'name': 'تصميم وجرافيك', 'icon': Icons.brush, 'color': Colors.pink},
    {'name': 'تسويق رقمي', 'icon': Icons.trending_up, 'color': Colors.orange},
    {'name': 'صيانة وإصلاح', 'icon': Icons.build, 'color': Colors.brown},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // تحديد التاب المبدئي
    if (widget.initialFilter == 'خبرات') {
      _tabController.index = 1;
    } else if (widget.initialFilter == 'خدمات') {
      _tabController.index = 2;
    }

    // التأكد من وجود الـ Controllers
    _initControllers();
  }

  void _initControllers() {
    if (!Get.isRegistered<ExperiencesController>()) {
      Get.put(ExperiencesController());
    }
    if (!Get.isRegistered<ServiceController>()) {
      Get.put(ServiceController());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // AppBar مع Header
              _buildSliverAppBar(),

              // شريط البحث
              SliverToBoxAdapter(child: _buildSearchBar()),

              // فلاتر الفئات
              SliverToBoxAdapter(child: _buildCategoryFilter()),

              // التابات
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'الكل'),
                      Tab(text: 'الخبرات'),
                      Tab(text: 'الخدمات'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllContent(),
              _buildExperiencesContent(),
              _buildServicesContent(),
            ],
          ),
        ),
        floatingActionButton: _buildFloatingButton(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AppBar
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_forward, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'الخبرات والخدمات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Pattern خلفي
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.network(
                    'https://www.transparenttextures.com/patterns/cubes.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // شريط البحث
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'ابحث عن خبير أو خدمة...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // فلتر الفئات
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = category['name']);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'],
                    size: 18,
                    color: isSelected ? Colors.white : category['color'],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المحتوى - الكل
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAllContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // الخبرات
          _buildSectionHeader('الخبرات', Icons.psychology),
          const SizedBox(height: 12),
          _buildExperiencesList(limit: 3),

          const SizedBox(height: 24),

          // الخدمات
          _buildSectionHeader('الخدمات', Icons.build),
          const SizedBox(height: 12),
          _buildServicesList(limit: 3),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            _tabController.animateTo(title == 'الخبرات' ? 1 : 2);
          },
          child: const Text('عرض الكل'),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المحتوى - الخبرات
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildExperiencesContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExperiencesList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExperiencesList({int? limit}) {
    return GetBuilder<ExperiencesController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        var experiences = controller.allExperiences.toList();

        // تطبيق الفلتر
        if (_selectedCategory != 'الكل') {
          experiences = experiences
              .where((e) =>
                  e.category.contains(_selectedCategory) ||
                  _selectedCategory.contains(e.category))
              .toList();
        }

        // تطبيق البحث
        if (_searchQuery.isNotEmpty) {
          experiences = experiences
              .where((e) =>
                  e.title.contains(_searchQuery) ||
                  e.expertName.contains(_searchQuery) ||
                  e.description.contains(_searchQuery))
              .toList();
        }

        // تحديد حد العرض
        if (limit != null && experiences.length > limit) {
          experiences = experiences.take(limit).toList();
        }

        if (experiences.isEmpty) {
          return _buildEmptyState('لا توجد خبرات', Icons.psychology);
        }

        return Column(
          children: experiences.map((e) => _buildExpertCard(e)).toList(),
        );
      },
    );
  }

  Widget _buildExpertCard(Experience experience) {
    return GestureDetector(
      onTap: () => _showExperienceDetails(experience),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة دائرية
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: experience.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: experience.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.primaryExtraLight,
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primaryExtraLight,
                          child: const Icon(Icons.person),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryExtraLight,
                        child: Center(
                          child: Text(
                            experience.expertName.isNotEmpty
                                ? experience.expertName[0].toUpperCase()
                                : 'خ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم والتخصص
                  Text(
                    experience.expertName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    experience.title,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // سنوات الخبرة والتقييم
                  Row(
                    children: [
                      Icon(Icons.work_history,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        experience.experienceText,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${experience.rating.toStringAsFixed(1)} (${experience.reviewsCount})',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // سعر الاستشارة
            if (experience.consultationPrice != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryExtraLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${experience.consultationPrice!.toInt()}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'ر.ي',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المحتوى - الخدمات
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildServicesContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildServicesList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildServicesList({int? limit}) {
    return GetBuilder<ServiceController>(
      builder: (controller) {
        if (controller.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        var services = controller.allServices.toList();

        // تطبيق الفلتر
        if (_selectedCategory != 'الكل') {
          services = services
              .where((s) =>
                  s.category.contains(_selectedCategory) ||
                  _selectedCategory.contains(s.category))
              .toList();
        }

        // تطبيق البحث
        if (_searchQuery.isNotEmpty) {
          services = services
              .where((s) =>
                  s.title.contains(_searchQuery) ||
                  s.ownerName.contains(_searchQuery) ||
                  s.description.contains(_searchQuery))
              .toList();
        }

        if (limit != null && services.length > limit) {
          services = services.take(limit).toList();
        }

        if (services.isEmpty) {
          return _buildEmptyState('لا توجد خدمات', Icons.build);
        }

        return Column(
          children: services.map((s) => _buildServiceCard(s)).toList(),
        );
      },
    );
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => _showServiceDetails(service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 2,
                child: service.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.images.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 40),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryExtraLight,
                        child: Icon(
                          ServiceCategory.getIcon(service.category),
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // مقدم الخدمة
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          service.ownerName.isNotEmpty
                              ? service.ownerName[0].toUpperCase()
                              : 'خ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.ownerName,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      // مستوى البائع
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              service.sellerLevel.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(service.sellerLevel.icon,
                                size: 12, color: service.sellerLevel.color),
                            const SizedBox(width: 4),
                            Text(
                              service.sellerLevel.arabicName,
                              style: TextStyle(
                                fontSize: 11,
                                color: service.sellerLevel.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // التقييم والسعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${service.rating.toStringAsFixed(1)} (${service.reviewsCount})',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Text(
                        'يبدأ من ${service.estimatedValue.toInt()} ر.ي',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

  // ══════════════════════════════════════════════════════════════════════════
  // Helper Widgets
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _addNew,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('إضافة', style: TextStyle(color: Colors.white)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Actions
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _refreshData() async {
    await Get.find<ExperiencesController>().loadExperiences();
    await Get.find<ServiceController>().loadServices();
  }

  void _addNew() {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لإضافة خبرة أو خدمة')) return;

    // عرض خيارات الإضافة
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ماذا تريد إضافته؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAddOption(
              icon: Icons.psychology,
              title: 'إضافة خبرة',
              subtitle: 'شارك خبرتك مع الآخرين',
              color: Colors.purple,
              onTap: () {
                Get.back();
                Get.toNamed('/add-experience');
              },
            ),
            const SizedBox(height: 12),
            _buildAddOption(
              icon: Icons.build,
              title: 'إضافة خدمة',
              subtitle: 'اعرض خدماتك للبيع أو التبادل',
              color: Colors.teal,
              onTap: () {
                Get.back();
                Get.toNamed('/add-service');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showExperienceDetails(Experience experience) {
    Get.bottomSheet(
      _buildExperienceDetailsSheet(experience),
      isScrollControlled: true,
    );
  }

  Widget _buildExperienceDetailsSheet(Experience experience) {
    return Container(
      height: MediaQuery.of(Get.context!).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // صورة الخبير
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryExtraLight,
                    backgroundImage: experience.imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(experience.imageUrl)
                        : null,
                    child: experience.imageUrl.isEmpty
                        ? Text(
                            experience.expertName.isNotEmpty
                                ? experience.expertName[0].toUpperCase()
                                : 'خ',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // الاسم
                  Text(
                    experience.expertName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    experience.title,
                    style: TextStyle(color: AppColors.primary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // الإحصائيات
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.work_history,
                          experience.experienceText, 'الخبرة'),
                      _buildStatItem(Icons.star,
                          experience.rating.toStringAsFixed(1), 'التقييم'),
                      _buildStatItem(Icons.reviews,
                          '${experience.reviewsCount}', 'التقييمات'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // الوصف
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      experience.description,
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // أزرار التفاعل
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startConsultation(experience),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('طلب استشارة',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => _callExpert(experience),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green, width: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.phone),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  void _showServiceDetails(Service service) {
    // يمكن فتح صفحة تفاصيل الخدمة
    Get.snackbar('قريباً', 'سيتم فتح تفاصيل الخدمة');
  }

  void _startConsultation(Experience experience) async {
    Get.back();

    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لطلب استشارة')) return;

    try {
      final chatId = await ChatService().createOrGetChat(
        experience.id, // استخدام ID الخبرة كـ productId
        experience.id,
      );
      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: experience.id,
            otherUserName: experience.expertName,
          ));
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في بدء المحادثة');
    }
  }

  void _callExpert(Experience experience) {
    Get.snackbar(
      'قريباً',
      'ستتوفر خاصية الاتصال قريباً',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Delegate للـ TabBar الثابت
// ═══════════════════════════════════════════════════════════════════════════
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
