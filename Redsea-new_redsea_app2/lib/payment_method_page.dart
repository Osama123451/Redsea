import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/orders_controller.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/services/imgbb_service.dart';

/// صفحة الدفع - تعرض معلومات حساب البائع ورفع الإيصال
class PaymentMethodPage extends StatefulWidget {
  final List<Product> cartItems;

  const PaymentMethodPage({super.key, required this.cartItems});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _transactionNumberController =
      TextEditingController();
  bool _isProcessing = false;
  bool _isUploadingReceipt = false;
  File? _receiptImage;
  String? _uploadedReceiptUrl;

  double get _totalPrice {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // الحصول على طريقة الدفع من المنتج الأول
  String get _paymentMethod {
    if (widget.cartItems.isEmpty) return 'cod';
    return widget.cartItems.first.paymentMethod ?? 'cod';
  }

  String? get _paymentAccountNumber {
    if (widget.cartItems.isEmpty) return null;
    return widget.cartItems.first.paymentAccountNumber;
  }

  String? get _paymentAccountName {
    if (widget.cartItems.isEmpty) return null;
    return widget.cartItems.first.paymentAccountName;
  }

  String? get _paymentInstructions {
    if (widget.cartItems.isEmpty) return null;
    return widget.cartItems.first.paymentInstructions;
  }

  bool get _isCashOnDelivery => _paymentMethod == 'cod';

  String get _paymentMethodName {
    switch (_paymentMethod) {
      case 'kuraimi':
        return 'الكريمي';
      case 'jawali':
        return 'محفظة جوالي';
      case 'cashu':
        return 'كاش يو';
      case 'bank':
        return 'تحويل بنكي';
      case 'other':
        return 'محفظة إلكترونية';
      case 'cod':
      default:
        return 'الدفع عند الاستلام';
    }
  }

  IconData get _paymentMethodIcon {
    switch (_paymentMethod) {
      case 'kuraimi':
        return Icons.account_balance_wallet;
      case 'jawali':
        return Icons.phone_android;
      case 'cashu':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'other':
        return Icons.wallet;
      case 'cod':
      default:
        return Icons.money;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _transactionNumberController.dispose();
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

            // معلومات الدفع
            if (_isCashOnDelivery)
              _buildCashOnDeliveryInfo()
            else
              _buildPaymentDetails(),
            const SizedBox(height: 24),

            // إثبات الدفع (إذا لم يكن الدفع عند الاستلام)
            if (!_isCashOnDelivery) ...[
              _buildPaymentProofSection(),
              const SizedBox(height: 24),
            ],

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
            const SizedBox(height: 100),
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
                        '${item.totalPrice.toStringAsFixed(2)} ر.ي',
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
                  '${_totalPrice.toStringAsFixed(2)} ر.ي',
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

  Widget _buildCashOnDeliveryInfo() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.money, size: 48, color: Colors.green.shade700),
            const SizedBox(height: 12),
            Text(
              'الدفع عند الاستلام',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم الدفع نقداً عند استلام الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(_paymentMethodIcon, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Text(
                  'معلومات الدفع - $_paymentMethodName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),

          // تفاصيل الحساب
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // رقم الحساب
                if (_paymentAccountNumber != null) ...[
                  _buildPaymentInfoRow(
                    label: 'رقم الحساب',
                    value: _paymentAccountNumber!,
                    canCopy: true,
                  ),
                  const Divider(height: 24),
                ],

                // اسم صاحب الحساب
                if (_paymentAccountName != null) ...[
                  _buildPaymentInfoRow(
                    label: 'اسم المستفيد',
                    value: _paymentAccountName!,
                    canCopy: false,
                  ),
                  const Divider(height: 24),
                ],

                // المبلغ المطلوب
                _buildPaymentInfoRow(
                  label: 'المبلغ المطلوب',
                  value: '${_totalPrice.toStringAsFixed(2)} ر.ي',
                  canCopy: true,
                  isAmount: true,
                ),

                // تعليمات البائع
                if (_paymentInstructions != null &&
                    _paymentInstructions!.isNotEmpty) ...[
                  const Divider(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'تعليمات البائع',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.info_outline,
                                size: 18, color: Colors.blue.shade700),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _paymentInstructions!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // تنبيه
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'قم بالدفع خارج التطبيق ثم عد لرفع إثبات الدفع',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoRow({
    required String label,
    required String value,
    required bool canCopy,
    bool isAmount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canCopy)
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar(
                'تم النسخ',
                'تم نسخ $label',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  const Text('نسخ', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          )
        else
          const SizedBox(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isAmount ? 18 : 16,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProofSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'إثبات الدفع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.receipt_long, color: Colors.blue.shade800),
              ],
            ),
            const Divider(height: 24),

            // رقم العملية
            TextField(
              controller: _transactionNumberController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'رقم العملية/الحوالة *',
                hintText: 'أدخل رقم العملية',
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // رفع صورة الإيصال
            const Text(
              'صورة الإيصال *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploadingReceipt ? null : _pickReceiptImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _uploadedReceiptUrl != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: _isUploadingReceipt
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
                    : _receiptImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _receiptImage!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_uploadedReceiptUrl != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
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
                              Icon(Icons.camera_alt,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'اضغط لرفع صورة الإيصال',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
              ),
            ),
            if (_uploadedReceiptUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'تم رفع الصورة بنجاح ✓',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _receiptImage = File(pickedFile.path);
          _uploadedReceiptUrl = null;
        });
        await _uploadReceiptImage();
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في اختيار الصورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadReceiptImage() async {
    if (_receiptImage == null) return;

    setState(() {
      _isUploadingReceipt = true;
    });

    try {
      final imageUrl = await ImgBBService.uploadImage(_receiptImage!);
      if (imageUrl != null) {
        setState(() {
          _uploadedReceiptUrl = imageUrl;
        });
      } else {
        throw Exception('فشل رفع الصورة');
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في رفع الصورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isUploadingReceipt = false;
      });
    }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.right,
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
                : Text(
                    _isCashOnDelivery ? 'تأكيد الطلب' : 'تأكيد الدفع',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    // التحقق من العنوان
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

    // التحقق من إثبات الدفع (إذا لم يكن الدفع عند الاستلام)
    if (!_isCashOnDelivery) {
      if (_transactionNumberController.text.trim().isEmpty) {
        Get.snackbar(
          'تنبيه',
          'يرجى إدخال رقم العملية',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_uploadedReceiptUrl == null) {
        Get.snackbar(
          'تنبيه',
          'يرجى رفع صورة الإيصال',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // تحويل المنتجات لصيغة مناسبة للطلب
      final List<Map<String, dynamic>> orderItems =
          widget.cartItems.map((item) {
        return {
          'productId': item.id,
          'name': item.name,
          'price': double.tryParse(item.price) ?? 0,
          'quantity': item.quantity,
          'totalPrice': item.totalPrice,
          'sellerId': item.ownerId,
        };
      }).toList();

      // إنشاء الطلب
      final ordersController = Get.find<OrdersController>();
      final orderId = await ordersController.createOrder(
        items: orderItems,
        totalPrice: _totalPrice,
        paymentMethod: _paymentMethod,
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        transactionNumber:
            _isCashOnDelivery ? null : _transactionNumberController.text.trim(),
        paymentReceiptUrl: _isCashOnDelivery ? null : _uploadedReceiptUrl,
      );

      if (orderId != null) {
        // مسح السلة بعد الطلب الناجح
        final cartController = Get.find<CartController>();
        await cartController.clearCart();

        // عرض رسالة نجاح
        Get.offNamedUntil('/home', (route) => false);
        Get.snackbar(
          'تم بنجاح! ✅',
          _isCashOnDelivery
              ? 'تم إنشاء طلبك بنجاح. سيتم التواصل معك للتسليم.'
              : 'تم تقديم طلبك. بانتظار تأكيد البائع للدفع.',
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
