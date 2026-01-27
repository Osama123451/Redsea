import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:redsea/app/controllers/service_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/models/service_model.dart';
import 'package:redsea/services/imgbb_service.dart';

/// صفحة إضافة خدمة جديدة - تصميم محسّن مع الاختيار التلقائي الذكي
class AddServicePage extends StatefulWidget {
  final String? initialCategory;

  const AddServicePage({super.key, this.initialCategory});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _durationController = TextEditingController();

  late String _selectedCategory;
  bool _isCategoryAutoDetected = false; // هل تم اختيار الفئة تلقائياً
  bool _canEditCategory = false; // هل يمكن تعديل الفئة (في حالة "أخرى")
  final List<String> _selectedPreferences = [];
  final List<String> _portfolioUrls = [];
  final List<ServicePackage> _packages = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;

  // متغيرات العرض الخاص
  bool _isSpecialOffer = false;
  final _oldValueController = TextEditingController();

  // الكلمات المفتاحية لكل فئة
  static const Map<String, List<String>> _categoryKeywords = {
    'تصميم': [
      'شعار',
      'لوجو',
      'logo',
      'بنر',
      'banner',
      'فلاير',
      'هوية',
      'بوستر',
      'تصميم',
      'جرافيك',
      'graphic',
      'design',
      'بطاقة',
      'كرت',
      'سوشيال',
      'انفوجرافيك',
      'ui',
      'ux',
      'واجهة',
      'موك اب',
      'mockup',
      'فوتوشوب',
      'اليستريتور',
      'كانفا',
      'صورة بروفايل',
      'غلاف',
    ],
    'برمجة': [
      'موقع',
      'تطبيق',
      'app',
      'website',
      'كود',
      'برنامج',
      'أندرويد',
      'android',
      'ios',
      'آيفون',
      'فلاتر',
      'flutter',
      'react',
      'برمجة',
      'نظام',
      'api',
      'قاعدة بيانات',
      'database',
      'سكربت',
      'script',
      'ووردبريس',
      'wordpress',
      'شوبيفاي',
      'متجر الكتروني',
      'لوحة تحكم',
      'dashboard',
      'بوت',
      'bot',
    ],
    'تصوير': [
      'صورة',
      'فيديو',
      'تصوير',
      'كاميرا',
      'إعلان',
      'منتج',
      'عقاري',
      'زفاف',
      'مناسبة',
      'استوديو',
      'فوتو',
      'photo',
      'video',
      'drone',
      'درون',
      'ريلز',
      'reels',
      'يوتيوب',
      'youtube',
      'تيك توك',
    ],
    'كتابة وترجمة': [
      'ترجمة',
      'كتابة',
      'مقال',
      'محتوى',
      'تدقيق',
      'نسخ',
      'سيناريو',
      'رواية',
      'قصة',
      'بحث',
      'تقرير',
      'سيرة ذاتية',
      'cv',
      'resume',
      'نصوص',
      'اعلاني',
      'سلوقان',
      'شعار كتابي',
      'بايو',
      'bio',
      'وصف',
      'عربي',
      'انجليزي',
      'translate',
      'translation',
      'content',
      'copywriting',
      'article',
    ],
    'تسويق رقمي': [
      'إعلان',
      'تسويق',
      'سوشيال',
      'فيسبوك',
      'انستقرام',
      'حملة',
      'seo',
      'ادارة',
      'صفحة',
      'اعلانات',
      'ممول',
      'جوجل',
      'google ads',
      'تيك توك',
      'سناب',
      'يوتيوب',
      'marketing',
      'digital',
      'social media',
      'followers',
      'متابعين',
      'لايكات',
      'تفاعل',
      'engagement',
    ],
    'صيانة وإصلاح': [
      'صيانة',
      'إصلاح',
      'تركيب',
      'كهرباء',
      'سباكة',
      'تكييف',
      'جوال',
      'موبايل',
      'لابتوب',
      'كمبيوتر',
      'شاشة',
      'تصليح',
      'قطع غيار',
      'فني',
      'تمديد',
      'دهان',
      'نجارة',
      'ألمنيوم',
      'أبواب',
      'نوافذ',
    ],
    'تدريس وتعليم': [
      'تدريس',
      'دروس',
      'تعليم',
      'إنجليزي',
      'english',
      'رياضيات',
      'math',
      'شرح',
      'دورة',
      'كورس',
      'course',
      'تدريب',
      'training',
      'أستاذ',
      'معلم',
      'مدرس',
      'private',
      'خصوصي',
      'اونلاين',
      'online',
      'قرآن',
      'تجويد',
      'فيزياء',
      'كيمياء',
      'علوم',
      'عربي',
      'فرنسي',
      'ألماني',
      'برمجة للمبتدئين',
    ],
    'إنتاج صوتي ومرئي': [
      'تعليق',
      'صوتي',
      'مونتاج',
      'فويس',
      'voiceover',
      'voice',
      'بودكاست',
      'podcast',
      'موسيقى',
      'أغنية',
      'لحن',
      'تسجيل',
      'هندسة صوتية',
      'مكس',
      'mix',
      'master',
      'ماستر',
      'اوديو',
      'audio',
      'فيديو',
      'edit',
      'editing',
      'مقدمة',
      'intro',
      'outro',
      'افتر افكت',
      'after effects',
      'بريمير',
    ],
  };

