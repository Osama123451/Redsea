/// نموذج الملف الشخصي العام للمستخدم
/// يُستخدم لعرض معلومات المستخدم للآخرين
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final DateTime joinDate;
  final bool isVerified;
  final double trustScore; // متوسط التقييمات (1-5)
  final int swapsCount; // عدد المقايضات المكتملة
  final int reviewsCount; // عدد التقييمات المستلمة
  final int productsCount; // عدد المنتجات المعروضة
  final String? verificationRejectionReason; // سبب رفض توثيق الحساب إن وجد

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    required this.joinDate,
    this.isVerified = false,
    this.trustScore = 0,
    this.swapsCount = 0,
    this.reviewsCount = 0,
    this.productsCount = 0,
    this.verificationRejectionReason,
  });

  /// إنشاء من Map (Firebase)
  factory UserProfile.fromMap(String id, Map<dynamic, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] ?? 'مستخدم',
      email: map['email'],
      photoUrl: map['photoUrl'],
      joinDate: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ??
            map['joinDate'] ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      isVerified: map['isVerified'] ?? false,
      trustScore: (map['trustScore'] ?? 0).toDouble(),
      swapsCount: map['swapsCount'] ?? 0,
      reviewsCount: map['reviewsCount'] ?? 0,
      productsCount: map['productsCount'] ?? 0,
      verificationRejectionReason: map['verificationRejectionReason'],
    );
  }

  /// تحويل إلى Map للحفظ في Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'joinDate': joinDate.millisecondsSinceEpoch,
      'isVerified': isVerified,
      'trustScore': trustScore,
      'swapsCount': swapsCount,
      'reviewsCount': reviewsCount,
      'productsCount': productsCount,
      'verificationRejectionReason': verificationRejectionReason,
    };
  }

  /// الحرف الأول من الاسم للصورة الافتراضية
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'م';

  /// نص مستوى الثقة
  String get trustLevelText {
    if (trustScore >= 4.5) return 'موثوق جداً';
    if (trustScore >= 4) return 'موثوق';
    if (trustScore >= 3) return 'جيد';
    if (trustScore >= 2) return 'مبتدئ';
    if (trustScore > 0) return 'جديد';
    return 'لا يوجد تقييم';
  }

  /// تنسيق تاريخ الانضمام
  String get formattedJoinDate {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${months[joinDate.month - 1]} ${joinDate.year}';
  }
}
