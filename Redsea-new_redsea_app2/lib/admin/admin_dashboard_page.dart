import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/services/report_service.dart';
import 'package:redsea/services/user_report_service.dart';
import 'package:intl/intl.dart' as intl;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AuthController authController = Get.find<AuthController>();

  // إحصائيات
  int _usersCount = 0;
  int _productsCount = 0;
  int _ordersCount = 0;
  int _chatsCount = 0;
  int _reportsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // التحقق من صلاحيات الأدمن
    if (!authController.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        authController.showNoPermission('هذه الصفحة للمسؤولين فقط');
      });
    } else {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // عدد المستخدمين
      final usersSnapshot = await dbRef.child('users').get();
      if (usersSnapshot.exists) {
        _usersCount = (usersSnapshot.value as Map).length;
      }

      // عدد المنتجات
      final productsSnapshot = await dbRef.child('products').get();
      if (productsSnapshot.exists) {
        _productsCount = (productsSnapshot.value as Map).length;
      }

      // عدد الطلبات
      final ordersSnapshot = await dbRef.child('orders').get();
      if (ordersSnapshot.exists) {
        _ordersCount = (ordersSnapshot.value as Map).length;
      }

      // عدد المحادثات
      final chatsSnapshot = await dbRef.child('chats').get();
      if (chatsSnapshot.exists) {
        _chatsCount = (chatsSnapshot.value as Map).length;
      }

      // عدد البلاغات قيد الانتظار
      _reportsCount = await UserReportService.getPendingReportsCount();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!authController.isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ترحيب
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),

                    // الإحصائيات
                    _buildSectionTitle('الإحصائيات العامة'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // الإجراءات السريعة
                    _buildSectionTitle('الإجراءات السريعة'),
                    const SizedBox(height: 12),
                    _buildActionsGrid(),
                    const SizedBox(height: 24),

                    // آخر النشاطات
                    _buildSectionTitle('الأدوات'),
                    const SizedBox(height: 12),
                    _buildToolsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً، مسؤول النظام',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر تسجيل: ${intl.DateFormat('yyyy/MM/dd - hh:mm a').format(DateTime.now())}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('المستخدمين', _usersCount, Icons.people, Colors.blue),
        _buildStatCard(
            'المنتجات', _productsCount, Icons.inventory_2, Colors.green),
        _buildStatCard(
            'الطلبات', _ordersCount, Icons.shopping_bag, Colors.orange),
        _buildStatCard('المحادثات', _chatsCount, Icons.chat, Colors.purple),
        _buildStatCard('البلاغات', _reportsCount, Icons.flag, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionButton('المستخدمين', Icons.people, Colors.blue, () {
          Get.snackbar('قريباً', 'إدارة المستخدمين');
        }),
        _buildActionButton('المنتجات', Icons.inventory, Colors.green, () {
          Get.snackbar('قريباً', 'إدارة المنتجات');
        }),
        _buildActionButton('الطلبات', Icons.receipt_long, Colors.orange, () {
          Get.snackbar('قريباً', 'إدارة الطلبات');
        }),
        _buildActionButton('التقارير', Icons.analytics, Colors.purple, () {
          _showExportDialog();
        }),
        _buildActionButton('البلاغات', Icons.flag, Colors.red, () {
          _showReportsList();
        }),
        _buildActionButton('الإعدادات', Icons.settings, Colors.grey, () {
          Get.snackbar('قريباً', 'إعدادات النظام');
        }),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsList() {
    return Column(
      children: [
        _buildToolItem(
            'مشاهدة جميع المستخدمين', Icons.people_alt, _showUsersList),
        _buildToolItem('إدارة البلاغات', Icons.flag, _showReportsList),
        _buildToolItem(
            'إرسال إشعار عام', Icons.campaign, _showNotificationDialog),
        _buildToolItem('تصدير التقارير (PDF/Excel)', Icons.file_download,
            _showExportDialog),
      ],
    );
  }

  Widget _buildToolItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // --- وظائف الأدمن ---

  // 1. عرض قائمة المستخدمين وحظرهم
  void _showUsersList() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'إدارة المستخدمين',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                future: FirebaseDatabase.instance.ref().child('users').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('لا يوجد مستخدمين'));
                  }

                  // معالجة البيانات وإزالة التكرار
                  List<MapEntry<String, dynamic>> usersList = [];
                  Set<String> processedIds = {}; // لمنع التكرار

                  try {
                    void processUser(String id, dynamic value) {
                      // تجاوز المستخدم الحالي (الأدمن)
                      if (id == authController.userId) return;
                      // تجاوز إذا تم معالجته مسبقاً
                      if (processedIds.contains(id)) return;

                      processedIds.add(id);
                      usersList.add(MapEntry(id, value));
                    }

                    if (snapshot.data!.value is Map) {
                      final usersMap = Map<String, dynamic>.from(
                          snapshot.data!.value as Map);
                      usersMap.forEach(processUser);
                    } else if (snapshot.data!.value is List) {
                      final list = snapshot.data!.value as List<dynamic>;
                      for (int i = 0; i < list.length; i++) {
                        if (list[i] != null) {
                          // محاولة العثور على ID داخل البيانات أو استخدام ال index
                          final data = Map<String, dynamic>.from(list[i]);
                          final id = data['uid'] ?? data['id'] ?? i.toString();
                          processUser(id, list[i]);
                        }
                      }
                    }
                  } catch (e) {
                    return Center(child: Text('خطأ في معالجة البيانات: $e'));
                  }

                  if (usersList.isEmpty) {
                    return const Center(child: Text('لا يوجد مستخدمين لعرضهم'));
                  }

                  return ListView.separated(
                    itemCount: usersList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final userId = usersList[index].key;
                      final userData = usersList[index].value is Map
                          ? Map<String, dynamic>.from(usersList[index].value)
                          : <String, dynamic>{};

                      final isBanned = userData['isBanned'] == true;
                      // فلتر إضافي - عدم عرض الأدمن إذا كان الدور محدد
                      if (userData['role'] == 'admin') {
                        return const SizedBox.shrink();
                      }

                      final name =
                          userData['name'] ?? userData['firstName'] ?? 'مستخدم';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isBanned ? Colors.grey : Colors.indigo,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        // تم إخفاء ال subtitle (الإيميل) حسب الطلب
                        trailing: ElevatedButton(
                          onPressed: () => _toggleBanUser(userId, !isBanned),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isBanned ? Colors.green : Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isBanned ? 'إلغاء الحظر' : 'حظر'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // عرض قائمة البلاغات
  void _showReportsList() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إدارة البلاغات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      Get.back();
                      _showReportsList();
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: UserReportService.getAllReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 80, color: Colors.green.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد بلاغات',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final reports = snapshot.data!;
                  return ListView.separated(
                    itemCount: reports.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final status = report['status'] ?? 'pending';
                      final statusColor =
                          Color(UserReportService.getStatusColor(status));

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: const Icon(Icons.flag, color: Colors.white),
                        ),
                        title: Text(
                          'بلاغ ضد: ${report['reportedUserName'] ?? 'غير معروف'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السبب: ${UserReportService.getReasonLabel(report['reason'] ?? '')}',
                            ),
                            Text(
                              'الحالة: ${UserReportService.translateStatus(status)}',
                              style: TextStyle(color: statusColor),
                            ),
                            if (report['details'] != null &&
                                report['details'].toString().isNotEmpty)
                              Text(
                                'التفاصيل: ${report['details']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) =>
                              _handleReportAction(report, action),
                          itemBuilder: (context) => [
                            if (status == 'pending') ...[
                              const PopupMenuItem(
                                value: 'reviewed',
                                child: Text('تحديد كمراجعة'),
                              ),
                              const PopupMenuItem(
                                value: 'resolved',
                                child: Text('تم الحل'),
                              ),
                              const PopupMenuItem(
                                value: 'rejected',
                                child: Text('رفض البلاغ'),
                              ),
                            ],
                            const PopupMenuItem(
                              value: 'ban_user',
                              child: Text('حظر المستخدم المُبلَّغ عنه',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف البلاغ',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // معالجة إجراءات البلاغ
  Future<void> _handleReportAction(
      Map<String, dynamic> report, String action) async {
    switch (action) {
      case 'reviewed':
      case 'resolved':
      case 'rejected':
        _showReportRejectDialog(report);
        break;
      case 'ban_user':
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('تأكيد الحظر'),
            content: Text('هل أنت متأكد من حظر ${report['reportedUserName']}؟'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('حظر', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _toggleBanUser(report['reportedUserId'], true);
          await UserReportService.updateReportStatus(
            reportId: report['id'],
            newStatus: 'resolved',
            adminNote: 'تم حظر المستخدم',
          );
        }
        break;
      case 'delete':
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('حذف البلاغ'),
            content: const Text('هل أنت متأكد من حذف هذا البلاغ؟'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final success = await UserReportService.deleteReport(report['id']);
          if (success) {
            Get.snackbar(
              'تم',
              'تم حذف البلاغ',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Get.back();
            _showReportsList();
            _loadStats();
          }
        }
        break;
    }
  }

  // تفعيل/إلغاء حظر مستخدم
  Future<void> _toggleBanUser(String userId, bool ban) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .update({'isBanned': ban});

      // إجبار إعادة بناء الواجهة (يمكن تحسينه باستخدام setState محلي)
      Get.back(); // إغلاق القائمة
      Get.snackbar(
        'نجاح',
        ban ? 'تم حظر المستخدم' : 'تم إلغاء حظر المستخدم',
        backgroundColor: ban ? Colors.orange : Colors.green,
        colorText: Colors.white,
      );
      _showUsersList(); // فتح القائمة مرة أخرى للتحديث
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث حالة المستخدم: $e');
    }
  }

  // 2. إرسال إشعار عام
  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    Get.defaultDialog(
      title: 'إرسال إشعار عام',
      content: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الإشعار',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            decoration: const InputDecoration(
              labelText: 'نص الإشعار',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'إرسال للجميع',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.indigo,
      onConfirm: () async {
        if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
          Get.back(); // إغلاق
          await _sendGeneralNotification(
              titleController.text, bodyController.text);
        } else {
          Get.snackbar('تنبيه', 'يرجى ملء جميع الحقول');
        }
      },
    );
  }

  Future<void> _sendGeneralNotification(String title, String body) async {
    Get.showSnackbar(const GetSnackBar(
      message: 'جاري إرسال الإشعار...',
      showProgressIndicator: true,
      duration: Duration(seconds: 2),
    ));

    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final usersSnapshot = await dbRef.child('users').get();

      if (usersSnapshot.exists) {
        final usersMap = Map<String, dynamic>.from(usersSnapshot.value as Map);

        // إرسال لكل مستخدم
        // ملاحظة: هذا الإجراء ثقيل إذا كان عدد المستخدمين كبير جداً
        // الأفضل استخدام Cloud Functions و FCM Topics في الإنتاج
        for (var userId in usersMap.keys) {
          await dbRef.child('notifications').child(userId).push().set({
            'title': title,
            'body': body,
            'timestamp': ServerValue.timestamp,
            'type': 'admin_broadcast',
            'isRead': false,
          });
        }

        Get.snackbar(
          'تم بنجاح',
          'تم إرسال الإشعار لـ ${usersMap.length} مستخدم',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إرسال الإشعار: $e');
    }
  }

  // 3. تصدير التقارير
  void _showExportDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تصدير التقارير',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // تقرير المستخدمين
            _buildExportRow(
              'تقرير المستخدمين',
              Icons.people,
              Colors.blue,
              onPdfTap: () => _exportReport('users', 'pdf'),
              onExcelTap: () => _exportReport('users', 'excel'),
            ),
            const Divider(),

            // تقرير المنتجات
            _buildExportRow(
              'تقرير المنتجات',
              Icons.inventory_2,
              Colors.green,
              onPdfTap: () => _exportReport('products', 'pdf'),
              onExcelTap: () => _exportReport('products', 'excel'),
            ),
            const Divider(),

            // تقرير الطلبات
            _buildExportRow(
              'تقرير الطلبات',
              Icons.shopping_bag,
              Colors.orange,
              onPdfTap: () => _exportReport('orders', 'pdf'),
              onExcelTap: () => _exportReport('orders', 'excel'),
            ),
            const Divider(),

            // تقرير المقايضات
            _buildExportRow(
              'تقرير المقايضات',
              Icons.swap_horiz,
              Colors.purple,
              onPdfTap: () => _exportReport('swaps', 'pdf'),
              onExcelTap: () => _exportReport('swaps', 'excel'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportRow(
    String title,
    IconData icon,
    Color color, {
    required VoidCallback onPdfTap,
    required VoidCallback onExcelTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          // زر PDF
          ElevatedButton.icon(
            onPressed: onPdfTap,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          // زر Excel
          ElevatedButton.icon(
            onPressed: onExcelTap,
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(String type, String format) async {
    Get.back(); // إغلاق الدايلوج

    Get.snackbar(
      'جاري التصدير...',
      'يرجى الانتظار',
      showProgressIndicator: true,
      duration: const Duration(seconds: 10),
    );

    String? filePath;

    try {
      switch (type) {
        case 'users':
          filePath = format == 'pdf'
              ? await ReportService.exportUsersPDF()
              : await ReportService.exportUsersExcel();
          break;
        case 'products':
          filePath = format == 'pdf'
              ? await ReportService.exportProductsPDF()
              : await ReportService.exportProductsExcel();
          break;
        case 'orders':
          filePath = format == 'pdf'
              ? await ReportService.exportOrdersPDF()
              : await ReportService.exportOrdersExcel();
          break;
        case 'swaps':
          filePath = format == 'pdf'
              ? await ReportService.exportSwapRequestsPDF()
              : await ReportService.exportSwapRequestsExcel();
          break;
      }

      // إغلاق سناك بار التحميل
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

      if (filePath != null) {
        Get.snackbar(
          'تم التصدير بنجاح! ✅',
          'اضغط لفتح الملف',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          onTap: (_) => ReportService.openExportedFile(filePath!),
          mainButton: TextButton(
            onPressed: () => ReportService.openExportedFile(filePath!),
            child: const Text('فتح', style: TextStyle(color: Colors.white)),
          ),
        );
      } else {
        Get.snackbar(
          'تنبيه',
          'لا توجد بيانات للتصدير',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Get.snackbar(
        'خطأ',
        'فشل التصدير: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showReportRejectDialog(Map<String, dynamic> report) {
    final reasonController = TextEditingController();
    Get.defaultDialog(
      title: 'رفض البلاغ',
      content: Column(
        children: [
          const Text('يرجى إدخال سبب رفض البلاغ:'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'مثلاً: معلومات غير كافية، البلاغ غير صحيح...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'تأكيد الرفض',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        if (reasonController.text.trim().isEmpty) {
          Get.snackbar('تنبيه', 'يرجى كتابة سبب الرفض');
          return;
        }
        final reason = reasonController.text.trim();
        Get.back(); // إغلاق الدايلوج
        await _submitReportRejection(report, reason);
      },
    );
  }

  Future<void> _submitReportRejection(
      Map<String, dynamic> report, String reason) async {
    try {
      final success = await UserReportService.updateReportStatus(
        reportId: report['id'],
        newStatus: 'rejected',
        adminNote: reason,
      );

      if (success) {
        // إرسال إشعار للمُبلِّغ (reporter)
        if (Get.isRegistered<NotificationsController>() &&
            report['reporterId'] != null) {
          await Get.find<NotificationsController>().sendRejectionNotification(
            toUserId: report['reporterId'],
            itemName: 'بلاغك ضد ${report['reportedUserName']}',
            reason: reason,
            type: 'report_rejection',
            extraData: {
              'reportId': report['id'],
            },
          );
        }

        Get.snackbar(
          'تم الرفض',
          'تم رفض البلاغ وإشعار المُبلِّغ بالسبب',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Get.back(); // إغلاق قائمة البلاغات
        _showReportsList(); // إعادة فتحها للتحديث
        _loadStats();
      }
    } catch (e) {
      debugPrint('Error rejecting report: $e');
      Get.snackbar('خطأ', 'فشل رفض البلاغ');
    }
  }
}