  // قوالب الوصف لكل فئة
  static const Map<String, String> _descriptionTemplates = {
    'تصميم':
        'أقدم خدمة {title} باحترافية عالية وجودة ممتازة. سأصمم لك عملاً مميزاً بأسلوب عصري يناسب هويتك ويحقق أهدافك. أضمن لك نتيجة مبهرة مع إمكانية التعديل حتى الرضا الكامل.',
    'برمجة':
        'أقدم خدمة {title} بأحدث التقنيات والمعايير. سأطور لك حلاً برمجياً نظيفاً ومنظماً وقابلاً للتطوير. أضمن كوداً عالي الجودة مع توثيق كامل ودعم فني بعد التسليم.',
    'تصوير':
        'أقدم خدمة {title} باحترافية وجودة عالية. سأوفر لك صوراً/فيديوهات مميزة بإضاءة وزوايا احترافية. أستخدم أحدث المعدات وتقنيات المعالجة للحصول على أفضل النتائج.',
    'كتابة وترجمة':
        'أقدم خدمة {title} بدقة واحترافية. سأكتب/أترجم لك محتوى سليماً لغوياً وجذاباً للقارئ. أهتم بالتفاصيل وأضمن خلو العمل من الأخطاء مع الحفاظ على المعنى والسياق.',
    'تسويق رقمي':
        'أقدم خدمة {title} بخبرة واسعة في المجال. سأساعدك في الوصول لجمهورك المستهدف وزيادة التفاعل والمبيعات. أستخدم استراتيجيات مجربة وأدوات تحليل متقدمة.',
    'صيانة وإصلاح':
        'أقدم خدمة {title} بخبرة ومهارة. سأقوم بالعمل بدقة وسرعة مع ضمان الجودة. أستخدم قطع غيار أصلية وأوفر ضماناً على العمل المنجز.',
    'تدريس وتعليم':
        'أقدم خدمة {title} بأسلوب مبسط وفعال. سأساعدك في فهم المادة بطريقة تفاعلية تضمن الاستيعاب والتميز. لدي خبرة واسعة وأساليب تدريس متنوعة تناسب جميع المستويات.',
    'إنتاج صوتي ومرئي':
        'أقدم خدمة {title} بجودة استوديو احترافي. سأوفر لك عملاً صوتياً/مرئياً مميزاً بأعلى المعايير. أستخدم أحدث البرامج والتقنيات مع إمكانية التعديل حسب طلبك.',
    'أخرى':
        'أقدم خدمة {title} باحترافية وإتقان. سأنفذ العمل بجودة عالية وفي الوقت المحدد. أهتم برضا العميل وأضمن نتيجة مميزة تلبي توقعاتك.',
  };

  @override
  void initState() {
    super.initState();
    // تعيين الفئة المبدئية إذا تم تمريرها
    _selectedCategory =
        (widget.initialCategory != null && widget.initialCategory != 'الكل')
            ? widget.initialCategory!
            : 'أخرى';

    // إضافة listener للعنوان للكشف التلقائي
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    _oldValueController.dispose();
    super.dispose();
  }

  /// عند تغيير العنوان - الكشف التلقائي عن الفئة
  void _onTitleChanged() {
    final title = _titleController.text.trim().toLowerCase();
    if (title.isEmpty) {
      setState(() {
        _isCategoryAutoDetected = false;
        _canEditCategory = true;
      });
      return;
    }

    final detectedCategory = _detectCategory(title);
    setState(() {
      _selectedCategory = detectedCategory;
      _isCategoryAutoDetected = detectedCategory != 'أخرى';
      _canEditCategory =
          detectedCategory == 'أخرى'; // السماح بالتعديل فقط إذا كانت "أخرى"

      // اقتراح الوصف تلقائياً (إذا كان فارغاً أو لم يتم تعديله)
      if (_descriptionController.text.isEmpty ||
          _isAutoGeneratedDescription(_descriptionController.text)) {
        _descriptionController.text = _generateSuggestedDescription();
      }
    });
  }

  /// الكشف التلقائي عن الفئة من العنوان
  String _detectCategory(String title) {
    String bestMatch = 'أخرى';
    int maxMatches = 0;

    for (final entry in _categoryKeywords.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (title.contains(keyword.toLowerCase())) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestMatch = entry.key;
      }
    }

