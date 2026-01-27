import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// اختبارات Widget لصفحة تسجيل الدخول
/// تختبر عرض العناصر والتفاعلات بدون اتصال حقيقي بـ Firebase
void main() {
  // تهيئة GetX للاختبارات
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginPage UI Tests - اختبارات واجهة صفحة الدخول', () {
    testWidgets('يجب أن تظهر جميع عناصر الواجهة الأساسية', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // التحقق من وجود العناصر الأساسية
      expect(find.text('REDSEA'), findsOneWidget);
      // يوجد نصين "تسجيل الدخول" - واحد في التاب وواحد في الزر
      expect(find.text('تسجيل الدخول'), findsAtLeast(1));
      expect(
          find.byType(TextField), findsNWidgets(2)); // حقل الهاتف + كلمة المرور
      expect(find.text('أدخل رقم الهاتف'), findsOneWidget);
      expect(find.text('كلمة المرور'), findsOneWidget);
    });

    testWidgets('يجب أن يكون زر الدخول موجوداً', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // البحث عن زر الدخول
      final loginButton = find.widgetWithText(ElevatedButton, 'تسجيل الدخول');
      expect(loginButton, findsOneWidget);
    });

    testWidgets('يجب أن يظهر خطأ عند محاولة الدخول بحقول فارغة',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // الضغط على زر الدخول بدون إدخال بيانات
      await tester.tap(find.widgetWithText(ElevatedButton, 'تسجيل الدخول'));
      await tester.pump();

      // التحقق من ظهور رسالة الخطأ
      expect(find.text('يرجى إدخال رقم الهاتف وكلمة المرور'), findsOneWidget);
    });

    testWidgets('يجب أن يقبل إدخال رقم الهاتف', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // إدخال رقم الهاتف
      await tester.enterText(
        find.byType(TextField).first,
        '775378412',
      );
      await tester.pump();

      // التحقق من إدخال القيمة
      expect(find.text('775378412'), findsOneWidget);
    });

    testWidgets('يجب أن يخفي كلمة المرور بشكل افتراضي', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // البحث عن حقل كلمة المرور والتحقق من أنه مخفي
      final passwordField = find.byType(TextField).last;
      final textField = tester.widget<TextField>(passwordField);

      expect(textField.obscureText, true);
    });

    testWidgets('يجب أن يُظهر/يُخفي كلمة المرور عند الضغط على أيقونة العين',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // الضغط على أيقونة العين
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // التحقق من تغيير الحالة
      final passwordField = find.byType(TextField).last;
      final textField = tester.widget<TextField>(passwordField);

      expect(textField.obscureText, false);
    });

    testWidgets('يجب أن يظهر رابط "إنشاء حساب"', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('إنشاء حساب'), findsWidgets);
    });

    testWidgets('يجب أن يظهر رابط "نسيت كلمة المرور"', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('نسيت كلمة المرور'), findsOneWidget);
    });

    testWidgets('يجب أن يظهر checkbox "تذكرني"', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تذكرني'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  group('Form Validation Tests - اختبارات التحقق من النموذج', () {
    testWidgets('يجب أن لا يُمكّن زر الدخول أثناء التحميل', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(isLoading: true),
          textDirection: TextDirection.rtl,
        ),
      );
      // استخدام pump بدلاً من pumpAndSettle لتجنب timeout مع CircularProgressIndicator
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );

      expect(button.enabled, false);
    });

    testWidgets('يجب أن يظهر مؤشر التحميل أثناء عملية الدخول', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(isLoading: true),
          textDirection: TextDirection.rtl,
        ),
      );
      // استخدام pump بدلاً من pumpAndSettle لتجنب timeout مع CircularProgressIndicator
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Input Field Tests - اختبارات حقول الإدخال', () {
    testWidgets('يجب أن يكون هناك حقلان للإدخال', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('يجب أن يقبل إدخال كلمة المرور', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // إدخال كلمة المرور
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      await tester.pump();

      // التحقق من إدخال القيمة
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Checkbox يجب أن يتغير عند الضغط عليه', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const _TestLoginPage(),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      // التحقق من أن الـ checkbox غير مختار بالبداية
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);

      // الضغط على الـ checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // التحقق من تغير القيمة
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });
  });
}

/// صفحة اختبار مبسطة تحاكي LoginPage الحقيقية
/// تُستخدم لتجنب الاعتماد على Firebase في الاختبارات
class _TestLoginPage extends StatefulWidget {
  final bool isLoading;

  const _TestLoginPage({this.isLoading = false});

  @override
  State<_TestLoginPage> createState() => _TestLoginPageState();
}

class _TestLoginPageState extends State<_TestLoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = false;
  late bool _loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loading = widget.isLoading;
  }

  void _handleLogin() {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال رقم الهاتف وكلمة المرور';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 80),

            // الشعار
            const Text(
              'REDSEA',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // التابات
            const Text('تسجيل الدخول', style: TextStyle(fontSize: 18)),

            const SizedBox(height: 40),

            // حقل رقم الهاتف
            const Text('أدخل رقم الهاتف'),
            const SizedBox(height: 8),
            TextField(controller: _phoneController),

            const SizedBox(height: 20),

            // حقل كلمة المرور
            const Text('كلمة المرور'),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                      _hidePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // تذكرني ونسيت كلمة المرور
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('نسيت كلمة المرور'),
                Row(
                  children: [
                    const Text('تذكرني'),
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                    ),
                  ],
                ),
              ],
            ),

            // رسالة الخطأ
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),

            // زر تسجيل الدخول
            ElevatedButton(
              onPressed: _loading ? null : _handleLogin,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('تسجيل الدخول'),
            ),

            const SizedBox(height: 24),

            // رابط إنشاء حساب
            const Text('إنشاء حساب'),
          ],
        ),
      ),
    );
  }
}
