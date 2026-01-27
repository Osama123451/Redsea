import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:redsea/services/imgbb_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:get/get.dart';

class AddExperiencePage extends StatefulWidget {
  final Experience? experience;
  const AddExperiencePage({super.key, this.experience});

  @override
  State<AddExperiencePage> createState() => _AddExperiencePageState();
}

class _AddExperiencePageState extends State<AddExperiencePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearsExpController = TextEditingController();
  final _userStudiesController = TextEditingController();
  final _locationController = TextEditingController();
  final _consultationPriceController = TextEditingController();
  final _experiencePriceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsController = TextEditingController();

  bool _isSaleable = true;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _selectedCategory = 'أخرى';
  String _selectedPriceUnit = 'ساعة';
  File? _selectedImage;
  String _uploadedImageUrl = '';

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    // Pre-fill data if editing
    if (widget.experience != null) {
      final exp = widget.experience!;
      _titleController.text = exp.title;
      _descriptionController.text = exp.description;
      _yearsExpController.text = exp.yearsOfExperience.toString();
      _userStudiesController.text = exp.userStudies ?? '';
      _locationController.text = exp.location ?? '';
      _consultationPriceController.text =
          exp.consultationPrice?.toString() ?? '';
      _experiencePriceController.text = exp.experiencePrice?.toString() ?? '';
      _phoneController.text = exp.phone;
      _skillsController.text = exp.skills.join(', ');

      _isSaleable = exp.isSaleable;
      _uploadedImageUrl = exp.imageUrl;
      _selectedCategory = ExperienceCategory.categories.contains(exp.category)
          ? exp.category
          : 'أخرى';
      _selectedPriceUnit = exp.priceUnit;
    } else {
      if (ExperienceCategory.categories.isNotEmpty) {
        _selectedCategory =
            ExperienceCategory.categories.contains('تصميم وبرمجة')
                ? 'تصميم وبرمجة'
                : ExperienceCategory.categories[1];
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploadingImage = true;
      });

      try {
        final url = await ImgBBService.uploadImage(_selectedImage!);
        if (url != null) {
          setState(() {
            _uploadedImageUrl = url;
          });
        }
      } catch (e) {
        Get.snackbar('خطأ', 'فشل رفع الصورة');
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveExperience() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final experienceData = {
        'expert_id': user.uid,
        'expertName': user.displayName ?? 'خبير',
        'title': _titleController.text,
        'description': _descriptionController.text,
        'years_exp': int.tryParse(_yearsExpController.text) ?? 0,
        'user_studies': _userStudiesController.text,
        'location': _locationController.text,
        'consultation_price':
            double.tryParse(_consultationPriceController.text) ?? 0.0,
        'experience_price': _isSaleable
            ? (double.tryParse(_experiencePriceController.text) ?? 0.0)
            : 0.0,
        'price_unit': _selectedPriceUnit,
        'is_saleable': _isSaleable,
        'category': _selectedCategory,
        'imageUrl': _uploadedImageUrl,
        'phone': _phoneController.text,
        'skills': skills,
        'isAvailable': true,
        // Preserve original fields if editing, else set defaults
        'rate': widget.experience?.rating ?? 0.0,
        'reviewsCount': widget.experience?.reviewsCount ?? 0,
        'timestamp': widget.experience?.timestamp ??
            DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.experience != null) {
        // Update existing
        await _database
            .child('experiences')
            .child(widget.experience!.id)
            .update(experienceData);
        Get.back();
        Get.snackbar('تم بنجاح', 'تم تحديث الخبرة بنجاح');
      } else {
        // Create new
        await _database.child('experiences').push().set(experienceData);
        Get.back();
        Get.snackbar('تم بنجاح', 'تم إضافة خبرتك بنجاح');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الحفظ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.experience != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل الخبرة' : 'أضف خبرتك'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    _buildTextField(_titleController,
                        'عنوان الخبرة (مثلاً: خبير صيانة ميكانيك)', Icons.work),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTextField(_yearsExpController,
                                'سنوات الخبرة', Icons.history,
                                keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildTextField(_consultationPriceController,
                                'سعر الاستشارة', Icons.message,
                                keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_userStudiesController, 'المؤهلات العلمية',
                        Icons.school),
                    const SizedBox(height: 12),
                    _buildTextField(_locationController, 'الموقع / المدينة',
                        Icons.location_on),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _phoneController, 'رقم التواصل', Icons.phone,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(_skillsController,
                        'المهارات (افصل بينها بفاصلة ,)', Icons.star),
                    const SizedBox(height: 12),
                    _buildTextField(_descriptionController,
                        'وصف الخبرة بالتفصيل', Icons.description,
                        maxLines: 4),
                    const SizedBox(height: 12),
                    _buildSaleableSwitch(),
                    if (_isSaleable) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(_experiencePriceController,
                                'السعر', Icons.payments,
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: _buildUnitDropdown(),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveExperience,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إضافة الخبرة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: _isUploadingImage
            ? const Center(child: CircularProgressIndicator())
            : _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('أضف صورة شخصية أو مهنية'),
                    ],
                  ),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPriceUnit,
      decoration: InputDecoration(
        labelText: 'الوحدة',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['ساعة', 'يوم', 'شهر', 'مشروع'].map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPriceUnit = newValue;
          });
        }
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'التصنيف',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: ExperienceCategory.categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
          });
        }
      },
    );
  }

  Widget _buildSaleableSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: _isSaleable,
            onChanged: (value) => setState(() => _isSaleable = value),
            activeColor: AppColors.primary,
          ),
          const Text('هل تريد بيع الخبرة؟', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
