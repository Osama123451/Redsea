import 'package:flutter/material.dart';
import 'package:redsea/app/core/app_theme.dart';

/// فئات الخدمات
class ServiceCategory {
  static const List<String> categories = [
    'الكل',
    'تصميم',
    'برمجة',
    'تصوير',
    'كتابة وترجمة',
    'تسويق رقمي',
    'صيانة وإصلاح',
    'تدريس وتعليم',
    'إنتاج صوتي ومرئي',
    'أخرى',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'تصميم':
        return Icons.brush;
      case 'برمجة':
        return Icons.code;
      case 'تصوير':
        return Icons.camera_alt;
      case 'كتابة وترجمة':
        return Icons.edit;
      case 'تسويق رقمي':
        return Icons.trending_up;
      case 'صيانة وإصلاح':
        return Icons.build;
      case 'تدريس وتعليم':
        return Icons.school;
      case 'إنتاج صوتي ومرئي':
        return Icons.music_note;
      default:
        return Icons.miscellaneous_services;
    }
  }

  /// الألوان الموحدة لكل الفئات - أزرق موحد
  static Color getColor(String category) {
    // لون أزرق موحد لكل الفئات
    return const Color(0xFF1976D2);
  }

  /// الحصول على تدرج لوني للفئة - أزرق موحد
  static List<Color> getGradient(String category) {
    // تدرج أزرق موحد لكل الفئات
    return [const Color(0xFF1976D2), const Color(0xFF0D47A1)];
  }
}

/// مستويات البائعين
enum SellerLevel {
  beginner, // مبتدئ
  intermediate, // محترف
  expert, // خبير
}

extension SellerLevelExtension on SellerLevel {
  String get arabicName {
    switch (this) {
      case SellerLevel.beginner:
        return 'مبتدئ';
      case SellerLevel.intermediate:
        return 'محترف';
      case SellerLevel.expert:
        return 'خبير';
    }
  }

  Color get color {
    switch (this) {
      case SellerLevel.beginner:
        return Colors.grey;
      case SellerLevel.intermediate:
        return Colors.blue;
      case SellerLevel.expert:
        return Colors.amber;
    }
  }

  IconData get icon {
    switch (this) {
      case SellerLevel.beginner:
        return Icons.star_outline;
      case SellerLevel.intermediate:
        return Icons.star_half;
      case SellerLevel.expert:
        return Icons.star;
    }
  }
}

/// باقة الخدمة
class ServicePackage {
  final String name;
  final String description;
  final double price;
  final String duration;
  final List<String> features;

  ServicePackage({
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.features = const [],
  });

