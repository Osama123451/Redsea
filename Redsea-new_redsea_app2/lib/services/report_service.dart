import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:redsea/models/report_model.dart';

/// خدمة جمع وحساب بيانات التقارير
class ReportService {
  static final DatabaseReference _ordersRef =
      FirebaseDatabase.instance.ref().child('orders');
  static final DatabaseReference _swapsRef =
      FirebaseDatabase.instance.ref().child('swapRequests');
  static final DatabaseReference _serviceOrdersRef =
      FirebaseDatabase.instance.ref().child('serviceOrders');
  static final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref().child('products');
  static final DatabaseReference _servicesRef =
      FirebaseDatabase.instance.ref().child('services');

  /// جمع تقرير كامل للمستخدم
  static Future<UserReport> generateReport({
    required ReportPeriod period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return UserReport();

    final startDate = period == ReportPeriod.custom
        ? customStartDate ?? DateTime.now().subtract(const Duration(days: 30))
        : period.startDate;
    final endDate = period == ReportPeriod.custom
        ? customEndDate ?? DateTime.now()
        : period.endDate;

    final startTimestamp = startDate.millisecondsSinceEpoch;
    final endTimestamp = endDate.millisecondsSinceEpoch;

    try {
      // جمع البيانات بالتوازي
      final results = await Future.wait([
        _getOrdersStats(userId, startTimestamp, endTimestamp),
        _getSellerStats(userId, startTimestamp, endTimestamp),
        _getSwapStats(userId, startTimestamp, endTimestamp),
        _getServiceStats(userId, startTimestamp, endTimestamp),
        _getActivityTimeline(userId, startTimestamp, endTimestamp),
        _getSalesTimeline(userId, startTimestamp, endTimestamp),
        _getMyProductsAndServicesCount(userId),
      ]);

      final ordersStats = results[0] as Map<String, dynamic>;
      final sellerStats = results[1] as Map<String, dynamic>;
      final swapStats = results[2] as Map<String, dynamic>;
      final serviceStats = results[3] as Map<String, dynamic>;
      final activityTimeline = results[4] as List<ActivityPoint>;
      final salesTimeline = results[5] as List<ActivityPoint>;
      final myItemsCounts = results[6] as Map<String, int>;

      return UserReport(
        // إحصائيات الطلبات
        totalOrders: ordersStats['total'] ?? 0,
        completedOrders: ordersStats['completed'] ?? 0,
        pendingOrders: ordersStats['pending'] ?? 0,
        cancelledOrders: ordersStats['cancelled'] ?? 0,
        totalSpent: ordersStats['totalSpent'] ?? 0.0,
        // إحصائيات المبيعات
        totalSales: sellerStats['total'] ?? 0,
        completedSales: sellerStats['completed'] ?? 0,
        totalEarnings: sellerStats['totalEarnings'] ?? 0.0,
        averageRating: sellerStats['averageRating'] ?? 0.0,
        reviewsCount: sellerStats['reviewsCount'] ?? 0,
        // إحصائيات المقايضات
        totalSwaps: swapStats['total'] ?? 0,
        successfulSwaps: swapStats['successful'] ?? 0,
        pendingSwaps: swapStats['pending'] ?? 0,
        rejectedSwaps: swapStats['rejected'] ?? 0,
        swapValue: swapStats['totalValue'] ?? 0.0,
        // إحصائيات الخدمات
        serviceOrdersBought: serviceStats['bought'] ?? 0,
        serviceOrdersSold: serviceStats['sold'] ?? 0,
        serviceSpending: serviceStats['spending'] ?? 0.0,
        serviceEarnings: serviceStats['earnings'] ?? 0.0,
        // منتجاتي وخدماتي
        myProductsCount: myItemsCounts['products'] ?? 0,
        myServicesCount: myItemsCounts['services'] ?? 0,
        // الرسوم البيانية
        activityTimeline: activityTimeline,
        salesTimeline: salesTimeline,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error generating report: $e');
      return UserReport(startDate: startDate, endDate: endDate);
    }
  }

  /// إحصائيات الطلبات (كمشتري)
  static Future<Map<String, dynamic>> _getOrdersStats(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot =
          await _ordersRef.orderByChild('userId').equalTo(userId).once();

      if (snapshot.snapshot.value == null) {
        return {
          'total': 0,
          'completed': 0,
          'pending': 0,
          'cancelled': 0,
          'totalSpent': 0.0
        };
      }

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      int total = 0, completed = 0, pending = 0, cancelled = 0;
      double totalSpent = 0;

      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        final timestamp = order['timestamp'] ?? 0;

        if (timestamp >= startTimestamp && timestamp <= endTimestamp) {
          total++;
          final status = order['status'] ?? '';
          final price = (order['totalPrice'] ?? 0).toDouble();

          if (status == 'delivered' || status == 'payment_confirmed') {
            completed++;
            totalSpent += price;
          } else if (status == 'cancelled') {
            cancelled++;
          } else {
            pending++;
          }
        }
      });

      return {
        'total': total,
        'completed': completed,
        'pending': pending,
        'cancelled': cancelled,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      debugPrint('Error getting orders stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'cancelled': 0,
        'totalSpent': 0.0
      };
    }
  }

