import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/services/encryption_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:intl/intl.dart' as intl;
import 'package:redsea/app/controllers/navigation_controller.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header: Title, Icons, Search, and Chips
          // شريط التصنيفات (Chips) فقط
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: _buildFilterChips(),
            ),
          ),

          // Chat list
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                );
              }

              final chats = controller.filteredChats.isEmpty &&
                      controller.searchQuery.value.isEmpty
                  ? controller.chats
                  : controller.filteredChats;

              if (chats.isEmpty) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildDemoChatItem(
                          _filterDemoChats(_getDemoChats())[index], index);
                    },
                    childCount: _filterDemoChats(_getDemoChats()).length,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chat = chats[index];
                    return _buildChatItem(chat, controller, index);
                  },
                  childCount: chats.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      'الكل',
      'البيع',
      'الشراء',
      'مقايضة',
      'خبرات',
      'غير مقروءة',
      'المفضلة'
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL support
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = filter);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.shade600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterDemoChats(
      List<Map<String, dynamic>> allChats) {
    if (_selectedFilter == 'الكل') return allChats;
    if (_selectedFilter == 'غير مقروءة')
      return allChats.where((c) => (c['unread'] ?? 0) > 0).toList();
    if (_selectedFilter == 'المفضلة')
      return allChats.where((c) => c['isFavorite'] == true).toList();
    if (_selectedFilter == 'خبرات')
      return allChats.where((c) => c['category'] == 'تبادل الخبرات').toList();
    return allChats.where((c) => c['category'] == _selectedFilter).toList();
  }

  /// بيانات الدردشات التجريبية
  List<Map<String, dynamic>> _getDemoChats() {
    return [
      {
        'id': 'demo_1',
        'name': 'خبير السيارات - أحمد',
        'lastMessage': 'يمكنني فحص السيارة غداً إن شاء الله',
        'time': 'الآن',
        'type': 'expert',
        'typeLabel': '🧠 خبير',
        'typeColor': const Color(0xFF1976D2),
        'unread': 2,
        'isOnline': true,
        'category': 'تبادل الخبرات',
        'isFavorite': true,
      },
      {
        'id': 'demo_2',
        'name': 'عبدالله أحمد',
        'lastMessage': 'موافق على تبادل الجهاز، متى نلتقي؟',
        'time': '10:30 ص',
        'type': 'barter',
        'typeLabel': '🔄 مقايضة',
        'typeColor': Colors.green,
        'unread': 1,
        'isOnline': true,
        'category': 'مقايضة',
        'isFavorite': false,
      },
      {
        'id': 'demo_3',
        'name': 'متجر النور',
        'lastMessage': 'طلبك قيد التجهيز الآن',
        'time': '11:15 ص',
        'type': 'selling',
        'typeLabel': '💰 بيع',
        'typeColor': Colors.orange,
        'unread': 0,
        'isOnline': true,
        'category': 'البيع',
        'isFavorite': true,
      },
      {
        'id': 'demo_4',
        'name': 'سوق العقارات',
        'lastMessage': 'هل الشقة لا تزال متاحة؟',
        'time': 'أمس',
        'type': 'buying',
        'typeLabel': '🛒 شراء',
        'typeColor': Colors.blue,
        'unread': 0,
        'isOnline': false,
        'category': 'الشراء',
        'isFavorite': false,
      },
      {
        'id': 'demo_5',
        'name': 'سالم خالد',
        'lastMessage': 'السلام عليكم، كم السعر النهائي؟',
        'time': 'السبت',
        'type': 'general',
        'typeLabel': '💬 عام',
        'typeColor': Colors.grey,
        'unread': 0,
        'isOnline': false,
        'category': 'البيع',
        'isFavorite': false,
      },
    ];
  }

  /// بناء عنصر دردشة تجريبية
  Widget _buildDemoChatItem(Map<String, dynamic> chat, int index) {
    final bool hasUnread = (chat['unread'] ?? 0) > 0;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Get.to(() => ChatPage(
                  chatId: chat['id'],
                  otherUserId: 'demo_user_${chat['id']}',
                  otherUserName: chat['name'],
                ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            chat['typeColor'] as Color,
                            (chat['typeColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: hasUnread
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (chat['name'] as String).isNotEmpty
                            ? (chat['name'] as String)[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (chat['isOnline'] == true)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    chat['name'] as String,
                                    style: TextStyle(
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (chat['typeColor'] as Color)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    chat['typeLabel'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: chat['typeColor'] as Color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            chat['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? AppColors.primary
                                  : Colors.grey.shade500,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 18,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chat['lastMessage'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${chat['unread']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(
      Map<String, dynamic> chat, ChatController controller, int index) {
    final otherUserId = controller.getOtherUserId(chat);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
      child: Dismissible(
        key: Key(chat['id']),
        background: Container(
          color: Colors.red.shade400,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text('حذف', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        secondaryBackground: Container(
          color: AppColors.primary.withValues(alpha: 0.6),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('أرشفة', style: TextStyle(color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.archive, color: Colors.white),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            return await _showDeleteConfirmation();
          }
          return false;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            controller.deleteChat(chat['id']);
          }
        },
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () async {
              HapticFeedback.selectionClick();
              controller.resetUnreadCount(chat['id']);
              final userName = await controller.getUserName(otherUserId);
              Get.to(() => ChatPage(
                    chatId: chat['id'],
                    otherUserId: otherUserId,
                    otherUserName: userName,
                  ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: FutureBuilder<String>(
                future: controller.getUserName(otherUserId),
                builder: (context, snapshot) {
                  final userName = snapshot.data ?? "جار التحميل...";
                  final dynamic rawMsg = chat['lastMessage'];
                  String lastMsgRaw = "";

                  if (rawMsg is String) {
                    lastMsgRaw = rawMsg;
                  } else if (rawMsg is Map) {
                    // معالجة الحالة التي يكون فيها الحقل كائن (Map)
                    lastMsgRaw = rawMsg['text']?.toString() ?? "";
                  }

                  final lastMessage = lastMsgRaw.isNotEmpty
                      ? EncryptionService.decrypt(lastMsgRaw)
                      : "لا توجد رسائل بعد";
                  final time = _formatTime(chat['lastMessageTime']);

                  final currentUid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  final unreadCount = chat['unreadCount']?[currentUid] ?? 0;
                  final bool hasUnread = unreadCount > 0;

                  return Row(
                    children: [
                      // Avatar with gradient
                      _buildAvatar(userName, hasUnread),
                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hasUnread
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade500,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (!hasUnread)
                                  Icon(
                                    Icons.done_all,
                                    size: 16,
                                    color: Colors.blue.shade300,
                                  ),
                                if (!hasUnread) const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: hasUnread
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                      fontWeight: hasUnread
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, bool hasUnread) {
    return Stack(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: hasUnread
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Online indicator
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.chatOnline,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('حذف المحادثة؟'),
            content: const Text('سيتم حذف المحادثة وجميع الرسائل نهائياً.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return intl.DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return intl.DateFormat('EEEE', 'ar').format(date);
    } else {
      return intl.DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
