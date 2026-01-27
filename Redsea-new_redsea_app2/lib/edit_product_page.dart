import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:redsea/services/imgbb_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// صفحة تعديل المنتج
class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  late bool _isNegotiable;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  late String _selectedCategory;
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  // حقول العروض الخاصة
  late bool _isSpecialOffer;
  late TextEditingController _oldPriceController;

  // حقول الموقع والحالة (مستقله الآن)
  late ProductCondition _selectedCondition;
  late TextEditingController _locationController;

  List<String> _categories = [
    'الكترونيات',
    'أجهزة منزلية',
    'ملابس',
    'عطور',
    'ساعات',
    'أخرى'
  ];

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // متغيرات للتصنيف المخصص
  bool _isCustomCategory = false;
  final TextEditingController _customCategoryController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromProduct();
    _loadCategories();
  }

  void _initializeFromProduct() {
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: product.price);
    _descriptionController = TextEditingController(text: product.description);
    _isNegotiable = product.negotiable;
    _selectedCategory = product.category;
    _uploadedImageUrls = product.images ??
        (product.imageUrl.isNotEmpty ? [product.imageUrl] : []);
    _isSpecialOffer = product.isSpecialOffer;
    _oldPriceController = TextEditingController(text: product.oldPrice ?? '');
    _selectedCondition = product.condition ?? ProductCondition.usedGood;
    _locationController = TextEditingController(text: product.location ?? '');
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _database.child('categories').get();
      if (snapshot.exists) {
        List<String> loadedCategories = [];

        if (snapshot.value is List) {
          final list = snapshot.value as List<dynamic>;
          loadedCategories =
              list.where((e) => e != null).map((e) => e.toString()).toList();
        } else if (snapshot.value is Map) {
          final map = snapshot.value as Map<dynamic, dynamic>;
          map.forEach((key, value) {
            if (value != null) {
              if (value is Map) {
                final catName = value['name']?.toString() ?? '';
                if (catName.isNotEmpty) {
                  loadedCategories.add(catName);
                }
              } else {
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
              _categories.add(_selectedCategory);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _oldPriceController.dispose();
    _customCategoryController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المنتج'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // صورة المنتج
                    _buildImageSection(),
                    const SizedBox(height: 20),

                    // اسم المنتج
                    _buildTextField(
                      controller: _nameController,
                      label: 'اسم المنتج',
                      hint: 'مثال: آيفون 15 برو',
                      icon: Icons.shopping_bag,
                    ),
                    const SizedBox(height: 16),

                    // السعر
                    _buildTextField(
                      controller: _priceController,
                      label: 'السعر (ريال يمني)',
                      hint: 'مثال: 250000',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // التصنيف
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),

                    // قابل للمقايضة
                    _buildNegotiableSwitch(),
                    const SizedBox(height: 16),

                    // حقول الموقع والحالة
                    _buildBasicInfoSection(),
                    const SizedBox(height: 16),

                    // عرض خاص
                    _buildSpecialOfferSection(),
                    const SizedBox(height: 16),

                    // الوصف
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'الوصف (اختياري)',
                      hint: 'أضف وصف للمنتج...',
                      icon: Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 30),

                    // زر الحفظ
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    int totalImages = _uploadedImageUrls.length + _selectedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isUploadingImage)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const Text(
                'صور المنتج',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: totalImages == 0
              ? GestureDetector(
                  onTap: _isUploadingImage ? null : _pickImage,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لاختيار صور',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _imagePageController,
                      itemCount: totalImages,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        bool isExisting = index < _uploadedImageUrls.length;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            if (isExisting)
                              CachedNetworkImage(
                                imageUrl: _uploadedImageUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.error),
                              )
                            else
                              Image.file(
                                _selectedImages[
                                    index - _uploadedImageUrls.length],
                                fit: BoxFit.cover,
                              ),
                            // زر الحذف
                            Positioned(
                              top: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isExisting) {
                                      _uploadedImageUrls.removeAt(index);
                                    } else {
                                      _selectedImages.removeAt(
                                          index - _uploadedImageUrls.length);
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
                        );
                      },
                    ),
                    // مؤشر الصفحات (Dots)
                    if (totalImages > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            totalImages,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentImageIndex == index ? 10 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: _currentImageIndex == index
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.7),
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
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'إضافة المزيد',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: (value) {
        if (label.contains('اسم') && (value == null || value.isEmpty)) {
          return 'يرجى إدخال اسم المنتج';
        }
        if (label.contains('السعر') && (value == null || value.isEmpty)) {
          return 'يرجى إدخال السعر';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // العنوان مع زر صنف جديد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isCustomCategory = !_isCustomCategory;
                      if (!_isCustomCategory) {
                        _customCategoryController.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isCustomCategory ? Icons.list : Icons.add,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _isCustomCategory ? 'اختر من القائمة' : 'صنف جديد',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'التصنيف',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.category, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          // حقل الإدخال أو القائمة المنسدلة
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _isCustomCategory
                ? TextFormField(
                    controller: _customCategoryController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم الصنف الجديد',
                      prefixIcon:
                          const Icon(Icons.edit, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
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
                    initialValue: _categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : _categories.first,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.category, color: AppColors.primary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiableSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: _isNegotiable,
            onChanged: (value) {
              setState(() {
                _isNegotiable = value;
                if (value) {
                  _isSpecialOffer = false;
                  _oldPriceController.clear();
                }
              });
            },
            activeThumbColor: AppColors.primary,
          ),
          const Row(
            children: [
              Text('قابل للمقايضة',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.handshake, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButton<ProductCondition>(
                  value: _selectedCondition,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600),
                  items: const [
                    DropdownMenuItem(
                      value: ProductCondition.newProduct,
                      child: Text('جديد', textAlign: TextAlign.right),
                    ),
                    DropdownMenuItem(
                      value: ProductCondition.usedGood,
                      child: Text('مستعمل - حالة جيدة',
                          textAlign: TextAlign.right),
                    ),
                    DropdownMenuItem(
                      value: ProductCondition.usedFair,
                      child: Text('مستعمل - حالة متوسطة',
                          textAlign: TextAlign.right),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCondition = value!),
                ),
              ),
              const SizedBox(width: 12),
              const Text('حالة المنتج',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.stars, color: AppColors.primary),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _locationController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'مثال: صنعاء، عدن',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('الموقع',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOfferSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isNegotiable
            ? Colors.grey.shade50
            : (_isSpecialOffer ? Colors.green.shade50 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isNegotiable
              ? Colors.grey.shade200
              : (_isSpecialOffer ? Colors.green : Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: _isSpecialOffer,
                onChanged: _isNegotiable
                    ? null
                    : (value) {
                        setState(() {
                          _isSpecialOffer = value;
                        });
                      },
                activeThumbColor: Colors.green,
              ),
              Row(
                children: [
                  Text(
                    _isNegotiable ? 'عرض خاص (غير متاح)' : 'عرض خاص 🔥',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _isNegotiable ? Colors.grey.shade400 : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isSpecialOffer) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _oldPriceController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'السعر القديم',
                prefixIcon: const Icon(Icons.money_off, color: Colors.red),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'حفظ التعديلات',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في التقاط الصورة')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
        await _uploadImages();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
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
      List<String> newUrls = [];
      for (var imageFile in _selectedImages) {
        final imageUrl = await ImgBBService.uploadImage(imageFile);
        if (imageUrl != null) {
          newUrls.add(imageUrl);
        }
      }

      if (mounted) {
        setState(() {
          _uploadedImageUrls.addAll(newUrls);
          _selectedImages.clear(); // تفريغ الملفات بعد الرفع بنجاح
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصور: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من أن المنتج يخص المستخدم الحالي
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    if (widget.product.ownerId != null && widget.product.ownerId != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ لا يمكنك تعديل منتج لا تملكه')),
      );
      return;
    }

    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار صورة واحدة على الأقل للمنتج')),
      );
      return;
    }

    // التحقق من حقول الدفع إذا لم يكن الدفع عند الاستلام

    setState(() {
      _isLoading = true;
    });

    try {
      // تحديد التصنيف النهائي
      final String category = _isCustomCategory
          ? _customCategoryController.text.trim()
          : _selectedCategory;

      final updates = {
        'name': _nameController.text.trim(),
        'price': _priceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': category,
        'imageUrl': _uploadedImageUrls.first,
        'images': _uploadedImageUrls,
        'isNegotiable': _isNegotiable,
        'negotiable': _isNegotiable,
        'isSpecialOffer': _isSpecialOffer,
        'oldPrice': _isSpecialOffer ? _oldPriceController.text.trim() : null,
        'isApproved': false,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'location': _locationController.text.trim(),
        'condition': _selectedCondition.index,
      };

      await _database
          .child('products')
          .child(widget.product.id)
          .update(updates);

      // حفظ التصنيف الجديد في Firebase إذا كان مخصصاً
      if (_isCustomCategory && category.isNotEmpty) {
        try {
          if (!_categories.contains(category)) {
            await _database.child('categories').push().set({
              'name': category,
              'createdBy': userId,
              'createdAt': ServerValue.timestamp,
            });
            debugPrint('✅ تم حفظ التصنيف الجديد: $category');
          }
        } catch (e) {
          debugPrint('Error saving new category: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث المنتج بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ في التحديث: $e')),
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
