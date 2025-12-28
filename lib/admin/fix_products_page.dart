import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// صفحة لإصلاح المنتجات القديمة التي ليس بها userId
class FixProductsPage extends StatefulWidget {
  const FixProductsPage({super.key});

  @override
  State<FixProductsPage> createState() => _FixProductsPageState();
}

class _FixProductsPageState extends State<FixProductsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool _isLoading = false;
  String _status = '';
  int _totalProducts = 0;
  int _productsWithoutUserId = 0;
  int _fixedProducts = 0;

  @override
  void initState() {
    super.initState();
    _checkProducts();
  }

  Future<void> _checkProducts() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري فحص المنتجات...';
    });

    try {
      final snapshot = await _dbRef.child('products').once();

      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        int withoutUserId = 0;

        data.forEach((key, value) {
          final product = Map<String, dynamic>.from(value);
          if (product['userId'] == null ||
              product['userId'].toString().isEmpty) {
            withoutUserId++;
          }
        });

        setState(() {
          _totalProducts = data.length;
          _productsWithoutUserId = withoutUserId;
          _status = 'تم الفحص';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixProducts() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'جاري إصلاح المنتجات...';
      _fixedProducts = 0;
    });

    try {
      final snapshot = await _dbRef.child('products').once();

      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);

        for (var entry in data.entries) {
          final key = entry.key;
          final product = Map<String, dynamic>.from(entry.value);

          if (product['userId'] == null ||
              product['userId'].toString().isEmpty) {
            // إضافة userId للمنتجات القديمة (يمكن تعيين userId محدد)
            await _dbRef.child('products').child(key).update({
              'userId': currentUserId, // سيتم تعيين المستخدم الحالي كمالك
            });

            setState(() {
              _fixedProducts++;
              _status = 'تم إصلاح $_fixedProducts منتج...';
            });
          }
        }

        setState(() {
          _status = 'تم إصلاح $_fixedProducts منتج بنجاح!';
          _productsWithoutUserId = 0;
        });

        Get.snackbar('نجاح', 'تم إصلاح جميع المنتجات!',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      setState(() {
        _status = 'خطأ: $e';
      });
      Get.snackbar('خطأ', 'فشل في إصلاح المنتجات: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إصلاح المنتجات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.build, size: 48, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'أداة إصلاح المنتجات',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'هذه الأداة تضيف معرف المستخدم للمنتجات القديمة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('إجمالي المنتجات:', '$_totalProducts'),
                    const Divider(),
                    _buildStatRow(
                        'منتجات بدون userId:', '$_productsWithoutUserId',
                        color: _productsWithoutUserId > 0
                            ? Colors.red
                            : Colors.green),
                    const Divider(),
                    _buildStatRow('تم إصلاحها:', '$_fixedProducts'),
                    const Divider(),
                    Text(_status,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _checkProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة الفحص'),
              ),
              const SizedBox(height: 8),
              if (_productsWithoutUserId > 0)
                ElevatedButton.icon(
                  onPressed: _fixProducts,
                  icon: const Icon(Icons.build),
                  label: Text('إصلاح $_productsWithoutUserId منتج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label),
        ],
      ),
    );
  }
}
