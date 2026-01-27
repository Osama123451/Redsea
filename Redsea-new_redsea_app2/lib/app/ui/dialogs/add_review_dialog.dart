import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:redsea/app/ui/widgets/rating_star_widget.dart';

/// دايالوج إضافة تقييم لمستخدم
class AddReviewDialog extends StatefulWidget {
  final String ratedUserId;
  final String ratedUserName;

  const AddReviewDialog({
    super.key,
    required this.ratedUserId,
    required this.ratedUserName,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      Get.snackbar(
        'خطأ',
        'الرجاء اختيار تقييم',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
      return;
    }

    // لا يمكن تقييم نفسك
    if (currentUser.uid == widget.ratedUserId) {
      Get.snackbar(
        'خطأ',
        'لا يمكنك تقييم نفسك',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // جلب اسم المستخدم الحالي
      final userSnapshot = await dbRef.child('users/${currentUser.uid}').once();
      String raterName = 'مستخدم';
      if (userSnapshot.snapshot.value != null) {
        final userData =
            Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
        raterName = userData['name'] ?? currentUser.displayName ?? 'مستخدم';
      }

      // إنشاء التقييم الجديد
      final reviewRef = dbRef.child('reviews').push();
      await reviewRef.set({
        'raterId': currentUser.uid,
        'raterName': raterName,
        'ratedUserId': widget.ratedUserId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'timestamp': ServerValue.timestamp,
      });

      // تحديث متوسط التقييم للمستخدم المُقيَّم
      await _updateUserTrustScore(widget.ratedUserId);

      Get.back(result: true);
      Get.snackbar(
        'نجاح',
        'تم إرسال التقييم بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل إرسال التقييم: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateUserTrustScore(String userId) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // جلب جميع تقييمات هذا المستخدم
      final reviewsSnapshot = await dbRef
          .child('reviews')
          .orderByChild('ratedUserId')
          .equalTo(userId)
          .once();

      if (reviewsSnapshot.snapshot.value != null) {
        final reviews =
            Map<String, dynamic>.from(reviewsSnapshot.snapshot.value as Map);
        double totalRating = 0;
        int count = 0;

        reviews.forEach((key, value) {
          final review = Map<String, dynamic>.from(value);
          totalRating += (review['rating'] ?? 0).toDouble();
          count++;
        });

        final averageRating = count > 0 ? totalRating / count : 0;

        // تحديث بيانات المستخدم
        await dbRef.child('users/$userId').update({
          'trustScore': averageRating,
          'reviewsCount': count,
        });
      }
    } catch (e) {
      debugPrint('Error updating trust score: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                    const Expanded(
                      child: Text(
                        'إضافة تقييم',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // للموازنة
                  ],
                ),
                const SizedBox(height: 16),

                // اسم المستخدم المُقيَّم
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.ratedUserName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // اختيار التقييم
                InteractiveRatingWidget(
                  label: 'كيف كانت تجربتك؟',
                  onRatingChanged: (value) {
                    setState(() => _rating = value);
                  },
                ),
                const SizedBox(height: 24),

                // حقل التعليق
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقاً (اختياري)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // أزرار الإرسال والإلغاء
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'إرسال التقييم',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// دالة مساعدة لفتح دايالوج التقييم
Future<bool?> showAddReviewDialog({
  required String ratedUserId,
  required String ratedUserName,
}) {
  return Get.dialog<bool>(
    AddReviewDialog(
      ratedUserId: ratedUserId,
      ratedUserName: ratedUserName,
    ),
    barrierDismissible: false,
  );
}
