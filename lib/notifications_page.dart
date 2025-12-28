// notification_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'
    as intl; // Alias to avoid conflict if any data has similar names
import 'app/controllers/notifications_controller.dart';
import 'app/core/app_theme.dart';
import 'chat/chat_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationsController controller = Get.put(NotificationsController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Theme.of(context).iconTheme.color),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => controller.unreadCount.value > 0
              ? TextButton.icon(
                  onPressed: () => controller.markAllAsRead(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('قراءة الكل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                )
              : const SizedBox()),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            _buildTab('الكل', controller.unreadCount),
            _buildTab('المحادثات', controller.unreadChatCount),
            _buildTab('الطلبات', controller.unreadOrderCount),
            _buildTab('الإدارة', controller.unreadAdminCount),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(null), // الكل
          _buildNotificationList('chat'),
          _buildNotificationList('order'),
          _buildNotificationList('admin'),
        ],
      ),
    );
  }

  Widget _buildTab(String title, RxInt count) {
    return Tab(
      child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count.value > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.value > 99 ? '99+' : count.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          )),
    );
  }

  Widget _buildNotificationList(String? filterType) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      List<Map<String, dynamic>> filteredNotifications;
      if (filterType == null) {
        filteredNotifications = controller.notifications.toList();
      } else if (filterType == 'order') {
        filteredNotifications = controller.notifications
            .where((n) =>
                n['type'] == 'order' ||
                n['type'] == 'orderComplete' ||
                n['type'] == 'orderPending')
            .toList();
      } else if (filterType == 'admin') {
        filteredNotifications = controller.notifications
            .where((n) => n['isAdmin'] == true || n['type'] == 'system')
            .toList();
      } else {
        filteredNotifications = controller.notifications
            .where((n) => n['type'] == filterType)
            .toList();
      }

      if (filteredNotifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 64,
                  color: Theme.of(context)
                      .iconTheme
                      .color
                      ?.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'لا توجد إشعارات',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7)),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // زر حذف الكل
          if (filterType == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _showClearNotificationsDialog(context, controller),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف جميع الإشعارات'),
                  ),
                ],
              ),
            ),

          // قائمة الإشعارات
          Expanded(
            child: ListView.builder(
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(
                    filteredNotifications[index], controller);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildNotificationItem(
      Map<String, dynamic> notification, NotificationsController controller) {
    final bool isRead = notification['isRead'] == true;
    final int timestamp = notification['timestamp'] ?? 0;
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final String timeStr = _formatTime(date);
    final String type = notification['type'] ?? 'general';
    final bool isAdmin = notification['isAdmin'] == true;
    final bool isChat = type == 'chat';

    // الحصول على اللون والأيقونة حسب النوع
    final typeInfo = _getTypeInfo(type, isAdmin);

    return Dismissible(
      key: Key(notification['id'] ?? ''),
      direction: isAdmin ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        child: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('حذف',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الإشعار'),
            content: const Text('هل تريد حذف هذا الإشعار؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        controller.deleteNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الإشعار'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            controller.markAsRead(notification['id']);
          }
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? Theme.of(context).cardColor
                : typeInfo['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead
                  ? Colors.grey.shade200
                  : typeInfo['color'].withValues(alpha: 0.3),
              width: isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // محتوى الإشعار
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                notification['title'] ?? 'إشعار',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: isRead
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                      : typeInfo['color'],
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification['message'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'من الإدارة',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // أيقونة النوع
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeInfo['color'].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        typeInfo['icon'],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ],
              ),

              // أزرار التفاعل لإشعارات المحادثات
              if (isChat) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // زر الحذف
                    TextButton.icon(
                      onPressed: () {
                        controller.deleteNotification(notification['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حذف الإشعار'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('حذف', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // زر الرد
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!isRead) {
                          controller.markAsRead(notification['id']);
                        }
                        _handleNotificationTap(notification);
                      },
                      icon: const Icon(Icons.reply, size: 18),
                      label: const Text('رد', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type, bool isAdmin) {
    if (isAdmin) {
      return {'icon': '📢', 'color': Colors.orange};
    }

    switch (type) {
      case 'chat':
        return {'icon': '💬', 'color': Colors.blue};
      case 'order':
        return {'icon': '📦', 'color': Colors.purple};
      case 'orderComplete':
        return {'icon': '✅', 'color': Colors.green};
      case 'orderPending':
        return {'icon': '⏳', 'color': Colors.amber};
      case 'system':
        return {'icon': '🔔', 'color': Colors.teal};
      case 'promotion':
        return {'icon': '🎉', 'color': Colors.pink};
      default:
        return {'icon': '📌', 'color': Colors.grey};
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'قبل ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'قبل ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'قبل ${difference.inDays} يوم';
    } else {
      return intl.DateFormat('yyyy-MM-dd').format(date);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];

    switch (type) {
      case 'chat':
        final chatId = notification['chatId'];
        final senderId = notification['senderId'];

        // استخراج اسم المرسل من العنوان
        final String title = notification['title'] ?? '';
        String otherUserName = 'مستخدم';
        if (title.contains('من ')) {
          otherUserName = title.split('من ').last;
        }

        if (chatId != null && senderId != null) {
          Get.to(() => ChatPage(
                chatId: chatId,
                otherUserId: senderId,
                otherUserName: otherUserName,
              ));
        } else {
          // محاولة للتنقل حتى لو البيانات ناقصة (للإشعارات القديمة)
          // يمكننا توجيه المستخدم لصفحة المحادثات العامة
          Get.snackbar('تنبيه',
              'لا يمكن فتح المحادثة مباشرة، يرجى الذهاب لقائمة المحادثات');
        }
        break;
      case 'order':
      case 'orderComplete':
      case 'orderPending':
        final orderId = notification['orderId'];
        if (orderId != null) {
          // Navigate to order details
          // Get.toNamed(AppRoutes.orders);
        }
        break;
      default:
        break;
    }
  }

  void _showClearNotificationsDialog(
      BuildContext context, NotificationsController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف الإشعارات'),
          content: const Text(
              'هل أنت متأكد من رغبتك في حذف جميع الإشعارات؟\n(إشعارات الإدارة لن تُحذف)'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                controller.clearAllNotifications();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف جميع الإشعارات')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('حذف الكل'),
            ),
          ],
        );
      },
    );
  }
}
