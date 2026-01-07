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
              // فقط الخدمات المتاحة ومن مستخدمين آخرين
              if (service.isAvailable && service.ownerId != currentUserId) {
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

  /// تحميل خدماتي
  Future<void> loadMyServices() async {
    if (currentUserId == null) return;

    try {
      final snapshot = await _dbRef
          .child('services')
          .orderByChild('ownerId')
          .equalTo(currentUserId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.exists && snapshot.value != null) {
        List<Service> services = [];
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            if (value is Map) {
              services
                  .add(Service.fromMap(key, Map<dynamic, dynamic>.from(value)));
            }
          } catch (e) {
            debugPrint('Error parsing my service $key: $e');
          }
        });

        services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        myServices.value = services;
      } else {
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
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      // الحصول على اسم المستخدم
      final userSnapshot =
          await _dbRef.child('users/$currentUserId/name').get();
      String ownerName = userSnapshot.value?.toString() ?? 'مستخدم';

      final serviceRef = _dbRef.child('services').push();
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
      );

      await serviceRef.set(service.toMap());
      await loadMyServices();
      await loadServices();

      Get.snackbar('نجاح', 'تم إضافة الخدمة إلى قائمة خدماتك');
      return true;
    } catch (e) {
      debugPrint('Error adding service: $e');
      Get.snackbar('خطأ', 'فشل في إضافة الخدمة');
      return false;
    }
  }

  /// حذف خدمة
  Future<bool> deleteService(String serviceId) async {
    try {
      await _dbRef.child('services/$serviceId').remove();
      await loadMyServices();
      Get.snackbar('تم', 'تم حذف الخدمة');
      return true;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في حذف الخدمة');
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
}