  /// إحصائيات المبيعات (كبائع)
  static Future<Map<String, dynamic>> _getSellerStats(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot =
          await _ordersRef.orderByChild('sellerId').equalTo(userId).once();

      if (snapshot.snapshot.value == null) {
        return {
          'total': 0,
          'completed': 0,
          'totalEarnings': 0.0,
          'averageRating': 0.0,
          'reviewsCount': 0
        };
      }

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      int total = 0, completed = 0;
      double totalEarnings = 0;

      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        final timestamp = order['timestamp'] ?? 0;

        if (timestamp >= startTimestamp && timestamp <= endTimestamp) {
          total++;
          final status = order['status'] ?? '';
          final price = (order['totalPrice'] ?? 0).toDouble();

          if (status == 'delivered' || status == 'payment_confirmed') {
            completed++;
            totalEarnings += price;
          }
        }
      });

      // جلب التقييم من المنتجات
      double averageRating = 0;
      int reviewsCount = 0;
      try {
        final productsSnapshot =
            await _productsRef.orderByChild('sellerId').equalTo(userId).once();
        if (productsSnapshot.snapshot.value != null) {
          final products = Map<dynamic, dynamic>.from(
              productsSnapshot.snapshot.value as Map);
          double totalRating = 0;
          int ratedProducts = 0;
          products.forEach((key, value) {
            final product = Map<String, dynamic>.from(value);
            final rating = (product['rating'] ?? 0).toDouble();
            if (rating > 0) {
              totalRating += rating;
              ratedProducts++;
              reviewsCount += (product['reviewsCount'] ?? 0) as int;
            }
          });
          if (ratedProducts > 0) {
            averageRating = totalRating / ratedProducts;
          }
        }
      } catch (e) {
        debugPrint('Error getting rating: $e');
      }

      return {
        'total': total,
        'completed': completed,
        'totalEarnings': totalEarnings,
        'averageRating': averageRating,
        'reviewsCount': reviewsCount,
      };
    } catch (e) {
      debugPrint('Error getting seller stats: $e');
      return {
        'total': 0,
        'completed': 0,
        'totalEarnings': 0.0,
        'averageRating': 0.0,
        'reviewsCount': 0
      };
    }
  }

  /// إحصائيات المقايضات
  static Future<Map<String, dynamic>> _getSwapStats(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot = await _swapsRef.once();

      if (snapshot.snapshot.value == null) {
        return {
          'total': 0,
          'successful': 0,
          'pending': 0,
          'rejected': 0,
          'totalValue': 0.0
        };
      }

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      int total = 0, successful = 0, pending = 0, rejected = 0;
      double totalValue = 0;

      data.forEach((key, value) {
        final swap = Map<String, dynamic>.from(value);
        final requesterId = swap['requesterId'] ?? '';
        final targetOwnerId = swap['targetOwnerId'] ?? '';
        final timestamp = swap['timestamp'] ?? 0;

        // فقط المقايضات الخاصة بالمستخدم
        if ((requesterId == userId || targetOwnerId == userId) &&
            timestamp >= startTimestamp &&
            timestamp <= endTimestamp) {
          total++;
          final status = swap['status'] ?? '';

          if (status == 'completed') {
            successful++;
            totalValue += (swap['targetProductPrice'] ?? 0).toDouble();
          } else if (status == 'pending') {
            pending++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }
      });

      return {
        'total': total,
        'successful': successful,
        'pending': pending,
        'rejected': rejected,
        'totalValue': totalValue,
      };
    } catch (e) {
      debugPrint('Error getting swap stats: $e');
      return {
        'total': 0,
        'successful': 0,
        'pending': 0,
        'rejected': 0,
        'totalValue': 0.0
      };
    }
  }

  /// إحصائيات الخدمات
  static Future<Map<String, dynamic>> _getServiceStats(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot = await _serviceOrdersRef.once();

      if (snapshot.snapshot.value == null) {
        return {'bought': 0, 'sold': 0, 'spending': 0.0, 'earnings': 0.0};
      }

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      int bought = 0, sold = 0;
      double spending = 0, earnings = 0;

      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        final buyerId = order['buyerId'] ?? '';
        final sellerId = order['sellerId'] ?? '';
        final timestamp = order['timestamp'] ?? 0;
        final price = (order['totalPrice'] ?? 0).toDouble();
        final status = order['status'] ?? '';

        if (timestamp >= startTimestamp && timestamp <= endTimestamp) {
          if (buyerId == userId && status == 'completed') {
            bought++;
            spending += price;
          }
          if (sellerId == userId && status == 'completed') {
            sold++;
            earnings += price;
          }
        }
      });

      return {
        'bought': bought,
        'sold': sold,
        'spending': spending,
        'earnings': earnings,
      };
    } catch (e) {
      debugPrint('Error getting service stats: $e');
      return {'bought': 0, 'sold': 0, 'spending': 0.0, 'earnings': 0.0};
    }
  }

  /// بيانات الرسم البياني للنشاط عبر الزمن
  static Future<List<ActivityPoint>> _getActivityTimeline(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot =
          await _ordersRef.orderByChild('userId').equalTo(userId).once();

      if (snapshot.snapshot.value == null) return [];

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      Map<String, double> dailyActivity = {};

      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        final timestamp = order['timestamp'] ?? 0;

        if (timestamp >= startTimestamp && timestamp <= endTimestamp) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final dateKey = '${date.year}-${date.month}-${date.day}';
          dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
        }
      });

      return dailyActivity.entries.map((entry) {
        final parts = entry.key.split('-');
        return ActivityPoint(
          date: DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          value: entry.value,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Error getting activity timeline: $e');
      return [];
    }
  }

  /// بيانات الرسم البياني للمبيعات عبر الزمن
  static Future<List<ActivityPoint>> _getSalesTimeline(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) async {
    try {
      final snapshot =
          await _ordersRef.orderByChild('sellerId').equalTo(userId).once();

      if (snapshot.snapshot.value == null) return [];

      final data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
      Map<String, double> dailySales = {};

      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value);
        final timestamp = order['timestamp'] ?? 0;
        final status = order['status'] ?? '';

        if (timestamp >= startTimestamp &&
            timestamp <= endTimestamp &&
            (status == 'delivered' || status == 'payment_confirmed')) {
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final dateKey = '${date.year}-${date.month}-${date.day}';
          final price = (order['totalPrice'] ?? 0).toDouble();
          dailySales[dateKey] = (dailySales[dateKey] ?? 0) + price;
        }
      });

      return dailySales.entries.map((entry) {
        final parts = entry.key.split('-');
        return ActivityPoint(
          date: DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
          value: entry.value,
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Error getting sales timeline: $e');
      return [];
    }
  }

  /// عد منتجاتي وخدماتي
  static Future<Map<String, int>> _getMyProductsAndServicesCount(
    String userId,
  ) async {
    try {
      int productsCount = 0;
      int servicesCount = 0;

      // عد المنتجات
      final productsSnapshot =
          await _productsRef.orderByChild('userId').equalTo(userId).once();
      if (productsSnapshot.snapshot.value != null) {
        productsCount = (productsSnapshot.snapshot.value as Map).length;
      }

      // عد الخدمات
      final servicesSnapshot =
          await _servicesRef.orderByChild('ownerId').equalTo(userId).once();
      if (servicesSnapshot.snapshot.value != null) {
        servicesCount = (servicesSnapshot.snapshot.value as Map).length;
      }

      return {
        'products': productsCount,
        'services': servicesCount,
      };
    } catch (e) {
      debugPrint('Error getting my products and services count: $e');
      return {'products': 0, 'services': 0};
    }
  }

  // =====================================
  // Admin Export Methods (Stubs)
  // =====================================

  /// تصدير المستخدمين كـ PDF
  static Future<String?> exportUsersPDF() async {
    // TODO: Implement user export to PDF
    debugPrint('exportUsersPDF: Not implemented yet');
    return null;
  }

  /// تصدير المستخدمين كـ Excel
  static Future<String?> exportUsersExcel() async {
    // TODO: Implement user export to Excel
    debugPrint('exportUsersExcel: Not implemented yet');
    return null;
  }

  /// تصدير المنتجات كـ PDF
  static Future<String?> exportProductsPDF() async {
    // TODO: Implement products export to PDF
    debugPrint('exportProductsPDF: Not implemented yet');
    return null;
  }

  /// تصدير المنتجات كـ Excel
  static Future<String?> exportProductsExcel() async {
    // TODO: Implement products export to Excel
    debugPrint('exportProductsExcel: Not implemented yet');
    return null;
  }

  /// تصدير الطلبات كـ PDF
  static Future<String?> exportOrdersPDF() async {
    // TODO: Implement orders export to PDF
    debugPrint('exportOrdersPDF: Not implemented yet');
    return null;
  }

  /// تصدير الطلبات كـ Excel
  static Future<String?> exportOrdersExcel() async {
    // TODO: Implement orders export to Excel
    debugPrint('exportOrdersExcel: Not implemented yet');
    return null;
  }

  /// تصدير المقايضات كـ PDF
  static Future<String?> exportSwapRequestsPDF() async {
    // TODO: Implement swap requests export to PDF
    debugPrint('exportSwapRequestsPDF: Not implemented yet');
    return null;
  }

  /// تصدير المقايضات كـ Excel
  static Future<String?> exportSwapRequestsExcel() async {
    // TODO: Implement swap requests export to Excel
    debugPrint('exportSwapRequestsExcel: Not implemented yet');
    return null;
  }

  /// فتح الملف المصدر
  static Future<void> openExportedFile(String filePath) async {
    // TODO: Implement file opening
    debugPrint('openExportedFile: $filePath');
  }
}
