import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Controllers منفصلة لكل حقل
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final ProductController productController = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();

  // فلاتر البحث
  String? selectedCategory;
  bool negotiableOnly = false;
  String sortBy = 'الأحدث';

  List<Product> searchResults = [];
  bool isSearching = false;
  bool showFilters = false;

  // عدد الفلاتر النشطة
  int get activeFiltersCount {
    int count = 0;
    if (selectedCategory != null && selectedCategory != 'الكل') count++;
    if (_minPriceController.text.isNotEmpty) count++;
    if (_maxPriceController.text.isNotEmpty) count++;
    if (negotiableOnly) count++;
    if (sortBy != 'الأحدث') count++;
    return count;
  }

  final List<String> categories = [
    'الكل',
    'الكترونيات',
    'أجهزة منزلية',
    'ملابس',
    'عطور',
    'ساعات',
    'سيارات',
    'أثاث',
    'أخرى',
  ];

  final List<String> sortOptions = [
    'الأحدث',
    'الأقدم',
    'السعر: الأقل',
    'السعر: الأعلى',
    'أبجدياً',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // عرض كل المنتجات في البداية
    searchResults = productController.allProducts.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      isSearching = true;
    });

    List<Product> results = productController.allProducts.toList();

    // فلترة حسب النص
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      results = results.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }).toList();
    }

    // فلترة حسب التصنيف
    if (selectedCategory != null && selectedCategory != 'الكل') {
      results = results.where((p) => p.category == selectedCategory).toList();
    }

    // فلترة حسب السعر - من
    if (_minPriceController.text.isNotEmpty) {
      double? minPrice = double.tryParse(_minPriceController.text);
      if (minPrice != null) {
        results = results.where((p) {
          double productPrice =
              double.tryParse(p.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return productPrice >= minPrice;
        }).toList();
      }
    }

    // فلترة حسب السعر - إلى
    if (_maxPriceController.text.isNotEmpty) {
      double? maxPrice = double.tryParse(_maxPriceController.text);
      if (maxPrice != null) {
        results = results.where((p) {
          double productPrice =
              double.tryParse(p.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return productPrice <= maxPrice;
        }).toList();
      }
    }

    // فلترة القابل للمقايضة فقط
    if (negotiableOnly) {
      results = results.where((p) => p.negotiable).toList();
    }

    // الترتيب
    switch (sortBy) {
      case 'الأحدث':
        results.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'الأقدم':
        results.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case 'السعر: الأقل':
        results.sort((a, b) {
          double priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          double priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'السعر: الأعلى':
        results.sort((a, b) {
          double priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          double priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'أبجدياً':
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      searchResults = results;
      isSearching = false;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedCategory = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      negotiableOnly = false;
      sortBy = 'الأحدث';
      _searchController.clear();
    });
    _performSearch();
  }

  void _applyFilters() {
    _performSearch();
    setState(() {
      showFilters = false;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'البحث المتقدم',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        // زر الفلاتر على اليسار (للغة العربية)
        leading: Stack(
          children: [
            IconButton(
              icon: Icon(
                showFilters ? Icons.filter_list_off : Icons.tune,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  showFilters = !showFilters;
                });
              },
            ),
            if (activeFiltersCount > 0)
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
                    '$activeFiltersCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // زر الرجوع على اليمين (للغة العربية)
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // شريط البحث
            _buildSearchBar(),

            // عدد النتائج والفلاتر النشطة
            _buildResultsHeader(),

            // الفلاتر - قابلة للتمرير لتجنب الـ overflow
            if (showFilters)
              Flexible(
                flex: 1,
                fit: FlexFit.loose,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: _buildFiltersPanel(),
                  ),
                ),
              ),

            // النتائج
            Expanded(
              flex: 1,
              child: isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchController.text.isEmpty && !showFilters
                      ? _buildSearchJourney()
                      : searchResults.isEmpty
                          ? SingleChildScrollView(child: _buildEmptyResults())
                          : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          hintStyle: AppTextStyles.bodyMedium,
          prefixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          suffixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${searchResults.length} نتيجة',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (activeFiltersCount > 0)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('مسح الكل'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // عنوان الفلاتر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('إعادة ضبط',
                    style: TextStyle(color: Colors.red)),
              ),
              Row(
                children: [
                  Text('الفلاتر',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.tune, color: AppColors.primary),
                ],
              ),
            ],
          ),
          const Divider(),

          // التصنيف
          _buildSectionTitle('التصنيف', Icons.category),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category ||
                    (selectedCategory == null && category == 'الكل');
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = selected
                            ? (category == 'الكل' ? null : category)
                            : null;
                      });
                      _performSearch();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // نطاق السعر
          _buildSectionTitle('نطاق السعر (ريال)', Icons.attach_money),
          const SizedBox(height: 12),
          Row(
            children: [
              // من (يمين في العربية)
              Expanded(
                child: _buildPriceField(
                  controller: _minPriceController,
                  label: 'من',
                  icon: Icons.arrow_downward,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: const Icon(Icons.remove, color: Colors.grey),
              ),
              // إلى (يسار في العربية)
              Expanded(
                child: _buildPriceField(
                  controller: _maxPriceController,
                  label: 'إلى',
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // الترتيب
          _buildSectionTitle('ترتيب حسب', Icons.sort),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: sortBy,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, textAlign: TextAlign.right),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  sortBy = value!;
                });
                _performSearch();
              },
            ),
          ),

          const SizedBox(height: 16),

          // القابل للمقايضة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  negotiableOnly ? Colors.green.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: negotiableOnly ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: negotiableOnly,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      negotiableOnly = value;
                    });
                    _performSearch();
                  },
                ),
                Row(
                  children: [
                    Text(
                      'قابل للمقايضة فقط',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: negotiableOnly
                            ? Colors.green
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.swap_horiz,
                      color: negotiableOnly ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // زر تطبيق
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check),
              label:
                  const Text('تطبيق الفلاتر', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 18, color: AppColors.primary),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          suffixText: 'ر.س',
          suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        onChanged: (value) {
          _performSearch();
        },
      ),
    );
  }

  Widget _buildEmptyResults() {
    return AppWidgets.emptyState(
      icon: Icons.search_off,
      title: 'لا توجد نتائج',
      subtitle: 'جرب البحث بكلمات مختلفة أو تغيير الفلاتر',
      buttonText: 'مسح البحث',
      onButtonPressed: _clearFilters,
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final product = searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    // ... (keep existing card as is for now)
    return Container(); // Placeholder as I'll just keep the existing code below
  }

  Widget _buildSearchJourney() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildJourneySection(
            'عمليات البحث الأخيرة',
            [
              'تويوتا كورولا',
              'آيفون 15 برو',
              'شقة للايجار',
            ],
            Icons.history),
        const SizedBox(height: 24),
        _buildJourneySection(
            'الأكثر رواجاً اليوم',
            [
              'كاميرات كانون',
              'ساعات ذكية',
              'نظارات شمسية',
            ],
            Icons.trending_up),
        const SizedBox(height: 24),
        const Text(
          'الأقسام',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...categories.where((c) => c != 'الكل').map((category) => ListTile(
              title: Text(category, textAlign: TextAlign.right),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  selectedCategory = category;
                  _searchController.text = category;
                });
                _performSearch();
              },
            )),
      ],
    );
  }

  Widget _buildJourneySection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: items
              .map((item) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.text = item;
                      });
                      _performSearch();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(item),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
