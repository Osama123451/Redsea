import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redsea/search_page.dart';
import 'package:redsea/advanced_filter_page.dart';
import 'package:redsea/app/controllers/product_controller.dart';

/// صفحة البحث المتقدمة
/// تعرض آخر البحوث، الأكثر رواجاً، والأقسام الرئيسية
class SearchViewPage extends StatefulWidget {
  const SearchViewPage({super.key});

  @override
  State<SearchViewPage> createState() => _SearchViewPageState();
}

class _SearchViewPageState extends State<SearchViewPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> recentSearches = [];

  // الكلمات الأكثر رواجاً
  final List<String> trendingSearches = [
    'آيفون 15',
    'لابتوب',
    'سيارة',
    'شقة للإيجار',
    'بلايستيشن',
    'ساعة ذكية',
    'أثاث مستعمل',
    'موبايل سامسونج',
  ];

  // الأقسام الرئيسية
  final List<Map<String, dynamic>> mainCategories = [
    {'name': 'خبرات', 'icon': Icons.psychology, 'color': Colors.purple},
    {'name': 'سيارات', 'icon': Icons.directions_car, 'color': Colors.red},
    {'name': 'موبايلات', 'icon': Icons.phone_android, 'color': Colors.blue},
    {'name': 'عقارات', 'icon': Icons.home, 'color': Colors.green},
    {'name': 'إلكترونيات', 'icon': Icons.computer, 'color': Colors.indigo},
    {'name': 'أثاث', 'icon': Icons.chair, 'color': Colors.brown},
    {'name': 'ملابس', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'خدمات', 'icon': Icons.build, 'color': Colors.orange},
    {'name': 'وظائف', 'icon': Icons.work, 'color': Colors.teal},
    {'name': 'ساعات', 'icon': Icons.watch, 'color': Colors.amber},
    {'name': 'عطور', 'icon': Icons.spa, 'color': Colors.deepPurple},
    {'name': 'أجهزة منزلية', 'icon': Icons.kitchen, 'color': Colors.cyan},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // فتح لوحة المفاتيح تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(query);
    recentSearches.insert(0, query);
    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', recentSearches);
  }

  Future<void> _clearAllSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() {
      recentSearches = [];
    });
  }

  Future<void> _removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(query);
    await prefs.setStringList('recent_searches', recentSearches);
    setState(() {});
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveSearch(query);
    // الانتقال لصفحة البحث مع النص
    final productController = Get.find<ProductController>();
    productController.updateSearchQuery(query);
    Get.off(() => const SearchPage());
  }

  void _selectCategory(String category) {
    FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح
    final productController = Get.find<ProductController>();
    productController.changeFilter(category);
    Get.back();
  }

  /// الرجوع مع إخفاء لوحة المفاتيح
  void _goBack() {
    FocusScope.of(context).unfocus(); // إخفاء لوحة المفاتيح
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context)
          .unfocus(), // إخفاء لوحة المفاتيح عند الضغط خارج الحقل
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Column(
            children: [
              // شريط البحث العلوي
              _buildSearchHeader(),
              // المحتوى
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // آخر البحوث
                      if (recentSearches.isNotEmpty) ...[
                        _buildRecentSearches(),
                        const SizedBox(height: 24),
                      ],
                      // الأكثر رواجاً
                      _buildTrendingSearches(),
                      const SizedBox(height: 24),
                      // الأقسام
                      _buildCategoriesSection(),
                      const SizedBox(height: 32),
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

  /// شريط البحث العلوي
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الفلترة
          GestureDetector(
            onTap: () => Get.to(() => const AdvancedFilterPage()),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          // حقل البحث
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج أو خدمة...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر الرجوع
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// قسم آخر البحوث
  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // العنوان مع زر حذف الكل
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _clearAllSearches,
              child: Text(
                'حذف الكل',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 13,
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.history, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'آخر البحوث',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // قائمة البحوث
        ...recentSearches
            .take(5)
            .map((search) => _buildRecentSearchItem(search)),
      ],
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return InkWell(
      onTap: () => _performSearch(search),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // زر الحذف
            GestureDetector(
              onTap: () => _removeSearch(search),
              child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            ),
            const Spacer(),
            // النص
            Text(
              search,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            // أيقونة
            Icon(Icons.access_time, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  /// قسم الأكثر رواجاً
  Widget _buildTrendingSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.trending_up, color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'الأكثر رواجاً',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: trendingSearches.map((search) {
            return GestureDetector(
              onTap: () => _performSearch(search),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      search,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.orange.shade400,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// قسم الأقسام
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.category, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            const Text(
              'الأقسام',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // قائمة الأقسام طولية
        ...mainCategories.map((category) => _buildCategoryItem(category)),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return InkWell(
      onTap: () => _selectCategory(category['name']),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
            const Spacer(),
            Text(
              category['name'],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category['icon'],
                color: category['color'],
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
