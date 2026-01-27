import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';

/// صفحة تعديل الخدمة
class EditServicePage extends StatefulWidget {
  final Service service;

  const EditServicePage({super.key, required this.service});

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TextEditingController _durationController;

  late String _selectedCategory;
  late List<String> _selectedPreferences;
  bool _isLoading = false;

  // متغيرات العرض الخاص
  late bool _isSpecialOffer;
  late TextEditingController _oldValueController;

  @override
  void initState() {
    super.initState();
    _initializeFromService();
  }

  void _initializeFromService() {
    final service = widget.service;
    _titleController = TextEditingController(text: service.title);
    _descriptionController = TextEditingController(text: service.description);
    _valueController =
        TextEditingController(text: service.estimatedValue.toStringAsFixed(0));
    _durationController = TextEditingController(text: service.duration);
    _selectedCategory = service.category;
    _selectedPreferences = List<String>.from(service.swapPreferences);
    _isSpecialOffer = service.isSpecialOffer;
    _oldValueController = TextEditingController(
      text: service.oldEstimatedValue?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    _oldValueController.dispose();
    super.dispose();
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = Get.find<ServiceController>();
    final success = await controller.updateService(
      serviceId: widget.service.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      estimatedValue: double.tryParse(_valueController.text) ?? 0,
      duration: _durationController.text.trim(),
      swapPreferences: _selectedPreferences,
      isSpecialOffer: _isSpecialOffer,
      oldEstimatedValue:
          _isSpecialOffer ? double.tryParse(_oldValueController.text) : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الخدمة'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ═══════════════════════════════════════════════════════════
              // عنوان الخدمة
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('عنوان الخدمة', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('عنوان الخدمة'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال عنوان الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // التصنيف
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('التصنيف', Icons.category),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                    items: ServiceCategory.categories
                        .where((c) => c != 'الكل')
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(category),
                                  const SizedBox(width: 8),
                                  Icon(
                                    ServiceCategory.getIcon(category),
                                    color: ServiceCategory.getColor(category),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // وصف الخدمة
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('وصف الخدمة', Icons.description),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                textAlign: TextAlign.right,
                maxLines: 5,
                decoration: _inputDecoration('وصف تفصيلي لخدمتك...'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال وصف الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // القيمة التقديرية
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('القيمة التقديرية (ريال)', Icons.attach_money),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valueController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('مثال: 500'),
                validator: (value) => value?.isEmpty == true
                    ? 'يرجى إدخال القيمة التقديرية'
                    : null,
              ),

              const SizedBox(height: 16),

              // ═══════════════════════════════════════════════════════════
              // عرض خاص (خيار إضافي)
              // ═══════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSpecialOffer
                      ? Colors.red.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSpecialOffer
                        ? Colors.red.shade300
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Switch(
                          value: _isSpecialOffer,
                          onChanged: (value) {
                            setState(() {
                              _isSpecialOffer = value;
                              if (!value) {
                                _oldValueController.clear();
                              }
                            });
                          },
                          activeThumbColor: Colors.red,
                        ),
                        const Row(
                          children: [
                            Text(
                              'عرض خاص 🔥',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.local_offer,
                                color: Colors.red, size: 20),
                          ],
                        ),
                      ],
                    ),
                    if (_isSpecialOffer) ...[
                      const SizedBox(height: 12),
                      Text(
                        'أدخل السعر الأصلي (قبل الخصم)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _oldValueController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('مثال: 800').copyWith(
                          prefixText: 'ريال ',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (_isSpecialOffer && (value?.isEmpty == true)) {
                            return 'يرجى إدخال السعر الأصلي';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_valueController.text.isNotEmpty &&
                          _oldValueController.text.isNotEmpty)
                        Builder(builder: (context) {
                          final newValue =
                              double.tryParse(_valueController.text) ?? 0;
                          final oldValue =
                              double.tryParse(_oldValueController.text) ?? 0;
                          if (oldValue > 0 && newValue < oldValue) {
                            final discount =
                                ((oldValue - newValue) / oldValue * 100)
                                    .toStringAsFixed(0);
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'نسبة الخصم: $discount%',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.discount,
                                      color: Colors.green.shade700, size: 18),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // مدة التنفيذ
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('مدة التنفيذ', Icons.timer),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('مثال: 2-3 أيام'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال مدة التنفيذ' : null,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // الخدمات المفضلة للتبادل
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle(
                  'أفضّل التبادل مع (اختياري)', Icons.swap_horiz),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: ServiceCategory.categories
                    .where((c) => c != 'الكل' && c != _selectedCategory)
                    .map((category) => FilterChip(
                          label: Text(category,
                              style: const TextStyle(fontSize: 12)),
                          selected: _selectedPreferences.contains(category),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(category);
                              } else {
                                _selectedPreferences.remove(category);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 40),

              // ═══════════════════════════════════════════════════════════
              // زر الحفظ
              // ═══════════════════════════════════════════════════════════
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'جاري الحفظ...' : 'حفظ التعديلات',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: AppColors.primary),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
