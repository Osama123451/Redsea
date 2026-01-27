import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/core/category_schemas.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/product_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/edit_product_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final List<Product> cartItems;
  final Function(Product)? onAddToCart;
  final Function(String)? onRemoveFromCart;
  final Function(String, int)? onUpdateQuantity;
  final bool isViewOnly;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.cartItems = const [],
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onUpdateQuantity,
    this.isViewOnly = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // Controllers
  final FavoritesController _favoritesController =
      Get.find<FavoritesController>();
  final PageController _imagePageController = PageController();

  // State
  int _currentImageIndex = 0;
  bool _isInCart = false;
  int _currentQuantity = 0;
  String _sellerName = 'البائع';
  bool _isLoadingSellerName = true;
  double _sellerRating = 0.0;
  DateTime? _sellerJoinDate;
  String _selectedCurrency = 'ر.ي';

  // التقييمات
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  int _totalViews = 0;
  bool _isLoadingReviews = true;
  bool _hasUserReviewed = false;
  bool _isApproving = false;
  late Product _currentProduct;
  StreamSubscription<DatabaseEvent>? _productSubscription;

  // صور المنتج (للتمرير)
  List<String> get _productImages {
    // استخدم قائمة الصور الجديدة إذا كانت موجودة، وإلا استخدم الصورة الرئيسية
    if (_currentProduct.images != null && _currentProduct.images!.isNotEmpty) {
      return _currentProduct.images!;
    }
    if (_currentProduct.imageUrl.isEmpty) return [];
    return [_currentProduct.imageUrl];
  }

  // هل المستخدم هو صاحب المنتج؟
  bool get _isProductOwner =>
      _currentProduct.ownerId == FirebaseAuth.instance.currentUser?.uid;

  // المنتجات المقبولة للمقايضة
  List<String> get _acceptedBarterItems => [];

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _startProductListener();
    _updateCartStatus();
    _loadSellerName();
    _loadReviews();
    _incrementViewCount();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _productSubscription?.cancel();
    super.dispose();
  }

  void _startProductListener() {
    _productSubscription = FirebaseDatabase.instance
        .ref('products/${widget.product.id}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _currentProduct =
                Product.fromMap({...data, 'id': widget.product.id});
          });
        }
      }
    });
  }

  // زيادة عداد المشاهدات
  Future<void> _incrementViewCount() async {
    if (_isProductOwner) return;
    try {
      await FirebaseDatabase.instance
          .ref('products/${widget.product.id}/viewsCount')
          .set(ServerValue.increment(1));
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // جلب معلومات البائع
  Future<void> _loadSellerName() async {
    if (widget.product.ownerId != null) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/${widget.product.ownerId}')
            .get();

        if (snapshot.exists && mounted) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _sellerName = data['name'] ?? 'مستخدم';
            _sellerRating = (data['rating'] ?? 0.0).toDouble();
            if (data['createdAt'] != null) {
              _sellerJoinDate =
                  DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
            }
            _isLoadingSellerName = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading seller details: $e');
        if (mounted) setState(() => _isLoadingSellerName = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingSellerName = false);
    }
  }

  // جلب التقييمات
  Future<void> _loadReviews() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('reviews/${widget.product.id}')
          .get();

      final viewsSnapshot = await FirebaseDatabase.instance
          .ref('products/${widget.product.id}/viewsCount')
          .get();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (mounted) {
        if (snapshot.exists) {
          final reviewsMap = Map<String, dynamic>.from(snapshot.value as Map);
          List<Map<String, dynamic>> loadedReviews = [];
          double totalRating = 0;
          bool userHasReviewed = false;

          for (var entry in reviewsMap.entries) {
            final review = Map<String, dynamic>.from(entry.value);
            review['odUserId'] = entry.key;
            loadedReviews.add(review);
            totalRating += (review['rating'] ?? 0).toDouble();
            if (entry.key == currentUserId) userHasReviewed = true;
          }

          setState(() {
            _reviews = loadedReviews;
            _averageRating = loadedReviews.isNotEmpty
                ? totalRating / loadedReviews.length
                : 0;
            _hasUserReviewed = userHasReviewed;
            _isLoadingReviews = false;
          });
        } else {
          setState(() => _isLoadingReviews = false);
        }

        if (viewsSnapshot.exists) {
          setState(() => _totalViews = (viewsSnapshot.value as int?) ?? 0);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  void _updateCartStatus() {
    if (widget.cartItems.any((item) => item.id == widget.product.id)) {
      Product cartProduct = widget.cartItems.firstWhere(
        (item) => item.id == widget.product.id,
      );
      setState(() {
        _isInCart = true;
        _currentQuantity = cartProduct.quantity;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Image Slider مع AppBar شفاف
                _buildImageSliver(),

                // بنر انتظار الموافقة
                if (!_currentProduct.isApproved)
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty,
                              color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'بانتظار موافقة المشرف',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'هذا المنتج لن يظهر للعامة حتى تتم مراجعته واعتماده.',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // المحتوى
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // أزرار الإدارة (للمشرفين فقط)
                      _buildAdminApprovalActions(),

                      // قسم السعر والبيانات الأساسية
                      _buildPriceSection(),

                      // جدول المواصفات
                      _buildSpecificationsSection(),

                      // الوصف
                      _buildDescriptionSection(),

                      // الموقع
                      _buildLocationSection(),

                      // معلومات البائع
                      _buildSellerSection(),

                      // إعلانات مشابهة
                      _buildSimilarProductsSection(),

                      // مساحة للـ Bottom Bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),

            // Fixed Bottom Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFixedBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. Image Slider مع AppBar شفاف
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildImageSliver() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: _buildCircleButton(
        icon: Icons.arrow_forward,
        onTap: () => Get.back(),
      ),
      actions: [
        _buildCircleButton(
          icon: Icons.share,
          onTap: _shareProduct,
        ),
        const SizedBox(width: 8),
        Obx(() => _buildCircleButton(
              icon: _favoritesController.isFavorite(_currentProduct.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _favoritesController.isFavorite(_currentProduct.id)
                  ? Colors.red
                  : Colors.white,
              onTap: () => _favoritesController.toggleFavorite(_currentProduct),
            )),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // صور المنتج
            if (_productImages.isNotEmpty)
              PageView.builder(
                controller: _imagePageController,
                itemCount: _productImages.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: _productImages[index],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 60),
                    ),
                  );
                },
              )
            else
              Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              ),

            // مؤشر الصفحات (Dots)
            if (_productImages.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _productImages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        boxShadow: [
                          if (_currentImageIndex == index)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // شارات (مقايضة / عرض خاص)
            Positioned(
              top: 100,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_currentProduct.isSwappable)
                    _buildBadge('مقايضة', Icons.swap_horiz, Colors.green),
                  if (_currentProduct.isSpecialOffer) ...[
                    const SizedBox(height: 8),
                    _buildBadge('عرض خاص', Icons.local_offer, Colors.orange),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. قسم السعر والبيانات الأساسية
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // السعر مع تبديل العملة
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _formatPrice(_currentProduct.price),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر تبديل العملة
                    GestureDetector(
                      onTap: _toggleCurrency,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryExtraLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedCurrency,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // السعر القديم (إذا كان عرض خاص)
              if (_currentProduct.isSpecialOffer &&
                  _currentProduct.oldPrice != null)
                Text(
                  '${_currentProduct.oldPrice} $_selectedCurrency',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // عنوان المنتج
          Text(
            _currentProduct.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // الموقع والتاريخ
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _currentProduct.location ?? 'اليمن',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDate(_currentProduct.dateAdded),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // التقييم والمشاهدات
          Row(
            children: [
              // النجوم
              // النجوم
              _buildRatingStars(_averageRating, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_averageRating.toStringAsFixed(1)} (${_reviews.length})',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '$_totalViews مشاهدة',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(String price) {
    if (_selectedCurrency == '\$') {
      // تحويل تقريبي
      double? priceNum =
          double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (priceNum != null) {
        return (priceNum / 540).toStringAsFixed(2);
      }
    }
    return price;
  }

  void _toggleCurrency() {
    setState(() {
      _selectedCurrency = _selectedCurrency == 'ر.ي' ? '\$' : 'ر.ي';
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
    return 'منذ ${(diff.inDays / 30).floor()} أشهر';
  }

  String _formatJoinDate(DateTime date) {
    return '${date.year}/${date.month}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. معلومات البائع
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSellerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // صورة البائع
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              _sellerName.isNotEmpty ? _sellerName[0].toUpperCase() : 'B',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // اسم البائع
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingSellerName ? 'جاري التحميل...' : _sellerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // تقييم المستخدم
                if (!_isLoadingSellerName)
                  Row(
                    children: [
                      _buildRatingStars(_sellerRating, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _sellerRating > 0
                            ? _sellerRating.toStringAsFixed(1)
                            : '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          color: Colors.grey, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _sellerJoinDate != null
                            ? 'عضو منذ ${_formatJoinDate(_sellerJoinDate!)}'
                            : 'عضو جديد',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(
                  'عرض الملف الشخصي',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
          // أيقونة التوجه للملف
          Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. جدول المواصفات
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSpecificationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'المواصفات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Prepare the merged list of specifications
          Builder(builder: (context) {
            List<Map<String, String>> mergedSpecs = [];

            // A. Add Static Fields
            mergedSpecs
                .add({'label': 'الفئة', 'value': _currentProduct.category});
            mergedSpecs.add({'label': 'الحالة', 'value': _getConditionText()});

            if (_currentProduct.negotiable) {
              mergedSpecs.add({'label': 'السعر', 'value': 'قابل للمقايضة'});
            }

            mergedSpecs.add({
              'label': 'المقايضة',
              'value': _currentProduct.isSwappable ? 'متاح' : 'غير متاح'
            });

            // B. Add Dynamic Fields
            if (_currentProduct.specifications != null &&
                _currentProduct.specifications!.isNotEmpty) {
              final schema = categorySchemas[_currentProduct.category];

              _currentProduct.specifications!.forEach((key, value) {
                String label = key;
                if (schema != null && schema.containsKey(key)) {
                  label = schema[key]!['label'] ?? key;
                }

                String displayValue = value.toString();
                if (value is bool) {
                  displayValue = value ? 'نعم' : 'لا';
                }

                mergedSpecs.add({'label': label, 'value': displayValue});
              });
            }

            // 2. Render the merged list with Zebra Striping
            return Column(
              children: mergedSpecs.asMap().entries.map((entry) {
                final int index = entry.key;
                final Map<String, String> spec = entry.value;

                return _buildEnhancedSpecRow(
                  spec['label']!,
                  spec['value']!,
                  isColored: index % 2 == 0,
                );
              }).toList(),
            );
          }),

          // 3. Accepted Barter Items (Keep separate as it's a special box)
          if (widget.product.isSwappable &&
              _acceptedBarterItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'هذا المعلن يقبل المقايضة بـ:',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _acceptedBarterItems.map((item) {
                      return Chip(
                        label: Text(item, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.green.shade100,
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // أزرار الإدارة (للمشرفين فقط)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAdminApprovalActions() {
    final authController = Get.find<AuthController>();
    if (!authController.isAdmin || _currentProduct.isApproved) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'لوحة تحكم المشرف',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isApproving ? null : _approveProduct,
            icon: _isApproving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label:
                Text(_isApproving ? 'جاري الاعتماد...' : 'اعتماد ونشر المنتج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveProduct() async {
    setState(() => _isApproving = true);
    try {
      await FirebaseDatabase.instance
          .ref('products/${_currentProduct.id}')
          .update({'isApproved': true});

      Get.snackbar(
        'تم بنجاح',
        'تم اعتماد المنتج ونشره للعامة بنجاح ✅',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // العودة وتحديث البيانات
      Get.back();
      if (Get.isRegistered<ProductController>()) {
        Get.find<ProductController>().loadProducts();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في اعتماد المنتج: $e');
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  String _getConditionText() {
    switch (widget.product.condition) {
      case ProductCondition.newProduct:
        return 'جديد';
      case ProductCondition.usedGood:
        return 'مستعمل - حالة جيدة';
      case ProductCondition.usedFair:
        return 'مستعمل - حالة متوسطة';
      default:
        return 'غير محدد';
    }
  }

  Widget _buildEnhancedSpecRow(String label, String value,
      {bool isColored = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isColored ? const Color(0xFFF5F6FA) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Value (Left in design/Right in RTL structure)
          // Based on image: English text "Samsung" is on Left, Label "Brand" is on Right.
          // In RTL environment: Start is Right.
          // So Label should be Start (Right), Value should be End (Left).

          Expanded(
            flex: 2,
            child: Text(
              label,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. قسم الوصف
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'الوصف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.product.description.isNotEmpty
                  ? widget.product.description
                  : 'لا يوجد وصف متاح',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. قسم الموقع
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'الموقع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryExtraLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.location ?? 'اليمن',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'اضغط لعرض الخريطة',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7. إعلانات مشابهة
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSimilarProductsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.grid_view, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'إعلانات مشابهة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: GetBuilder<ProductController>(
              builder: (controller) {
                final similarProducts = controller.allProducts
                    .where((p) =>
                        p.category == widget.product.category &&
                        p.id != widget.product.id)
                    .take(5)
                    .toList();

                if (similarProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد منتجات مشابهة',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: similarProducts.length,
                  itemBuilder: (context, index) {
                    return _buildSimilarProductCard(similarProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Get.off(() => ProductDetailsPage(
              product: product,
              cartItems: widget.cartItems,
              onAddToCart: widget.onAddToCart,
              onRemoveFromCart: widget.onRemoveFromCart,
              onUpdateQuantity: widget.onUpdateQuantity,
            ));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price} ر.ي',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8. Fixed Bottom Bar
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFixedBottomBar() {
    // إذا كان صاحب المنتج
    if (_isProductOwner) {
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
          child: Row(
            children: [
              // زر الحذف (أحمر صغير)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _deleteProduct,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'حذف',
                ),
              ),
              const SizedBox(width: 8),
              // زر التعديل (أساسي)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => EditProductPage(product: _currentProduct));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('تعديل', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 8),
              // زر الترويج (برتقالي مميز)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      _currentProduct.isApproved ? _promoteProduct : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentProduct.isApproved
                        ? Colors.amber.shade700
                        : Colors.grey.shade300,
                    foregroundColor: _currentProduct.isApproved
                        ? Colors.white
                        : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.bolt,
                      size: 20,
                      color: _currentProduct.isApproved
                          ? Colors.white
                          : Colors.grey.shade500),
                  label: Text(
                      _currentProduct.isApproved ? 'ترويج' : 'بانتظار الموافقة',
                      style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        child: widget.isViewOnly
            ? _buildViewOnlyLayout()
            : widget.product.isSwappable
                ? _buildTripleButtonLayout()
                : _buildDualButtonLayout(),
      ),
    );
  }

  /// تخطيط "للعرض فقط" (يخفي أزرار المقايضة والشراء)
  Widget _buildViewOnlyLayout() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('دردشة مع البائع', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  /// تخطيط الأزرار الثلاثي (للمنتجات القابلة للمقايضة)
  Widget _buildTripleButtonLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الصف العلوي: زر الدردشة عريض
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label:
                const Text('دردشة مع البائع', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        // الصف السفلي: زرين متجاورين
        Row(
          children: [
            // طلب مقايضة (برتقالي)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _requestBarter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('طلب مقايضة', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            // شراء المنتج (أزرق غامق)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _buyProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_cart),
                label:
                    const Text('شراء المنتج', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// تخطيط الأزرار الثنائي (للمنتجات غير القابلة للمقايضة)
  Widget _buildDualButtonLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الصف العلوي: زر الدردشة عريض
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label:
                const Text('دردشة مع البائع', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        // الصف السفلي: زر الشراء فقط
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _buyProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('شراء المنتج', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  void _buyProduct() {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لشراء المنتج')) return;

    // إضافة للسلة والانتقال لصفحة السلة
    if (widget.onAddToCart != null) {
      widget.onAddToCart!(widget.product.copyWith(quantity: 1));
    }

    Get.snackbar(
      'تمت الإضافة',
      'تم إضافة المنتج للسلة',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );

    // الانتقال لصفحة السلة
    Get.toNamed('/basket');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helper: بناء نجوم التقييم
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRatingStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        }
        return Icon(Icons.star_border, color: Colors.amber, size: size);
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الوظائف المساعدة
  // ══════════════════════════════════════════════════════════════════════════
  void _shareProduct() {
    final text =
        'تفقد هذا المنتج: ${widget.product.name}\nالسعر: ${widget.product.price} ر.ي\n\nعبر تطبيق RedSea';
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ رابط المنتج للمشاركة',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void _startChat() async {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك للدردشة')) return;

    final sellerId = widget.product.ownerId ?? '';
    if (sellerId.isEmpty) {
      Get.snackbar('تنبيه', 'لا يمكن بدء المحادثة');
      return;
    }

    try {
      final chatId =
          await ChatService().createOrGetChat(sellerId, widget.product.id);
      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: sellerId,
            otherUserName: _sellerName,
          ));
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في بدء المحادثة');
    }
  }

  void _callSeller() {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك للاتصال')) return;

    Get.snackbar(
      'قريباً',
      'ستتوفر خاصية الاتصال قريباً',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void _requestBarter() {
    final auth = Get.find<AuthController>();
    if (!auth.requireLogin(message: 'سجّل دخولك لطلب المقايضة')) return;

    Get.toNamed(
      AppRoutes.swapSelection,
      arguments: {'targetProduct': widget.product},
    );
  }

  Future<void> _deleteProduct() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المنتج؟'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseDatabase.instance
            .ref('products/${widget.product.id}')
            .remove();
        Get.back();
        Get.snackbar('تم', 'تم حذف المنتج بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar('خطأ', 'فشل حذف المنتج',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void _promoteProduct() {
    Get.toNamed(AppRoutes.promoteProduct, arguments: _currentProduct);
  }
}
