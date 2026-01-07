/// أسماء المسارات للتطبيق
abstract class AppRoutes {
  // الصفحات الأساسية
  static const first = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';

  // المنتجات
  static const productDetails = '/product-details';
  static const addProduct = '/add-product';
  static const myProducts = '/my-products';

  // السلة والدفع
  static const basket = '/basket';
  static const payment = '/payment';

  // الملف الشخصي والإعدادات
  static const profile = '/profile';
  static const settings = '/settings';

  // المحادثات
  static const chatList = '/chat-list';
  static const chat = '/chat';

  // الطلبات والإشعارات
  static const orders = '/orders';
  static const notifications = '/notifications';

  // التصنيفات والبحث
  static const categories = '/categories';
  static const search = '/search';
  static const favorites = '/favorites';

  // المقايضة
  static const swapSelection = '/swap-selection';
  static const swapRequests = '/swap-requests';
  static const servicesExchange = '/services-exchange';

  // الأدمن
  static const admin = '/admin';
  static const adminFixProducts = '/admin/fix-products';

  // MFA
  static const mfaEnrollment = '/mfa-enrollment';
  static const mfaVerification = '/mfa-verification';
}
