import 'package:flutter/material.dart';

/// فئات الخبرات
class ExperienceCategory {
  static const List<String> categories = [
    'الكل',
    'سيارات',
    'إلكترونيات',
    'عقارات',
    'كهرباء وتكييف',
    'تصميم وبرمجة',
    'تسويق',
    'تعليم',
    'قانون',
    'أخرى',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'سيارات':
        return Icons.directions_car;
      case 'إلكترونيات':
        return Icons.phone_android;
      case 'عقارات':
        return Icons.home;
      case 'كهرباء وتكييف':
        return Icons.electrical_services;
      case 'تصميم وبرمجة':
        return Icons.code;
      case 'تسويق':
        return Icons.campaign;
      case 'تعليم':
        return Icons.school;
      case 'قانون':
        return Icons.gavel;
      default:
        return Icons.work;
    }
  }

  static Color getColor(String category) {
    return const Color(0xFF1976D2); // لون أزرق موحد
  }
}

/// نموذج الخبرة
class Experience {
  final String id;
  final String? expertId;
  final String title;
  final String expertName;
  final String imageUrl;
  final String description;
  final int yearsOfExperience;
  final double rating;
  final int reviewsCount;
  final String category;
  final String phone;
  final bool isAvailable;
  final DateTime createdAt;
  final String? location;
  final double? consultationPrice;
  final double? experiencePrice;
  final String priceUnit; // ساعة، شهر، إلخ
  final List<String> skills;
  final String? userStudies;
  final bool isSaleable;
  final int timestamp;
  final bool isPublic; // هل الخبرة معروضة للعامة في القلعة

  Experience({
    required this.id,
    this.expertId,
    required this.title,
    required this.expertName,
    this.imageUrl = '',
    required this.description,
    required this.yearsOfExperience,
    this.rating = 0.0,
    this.reviewsCount = 0,
    required this.category,
    this.phone = '',
    this.isAvailable = true,
    required this.createdAt,
    this.location,
    this.consultationPrice,
    this.experiencePrice,
    this.priceUnit = 'ساعة',
    this.skills = const [],
    this.userStudies,
    this.isSaleable = true,
    required this.timestamp,
    this.isPublic = true,
  });

  factory Experience.fromMap(String id, Map<dynamic, dynamic> map) {
    return Experience(
      id: id,
      expertId: map['expert_id'],
      title: map['title'] ?? map['category'] ?? '',
      expertName: map['expertName'] ?? map['expert_id'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      yearsOfExperience: map['years_exp'] ?? map['yearsOfExperience'] ?? 0,
      rating: (map['rate'] ?? map['rating'] ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      category: map['category'] ?? 'أخرى',
      phone: map['phone'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] ?? map['createdAt'] ?? 0),
      location: map['location'],
      consultationPrice:
          (map['consultation_price'] ?? map['consultationPrice'] ?? 0)
              .toDouble(),
      experiencePrice: (map['experience_price'] ?? 0).toDouble(),
      priceUnit: map['price_unit'] ?? 'ساعة',
      skills: List<String>.from(map['skills'] ?? []),
      userStudies: map['user_studies'],
      isSaleable: map['is_saleable'] ?? true,
      timestamp: map['timestamp'] ?? 0,
      isPublic: map['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expert_id': expertId,
      'title': title,
      'expertName': expertName,
      'imageUrl': imageUrl,
      'description': description,
      'years_exp': yearsOfExperience,
      'rate': rating,
      'reviewsCount': reviewsCount,
      'category': category,
      'phone': phone,
      'isAvailable': isAvailable,
      'timestamp': timestamp,
      'location': location,
      'consultation_price': consultationPrice,
      'experience_price': experiencePrice,
      'price_unit': priceUnit,
      'skills': skills,
      'user_studies': userStudies,
      'is_saleable': isSaleable,
      'isPublic': isPublic,
    };
  }

  Experience copyWith({
    String? id,
    String? expertId,
    String? title,
    String? expertName,
    String? imageUrl,
    String? description,
    int? yearsOfExperience,
    double? rating,
    int? reviewsCount,
    String? category,
    String? phone,
    bool? isAvailable,
    DateTime? createdAt,
    String? location,
    double? consultationPrice,
    double? experiencePrice,
    String? priceUnit,
    List<String>? skills,
    String? userStudies,
    bool? isSaleable,
    int? timestamp,
    bool? isPublic,
  }) {
    return Experience(
      id: id ?? this.id,
      expertId: expertId ?? this.expertId,
      title: title ?? this.title,
      expertName: expertName ?? this.expertName,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      experiencePrice: experiencePrice ?? this.experiencePrice,
      priceUnit: priceUnit ?? this.priceUnit,
      skills: skills ?? this.skills,
      userStudies: userStudies ?? this.userStudies,
      isSaleable: isSaleable ?? this.isSaleable,
      timestamp: timestamp ?? this.timestamp,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// نص سنوات الخبرة
  String get experienceText {
    if (yearsOfExperience == 1) return 'سنة واحدة';
    if (yearsOfExperience == 2) return 'سنتين';
    if (yearsOfExperience <= 10) return '$yearsOfExperience سنوات';
    return '$yearsOfExperience سنة';
  }
}
