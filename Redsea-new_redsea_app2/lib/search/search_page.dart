import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/search/product_listing_page.dart';

/// صفحة البحث الجديدة
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // الكلمات الأكثر رواجاً
  final List<String> _trendingKeywords = [
    'آيفون 15',
    'سيارة تويوتا',
    'شقة للإيجار',
    'لاب توب',
    'أثاث مستعمل',
    'دراجة نارية',
    'كاميرا',
    'ساعة ذكية',
    'هاتف سامسونج',
    'أرض للبيع',
  ];

  // الأقسام الرئيسية
  final List<CategorySection> _categories = [
    CategorySection(
        name: 'خبرات واستشارات', icon: Icons.psychology, color: Colors.purple),
    CategorySection(
        name: 'خدمات', icon: Icons.miscellaneous_services, color: Colors.teal),
    CategorySection(
        name: 'سيارات ومركبات',
        icon: Icons.directions_car,
        color: Colors.orange),
    CategorySection(name: 'عقارات', icon: Icons.home_work, color: Colors.brown),
    CategorySection(
        name: 'هواتف وإلكترونيات',
        icon: Icons.phone_android,
        color: AppColors.primary),
    CategorySection(
        name: 'أثاث ومفروشات', icon: Icons.chair, color: Colors.amber.shade700),
    CategorySection(
        name: 'أزياء وملابس', icon: Icons.checkroom, color: Colors.pink),
    CategorySection(
        name: 'رياضة ولياقة', icon: Icons.sports_soccer, color: Colors.green),
    CategorySection(
        name: 'كتب وتعليم', icon: Icons.menu_book, color: Colors.indigo),
    CategorySection(
        name: 'أدوات ومعدات',
        icon: Icons.handyman,
        color: Colors.grey.shade700),
    CategorySection(
        name: 'حيوانات', icon: Icons.pets, color: Colors.deepOrange),
    CategorySection(
        name: 'أخرى', icon: Icons.more_horiz, color: Colors.blueGrey),
  ];

  @override
  void initState() {
    super.initState();
    // فتح الكيبورد تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // الأكثر رواجاً
                      _buildTrendingSection(),
                      const SizedBox(height: 24),
                      // الأقسام الرئيسية
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),
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

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // صف البحث
          Row(
            children: [
              // زر الرجوع
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 12),
              // حقل البحث
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن أي شيء...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (value) => _performSearch(value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // زر الفلترة
              IconButton(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.tune, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'الأكثر رواجاً',
              style: AppTextStyles.headline3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingKeywords.map((keyword) {
            return ActionChip(
              label: Text(keyword),
              labelStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
              ),
              backgroundColor:
                  AppColors.primaryExtraLight.withValues(alpha: 0.5),
              side: BorderSide(
                  color: AppColors.primaryLight.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _performSearch(keyword),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'الأقسام الرئيسية',
              style: AppTextStyles.headline3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _buildCategoryTile(category);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTile(CategorySection category) {
    return ListTile(
      onTap: () => _navigateToCategory(category.name),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(category.icon, color: category.color, size: 24),
      ),
      title: Text(
        category.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_back_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // تحديث الفلتر بالبحث
    final filterController = Get.find<FilterController>();
    filterController.setSearchQuery(query);

    // التوجيه لصفحة النتائج
    Get.to(() => ProductListingPage(
          title: 'نتائج البحث: $query',
          searchQuery: query,
        ));
  }

  void _navigateToCategory(String categoryName) {
    Get.to(() => ProductListingPage(
          title: categoryName,
          category: categoryName,
        ));
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}

/// نموذج القسم
class CategorySection {
  final String name;
  final IconData icon;
  final Color color;

  CategorySection({
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Bottom Sheet للفلترة
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCity;
  RangeValues _priceRange = const RangeValues(0, 1000000);
  String _selectedCurrency = 'ر.ي';
  String _selectedAdType = 'الكل';

  final List<String> _cities = [
    'صنعاء',
    'عدن',
    'تعز',
    'الحديدة',
    'إب',
    'المكلا',
    'ذمار',
    'حجة',
    'عمران',
    'صعدة',
  ];

  final List<String> _currencies = ['ر.ي', 'ر.س', '\$'];
  final List<String> _adTypes = ['الكل', 'بيع', 'مقايضة'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // المقبض
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // العنوان
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فلترة النتائج',
                    style: AppTextStyles.headline2,
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('إعادة تعيين'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المدينة
                    _buildSectionTitle('المدينة', Icons.location_city),
                    const SizedBox(height: 12),
                    _buildCityDropdown(),
                    const SizedBox(height: 24),

                    // نطاق السعر
                    _buildSectionTitle('نطاق السعر', Icons.attach_money),
                    const SizedBox(height: 12),
                    _buildPriceRangeSlider(),
                    const SizedBox(height: 24),

                    // العملة
                    _buildSectionTitle('العملة', Icons.currency_exchange),
                    const SizedBox(height: 12),
                    _buildCurrencySelector(),
                    const SizedBox(height: 24),

                    // نوع الإعلان
                    _buildSectionTitle('نوع الإعلان', Icons.sell),
                    const SizedBox(height: 12),
                    _buildAdTypeSelector(),
                  ],
                ),
              ),
            ),
            // زر التطبيق
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'تطبيق الفلترة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          hint: const Text('اختر المدينة'),
          isExpanded: true,
          items: _cities.map((city) {
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
          onChanged: (value) => setState(() => _selectedCity = value),
        ),
      ),
    );
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 1000000,
          divisions: 100,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primaryExtraLight,
          labels: RangeLabels(
            '${_priceRange.start.round()} $_selectedCurrency',
            '${_priceRange.end.round()} $_selectedCurrency',
          ),
          onChanged: (values) => setState(() => _priceRange = values),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'من: ${_priceRange.start.round()} $_selectedCurrency',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              'إلى: ${_priceRange.end.round()} $_selectedCurrency',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Wrap(
      spacing: 12,
      children: _currencies.map((currency) {
        final isSelected = _selectedCurrency == currency;
        return ChoiceChip(
          label: Text(currency),
          selected: isSelected,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (selected) {
            if (selected) setState(() => _selectedCurrency = currency);
          },
        );
      }).toList(),
    );
  }

  Widget _buildAdTypeSelector() {
    return Wrap(
      spacing: 12,
      children: _adTypes.map((type) {
        final isSelected = _selectedAdType == type;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == 'مقايضة') ...[
                const Icon(Icons.swap_horiz, size: 16),
                const SizedBox(width: 4),
              ],
              if (type == 'بيع') ...[
                const Icon(Icons.sell, size: 16),
                const SizedBox(width: 4),
              ],
              Text(type),
            ],
          ),
          selected: isSelected,
          selectedColor: type == 'مقايضة'
              ? Colors.green
              : (type == 'بيع' ? AppColors.primary : Colors.grey),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (selected) {
            if (selected) setState(() => _selectedAdType = type);
          },
        );
      }).toList(),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _priceRange = const RangeValues(0, 1000000);
      _selectedCurrency = 'ر.ي';
      _selectedAdType = 'الكل';
    });
  }

  void _applyFilters() {
    // تطبيق الفلاتر
    final filterController = Get.find<FilterController>();

    if (_selectedCity != null) {
      filterController.setCity(_selectedCity!);
    }
    filterController.setPriceRange(_priceRange.start, _priceRange.end);
    filterController.setCurrency(_selectedCurrency);

    if (_selectedAdType == 'مقايضة') {
      filterController.setBarterMode();
    } else if (_selectedAdType == 'بيع') {
      // وضع البيع العادي (إلغاء وضع المقايضة)
      filterController.isBarterOnly.value = false;
    }

    Get.back();

    // التوجيه لصفحة النتائج
    Get.to(() => const ProductListingPage(
          title: 'نتائج الفلترة',
        ));
  }
}
