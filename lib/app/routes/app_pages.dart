import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';

// Bindings

import 'package:redsea/app/bindings/home_binding.dart';
import 'package:redsea/app/bindings/auth_binding.dart';
import 'package:redsea/app/bindings/chat_binding.dart';
import 'package:redsea/app/bindings/swap_binding.dart';
// Note: profile_binding, notifications_binding, orders_binding, chat_binding
// available for use when needed in GetPage definitions

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
import 'package:redsea/swap_selection_page.dart';
import 'package:redsea/swap_requests_page.dart';

/// تعريف صفحات التطبيق مع الـ Bindings
abstract class AppPages {
  static final pages = [
    // الصفحة الأولى
    GetPage(
      name: AppRoutes.first,
      page: () => const Firstpage(),
    ),

    // صفحات المصادقة
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

    // الصفحة الرئيسية
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),

    // صفحة تفاصيل المنتج
    GetPage(
      name: AppRoutes.productDetails,
      page: () => ProductDetailsPage(
        product: Get.arguments['product'],
        cartItems: Get.arguments['cartItems'] ?? [],
        onAddToCart: Get.arguments['onAddToCart'],
        onRemoveFromCart: Get.arguments['onRemoveFromCart'],
        onUpdateQuantity: Get.arguments['onUpdateQuantity'],
      ),
    ),

    // إضافة منتج
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddProductPage(),
    ),

    // السلة
    GetPage(
      name: AppRoutes.basket,
      page: () => BasketPage(cartItems: Get.arguments ?? []),
    ),

    // الدفع
    GetPage(
      name: AppRoutes.payment,
      page: () => PaymentMethodPage(cartItems: Get.arguments ?? []),
    ),

    // الملف الشخصي
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
    ),

    // الإعدادات
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
    ),

    // المحادثات
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
    ),

    // منتجاتي
    GetPage(
      name: AppRoutes.myProducts,
      page: () => const MyProductsPage(),
    ),

    // طلباتي
    GetPage(
      name: AppRoutes.orders,
      page: () => const OrdersPage(),
    ),

    // الإشعارات
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationPage(),
    ),

    // التصنيفات
    GetPage(
      name: AppRoutes.categories,
      page: () => CategoriesPage(
        onCategorySelected: Get.arguments ?? (category) {},
      ),
    ),

    // اختيار المقايضة
    GetPage(
      name: AppRoutes.swapSelection,
      page: () => SwapSelectionPage(
        targetProduct: Get.arguments['targetProduct'],
      ),
    ),

    // طلبات المقايضة
    GetPage(
      name: AppRoutes.swapRequests,
      page: () => const SwapRequestsPage(),
      binding: SwapBinding(),
    ),
  ];
}
