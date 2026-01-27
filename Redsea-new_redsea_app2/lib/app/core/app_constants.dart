/// ثوابت التطبيق
class AppConstants {
  // Firebase
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String favoritesCollection = 'favorites';

  // API Keys
  static const String imgbbApiKey = '5fc2622b097fcd07fb1a03eca1daf3d3';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Pagination
  static const int itemsPerPage = 20;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif'
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int phoneLength = 9;

  // Order Status
  static const String statusPendingVerification = 'pending_verification';
  static const String statusVerified = 'verified';
  static const String statusProcessing = 'processing';
  static const String statusShipped = 'shipped';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Categories
  static const List<String> categories = [
    'الكترونيات',
    'أجهزة منزلية',
    'ملابس',
    'عطور',
    'ساعات',
    'سيارات',
    'أثاث',
    'خدمات',
  ];
}

/// رسائل التطبيق
class AppMessages {
  // Success
  static const String loginSuccess = 'تم تسجيل الدخول بنجاح';
  static const String signupSuccess = 'تم إنشاء الحساب بنجاح';
  static const String productAdded = 'تم إضافة المنتج بنجاح';
  static const String productDeleted = 'تم حذف المنتج بنجاح';
  static const String orderCreated = 'تم إنشاء الطلب بنجاح';
  static const String orderCancelled = 'تم إلغاء الطلب';
  static const String addedToCart = 'تم إضافة المنتج للسلة';
  static const String removedFromCart = 'تم إزالة المنتج من السلة';
  static const String addedToFavorites = 'تم إضافة المنتج للمفضلة';
  static const String removedFromFavorites = 'تم إزالة المنتج من المفضلة';
  static const String profileUpdated = 'تم تحديث الملف الشخصي';
  static const String passwordResetSent =
      'تم إرسال رابط إعادة تعيين كلمة المرور';

  // Errors
  static const String errorGeneric = 'حدث خطأ غير متوقع';
  static const String errorNetwork = 'خطأ في الاتصال بالإنترنت';
  static const String errorAuth = 'خطأ في المصادقة';
  static const String errorInvalidCredentials = 'بيانات الدخول غير صحيحة';
  static const String errorUserNotFound = 'المستخدم غير موجود';
  static const String errorPhoneExists = 'رقم الهاتف مستخدم مسبقاً';
  static const String errorEmailExists = 'البريد الإلكتروني مستخدم مسبقاً';
  static const String errorWeakPassword = 'كلمة المرور ضعيفة';
  static const String errorImageUpload = 'خطأ في رفع الصورة';
  static const String errorLoadData = 'خطأ في تحميل البيانات';

  // Validation
  static const String validationRequired = 'هذا الحقل مطلوب';
  static const String validationInvalidPhone = 'رقم الهاتف غير صحيح';
  static const String validationInvalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String validationPasswordTooShort = 'كلمة المرور قصيرة جداً';
  static const String validationPasswordsNotMatch = 'كلمات المرور غير متطابقة';

  // Confirm
  static const String confirmLogout = 'هل أنت متأكد من تسجيل الخروج؟';
  static const String confirmDeleteProduct = 'هل أنت متأكد من حذف هذا المنتج؟';
  static const String confirmCancelOrder = 'هل أنت متأكد من إلغاء الطلب؟';
  static const String confirmClearCart = 'هل أنت متأكد من إفراغ السلة؟';
  static const String confirmClearNotifications =
      'هل أنت متأكد من حذف جميع الإشعارات؟';
}
