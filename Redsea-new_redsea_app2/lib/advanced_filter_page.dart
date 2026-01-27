import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/filter_controller.dart';
import 'package:redsea/search_results_page.dart';

/// صفحة الفلترة المتقدمة
/// تحتوي على جميع خيارات الفلترة
class AdvancedFilterPage extends StatefulWidget {
  const AdvancedFilterPage({super.key});

  @override
  State<AdvancedFilterPage> createState() => _AdvancedFilterPageState();
}

class _AdvancedFilterPageState extends State<AdvancedFilterPage> {
  late FilterController filterController;

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // التأكد من تسجيل الـ Controller
    if (!Get.isRegistered<FilterController>()) {
      Get.put(FilterController());
    }
    filterController = Get.find<FilterController>();

    // تحميل القيم الحالية
    if (filterController.minPrice.value > 0) {
      _minPriceController.text =
          filterController.minPrice.value.toStringAsFixed(0);
    }
    if (filterController.maxPrice.value > 0) {
      _maxPriceController.text =
          filterController.maxPrice.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() async {
    // تحديث السعر
    filterController.minPrice.value =
        double.tryParse(_minPriceController.text) ?? 0;
    filterController.maxPrice.value =
        double.tryParse(_maxPriceController.text) ?? 0;

    // تطبيق الفلترة
    await filterController.applyFilters();

    // الانتقال لصفحة النتائج
    Get.off(() => const SearchResultsPage());
  }

  void _clearFilters() {
    filterController.clearAllFilters();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'الفلترة المتقدمة',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'مسح الكل',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 1. الأقسام
            _buildCategoriesSection(),
            const SizedBox(height: 24),

            // 2. الموقع
            _buildLocationSection(),
            const SizedBox(height: 24),

            // 3. السعر
            _buildPriceSection(),
            const SizedBox(height: 24),

            // 4. خيارات إضافية
            _buildAdditionalOptions(),
            const SizedBox(height: 24),

            // 5. التقييم
            _buildRatingSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // زر تطبيق الفلترة
      bottomNavigationBar: _buildApplyButton(),
    );
  }

  /// قسم الأقسام
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('الأقسام', Icons.category),
        const SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: filterController.categories.map((cat) {
                final isSelected =
                    filterController.selectedCategory.value == cat['name'] ||
                        (filterController.selectedCategory.value.isEmpty &&
                            cat['name'] == 'الكل');
                return GestureDetector(
                  onTap: () {
                    filterController.setCategory(cat['name']);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade600 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          cat['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : cat['color'],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  /// قسم الموقع
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('الموقع', Icons.location_on),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(() => DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterController.selectedCity.value.isEmpty
                      ? 'الكل'
                      : filterController.selectedCity.value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  hint: const Text('اختر المدينة'),
                  items: filterController.cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city, textAlign: TextAlign.right),
                    );
                  }).toList(),
                  onChanged: (value) {
                    filterController.setCity(value ?? 'الكل');
                  },
                ),
              )),
        ),
      ],
    );
  }

  /// قسم السعر
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('نطاق السعر', Icons.attach_money),
        const SizedBox(height: 12),
        Row(
          children: [
            // العملة
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterController.currency.value,
                      items: ['ريال', 'دولار'].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (value) {
                        filterController.setCurrency(value ?? 'ريال');
                      },
                    ),
                  ),
                )),
            const SizedBox(width: 12),
            // أعلى سعر
            Expanded(
              child: _buildPriceField(
                controller: _maxPriceController,
                hint: 'أعلى سعر',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('—', style: TextStyle(color: Colors.grey)),
            ),
            // أدنى سعر
            Expanded(
              child: _buildPriceField(
                controller: _minPriceController,
                hint: 'أدنى سعر',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  /// قسم الخيارات الإضافية
  Widget _buildAdditionalOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('خيارات إضافية', Icons.tune),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSwitchOption(
                title: 'إعلانات مع صور',
                icon: Icons.image,
                value: filterController.hasImages,
              ),
              _buildDivider(),
              _buildSwitchOption(
                title: 'إعلانات مع فيديو',
                icon: Icons.videocam,
                value: filterController.hasVideo,
              ),
              _buildDivider(),
              _buildSwitchOption(
                title: 'إعلانات مميزة',
                icon: Icons.star,
                value: filterController.isFeatured,
              ),
              _buildDivider(),
              _buildSwitchOption(
                title: 'خدمة التوصيل',
                icon: Icons.local_shipping,
                value: filterController.hasDelivery,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required IconData icon,
    required RxBool value,
  }) {
    return Obx(() => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Switch(
            value: value.value,
            activeColor: Colors.blue.shade600,
            onChanged: (v) => value.value = v,
          ),
          title: Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(icon, color: Colors.grey.shade600),
        ));
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  /// قسم التقييم
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader('التقييم', Icons.star),
        const SizedBox(height: 12),
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildRatingChip('أي تقييم', 0),
                const SizedBox(width: 8),
                _buildRatingChip('3+ نجوم', 3),
                const SizedBox(width: 8),
                _buildRatingChip('4+ نجوم', 4),
              ],
            )),
      ],
    );
  }

  Widget _buildRatingChip(String label, int rating) {
    final isSelected = filterController.minRating.value == rating;
    return GestureDetector(
      onTap: () {
        filterController.setMinRating(rating);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (rating > 0) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 16,
                color: isSelected ? Colors.white : Colors.amber,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: Colors.blue.shade600, size: 20),
      ],
    );
  }

  /// زر تطبيق الفلترة
  Widget _buildApplyButton() {
    return Container(
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
        child: Obx(() => ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check),
                  const SizedBox(width: 8),
                  Text(
                    filterController.activeFiltersCount > 0
                        ? 'تطبيق الفلترة (${filterController.activeFiltersCount})'
                        : 'تطبيق الفلترة',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
