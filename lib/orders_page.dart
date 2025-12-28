import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:intl/intl.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _ordersRef =
      FirebaseDatabase.instance.ref().child('orders');

  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot =
          await _ordersRef.orderByChild('userId').equalTo(userId).once();

      List<Map<String, dynamic>> orders = [];
      if (snapshot.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        data.forEach((key, value) {
          final orderData = Map<String, dynamic>.from(value);
          orders.add({
            'id': key,
            ...orderData,
          });
        });
      }

      // Sort by timestamp descending
      orders
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      setState(() {
        _myOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_verification':
        return 'قيد المراجعة';
      case 'verified':
        return 'تم التأكيد';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_verification':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لم تقم بأي طلبات بعد',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myOrders.length,
                  itemBuilder: (context, index) {
                    final order = _myOrders[index];
                    final items = (order['items'] as List?) ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(
                            'طلب #${order['id'].toString().substring(1, 6)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(order['status'] ?? ''),
                              style: TextStyle(
                                  color: _getStatusColor(order['status'] ?? ''),
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy hh:mm a').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      order['timestamp'] ?? 0)),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Text('${order['totalPrice']} ريال',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('المنتجات:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                ...items
                                    .map((item) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                  '- ${item['name']} (x${item['quantity'] ?? 1})'),
                                              Text('${item['price']} ريال'),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                const Divider(),
                                if (order['paymentMethod'] != null)
                                  Text(
                                      'طريقة الدفع: ${order['paymentMethod']}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
