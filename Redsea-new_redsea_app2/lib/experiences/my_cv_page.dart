import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/experiences/add_experience_page.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// صفحة سيرتي الذاتية (Digital CV) - Enhanced

/// صفحة سيرتي الذاتية (Digital CV) - Enhanced
class MyCVPage extends StatefulWidget {
  const MyCVPage({super.key});

  @override
  State<MyCVPage> createState() => _MyCVPageState();
}

class _MyCVPageState extends State<MyCVPage> {
  final _dbRef = FirebaseDatabase.instance.ref().child('users');
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await _dbRef.child(user.uid).get();
        if (snapshot.exists) {
          setState(() {
            _userData = Map<String, dynamic>.from(snapshot.value as Map);
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExperiencesController>();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('سيرتي الذاتية',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final myExperiences = controller.myExperiences;

        // استنتاج المسمى الوظيفي والموقع من آخر خبرة
        // استنتاج المسمى الوظيفي والموقع من آخر خبرة (كاحتياطي)
        String inferredTitle = 'مستخدم جديد';
        String inferredLocation = 'غير محدد';

        if (myExperiences.isNotEmpty) {
          myExperiences.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final latest = myExperiences.first;
          inferredTitle = latest.title;
          if (latest.location != null && latest.location!.isNotEmpty) {
            inferredLocation = latest.location!;
          }
        }

        // استخدام البيانات من الملف الشخصي إذا وجدت، وإلا الاحتياطي
        final displayTitle = _userData['jobTitle'] ?? inferredTitle;
        final displayLocation = _userData['location'] ?? inferredLocation;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeaderProfile(
                  user, displayTitle, displayLocation, myExperiences),
            ),
            if (myExperiences.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu,
                          size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد خبرات مضافة بعد',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ابدأ ببناء سيرتك الذاتية الرقمية الآن',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Get.to(() => const AddExperiencePage()),
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة أول خبرة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final exp = myExperiences[index];
                      final isFirst = index == 0;
                      final isLast = index == myExperiences.length - 1;

                      return _buildTimelineItem(exp, isFirst, isLast);
                    },
                    childCount: myExperiences.length,
                  ),
                ),
              ),
              // Skills Cloud Section
              if (myExperiences.any((e) => e.skills.isNotEmpty))
                SliverToBoxAdapter(
                  child: _buildSkillsSection(myExperiences),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddExperiencePage()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة خبرة', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeaderProfile(
      User? user, String title, String location, List<Experience> exps) {
    // Stats Calculation
    int totalYears = exps.fold(0, (sum, item) => sum + item.yearsOfExperience);
    double avgRating = 0.0;
    if (exps.isNotEmpty) {
      double totalRate = exps.fold(0.0, (sum, item) => sum + item.rating);
      avgRating = totalRate / exps.length;
    }

    final displayEmail =
        _userData['publicEmail'] ?? user?.email ?? 'لا يوجد بريد';

    // الهاتف: من الملف الشخصي > رقم الهاتف المسجل > من الخبرات
    String displayPhone = _userData['publicPhone'] ?? user?.phoneNumber ?? '';

    if (displayPhone.isEmpty && exps.isNotEmpty) {
      for (var e in exps) {
        if (e.phone.isNotEmpty) {
          displayPhone = e.phone;
          break;
        }
      }
    }
    if (displayPhone.isEmpty) displayPhone = 'لا يوجد رقم';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar & Basic Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage:
                      (exps.isNotEmpty && exps.first.imageUrl.isNotEmpty)
                          ? NetworkImage(exps.first.imageUrl)
                          : null,
                  child: (exps.isEmpty || exps.first.imageUrl.isEmpty)
                      ? Text(
                          (user?.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['name'] ?? user?.displayName ?? 'مستخدم',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Contact Info Rows
                    _buildContactRow(Icons.location_on_outlined, location),
                    const SizedBox(height: 4),
                    _buildContactRow(Icons.email_outlined, displayEmail),
                    const SizedBox(height: 4),
                    _buildContactRow(Icons.phone_outlined, displayPhone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Edit Profile Button
          OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(
                user, title, location, displayEmail, displayPhone),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('تعديل الملف الشخصي'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(height: 24),
          // Advanced Stats (Ratings & Years)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('$totalYears', 'سنوات الخبرة',
                    Icons.hourglass_top, Colors.blue),
                _buildContainerDivider(),
                _buildStatItem(avgRating.toStringAsFixed(1), 'التقييم العام',
                    Icons.star, Colors.amber),
                _buildContainerDivider(),
                _buildStatItem(
                    '${exps.length}', 'المشاريع', Icons.work, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContainerDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Experience exp, bool isFirst, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Upper Line
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
                // Dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                ),
                // Lower Line
                Expanded(
                  flex: 5,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Edit
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                ExperienceCategory.getIcon(exp.category),
                                color: AppColors.primary,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${exp.createdAt.year} - ${exp.isAvailable ? 'الآن' : 'سابقاً'}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: Colors.blueGrey),
                            onPressed: () => Get.to(
                                () => AddExperiencePage(experience: exp)),
                            tooltip: 'تعديل الخبرة',
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Details with Labels
                          _buildDetailRow('التفاصيل:', exp.description),
                          if (exp.userStudies != null &&
                              exp.userStudies!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow('المؤهلات:', exp.userStudies!)
                          ],

                          const SizedBox(height: 12),

                          if (exp.skills.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: exp.skills
                                  .map((s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          s,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: Key(label), // dummy key to use label
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey.shade800),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(List<Experience> exps) {
    // Collect all unique skills
    final Set<String> allSkills = {};
    for (var exp in exps) {
      allSkills.addAll(exp.skills);
    }

    if (allSkills.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primary),
              SizedBox(width: 8),
              const Text(
                'ملخص المهارات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSkills.map((s) {
              return Chip(
                label: Text(s),
                backgroundColor:
                    AppColors.primaryExtraLight.withValues(alpha: 0.3),
                labelStyle: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(User? user, String currentTitle,
      String currentLocation, String currentEmail, String currentPhone) {
    if (user == null) return;

    final nameController =
        TextEditingController(text: _userData['name'] ?? user.displayName);
    final titleController = TextEditingController(text: currentTitle);
    final locationController = TextEditingController(text: currentLocation);
    final phoneController = TextEditingController(text: currentPhone);
    final emailController = TextEditingController(text: currentEmail);

    Get.dialog(
      AlertDialog(
        title: const Text('تعديل الملف الشخصي'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'الاسم', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: 'المسمى الوظيفي', prefixIcon: Icon(Icons.work)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                  labelText: 'الموقع', prefixIcon: Icon(Icons.location_on)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbRef.child(user.uid).update({
                  'name': nameController.text.trim(),
                  'jobTitle': titleController.text.trim(),
                  'location': locationController.text.trim(),
                  'publicPhone': phoneController.text.trim(),
                  'publicEmail': emailController.text.trim(),
                });

                await _loadUserData(); // Reload local state
                Get.back();
                Get.snackbar('نجاح', 'تم تحديث الملف الشخصي',
                    backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('خطأ', 'فشل التحديث: $e',
                    backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
