import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/services/encryption_service.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:intl/intl.dart' as intl;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // App-style AppBar
          SliverAppBar(
            expandedHeight: _isSearching ? 60 : 120,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      setState(() => _isSearching = false);
                      _searchController.clear();
                      controller.setSearchQuery('');
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'بحث...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => controller.setSearchQuery(value),
                  )
                : null,
            flexibleSpace: _isSearching
                ? null
                : FlexibleSpaceBar(
                    title: const Text(
                      'المحادثات',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                    ),
                  ),
            actions: [
              if (!_isSearching) ...[
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => setState(() => _isSearching = true),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'new_group',
                      child: Text('مجموعة جديدة'),
                    ),
                    const PopupMenuItem(
                      value: 'new_broadcast',
                      child: Text('قائمة بث جديدة'),
                    ),
                    const PopupMenuItem(
                      value: 'starred',
                      child: Text('الرسائل المميزة'),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('الإعدادات'),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Chat list
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              }

              final chats = controller.filteredChats.isEmpty &&
                      controller.searchQuery.value.isEmpty
                  ? controller.chats
                  : controller.filteredChats;

              if (chats.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
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
      // WhatsApp-style FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Open contact list to start new chat
          Get.snackbar(
            'قريباً',
            'اختيار جهة اتصال لبدء محادثة جديدة',
            backgroundColor: AppColors.primary,
            colorText: Colors.white,
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated illustration
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text(
          "لا توجد محادثات",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "ابدأ محادثة جديدة مع البائعين",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text(
            'محادثة جديدة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: FutureBuilder<String>(
                future: controller.getUserName(otherUserId),
                builder: (context, snapshot) {
                  final userName = snapshot.data ?? "جار التحميل...";
                  final lastMessage =
                      EncryptionService.decrypt(chat['lastMessage'] ?? '');
                  final time = _formatTime(chat['lastMessageTime']);

                  // حساب الرسائل غير المقروءة بشكل صحيح
                  final currentUid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  final unreadCount = chat['unreadCount']?[currentUid] ?? 0;
                  final bool hasUnread = unreadCount > 0;

                  return Row(
                    children: [
                      // Avatar with gradient
                      _buildAvatar(userName, hasUnread),
                      const SizedBox(width: 16),

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
                                    fontSize: 17,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  time,
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
                                // Read status icon
                                Icon(
                                  Icons.done_all,
                                  size: 18,
                                  color:
                                      AppColors.primary.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
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
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
