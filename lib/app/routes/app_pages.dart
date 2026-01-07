import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';

// Bindings
import 'package:redsea/app/bindings/home_binding.dart';
import 'package:redsea/app/bindings/auth_binding.dart';
import 'package:redsea/app/bindings/chat_binding.dart';
import 'package:redsea/app/bindings/swap_binding.dart';
import 'package:redsea/app/bindings/admin_binding.dart';
import 'package:redsea/app/bindings/search_binding.dart';
import 'package:redsea/app/bindings/favorites_binding.dart';
import 'package:redsea/app/bindings/product_binding.dart';
import 'package:redsea/app/bindings/basket_binding.dart';
import 'package:redsea/app/bindings/payment_binding.dart';
import 'package:redsea/app/bindings/settings_binding.dart';
import 'package:redsea/app/bindings/categories_binding.dart';
import 'package:redsea/app/bindings/profile_binding.dart';
import 'package:redsea/app/bindings/notifications_binding.dart';
import 'package:redsea/app/bindings/orders_binding.dart';

// Views
import 'package:redsea/firstpage.dart';
import 'package:redsea/login.dart';
import 'package:redsea/signup.dart';
import 'package:redsea/homepage.dart';
import 'package:redsea/product_details_page.dart';
import 'package:redsea/add_product_page.dart';
import 'package:redsea/basket_page.dart';
import 'package:redsea/payment_method_page.dart';
import 'package:redsea/services/profile_page.dart';
import 'package:redsea/services/settings_page.dart';
import 'package:redsea/chat/chat_list_page.dart';
import 'package:redsea/chat/chat_page.dart';
import 'package:redsea/my_products_page.dart';
import 'package:redsea/orders_page.dart';
import 'package:redsea/notifications_page.dart';
import 'package:redsea/categories_page.dart';
import 'package:redsea/search_page.dart';
import 'package:redsea/favorites_page.dart';
import 'package:redsea/swap_selection_page.dart';
import 'package:redsea/swap_requests_page.dart';
import 'package:redsea/admin/admin_dashboard_page.dart';
import 'package:redsea/admin/fix_products_page.dart';
import 'package:redsea/auth/mfa_enrollment_page.dart';
import 'package:redsea/auth/mfa_verification_page.dart';
import 'package:redsea/app/bindings/service_binding.dart';
import 'package:redsea/services_exchange/services_exchange_page.dart';
import 'package:redsea/app/ui/pages/profile/public_profile_page.dart';
import 'package:redsea/app/ui/pages/onboarding/onboarding_page.dart';

/// تعريف صفحات التطبيق مع الـ Bindings
abstract class AppPages {
  static final pages = [
    // ═══════════════════════════════════════════════════════════════
    // الصفحات الأساسية
    // ═══════════════════════════════════════════════════════════════

    // الصفحة الأولى (الترحيب)
    GetPage(
      name: AppRoutes.first,
      page: () => const Firstpage(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // صفحات المصادقة
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignUpPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.mfaEnrollment,
      page: () => const MfaEnrollmentPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.mfaVerification,
      page: () => MfaVerificationPage(
        userId: Get.arguments?['userId'] ?? '',
        email: Get.arguments?['email'] ?? '',
        password: Get.arguments?['password'] ?? '',
      ),
      binding: AuthBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // الصفحة الرئيسية
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // صفحات المنتجات
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.productDetails,
      page: () => ProductDetailsPage(
        product: Get.arguments['product'],
        cartItems: Get.arguments['cartItems'] ?? [],
        onAddToCart: Get.arguments['onAddToCart'],
        onRemoveFromCart: Get.arguments['onRemoveFromCart'],
        onUpdateQuantity: Get.arguments['onUpdateQuantity'],
      ),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.myProducts,
      page: () => const MyProductsPage(),
      binding: ProductBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // السلة والدفع
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.basket,
      page: () => BasketPage(cartItems: Get.arguments ?? []),
      binding: BasketBinding(),
    ),
    GetPage(
      name: AppRoutes.payment,
      page: () => PaymentMethodPage(cartItems: Get.arguments ?? []),
      binding: PaymentBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // الملف الشخصي والإعدادات
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // المحادثات
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.chatList,
      page: () => const ChatListPage(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => ChatPage(
        chatId: Get.arguments['chatId'],
        otherUserId: Get.arguments['otherUserId'],
        otherUserName: Get.arguments['otherUserName'],
      ),
      binding: ChatBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // الطلبات والإشعارات
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.orders,
      page: () => const OrdersPage(),
      binding: OrdersBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationPage(),
      binding: NotificationsBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // التصنيفات والبحث والمفضلة
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.categories,
      page: () => CategoriesPage(
        onCategorySelected: Get.arguments ?? (category) {},
      ),
      binding: CategoriesBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchPage(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesPage(),
      binding: FavoritesBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // المقايضة
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.swapSelection,
      page: () => SwapSelectionPage(
        targetProduct: Get.arguments['targetProduct'],
      ),
      binding: SwapBinding(),
    ),
    GetPage(
      name: AppRoutes.swapRequests,
      page: () => const SwapRequestsPage(),
      binding: SwapBinding(),
    ),
    GetPage(
      name: AppRoutes.servicesExchange,
      page: () => const ServicesExchangePage(),
      binding: ServiceBinding(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // الملف الشخصي العام
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.publicProfile,
      page: () => PublicProfilePage(
        userId: Get.parameters['userId'] ?? Get.arguments?['userId'] ?? '',
      ),
    ),

    // ═══════════════════════════════════════════════════════════════
    // شاشة الترحيب
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
    ),

    // ═══════════════════════════════════════════════════════════════
    // لوحة تحكم المسؤول
    // ═══════════════════════════════════════════════════════════════

    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminDashboardPage(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: AppRoutes.adminFixProducts,
      page: () => const FixProductsPage(),
      binding: AdminBinding(),
    ),
  ];
}
