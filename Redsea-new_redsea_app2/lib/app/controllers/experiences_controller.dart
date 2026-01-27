import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/models/experience_model.dart';
import 'package:flutter/foundation.dart';

/// Controller للتحكم بالخبرات
class ExperiencesController extends GetxController {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('experiences');
  StreamSubscription<DatabaseEvent>? _experiencesSubscription;

  // قائمة الخبرات
  final RxList<Experience> allExperiences = <Experience>[].obs;

  // الخبرات المفلترة
  final RxList<Experience> filteredExperiences = <Experience>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;

  // البحث
  final RxString searchQuery = ''.obs;

  // الفئة المختارة
  final RxString selectedCategory = 'الكل'.obs;

  @override
  void onInit() {
    super.onInit();
    startExperiencesListener();

    // مراقبة التغييرات في البحث والفئة
    ever(searchQuery, (_) => _filterExperiences());
    ever(selectedCategory, (_) => _filterExperiences());
  }

  @override
  void onClose() {
    _experiencesSubscription?.cancel();
    super.onClose();
  }

  /// بدء مستمع الخبرات لمزامنة البيانات في الوقت الحقيقي
  void startExperiencesListener() {
    try {
      isLoading.value = true;
      _experiencesSubscription?.cancel();

      _experiencesSubscription = _dbRef.onValue.listen((event) {
        DataSnapshot snapshot = event.snapshot;
        List<Experience> loadedExperiences = [];

        if (snapshot.value != null) {
          Map<dynamic, dynamic> experiencesMap =
              snapshot.value as Map<dynamic, dynamic>;

          experiencesMap.forEach((key, value) {
            try {
              Map<String, dynamic> experienceData =
                  Map<String, dynamic>.from(value);
              Experience experience =
                  Experience.fromMap(key.toString(), experienceData);

              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              if (shouldShowExperience(experience, currentUserId)) {
                loadedExperiences.add(experience);
              }
            } catch (e) {
              debugPrint('Error parsing experience $key: $e');
            }
          });

          loadedExperiences.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }

        allExperiences.value = loadedExperiences;
        _filterExperiences();
        isLoading.value = false;
      }, onError: (error) {
        debugPrint('Error in experiences stream: $error');
        isLoading.value = false;
      });
    } catch (e) {
      debugPrint('Error starting experiences listener: $e');
      isLoading.value = false;
    }
  }

  /// هل يجب عرض الخبرة للمستخدم الحالي؟
  bool shouldShowExperience(Experience experience, String? currentUserId) {
    bool isOwner =
        currentUserId != null && experience.expertId == currentUserId;
    // إضافة منطق المسؤول إذا لزم الأمر مستقبلاً
    return isOwner || experience.isPublic;
  }

  /// تحميل الخبرات (للتوافق)
  Future<void> loadExperiences() async {
    startExperiencesListener();
  }

  /// فلترة الخبرات
  void _filterExperiences() {
    List<Experience> result = allExperiences.toList();

    // فلترة حسب الفئة
    if (selectedCategory.value != 'الكل') {
      result =
          result.where((e) => e.category == selectedCategory.value).toList();
    }

    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.expertName.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.skills.any((s) => s.toLowerCase().contains(query));
      }).toList();
    }

    filteredExperiences.value = result;
  }

  /// تغيير الفئة
  void changeCategory(String category) {
    selectedCategory.value = category;
  }

  /// تحديث البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// الخبرات المميزة (أعلى تقييم)
  List<Experience> get featuredExperiences {
    final sorted = allExperiences.toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  /// خبرات المستخدم الحالي (للسيرة الذاتية)
  List<Experience> get myExperiences {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    return allExperiences.where((e) => e.expertId == uid).toList();
  }

  /// عدد الخبرات المتاحة للعامة
  int get availableCount =>
      allExperiences.where((e) => e.isAvailable && e.isPublic).length;
}
