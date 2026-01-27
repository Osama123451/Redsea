import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/experiences/add_experience_page.dart';
import 'package:redsea/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redsea/app/controllers/experiences_controller.dart';
import 'package:redsea/app/controllers/auth_controller.dart';
import 'package:redsea/app/controllers/chat_controller.dart';
import 'package:redsea/app/controllers/cart_controller.dart';
import 'package:redsea/app/controllers/favorites_controller.dart';
import 'package:redsea/app/controllers/notifications_controller.dart';
import 'package:redsea/app/controllers/experience_swap_controller.dart'; // New import
import 'package:redsea/models/experience_model.dart';
import 'package:redsea/app/ui/widgets/home/custom_marketplace_header.dart';
import 'package:redsea/chat/chat_page.dart';

import 'package:redsea/experiences/select_experience_to_offer_page.dart'; // New import
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/basket_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/notifications_page.dart';

class ExperiencesPage extends StatefulWidget {
  const ExperiencesPage({super.key});

  @override
  State<ExperiencesPage> createState() => _ExperiencesPageState();
}

class _ExperiencesPageState extends State<ExperiencesPage> {
  late ExperiencesController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ExperiencesController>()) {
      Get.put(ExperiencesController());
    }
    controller = Get.find<ExperiencesController>();

    // Ensure other necessary controllers are registered just in case
    // (though they should be from HomePage)
    if (!Get.isRegistered<CartController>()) Get.put(CartController());
    if (!Get.isRegistered<FavoritesController>())
      Get.put(FavoritesController());
    if (!Get.isRegistered<NotificationsController>())
      Get.put(NotificationsController());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final favoritesController = Get.find<FavoritesController>();
    final notificationsController = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Constant Header from Home Page
            SliverToBoxAdapter(
              child: CustomMarketplaceHeader(
                title: 'تبادل الخبرات',
                showBackButton: true,
                onBackTap: () => Get.back(),
                notificationCount: notificationsController.unreadCount.value,
                favoriteCount: favoritesController.favorites.length,
                cartCount: cartController.totalItems,
                onNotificationTap: () =>
                    _requireLogin(() => Get.to(() => const NotificationPage())),
                onFavoriteTap: () =>
                    _requireLogin(() => Get.to(() => FavoritesPage())),
                onCartTap: () => _requireLogin(() => Get.to(() =>
                    BasketPage(cartItems: cartController.cartItems.toList()))),
                showSearchBar: false, // Remove duplicate search bar
              ),
            ),

            // Filter/Search specific to experiences
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) => controller.updateSearchQuery(value),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن خبير أو مهارة...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),

            // Experiences List
            Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final experiences = controller.filteredExperiences;

              if (experiences.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد خبراء مطابقين للبحث',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildDetailedExperienceCard(experiences[index]),
                  childCount: experiences.length,
                ),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      // Consistent Bottom Bar visual
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _addExperience,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _requireLogin(VoidCallback onSuccess) {
    if (Get.find<AuthController>().requireLogin()) {
      onSuccess();
    }
  }

  Widget _buildDetailedExperienceCard(Experience exp) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header: Image, Favorite, Name, Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info (Right aligned in look, left in code for RTL)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        exp.expertName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exp.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Rating & Experience
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.work_history_outlined,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            exp.experienceText,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 4),
                          Text(
                            exp.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Image with Favorite
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: exp.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(exp.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Colors.grey.shade200,
                      ),
                      child: exp.imageUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Obx(() {
                        final isFav =
                            Get.find<FavoritesController>().isFavorite(exp.id);
                        return GestureDetector(
                          onTap: () => _toggleFavorite(exp),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bio/Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              exp.description,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),

          // Skills
          if (exp.skills.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: exp.skills.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          exp.skills[index],
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'استشارة',
                    color: Colors.blue.shade600,
                    onTap: () => _startConsultation(exp),
                    isFilled: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.swap_horiz,
                    label: 'مقايضة',
                    color: Colors.green.shade600,
                    onTap: () => _startExchange(exp),
                    isFilled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'عرض',
                    color: Colors.orange.shade700,
                    onTap: () => _showExperienceDetails(exp),
                    isFilled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isFilled,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isFilled ? color : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isFilled ? color : color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isFilled ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: isFilled ? Colors.white : color, size: 16),
          ],
        ),
      ),
    );
  }

  void _addExperience() {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لإضافة خبرة')) return;
    Get.to(() => const AddExperiencePage());
  }

  void _startConsultation(Experience exp) async {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لطلب استشارة')) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (exp.expertId == null || exp.expertId == currentUserId) {
      Get.snackbar('تنبيه', 'هذه خبرتك الخاصة',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final chatController = Get.find<ChatController>();
    final chatId =
        await chatController.createOrGetChat(exp.expertId!, 'exp_${exp.id}');

    if (chatId != null) {
      Get.to(() => ChatPage(
            chatId: chatId,
            otherUserId: exp.expertId!,
            otherUserName: exp.expertName,
          ));
    }
  }

  void _startExchange(Experience exp) async {
    if (!Get.find<AuthController>()
        .requireLogin(message: 'سجّل دخولك لطلب المقايضة')) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (exp.expertId == null || exp.expertId == currentUserId) {
      Get.snackbar('تنبيه', 'لا يمكنك المقايضة مع خبرتك الخاصة',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final offeredExp = await Get.to<Experience>(
        () => SelectExperienceToOfferPage(targetExperience: exp));

    if (offeredExp != null) {
      final swapController = Get.put(ExperienceSwapController());
      final success = await swapController.sendSwapRequest(
        targetExperience: exp,
        offeredExperience: offeredExp,
      );

      if (success) {
        Get.snackbar('تم الإرسال', 'تم إرسال طلب تبادل الخبرات بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    }
  }

  void _toggleFavorite(Experience exp) {
    final favController = Get.find<FavoritesController>();
    // Temporarily map to product for favorites logic compatibility
    // Ideally FavoritesController should support flexible types
    final product = Product(
      id: exp.id,
      name: exp.title,
      description: exp.description,
      price: (exp.experiencePrice ?? 0).toString(),
      negotiable: false,
      imageUrl: exp.imageUrl,
      ownerId: exp.expertId,
      category: 'خبرات',
      dateAdded: DateTime.now(),
      isService: true,
    );
    favController.toggleFavorite(product);
  }

  void _showExperienceDetails(Experience exp) {
    // Show simple details dialog or bottom sheet
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40, height: 4, color: Colors.grey.shade300)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(exp.expertName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  CircleAvatar(
                      backgroundImage: NetworkImage(exp.imageUrl), radius: 30),
                ],
              ),
              const SizedBox(height: 10),
              Text(exp.title,
                  style: TextStyle(color: AppColors.primary, fontSize: 16)),
              const SizedBox(height: 20),
              const Text('نبذة', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(exp.description,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              if (exp.skills.isNotEmpty) ...[
                const Text('المهارات',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: exp.skills
                      .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade100))
                      .toList(),
                )
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _startConsultation(exp);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('بدء المحادثة'),
                ),
              )
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
