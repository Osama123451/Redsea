import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/controllers/auth_controller.dart';

/// Header مخصص للصفحة الرئيسية بتصميم Marketplace
class CustomMarketplaceHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onBackTap;
  final int notificationCount;
  final int favoriteCount;
  final int cartCount;
  final String? title;
  final bool showBackButton;
  final bool showSearchBar;
  final Widget? bottom;
  final List<Widget>? actions;
  final String? searchHint;
  final bool showSearchFilter;

  const CustomMarketplaceHeader({
    super.key,
    this.onNotificationTap,
    this.onFavoriteTap,
    this.onCartTap,
    this.onSearchTap,
    this.onBackTap,
    this.notificationCount = 0,
    this.favoriteCount = 0,
    this.cartCount = 0,
    this.title,
    this.showBackButton = false,
    this.showSearchBar = true,
    this.bottom,
    this.actions,
    this.searchHint,
    this.showSearchFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصف العلوي: الشعار/العنوان + الأيقونات
              _buildTopRow(),
              if (showSearchBar) ...[
                const SizedBox(height: 16),
                // شريط البحث
                _buildSearchBar(),
              ],
              if (bottom != null) ...[
                const SizedBox(height: 12),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // أيقونات الإجراءات (يسار)
        Row(
          children: actions ??
              [
                _buildIconButton(
                  icon: Icons.shopping_cart_outlined,
                  onTap: onCartTap ?? () => Get.toNamed(AppRoutes.basket),
                  badge: cartCount,
                  tooltip: 'السلة',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.favorite_border,
                  onTap:
                      onFavoriteTap ?? () => Get.toNamed(AppRoutes.favorites),
                  badge: favoriteCount,
                  tooltip: 'المفضلة',
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: onNotificationTap ??
                      () => Get.toNamed(AppRoutes.notifications),
                  badge: notificationCount,
                  tooltip: 'الإشعارات',
                ),
              ],
        ),
        // الشعار أو العنوان (يمين) مع زر العودة إذا وجد
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              _buildLogo(),
            if (showBackButton) ...[
              const SizedBox(width: 12),
              _buildIconButton(
                icon: Icons.arrow_forward_ios,
                onTap: onBackTap ?? () => Get.back(),
                tooltip: 'رجوع',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'RED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
                letterSpacing: 1,
              ),
            ),
            TextSpan(
              text: 'SEA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
    int badge = 0,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (badge > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: onSearchTap ??
          () {
            // التنقل لصفحة البحث
            if (Get.isRegistered<AuthController>()) {
              Get.toNamed(AppRoutes.searchResults);
            }
          },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // أيقونة الفلتر (يسار في RTL)
            if (showSearchFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            // النص
            Expanded(
              child: Text(
                searchHint ?? 'ابحث عن منتجات...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            // أيقونة البحث (يمين في RTL)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(
                Icons.search,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
