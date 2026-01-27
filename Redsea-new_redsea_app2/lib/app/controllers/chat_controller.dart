import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// Controller لإدارة المحادثات
class ChatController extends GetxController {
  final DatabaseReference _chatsRef =
      FirebaseDatabase.instance.ref().child('chats');
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');

  // المتغيرات
  final RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredChats =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt unreadChatsCount = 0.obs;
  final RxString searchQuery = ''.obs;

  StreamSubscription? _authSubscription;
  StreamSubscription? _chatsSubscription;

  // ذاكرة تخزين مؤقت لبيانات المستخدمين لتقليل الطلبات
  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void onInit() {
    super.onInit();
    // الاستماع لتغيرات حالة المصادقة
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startChatListener();
        loadBlockedUsers(); // تحميل قائمة المحظورين
      } else {
        _clearData();
      }
    });

    // الاستماع للبحث
    debounce(searchQuery, (_) => _filterChats(),
        time: const Duration(milliseconds: 300));
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _chatsSubscription?.cancel();
    _chatsSubscription2?.cancel();
    super.onClose();
  }

  /// مسح البيانات عند تسجيل الخروج
  void _clearData() {
    chats.clear();
    filteredChats.clear();
    unreadChatsCount.value = 0;
    _chatsSubscription?.cancel();
    _chatsSubscription2?.cancel();
  }

  // اشتراك ثانوي للمحادثات كـ user2
  StreamSubscription? _chatsSubscription2;

  // متغيرات لإدارة نتائج الاستعلامات
  int _completedQueries = 0;
  final Map<String, Map<String, dynamic>> _chatMap = {};

  /// بدء الاستماع للمحادثات (Realtime) - استخدام استعلامات مفهرسة بدلاً من تحميل كل المحادثات
  void startChatListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('ChatController: No user logged in, skipping chat listener');
      return;
    }

    isLoading.value = true;
    _chatsSubscription?.cancel();
    _chatsSubscription2?.cancel();

    // إعادة تعيين المتغيرات عند بدء استماع جديد
    _completedQueries = 0;
    _chatMap.clear();

    debugPrint('📋 ChatController: Starting chat listener for user: $userId');

    void processResults() {
      if (_completedQueries < 2) return; // انتظار اكتمال كلا الاستعلامين

      final List<Map<String, dynamic>> loadedChats = _chatMap.values.toList();
      int unread = 0;

      for (var chat in loadedChats) {
        if (chat['unreadCount'] != null &&
            chat['unreadCount'][userId] != null) {
          unread += (chat['unreadCount'][userId] as int);
        }
      }

      // ترتيب حسب آخر رسالة تنازلياً
      loadedChats.sort((a, b) =>
          (b['lastMessageTime'] ?? 0).compareTo(a['lastMessageTime'] ?? 0));

      debugPrint('📋 ChatController: Loaded ${loadedChats.length} chats');

      chats.value = loadedChats;
      unreadChatsCount.value = unread;
      _filterChats();
      isLoading.value = false;

      // تحميل أسماء المستخدمين مسبقاً لتحسين الأداء
      _preCacheUserNames(loadedChats);
    }

    // الاستعلام الأول: المحادثات حيث المستخدم هو user1Id
    _chatsSubscription = _chatsRef
        .orderByChild('user1Id')
        .equalTo(userId)
        .onValue
        .listen((event) {
      try {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            try {
              final chat = Map<String, dynamic>.from(value);
              chat['id'] = key;
              _chatMap[key] = chat;
            } catch (e) {
              debugPrint('Error parsing chat $key: $e');
            }
          });
        }
        _completedQueries = (_completedQueries == 0) ? 1 : 2;
        processResults();
      } catch (e) {
        debugPrint('Error processing user1 chats: $e');
        _completedQueries = (_completedQueries == 0) ? 1 : 2;
        processResults();
      }
    }, onError: (error) {
      debugPrint('Error listening to user1 chats: $error');
      _completedQueries = (_completedQueries == 0) ? 1 : 2;
      processResults();
    });

    // الاستعلام الثاني: المحادثات حيث المستخدم هو user2Id
    _chatsSubscription2 = _chatsRef
        .orderByChild('user2Id')
        .equalTo(userId)
        .onValue
        .listen((event) {
      try {
        if (event.snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            try {
              final chat = Map<String, dynamic>.from(value);
              chat['id'] = key;
              _chatMap[key] = chat;
            } catch (e) {
              debugPrint('Error parsing chat $key: $e');
            }
          });
        }
        _completedQueries = (_completedQueries == 0) ? 1 : 2;
        processResults();
      } catch (e) {
        debugPrint('Error processing user2 chats: $e');
        _completedQueries = (_completedQueries == 0) ? 1 : 2;
        processResults();
      }
    }, onError: (error) {
      debugPrint('Error listening to user2 chats: $error');
      _completedQueries = (_completedQueries == 0) ? 1 : 2;
      processResults();
    });
  }

  /// تصفية المحادثات بناءً على البحث
  void _filterChats() {
    if (searchQuery.value.isEmpty) {
      filteredChats.value = chats.toList();
      return;
    }

    final query = searchQuery.value.toLowerCase();

    // تصفية بسيطة بدون جلب البيانات من الشبكة لتجنب التعليق
    // فقط نستخدم البيانات المخزنة مؤقتاً
    final List<Map<String, dynamic>> results = [];

    for (var chat in chats) {
      // البحث في اسم الطرف الآخر من الكاش
      final otherUserId = getOtherUserId(chat);
      String otherUserName = 'مستخدم';
      if (_userCache.containsKey(otherUserId)) {
        final data = _userCache[otherUserId]!;
        String display = '';
        if (data['firstName'] != null) {
          display = '${data['firstName']} ${data['lastName'] ?? ''}'.trim();
        }

        if (display.isEmpty || display == 'مستخدم') {
          display = data['name'] ?? '';
        }

        otherUserName = display.isNotEmpty ? display : 'مستخدم';
      }

      // البحث في الاسم فقط
      if (otherUserName.toLowerCase().contains(query)) {
        results.add(chat);
      }
    }

    filteredChats.value = results;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// الحصول على معرف الطرف الآخر
  String getOtherUserId(Map<String, dynamic> chat) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return '';

    String otherId = '';
    if (chat['participants'] != null) {
      final participants = Map<dynamic, dynamic>.from(chat['participants']);
      participants.forEach((key, value) {
        if (key != currentUserId && value == true) {
          otherId = key.toString();
        }
      });
    }
    return otherId;
  }

  /// جلب اسم المستخدم (مع التخزين المؤقت)
  Future<String> getUserName(String userId) async {
    if (_userCache.containsKey(userId)) {
      final data = _userCache[userId]!;
      String display = '';

      // 1. محاولة استخدام firstName + lastName
      if (data['firstName'] != null) {
        display = '${data['firstName']} ${data['lastName'] ?? ''}'.trim();
      }

      // 2. إذا لم يوجد، نستخدم name
      if (display.isEmpty || display == 'مستخدم') {
        display = data['name'] ?? '';
      }

      // 3. إذا كان الاسم فارغاً أو "مستخدم"، نستخدم القيمة الافتراضية

      return display.isNotEmpty ? display : 'مستخدم';
    }

    try {
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _userCache[userId] = data;

        String display = '';

        if (data['firstName'] != null) {
          display = '${data['firstName']} ${data['lastName'] ?? ''}'.trim();
        }

        if (display.isEmpty || display == 'مستخدم') {
          display = data['name'] ?? '';
        }

        // 3. إذا كان الاسم فارغاً أو "مستخدم"، نستخدم القيمة الافتراضية

        return display.isNotEmpty ? display : 'مستخدم';
      }
    } catch (e) {
      debugPrint('Error getting user name: $e');
    }
    return 'مستخدم';
  }

  /// تحميل أسماء المستخدمين مسبقاً لتحسين الأداء
  void _preCacheUserNames(List<Map<String, dynamic>> loadedChats) async {
    for (var chat in loadedChats) {
      final otherUserId = getOtherUserId(chat);
      if (otherUserId.isNotEmpty && !_userCache.containsKey(otherUserId)) {
        // جلب في الخلفية بدون انتظار
        getUserName(otherUserId);
      }
    }
  }

  /// جلب صورة المستخدم
  Future<String?> getUserImage(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]?['profileImage'];
    }
    // سيتم جلبها مع الاسم لاحقاً أو يمكن تحسين الجلب ليكون مرة واحدة
    return null;
  }

  /// جلب اسم المنتج (نقوم بجلب المنتج مرة واحدة)
  // يمكن نقل هذا لخدمة المنتجات ولكن للتبسيط هنا
  Future<String> getProductName(String? productId) async {
    if (productId == null || productId.isEmpty) return 'محادثة عامة';
    // للسرعة سنفترض أن الاسم مخزن في المحادثة أحياناً، أو نجلبه
    // هنا سنستخدم قيمة افتراضية أو نجلب من الـ DB إذا لزم
    return 'منتج'; // تحسين: جلب فعلي
  }

  /// إنشاء محادثة جديدة أو الحصول على محادثة موجودة
  Future<String?> createOrGetChat(String otherUserId, String? productId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      // البحث عن محادثة موجودة
      final existingChat = chats.firstWhereOrNull((chat) {
        final participants = chat['participants'] as Map?;
        final pId = chat['productId'];
        return participants != null &&
            participants[userId] == true &&
            participants[otherUserId] == true &&
            pId == productId;
      });

      if (existingChat != null) {
        return existingChat['id'];
      }

      // إنشاء محادثة جديدة
      final chatId = _chatsRef.push().key;
      if (chatId == null) return null;

      // ترتيب المستخدمين لضمان التناسق
      List<String> usersList = [userId, otherUserId];
      usersList.sort();

      final chatData = {
        'participants': {
          userId: true,
          otherUserId: true,
        },
        'user1Id': usersList[0],
        'user2Id': usersList[1],
        'productId': productId ?? '',
        'lastMessage': '',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'unreadCount': {
          userId: 0,
          otherUserId: 0,
        },
      };

      await _chatsRef.child(chatId).set(chatData);
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  /// تحديث آخر رسالة
  Future<void> updateLastMessage(String chatId, String message) async {
    // هذا يتم غالباً في الـ Backend أو عند الإرسال،
    // ولكن لا بأس من وجوده هنا إذا كنا نستخدمه في الواجهة
    // تم التنفيذ في ChatService
  }

  /// تصفير عداد الرسائل غير المقروءة
  Future<void> resetUnreadCount(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _chatsRef.child(chatId).child('unreadCount').update({userId: 0});
      // التحديث المحلي سيتم تلقائياً عبر المستمع (Stream)
    } catch (e) {
      debugPrint('Error resetting unread count: $e');
    }
  }

  /// حذف محادثة (يحذفها من قائمة المستخدم الحالي فقط)
  Future<void> deleteChat(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // حذف المحادثة من user_chats للمستخدم الحالي
      await FirebaseDatabase.instance
          .ref()
          .child('user_chats/$userId/$chatId')
          .remove();
      // ملاحظة: لا نحذف المحادثة الفعلية أو الرسائل، فقط نزيلها من قائمة المستخدم
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  /// حذف رسالة محددة
  Future<bool> deleteMessage(String chatId, String messageId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      // التحقق من أن المستخدم هو مرسل الرسالة
      final messageRef =
          FirebaseDatabase.instance.ref().child('messages/$chatId/$messageId');
      final snapshot = await messageRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (data['senderId'] == userId) {
          await messageRef.remove();
          debugPrint('✅ Message deleted: $messageId');
          return true;
        } else {
          debugPrint('❌ Cannot delete: not the sender');
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// حذف المحادثة بالكامل مع جميع الرسائل
  Future<bool> deleteChatCompletely(String chatId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      // 1. حذف جميع الرسائل
      await FirebaseDatabase.instance.ref().child('messages/$chatId').remove();

      // 2. حذف بيانات المحادثة الوصفية (metadata)
      // هذا يضمن إعادة تعيين المحادثة بالكامل عند البدء من جديد
      await FirebaseDatabase.instance.ref().child('chats/$chatId').remove();

      // 3. إزالة المحادثة من قائمة المستخدم الحالي
      await FirebaseDatabase.instance
          .ref()
          .child('user_chats/$userId/$chatId')
          .remove();

      // ملاحظة: قد نرغب في حذفها من قائمة الطرف الآخر أيضًا
      // ولكن سنتركها لتظهر فارغة أو تختفي عند التحديث لتجنب المشاكل

      // تحديث القائمة المحلية
      chats.removeWhere((chat) => chat['id'] == chatId);
      _chatMap.remove(chatId);
      _filterChats();

      debugPrint('✅ Chat deleted completely: $chatId');
      return true;
    } catch (e) {
      debugPrint('Error deleting chat completely: $e');
      return false;
    }
  }

  // قائمة المستخدمين المحظورين (مخزنة مؤقتاً)
  final RxSet<String> blockedUsers = <String>{}.obs;

  /// حظر مستخدم
  Future<bool> blockUser(String blockedUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final blockData = {
        'blockedAt': DateTime.now().millisecondsSinceEpoch,
        'blockedBy': userId,
      };

      await FirebaseDatabase.instance
          .ref()
          .child('blocked_users/$userId/$blockedUserId')
          .set(blockData);

      blockedUsers.add(blockedUserId);
      debugPrint('✅ User blocked: $blockedUserId');
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// إلغاء حظر مستخدم
  Future<bool> unblockUser(String blockedUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      await FirebaseDatabase.instance
          .ref()
          .child('blocked_users/$userId/$blockedUserId')
          .remove();

      blockedUsers.remove(blockedUserId);
      debugPrint('✅ User unblocked: $blockedUserId');
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// التحقق من حالة الحظر
  bool isUserBlocked(String userId) {
    return blockedUsers.contains(userId);
  }

  /// جلب قائمة المستخدمين المحظورين
  Future<void> loadBlockedUsers() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('blocked_users/$userId')
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        blockedUsers.clear();
        blockedUsers.addAll(data.keys.cast<String>());
        debugPrint('📋 Loaded ${blockedUsers.length} blocked users');
      }
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }

  /// التحقق مما إذا كان المستخدم محظوراً من قبل الطرف الآخر
  Future<bool> isBlockedByUser(String otherUserId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('blocked_users/$otherUserId/$userId')
          .get();

      return snapshot.exists;
    } catch (e) {
      debugPrint('Error checking if blocked by user: $e');
      return false;
    }
  }
}
