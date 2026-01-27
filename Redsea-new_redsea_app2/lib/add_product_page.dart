import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:redsea/services/imgbb_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/core/category_schemas.dart';
import 'package:redsea/product_details_page.dart';
import 'package:get/get.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isNegotiable = true;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _selectedCategory = 'الكترونيات';
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  final PageController _imagePageController = PageController();

  // حقول المقايضة الجديدة
  // SwapType _selectedSwapType = SwapType.productProduct; // Removed as per request to simplify UI
  ProductCondition _selectedCondition = ProductCondition.usedGood;
  final TextEditingController _locationController = TextEditingController();

  // Dynamic state for category specifications
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, dynamic> _dynamicValues = {};

  List<String> _categories = [];

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    // Initialize with schema categories
    _categories = categorySchemas.keys.toList();
    _categories.sort(); // Optional: Sort alphabetically
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
    _loadCategories();
  }

  /// تحميل التصنيفات من قاعدة البيانات
  Future<void> _loadCategories() async {
    try {
      final snapshot = await _database.child('categories').get();
      if (snapshot.exists) {
        // التعامل مع البيانات سواء كانت قائمة أو خريطة
        List<String> loadedCategories = [];

        if (snapshot.value is List) {
          final list = snapshot.value as List<dynamic>;
          // قد تحتوي القائمة على nulls
          loadedCategories =
              list.where((e) => e != null).map((e) => e.toString()).toList();
        } else if (snapshot.value is Map) {
          final map = snapshot.value as Map<dynamic, dynamic>;
          map.forEach((key, value) {
            if (value != null) {
              // التعامل مع حالة أن القيمة خريطة (Map) تحتوي على name
              if (value is Map) {
                final catName = value['name']?.toString() ?? '';
                if (catName.isNotEmpty) {
                  loadedCategories.add(catName);
                }
              } else {
                // القيمة نص مباشر
                loadedCategories.add(value.toString());
              }
            }
          });
        }

        if (loadedCategories.isNotEmpty) {
          setState(() {
            // دمج التصنيفات المحملة مع الحالية وإزالة التكرار
            final uniqueCategories = <String>{
              ..._categories,
              ...loadedCategories
            };
            _categories = uniqueCategories.toList();

            // التأكد من أن التصنيف المختار موجود
            if (!_categories.contains(_selectedCategory)) {
              if (_categories.isNotEmpty) {
                _selectedCategory = _categories.first;
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'إضافة منتج جديد',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري إضافة المنتج...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 20),

                    // 1. قسم الصور
                    _buildSectionContainer(
                      title: 'صور المنتج',
                      icon: Icons.camera_alt,
                      child: _buildImageField(),
                    ),

                    const SizedBox(height: 16),

                    // 2. قسم البيانات الأساسية (الاسم والسعر)
                    _buildSectionContainer(
                      title: 'البيانات الأساسية',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'اسم المنتج',
                            hint: 'أدخل اسم المنتج',
                            icon: Icons.shopping_bag,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المنتج';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _priceController,
                            label: 'السعر',
                            hint: 'أدخل السعر بالريال',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال سعر المنتج';
                              }
                              if (double.tryParse(value) == null) {
                                return 'يرجى إدخال سعر صحيح';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. قسم التصنيف والمواصفات
                    _buildSectionContainer(
                      title: 'التصنيف والمواصفات',
                      icon: Icons.list_alt,
                      child: Column(
                        children: [
                          _buildCategoryField(),
                          _buildCategorySpecificFields(),
                          Divider(height: 32, color: Colors.grey.shade200),
                          _buildBasicInfoSection(), // Location and Condition
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. خيارات البيع والمقايضة
                    _buildSectionContainer(
                      title: 'خيارات البيع',
                      icon: Icons.handshake_outlined,
                      child: Column(
                        children: [
                          _buildNegotiableField(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. الوصف
                    _buildSectionContainer(
                      title: 'وصف المنتج',
                      icon: Icons.description_outlined,
                      child: _buildDescriptionField(),
                    ),

                    const SizedBox(height: 32),

                    // زر إضافة المنتج
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildAddButton(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
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
              Icon(icon, color: AppColors.primary, size: 20),
            ],
          ),
          Divider(height: 32, color: Colors.grey.shade200),
          child,
        ],
      ),
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isUploadingImage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 6),
                  Text('جاري الرفع...',
                      style: TextStyle(fontSize: 11, color: Colors.blue)),
                ],
              ),
            ),
          ),
        // صندوق الصور
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImages.isEmpty
              ? GestureDetector(
                  onTap: _isUploadingImage ? null : _pickImage,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'أضف صور المنتج',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يمكنك اختيار عدة صور',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      itemCount: _selectedImages.length,
                      onPageChanged: (index) {
                        setState(() {});
                      },
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                              ),
                              // زر الحذف
                              Positioned(
                                top: 10,
                                left: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      if (_uploadedImageUrls.length > index) {
                                        _uploadedImageUrls.removeAt(index);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // مؤشر الصفحات
                    if (_selectedImages.length > 1)
                      Positioned(
                        bottom: 15,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _selectedImages.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_imagePageController.hasClients &&
                                        _imagePageController.page?.round() ==
                                            index)
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // زر إضافة المزيد
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'إضافة المزيد',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.right,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  bool _isCustomCategory = false;
  final TextEditingController _customCategoryController =
      TextEditingController();

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // العنوان مع زر صنف جديد
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // زر صنف جديد
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomCategory = !_isCustomCategory;
                    if (!_isCustomCategory) {
                      _selectedCategory = _categories.first;
                      _customCategoryController.clear();
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isCustomCategory
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _isCustomCategory ? Colors.orange : Colors.blue,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCustomCategory ? Icons.list : Icons.add_circle,
                        size: 14,
                        color: _isCustomCategory ? Colors.orange : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isCustomCategory ? 'اختر من القائمة' : 'صنف جديد',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              _isCustomCategory ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'التصنيف',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        // حقل التصنيف
        _isCustomCategory
            ? TextFormField(
                controller: _customCategoryController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'أدخل اسم الصنف الجديد',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon:
                      Icon(Icons.edit, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (_isCustomCategory &&
                      (value == null || value.trim().isEmpty)) {
                    return 'يرجى إدخال اسم الصنف';
                  }
                  return null;
                },
              )
            : DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _dynamicControllers.forEach((_, c) => c.dispose());
                    _dynamicControllers.clear();
                    _dynamicValues.clear();
                  });
                },
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.category, color: AppColors.primary, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                dropdownColor: Colors.white,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                ),
              ),
      ],
    );
  }

  Widget _buildNegotiableField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _isNegotiable,
                onChanged: (value) {
                  setState(() {
                    _isNegotiable = value;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ),
            Row(
              children: [
                Text(
                  'قابل للمقايضة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isNegotiable
                        ? AppColors.primary
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.swap_horiz,
                  color:
                      _isNegotiable ? AppColors.primary : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSwapOption(
          label: 'حالة المنتج',
          icon: Icons.stars,
          child: DropdownButton<ProductCondition>(
            value: _selectedCondition,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            items: const [
              DropdownMenuItem(
                  value: ProductCondition.newProduct,
                  child: Text('جديد', textAlign: TextAlign.right)),
              DropdownMenuItem(
                  value: ProductCondition.usedGood,
                  child:
                      Text('مستعمل - حالة جيدة', textAlign: TextAlign.right)),
              DropdownMenuItem(
                  value: ProductCondition.usedFair,
                  child:
                      Text('مستعمل - حالة متوسطة', textAlign: TextAlign.right)),
            ],
            onChanged: (value) => setState(() => _selectedCondition = value!),
          ),
        ),
        const SizedBox(height: 12),
        _buildSwapOption(
          label: 'الموقع',
          icon: Icons.location_on,
          child: TextField(
            controller: _locationController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'مثال: صنعاء، عدن',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwapOption(
      {required String label, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: child),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }

  /// قسم إعدادات الدفع

  /// حقل نصي لإعدادات الدفع

  Widget _buildCategorySpecificFields() {
    final String category = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    // Get schema for this category
    // We try to find a match in the keys allowing for partial matches if needed,
    // or exact match. The simple exact match is safest first.
    final schema = categorySchemas[category];

    if (schema == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(right: 28.0, bottom: 8),
          child: Text(
            'تفاصيل المنتج ($category)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        ...schema.entries.map((entry) {
          final fieldName = entry.key;
          final fieldData = entry.value;
          final String type = fieldData['type'];
          final String label = fieldData['label'];
          final bool required = fieldData['required'];

          if (type == 'text' || type == 'number' || type == 'float') {
            // Check if controller exists, else create
            if (!_dynamicControllers.containsKey(fieldName)) {
              _dynamicControllers[fieldName] = TextEditingController();
            }
            final controller = _dynamicControllers[fieldName]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTextField(
                controller: controller,
                label: label,
                hint: fieldData['hint'] ?? '',
                icon: Icons.info_outline,
                keyboardType: (type == 'number' || type == 'float')
                    ? TextInputType.number
                    : TextInputType.text,
                validator: (value) {
                  if (required && (value == null || value.isEmpty)) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                },
              ),
            );
          } else if (type == 'list') {
            final List<String> options =
                List<String>.from(fieldData['options']);
            // Initialize value if null
            if (_dynamicValues[fieldName] == null && options.isNotEmpty) {
              _dynamicValues[fieldName] = options.first;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 24, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label + (required ? ' *' : ''),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _dynamicValues[fieldName],
                      items: options.map((opt) {
                        return DropdownMenuItem(
                          value: opt,
                          child: Text(opt, textAlign: TextAlign.right),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _dynamicValues[fieldName] = val;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (type == 'boolean') {
            // Initialize to false if null
            if (_dynamicValues[fieldName] == null) {
              _dynamicValues[fieldName] = false;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 24, right: 24),
              child: CheckboxListTile(
                title: Text(label, textAlign: TextAlign.right),
                value: _dynamicValues[fieldName] ?? false,
                onChanged: (val) {
                  setState(() {
                    _dynamicValues[fieldName] = val;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4.0, bottom: 8),
          child: Text(
            'الوصف (اختياري)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        TextFormField(
          controller: _descriptionController,
          textAlign: TextAlign.right,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'أدخل وصف المنتج بشكل مفصل...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:
                const Icon(Icons.description, color: Colors.teal, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || _isUploadingImage) ? null : _addProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'إضافة المنتج',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'إضافة صور',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'كاميرا',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromSource(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        await _uploadImages();
      }
    } catch (e) {
      debugPrint('❌ خطأ في التقاط الصورة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في التقاط الصورة')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((img) => File(img.path)));
        });
        await _uploadImages();
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصور: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في اختيار الصور')),
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // رفع الصور التي لم يتم رفعها بعد
      // لتبسيط المنطق حالياً، سنقوم برفع الصور الجديدة فقط
      // ولكن بما أن _uploadedImageUrls يتم تصفيرها في pickImage القديم،
      // سنقوم هنا برفع كل الصور التي ليس لها URL (إذا أردنا منطقاً أدق)
      // للتبسيط الآن: سنقوم برفع كل الصور المختارة وتحديث القائمة

      List<String> urls = [];
      for (var image in _selectedImages) {
        String? imageUrl = await ImgBBService.uploadImage(image);
        if (imageUrl != null) {
          urls.add(imageUrl);
        }
      }

      setState(() {
        _uploadedImageUrls = urls;
      });

      if (!mounted) return;
      if (urls.length == _selectedImages.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم رفع جميع الصور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (urls.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ تم رفع ${urls.length} من أصل ${_selectedImages.length} صور'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصور: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في رفع الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty || _uploadedImageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 يرجى رفع صور للمنتج أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint('🚀 بدأ إضافة المنتج...');

        // إنشاء معرف فريد للمنتج
        String productId = DateTime.now().millisecondsSinceEpoch.toString();

        // تحديد التصنيف النهائي
        final String category = _isCustomCategory
            ? _customCategoryController.text.trim()
            : _selectedCategory;

        // إعداد بيانات المنتج
        Map<String, dynamic> productData = {
          'id': productId,
          'name': _nameController.text.trim(),
          'price': _priceController.text.trim(),
          'isNegotiable': _isNegotiable,
          'description': _descriptionController.text.trim(),
          'category': category,
          'imageUrl': _uploadedImageUrls.first,
          'images': _uploadedImageUrls,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'isAvailable': true,
          'isApproved': false,
          'sellerId': FirebaseAuth.instance.currentUser?.uid,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'ownerId': FirebaseAuth.instance.currentUser?.uid,
          // حقول المقايضة (الموقع والحالة دائماً)
          'location': _locationController.text.trim(),
          'condition': _selectedCondition.index,
          'isSwappable': _isNegotiable,
          'swapType': _isNegotiable ? SwapType.productProduct.index : null,
          'swapStatus': SwapStatus.available.index,
          'specifications': _collectSpecifications(category),
        };

        debugPrint('🔥 جاري حفظ البيانات في Firebase...');
        await _database.child('products').child(productId).set(productData);

        // حفظ التصنيف الجديد إذا كان مخصصاً
        if (_isCustomCategory) {
          try {
            // التحقق من عدم وجود التصنيف مسبقاً
            if (!_categories.contains(category)) {
              // إضافة للقائمة المحلية
              _categories.add(category);

              // تحديث القائمة في قاعدة البيانات
              // ملاحظة: الأفضل استخدام قائمة (array) أو map في Realtime Database
              // هنا سنفترض أننا نضيف لقائمة بسيطة، لكن الأفضل استخدام push() للمعرفات الفريدة
              // ولكن للتبسيط ولتوافق الكود الحالي سنقوم بإعادة حفظ القائمة كاملة أو إضافته كعنصر جديد

              // الطريقة الأبسط: إضافة عقدة جديدة
              // ولكن بما أننا نقرأها كقائمة، سنقوم بجلب القائمة الحالية، وإضافة العنصر، ثم الحفظ
              // سنستخدم push لإضافة قيمة جديدة ولن نعتمد على الفهرس الرقمي
              // ولكن لكي يعمل التحميل (reading as List) يجب أن تكون المفاتيح رقمية متسلسلة 0,1,2...
              // في Realtime Database العادية القوائم صعبة.
              // الحل العملي: حفظ التصنيفات كمفاتيح (keys) لسهولة البحث ومنع التكرار

              // سنقوم بحفظ التصنيف الجديد باستخدام push لكن سنحتاج لتعديل القراءة
              // أو سنقوم بحفظه في مسار 'categories/custom_categories' لتفريقها

              // للتوافق مع الحل الأسرع:
              // سنحفظه في مسار جديد ونحدث القراءة لتقرأ منه أيضاً
              await _database.child('categories').push().set({
                'name': category,
                'createdBy': FirebaseAuth.instance.currentUser?.uid,
                'createdAt': ServerValue.timestamp,
              });
            }
          } catch (e) {
            debugPrint('Error saving new category: $e');
          }
        }

        debugPrint('✅ تم حفظ البيانات في Firebase');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم إضافة المنتج بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // الانتقال لصفحة تفاصيل المنتج بدلاً من مجرد العودة
        if (mounted) {
          Get.off(() => ProductDetailsPage(
                product: Product.fromMap(productData),
              ));
        }
      } catch (e) {
        debugPrint('❌ خطأ في إضافة المنتج: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إضافة المنتج: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Map<String, dynamic> _collectSpecifications(String category) {
    // Collect from dynamic controllers
    Map<String, dynamic> specs = {};
    _dynamicControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        specs[key] = controller.text.trim();
      }
    });
    // Collect from dynamic values
    _dynamicValues.forEach((key, value) {
      if (value != null) {
        specs[key] = value;
      }
    });
    return specs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customCategoryController.dispose();
    _dynamicControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
}
