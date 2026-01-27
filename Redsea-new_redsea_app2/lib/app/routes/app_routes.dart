/// أسماء المسارات للتطبيق
abstract class AppRoutes {
  // الصفحات الأساسية
  static const splash = '/';
  static const first = '/first';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';

  // المنتجات
  static const productDetails = '/product-details';
  static const addProduct = '/add-product';
  static const addExperience = '/add-experience';
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
  static const searchResults = '/search-results';
  static const advancedFilter = '/advanced-filter';
  static const experiences = '/experiences';
  static const favorites = '/favorites';
  static const searchNew = '/search-new';
  static const productListing = '/product-listing';

  // المقايضة والخدمات
  static const swapSelection = '/swap-selection';
  static const swapRequests = '/swap-requests';
  static const servicesExchange = '/services-exchange';
  static const serviceCategories = '/service-categories';
  static const categoryServices = '/category-services';
  static const serviceOrders = '/service-orders';
  static const serviceReviews = '/service-reviews';
  static const serviceProviderProfile = '/service-provider-profile';

  // الملف الشخصي العام
  static const publicProfile = '/public-profile';

  // شاشة الترحيب
  static const onboarding = '/onboarding';

  // الأدمن
  static const admin = '/admin';
  static const adminFixProducts = '/admin/fix-products';

  static const main = '/main';
  static const mfaEnrollment = '/mfa-enrollment';
  static const mfaVerification = '/mfa-verification';

  // الترويج والإعلانات
  static const promoteProduct = '/promote-product';
  static const promotionCheckout = '/promotion-checkout';
}
