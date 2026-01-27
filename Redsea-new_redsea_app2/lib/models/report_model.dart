/// نموذج بيانات التقارير والإحصائيات
class UserReport {
  // إحصائيات الطلبات (كمشتري)
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double totalSpent;

  // إحصائيات المقايضات
  final int totalSwaps;
  final int successfulSwaps;
  final int pendingSwaps;
  final int rejectedSwaps;
  final double swapValue;

  // إحصائيات المبيعات (كبائع)
  final int totalSales;
  final int completedSales;
  final double totalEarnings;
  final double averageRating;
  final int reviewsCount;

  // إحصائيات الخدمات
  final int serviceOrdersBought;
  final int serviceOrdersSold;
  final double serviceSpending;
  final double serviceEarnings;

  // منتجاتي وخدماتي (العدد الإجمالي)
  final int myProductsCount;
  final int myServicesCount;

  // بيانات الرسوم البيانية (نشاط عبر الزمن)
  final List<ActivityPoint> activityTimeline;
  final List<ActivityPoint> salesTimeline;
  final List<ActivityPoint> ratingTimeline;

  // الفترة الزمنية
  final DateTime startDate;
  final DateTime endDate;

  UserReport({
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.pendingOrders = 0,
    this.cancelledOrders = 0,
    this.totalSpent = 0,
    this.totalSwaps = 0,
    this.successfulSwaps = 0,
    this.pendingSwaps = 0,
    this.rejectedSwaps = 0,
    this.swapValue = 0,
    this.totalSales = 0,
    this.completedSales = 0,
    this.totalEarnings = 0,
    this.averageRating = 0,
    this.reviewsCount = 0,
    this.serviceOrdersBought = 0,
    this.serviceOrdersSold = 0,
    this.serviceSpending = 0,
    this.serviceEarnings = 0,
    this.myProductsCount = 0,
    this.myServicesCount = 0,
    this.activityTimeline = const [],
    this.salesTimeline = const [],
    this.ratingTimeline = const [],
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate =
            startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate = endDate ?? DateTime.now();

  /// إجمالي الإيرادات الصافية
  double get netEarnings =>
      totalEarnings + serviceEarnings - totalSpent - serviceSpending;

  /// نسبة الطلبات المكتملة
  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;

  /// نسبة المقايضات الناجحة
  double get swapSuccessRate =>
      totalSwaps > 0 ? (successfulSwaps / totalSwaps) * 100 : 0;
}

/// نقطة نشاط للرسم البياني
class ActivityPoint {
  final DateTime date;
  final double value;
  final String? label;

  ActivityPoint({
    required this.date,
    required this.value,
    this.label,
  });

  /// تحويل من Map
  factory ActivityPoint.fromMap(Map<String, dynamic> map) {
    return ActivityPoint(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      value: (map['value'] ?? 0).toDouble(),
      label: map['label'],
    );
  }
}

/// فترات التقارير
enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  last3Months,
  thisYear,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get arabicName {
    switch (this) {
      case ReportPeriod.today:
        return 'اليوم';
      case ReportPeriod.thisWeek:
        return 'هذا الأسبوع';
      case ReportPeriod.thisMonth:
        return 'هذا الشهر';
      case ReportPeriod.last3Months:
        return 'آخر 3 أشهر';
      case ReportPeriod.thisYear:
        return 'هذه السنة';
      case ReportPeriod.custom:
        return 'مخصص';
    }
  }

  /// الحصول على تاريخ البداية للفترة
  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.last3Months:
        return DateTime(now.year, now.month - 3, now.day);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.custom:
        return now.subtract(const Duration(days: 30));
    }
  }

  DateTime get endDate => DateTime.now();
}