  factory ServicePackage.fromMap(Map<dynamic, dynamic> map) {
    return ServicePackage(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      features: List<String>.from(map['features'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'features': features,
    };
  }
}

/// نموذج الخدمة المحسّن
class Service {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final String category;
  final double estimatedValue;
  final String duration;
  final List<String> images;
  final List<String> swapPreferences;
  final bool isAvailable;
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;

  // حقول جديدة
  final SellerLevel sellerLevel;
  final int completedOrders;
  final double responseRate;
  final String responseTime;
  final List<String> portfolio;
  final List<ServicePackage> packages;
  final bool isFeatured;
  final int viewsCount;
  final bool isFavorite;

  // حقول العروض الخاصة
  final bool isSpecialOffer; // هل عرض خاص
  final double? oldEstimatedValue; // القيمة القديمة قبل الخصم

  // حقول الدفع المخصص
  final String? paymentMethod; // طريقة الدفع (kuraimi, cashu, bank, cod, other)
  final String? paymentAccountNumber; // رقم الحساب/المحفظة
  final String? paymentAccountName; // اسم صاحب الحساب
  final String? paymentInstructions; // تعليمات إضافية للدفع

  Service({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedValue,
    required this.duration,
    this.images = const [],
    this.swapPreferences = const [],
    this.isAvailable = true,
    this.rating = 0,
    this.reviewsCount = 0,
    required this.createdAt,
    // حقول جديدة
    this.sellerLevel = SellerLevel.beginner,
    this.completedOrders = 0,
    this.responseRate = 100,
    this.responseTime = 'خلال ساعة',
    this.portfolio = const [],
    this.packages = const [],
    this.isFeatured = false,
    this.viewsCount = 0,
    this.isFavorite = false,
    // حقول العروض الخاصة
    this.isSpecialOffer = false,
    this.oldEstimatedValue,
    // حقول الدفع
    this.paymentMethod,
    this.paymentAccountNumber,
    this.paymentAccountName,
    this.paymentInstructions,
  });

  factory Service.fromMap(String id, Map<dynamic, dynamic> map) {
    // Parse packages
    List<ServicePackage> packagesList = [];
    if (map['packages'] != null) {
      final packagesData = map['packages'];
      if (packagesData is List) {
        packagesList = packagesData
            .map((p) => ServicePackage.fromMap(Map<dynamic, dynamic>.from(p)))
            .toList();
      }
    }

    return Service(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'أخرى',
      estimatedValue: (map['estimatedValue'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      swapPreferences: List<String>.from(map['swapPreferences'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      // حقول جديدة
      sellerLevel: _parseSellerLevel(map['sellerLevel']),
      completedOrders: map['completedOrders'] ?? 0,
      responseRate: (map['responseRate'] ?? 100).toDouble(),
      responseTime: map['responseTime'] ?? 'خلال ساعة',
      portfolio: List<String>.from(map['portfolio'] ?? []),
      packages: packagesList,
      isFeatured: map['isFeatured'] ?? false,
      viewsCount: map['viewsCount'] ?? 0,
      // حقول العروض الخاصة
      isSpecialOffer: map['isSpecialOffer'] ?? false,
      oldEstimatedValue: map['oldEstimatedValue'] != null
          ? (map['oldEstimatedValue']).toDouble()
          : null,
      // حقول الدفع
      paymentMethod: map['paymentMethod'],
      paymentAccountNumber: map['paymentAccountNumber'],
      paymentAccountName: map['paymentAccountName'],
      paymentInstructions: map['paymentInstructions'],
    );
  }

  static SellerLevel _parseSellerLevel(dynamic value) {
    if (value == null) return SellerLevel.beginner;
    switch (value.toString()) {
      case 'intermediate':
        return SellerLevel.intermediate;
      case 'expert':
        return SellerLevel.expert;
      default:
        return SellerLevel.beginner;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'category': category,
      'estimatedValue': estimatedValue,
      'duration': duration,
      'images': images,
      'swapPreferences': swapPreferences,
      'isAvailable': isAvailable,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      // حقول جديدة
      'sellerLevel': sellerLevel.name,
      'completedOrders': completedOrders,
      'responseRate': responseRate,
      'responseTime': responseTime,
      'portfolio': portfolio,
      'packages': packages.map((p) => p.toMap()).toList(),
      'isFeatured': isFeatured,
      'viewsCount': viewsCount,
      // حقول العروض الخاصة
      'isSpecialOffer': isSpecialOffer,
      'oldEstimatedValue': oldEstimatedValue,
      // حقول الدفع
      'paymentMethod': paymentMethod,
      'paymentAccountNumber': paymentAccountNumber,
      'paymentAccountName': paymentAccountName,
      'paymentInstructions': paymentInstructions,
    };
  }

  Service copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? title,
    String? description,
    String? category,
    double? estimatedValue,
    String? duration,
    List<String>? images,
    List<String>? swapPreferences,
    bool? isAvailable,
    double? rating,
    int? reviewsCount,
    DateTime? createdAt,
    SellerLevel? sellerLevel,
    int? completedOrders,
    double? responseRate,
    String? responseTime,
    List<String>? portfolio,
    List<ServicePackage>? packages,
    bool? isFeatured,
    int? viewsCount,
    bool? isFavorite,
    // حقول العروض الخاصة
    bool? isSpecialOffer,
    double? oldEstimatedValue,
    // حقول الدفع
    String? paymentMethod,
    String? paymentAccountNumber,
    String? paymentAccountName,
    String? paymentInstructions,
  }) {
    return Service(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      duration: duration ?? this.duration,
      images: images ?? this.images,
      swapPreferences: swapPreferences ?? this.swapPreferences,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
      sellerLevel: sellerLevel ?? this.sellerLevel,
      completedOrders: completedOrders ?? this.completedOrders,
      responseRate: responseRate ?? this.responseRate,
      responseTime: responseTime ?? this.responseTime,
      portfolio: portfolio ?? this.portfolio,
      packages: packages ?? this.packages,
      isFeatured: isFeatured ?? this.isFeatured,
      viewsCount: viewsCount ?? this.viewsCount,
      isFavorite: isFavorite ?? this.isFavorite,
      // حقول العروض الخاصة
      isSpecialOffer: isSpecialOffer ?? this.isSpecialOffer,
      oldEstimatedValue: oldEstimatedValue ?? this.oldEstimatedValue,
      // حقول الدفع
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
    );
  }
}

/// نموذج تقييم الخدمة
class ServiceReview {
  final String id;
  final String serviceId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ServiceReview({
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ServiceReview.fromMap(String id, Map<dynamic, dynamic> map) {
    return ServiceReview(
      id: id,
      serviceId: map['serviceId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

/// نموذج طلب تبادل الخدمات
class ServiceSwapRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterServiceId;
  final String requesterServiceTitle;
  final String targetOwnerId;
  final String targetServiceId;
  final String targetServiceTitle;
  final String message;
  final String status; // pending, accepted, rejected, completed, cancelled
  final String? chatId;
  final DateTime timestamp;

  ServiceSwapRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterServiceId,
    required this.requesterServiceTitle,
    required this.targetOwnerId,
    required this.targetServiceId,
    required this.targetServiceTitle,
    this.message = '',
    this.status = 'pending',
    this.chatId,
    required this.timestamp,
  });

  factory ServiceSwapRequest.fromMap(String id, Map<dynamic, dynamic> map) {
    return ServiceSwapRequest(
      id: id,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterServiceId: map['requesterServiceId'] ?? '',
      requesterServiceTitle: map['requesterServiceTitle'] ?? '',
      targetOwnerId: map['targetOwnerId'] ?? '',
      targetServiceId: map['targetServiceId'] ?? '',
      targetServiceTitle: map['targetServiceTitle'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      chatId: map['chatId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterServiceId': requesterServiceId,
      'requesterServiceTitle': requesterServiceTitle,
      'targetOwnerId': targetOwnerId,
      'targetServiceId': targetServiceId,
      'targetServiceTitle': targetServiceTitle,
      'message': message,
      'status': status,
      'chatId': chatId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  String get statusText {
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
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppColors.primaryLight;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