    return bestMatch;
  }

  /// توليد وصف مقترح
  String _generateSuggestedDescription() {
    final template = _descriptionTemplates[_selectedCategory] ??
        _descriptionTemplates['أخرى']!;
    final title = _titleController.text.trim();
    return template.replaceAll('{title}', title.isEmpty ? 'هذه الخدمة' : title);
  }

  /// التحقق مما إذا كان الوصف مُولّد تلقائياً
  bool _isAutoGeneratedDescription(String description) {
    // نتحقق من بداية القالب - جميع القوالب تبدأ بـ "أقدم خدمة"
    return description.startsWith('أقدم خدمة');
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
      isSpecialOffer: _isSpecialOffer,
      oldEstimatedValue:
          _isSpecialOffer ? double.tryParse(_oldValueController.text) : null,
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
              // ═══════════════════════════════════════════════════════════
              // 1️⃣ عنوان الخدمة (الأول)
              // ═══════════════════════════════════════════════════════════
              _buildSectionTitle('عنوان الخدمة', Icons.title),
              const SizedBox(height: 4),
              Text(
                'اكتب عنواناً واضحاً وسيتم تحديد التصنيف تلقائياً',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textAlign: TextAlign.right,
                decoration:
                    _inputDecoration('مثال: تدريس لغة إنجليزية للمبتدئين'),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال عنوان الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // 2️⃣ التصنيف (الثاني - تلقائي)
              // ═══════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شارة الاختيار التلقائي
                  if (_isCategoryAutoDetected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تم الاختيار تلقائياً',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.auto_awesome,
                              size: 14, color: Colors.green.shade700),
                        ],
                      ),
                    )
                  else if (_canEditCategory)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'اختر التصنيف يدوياً',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit,
                              size: 14, color: Colors.orange.shade700),
                        ],
                      ),
                    ),
                  _buildSectionTitle('التصنيف', Icons.category),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _isCategoryAutoDetected
                      ? Colors.grey.shade100
                      : Colors.white,
                  border: Border.all(
                    color: _isCategoryAutoDetected
                        ? ServiceCategory.getColor(_selectedCategory)
                            .withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                    width: _isCategoryAutoDetected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: Icon(
                      _isCategoryAutoDetected
                          ? Icons.lock
                          : Icons.keyboard_arrow_down,
                      color: _isCategoryAutoDetected ? Colors.grey : null,
                    ),
                    // تعطيل التفاعل إذا تم الاختيار التلقائي
                    onChanged: _isCategoryAutoDetected
                        ? null
                        : (value) {
                            setState(() => _selectedCategory = value!);
                            // تحديث الوصف عند تغيير الفئة يدوياً
                            if (_descriptionController.text.isEmpty ||
                                _isAutoGeneratedDescription(
                                    _descriptionController.text)) {
                              _descriptionController.text =
                                  _generateSuggestedDescription();
                            }
                          },
                    items: ServiceCategory.categories
                        .where((c) => c != 'الكل')
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: _isCategoryAutoDetected &&
                                              category == _selectedCategory
                                          ? ServiceCategory.getColor(category)
                                          : null,
                                      fontWeight: category == _selectedCategory
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
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
              // 3️⃣ وصف الخدمة (الثالث - مقترح)
              // ═══════════════════════════════════════════════════════════
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // زر إعادة توليد الوصف
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _descriptionController.text =
                            _generateSuggestedDescription();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('اقتراح جديد',
                        style: TextStyle(fontSize: 12)),
                  ),
                  _buildSectionTitle('وصف الخدمة', Icons.description),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'يمكنك تعديل الوصف المقترح أو كتابة وصف خاص بك',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                textAlign: TextAlign.right,
                maxLines: 5,
                decoration: _inputDecoration('وصف تفصيلي لخدمتك...').copyWith(
                  filled: true,
                  fillColor: Colors.blue.shade50.withValues(alpha: 0.3),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'يرجى إدخال وصف الخدمة' : null,
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // 4️⃣ القيمة التقديرية
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
              // 5️⃣ مدة التنفيذ
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
              // 6️⃣ معرض الأعمال
              // ═══════════════════════════════════════════════════════════
              _buildPortfolioSection(),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // 7️⃣ الباقات
              // ═══════════════════════════════════════════════════════════
              _buildPackagesSection(),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // 8️⃣ الخدمات المفضلة للتبادل
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
              // زر الإضافة
              // ═══════════════════════════════════════════════════════════
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitService,
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
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _isLoading ? 'جاري الإضافة...' : 'إضافة الخدمة',
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

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر رفع صورة من الجهاز
            TextButton.icon(
              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload, size: 18),
              label: Text(_isUploadingImage ? 'جاري الرفع...' : 'رفع صورة'),
            ),
            // زر إضافة رابط
            TextButton.icon(
              onPressed: _addPortfolioUrl,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('رابط'),
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

  /// اختيار صورة من الجهاز ورفعها إلى imgbb
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final imageUrl = await ImgBBService.uploadImage(File(pickedFile.path));
      if (imageUrl != null) {
        setState(() {
          _portfolioUrls.add(imageUrl);
        });
        Get.snackbar(
          'نجاح',
          'تم رفع الصورة بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في رفع الصورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
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
