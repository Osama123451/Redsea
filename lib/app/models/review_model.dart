import 'package:flutter/material.dart';

/// نموذج تقييم المستخدم
/// يُستخدم لتقييم المستخدمين بعد إتمام المعاملات
class UserReview {
  final String id;
  final String raterId; // من قام بالتقييم
  final String raterName;
  final String ratedUserId; // المستخدم المُقيَّم
  final double rating; // 1-5 نجوم
  final String comment;
  final DateTime timestamp;

  UserReview({
    required this.id,
    required this.raterId,
    required this.raterName,
    required this.ratedUserId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  /// إنشاء من Map (Firebase)
  factory UserReview.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserReview(
      id: id,
      raterId: map['raterId'] ?? '',
      raterName: map['raterName'] ?? 'مستخدم',
      ratedUserId: map['ratedUserId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// تحويل إلى Map للحفظ في Firebase
  Map<String, dynamic> toMap() {
    return {
      'raterId': raterId,
      'raterName': raterName,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// الحصول على لون التقييم
  Color get ratingColor {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  /// نص التقييم
  String get ratingText {
    if (rating >= 4.5) return 'ممتاز';
    if (rating >= 4) return 'جيد جداً';
    if (rating >= 3) return 'جيد';
    if (rating >= 2) return 'مقبول';
    return 'ضعيف';
  }
}
