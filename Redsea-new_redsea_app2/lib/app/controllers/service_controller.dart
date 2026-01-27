import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/models/service_model.dart';

/// متحكم نظام تبادل الخدمات
class ServiceController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // البيانات المرصودة
  final RxList<Service> allServices = <Service>[].obs;
  final RxList<Service> myServices = <Service>[].obs;
  final RxList<ServiceSwapRequest> incomingRequests =
      <ServiceSwapRequest>[].obs;
  final RxList<ServiceSwapRequest> outgoingRequests =
      <ServiceSwapRequest>[].obs;
  final RxBool isLoading = false.obs;

  // فلاتر
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'الكل'.obs;

  // إحصائيات المنصة (بيانات حقيقية)
  final RxInt totalCompletedOrders = 0.obs;
  final RxInt totalServiceProviders = 0.obs;
  final RxInt totalAvailableServices = 0.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // تحميل البيانات بشكل آمن في الخلفية
    _initializeData();
  }

  /// تهيئة البيانات بشكل آمن
  Future<void> _initializeData() async {
    try {
      await loadServices();
      if (currentUserId != null) {
        // تحميل البيانات الإضافية بدون حجب UI
        loadMyServices();
        loadSwapRequests();
      }
    } catch (e) {
      debugPrint('Error initializing service controller: $e');
    }
  }

  /// تحميل جميع الخدمات المتاحة
  Future<void> loadServices() async {
    if (isLoading.value) return; // منع التحميل المتكرر

    isLoading.value = true;
    try {
      final snapshot = await _dbRef.child('services').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (snapshot.exists && snapshot.value != null) {
        List<Service> services = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            if (value is Map) {
              Service service =
                  Service.fromMap(key, Map<dynamic, dynamic>.from(value));
              // إظهار جميع الخدمات المتاحة (بما فيها خدمات المستخدم)
              // سيتم تمييز خدمات المستخدم ومنع التفاعل معها في واجهة المستخدم
              if (service.isAvailable) {
                services.add(service);
              }
            }
          } catch (e) {
            debugPrint('Error parsing service $key: $e');
          }
        });

        // ترتيب حسب الأحدث
        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        allServices.value = services;
      } else {
        allServices.value = [];
      }

      // تحديث إحصائيات المنصة
      _updatePlatformStatistics();
    } catch (e) {
      debugPrint('Error loading services: $e');
      allServices.value = [];
      // عرض رسالة خطأ للمستخدم
      if (e.toString().contains('permission-denied')) {
        Get.snackbar('خطأ', 'ليس لديك صلاحية لعرض الخدمات');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث إحصائيات المنصة من البيانات الحقيقية
  void _updatePlatformStatistics() {
    // 1. عدد الخدمات المتاحة
    totalAvailableServices.value = allServices.length;

    // 2. عدد مقدمي الخدمات الفريدين
    final uniqueProviders = allServices.map((s) => s.ownerId).toSet();
    totalServiceProviders.value = uniqueProviders.length;

    // 3. تحميل عدد الطلبات المكتملة من قاعدة البيانات
    _loadCompletedOrdersCount();
  }

  /// تحميل عدد الطلبات المكتملة
  Future<void> _loadCompletedOrdersCount() async {
    try {
      final ordersSnapshot = await _dbRef
          .child('service_orders')
          .orderByChild('status')
          .equalTo('completed')
          .get()
          .timeout(const Duration(seconds: 5));

      if (ordersSnapshot.exists && ordersSnapshot.value != null) {
        totalCompletedOrders.value = (ordersSnapshot.value as Map).length;
      } else {
        totalCompletedOrders.value = 0;
      }
    } catch (e) {
      debugPrint('Error loading completed orders count: $e');
      // في حالة الخطأ، نحاول حساب من الطلبات المحلية إن وجدت
    }
  }

  /// تحميل خدماتي
  Future<void> loadMyServices() async {
    if (currentUserId == null) {
      debugPrint('loadMyServices: No user logged in');
      return;
    }

    debugPrint('=== Loading My Services ===');
    debugPrint('User ID: $currentUserId');

    try {
      final snapshot = await _dbRef
          .child('services')
          .orderByChild('ownerId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('Snapshot exists: ${snapshot.exists}');
      debugPrint('Snapshot value: ${snapshot.value}');

      if (snapshot.exists && snapshot.value != null) {
        List<Service> services = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        debugPrint('Found ${data.length} services');

        data.forEach((key, value) {
          try {
            if (value is Map) {
              debugPrint('Parsing service: $key');
              services
                  .add(Service.fromMap(key, Map<dynamic, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Error parsing my service $key: $e');
          }
        });

        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        myServices.value = services;
        debugPrint('Loaded ${services.length} services');
      } else {
        debugPrint('No services found for user');
        myServices.value = [];
      }
    } catch (e) {
      debugPrint('Error loading my services: $e');
      myServices.value = [];
    }
  }

  /// الخدمات المفلترة
  List<Service> get filteredServices {
    List<Service> results = allServices.toList();

    // فلترة حسب التصنيف
    if (selectedCategory.value != 'الكل') {
      results =
          results.where((s) => s.category == selectedCategory.value).toList();
    }

    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      results = results
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              s.description.toLowerCase().contains(query) ||
              s.ownerName.toLowerCase().contains(query))
          .toList();
    }

    return results;
  }

  /// إضافة خدمة جديدة
  Future<bool> addService({
    required String title,
    required String description,
    required String category,
    required double estimatedValue,
    required String duration,
    List<String> images = const [],
    List<String> swapPreferences = const [],
    bool isSpecialOffer = false,
    double? oldEstimatedValue,
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      debugPrint('=== Adding Service ===');
      debugPrint('User ID: $currentUserId');
      debugPrint('Title: $title');
      debugPrint('Category: $category');

      // الحصول على اسم المستخدم
      String ownerName = 'مستخدم';
      try {
        final userSnapshot = await _dbRef
            .child('users/$currentUserId/name')
            .get()
            .timeout(const Duration(seconds: 5));
        ownerName = userSnapshot.value?.toString() ?? 'مستخدم';
        debugPrint('Owner Name: $ownerName');
      } catch (e) {
        debugPrint('Warning: Could not get user name: $e');
        // استمر حتى لو لم نحصل على الاسم
      }

      final serviceRef = _dbRef.child('services').push();
      debugPrint('Service Ref Key: ${serviceRef.key}');

      final service = Service(
        id: serviceRef.key!,
        ownerId: currentUserId!,
        ownerName: ownerName,
        title: title,
        description: description,
        category: category,
        estimatedValue: estimatedValue,
        duration: duration,
        images: images,
        swapPreferences: swapPreferences,
        createdAt: DateTime.now(),
        isSpecialOffer: isSpecialOffer,
        oldEstimatedValue: oldEstimatedValue,
      );

      debugPrint('Saving service to database...');
      // حفظ بدون timeout - Firebase سيعيد المحاولة تلقائياً
      await serviceRef.set(service.toMap());
      debugPrint('Service saved successfully!');

      // تحديث القوائم في الخلفية بدون انتظار
      loadMyServices();
      loadServices();

      Get.snackbar('نجاح', 'تم إضافة الخدمة إلى قائمة خدماتك',
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error adding service: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar('خطأ', 'فشل في إضافة الخدمة: ${e.toString()}',
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white);
      return false;
    }
  }

  /// حذف خدمة
  Future<bool> deleteService(String serviceId) async {
    // التحقق من تسجيل الدخول
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      // التحقق من أن الخدمة موجودة وتنتمي للمستخدم الحالي
      final serviceSnapshot = await _dbRef.child('services/$serviceId').get();

      if (!serviceSnapshot.exists) {
        Get.snackbar('خطأ', 'الخدمة غير موجودة أو تم حذفها مسبقاً');
        // إعادة تحميل القائمة لتحديثها
        await loadMyServices();
        return false;
      }

      final serviceData = serviceSnapshot.value as Map<dynamic, dynamic>;
      final ownerId = serviceData['ownerId']?.toString();

      if (ownerId != currentUserId) {
        Get.snackbar('خطأ', 'لا يمكنك حذف خدمة لا تملكها');
        return false;
      }

      // حذف الخدمة
      await _dbRef.child('services/$serviceId').remove();

      // تحديث القائمة المحلية
      myServices.removeWhere((s) => s.id == serviceId);
      allServices.removeWhere((s) => s.id == serviceId);

      Get.snackbar(
        'تم',
        'تم حذف الخدمة بنجاح',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      String errorMessage = 'فشل في حذف الخدمة';

      // تحديد نوع الخطأ
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'ليس لديك صلاحية لحذف هذه الخدمة';
      } else if (e.toString().contains('network')) {
        errorMessage = 'خطأ في الاتصال، تحقق من الإنترنت';
      }

      Get.snackbar(
        'خطأ',
        errorMessage,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  /// تحديث خدمة موجودة (مع التحقق من الملكية)
  Future<bool> updateService({
    required String serviceId,
    required String title,
    required String description,
    required String category,
    required double estimatedValue,
    required String duration,
    List<String> swapPreferences = const [],
    bool isSpecialOffer = false,
    double? oldEstimatedValue,
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      // التحقق من أن الخدمة تنتمي للمستخدم الحالي
      final serviceSnapshot = await _dbRef.child('services/$serviceId').get();
      if (!serviceSnapshot.exists) {
        Get.snackbar('خطأ', 'الخدمة غير موجودة');
        return false;
      }

      final serviceData = serviceSnapshot.value as Map<dynamic, dynamic>;
      if (serviceData['ownerId'] != currentUserId) {
        Get.snackbar('خطأ', 'لا يمكنك تعديل خدمة لا تملكها');
        return false;
      }

      await _dbRef.child('services/$serviceId').update({
        'title': title,
        'description': description,
        'category': category,
        'estimatedValue': estimatedValue,
        'duration': duration,
        'swapPreferences': swapPreferences,
        'isSpecialOffer': isSpecialOffer,
        'oldEstimatedValue': oldEstimatedValue,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await loadMyServices();
      await loadServices();
      Get.snackbar('نجاح', 'تم تحديث الخدمة بنجاح');
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الخدمة');
      return false;
    }
  }

  /// تحميل طلبات التبادل
  Future<void> loadSwapRequests() async {
    if (currentUserId == null) return;

    try {
      // الطلبات الواردة
      final incomingSnapshot = await _dbRef
          .child('service_swap_requests')
          .orderByChild('targetOwnerId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (incomingSnapshot.exists && incomingSnapshot.value != null) {
        List<ServiceSwapRequest> requests = [];
        Map<dynamic, dynamic> data =
            incomingSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            if (value is Map) {
              requests.add(ServiceSwapRequest.fromMap(
                  key, Map<dynamic, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Error parsing incoming request $key: $e');
          }
        });
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        incomingRequests.value = requests;
      } else {
        incomingRequests.value = [];
      }

      // الطلبات الصادرة
      final outgoingSnapshot = await _dbRef
          .child('service_swap_requests')
          .orderByChild('requesterId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (outgoingSnapshot.exists && outgoingSnapshot.value != null) {
        List<ServiceSwapRequest> requests = [];
        Map<dynamic, dynamic> data =
            outgoingSnapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            if (value is Map) {
              requests.add(ServiceSwapRequest.fromMap(
                  key, Map<dynamic, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Error parsing outgoing request $key: $e');
          }
        });
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        outgoingRequests.value = requests;
      } else {
        outgoingRequests.value = [];
      }
    } catch (e) {
      debugPrint('Error loading swap requests: $e');
      incomingRequests.value = [];
      outgoingRequests.value = [];
    }
  }

  /// إرسال طلب تبادل
  Future<bool> sendSwapRequest({
    required Service targetService,
    required Service offeredService,
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

      final requestRef = _dbRef.child('service_swap_requests').push();
      final request = ServiceSwapRequest(
        id: requestRef.key!,
        requesterId: currentUserId!,
        requesterName: requesterName,
        requesterServiceId: offeredService.id,
        requesterServiceTitle: offeredService.title,
        targetOwnerId: targetService.ownerId,
        targetServiceId: targetService.id,
        targetServiceTitle: targetService.title,
        message: message,
        timestamp: DateTime.now(),
      );

      await requestRef.set(request.toMap());

      // إرسال إشعار
      _sendNotification(
        targetService.ownerId,
        'طلب تبادل خدمات جديد',
        '$requesterName يريد تبادل خدمة "${offeredService.title}" مقابل "${targetService.title}"',
      );

      await loadSwapRequests();
      Get.snackbar('نجاح', 'تم إرسال طلب التبادل');
      return true;
    } catch (e) {
      debugPrint('Error sending swap request: $e');
      Get.snackbar('خطأ', 'فشل في إرسال الطلب');
      return false;
    }
  }

  /// قبول طلب تبادل
  Future<bool> acceptSwapRequest(ServiceSwapRequest request) async {
    try {
      await _dbRef
          .child('service_swap_requests/${request.id}/status')
          .set('accepted');

      _sendNotification(
        request.requesterId,
        'تم قبول طلب التبادل! 🎉',
        'تم قبول طلبك لتبادل "${request.requesterServiceTitle}"',
      );

      await loadSwapRequests();
      Get.snackbar('نجاح', 'تم قبول الطلب');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في قبول الطلب');
      return false;
    }
  }

  /// رفض طلب تبادل
  Future<bool> rejectSwapRequest(ServiceSwapRequest request,
      {String? reason}) async {
    try {
      await _dbRef
          .child('service_swap_requests/${request.id}/status')
          .set('rejected');

      _sendNotification(
        request.requesterId,
        'تم رفض طلب التبادل',
        reason ?? 'تم رفض طلبك لتبادل "${request.requesterServiceTitle}"',
      );

      await loadSwapRequests();
      Get.snackbar('تم', 'تم رفض الطلب');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في رفض الطلب');
      return false;
    }
  }

  /// إلغاء طلب تبادل
  Future<bool> cancelSwapRequest(ServiceSwapRequest request) async {
    try {
      await _dbRef
          .child('service_swap_requests/${request.id}/status')
          .set('cancelled');
      await loadSwapRequests();
      Get.snackbar('تم', 'تم إلغاء الطلب');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في إلغاء الطلب');
      return false;
    }
  }

  /// إرسال إشعار
  void _sendNotification(String userId, String title, String body) {
    try {
      _dbRef.child('notifications/$userId').push().set({
        'title': title,
        'message': body,
        'type': 'service_swap',
        'timestamp': ServerValue.timestamp,
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// عدد الطلبات المعلقة
  int get pendingRequestsCount {
    return incomingRequests.where((r) => r.status == 'pending').length;
  }

  // ================== المفضلة ==================

  final RxList<String> favoriteServiceIds = <String>[].obs;

  /// تحميل خدماتي المفضلة
  Future<void> loadFavorites() async {
    if (currentUserId == null) return;

    try {
      final snapshot = await _dbRef
          .child('service_favorites/$currentUserId')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        favoriteServiceIds.value = data.keys.cast<String>().toList();
      } else {
        favoriteServiceIds.value = [];
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// التحقق إذا كانت الخدمة مفضلة
  bool isFavorite(String serviceId) {
    return favoriteServiceIds.contains(serviceId);
  }

  /// إضافة/إزالة من المفضلة
  Future<void> toggleFavorite(String serviceId) async {
    if (currentUserId == null) {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final favRef =
          _dbRef.child('service_favorites/$currentUserId/$serviceId');

      if (isFavorite(serviceId)) {
        await favRef.remove();
        favoriteServiceIds.remove(serviceId);
        Get.snackbar('تم', 'تمت الإزالة من المفضلة');
      } else {
        await favRef.set({'addedAt': ServerValue.timestamp});
        favoriteServiceIds.add(serviceId);
        Get.snackbar('تم', 'تمت الإضافة إلى المفضلة');
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      Get.snackbar('خطأ', 'فشل في تعديل المفضلة');
    }
  }

  // ================== التقييمات ==================

  final RxList<ServiceReview> serviceReviews = <ServiceReview>[].obs;
  final RxBool isLoadingReviews = false.obs;

  /// تحميل تقييمات خدمة معينة
  Future<List<ServiceReview>> loadServiceReviews(String serviceId) async {
    isLoadingReviews.value = true;
    try {
      final snapshot = await _dbRef
          .child('service_reviews/$serviceId')
          .get()
          .timeout(const Duration(seconds: 10));

      List<ServiceReview> reviews = [];
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            if (value is Map) {
              reviews.add(ServiceReview.fromMap(
                  key, Map<dynamic, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Error parsing review $key: $e');
          }
        });
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      serviceReviews.value = reviews;
      return reviews;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      serviceReviews.value = [];
      return [];
    } finally {
      isLoadingReviews.value = false;
    }
  }

  /// إضافة تقييم لخدمة
  Future<bool> addReview({
    required String serviceId,
    required double rating,
    required String comment,
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      // الحصول على اسم المستخدم
      final userSnapshot =
          await _dbRef.child('users/$currentUserId/name').get();
      String reviewerName = userSnapshot.value?.toString() ?? 'مستخدم';

      final reviewRef = _dbRef.child('service_reviews/$serviceId').push();
      final review = ServiceReview(
        id: reviewRef.key!,
        serviceId: serviceId,
        userId: currentUserId!,
        userName: reviewerName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await reviewRef.set(review.toMap());

      // تحديث متوسط الـ rating في الخدمة
      await _updateServiceRating(serviceId);

      await loadServiceReviews(serviceId);
      Get.snackbar('نجاح', 'تم إضافة تقييمك بنجاح');
      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      Get.snackbar('خطأ', 'فشل في إضافة التقييم');
      return false;
    }
  }

  /// تحديث متوسط تقييم الخدمة
  Future<void> _updateServiceRating(String serviceId) async {
    try {
      final snapshot = await _dbRef.child('service_reviews/$serviceId').get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        double totalRating = 0;
        int count = 0;
        data.forEach((key, value) {
          if (value is Map && value['rating'] != null) {
            totalRating += (value['rating'] as num).toDouble();
            count++;
          }
        });
        if (count > 0) {
          double avgRating = totalRating / count;
          await _dbRef.child('services/$serviceId').update({
            'rating': avgRating,
            'reviewsCount': count,
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating service rating: $e');
    }
  }

  // ================== المشاهدات ==================

  /// زيادة عدد مشاهدات خدمة
  Future<void> incrementViews(String serviceId) async {
    try {
      await _dbRef
          .child('services/$serviceId/viewsCount')
          .set(ServerValue.increment(1));
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  // ================== الخدمات المميزة ==================

  /// تحميل الخدمات المميزة فقط
  List<Service> get featuredServices {
    return allServices.where((s) => s.isFeatured).toList();
  }

  // ================== طلبات شراء الخدمات ==================

  final RxList<Map<String, dynamic>> serviceOrders =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> sellerServiceOrders =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingOrders = false.obs;

  /// إنشاء طلب شراء خدمة
  Future<bool> createServiceOrder({
    required Service service,
    required String paymentMethod,
    String? transactionNumber,
    String? paymentReceiptUrl,
    String? notes,
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    if (service.ownerId == currentUserId) {
      Get.snackbar('خطأ', 'لا يمكنك شراء خدمتك الخاصة');
      return false;
    }

    try {
      // الحصول على اسم المشتري
      final userSnapshot =
          await _dbRef.child('users/$currentUserId/name').get();
      String buyerName = userSnapshot.value?.toString() ?? 'مستخدم';

      final orderRef = _dbRef.child('service_orders').push();

      final orderData = {
        'id': orderRef.key,
        'serviceId': service.id,
        'serviceTitle': service.title,
        'serviceValue': service.estimatedValue,
        'buyerId': currentUserId,
        'buyerName': buyerName,
        'sellerId': service.ownerId,
        'sellerName': service.ownerName,
        'paymentMethod': paymentMethod,
        'transactionNumber': transactionNumber,
        'paymentReceiptUrl': paymentReceiptUrl,
        'notes': notes,
        'status':
            'pending_payment', // pending_payment, payment_confirmed, in_progress, completed, cancelled
        'paymentStatus': 'pending', // pending, confirmed, rejected
        'createdAt': ServerValue.timestamp,
        // معلومات الدفع من الخدمة
        'paymentAccountNumber': service.paymentAccountNumber,
        'paymentAccountName': service.paymentAccountName,
        'paymentInstructions': service.paymentInstructions,
      };

      await orderRef.set(orderData);

      // إرسال إشعار للبائع
      _sendNotification(
        service.ownerId,
        'طلب شراء خدمة جديد! 🛒',
        '$buyerName طلب شراء خدمة "${service.title}"',
      );

      Get.snackbar(
        'تم إرسال الطلب',
        'سيتم إعلامك عند تأكيد البائع لاستلام الدفع',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating service order: $e');
      Get.snackbar('خطأ', 'فشل في إنشاء الطلب');
      return false;
    }
  }

  /// تحميل طلبات الشراء (كمشتري)
  Future<void> loadServiceOrders() async {
    if (currentUserId == null) return;

    isLoadingOrders.value = true;
    try {
      final snapshot = await _dbRef
          .child('service_orders')
          .orderByChild('buyerId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists && snapshot.value != null) {
        List<Map<String, dynamic>> orders = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            orders.add(Map<String, dynamic>.from(value));
          }
        });
        orders.sort(
            (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        serviceOrders.value = orders;
      } else {
        serviceOrders.value = [];
      }
    } catch (e) {
      debugPrint('Error loading service orders: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  /// تحميل طلبات البائع (الطلبات الواردة)
  Future<void> loadSellerServiceOrders() async {
    if (currentUserId == null) return;

    try {
      final snapshot = await _dbRef
          .child('service_orders')
          .orderByChild('sellerId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists && snapshot.value != null) {
        List<Map<String, dynamic>> orders = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value is Map) {
            orders.add(Map<String, dynamic>.from(value));
          }
        });
        orders.sort(
            (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        sellerServiceOrders.value = orders;
      } else {
        sellerServiceOrders.value = [];
      }
    } catch (e) {
      debugPrint('Error loading seller service orders: $e');
    }
  }

  /// تأكيد استلام الدفع (للبائع)
  Future<bool> confirmServicePayment(String orderId) async {
    try {
      await _dbRef.child('service_orders/$orderId').update({
        'paymentStatus': 'confirmed',
        'status': 'in_progress',
        'paymentConfirmedAt': ServerValue.timestamp,
      });

      // الحصول على معلومات الطلب لإرسال إشعار
      final orderSnapshot = await _dbRef.child('service_orders/$orderId').get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map<dynamic, dynamic>;
        _sendNotification(
          orderData['buyerId'],
          'تم تأكيد الدفع! ✅',
          'تم تأكيد دفعك لخدمة "${orderData['serviceTitle']}"',
        );
      }

      await loadSellerServiceOrders();
      Get.snackbar(
        'تم التأكيد',
        'تم تأكيد استلام الدفع وبدء تنفيذ الخدمة',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error confirming payment: $e');
      Get.snackbar('خطأ', 'فشل في تأكيد الدفع');
      return false;
    }
  }

  /// رفض الدفع (للبائع)
  Future<bool> rejectServicePayment(String orderId, {String? reason}) async {
    try {
      await _dbRef.child('service_orders/$orderId').update({
        'paymentStatus': 'rejected',
        'status': 'cancelled',
        'rejectionReason': reason,
        'rejectedAt': ServerValue.timestamp,
      });

      // الحصول على معلومات الطلب لإرسال إشعار
      final orderSnapshot = await _dbRef.child('service_orders/$orderId').get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map<dynamic, dynamic>;
        _sendNotification(
          orderData['buyerId'],
          'تم رفض الدفع ❌',
          reason ?? 'تم رفض دفعك لخدمة "${orderData['serviceTitle']}"',
        );
      }

      await loadSellerServiceOrders();
      Get.snackbar('تم', 'تم رفض الطلب');
      return true;
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      Get.snackbar('خطأ', 'فشل في رفض الطلب');
      return false;
    }
  }

  /// تحديث حالة طلب الخدمة
  Future<bool> updateServiceOrderStatus(String orderId, String status) async {
    try {
      await _dbRef.child('service_orders/$orderId').update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });

      // إرسال إشعار للمشتري
      final orderSnapshot = await _dbRef.child('service_orders/$orderId').get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map<dynamic, dynamic>;
        String statusText = _getStatusText(status);
        _sendNotification(
          orderData['buyerId'],
          'تحديث حالة الطلب',
          'تم تحديث حالة طلبك إلى: $statusText',
        );
      }

      await loadSellerServiceOrders();
      Get.snackbar('تم', 'تم تحديث حالة الطلب');
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الحالة');
      return false;
    }
  }

  /// إكمال الخدمة
  Future<bool> completeServiceOrder(String orderId) async {
    try {
      await _dbRef.child('service_orders/$orderId').update({
        'status': 'completed',
        'completedAt': ServerValue.timestamp,
      });

      // الحصول على معلومات الطلب لتحديث عدد الطلبات المكتملة
      final orderSnapshot = await _dbRef.child('service_orders/$orderId').get();
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map<dynamic, dynamic>;

        // تحديث عدد الطلبات المكتملة للخدمة
        await _dbRef
            .child('services/${orderData['serviceId']}/completedOrders')
            .set(ServerValue.increment(1));

        _sendNotification(
          orderData['buyerId'],
          'تم إكمال الخدمة! 🎉',
          'تم إكمال خدمة "${orderData['serviceTitle']}" بنجاح',
        );
      }

      await loadSellerServiceOrders();
      Get.snackbar(
        'تم الإكمال',
        'تم إنهاء الخدمة بنجاح',
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      debugPrint('Error completing order: $e');
      Get.snackbar('خطأ', 'فشل في إكمال الطلب');
      return false;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment':
        return 'في انتظار الدفع';
      case 'payment_confirmed':
        return 'تم تأكيد الدفع';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  /// حذف طلب تبادل خدمة معين
  Future<bool> deleteSwapRequest(String id) async {
    try {
      await _dbRef.child('service_swap_requests/$id').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting service swap request: $e');
      return false;
    }
  }

  /// حذف جميع طلبات تبادل الخدمات المنتهية
  Future<void> clearSwapRequests(bool isIncoming) async {
    try {
      final list = isIncoming ? incomingRequests : outgoingRequests;
      final toDelete = list
          .where((r) =>
              r.status == 'accepted' ||
              r.status == 'rejected' ||
              r.status == 'cancelled')
          .toList();

      for (var request in toDelete) {
        await deleteSwapRequest(request.id);
      }
      Get.snackbar('نجاح', 'تم تنظيف قائمة الطلبات');
    } catch (e) {
      debugPrint('Error clearing service swap requests: $e');
    }
  }

  /// حذف طلب شراء خدمة
  Future<bool> deleteServiceOrder(String orderId) async {
    try {
      await _dbRef.child('service_orders/$orderId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting service order: $e');
      return false;
    }
  }

  /// حذف جميع طلبات شراء الخدمات المكتملة أو الملغاة
  Future<void> clearServiceOrders(bool isSeller) async {
    try {
      final list = isSeller ? sellerServiceOrders : serviceOrders;
      final toDelete = list
          .where((o) =>
              o['status'] == 'completed' ||
              o['status'] == 'cancelled' ||
              o['status'] == 'rejected')
          .toList();

      for (var order in toDelete) {
        await deleteServiceOrder(order['id']);
      }
      Get.snackbar('نجاح', 'تم تنظيف قائمة الطلبات');
    } catch (e) {
      debugPrint('Error clearing service orders: $e');
    }
  }
}
