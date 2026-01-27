import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/product_model.dart';
import 'package:redsea/app/core/app_theme.dart';

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
      requesterId: map['requesterId']?.toString() ?? '',
      requesterName: map['requesterName']?.toString() ?? '',
      targetOwnerId: map['targetOwnerId']?.toString() ?? '',
      targetProductId: map['targetProductId']?.toString() ?? '',
      targetProductName: map['targetProductName']?.toString() ?? '',
      offeredProductId: map['offeredProductId']?.toString() ?? '',
      offeredProductName: map['offeredProductName']?.toString() ?? '',
      additionalMoney:
          double.tryParse(map['additionalMoney']?.toString() ?? '0') ?? 0.0,
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      chatId: map['chatId']?.toString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(map['timestamp']?.toString() ?? '0') ?? 0),
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
        return AppColors.primaryLight;
      case 'accepted':
        return AppColors.primary;
      case 'rejected':
        return AppColors.primaryDark;
      case 'completed':
        return AppColors.primary;
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

  // Internal lists to separate sources
  final List<SwapRequest> _liveIncoming = [];
  final List<SwapRequest> _archivedIncoming = [];
  final List<SwapRequest> _liveOutgoing = [];
  final List<SwapRequest> _archivedOutgoing = [];

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _archivedIncomingSub;
  StreamSubscription? _archivedOutgoingSub;

  // Auth listener to handle user state changes
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes to ensure we load data once user is ready
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint(
            'SwapController: Auth state changed. User ${user.uid} is signed in. Reloading requests...');
        loadSwapRequests();
      } else {
        debugPrint('SwapController: Auth state changed. User signed out.');
        swappableProducts.clear();
        incomingRequests.clear();
        outgoingRequests.clear();
      }
    });
  }

  @override
  void onClose() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _archivedIncomingSub?.cancel();
    _archivedOutgoingSub?.cancel();
    _authSubscription?.cancel();
    super.onClose();
  }

  void _updatePublicIncoming() {
    // Merge live and archived, preferring live if duplicates exist (though they shouldn't usually conflict in fields)
    final Map<String, SwapRequest> uniqueRequests = {};

    // Add archived first
    for (var r in _archivedIncoming) {
      uniqueRequests[r.id] = r;
    }
    // Add live (overwriting archived if same ID, assuming live 'swap_requests' is current)
    for (var r in _liveIncoming) {
      uniqueRequests[r.id] = r;
    }

    final sorted = uniqueRequests.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    incomingRequests.value = sorted;
  }

  void _updatePublicOutgoing() {
    final Map<String, SwapRequest> uniqueRequests = {};

    for (var r in _archivedOutgoing) {
      uniqueRequests[r.id] = r;
    }
    for (var r in _liveOutgoing) {
      uniqueRequests[r.id] = r;
    }

    final sorted = uniqueRequests.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    outgoingRequests.value = sorted;
  }

  /// الاستماع لطلبات المقايضة (Real-time)
  void _startListeningToSwapRequests() {
    if (currentUserId == null) {
      debugPrint(
          'SwapController: No current user found. Cannot listen to requests.');
      return;
    }

    // Cancel existing subscriptions if any to avoid duplicates or listening to wrong user
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _archivedIncomingSub?.cancel();
    _archivedOutgoingSub?.cancel();

    debugPrint('SwapController: Starting listener for User ID: $currentUserId');

    // 1. الطلبات الواردة (Live) - حيث أنا صاحب المنتج "targetOwnerId"
    debugPrint(
        'SwapController: Listening for Incoming Requests (targetOwnerId=$currentUserId)');
    final incomingQuery = _dbRef
        .child('swap_requests')
        .orderByChild('targetOwnerId')
        .equalTo(currentUserId);

    _incomingSub = incomingQuery.onValue.listen((event) {
      _liveIncoming.clear();
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        debugPrint(
            'SwapController: Incoming Live Data received: ${event.snapshot.children.length} items');
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            try {
              _liveIncoming.add(SwapRequest.fromMap(key, value));
            } catch (e) {
              debugPrint('Error parsing incoming request $key: $e');
            }
          }
        });
      } else {
        debugPrint('SwapController: No Incoming Live Data found.');
      }
      _updatePublicIncoming();
    }, onError: (e) {
      debugPrint('Error listening to incoming swap requests: $e');
    });

    // 2. الطلبات الصادرة (Live) - حيث أنا الطالب "requesterId"
    debugPrint(
        'SwapController: Listening for Outgoing Requests (requesterId=$currentUserId)');
    final outgoingQuery = _dbRef
        .child('swap_requests')
        .orderByChild('requesterId')
        .equalTo(currentUserId);

    _outgoingSub = outgoingQuery.onValue.listen((event) {
      _liveOutgoing.clear();
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        debugPrint(
            'SwapController: Outgoing Live Data received: ${event.snapshot.children.length} items');
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            try {
              _liveOutgoing.add(SwapRequest.fromMap(key, value));
            } catch (e) {
              debugPrint('Error parsing outgoing request $key: $e');
            }
          }
        });
      } else {
        debugPrint('SwapController: No Outgoing Live Data found.');
      }
      _updatePublicOutgoing();
    }, onError: (e) {
      debugPrint('Error listening to outgoing swap requests: $e');
    });

    // 3. المقايضات المكتملة (Archived - Incoming)
    final completedIncomingQuery = _dbRef
        .child('completed_swaps')
        .orderByChild('receiver_user_id')
        .equalTo(currentUserId);

    _archivedIncomingSub = completedIncomingQuery.onValue.listen((event) {
      _archivedIncoming.clear();
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        debugPrint('SwapController: Archived Incoming Data received.');
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && value['original_request'] != null) {
            try {
              _archivedIncoming.add(SwapRequest.fromMap(
                  key, Map<dynamic, dynamic>.from(value['original_request'])));
            } catch (e) {
              debugPrint('Error parsing archived incoming: $e');
            }
          }
        });
      }
      _updatePublicIncoming();
    });

    // 4. المقايضات المكتملة (Archived - Outgoing)
    final completedOutgoingQuery = _dbRef
        .child('completed_swaps')
        .orderByChild('sender_user_id')
        .equalTo(currentUserId);

    _archivedOutgoingSub = completedOutgoingQuery.onValue.listen((event) {
      _archivedOutgoing.clear();
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        debugPrint('SwapController: Archived Outgoing Data received.');
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map && value['original_request'] != null) {
            try {
              _archivedOutgoing.add(SwapRequest.fromMap(
                  key, Map<dynamic, dynamic>.from(value['original_request'])));
            } catch (e) {
              debugPrint('Error parsing archived outgoing: $e');
            }
          }
        });
      }
      _updatePublicOutgoing();
    });
  }

  Future<void> loadSwapRequests() async {
    // Always ensuring we are listening when this is called,
    // especially if the user context might have changed or first load.
    // _startListeningToSwapRequests handles duplicates/cancellation internally.
    _startListeningToSwapRequests();

    await loadSwappableProducts();
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

    if (targetProduct.ownerId == null || targetProduct.ownerId!.isEmpty) {
      Get.snackbar('خطأ', 'لا يمكن تحديد صاحب المنتج المستهدف');
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

      // إرسال إشعار لصاحب المنتج المستهدف (الطرف الآخر)
      _sendNotification(
        targetProduct.ownerId!,
        'طلب مقايضة جديد 🔄',
        '$requesterName يريد مقايضة "${offeredProduct.name}" مقابل "${targetProduct.name}"',
        data: {'type': 'swap_incoming', 'requestId': requestRef.key},
      );

      // إرسال إشعار للطالب (تأكيد الطلب) - ليظهر في صفحة الإشعارات كـ Pending
      _sendNotification(
        currentUserId!,
        'تم إرسال الطلب ⏳',
        'طلب مقايضة "${offeredProduct.name}" مقابل "${targetProduct.name}" قيد الانتظار',
        data: {'type': 'swap_outgoing', 'requestId': requestRef.key},
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

  /// قبول طلب مقايضة وإتمامه مباشرة
  Future<bool> acceptSwapRequest(SwapRequest request) async {
    try {
      // 1. إنشاء محادثة بين الطرفين (للتوثيق والتاريخ)
      final chatId = await _createSwapChat(request);

      // 2. تحديث الطلب بمعرف المحادثة إذا تم إنشاؤها
      if (chatId != null) {
        await _dbRef.child('swap_requests/${request.id}/chatId').set(chatId);
      }

      // 3. إتمام المقايضة فوراً ونقل الملكية
      return await completeSwap(request);
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
      // 1. إنشاء سجل في جدول completed_swaps
      final completedSwapRef =
          _dbRef.child('completed_swaps').child(request.id);
      await completedSwapRef.set({
        'sender_user_id': request.requesterId,
        'receiver_user_id': request.targetOwnerId,
        'offered_product_id': request.offeredProductId,
        'target_product_id': request.targetProductId,
        'timestamp': ServerValue.timestamp,
        'original_request': request.toMap(),
      });

      // 2. تحديث حالة الطلب الأصلي
      await _dbRef.child('swap_requests/${request.id}/status').set('completed');

      // 3. نقل الملكية وتغيير الحالة (Swap Logic Core)

      // المنتج المستهدف (كان ملك TargetOwner -> يصير ملك Requester)
      final targetProductUpdates = {
        'ownerId': request.requesterId, // نقل الملكية
        'userId': request.requesterId, // للحفاظ على التوافق مع النماذج القديمة
        'sellerId': request.requesterId, // للحفاظ على التوافق
        'swapStatus': SwapStatus.available.index, // إعادة اتاحته للمقايضة
        'location': null, // قد يحتاج لتحديث، سنتركه حالياً
      };

      await _dbRef
          .child('products/${request.targetProductId}')
          .update(targetProductUpdates);

      // المنتج المعروض (كان ملك Requester -> يصير ملك TargetOwner)
      final offeredProductUpdates = {
        'ownerId': request.targetOwnerId, // نقل الملكية
        'userId': request.targetOwnerId,
        'sellerId': request.targetOwnerId,
        'swapStatus': SwapStatus.available.index, // إعادة اتاحته للمقايضة
      };

      await _dbRef
          .child('products/${request.offeredProductId}')
          .update(offeredProductUpdates);

      // إرسال إشعارات لكلا الطرفين
      _sendNotification(
        request.requesterId,
        'تمت المقايضة بنجاح! 🎉',
        'أصبح منتج "${request.targetProductName}" ملكاً لك الآن!',
      );
      _sendNotification(
        request.targetOwnerId,
        'تمت المقايضة بنجاح! 🎉',
        'أصبح منتج "${request.offeredProductName}" ملكاً لك الآن!',
      );

      await loadSwapRequests();
      await loadSwappableProducts();
      Get.snackbar('نجاح', 'تمت المقايضة ونقل الملكية بنجاح!');
      return true;
    } catch (e) {
      debugPrint('Error completing swap: $e');
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
  void _sendNotification(String userId, String title, String body,
      {Map<String, dynamic>? data}) {
    try {
      // حفظ الإشعار في قاعدة البيانات
      _dbRef.child('notifications/$userId').push().set({
        'title': title,
        'message': body,
        'type': 'swap',
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        if (data != null) ...data,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// عدد الطلبات الواردة المعلقة
  int get pendingRequestsCount {
    return incomingRequests.where((r) => r.status == 'pending').length;
  }

  /// تحديث رؤية المنتج (عام/خاص)
  Future<void> updateProductVisibility(String productId, bool isPublic) async {
    try {
      await _dbRef.child('products/$productId/isPublic').set(isPublic);
      debugPrint('✅ Product $productId visibility updated to: $isPublic');
    } catch (e) {
      debugPrint('❌ Error updating product visibility: $e');
    }
  }
}

/// نتيجة مقارنة الأسعار
enum SwapPriceComparison {
  equal, // متساوية القيمة
  higher, // المنتج المستهدف أعلى قيمة
  lower, // المنتج المستهدف أقل قيمة
}
