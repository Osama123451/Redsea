import 'dart:convert';
import 'package:flutter/material.dart';

/// أنواع المقايضة المتاحة
enum SwapType {
  productProduct, // منتج مقابل منتج
  productService, // منتج مقابل خدمة
  serviceService, // خدمة مقابل خدمة
  productMoney, // منتج + مبلغ مالي
}

/// حالة المنتج
enum ProductCondition {
  newProduct, // جديد
  usedGood, // مستعمل - حالة جيدة
  usedFair, // مستعمل - حالة متوسطة
}

/// حالة المقايضة
enum SwapStatus {
  available, // متاح للمقايضة
  inSwap, // قيد التفاوض
  swapped, // تمت المقايضة
}

class Product {
  final String id;
  final String name;
  final String price;
  final bool negotiable;
  final String imageUrl;
  final List<String>? images;
  final String? imageBase64;
  final String? imageType;
  final String description;
  final String category;
  final DateTime dateAdded;
  final String? ownerId;
  int quantity;

  // حقول المقايضة الجديدة
  final bool isSwappable; // هل قابل للمقايضة
  final SwapType? swapType; // نوع المقايضة المفضل
  final bool isService; // هل هو خدمة أم منتج
  final ProductCondition? condition; // حالة المنتج
  final String? location; // الموقع الجغرافي
  final SwapStatus swapStatus; // حالة المقايضة الحالية

  // حقول العروض الخاصة
  final bool isSpecialOffer; // هل عرض خاص
  final String? oldPrice; // السعر القديم قبل الخصم

  // حقول المنتجات المميزة
  final int viewsCount; // عدد المشاهدات
  final int salesCount; // عدد المبيعات
  final double rating; // التقييم (0-5)
  final int reviewsCount; // عدد التقييمات
  final bool isFeatured; // تحديد يدوي كمميز (من Admin)

