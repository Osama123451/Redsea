import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/models/experience_swap_model.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/services/chat_service.dart';

class ExperienceSwapController extends GetxController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ExperienceSwapRequest> incomingRequests =
      <ExperienceSwapRequest>[].obs;
  final RxList<ExperienceSwapRequest> outgoingRequests =
      <ExperienceSwapRequest>[].obs;
  final RxBool isLoading = false.obs;

  StreamSubscription? _incomingSub;
  StreamSubscription? _outgoingSub;
  StreamSubscription? _authSub;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      listenToRequests();
    }
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        listenToRequests();
      } else {
        _stopListening();
      }
    });
  }

  @override
  void onClose() {
    _stopListening();
    _authSub?.cancel();
    super.onClose();
  }

  void _stopListening() {
    _incomingSub?.cancel();
    _incomingSub = null;
    _outgoingSub?.cancel();
    _outgoingSub = null;
    incomingRequests.clear();
    outgoingRequests.clear();
  }

  void listenToRequests() {
    if (currentUserId == null) return;

    // Listen to incoming requests (where the user is the target expert)
    _incomingSub?.cancel();
    _incomingSub = _dbRef
        .child('experience_swap_requests')
        .orderByChild('targetExpertId')
        .equalTo(currentUserId)
        .onValue
        .listen((event) {
      final List<ExperienceSwapRequest> requests = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          requests.add(ExperienceSwapRequest.fromMap(key, value));
        });
      }
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      incomingRequests.value = requests;
    }, onError: (e) {
      debugPrint('Error listening to incoming experience swap requests: $e');
    });

    // Listen to outgoing requests (where the user is the requester)
    _outgoingSub?.cancel();
    _outgoingSub = _dbRef
        .child('experience_swap_requests')
        .orderByChild('requesterId')
        .equalTo(currentUserId)
        .onValue
        .listen((event) {
      final List<ExperienceSwapRequest> requests = [];
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          requests.add(ExperienceSwapRequest.fromMap(key, value));
        });
      }
      requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      outgoingRequests.value = requests;
    }, onError: (e) {
      debugPrint('Error listening to outgoing experience swap requests: $e');
    });
  }

  Future<bool> sendSwapRequest({
    required Experience targetExperience,
    required Experience offeredExperience,
    String message = '',
  }) async {
    if (currentUserId == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return false;
    }

    try {
      final requesterName = _auth.currentUser?.displayName ?? 'خبير';
      final requestRef = _dbRef.child('experience_swap_requests').push();

      final request = ExperienceSwapRequest(
        id: requestRef.key!,
        requesterId: currentUserId!,
        requesterName: requesterName,
        targetExpertId: targetExperience.expertId ?? '',
        targetExperienceId: targetExperience.id,
        targetExperienceTitle: targetExperience.title,
        offeredExperienceId: offeredExperience.id,
        offeredExperienceTitle: offeredExperience.title,
        message: message,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await requestRef.set(request.toMap());

      // Notify the target expert
      _sendNotification(
        targetExperience.expertId!,
        'طلب تبادل خبرات 🔄',
        'يريد $requesterName تبادل خبرة "${offeredExperience.title}" مقابل "${targetExperience.title}"',
      );

      Get.snackbar('نجاح', 'تم إرسال طلب التبادل بنجاح');
      return true;
    } catch (e) {
      debugPrint('Error sending experience swap: $e');
      Get.snackbar('خطأ', 'فشل في إرسال الطلب');
      return false;
    }
  }

  Future<void> updateRequestStatus(
      String requestId, String newStatus, String requesterId) async {
    try {
      await _dbRef
          .child('experience_swap_requests/$requestId/status')
          .set(newStatus);

      String title = '';
      String body = '';

      if (newStatus == 'accepted') {
        title = 'تم قبول طلب التبادل! ✅';
        body = 'تم قبول طلبك لتبادل الخبرات. يمكنك الآن التواصل مع الخبير.';
      } else if (newStatus == 'rejected') {
        title = 'تم رفض طلب التبادل ❌';
        body = 'نعتذر، لم يتم قبول طلب التبادل الخاص بك.';
      }

      if (title.isNotEmpty) {
        _sendNotification(requesterId, title, body);
      }

      // إنشاء محادثة تلقائية عند القبول
      if (newStatus == 'accepted') {
        final request = incomingRequests.firstWhere((r) => r.id == requestId);
        final chatService = ChatService();

        // إنشاء المحادثة
        final chatId = await chatService.createOrGetExperienceChat(
          requesterId,
          request.targetExperienceId,
        );

        // إرسال رسالة ترحيبية تلقائية
        await chatService.sendMessage(
          chatId,
          'تم قبول طلب تبادل الخبرات: "${request.offeredExperienceTitle}" مقابل "${request.targetExperienceTitle}". يمكننا الآن مناقشة التفاصيل هنا.',
          requesterId,
          type: 'text',
        );
      }

      Get.snackbar('تم', 'تم تحديث حالة الطلب لبدء التبادل');
    } catch (e) {
      debugPrint('Error updating experience swap status: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الحالة وبدء المحادثة');
    }
  }

  void _sendNotification(String userId, String title, String body) {
    _dbRef.child('notifications/$userId').push().set({
      'title': title,
      'message': body,
      'type': 'experience_swap',
      'timestamp': ServerValue.timestamp,
      'isRead': false,
    });
  }

  /// حذف طلب تبادل خبرة معين
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _dbRef.child('experience_swap_requests/$requestId').remove();
      return true;
    } catch (e) {
      debugPrint('Error deleting experience swap request: $e');
      return false;
    }
  }

  /// حذف جميع الطلبات المنتهية (مقبولة، مرفوضة)
  /// ملاحظة: الخبرات لا تملك حالة "cancelled" حالياً في النموذج لكن نضيفها للاحتياط
  Future<void> clearRequests(bool isIncoming) async {
    try {
      final list = isIncoming ? incomingRequests : outgoingRequests;
      final toDelete = list
          .where((r) =>
              r.status == 'accepted' ||
              r.status == 'rejected' ||
              r.status == 'cancelled')
          .toList();

      for (var request in toDelete) {
        await deleteRequest(request.id);
      }

      Get.snackbar('نجاح', 'تم تنظيف قائمة الطلبات');
    } catch (e) {
      debugPrint('Error clearing experience swap requests: $e');
      Get.snackbar('خطأ', 'فشل في تنظيف القائمة');
    }
  }

  /// تحديث رؤية الخبرة (عام/خاص)
  Future<void> updateExperienceVisibility(
      String experienceId, bool isPublic) async {
    try {
      await _dbRef.child('experiences/$experienceId/isPublic').set(isPublic);
      debugPrint('✅ Experience $experienceId visibility updated to: $isPublic');
    } catch (e) {
      debugPrint('❌ Error updating experience visibility: $e');
    }
  }
}
