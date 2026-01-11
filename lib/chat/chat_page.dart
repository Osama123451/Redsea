import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redsea/services/chat_service.dart';
import 'package:redsea/services/encryption_service.dart';
import 'package:redsea/services/imgbb_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';

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

  // Subscription للـ typing status
  StreamSubscription<DatabaseEvent>? _typingSubscription;

  // Audio & Image
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isRecording = false;
  String? _audioPath;
  static final AudioPlayer _globalAudioPlayer = AudioPlayer();
  AudioPlayer get _audioPlayer => _globalAudioPlayer;

  // Audio Playback State
  String? _currentlyPlayingId;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;
  final Stopwatch _recordingStopwatch = Stopwatch();

  // Streams
  late Stream<DatabaseEvent> _messagesStream;

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

    // Audio Player Listeners
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
          _currentlyPlayingId = null;
        });
      }
    });

    // Initialize messages stream
    _messagesStream = _chatService.getMessagesStream(widget.chatId);

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
    // إلغاء الاشتراك أولاً لمنع التعليق
    _typingSubscription?.cancel();
    _updateTypingStatus(false);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
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
    _typingSubscription = ref.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _otherUserTyping = event.snapshot.value == true;
        });
      }
    });
  }

  // التقاط صورة
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        requestFullMetadata: false, // قد يساعد في بعض الأجهزة
      );

      if (image != null) {
        _uploadAndSendFile(File(image.path), 'image');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (e.toString().contains('permission')) {
        Get.snackbar(
          'تنبيه',
          'يرجى منح صلاحية الوصول للصور',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('خطأ', 'فشل اختيار الصورة',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  // تسجيل صوت
  Future<void> _startRecording() async {
    try {
      // طلب الإذن بشكل صريح باستخدام permission_handler
      var status = await Permission.microphone.status;

      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (status.isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // تكوين التسجيل
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
        );

        _recordingStopwatch.reset();
        _recordingStopwatch.start();
        await _audioRecorder.start(config, path: path);

        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      } else {
        // إذا تم رفض الإذن
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        Get.snackbar(
          'تنبيه',
          'يرجى منح صلاحية الميكروفون لتسجيل الصوت',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      Get.snackbar('خطأ', 'فشل بدء التسجيل: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordingStopwatch.stop();
      final duration = _recordingStopwatch.elapsedMilliseconds;
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _uploadAndSendFile(File(path), 'audio', duration: duration);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _uploadAndSendFile(File file, String type,
      {int? duration}) async {
    // إظهار مؤشر تحميل (يمكن تحسينه)
    Get.snackbar(
      'جاري الإرسال',
      type == 'image' ? 'جاري رفع الصورة...' : 'جاري معالجة التسجيل...',
      showProgressIndicator: true,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );

    String? url;

    try {
      // استخدام ImgBB للصور
      if (type == 'image') {
        url = await ImgBBService.uploadImage(file);
      } else if (type == 'audio') {
        // تحويل الصوت إلى Base64 وتخزينه مباشرة
        final bytes = await file.readAsBytes();
        url = base64Encode(bytes);
      } else {
        url = await _chatService.uploadFile(file, widget.chatId, type);
      }

      if (url != null) {
        Map<String, dynamic>? metadata;
        if (type == 'audio' && duration != null) {
          metadata = {'duration': duration};
        }

        await _chatService.sendMessage(
          widget.chatId,
          url,
          widget.otherUserId,
          type: type,
          replyTo: _replyingTo,
          metadata: metadata,
        );

        // إخفاء الرد بعد الإرسال
        setState(() => _replyingTo = null);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'خطأ',
        'فشل الرفع: $errorMessage',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
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
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _messagesStream,
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

                    List<Map<String, dynamic>> messages = [];
                    for (var child in snapshot.data!.snapshot.children) {
                      if (child.value == null) continue;
                      final msg = Map<String, dynamic>.from(child.value as Map);
                      msg['id'] = child.key;
                      messages.add(msg);
                    }

                    // الترتيب من الأقدم للأحدث (اختياري حسب ListView)
                    // messages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                    debugPrint(
                        '📨 Loaded ${messages.length} messages for chat: ${widget.chatId}');

                    messages.sort((a, b) =>
                        (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

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
                  color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
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
              color: Colors.black.withOpacity(0.05),
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

    final bool isAudio = msg['type'] == 'audio';

    Widget bubble = Padding(
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isAudio
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasReply)
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                child: _buildReplyInMessage(msg['replyTo'])),
                          _buildAudioMessage(
                              msg['text'], isMe, msg['metadata'], msg['id']),
                          const SizedBox(height: 2),
                          _buildMessageStatus(msg, isMe),
                        ],
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onLongPress: () => _showMessageOptions(msg),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasReply)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    child:
                                        _buildReplyInMessage(msg['replyTo'])),
                              if (msg['type'] == 'image')
                                _buildImageMessage(msg['text'], isMe)
                              else
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  child: Text(
                                    EncryptionService.decrypt(
                                        msg['text'] ?? ''),
                                    style: TextStyle(
                                      color: Colors.grey.shade900,
                                      fontSize: 16,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 2),
                              _buildMessageStatus(msg, isMe),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );

    if (isAudio) return bubble;

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
      child: bubble,
    );
  }

  Widget _buildMessageStatus(Map<String, dynamic> msg, bool isMe) {
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] ?? 0);
    final formattedTime = intl.DateFormat('HH:mm').format(timestamp);

    IconData? statusIcon;
    Color? iconColor;

    if (isMe) {
      final status = msg['status'];
      if (status == 'sent') {
        statusIcon = Icons.done;
        iconColor = Colors.grey.shade500;
      } else if (status == 'delivered') {
        statusIcon = Icons.done_all;
        iconColor = Colors.grey.shade500;
      } else if (status == 'read') {
        statusIcon = Icons.done_all;
        iconColor = AppColors.primary;
      } else {
        statusIcon = Icons.access_time; // Pending
        iconColor = Colors.grey.shade500;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 10,
        right: isMe ? 10 : 0,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.grey.shade300 : Colors.grey.shade500,
            ),
          ),
          if (isMe && statusIcon != null) ...[
            const SizedBox(width: 4),
            Icon(
              statusIcon,
              size: 14,
              color: iconColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInMessage(Map<dynamic, dynamic> replyData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
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
              color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
                    icon: Icon(Icons.image, color: Colors.grey.shade600),
                    onPressed: _pickImage,
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
                onTap: () {
                  if (_isTyping) {
                    _sendMessage();
                  } else {
                    // تنبيه المستخدم بالضغط المطول
                    Get.closeAllSnackbars();
                    Get.snackbar(
                      'تسجيل صوتي',
                      'اضغط مطولاً للتسجيل',
                      backgroundColor: AppColors.primary,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 1),
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
                onLongPress: () {
                  if (!_isTyping) _startRecording();
                },
                onLongPressEnd: (_) {
                  if (!_isTyping) _stopRecording();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isTyping
                        ? Icons.send
                        : (_isRecording ? Icons.stop : Icons.mic),
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

  Widget _buildImageMessage(String url, bool isMe) {
    return GestureDetector(
      onTap: () {
        // TODO: Show full screen image
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage(String url, bool isMe,
      [dynamic metadata, String? messageId]) {
    final Map<String, dynamic>? meta =
        metadata != null ? Map<String, dynamic>.from(metadata) : null;
    final bool isThisPlaying = _currentlyPlayingId == messageId;
    final bool isActuallyPlaying =
        isThisPlaying && _playerState == PlayerState.playing;

    // الحصول على المدة المخزنة في metadata إذا لم تكن الرسالة قيد التشغيل حالياً أو في بدايتها
    final int storedDurationMs = meta?['duration'] ?? 0;
    final Duration displayDuration =
        (isThisPlaying && _duration != Duration.zero)
            ? _duration
            : Duration(milliseconds: storedDurationMs);
    final Duration displayPosition = isThisPlaying ? _position : Duration.zero;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        try {
          debugPrint('🎯 TAP on ID: $messageId | State: ${_playerState.name}');

          if (isThisPlaying) {
            if (_playerState == PlayerState.playing) {
              debugPrint('🛑 PAUSE command fired');
              await _audioPlayer.pause();
              setState(() => _playerState = PlayerState.paused);
            } else {
              debugPrint('▶ RESUME command fired');
              await _audioPlayer.resume();
              setState(() => _playerState = PlayerState.playing);
            }
            return;
          }

          // New Audio
          debugPrint('🆕 NEW PLAY command fired');
          await _audioPlayer.stop();

          setState(() {
            _currentlyPlayingId = messageId;
            _position = Duration.zero;
            _duration = Duration(milliseconds: storedDurationMs);
          });

          final bytes = base64Decode(url);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/audio_${messageId.hashCode}.m4a');
          await file.writeAsBytes(bytes);
          await _audioPlayer.play(DeviceFileSource(file.path));
        } catch (e) {
          debugPrint('Error: $e');
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Colors.transparent, // ضروري مع HitTestBehavior.opaque
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isMe
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    isActuallyPlaying ? Icons.pause : Icons.play_arrow,
                    color: isMe ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رسالة صوتية',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: displayDuration.inMilliseconds > 0
                              ? displayPosition.inMilliseconds /
                                  displayDuration.inMilliseconds
                              : 0.0,
                          backgroundColor:
                              isMe ? Colors.white24 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMe ? Colors.white : AppColors.primary,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 52),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(displayPosition),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _formatDuration(displayDuration),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
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
