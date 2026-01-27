import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:redsea/models/report_model.dart';

/// خدمة تصدير التقارير كـ PDF
class PdfExportService {
  static Future<void> exportReport(UserReport report) async {
    final pdf = pw.Document();
    final formatter = NumberFormat('#,###');
    final dateFormatter = DateFormat('yyyy/MM/dd');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          // العنوان
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير النشاط',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'الفترة: ${dateFormatter.format(report.startDate)} - ${dateFormatter.format(report.endDate)}',
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 20),

          // إحصائيات الطلبات
          _buildSection('إحصائيات الطلبات', [
            _buildRow('إجمالي الطلبات', report.totalOrders.toString()),
            _buildRow('الطلبات المكتملة', report.completedOrders.toString()),
            _buildRow('الطلبات المعلقة', report.pendingOrders.toString()),
            _buildRow('الطلبات الملغية', report.cancelledOrders.toString()),
            _buildRow('إجمالي المصروفات',
                '${formatter.format(report.totalSpent)} ر.ي'),
          ]),

          pw.SizedBox(height: 15),

          // إحصائيات المبيعات
          _buildSection('إحصائيات المبيعات', [
            _buildRow('إجمالي المبيعات', report.totalSales.toString()),
            _buildRow('المبيعات المكتملة', report.completedSales.toString()),
            _buildRow('إجمالي الإيرادات',
                '${formatter.format(report.totalEarnings)} ر.ي'),
            _buildRow(
                'التقييم', '${report.averageRating.toStringAsFixed(1)} / 5'),
          ]),

          pw.SizedBox(height: 15),

          // إحصائيات المقايضات
          _buildSection('إحصائيات المقايضات', [
            _buildRow('إجمالي المقايضات', report.totalSwaps.toString()),
            _buildRow('المقايضات الناجحة', report.successfulSwaps.toString()),
            _buildRow('المقايضات المعلقة', report.pendingSwaps.toString()),
            _buildRow('المقايضات المرفوضة', report.rejectedSwaps.toString()),
            _buildRow(
                'قيمة المقايضات', '${formatter.format(report.swapValue)} ر.ي'),
          ]),

          pw.SizedBox(height: 15),

          // إحصائيات الخدمات
          _buildSection('إحصائيات الخدمات', [
            _buildRow(
                'الخدمات المشتراة', report.serviceOrdersBought.toString()),
            _buildRow('الخدمات المقدمة', report.serviceOrdersSold.toString()),
            _buildRow('إنفاق الخدمات',
                '${formatter.format(report.serviceSpending)} ر.ي'),
            _buildRow('إيرادات الخدمات',
                '${formatter.format(report.serviceEarnings)} ر.ي'),
          ]),

          pw.SizedBox(height: 20),

          // الملخص المالي
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الملخص المالي',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: 10),
                _buildRow(
                  'إجمالي المصروفات',
                  '${formatter.format(report.totalSpent + report.serviceSpending)} ر.ي',
                ),
                _buildRow(
                  'إجمالي الإيرادات',
                  '${formatter.format(report.totalEarnings + report.serviceEarnings)} ر.ي',
                ),
                pw.Divider(),
                _buildRow(
                  'صافي الحساب',
                  '${formatter.format(report.netEarnings)} ر.ي',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // حفظ الملف
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    // فتح الملف
    await OpenFilex.open(file.path);
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Divider(),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
