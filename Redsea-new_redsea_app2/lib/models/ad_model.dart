class Ad {
  final String id;
  final String productId;
  final String ownerId;
  final String title;
  final String? location;
  final List<String> mediaUrls;
  final String adType; // banner, post, bottom_notes, video
  final String plan; // standard, premium
  final String status; // pending, active, expired
  final String paymentStatus; // unpaid, paid
  final String? targetAudience;
  final double viewersPerDay;
  final int durationDays;
  final double price; // Total price in local currency
  final int timestamp;
  final int updatedAt;
  final int? startTime;

  Ad({
    required this.id,
    required this.productId,
    required this.ownerId,
    required this.title,
    this.location,
    required this.mediaUrls,
    required this.adType,
    required this.plan,
    required this.status,
    required this.paymentStatus,
    this.targetAudience,
    required this.viewersPerDay,
    required this.durationDays,
    required this.price,
    required this.timestamp,
    required this.updatedAt,
    this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'ownerId': ownerId,
      'title': title,
      'location': location,
      'media_urls': mediaUrls,
      'ad_type': adType,
      'plan': plan,
      'status': status,
      'payment_status': paymentStatus,
      'target_audience': targetAudience,
      'viewers_per_day': viewersPerDay,
      'duration_days': durationDays,
      'price': price,
      'timestamp': timestamp,
      'updated_at': updatedAt,
      'start_time': startTime,
    };
  }

  factory Ad.fromMap(Map<dynamic, dynamic> map) {
    return Ad(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      ownerId: map['owner_id'] ?? map['ownerId'] ?? '',
      title: map['title'] ?? '',
      location: map['location'],
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
      adType: map['ad_type'] ?? 'post',
      plan: map['plan'] ?? 'standard',
      status: map['status'] ?? 'pending',
      paymentStatus: map['payment_status'] ?? 'unpaid',
      targetAudience: map['target_audience'],
      viewersPerDay: (map['viewers_per_day'] ?? 0).toDouble(),
      durationDays: map['duration_days'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
      timestamp: map['timestamp'] ?? 0,
      updatedAt: map['updated_at'] ?? 0,
      startTime: map['start_time'],
    );
  }
}
