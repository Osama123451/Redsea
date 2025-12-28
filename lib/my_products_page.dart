import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/add_product_page.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref().child('products');

  List<Product> _myProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  Future<void> _loadMyProducts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot =
          await _productsRef.orderByChild('userId').equalTo(userId).once();

      List<Product> products = [];
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        data.forEach((key, value) {
          final productData = Map<String, dynamic>.from(value);
          products.add(Product(
            id: key,
            name: productData['name'],
            price: productData['price'],
            description: productData['description'],
            imageUrl: productData['imageUrl'],
            category: productData['category'],
            negotiable: productData['negotiable'] ?? false,
            dateAdded:
                DateTime.fromMillisecondsSinceEpoch(productData['createdAt']),
            ownerId: productData['userId'],
          ));
        });
      }

      setState(() {
        _myProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading my products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _productsRef.child(productId).remove();
      setState(() {
        _myProducts.removeWhere((p) => p.id == productId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المنتج بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحذف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منتجاتي'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('لم تضف أي منتجات بعد',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AddProductPage()),
                          ).then((_) => _loadMyProducts());
                        },
                        child: const Text('أضف منتج الآن'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myProducts.length,
                  itemBuilder: (context, index) {
                    final product = _myProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.error),
                          ),
                        ),
                        title: Text(product.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${product.price} ريال'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(product.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showDeleteDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
