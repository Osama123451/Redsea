import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';

/// نموذج طلب المقايضة
class SwapRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String targetOwnerId;
  final String targetProductId;
  final String targetProductName;
  final String offeredProductId;
  final String offeredProductName;
  final double additionalMoney;
  final String message;
  final String status; // pending, accepted, rejected, completed, cancelled
  final String? chatId;
  final DateTime timestamp;

  SwapRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.targetOwnerId,
    required this.targetProductId,
    required this.targetProductName,
    required this.offeredProductId,
    required this.offeredProductName,
    this.additionalMoney = 0,
    this.message = '',
    this.status = 'pending',
    this.chatId,
    required this.timestamp,
  });

  factory SwapRequest.fromMap(String id, Map<dynamic, dynamic> map) {
    return SwapRequest(
      id: id,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      targetOwnerId: map['targetOwnerId'] ?? '',
      targetProductId: map['targetProductId'] ?? '',
      targetProductName: map['targetProductName'] ?? '',
      offeredProductId: map['offeredProductId'] ?? '',
      offeredProductName: map['offeredProductName'] ?? '',
      additionalMoney: (map['additionalMoney'] ?? 0).toDouble(),
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
      'targetOwnerId': targetOwnerId,
      'targetProductId': targetProductId,
      'targetProductName': targetProductName,
      'offeredProductId': offeredProductId,
      'offeredProductName': offeredProductName,
      'additionalMoney': additionalMoney,
      'message': message,
      'status': status,
      'chatId': chatId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// نص حالة الطلب
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

  /// لون الحالة
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// متحكم نظام المقايضة
class SwapController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // البيانات المرصودة
  final RxList<Product> swappableProducts = <Product>[].obs;
  final RxList<SwapRequest> incomingRequests = <SwapRequest>[].obs;
  final RxList<SwapRequest> outgoingRequests = <SwapRequest>[].obs;
  final RxBool isLoading = false.obs;

  // فلاتر البحث
  final RxString searchQuery = ''.obs;
  final Rxn<String> selectedCategory = Rxn<String>();
  final Rxn<double> minPrice = Rxn<double>();
  final Rxn<double> maxPrice = Rxn<double>();
  final RxDouble priceRange = 15.0.obs; // نسبة تفاوت السعر
  final RxBool samePrice = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadSwappableProducts();
    if (currentUserId != null) {
      loadSwapRequests();
    }
  }

  /// تحميل المنتجات القابلة للمقايضة
  Future<void> loadSwappableProducts() async {
    isLoading.value = true;
    try {
      final snapshot = await _dbRef.child('products').get();
      if (snapshot.value != null) {
        List<Product> products = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            Product product =
                Product.fromMap(Map<dynamic, dynamic>.from(value));
            // فقط المنتجات القابلة للمقايضة والمتاحة
            if (product.isSwappable &&
                product.swapStatus == SwapStatus.available &&
                product.ownerId != currentUserId) {
              products.add(product);
            }
          } catch (e) {
            debugPrint('Error parsing product: $e');
          }
        });

        // ترتيب حسب الأحدث
        products.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        swappableProducts.value = products;
      }
    } catch (e) {
      debugPrint('Error loading swappable products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// البحث الذكي في المنتجات القابلة للمقايضة
  List<Product> searchSwapProducts({
    String? query,
    String? category,
    double? userProductPrice,
    bool exactPrice = false,
    double priceRangePercent = 15,
  }) {
    List<Product> results = swappableProducts.toList();

    // فلترة حسب النص
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    // فلترة حسب التصنيف
    if (category != null && category.isNotEmpty && category != 'الكل') {
      results = results.where((p) => p.category == category).toList();
    }

    // فلترة حسب السعر المقارب لمنتج المستخدم
    if (userProductPrice != null) {
      if (exactPrice) {
        // نفس السعر تماماً (±5%)
        double minP = userProductPrice * 0.95;
        double maxP = userProductPrice * 1.05;
        results = results
            .where((p) => p.priceAsDouble >= minP && p.priceAsDouble <= maxP)
            .toList();
      } else {
        // في نطاق معين
        double minP = userProductPrice * (1 - priceRangePercent / 100);
        double maxP = userProductPrice * (1 + priceRangePercent / 100);
        results = results
            .where((p) => p.priceAsDouble >= minP && p.priceAsDouble <= maxP)
            .toList();
      }
    }

    return results;
  }

  /// مقارنة الأسعار وتحديد نوع المقايضة
  SwapPriceComparison comparePrice(double userPrice, double targetPrice) {
    double diff = targetPrice - userPrice;
    double percentage = (diff.abs() / userPrice) * 100;

    if (percentage <= 5) {
      return SwapPriceComparison.equal;
    } else if (diff > 0) {
      return SwapPriceComparison.higher;
    } else {
      return SwapPriceComparison.lower;
    }
  }

  /// تحميل طلبات المقايضة
  Future<void> loadSwapRequests() async {
    if (currentUserId == null) return;

    try {
      // الطلبات الواردة
      final incomingSnapshot = await _dbRef
          .child('swap_requests')
          .orderByChild('targetOwnerId')
          .equalTo(currentUserId)
          .get();

      if (incomingSnapshot.value != null) {
        List<SwapRequest> requests = [];
        Map<dynamic, dynamic> data =
            incomingSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          requests
              .add(SwapRequest.fromMap(key, Map<dynamic, dynamic>.from(value)));
        });
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        incomingRequests.value = requests;
      }

      // الطلبات الصادرة
      final outgoingSnapshot = await _dbRef
          .child('swap_requests')
          .orderByChild('requesterId')
          .equalTo(currentUserId)
          .get();

      if (outgoingSnapshot.value != null) {
        List<SwapRequest> requests = [];
        Map<dynamic, dynamic> data =
            outgoingSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          requests
              .add(SwapRequest.fromMap(key, Map<dynamic, dynamic>.from(value)));
        });
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        outgoingRequests.value = requests;
      }
    } catch (e) {
      debugPrint('Error loading swap requests: $e');
    }
  }

  /// إرسال طلب مقايضة
  Future<bool> sendSwapRequest({
    required Product targetProduct,
    required Product offeredProduct,
    double additionalMoney = 0,
    String message = '',
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      // الحصول على اسم المستخدم
      final userSnapshot =
          await _dbRef.child('users/$currentUserId/name').get();
      String requesterName = userSnapshot.value?.toString() ?? 'مستخدم';

      // إنشاء الطلب
      final requestRef = _dbRef.child('swap_requests').push();
      final request = SwapRequest(
        id: requestRef.key!,
        requesterId: currentUserId!,
        requesterName: requesterName,
        targetOwnerId: targetProduct.ownerId!,
        targetProductId: targetProduct.id,
        targetProductName: targetProduct.name,
        offeredProductId: offeredProduct.id,
        offeredProductName: offeredProduct.name,
        additionalMoney: additionalMoney,
        message: message,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await requestRef.set(request.toMap());

      // تحديث حالة المنتجين
      await _dbRef
          .child('products/${targetProduct.id}/swapStatus')
          .set(SwapStatus.inSwap.index);
      await _dbRef
          .child('products/${offeredProduct.id}/swapStatus')
          .set(SwapStatus.inSwap.index);

      // إرسال إشعار
      _sendNotification(
        targetProduct.ownerId!,
        'طلب مقايضة جديد',
        '$requesterName يريد مقايضة "${offeredProduct.name}" مقابل "${targetProduct.name}"',
      );

      // تحديث القوائم
      await loadSwapRequests();
      await loadSwappableProducts();

      Get.snackbar('نجاح', 'تم إرسال طلب المقايضة');
      return true;
    } catch (e) {
      debugPrint('Error sending swap request: $e');
      Get.snackbar('خطأ', 'فشل في إرسال الطلب');
      return false;
    }
  }

  /// قبول طلب مقايضة
  Future<bool> acceptSwapRequest(SwapRequest request) async {
    try {
      // 1. تحديث حالة الطلب
      await _dbRef.child('swap_requests/${request.id}/status').set('accepted');

      // 2. إنشاء محادثة بين الطرفين
      final chatId = await _createSwapChat(request);

      // 3. تحديث الطلب بمعرف المحادثة
      if (chatId != null) {
        await _dbRef.child('swap_requests/${request.id}/chatId').set(chatId);
      }

      // 4. إرسال إشعار
      _sendNotification(
        request.requesterId,
        'تم قبول طلب المقايضة! 🎉',
        'تم قبول طلبك لمقايضة "${request.offeredProductName}"، يمكنك الآن التواصل عبر المحادثة.',
      );

      await loadSwapRequests();
      Get.snackbar('نجاح', 'تم قبول الطلب وإنشاء محادثة');
      return true;
    } catch (e) {
      debugPrint('Error in acceptSwapRequest: $e');
      Get.snackbar('خطأ', 'فشل في قبول الطلب');
      return false;
    }
  }

  /// إنشاء محادثة للمقايضة
  Future<String?> _createSwapChat(SwapRequest request) async {
    try {
      // التحقق من وجود محادثة سابقة (اختياري، هنا ننشئ واحدة جديدة أو نستخدم chat_service)
      final chatRef = _dbRef.child('chats').push();
      final chatId = chatRef.key;

      const timestamp = ServerValue.timestamp;

      // بيانات المحادثة
      await chatRef.set({
        'user1Id': request.requesterId,
        'user2Id': request.targetOwnerId,
        'user1Name': request.requesterName,
        'user2Name': 'صاحب المنتج', // سيتم تحديثه عند الفتح أو جلبه الآن
        'lastMessage': {
          'text': 'تم قبول طلب المقايضة لـ ${request.targetProductName}',
          'senderId': 'system',
          'timestamp': timestamp,
        },
        'lastMessageTime': timestamp,
        'isSwapChat': true,
        'swapRequestId': request.id,
      });

      // إضافة المحادثة لقائمة محادثات المستخدمين
      await _dbRef
          .child('user_chats/${request.requesterId}/$chatId')
          .set(timestamp);
      await _dbRef
          .child('user_chats/${request.targetOwnerId}/$chatId')
          .set(timestamp);

      // إرسال رسالة ترحيبية تلقائية
      final messageRef = _dbRef.child('messages/$chatId').push();
      await messageRef.set({
        'senderId': 'system',
        'text': 'تم بدء المحادثة بخصوص طلب المقايضة رقم ${request.id}',
        'type': 'text',
        'timestamp': timestamp,
      });

      return chatId;
    } catch (e) {
      debugPrint('Error creating swap chat: $e');
      return null;
    }
  }

  /// رفض طلب مقايضة
  Future<bool> rejectSwapRequest(SwapRequest request, {String? reason}) async {
    try {
      await _dbRef.child('swap_requests/${request.id}/status').set('rejected');

      // إعادة حالة المنتجات للمتاح
      await _dbRef
          .child('products/${request.targetProductId}/swapStatus')
          .set(SwapStatus.available.index);
      await _dbRef
          .child('products/${request.offeredProductId}/swapStatus')
          .set(SwapStatus.available.index);

      // إرسال إشعار
      _sendNotification(
        request.requesterId,
        'تم رفض طلب المقايضة',
        reason ?? 'تم رفض طلبك لمقايضة "${request.offeredProductName}"',
      );

      await loadSwapRequests();
      await loadSwappableProducts();
      Get.snackbar('تم', 'تم رفض طلب المقايضة');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في رفض الطلب');
      return false;
    }
  }

  /// إتمام المقايضة
  Future<bool> completeSwap(SwapRequest request) async {
    try {
      await _dbRef.child('swap_requests/${request.id}/status').set('completed');

      // تحديث حالة المنتجات
      await _dbRef
          .child('products/${request.targetProductId}/swapStatus')
          .set(SwapStatus.swapped.index);
      await _dbRef
          .child('products/${request.offeredProductId}/swapStatus')
          .set(SwapStatus.swapped.index);

      // إرسال إشعارات لكلا الطرفين
      _sendNotification(
        request.requesterId,
        'تمت المقايضة بنجاح! 🎉',
        'اكتملت عملية مقايضة "${request.offeredProductName}"',
      );
      _sendNotification(
        request.targetOwnerId,
        'تمت المقايضة بنجاح! 🎉',
        'اكتملت عملية مقايضة "${request.targetProductName}"',
      );

      await loadSwapRequests();
      await loadSwappableProducts();
      Get.snackbar('نجاح', 'تمت المقايضة بنجاح!');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إتمام المقايضة');
      return false;
    }
  }

  /// إلغاء طلب مقايضة
  Future<bool> cancelSwapRequest(SwapRequest request) async {
    try {
      await _dbRef.child('swap_requests/${request.id}/status').set('cancelled');

      // إعادة حالة المنتجات للمتاح
      await _dbRef
          .child('products/${request.targetProductId}/swapStatus')
          .set(SwapStatus.available.index);
      await _dbRef
          .child('products/${request.offeredProductId}/swapStatus')
          .set(SwapStatus.available.index);

      await loadSwapRequests();
      await loadSwappableProducts();
      Get.snackbar('تم', 'تم إلغاء طلب المقايضة');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إلغاء الطلب');
      return false;
    }
  }

  /// إرسال إشعار
  void _sendNotification(String userId, String title, String body) {
    try {
      // حفظ الإشعار في قاعدة البيانات
      _dbRef.child('notifications/$userId').push().set({
        'title': title,
        'message': body,
        'type': 'swap',
        'timestamp': ServerValue.timestamp,
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// عدد الطلبات الواردة المعلقة
  int get pendingRequestsCount {
    return incomingRequests.where((r) => r.status == 'pending').length;
  }
}

/// نتيجة مقارنة الأسعار
enum SwapPriceComparison {
  equal, // متساوية القيمة
  higher, // المنتج المستهدف أعلى قيمة
  lower, // المنتج المستهدف أقل قيمة
}
