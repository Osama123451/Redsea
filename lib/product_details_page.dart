import 'package:flutter/material.dart';

import 'package:redsea/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/routes/app_routes.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final List<Product> cartItems;
  final Function(Product)? onAddToCart;
  final Function(String)? onRemoveFromCart;
  final Function(String, int)? onUpdateQuantity;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.cartItems = const [],
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onUpdateQuantity,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isInCart = false;
  int _currentQuantity = 0;
  final FavoritesController favoritesController =
      Get.find<FavoritesController>();

  // متغيرات التقييم
  double _userRating = 0;
  double _averageRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  // قائمة التقييمات
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  // اسم البائع
  String _sellerName = 'البائع';
  bool _isLoadingSellerName = true;

  // هل المستخدم هو صاحب المنتج؟
  bool get _isProductOwner =>
      widget.product.ownerId == FirebaseAuth.instance.currentUser?.uid;

  // هل المستخدم قام بالتقييم مسبقاً؟
  bool _hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    _updateCartStatus();
    _loadSellerName();
    _loadReviews();
  }

  // جلب اسم البائع
  Future<void> _loadSellerName() async {
    if (widget.product.ownerId != null) {
      final name = await ChatService().getUserName(widget.product.ownerId!);
      if (mounted) {
        setState(() {
          _sellerName = name;
          _isLoadingSellerName = false;
        });
      }
    } else {
      setState(() {
        _isLoadingSellerName = false;
      });
    }
  }

  // جلب التقييمات من Firebase
  Future<void> _loadReviews() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final snapshot =
          await dbRef.child('reviews').child(widget.product.id).once();

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (snapshot.snapshot.value != null && mounted) {
        final reviewsMap =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<Map<String, dynamic>> loadedReviews = [];
        double totalRating = 0;
        bool userHasReviewed = false;

        for (var entry in reviewsMap.entries) {
          final review = Map<String, dynamic>.from(entry.value);
          review['odUserId'] = entry.key;
          loadedReviews.add(review);
          totalRating += (review['rating'] ?? 0).toDouble();

          // التحقق إذا المستخدم الحالي قام بالتقييم
          if (entry.key == currentUserId) {
            userHasReviewed = true;
          }
        }

        setState(() {
          _reviews = loadedReviews;
          _averageRating =
              loadedReviews.isNotEmpty ? totalRating / loadedReviews.length : 0;
          _isLoadingReviews = false;
          _hasUserReviewed = userHasReviewed;
        });
      } else {
        setState(() {
          _isLoadingReviews = false;
          _hasUserReviewed = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _updateCartStatus() {
    if (widget.cartItems.any((item) => item.id == widget.product.id)) {
      Product cartProduct =
          widget.cartItems.firstWhere((item) => item.id == widget.product.id);
      setState(() {
        _isInCart = true;
        _currentQuantity = cartProduct.quantity;
      });
    } else {
      setState(() {
        _isInCart = false;
        _currentQuantity = 0;
      });
    }
  }

  void _addToCart() {
    setState(() {
      _isInCart = true;
      _currentQuantity = 1;
    });

    if (widget.onAddToCart != null) {
      widget.onAddToCart!(widget.product.copyWith(quantity: 1));
    }

    Navigator.pop(context,
        {'action': 'add', 'product': widget.product.copyWith(quantity: 1)});
  }

  void _removeFromCart() {
    setState(() {
      _isInCart = false;
      _currentQuantity = 0;
    });

    if (widget.onRemoveFromCart != null) {
      widget.onRemoveFromCart!(widget.product.id);
    }

    Navigator.pop(
        context, {'action': 'remove', 'productId': widget.product.id});
  }

  void _updateQuantity(int quantity) {
    setState(() {
      _currentQuantity = quantity;
    });

    if (widget.onUpdateQuantity != null) {
      widget.onUpdateQuantity!(widget.product.id, quantity);
    }

    Navigator.pop(context, {
      'action': 'update',
      'productId': widget.product.id,
      'quantity': quantity
    });
  }

  // عرض نافذة التقييم
  void _showRatingDialog() {
    // التحقق إذا المستخدم قيّم مسبقاً
    if (_hasUserReviewed) {
      Get.snackbar(
        'تنبيه',
        'لقد قمت بتقييم هذا المنتج مسبقاً. يمكنك تقييم كل منتج مرة واحدة فقط.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    double tempRating = _userRating;
    _reviewController.clear();

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('تقييم المنتج', textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('اختر تقييمك للمنتج'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempRating = index + 1.0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < tempRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tempRating > 0
                        ? '${tempRating.toInt()} نجوم'
                        : 'لم يتم التقييم',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقك (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    maxLines: 2,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tempRating > 0) {
                    await _submitRating(tempRating, _reviewController.text);
                    setState(() {
                      _userRating = tempRating;
                    });
                    _loadReviews(); // تحديث التقييمات
                    Get.back();
                    Get.snackbar(
                      'شكراً لك!',
                      'تم إضافة تقييمك بنجاح ⭐',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar(
                      'تنبيه',
                      'يرجى اختيار تقييم',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إرسال'),
              ),
            ],
          );
        },
      ),
    );
  }

  // حذف المنتج
  Future<void> _deleteProduct() async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('products').child(widget.product.id).remove();

      Get.snackbar(
        'تم الحذف',
        'تم حذف المنتج بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // العودة للصفحة السابقة
      Get.back();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل حذف المنتج: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // حذف التقييم
  Future<void> _deleteReview(String reviewUserId) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef
          .child('reviews')
          .child(widget.product.id)
          .child(reviewUserId)
          .remove();

      _loadReviews(); // تحديث القائمة
      Get.snackbar(
        'نجاح',
        'تم حذف التقييم بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل حذف التقييم: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // إرسال التقييم إلى Firebase
  Future<void> _submitRating(double rating, String comment) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      debugPrint('📝 جاري إرسال التقييم...');

      // جلب اسم المستخدم
      String userName = 'مستخدم';
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(userId)
            .get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          userName = userData['name'] ?? userData['firstName'] ?? 'مستخدم';
        }
      } catch (e) {
        debugPrint('Error getting user name: $e');
      }

      final dbRef = FirebaseDatabase.instance.ref();
      await dbRef.child('reviews').child(widget.product.id).child(userId).set({
        'rating': rating,
        'comment': comment,
        'userId': userId,
        'userName': userName,
        'productId': widget.product.id,
        'createdAt': ServerValue.timestamp,
      });

      debugPrint('✅ تم إرسال التقييم بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال التقييم: $e');
      Get.snackbar(
        'خطأ في الحفظ',
        'تأكد من تحديث قواعد Firebase Database: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // عرض نافذة التقييمات
  void _showReviewsDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.reviews, color: Colors.blue),
            const SizedBox(width: 8),
            Text('التقييمات (${_reviews.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('لا توجد تقييمات بعد'),
                      Text('كن أول من يقيّم هذا المنتج!',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _reviews.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final rating = (review['rating'] ?? 0).toDouble();
                    final comment = review['comment'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // اسم المستخدم
                          Text(
                            review['userName'] ?? 'مستخدم',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زر الحذف (للأدمن أو صاحب التعليق)
                              if (Get.find<AuthController>().isAdmin ||
                                  review['odUserId'] ==
                                      FirebaseAuth.instance.currentUser?.uid)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () {
                                    Get.defaultDialog(
                                      title: 'حذف التقييم',
                                      middleText:
                                          'هل أنت متأكد من حذف هذا التقييم؟',
                                      textConfirm: 'حذف',
                                      textCancel: 'إلغاء',
                                      confirmTextColor: Colors.white,
                                      buttonColor: Colors.red,
                                      onConfirm: () async {
                                        Get.back(); // إغلاق الديالوج
                                        await _deleteReview(review['odUserId']);
                                      },
                                    );
                                  },
                                )
                              else
                                const SizedBox(),

                              // النجوم والتقييم
                              Row(
                                children: [
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(5, (i) {
                                    if (i < rating.floor()) {
                                      return const Icon(Icons.star,
                                          color: Colors.amber, size: 16);
                                    } else if (i < rating) {
                                      return const Icon(Icons.star_half,
                                          color: Colors.amber, size: 16);
                                    } else {
                                      return const Icon(Icons.star_border,
                                          color: Colors.amber, size: 16);
                                    }
                                  }),
                                ],
                              ),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              comment,
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // واجهة أزرار التحكم في الكمية
  Widget _buildQuantityControls() {
    // إذا كان صاحب المنتج - لا تظهر أزرار السلة
    if (_isProductOwner) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'هذا منتجك',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInCart) {
      return Row(
        children: [
          // زر المقايضة
          if (widget.product.isSwappable)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.swapSelection,
                      arguments: {'targetProduct': widget.product},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('طلب مقايضة'),
                ),
              ),
            ),

          // زر السلة
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('إضافة للسلة'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'الكمية في السلة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الناقص
              IconButton(
                onPressed: () {
                  if (_currentQuantity > 1) {
                    _updateQuantity(_currentQuantity - 1);
                  } else {
                    _removeFromCart();
                  }
                },
                icon: const Icon(Icons.remove, size: 20),
                color: Colors.red,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),

              // العدد
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_currentQuantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              // زر الزائد
              IconButton(
                onPressed: () {
                  _updateQuantity(_currentQuantity + 1);
                },
                icon: const Icon(Icons.add, size: 20),
                color: Colors.green,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _removeFromCart,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          icon: const Icon(Icons.remove_shopping_cart),
          label: const Text('إزالة من السلة'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.product.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        centerTitle: true,
        actions: [
          // زر الحذف (للمالك أو الأدمن)
          if (_isProductOwner || Get.find<AuthController>().isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Get.defaultDialog(
                  title: 'حذف المنتج',
                  middleText: 'هل أنت متأكد من أنك تريد حذف هذا المنتج؟',
                  textConfirm: 'حذف',
                  textCancel: 'إلغاء',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back(); // إغلاق النافذة
                    _deleteProduct();
                  },
                );
              },
            ),
          Obx(() => IconButton(
                icon: Icon(
                  favoritesController.isFavorite(widget.product.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: favoritesController.isFavorite(widget.product.id)
                      ? Colors.red
                      : Theme.of(context).iconTheme.color,
                ),
                onPressed: () =>
                    favoritesController.toggleFavorite(widget.product),
              )),
        ],
      ),
      body: Column(
        children: [
          // صورة المنتج
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              image: widget.product.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.product.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.product.imageUrl.isEmpty
                ? const Icon(Icons.image, size: 80, color: Colors.grey)
                : Stack(
                    children: [
                      if (widget.product.negotiable)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'قابل للمقايضة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // اسم المنتج
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 16),

                  // السعر
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.product.price} ريال',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'السعر:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // قابلية المقايضة
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.product.negotiable
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product.negotiable ? 'نعم' : 'لا',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.product.negotiable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const Text(
                          'قابل للمقايضة:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // التصنيف
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product.category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'التصنيف:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الوصف
                  const Text(
                    'الوصف:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.product.description.isEmpty
                          ? 'لا يوجد وصف للمنتج'
                          : widget.product.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // قسم التقييم
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                                _isLoadingReviews
                                    ? '...'
                                    : (_averageRating > 0
                                        ? _averageRating.toStringAsFixed(1)
                                        : 'جديد'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            ...List.generate(5, (index) {
                              double rating =
                                  _averageRating > 0 ? _averageRating : 0;
                              if (index < rating.floor()) {
                                return const Icon(Icons.star,
                                    color: Colors.amber, size: 20);
                              } else if (index < rating) {
                                return const Icon(Icons.star_half,
                                    color: Colors.amber, size: 20);
                              } else {
                                return const Icon(Icons.star_border,
                                    color: Colors.amber, size: 20);
                              }
                            }),
                            const Spacer(),
                            const Text(
                              'التقييم:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_reviews.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '(${_reviews.length} تقييم)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRatingDialog(),
                          icon: const Icon(Icons.star_rate,
                              color: Colors.amber, size: 18),
                          label: const Text('أضف تقييم'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReviewsDialog(),
                          icon: Icon(Icons.reviews,
                              color: Colors.blue.shade700, size: 18),
                          label: Text('التقييمات (${_reviews.length})'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // زر الدردشة مع البائع - يظهر دائماً إذا لم يكن المنتج للمستخدم الحالي
                  if (widget.product.ownerId == null ||
                      widget.product.ownerId !=
                          FirebaseAuth.instance.currentUser?.uid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // التحقق من تسجيل الدخول
                            if (FirebaseAuth.instance.currentUser == null) {
                              Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً',
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }

                            // التحقق من وجود معرف البائع
                            if (widget.product.ownerId == null ||
                                widget.product.ownerId!.isEmpty) {
                              Get.snackbar(
                                'غير متاح',
                                'هذا المنتج قديم ولا يمكن التواصل مع البائع',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            try {
                              String chatId = await ChatService()
                                  .createOrGetChat(widget.product.ownerId!,
                                      widget.product.id);

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                      chatId: chatId,
                                      otherUserId: widget.product.ownerId!,
                                      otherUserName: _isLoadingSellerName
                                          ? "البائع"
                                          : _sellerName,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('خطأ في فتح المحادثة: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble),
                          label: Text(
                              _isLoadingSellerName
                                  ? 'تواصل مع البائع'
                                  : 'تواصل مع $_sellerName',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // أزرار التحكم في الكمية
                  _buildQuantityControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
