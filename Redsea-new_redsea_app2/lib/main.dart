import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:redsea/app/routes/app_routes.dart';
import 'package:redsea/app/routes/app_pages.dart';
import 'package:redsea/app/bindings/initial_binding.dart';
import 'package:redsea/app/core/app_theme.dart';
import 'package:redsea/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:redsea/services/encryption_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.deviceCheck,
  );
  await initializeDateFormatting('ar_SA', null);

  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
  await EncryptionService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RedSea E-commerce',

      // الربط الأولي
      initialBinding: InitialBinding(),

      // المسار الأولي - دائماً نبدأ بـ Splash Screen
      initialRoute: AppRoutes.splash,

      // صفحات التطبيق
      getPages: AppPages.pages,

      // السمة
      // السمة
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // دعم اللغة العربية مع اتجاه RTL
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),

      // تغليف التطبيق بـ Directionality للـ RTL
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },

      // إعدادات الـ Transitions
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      navigatorObservers: [DebugNavigationObserver()],
    );
  }
}

// مراقب للتنقل لطباعة اسم الشاشة
class DebugNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      debugPrint('Navigation -- Push: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name != null) {
      debugPrint('Navigation -- Pop: ${previousRoute!.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings.name != null) {
      debugPrint('Navigation -- Replace: ${newRoute!.settings.name}');
    }
  }
}
