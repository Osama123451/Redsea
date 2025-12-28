import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart' as intl;

/// خدمة تصدير التقارير للمدير
class ReportService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // ============== تصدير المستخدمين ==============

  /// تصدير تقرير المستخدمين كـ PDF
  static Future<String?> exportUsersPDF() async {
    try {
      final snapshot = await _database.child('users').get();
      if (!snapshot.exists) return null;

      final users = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final user = Map<String, dynamic>.from(value as Map);
        user['id'] = key;
        users.add(user);
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير المستخدمين',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
                'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text('إجمالي المستخدمين: ${users.length}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['الاسم', 'البريد', 'الهاتف', 'الحالة'],
              data: users
                  .map((u) => [
                        u['name'] ?? '-',
                        u['email'] ?? '-',
                        u['phone'] ?? '-',
                        u['isBanned'] == true ? 'محظور' : 'نشط',
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'users_report');
    } catch (e) {
      debugPrint('Error exporting users PDF: $e');
      return null;
    }
  }

  /// تصدير تقرير المستخدمين كـ Excel
  static Future<String?> exportUsersExcel() async {
    try {
      final snapshot = await _database.child('users').get();
      if (!snapshot.exists) return null;

      final users = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final user = Map<String, dynamic>.from(value as Map);
        user['id'] = key;
        users.add(user);
      });

      final excel = Excel.createExcel();
      final sheet = excel['المستخدمين'];

      // العناوين
      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('البريد'),
        TextCellValue('الهاتف'),
        TextCellValue('الحالة'),
        TextCellValue('تاريخ التسجيل'),
      ]);

      // البيانات
      for (var user in users) {
        sheet.appendRow([
          TextCellValue(user['name'] ?? '-'),
          TextCellValue(user['email'] ?? '-'),
          TextCellValue(user['phone'] ?? '-'),
          TextCellValue(user['isBanned'] == true ? 'محظور' : 'نشط'),
          TextCellValue(user['createdAt'] ?? '-'),
        ]);
      }

      return await _saveExcel(excel, 'users_report');
    } catch (e) {
      debugPrint('Error exporting users Excel: $e');
      return null;
    }
  }

  // ============== تصدير المنتجات ==============

  /// تصدير تقرير المنتجات كـ PDF
  static Future<String?> exportProductsPDF() async {
    try {
      final snapshot = await _database.child('products').get();
      if (!snapshot.exists) return null;

      final products = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final product = Map<String, dynamic>.from(value as Map);
        product['id'] = key;
        products.add(product);
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير المنتجات',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
                'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text('إجمالي المنتجات: ${products.length}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['الاسم', 'التصنيف', 'السعر', 'قابل للمقايضة'],
              data: products
                  .map((p) => [
                        p['name'] ?? '-',
                        p['category'] ?? '-',
                        '${p['price'] ?? 0} ريال',
                        p['isAvailableForSwap'] == true ? 'نعم' : 'لا',
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'products_report');
    } catch (e) {
      debugPrint('Error exporting products PDF: $e');
      return null;
    }
  }

  /// تصدير تقرير المنتجات كـ Excel
  static Future<String?> exportProductsExcel() async {
    try {
      final snapshot = await _database.child('products').get();
      if (!snapshot.exists) return null;

      final products = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final product = Map<String, dynamic>.from(value as Map);
        product['id'] = key;
        products.add(product);
      });

      final excel = Excel.createExcel();
      final sheet = excel['المنتجات'];

      sheet.appendRow([
        TextCellValue('الاسم'),
        TextCellValue('التصنيف'),
        TextCellValue('السعر'),
        TextCellValue('قابل للمقايضة'),
        TextCellValue('الوصف'),
      ]);

      for (var product in products) {
        sheet.appendRow([
          TextCellValue(product['name'] ?? '-'),
          TextCellValue(product['category'] ?? '-'),
          TextCellValue('${product['price'] ?? 0}'),
          TextCellValue(product['isAvailableForSwap'] == true ? 'نعم' : 'لا'),
          TextCellValue(product['description'] ?? '-'),
        ]);
      }

      return await _saveExcel(excel, 'products_report');
    } catch (e) {
      debugPrint('Error exporting products Excel: $e');
      return null;
    }
  }

  // ============== تصدير الطلبات ==============

  /// تصدير تقرير الطلبات كـ PDF
  static Future<String?> exportOrdersPDF() async {
    try {
      final snapshot = await _database.child('orders').get();
      if (!snapshot.exists) return null;

      final orders = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value as Map);
        order['id'] = key;
        orders.add(order);
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير الطلبات',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
                'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text('إجمالي الطلبات: ${orders.length}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['رقم الطلب', 'المبلغ', 'الحالة', 'التاريخ'],
              data: orders
                  .map((o) => [
                        o['id'] ?? '-',
                        '${o['totalAmount'] ?? 0} ريال',
                        _translateOrderStatus(o['status']),
                        o['createdAt'] ?? '-',
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'orders_report');
    } catch (e) {
      debugPrint('Error exporting orders PDF: $e');
      return null;
    }
  }

  /// تصدير تقرير الطلبات كـ Excel
  static Future<String?> exportOrdersExcel() async {
    try {
      final snapshot = await _database.child('orders').get();
      if (!snapshot.exists) return null;

      final orders = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final order = Map<String, dynamic>.from(value as Map);
        order['id'] = key;
        orders.add(order);
      });

      final excel = Excel.createExcel();
      final sheet = excel['الطلبات'];

      sheet.appendRow([
        TextCellValue('رقم الطلب'),
        TextCellValue('المشتري'),
        TextCellValue('البائع'),
        TextCellValue('المبلغ'),
        TextCellValue('الحالة'),
      ]);

      for (var order in orders) {
        sheet.appendRow([
          TextCellValue(order['id'] ?? '-'),
          TextCellValue(order['buyerId'] ?? '-'),
          TextCellValue(order['sellerId'] ?? '-'),
          TextCellValue('${order['totalAmount'] ?? 0}'),
          TextCellValue(_translateOrderStatus(order['status'])),
        ]);
      }

      return await _saveExcel(excel, 'orders_report');
    } catch (e) {
      debugPrint('Error exporting orders Excel: $e');
      return null;
    }
  }

  // ============== تصدير طلبات المقايضة ==============

  /// تصدير تقرير طلبات المقايضة كـ PDF
  static Future<String?> exportSwapRequestsPDF() async {
    try {
      final snapshot = await _database.child('swap_requests').get();
      if (!snapshot.exists) return null;

      final swaps = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final swap = Map<String, dynamic>.from(value as Map);
        swap['id'] = key;
        swaps.add(swap);
      });

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير طلبات المقايضة',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
                'تاريخ التقرير: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.Text('إجمالي طلبات المقايضة: ${swaps.length}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['رقم الطلب', 'الحالة', 'التاريخ'],
              data: swaps
                  .map((s) => [
                        s['id'] ?? '-',
                        _translateSwapStatus(s['status']),
                        s['createdAt'] ?? '-',
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      return await _savePDF(pdf, 'swap_requests_report');
    } catch (e) {
      debugPrint('Error exporting swap requests PDF: $e');
      return null;
    }
  }

  /// تصدير تقرير طلبات المقايضة كـ Excel
  static Future<String?> exportSwapRequestsExcel() async {
    try {
      final snapshot = await _database.child('swap_requests').get();
      if (!snapshot.exists) return null;

      final swaps = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final swap = Map<String, dynamic>.from(value as Map);
        swap['id'] = key;
        swaps.add(swap);
      });

      final excel = Excel.createExcel();
      final sheet = excel['طلبات المقايضة'];

      sheet.appendRow([
        TextCellValue('رقم الطلب'),
        TextCellValue('مقدم الطلب'),
        TextCellValue('صاحب المنتج'),
        TextCellValue('الحالة'),
      ]);

      for (var swap in swaps) {
        sheet.appendRow([
          TextCellValue(swap['id'] ?? '-'),
          TextCellValue(swap['requesterId'] ?? '-'),
          TextCellValue(swap['targetOwnerId'] ?? '-'),
          TextCellValue(_translateSwapStatus(swap['status'])),
        ]);
      }

      return await _saveExcel(excel, 'swap_requests_report');
    } catch (e) {
      debugPrint('Error exporting swap requests Excel: $e');
      return null;
    }
  }

  // ============== دوال مساعدة ==============

  static Future<String?> _savePDF(pw.Document pdf, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp =
          intl.DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/${fileName}_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      return null;
    }
  }

  static Future<String?> _saveExcel(Excel excel, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp =
          intl.DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/${fileName}_$timestamp.xlsx');
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error saving Excel: $e');
      return null;
    }
  }

  /// فتح ملف بعد التصدير
  static Future<void> openExportedFile(String filePath) async {
    await OpenFilex.open(filePath);
  }

  static String _translateOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'confirmed':
        return 'مؤكد';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status ?? '-';
    }
  }

  static String _translateSwapStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status ?? '-';
    }
  }
}
