import 'package:flutter/material.dart';

import 'package:redsea/product_model.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/swap_controller.dart';
import 'package:redsea/app/bindings/swap_binding.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/add_product_page.dart';

// الصفحة الأولى: اختيار منتج للمقايضة
class SwapSelectionPage extends StatefulWidget {
  final Product targetProduct;

  const SwapSelectionPage({super.key, required this.targetProduct});

  @override
  State<SwapSelectionPage> createState() => _SwapSelectionPageState();
}

class _SwapSelectionPageState extends State<SwapSelectionPage> {
  Product? _selectedProduct;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  List<Product> _userProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadUserProducts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ref = FirebaseDatabase.instance.ref().child('products');
    try {
      // استخدام sellerId كما هو مخزن في صفحة الإضافة
      final snapshot =
          await ref.orderByChild('sellerId').equalTo(userId).once();

      List<Product> loadedProducts = [];
      if (snapshot.snapshot.value != null) {
        // التعامل مع البيانات سواء كانت Map أو List
        dynamic data = snapshot.snapshot.value;
        if (data is Map) {
          data.forEach((key, value) {
            try {
              Product p = Product.fromMap(Map<dynamic, dynamic>.from(value));
              // تصفية المنتجات: يجب أن تكون قابلة للمقايضة وليست المنتج المستهدف
              if (p.id != widget.targetProduct.id && p.isSwappable) {
                loadedProducts.add(p);
              }
            } catch (e) {
              debugPrint("Error parsing product: $e");
            }
          });
        }
      }

      // محاولة البحث بـ userId للمنتجات القديمة أو الوهمية
      if (loadedProducts.isEmpty) {
        final snapshotUserId =
            await ref.orderByChild('userId').equalTo(userId).once();
        if (snapshotUserId.snapshot.value != null) {
          dynamic data = snapshotUserId.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              try {
                Product p = Product.fromMap(Map<dynamic, dynamic>.from(value));
                // التأكد من عدم التكرار
                if (p.id != widget.targetProduct.id &&
                    p.isSwappable &&
                    !loadedProducts.any((lp) => lp.id == p.id)) {
                  loadedProducts.add(p);
                }
              } catch (e) {
                debugPrint("Error parsing product (userId): $e");
              }
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _userProducts = loadedProducts;
          _filteredProducts = loadedProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user products: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _userProducts.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addNewProduct() async {
    await Get.to(() => const AddProductPage());
    _loadUserProducts();
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
          'طلب مقايضة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _addNewProduct,
            tooltip: 'إضافة منتج جديد',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // بطاقة المنتج المستهدف
              _buildTargetProductCard(),
              const SizedBox(height: 20),

              // شريط البحث
              _buildSearchBar(),
              const SizedBox(height: 16),

              // عنوان قسم المنتجات
              _buildProductsHeader(),
              const SizedBox(height: 16),

              // قائمة منتجات المستخدم
              Expanded(
                child: _buildProductsList(),
              ),

              // زر المتابعة
              if (_selectedProduct != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildContinueButton(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetProductCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // صورة المنتج المستهدف
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: widget.targetProduct.imageUrl.isNotEmpty
                    ? NetworkImage(widget.targetProduct.imageUrl)
                    : const AssetImage('assets/placeholder.png')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'أنت تطلب المقايضة بمنتج:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.targetProduct.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.targetProduct.price} ريال',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'ابحث في منتجاتك...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredProducts.length} منتج',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Text(
          'اختر منتجاً من منتجاتك للمقايضة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد منتجات لديك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'يجب أن يكون لديك منتج واحد على الأقل للمقايضة'
                    : 'لم يتم العثور على منتج مطابق للبحث',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // زر إضافة منتج
              if (_searchController.text.isEmpty)
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _addNewProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج جديد'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductItem(_filteredProducts[index]);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    final isSelected = _selectedProduct?.id == product.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProduct = isSelected ? null : product;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة المنتج
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: product.imageUrl.isNotEmpty
                      ? NetworkImage(product.imageUrl)
                      : const AssetImage('assets/placeholder.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price} ريال',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Get.to(
            () => SwapConfirmationPage(
              targetProduct: widget.targetProduct,
              userProduct: _selectedProduct!,
            ),
            binding: SwapBinding(),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_left, size: 20),
            SizedBox(width: 8),
            Text(
              'المتابعة لتأكيد المقايضة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحة تأكيد المقايضة المطورة
class SwapConfirmationPage extends StatefulWidget {
  final Product targetProduct;
  final Product userProduct;

  const SwapConfirmationPage({
    super.key,
    required this.targetProduct,
    required this.userProduct,
  });

  @override
  State<SwapConfirmationPage> createState() => _SwapConfirmationPageState();
}

class _SwapConfirmationPageState extends State<SwapConfirmationPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  void _sendSwapRequest() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final swapController = Get.find<SwapController>();

      final success = await swapController.sendSwapRequest(
        targetProduct: widget.targetProduct,
        offeredProduct: widget.userProduct,
        message: _messageController.text.trim(),
        additionalMoney: 0,
      );

      if (success && mounted) {
        // العودة للصفحة الرئيسية بعد النجاح
        Get.offNamedUntil(AppRoutes.swapRequests, (route) => route.isFirst,
            arguments: {'initialTabIndex': 1});
      } else {
        setState(() => _isSending = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
        setState(() => _isSending = false);
      }
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
          'تأكيد المقايضة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // تفاصيل المقايضة
              _buildSwapDetails(),
              const SizedBox(height: 24),

              // رسالة إضافية
              _buildMessageField(),
              const SizedBox(height: 24),

              // ملاحظات
              _buildNotes(),
              const SizedBox(height: 32),

              // زر إرسال الطلب
              _buildSendButton(),
              const SizedBox(height: 20), // مساحة إضافية في الأسفل
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwapDetails() {
    return Column(
      children: [
        // المنتج المستهدف
        _buildProductCard('المنتج الذي تريده', widget.targetProduct,
            AppColors.primary.withValues(alpha: 0.1)),
        const SizedBox(height: 16),

        // السهم بين المنتجين
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.swap_vert, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // المنتج المعروض
        _buildProductCard(
            'منتجك المعروض', widget.userProduct, Colors.orange.shade50),
      ],
    );
  }

  Widget _buildProductCard(
      String title, Product product, Color backgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              // صورة المنتج
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: product.imageUrl.isNotEmpty
                        ? NetworkImage(product.imageUrl)
                        : const AssetImage('assets/placeholder.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.negotiable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'قابل للتفاوض',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        Text(
                          '${product.price} ريال',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'رسالة إضافية (اختياري)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'اكتب رسالة لصاحب المنتج...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'ملاحظات هامة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• سيتم إرسال طلب المقايضة لصاحب المنتج للموافقة عليه\n• يمكنك متابعة حالة الطلب من صفحة الطلبات\n• يرجى التحقق من معلومات المنتج قبل الإرسال',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendSwapRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSending
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'إرسال طلب المقايضة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}

// Bottom Sheet لإضافة منتج جديد
class AddProductBottomSheet extends StatefulWidget {
  final Function(Product) onProductAdded;

  const AddProductBottomSheet({super.key, required this.onProductAdded});

  @override
  State<AddProductBottomSheet> createState() => _AddProductBottomSheetState();
}

class _AddProductBottomSheetState extends State<AddProductBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool _negotiable = true;

  void _addProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        price: _priceController.text,
        negotiable: _negotiable,
        description: _descriptionController.text,
        category: _categoryController.text,
        imageUrl: 'https://via.placeholder.com/200x200?text=منتج+جديد',
        dateAdded: DateTime.now(),
      );

      widget.onProductAdded(newProduct);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المنتج بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'إضافة منتج جديد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال اسم المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر (ريال)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال سعر المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال فئة المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف المنتج',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال وصف المنتج';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('قابل للتفاوض'),
                      const Spacer(),
                      Switch(
                        value: _negotiable,
                        onChanged: (value) {
                          setState(() {
                            _negotiable = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('إضافة المنتج'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
