import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:redsea/services/imgbb_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/product_model.dart';

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
  File? _selectedImage;
  String? _uploadedImageUrl;

  // حقول المقايضة الجديدة
  // SwapType _selectedSwapType = SwapType.productProduct; // Removed as per request to simplify UI
  ProductCondition _selectedCondition = ProductCondition.usedGood;
  final TextEditingController _locationController = TextEditingController();

  List<String> _categories = [
    'الكترونيات',
    'أجهزة منزلية',
    'ملابس',
    'عطور',
    'ساعات',
    'أخرى'
  ];

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
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
              loadedCategories.add(value.toString());
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
      backgroundColor: Colors.white,
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
            fontSize: 20,
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 30),

                    // عنوان إضافة منتج جديد
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade50,
                              Colors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.blue.shade100, width: 2),
                        ),
                        child: const Text(
                          'إضافة منتج جديد',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // صورة المنتج
                    _buildImageField(),

                    const SizedBox(height: 30),

                    // اسم المنتج
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

                    const SizedBox(height: 20),

                    // السعر
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

                    const SizedBox(height: 20),

                    // التصنيف
                    _buildCategoryField(),

                    const SizedBox(height: 20),

                    // قابل للمقايضة
                    _buildNegotiableField(),

                    const SizedBox(height: 20),

                    // الوصف
                    _buildDescriptionField(),

                    const SizedBox(height: 40),

                    // زر إضافة المنتج
                    _buildAddButton(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isUploadingImage)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const SizedBox(width: 20),
                Text(
                  'صورة المنتج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.blue.shade50,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
              ),
              child: _isUploadingImage
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('جاري رفع الصورة...'),
                        ],
                      ),
                    )
                  : _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (_uploadedImageUrl != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.blue.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'إضافة صورة المنتج',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '(مطلوب)',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          if (_uploadedImageUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تم رفع الصورة بنجاح',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textAlign: TextAlign.right,
                    validator: validator,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        height: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isCustomCategory = false;
  final TextEditingController _customCategoryController =
      TextEditingController();

  Widget _buildCategoryField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر صنف جديد
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCustomCategory = !_isCustomCategory;
                      if (!_isCustomCategory) {
                        _selectedCategory = _categories.first;
                        _customCategoryController.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isCustomCategory ? Icons.list : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    _isCustomCategory ? 'اختر من القائمة' : 'صنف جديد',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
                Text(
                  'التصنيف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    _isCustomCategory ? Icons.edit : Icons.category,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: _isCustomCategory
                      ? TextFormField(
                          controller: _customCategoryController,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: 'أدخل اسم الصنف الجديد',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
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
                          key: ValueKey(_selectedCategory),
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
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          dropdownColor: Colors.white,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiableField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // خيار تفعيل المقايضة
          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isNegotiable
                    ? [AppColors.primary.withValues(alpha: 0.1), Colors.white]
                    : [Colors.white, AppColors.primary.withValues(alpha: 0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: _isNegotiable
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    )
                  : BorderRadius.circular(15),
              border: Border.all(
                color: _isNegotiable
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: _isNegotiable,
                  onChanged: (value) {
                    setState(() {
                      _isNegotiable = value;
                    });
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'قابل للمقايضة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.swap_horiz,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // خيارات المقايضة الإضافية
          if (_isNegotiable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // تم إزالة خيار نوع المقايضة بناءً على الطلب

                  // حالة المنتج
                  _buildSwapOption(
                    label: 'حالة المنتج',
                    icon: Icons.stars,
                    child: DropdownButton<ProductCondition>(
                      value: _selectedCondition,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: ProductCondition.newProduct,
                            child: Text('جديد')),
                        DropdownMenuItem(
                            value: ProductCondition.usedGood,
                            child: Text('مستعمل - حالة جيدة')),
                        DropdownMenuItem(
                            value: ProductCondition.usedFair,
                            child: Text('مستعمل - حالة متوسطة')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCondition = value!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // الموقع
                  _buildSwapOption(
                    label: 'الموقع',
                    icon: Icons.location_on,
                    child: TextField(
                      controller: _locationController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: 'مثال: جدة، الرياض',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwapOption(
      {required String label, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(child: child),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.green.shade700)),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.green.shade600, size: 20),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8),
            child: Text(
              'الوصف (اختياري)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.blue.shade700,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    textAlign: TextAlign.right,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'أدخل وصف المنتج',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (_isLoading || _isUploadingImage) ? null : _addProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl = null;
        });

        // رفع الصورة تلقائياً بعد الاختيار
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('❌ خطأ في اختيار الصورة: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في اختيار الصورة')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      String? imageUrl = await ImgBBService.uploadImage(_selectedImage!);

      if (imageUrl != null) {
        setState(() {
          _uploadedImageUrl = imageUrl;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم رفع الصورة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل في رفع الصورة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في رفع الصورة: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في رفع الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null || _uploadedImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 يرجى رفع صورة للمنتج أولاً'),
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
          'imageUrl': _uploadedImageUrl!,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'isAvailable': true,
          'sellerId': FirebaseAuth.instance.currentUser?.uid,
          // حقول المقايضة
          'isSwappable': _isNegotiable,
          'swapType': _isNegotiable
              ? SwapType.productProduct.index
              : null, // نوع افتراضي لأن القائمة حذفت
          'condition': _isNegotiable ? _selectedCondition.index : null,
          'location': _isNegotiable ? _locationController.text.trim() : null,
          'swapStatus': SwapStatus.available.index,
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
              // أو الأفضل لتجنب التعارض (race conditions): استخدام push

              // سنستخدم push لإضافة قيمة جديدة ولن نعتمد على الفهرس الرقمي
              // ولكن لكي يعمل التحميل (reading as List) يجب أن تكون المفاتيح رقمية متسلسلة 0,1,2...
              // في Realtime Database العادية القوائم صعبة.
              // الحل العملي: حفظ التصنيفات كمفاتيح (keys) لسهولة البحث ومنع التكرار

              // سنقوم بحفظ التصنيف الجديد باستخدام push لكن سنحتاج لتعديل القراءة
              // أو سنقوم بحفظه في مسار 'categories/custom_categories' لتفريقها

              // للتوافق مع الحل الأسرع:
              // سنحفظه في مسار جديد ونحدث القراءة لتقرأ منه أيضاً
              await _database.child('categories').push().set(category);
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

        // تنظيف الحقول بعد الإضافة
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _customCategoryController.clear();
        setState(() {
          _selectedImage = null;
          _uploadedImageUrl = null;
          _selectedCategory = 'الكترونيات';
          _isNegotiable = true;
          _isCustomCategory = false;
        });

        // العودة للصفحة الرئيسية بعد ثانية
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }
}
