import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:redsea/services/encryption_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:intl/intl.dart' as intl;

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String currentUserId = '';
  bool _isTyping = false;
  bool _otherUserTyping = false;
  bool _isUserBlocked = false;
  Map<String, dynamic>? _replyingTo;

  // Animation controllers
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    debugPrint('🚀 ChatPage opened:');
    debugPrint('   chatId: ${widget.chatId}');
    debugPrint('   currentUserId: $currentUserId');
    debugPrint('   otherUserId: ${widget.otherUserId}');

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOut),
    );

    _messageController.addListener(_onTextChanged);
    _listenToTypingStatus();

    // تحديد إشعارات هذه المحادثة كمقروءة
    _markNotificationsAsRead();

    // التحقق من حالة الحظر
    _checkBlockStatus();
  }

  /// التحقق من حالة الحظر
  Future<void> _checkBlockStatus() async {
    try {
      final chatController = Get.find<ChatController>();
      if (mounted) {
        setState(() {
          _isUserBlocked = chatController.isUserBlocked(widget.otherUserId);
        });
      }
    } catch (e) {
      debugPrint('Error checking block status: $e');
    }
  }

  /// تحديد إشعارات المحادثة كمقروءة
  void _markNotificationsAsRead() {
    try {
      if (Get.isRegistered<NotificationsController>()) {
        final notificationsController = Get.find<NotificationsController>();
        notificationsController.markChatNotificationsAsRead(widget.chatId);
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _updateTypingStatus(false);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText && !_isTyping) {
      _isTyping = true;
      _sendButtonController.forward();
      _updateTypingStatus(true);
    } else if (!hasText && _isTyping) {
      _isTyping = false;
      _sendButtonController.reverse();
      _updateTypingStatus(false);
    }
  }

  void _updateTypingStatus(bool isTyping) {
    final ref = FirebaseDatabase.instance
        .ref()
        .child('chats/${widget.chatId}/typing/$currentUserId');
    ref.set(isTyping);
  }

  void _listenToTypingStatus() {
    final ref = FirebaseDatabase.instance
        .ref()
        .child('chats/${widget.chatId}/typing/${widget.otherUserId}');
    ref.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _otherUserTyping = event.snapshot.value == true;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    final text = _messageController.text.trim();
    final replyData = _replyingTo;

    _messageController.clear();
    setState(() => _replyingTo = null);

    await _chatService.sendMessage(
      widget.chatId,
      text,
      widget.otherUserId,
      replyTo: replyData,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _setReplyingTo(Map<String, dynamic> message) {
    HapticFeedback.selectionClick();
    setState(() => _replyingTo = message);
    _focusNode.requestFocus();
  }

  /// معالجة خيارات القائمة المنبثقة
  void _handleMenuAction(String action) {
    switch (action) {
      case 'view':
        // عرض الملف الشخصي
        Get.snackbar('قريباً', 'سيتم إضافة عرض الملف الشخصي',
            backgroundColor: AppColors.primary, colorText: Colors.white);
        break;
      case 'media':
        Get.snackbar('قريباً', 'سيتم إضافة عرض الوسائط',
            backgroundColor: AppColors.primary, colorText: Colors.white);
        break;
      case 'search':
        Get.snackbar('قريباً', 'سيتم إضافة البحث في المحادثة',
            backgroundColor: AppColors.primary, colorText: Colors.white);
        break;
      case 'mute':
        Get.snackbar('قريباً', 'سيتم إضافة كتم الإشعارات',
            backgroundColor: AppColors.primary, colorText: Colors.white);
        break;
      case 'delete_chat':
        _showDeleteChatConfirmation();
        break;
      case 'block':
        _showBlockUserConfirmation();
        break;
      case 'unblock':
        _showUnblockUserConfirmation();
        break;
    }
  }

  /// حذف رسالة
  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الرسالة؟'),
        content: const Text('سيتم حذف هذه الرسالة نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final chatController = Get.find<ChatController>();
        final success =
            await chatController.deleteMessage(widget.chatId, msg['id']);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الرسالة')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حذف الرسالة')),
          );
        }
      }
    }
  }

  /// تأكيد حذف المحادثة
  Future<void> _showDeleteChatConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المحادثة؟'),
        content: const Text('سيتم حذف جميع الرسائل في هذه المحادثة نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final chatController = Get.find<ChatController>();
        final success =
            await chatController.deleteChatCompletely(widget.chatId);
        if (success && mounted) {
          Get.back();
          Get.snackbar('تم', 'تم حذف المحادثة',
              backgroundColor: AppColors.success, colorText: Colors.white);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حذف المحادثة')),
          );
        }
      }
    }
  }

  /// تأكيد حظر المستخدم
  Future<void> _showBlockUserConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حظر المستخدم؟'),
        content: Text(
            'هل أنت متأكد من حظر ${widget.otherUserName}؟\n\nلن تتمكن من تلقي رسائل منه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حظر', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final chatController = Get.find<ChatController>();
        final success = await chatController.blockUser(widget.otherUserId);
        if (success && mounted) {
          await _checkBlockStatus(); // تحديث الحالة
          Get.snackbar('تم', 'تم حظر ${widget.otherUserName}',
              backgroundColor: AppColors.error, colorText: Colors.white);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حظر المستخدم')),
          );
        }
      }
    }
  }

  /// تأكيد إلغاء حظر المستخدم
  Future<void> _showUnblockUserConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء حظر المستخدم؟'),
        content: Text(
            'هل أنت متأكد من إلغاء حظر ${widget.otherUserName}؟\n\nستتمكن من تبادل الرسائل معه مرة أخرى.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إلغاء الحظر',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final chatController = Get.find<ChatController>();
        final success = await chatController.unblockUser(widget.otherUserId);
        if (success && mounted) {
          await _checkBlockStatus(); // تحديث الحالة
          Get.snackbar('تم', 'تم إلغاء حظر ${widget.otherUserName}',
              backgroundColor: AppColors.success, colorText: Colors.white);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إلغاء حظر المستخدم')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBackground, // Unified background
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                debugPrint(
                    '📥 ChatPage receiving stream for chatId: ${widget.chatId}');
                debugPrint(
                    '   hasData: ${snapshot.hasData}, value: ${snapshot.data?.snapshot.value != null}');

                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return _buildEmptyState();
                }

                Map<dynamic, dynamic> messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> messages = [];

                messagesMap.forEach((key, value) {
                  final msg = Map<String, dynamic>.from(value);
                  msg['id'] = key;
                  messages.add(msg);
                });

                debugPrint(
                    '📨 Loaded ${messages.length} messages for chat: ${widget.chatId}');

                messages.sort((a, b) =>
                    (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return _buildMessagesList(messages);
              },
            ),
          ),
          // Typing indicator
          if (_otherUserTyping) _buildTypingIndicator(),
          // Reply preview
          if (_replyingTo != null) _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: AppColors.primary, // Unified blue
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Hero(
                tag: 'avatar_${widget.otherUserId}',
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  radius: 20,
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.chatOnline,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _otherUserTyping ? "يكتب..." : "متصل الآن",
                    key: ValueKey(_otherUserTyping),
                    style: TextStyle(
                      color: _otherUserTyping
                          ? AppColors.primaryLight
                          : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('عرض الملف الشخصي')),
            const PopupMenuItem(
                value: 'media', child: Text('الوسائط والملفات')),
            const PopupMenuItem(value: 'search', child: Text('بحث')),
            const PopupMenuItem(value: 'mute', child: Text('كتم الإشعارات')),
            const PopupMenuItem(
                value: 'delete_chat', child: Text('حذف المحادثة')),
            PopupMenuItem(
              value: _isUserBlocked ? 'unblock' : 'block',
              child: Text(
                _isUserBlocked ? 'إلغاء الحظر' : 'حظر',
                style: TextStyle(
                    color: _isUserBlocked ? Colors.green : Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.waving_hand,
              size: 60,
              color: Colors.amber.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "ابدأ محادثة مع ${widget.otherUserName}",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "أرسل رسالة ترحيبية 👋",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Map<String, dynamic>> messages) {
    // Group messages by date
    Map<String, List<Map<String, dynamic>>> groupedMessages = {};

    for (var msg in messages) {
      final date = DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] ?? 0);
      final dateKey = _getDateKey(date);
      groupedMessages.putIfAbsent(dateKey, () => []);
      groupedMessages[dateKey]!.add(msg);
    }

    List<Widget> widgets = [];

    groupedMessages.forEach((dateKey, dayMessages) {
      // Date divider
      widgets.add(_buildDateDivider(dateKey));

      // Messages
      for (int i = 0; i < dayMessages.length; i++) {
        final msg = dayMessages[i];
        final String messageSenderId = msg['senderId']?.toString() ?? '';
        final bool isMe =
            messageSenderId.isNotEmpty && messageSenderId == currentUserId;
        debugPrint(
            'Message: senderId=$messageSenderId, currentUserId=$currentUserId, isMe=$isMe');
        final bool showTail = i == dayMessages.length - 1 ||
            dayMessages[i + 1]['senderId'] != msg['senderId'];

        widgets.add(
          _AnimatedMessageBubble(
            key: ValueKey(msg['id']),
            child: _buildMessageBubble(msg, isMe, showTail),
          ),
        );
      }
    });

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      children: widgets,
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'اليوم';
    } else if (messageDate == yesterday) {
      return 'أمس';
    } else {
      return intl.DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildDateDivider(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          date,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> msg, bool isMe, bool showTail) {
    final hasReply = msg['replyTo'] != null;

    return Dismissible(
      key: ValueKey('dismiss_${msg['id']}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        _setReplyingTo(msg);
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: Colors.grey),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 4,
          bottom: showTail ? 12 : 4,
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
        ),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.chatBubbleSent
                    : AppColors.chatBubbleReceived,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe || !showTail ? 16 : 4),
                  bottomRight: Radius.circular(!isMe || !showTail ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onLongPress: () => _showMessageOptions(msg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview in message
                          if (hasReply) _buildReplyInMessage(msg['replyTo']),
                          // Message text
                          Text(
                            EncryptionService.decrypt(msg['text'] ?? ''),
                            style: TextStyle(
                              color: Colors.grey.shade900,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Time and read status
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(msg['timestamp']),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  msg['read'] == true
                                      ? Icons.done_all
                                      : Icons.done,
                                  size: 16,
                                  color: msg['read'] == true
                                      ? AppColors.primary
                                      : Colors.grey.shade400,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInMessage(Map<dynamic, dynamic> replyData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyData['senderName'] ?? 'مستخدم',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            EncryptionService.decrypt(replyData['text'] ?? ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primary),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(context);
                _setReplyingTo(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('نسخ'),
              onTap: () {
                Clipboard.setData(ClipboardData(
                    text: EncryptionService.decrypt(msg['text'] ?? '')));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward, color: AppColors.success),
              title: const Text('إعادة توجيه'),
              onTap: () => Navigator.pop(context),
            ),
            if (msg['senderId'] == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('حذف'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteMessage(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            _buildTypingDot(1),
            _buildTypingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          left: const BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!['senderId'] == currentUserId
                      ? 'أنت'
                      : widget.otherUserName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EncryptionService.decrypt(_replyingTo!['text'] ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji button
          IconButton(
            icon: Icon(Icons.emoji_emotions_outlined,
                color: Colors.grey.shade600),
            onPressed: () {},
          ),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 16),
                      maxLines: null,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: "اكتب رسالة...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send/Mic button with animation
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: _isTyping ? _sendMessage : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isTyping ? Icons.send : Icons.mic,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return intl.DateFormat('hh:mm a').format(date);
  }
}

// Animated message bubble wrapper
class _AnimatedMessageBubble extends StatefulWidget {
  final Widget child;

  const _AnimatedMessageBubble({super.key, required this.child});

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