  // حقول الدفع المخصص
  final String? paymentMethod; // طريقة الدفع (kuraimi, cashu, bank, cod, other)
  final String? paymentAccountNumber; // رقم الحساب/المحفظة
  final String? paymentAccountName; // اسم صاحب الحساب
  final String? paymentInstructions; // تعليمات إضافية للدفع
  final Map<String, dynamic>? specifications; // مواصفات خاصة حسب التصنيف
  final bool isApproved; // هل المنتج معتمد من قبل المشرف
  final String? rejectionReason; // سبب رفض المنتج إن وجد
  final bool isPublic; // هل المنتج معروض للعامة في المتجر

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.negotiable,
    this.imageUrl = '',
    this.imageBase64,
    this.imageType,
    this.description = '',
    this.category = 'عام',
    required this.dateAdded,
    this.ownerId,
    this.quantity = 1,
    // حقول المقايضة
    this.isSwappable = false,
    this.swapType,
    this.isService = false,
    this.condition,
    this.location,
    this.swapStatus = SwapStatus.available,
    // حقول العروض الخاصة
    this.isSpecialOffer = false,
    this.oldPrice,
    // حقول المنتجات المميزة
    this.viewsCount = 0,
    this.salesCount = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isFeatured = false,
    // حقول الدفع
    this.paymentMethod,
    this.paymentAccountNumber,
    this.paymentAccountName,
    this.paymentInstructions,
    this.specifications,
    this.images,
    this.isApproved = false,
    this.rejectionReason,
    this.isPublic = true,
  });

  // دالة مساعدة للحصول على الصورة
  ImageProvider get imageProvider {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return MemoryImage(base64Decode(imageBase64!));
    } else if (imageUrl.isNotEmpty) {
      return NetworkImage(imageUrl);
    } else {
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  /// الحصول على السعر كرقم
  double get priceAsDouble {
    return double.tryParse(price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  /// حساب درجة التميز للمنتج
  /// المعادلة: (التقييم × 20) + (المبيعات × 2) + (المشاهدات × 0.01) + (مميز يدوياً × 50)
  double get featuredScore {
    double score = (rating * 20) + (salesCount * 2) + (viewsCount * 0.01);
    if (isFeatured) score += 50;
    return score;
  }

  /// نص حالة المنتج
  String get conditionText {
    switch (condition) {
      case ProductCondition.newProduct:
        return 'جديد';
      case ProductCondition.usedGood:
        return 'مستعمل - جيد';
      case ProductCondition.usedFair:
        return 'مستعمل - متوسط';
      default:
        return 'غير محدد';
    }
  }

  /// نص نوع المقايضة
  String get swapTypeText {
    switch (swapType) {
      case SwapType.productProduct:
        return 'منتج مقابل منتج';
      case SwapType.productService:
        return 'منتج مقابل خدمة';
      case SwapType.serviceService:
        return 'خدمة مقابل خدمة';
      case SwapType.productMoney:
        return 'منتج + مبلغ';
      default:
        return 'غير محدد';
    }
  }

  /// نص حالة المقايضة
  String get swapStatusText {
    switch (swapStatus) {
      case SwapStatus.available:
        return 'متاح';
      case SwapStatus.inSwap:
        return 'قيد التفاوض';
      case SwapStatus.swapped:
        return 'تمت المقايضة';
    }
  }

  // دالة لنسخ المنتج مع تحديثات
  Product copyWith({
    int? quantity,
    SwapStatus? swapStatus,
    bool? isSwappable,
    bool? isSpecialOffer,
    int? viewsCount,
    int? salesCount,
    double? rating,
    int? reviewsCount,
    bool? isFeatured,
    String? oldPrice,
    // حقول الدفع
    String? paymentMethod,
    String? paymentAccountNumber,
    String? paymentAccountName,
    String? paymentInstructions,
    Map<String, dynamic>? specifications,
    bool? isApproved,
    String? rejectionReason,
    bool? isPublic,
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      negotiable: negotiable,
      imageUrl: imageUrl,
      images: images,
      imageBase64: imageBase64,
      imageType: imageType,
      description: description,
      category: category,
      dateAdded: dateAdded,
      ownerId: ownerId,
      quantity: quantity ?? this.quantity,
      isSwappable: isSwappable ?? this.isSwappable,
      swapType: swapType,
      isService: isService,
      condition: condition,
      location: location,
      swapStatus: swapStatus ?? this.swapStatus,
      isSpecialOffer: isSpecialOffer ?? this.isSpecialOffer,
      oldPrice: oldPrice ?? this.oldPrice,
      // حقول المميزة
      viewsCount: viewsCount ?? this.viewsCount,
      salesCount: salesCount ?? this.salesCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isFeatured: isFeatured ?? this.isFeatured,
      // حقول الدفع
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAccountNumber: paymentAccountNumber ?? this.paymentAccountNumber,
      paymentAccountName: paymentAccountName ?? this.paymentAccountName,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      specifications: specifications ?? this.specifications,
      isApproved: isApproved ?? this.isApproved,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // دالة لتحويل الكائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'negotiable': negotiable,
      'imageUrl': imageUrl,
      'images': images,
      'imageBase64': imageBase64,
      'imageType': imageType,
      'description': description,
      'category': category,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'userId': ownerId,
      'quantity': quantity,
      // حقول المقايضة
      'isSwappable': isSwappable,
      'swapType': swapType?.index,
      'isService': isService,
      'condition': condition?.index,
      'location': location,
      'swapStatus': swapStatus.index,
      // حقول العروض الخاصة
      'isSpecialOffer': isSpecialOffer,
      'oldPrice': oldPrice,
      // حقول المميزة
      'viewsCount': viewsCount,
      'salesCount': salesCount,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isFeatured': isFeatured,
      // حقول الدفع
      // حقول الدفع
      'paymentMethod': paymentMethod,
      'paymentAccountNumber': paymentAccountNumber,
      'paymentAccountName': paymentAccountName,
      'paymentInstructions': paymentInstructions,
      'specifications': specifications,
      'isApproved': isApproved,
      'rejectionReason': rejectionReason,
      'isPublic': isPublic,
    };
  }

  // دالة لإنشاء كائن من Map
  factory Product.fromMap(Map<dynamic, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toString() ?? '0',
      negotiable: map['isNegotiable'] ?? map['negotiable'] ?? false,
      imageUrl: map['imageUrl'] ?? '',
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      imageBase64: map['imageBase64'],
      imageType: map['imageType'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'عام',
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? map['dateAdded'] ?? 0),
      ownerId: map['sellerId'] ?? map['userId'] ?? map['ownerId'],
      quantity: map['quantity'] ?? 1,
      // حقول المقايضة
      isSwappable: map['isSwappable'] ?? false,
      swapType:
          map['swapType'] != null ? SwapType.values[map['swapType']] : null,
      isService: map['isService'] ?? false,
      condition: map['condition'] != null
          ? ProductCondition.values[map['condition']]
          : null,
      location: map['location'],
      swapStatus: map['swapStatus'] != null
          ? SwapStatus.values[map['swapStatus']]
          : SwapStatus.available,
      // حقول العروض الخاصة
      isSpecialOffer: map['isSpecialOffer'] ?? false,
      oldPrice: map['oldPrice'],
      // حقول المميزة
      viewsCount: map['viewsCount'] ?? 0,
      salesCount: map['salesCount'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      // حقول الدفع
      paymentMethod: map['paymentMethod'],
      paymentAccountNumber: map['paymentAccountNumber'],
      paymentAccountName: map['paymentAccountName'],
      paymentInstructions: map['paymentInstructions'],
      specifications: map['specifications'] != null
          ? Map<String, dynamic>.from(map['specifications'])
          : null,
      isApproved: map['isApproved'] ?? false,
      rejectionReason: map['rejectionReason'],
      isPublic: map['isPublic'] ?? true,
    );
  }

  // دالة لحساب السعر الإجمالي للمنتج
  double get totalPrice {
    String cleanPrice = price.replaceAll(',', '');
    return (double.tryParse(cleanPrice) ?? 0) * quantity;
  }
}
