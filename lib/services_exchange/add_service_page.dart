import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';

/// صفحة إضافة خدمة جديدة - تصميم محسّن
class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedCategory = 'تصميم';
  final List<String> _selectedPreferences = [];
  final List<String> _portfolioUrls = [];
  final List<ServicePackage> _packages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = Get.find<ServiceController>();
    final success = await controller.addService(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      estimatedValue: double.tryParse(_valueController.text) ?? 0,
      duration: _durationController.text.trim(),
      swapPreferences: _selectedPreferences,
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة خدمة جديدة'),
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
              // عنوان الخدمة
              _buildSectionTitle('عنوان الخدمة', Icons.title),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('مثال: تصميم شعارات احترافية'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال عنوان الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // وصف الخدمة
              _buildSectionTitle('وصف الخدمة', Icons.description),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                textAlign: TextAlign.right,
                maxLines: 4,
                decoration: _inputDecoration('اكتب وصفاً تفصيلياً لخدمتك...'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال وصف الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // التصنيف
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
                    onChanged: (value) {
                      setState(() => _selectedCategory = value!);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // القيمة التقديرية
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

              const SizedBox(height: 20),

              // مدة التنفيذ
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

              // معرض الأعمال
              _buildPortfolioSection(),

              const SizedBox(height: 20),

              // الباقات
              _buildPackagesSection(),

              const SizedBox(height: 20),

              // الخدمات المفضلة للتبادل
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

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إضافة الخدمة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _addPortfolioUrl,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('إضافة'),
            ),
            const Row(
              children: [
                Text(
                  'معرض الأعمال (اختياري)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.collections, size: 20, color: AppColors.primary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_portfolioUrls.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'أضف روابط لصور أعمالك السابقة',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Icon(Icons.image, color: Colors.grey.shade400),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _portfolioUrls.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  'صورة ${entry.key + 1}',
                  style: const TextStyle(fontSize: 11),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _portfolioUrls.removeAt(entry.key));
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addPortfolioUrl() {
    final urlController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('إضافة صورة للمعرض', textAlign: TextAlign.center),
        content: TextField(
          controller: urlController,
          decoration: _inputDecoration('رابط الصورة (URL)'),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                setState(() {
                  _portfolioUrls.add(urlController.text.trim());
                });
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _addPackage,
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('إضافة'),
            ),
            const Row(
              children: [
                Text(
                  'الباقات (اختياري)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.inventory_2, size: 20, color: AppColors.primary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_packages.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'أنشئ باقات مختلفة لخدمتك',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Icon(Icons.layers, color: Colors.grey.shade400),
              ],
            ),
          )
        else
          Column(
            children: _packages.asMap().entries.map((entry) {
              final package = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: () {
                        setState(() => _packages.removeAt(entry.key));
                      },
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${package.price.toStringAsFixed(0)} ر.س - ${package.duration}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2,
                          color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _addPackage() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final daysController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('إضافة باقة جديدة', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: _inputDecoration('اسم الباقة (مثال: أساسي)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: _inputDecoration('وصف الباقة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('السعر (ريال)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('مدة التسليم (أيام)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  priceController.text.trim().isNotEmpty) {
                setState(() {
                  _packages.add(ServicePackage(
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    price: double.tryParse(priceController.text) ?? 0,
                    duration: '${daysController.text.trim()} يوم',
                  ));
                });
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة'),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: AppColors.primary),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
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
