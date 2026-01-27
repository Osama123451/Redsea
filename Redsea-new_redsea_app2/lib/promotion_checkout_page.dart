import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/models/ad_model.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:ui' as ui;

class PromotionCheckoutPage extends StatefulWidget {
  const PromotionCheckoutPage({super.key});

  @override
  State<PromotionCheckoutPage> createState() => _PromotionCheckoutPageState();
}

class _PromotionCheckoutPageState extends State<PromotionCheckoutPage> {
  final Map<String, dynamic> _args = Get.arguments;
  late final Product _product;
  late final double _viewersCount;
  late final String _adType;
  late final int _durationDays;
  late final String _title;

  final double _pricePerViewerUsd = 0.05;
  final double _usdToYerRate = 550.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _product = _args['product'];
    _viewersCount = _args['viewersCount'];
    _adType = _args['adType'];
    _durationDays = _args['durationDays'];
    _title = _args['title'];
  }

  double get _totalUsd => (_viewersCount * _pricePerViewerUsd) * _durationDays;
  double get _totalYer => _totalUsd * _usdToYerRate;

  String formatPrice(double price) {
    return intl.NumberFormat('#,###').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('حساب التكلفة والدفع',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildCostBreakdown(),
                    const SizedBox(height: 24),
                    _buildPaymentNotice(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الإعلان',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          _buildSummaryRow('المنتج', _product.name),
          _buildSummaryRow('عنوان الإعلان', _title),
          _buildSummaryRow('نوع الإعلان', _getAdTypeName(_adType)),
          _buildSummaryRow('الجمهور يومياً', '${_viewersCount.toInt()} مشاهد'),
          _buildSummaryRow('مدة الإعلان', '$_durationDays أيام'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'تفاصيل التكلفة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCostRow('سعر المشاهد الواحد/يوم', '\$$_pricePerViewerUsd'),
          _buildCostRow('سعر الصرف التقديري', '1\$ = $_usdToYerRate ر.ي'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي بالدولار', style: TextStyle(fontSize: 14)),
              Text('\$${_totalUsd.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الإجمالي بالريال اليمني',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${formatPrice(_totalYer)} ر.ي',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'سيتم إرسال طلب الترويج للمراجعة. يمكنك الدفع لاحقاً من خلال قسم "إعلاناتي" لتفعيل الإعلان.',
              style: TextStyle(fontSize: 13, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: AppWidgets.primaryButton(
          text: 'تأكيد وطلب الترويج',
          isLoading: _isSubmitting,
          onPressed: _submitPromotion,
          icon: Icons.check_circle_outline,
        ),
      ),
    );
  }

  String _getAdTypeName(String id) {
    switch (id) {
      case 'post':
        return 'منشور رئيسي';
      case 'banner':
        return 'بنر علوي';
      case 'video':
        return 'فيديو قصير';
      case 'bottom_notes':
        return 'ملاحظة أسفل الشاشة';
      default:
        return id;
    }
  }

  Future<void> _submitPromotion() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يجب تسجيل الدخول أولاً';

      final adId = FirebaseDatabase.instance.ref('ads').push().key ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final newAd = Ad(
        id: adId,
        productId: _product.id,
        ownerId: user.uid,
        title: _title,
        adType: _adType,
        plan: 'standard',
        status: 'pending',
        paymentStatus: 'unpaid',
        viewersPerDay: _viewersCount,
        durationDays: _durationDays,
        price: _totalYer,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        mediaUrls: [_product.imageUrl],
        targetAudience: _args['targetAudience'],
      );

      await FirebaseDatabase.instance.ref('ads/$adId').set(newAd.toMap());

      Get.back(); // Back to promote page
      Get.back(); // Back to details page

      Get.snackbar(
        'تم بنجاح',
        'تم إرسال طلب الترويج بنجاح. سيتم مراجعة الطلب قريباً.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إرسال الطلب: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
