import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PromoteProductPage extends StatefulWidget {
  final Product product;
  const PromoteProductPage({super.key, required this.product});

  @override
  State<PromoteProductPage> createState() => _PromoteProductPageState();
}

class _PromoteProductPageState extends State<PromoteProductPage> {
  double _viewersCount = 1000;
  String _selectedAdType = 'post';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  int _durationDays = 7;

  // Ad Types
  final List<Map<String, dynamic>> _adTypes = [
    {
      'id': 'post',
      'name': 'منشور في الصفحة الرئيسية',
      'icon': Icons.post_add,
      'description': 'يظهر كمنشور عادي مع نص وصورة'
    },
    {
      'id': 'banner',
      'name': 'بنر إعلاني علوي',
      'icon': Icons.view_carousel,
      'description': 'يظهر في شريط البنرات العلوي'
    },
    {
      'id': 'video',
      'name': 'إعلان فيديو قصير',
      'icon': Icons.play_circle_outline,
      'description': 'يظهر كفيديو قصير مع زر شراء'
    },
    {
      'id': 'bottom_notes',
      'name': 'ملاحظة أسفل الشاشة',
      'icon': Icons.sticky_note_2_outlined,
      'description': 'تظهر كملاحظة منبثقة بسيطة'
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.product.name;
    _descriptionController.text = widget.product.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('ترويج المنتج',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Product Preview Header
              _buildProductPreview(),
              const SizedBox(height: 24),

              // 2. Viewers Count Selection
              _buildSectionTitle('عدد المشاهدات المستهدف يومياً'),
              _buildViewersSlider(),
              const SizedBox(height: 24),

              // 3. Ad Type Selection
              _buildSectionTitle('نوع الإعلان'),
              _buildAdTypeGrid(),
              const SizedBox(height: 24),

              // 4. Dynamic Input Fields
              _buildSectionTitle('محتوى الإعلان'),
              _buildDynamicInputs(),
              const SizedBox(height: 24),

              // 5. Duration Selection
              _buildSectionTitle('مدة الترويج'),
              _buildDurationSelection(),
              const SizedBox(height: 32),

              // 6. Action Button
              AppWidgets.primaryButton(
                text: 'الذهاب للدفع وحساب التكلفة',
                onPressed: _goToCheckout,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProductPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey.shade200),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'السعر الأصلي: ${widget.product.price} ر.ي',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewersSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_viewersCount.toInt()} مشاهدة/يوم',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Icon(Icons.trending_up, color: AppColors.primary),
            ],
          ),
          Slider(
            value: _viewersCount,
            min: 1,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _viewersCount = value);
            },
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('5,000', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('10,000',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _adTypes.length,
      itemBuilder: (context, index) {
        final type = _adTypes[index];
        final isSelected = _selectedAdType == type['id'];
        return GestureDetector(
          onTap: () => setState(() => _selectedAdType = type['id']),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type['icon'],
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  type['name'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الإعلان',
              hintText: 'مثلاً: عرض خاص على هذا المنتج',
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedAdType == 'post' || _selectedAdType == 'bottom_notes')
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإعلان',
                hintText: 'اكتب وصفاً جذاباً لمنتجك...',
              ),
            ),
          if (_selectedAdType == 'video')
            TextField(
              decoration: const InputDecoration(
                labelText: 'رابط الفيديو (YouTube/Drive)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetAudienceController,
            decoration: const InputDecoration(
              labelText: 'الجمهور المستهدف',
              hintText: 'مثلاً: عشاق التقنية، أصحاب السيارات...',
            ),
          ),
          if (_selectedAdType == 'banner' || _selectedAdType == 'video')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAdType == 'banner'
                          ? 'سيتم استخدام صورة البنر الرئيسية من صور المنتج الخاصة بك.'
                          : 'سيتم عرض الفيديو وماتبعه من زر الشراء المباشر للمنتج.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationSelection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [7, 15, 30].map((days) {
          final isSelected = _durationDays == days;
          return ChoiceChip(
            label: Text('$days يوم'),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary),
            onSelected: (selected) {
              if (selected) setState(() => _durationDays = days);
            },
          );
        }).toList(),
      ),
    );
  }

  void _goToCheckout() {
    if (_titleController.text.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال عنوان للإعلان',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    Get.toNamed(AppRoutes.promotionCheckout, arguments: {
      'product': widget.product,
      'viewersCount': _viewersCount,
      'adType': _selectedAdType,
      'durationDays': _durationDays,
      'title': _titleController.text,
      'description': _descriptionController.text,
      'targetAudience': _targetAudienceController.text,
    });
  }
}
