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
  }) {
    return Product(
      id: id,
      name: name,
      price: price,
      negotiable: negotiable,
      imageUrl: imageUrl,
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
    );
  }

  // دالة لحساب السعر الإجمالي للمنتج
  double get totalPrice {
    String cleanPrice = price.replaceAll(',', '');
    return (double.tryParse(cleanPrice) ?? 0) * quantity;
  }
}
