import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:redsea/services/encryption_service.dart';

class ChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصول على معرف المستخدم الحالي
  String? get currentUserId => _auth.currentUser?.uid;

  // إنشاء محادثة جديدة أو الحصول على معرف المحادثة الموجودة
  Future<String> createOrGetChat(String otherUserId, String productId) async {
    if (currentUserId == null) throw Exception("User not logged in");

    // ترتيب معرفات المستخدمين أبجدياً لضمان نفس chatId لكلا الطرفين
    List<String> usersList = [currentUserId!, otherUserId];
    usersList.sort();

    // صيغة chatId: productId_sortedUser1_sortedUser2
    // هذا يضمن أن كلا المستخدمين يحصلان على نفس chatId
    String chatId = "${productId}_${usersList[0]}_${usersList[1]}";

    debugPrint('🔗 ChatService.createOrGetChat');
    debugPrint('   chatId: $chatId');
    debugPrint('   currentUserId: $currentUserId');
    debugPrint('   otherUserId: $otherUserId');

    try {
      // التحقق من وجود المحادثة
      final chatRef = _dbRef.child('chats/$chatId');
      final snapshot = await chatRef.get();

      if (!snapshot.exists) {
        debugPrint('🆕 إنشاء محادثة جديدة: $chatId');

        // إنشاء محادثة جديدة
        await chatRef.set({
          'participants': {
            usersList[0]: true,
            usersList[1]: true,
          },
          'user1Id': usersList[0],
          'user2Id': usersList[1],
          'lastMessage': "",
          'lastMessageTime': ServerValue.timestamp,
          'productId': productId,
          'createdAt': ServerValue.timestamp,
        });

        // تسجيل المحادثة في user_chats لكلا المستخدمين
        await _dbRef.child('user_chats/${usersList[0]}/$chatId').set({
          'chatId': chatId,
          'otherUserId': usersList[1],
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unread': false,
        });

        await _dbRef.child('user_chats/${usersList[1]}/$chatId').set({
          'chatId': chatId,
          'otherUserId': usersList[0],
          'lastMessage': '',
          'lastMessageTime': ServerValue.timestamp,
          'unread': false,
        });
      } else {
        debugPrint('✅ وجدت محادثة موجودة: $chatId');
        // تحديث وقت آخر رسالة فقط
        await chatRef.update({
          'lastMessageTime': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('❌ Error creating chat: $e');
      rethrow;
    }

    return chatId;
  }

  // رفع ملف (صورة أو صوت)
  Future<String?> uploadFile(File file, String chatId, String type) async {
    try {
      final String fileName =
          '${type}_${DateTime.now().millisecondsSinceEpoch}';
      final Reference ref =
          FirebaseStorage.instance.ref().child('chats/$chatId/$fileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: type == 'image' ? 'image/jpeg' : 'audio/mp4',
        customMetadata: {'uploaded_by': currentUserId ?? 'unknown'},
      );

      final UploadTask uploadTask = ref.putFile(file, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // إرسال رسالة
  Future<void> sendMessage(String chatId, String content, String receiverId,
      {Map<String, dynamic>? replyTo,
      String type = 'text',
      Map<String, dynamic>? metadata}) async {
    if (currentUserId == null) return;

    debugPrint('💬 sendMessage called:');
    debugPrint('   chatId: $chatId');
    debugPrint('   senderId (currentUserId): $currentUserId');
    debugPrint('   receiverId: $receiverId');

    // التحقق من حالة الحظر - هل المستلم حظر المرسل؟
    try {
      final blockedSnapshot =
          await _dbRef.child('blocked_users/$receiverId/$currentUserId').get();
      if (blockedSnapshot.exists) {
        debugPrint('🚫 Cannot send: You are blocked by this user');
        return; // المستلم حظر المرسل - لا ترسل الرسالة
      }

      // هل المرسل حظر المستلم؟
      final blockedByMeSnapshot =
          await _dbRef.child('blocked_users/$currentUserId/$receiverId').get();
      if (blockedByMeSnapshot.exists) {
        debugPrint('🚫 Cannot send: You have blocked this user');
        return; // لا يمكن الإرسال لمستخدم محظور
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
    }

    try {
      final DatabaseReference messageRef =
          _dbRef.child('messages/$chatId').push();

      String encryptedText = content;
      if (type == 'text') {
        encryptedText = EncryptionService.encrypt(content);
      }

      final Map<String, dynamic> messageData = {
        'senderId': currentUserId,
        'receiverId': receiverId,
        'text': encryptedText,
        'type': type,
        'timestamp': ServerValue.timestamp,
        'read': false,
        'replyTo': replyTo,
        'metadata': metadata,
      };

      // إضافة بيانات الرد إذا كانت موجودة
      if (replyTo != null) {
        messageData['replyTo'] = {
          'text': replyTo['text'],
          'senderId': replyTo['senderId'],
          'senderName':
              replyTo['senderId'] == currentUserId ? 'أنت' : 'المستخدم',
        };
      }

      await messageRef.set(messageData);
      debugPrint('📤 Message sent to path: messages/$chatId');
      debugPrint('   senderId: $currentUserId, receiverId: $receiverId');

      // تحديث آخر رسالة في المحادثة
      final String lastMsgText = type == 'text'
          ? 'رسالة نصية'
          : (type == 'image' ? '📷 صورة' : '🎤 رسالة صوتية');

      final updateData = {
        'lastMessage': lastMsgText,
        'lastMessageTime': ServerValue.timestamp,
        'participants/${currentUserId!}': true,
        'participants/$receiverId': true,
        'users/${currentUserId!}': true,
        'users/$receiverId': true,
      };

      await _dbRef.child('chats/$chatId').update(updateData);

      // *** مهم: تسجيل المحادثة في user_chats لكلا المستخدمين ***
      // هذا يسمح لكل مستخدم برؤية المحادثات الخاصة به
      final userChatData = {
        'chatId': chatId,
        'otherUserId': receiverId,
        'lastMessage': lastMsgText,
        'lastMessageTime': ServerValue.timestamp,
        'unread': false,
      };

      await _dbRef
          .child('user_chats/${currentUserId!}/$chatId')
          .set(userChatData);

      final receiverChatData = {
        'chatId': chatId,
        'otherUserId': currentUserId,
        'lastMessage': lastMsgText,
        'lastMessageTime': ServerValue.timestamp,
        'unread': true,
      };

      await _dbRef
          .child('user_chats/$receiverId/$chatId')
          .set(receiverChatData);

      // زيادة عداد الرسائل غير المقروءة للمستلم
      final unreadRef = _dbRef.child('chats/$chatId/unreadCount/$receiverId');
      final unreadSnapshot = await unreadRef.get();
      int currentUnread = 0;
      if (unreadSnapshot.exists && unreadSnapshot.value != null) {
        currentUnread = (unreadSnapshot.value as int?) ?? 0;
      }
      await unreadRef.set(currentUnread + 1);

      // إرسال إشعار للمستلم
      String notificationBody = content;
      if (type == 'image') notificationBody = '📷 أرسل صورة';
      if (type == 'audio') notificationBody = '🎤 أرسل رسالة صوتية';

      await _sendNotification(receiverId, notificationBody, chatId);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // إرسال إشعار للمستلم
  Future<void> _sendNotification(
      String receiverId, String message, String chatId) async {
    debugPrint('📢 _sendNotification called:');
    debugPrint('   receiverId: $receiverId');
    debugPrint('   currentUserId: $currentUserId');
    debugPrint('   chatId: $chatId');

    try {
      // الحصول على اسم المرسل (المستخدم الحالي)
      String senderName = 'مستخدم';
      try {
        final snapshot = await _dbRef.child('users/$currentUserId').get();
        if (snapshot.exists) {
          final baseMap = snapshot.value as Map;
          final userData = Map<String, dynamic>.from(baseMap);
          senderName = userData['name'] ?? userData['displayName'] ?? 'مستخدم';
        }
      } catch (e) {
        debugPrint('   Error getting sender name: $e');
      }

      debugPrint('   senderName: $senderName');
      debugPrint('   Writing to: notifications/$receiverId');

      final notificationRef = _dbRef.child('notifications/$receiverId').push();
      await notificationRef.set({
        'title': 'رسالة جديدة من $senderName',
        'body': message,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'type': 'chat',
        'senderId': currentUserId,
        'recipientId': receiverId,
        'chatId': chatId,
      });

      debugPrint(
          '✅ Notification sent successfully to: notifications/$receiverId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // الحصول على تيار الرسائل
  Stream<DatabaseEvent> getMessagesStream(String chatId) {
    return _dbRef.child('messages/$chatId').orderByChild('timestamp').onValue;
  }

  // الحصول على قائمة معرفات محادثات المستخدم (الطريقة الآمنة)
  // هذا يستخدم user_chats/{userId} لجلب معرفات المحادثات فقط
  Stream<DatabaseEvent> getUserChatsStream() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return _dbRef.child('user_chats/$currentUserId').onValue;
  }

  // جلب تفاصيل محادثة واحدة
  Future<Map<String, dynamic>?> getChatDetails(String chatId) async {
    try {
      final snapshot = await _dbRef.child('chats/$chatId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = chatId;
        return data;
      }
    } catch (e) {
      debugPrint('Error getting chat details: $e');
    }
    return null;
  }

  // الاستماع لتغييرات محادثة واحدة (Realtime)
  Stream<DatabaseEvent> getChatStream(String chatId) {
    return _dbRef.child('chats/$chatId').onValue;
  }

  // جلب اسم المستخدم من قاعدة البيانات
  Future<String> getUserName(String userId) async {
    try {
      final snapshot = await _dbRef.child('users').child(userId).once();
      if (snapshot.snapshot.value != null) {
        final userData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        return userData['displayName'] ?? userData['name'] ?? 'مستخدم';
      }
      return 'مستخدم';
    } catch (e) {
      return 'مستخدم';
    }
  }

  // جلب اسم المنتج
  Future<String> getProductName(String productId) async {
    try {
      final snapshot = await _dbRef.child('products').child(productId).once();
      if (snapshot.snapshot.value != null) {
        final productData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        return productData['name'] ?? 'منتج';
      }
      return 'منتج';
    } catch (e) {
      return 'منتج';
    }
  }
}
