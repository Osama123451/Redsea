import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// خدمة إدارة البلاغات
class UserReportService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// أسباب البلاغ المحددة مسبقاً
  static const List<Map<String, String>> reportReasons = [
    {'id': 'spam', 'label': 'رسائل مزعجة / سبام'},
    {'id': 'harassment', 'label': 'تحرش أو إساءة'},
    {'id': 'fraud', 'label': 'احتيال أو نصب'},
    {'id': 'inappropriate', 'label': 'محتوى غير لائق'},
    {'id': 'fake_account', 'label': 'حساب مزيف'},
    {'id': 'scam', 'label': 'محاولة خداع'},
    {'id': 'other', 'label': 'سبب آخر'},
  ];

  /// إرسال بلاغ جديد
  static Future<bool> submitReport({
    required String reportedUserId,
    required String reportedUserName,
    required String reason,
    String? details,
    String? chatId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // الحصول على اسم المُبلِّغ
      String reporterName = 'مستخدم';
      try {
        final userSnapshot =
            await _database.child('users/${currentUser.uid}').get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          reporterName =
              userData['name'] ?? userData['displayName'] ?? 'مستخدم';
        }
      } catch (e) {
        debugPrint('Error getting reporter name: $e');
      }

      // إنشاء البلاغ
      final reportRef = _database.child('reports').push();
      await reportRef.set({
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reason': reason,
        'details': details ?? '',
        'chatId': chatId,
        'status': 'pending', // pending, reviewed, resolved, rejected
        'timestamp': ServerValue.timestamp,
        'reviewedAt': null,
        'adminNote': null,
      });

      debugPrint('✅ Report submitted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting report: $e');
      return false;
    }
  }

  /// الحصول على جميع البلاغات (للمدير)
  static Stream<DatabaseEvent> getReportsStream() {
    return _database.child('reports').orderByChild('timestamp').onValue;
  }

  /// الحصول على البلاغات قيد الانتظار فقط
  static Future<List<Map<String, dynamic>>> getPendingReports() async {
    try {
      final snapshot = await _database.child('reports').get();
      if (!snapshot.exists) return [];

      final reports = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final report = Map<String, dynamic>.from(value as Map);
        report['id'] = key;
        if (report['status'] == 'pending') {
          reports.add(report);
        }
      });

      // ترتيب من الأحدث للأقدم
      reports.sort((a, b) {
        final aTime = a['timestamp'] ?? 0;
        final bTime = b['timestamp'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return reports;
    } catch (e) {
      debugPrint('Error getting pending reports: $e');
      return [];
    }
  }

  /// الحصول على جميع البلاغات
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final snapshot = await _database.child('reports').get();
      if (!snapshot.exists) return [];

      final reports = <Map<String, dynamic>>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final report = Map<String, dynamic>.from(value as Map);
        report['id'] = key;
        reports.add(report);
      });

      // ترتيب من الأحدث للأقدم
      reports.sort((a, b) {
        final aTime = a['timestamp'] ?? 0;
        final bTime = b['timestamp'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return reports;
    } catch (e) {
      debugPrint('Error getting all reports: $e');
      return [];
    }
  }

  /// الحصول على عدد البلاغات قيد الانتظار
  static Future<int> getPendingReportsCount() async {
    try {
      final snapshot = await _database.child('reports').get();
      if (!snapshot.exists) return 0;

      int count = 0;
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final report = Map<String, dynamic>.from(value as Map);
        if (report['status'] == 'pending') {
          count++;
        }
      });

      return count;
    } catch (e) {
      debugPrint('Error getting pending reports count: $e');
      return 0;
    }
  }

  /// تحديث حالة البلاغ
  static Future<bool> updateReportStatus({
    required String reportId,
    required String newStatus,
    String? adminNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'reviewedAt': ServerValue.timestamp,
      };

      if (adminNote != null && adminNote.isNotEmpty) {
        updates['adminNote'] = adminNote;
      }

      await _database.child('reports/$reportId').update(updates);
      debugPrint('✅ Report status updated to: $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating report status: $e');
      return false;
    }
  }

  /// حذف بلاغ
  static Future<bool> deleteReport(String reportId) async {
    try {
      await _database.child('reports/$reportId').remove();
      debugPrint('✅ Report deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting report: $e');
      return false;
    }
  }

  /// ترجمة حالة البلاغ
  static String translateStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'reviewed':
        return 'قيد المراجعة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status ?? 'غير معروف';
    }
  }

  /// الحصول على لون الحالة
  static int getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return 0xFFFFA000; // برتقالي
      case 'reviewed':
        return 0xFF2196F3; // أزرق
      case 'resolved':
        return 0xFF4CAF50; // أخضر
      case 'rejected':
        return 0xFFF44336; // أحمر
      default:
        return 0xFF9E9E9E; // رمادي
    }
  }

  /// الحصول على وصف السبب
  static String getReasonLabel(String reasonId) {
    final reason = reportReasons.firstWhere(
      (r) => r['id'] == reasonId,
      orElse: () => {'label': reasonId},
    );
    return reason['label'] ?? reasonId;
  }
}
