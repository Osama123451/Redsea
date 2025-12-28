import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/orders_controller.dart';
import 'package:redsea/product_model.dart';

/// صفحة اختيار طريقة الدفع وإتمام الطلب
class PaymentMethodPage extends StatefulWidget {
  final List<Product> cartItems;

  const PaymentMethodPage({super.key, required this.cartItems});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedPaymentMethod = 'cash';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cash',
      'name': 'الدفع عند الاستلام',
      'icon': Icons.money,
      'description': 'ادفع نقداً عند استلام الطلب',
    },
    {
      'id': 'bank_transfer',
      'name': 'تحويل بنكي',
      'icon': Icons.account_balance,
      'description': 'تحويل للحساب البنكي',
    },
    {
      'id': 'card',
      'name': 'بطاقة ائتمان',
      'icon': Icons.credit_card,
      'description': 'الدفع ببطاقة فيزا أو ماستركارد',
    },
  ];

  double get _totalPrice {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ملخص الطلب
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // طرق الدفع
            _buildSectionTitle('طريقة الدفع'),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
            const SizedBox(height: 24),

            // عنوان التوصيل
            _buildSectionTitle('عنوان التوصيل'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              hintText: 'أدخل عنوان التوصيل',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // ملاحظات إضافية
            _buildSectionTitle('ملاحظات إضافية (اختياري)'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              hintText: 'أضف أي ملاحظات للبائع',
              icon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 100), // مساحة للزر السفلي
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الطلب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...widget.cartItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(2)} ريال',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع الكلي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_totalPrice.toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    bool isSelected = _selectedPaymentMethod == method['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  method['icon'],
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'تأكيد الطلب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    if (_addressController.text.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال عنوان التوصيل',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // تحويل المنتجات لصيغة مناسبة للطلب
      final List<Map<String, dynamic>> orderItems = widget.cartItems
          .map((item) => {
                'productId': item.id,
                'name': item.name,
                'price': double.tryParse(item.price) ?? 0,
                'quantity': item.quantity,
                'totalPrice': item.totalPrice,
              })
          .toList();

      // إنشاء الطلب
      final ordersController = Get.find<OrdersController>();
      final orderId = await ordersController.createOrder(
        items: orderItems,
        totalPrice: _totalPrice,
        paymentMethod: _selectedPaymentMethod,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (orderId != null) {
        // مسح السلة بعد الطلب الناجح
        final cartController = Get.find<CartController>();
        await cartController.clearCart();

        // عرض رسالة نجاح
        Get.offNamedUntil('/home', (route) => false);
        Get.snackbar(
          'تم بنجاح! ✅',
          'تم إنشاء طلبك بنجاح. رقم الطلب: $orderId',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'حدث خطأ أثناء إنشاء الطلب. يرجى المحاولة مرة أخرى.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
