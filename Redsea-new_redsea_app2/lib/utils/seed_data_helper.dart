// ignore_for_file: avoid_print
/// سكربت إضافة بيانات تجريبية للمنتجات والخدمات
/// لتشغيله: قم بتشغيله كـ Debug Console في التطبيق أو أضف زر مؤقت
///
/// الاستخدام:
/// 1. افتح التطبيق وسجّل دخول بالحساب المطلوب
/// 2. استدعي الدالة addTestData() من أي مكان
///
/// أو يمكنك نسخ البيانات وإضافتها يدوياً

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeedDataHelper {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // المستخدم المستهدف للبيانات التجريبية
  static const String targetUserId = '771727798';
  static const String targetUserName = 'ahmed000';

  /// صور مجانية من Unsplash لكل نوع
  static const Map<String, List<String>> productImages = {
    'الكترونيات': [
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400', // iPhone
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400', // Samsung
      'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=400', // Phone
      'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400', // AirPods
      'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=400', // Laptop
    ],
    'ساعات': [
      'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400', // Watch 1
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400', // Watch 2
      'https://images.unsplash.com/photo-1542496658-e33a6d0d50f6?w=400', // Watch 3
    ],
    'ملابس': [
      'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400', // Clothes
      'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=400', // Shirt
      'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400', // Jacket
    ],
    'عطور': [
      'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400', // Perfume 1
      'https://images.unsplash.com/photo-1587017539504-67cfbddac569?w=400', // Perfume 2
      'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=400', // Perfume 3
    ],
    'سيارات': [
      'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400', // Car 1
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400', // Car 2
      'https://images.unsplash.com/photo-1542362567-b07e54358753?w=400', // Car 3
    ],
    'أثاث': [
      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400', // Sofa
      'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=400', // Table
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=400', // Chair
    ],
    'أجهزة منزلية': [
      'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400', // Kitchen
      'https://images.unsplash.com/photo-1585237672814-8f85a8118bf6?w=400', // Mixer
      'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=400', // Microwave
    ],
  };

  /// بيانات المنتجات التجريبية (الأسعار بالريال اليمني)
  static List<Map<String, dynamic>> getTestProducts(
      String userId, String userName) {
    return [
      // ═══════════════════════════════════════════════════════════
      // 📱 الكترونيات (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'iPhone 15 Pro Max 256GB',
        'price': '450000',
        'description':
            'آيفون 15 برو ماكس جديد بالكرتونة، لون تيتانيوم أسود، ضمان سنة. البطارية 100%، لم يُستخدم إلا للفحص.',
        'category': 'الكترونيات',
        'imageUrl': productImages['الكترونيات']![0],
        'isSpecialOffer': true,
        'oldPrice': '500000',
        'rating': 4.8,
        'reviewsCount': 12,
        'viewsCount': 234,
        'isFeatured': true,
      },
      {
        'name': 'Samsung Galaxy S24 Ultra',
        'price': '380000',
        'description':
            'سامسونج S24 ألترا، شاشة رائعة وكاميرا احترافية. ذاكرة 512GB، رام 12GB. يأتي مع جميع الملحقات الأصلية.',
        'category': 'الكترونيات',
        'imageUrl': productImages['الكترونيات']![1],
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 8,
        'viewsCount': 156,
      },
      {
        'name': 'Apple AirPods Pro 2',
        'price': '55000',
        'description':
            'سماعات آيربودز برو الجيل الثاني، إلغاء الضوضاء النشط، صوت مذهل. جديدة بالكرتونة.',
        'category': 'الكترونيات',
        'imageUrl': productImages['الكترونيات']![3],
        'isSpecialOffer': true,
        'oldPrice': '65000',
        'rating': 4.9,
        'reviewsCount': 25,
        'viewsCount': 412,
      },

      // ═══════════════════════════════════════════════════════════
      // ⌚ ساعات (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'ساعة Casio G-Shock',
        'price': '18000',
        'description':
            'ساعة كاسيو جي شوك أصلية، مقاومة للماء والصدمات. مثالية للرياضة والاستخدام اليومي.',
        'category': 'ساعات',
        'imageUrl': productImages['ساعات']![0],
        'isSpecialOffer': false,
        'rating': 4.7,
        'reviewsCount': 15,
        'viewsCount': 189,
        'isFeatured': true,
      },
      {
        'name': 'Apple Watch Series 9',
        'price': '120000',
        'description':
            'ساعة آبل الجيل التاسع، 45mm، GPS. شاشة Always-On، مقاومة للماء. مثالية للرياضة والحياة اليومية.',
        'category': 'ساعات',
        'imageUrl': productImages['ساعات']![1],
        'isSpecialOffer': true,
        'oldPrice': '140000',
        'rating': 4.7,
        'reviewsCount': 18,
        'viewsCount': 267,
      },
      {
        'name': 'ساعة Samsung Galaxy Watch 6',
        'price': '75000',
        'description':
            'ساعة سامسونج ذكية، تتبع اللياقة والنوم، شاشة AMOLED. جديدة بالضمان.',
        'category': 'ساعات',
        'imageUrl': productImages['ساعات']![2],
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 10,
        'viewsCount': 145,
      },

      // ═══════════════════════════════════════════════════════════
      // 👔 ملابس (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'بدلة رسمية تركية',
        'price': '35000',
        'description':
            'بدلة تركية أصلية، مقاس 52، لون كحلي غامق. خامة فاخرة، مناسبة للمناسبات والعمل.',
        'category': 'ملابس',
        'imageUrl': productImages['ملابس']![0],
        'isSpecialOffer': false,
        'rating': 4.4,
        'reviewsCount': 7,
        'viewsCount': 145,
      },
      {
        'name': 'جاكيت جلد صناعي',
        'price': '12000',
        'description':
            'جاكيت جلد صناعي عالي الجودة، مقاس L، لون بني. تصميم كلاسيكي أنيق، مناسب للشتاء.',
        'category': 'ملابس',
        'imageUrl': productImages['ملابس']![2],
        'isSpecialOffer': true,
        'oldPrice': '15000',
        'rating': 4.3,
        'reviewsCount': 11,
        'viewsCount': 198,
      },
      {
        'name': 'طقم رياضي Nike',
        'price': '8000',
        'description':
            'طقم رياضي نايكي، يشمل جاكيت وبنطلون. خامة مريحة، مقاس M. جديد بالتاق.',
        'category': 'ملابس',
        'imageUrl': productImages['ملابس']![1],
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 15,
        'viewsCount': 278,
      },

      // ═══════════════════════════════════════════════════════════
      // 🌸 عطور (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'عطر بخور يمني فاخر',
        'price': '5000',
        'description':
            'بخور يمني أصلي، خليط من العود والعنبر. رائحة مميزة تدوم طويلاً. عبوة 50 جرام.',
        'category': 'عطور',
        'imageUrl': productImages['عطور']![0],
        'isSpecialOffer': false,
        'rating': 4.9,
        'reviewsCount': 32,
        'viewsCount': 456,
        'isFeatured': true,
      },
      {
        'name': 'عطر عربي مركز',
        'price': '8000',
        'description':
            'عطر عربي مركز، مزيج العود والمسك. ثبات ممتاز يدوم طوال اليوم. 100ml.',
        'category': 'عطور',
        'imageUrl': productImages['عطور']![1],
        'isSpecialOffer': true,
        'oldPrice': '10000',
        'rating': 4.7,
        'reviewsCount': 19,
        'viewsCount': 312,
      },
      {
        'name': 'عطر Dior Sauvage',
        'price': '45000',
        'description':
            'ديور سوفاج أصلي، عطر رجالي عصري ومنعش. ثبات ممتاز. 100ml.',
        'category': 'عطور',
        'imageUrl': productImages['عطور']![2],
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 28,
        'viewsCount': 389,
      },

      // ═══════════════════════════════════════════════════════════
      // 🚗 سيارات (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'Toyota Hilux 2020',
        'price': '6500000',
        'description':
            'تويوتا هايلوكس موديل 2020، دبل كابينه، ممشى 80 ألف كم. محرك ديزل، حالة ممتازة.',
        'category': 'سيارات',
        'imageUrl': productImages['سيارات']![0],
        'isSpecialOffer': false,
        'rating': 4.8,
        'reviewsCount': 4,
        'viewsCount': 567,
        'isFeatured': true,
      },
      {
        'name': 'Hyundai Accent 2019',
        'price': '2500000',
        'description':
            'هيونداي أكسنت 2019، أوتوماتيك، ممشى 60 ألف كم. لون أبيض، حالة جيدة.',
        'category': 'سيارات',
        'imageUrl': productImages['سيارات']![1],
        'isSpecialOffer': true,
        'oldPrice': '2800000',
        'rating': 4.4,
        'reviewsCount': 6,
        'viewsCount': 423,
      },
      {
        'name': 'Toyota Corolla 2021',
        'price': '4200000',
        'description':
            'تويوتا كورولا 2021، أوتوماتيك، ممشى 45 ألف كم. لون فضي، صيانة دورية.',
        'category': 'سيارات',
        'imageUrl': productImages['سيارات']![2],
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 9,
        'viewsCount': 378,
      },

      // ═══════════════════════════════════════════════════════════
      // 🛋️ أثاث (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'طقم كنب 7 مقاعد',
        'price': '120000',
        'description':
            'طقم كنب 7 مقاعد، قماش عالي الجودة، لون بيج. تصميم عصري مريح، حالة ممتازة.',
        'category': 'أثاث',
        'imageUrl': productImages['أثاث']![0],
        'isSpecialOffer': true,
        'oldPrice': '150000',
        'rating': 4.5,
        'reviewsCount': 8,
        'viewsCount': 234,
      },
      {
        'name': 'طاولة سفرة 6 كراسي',
        'price': '65000',
        'description': 'طاولة سفرة خشب مع 6 كراسي. صناعة محلية جيدة، لون بني.',
        'category': 'أثاث',
        'imageUrl': productImages['أثاث']![1],
        'isSpecialOffer': false,
        'rating': 4.3,
        'reviewsCount': 5,
        'viewsCount': 167,
      },
      {
        'name': 'غرفة نوم كاملة',
        'price': '200000',
        'description':
            'غرفة نوم كاملة: سرير + كومودينات + تسريحة + دولاب 4 أبواب. خشب محلي.',
        'category': 'أثاث',
        'imageUrl': productImages['أثاث']![2],
        'isSpecialOffer': false,
        'rating': 4.4,
        'reviewsCount': 11,
        'viewsCount': 289,
        'isFeatured': true,
      },

      // ═══════════════════════════════════════════════════════════
      // 🏠 أجهزة منزلية (3 منتجات)
      // ═══════════════════════════════════════════════════════════
      {
        'name': 'مكيف سبليت 1.5 طن',
        'price': '95000',
        'description':
            'مكيف سبليت 1.5 طن، موفر للطاقة، تبريد سريع. جديد بالضمان.',
        'category': 'أجهزة منزلية',
        'imageUrl': productImages['أجهزة منزلية']![0],
        'isSpecialOffer': true,
        'oldPrice': '110000',
        'rating': 4.6,
        'reviewsCount': 14,
        'viewsCount': 345,
      },
      {
        'name': 'ثلاجة LG 18 قدم',
        'price': '180000',
        'description': 'ثلاجة ال جي 18 قدم، نو فروست. لون فضي، ضمان سنة.',
        'category': 'أجهزة منزلية',
        'imageUrl': productImages['أجهزة منزلية']![1],
        'isSpecialOffer': false,
        'rating': 4.4,
        'reviewsCount': 9,
        'viewsCount': 234,
      },
      {
        'name': 'غسالة أوتوماتيك 7 كيلو',
        'price': '85000',
        'description':
            'غسالة ملابس أوتوماتيك 7 كيلو، فتحة أمامية، 10 برامج غسيل. موفرة للماء.',
        'category': 'أجهزة منزلية',
        'imageUrl': productImages['أجهزة منزلية']![2],
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 17,
        'viewsCount': 278,
      },
    ];
  }

  /// بيانات الخدمات التجريبية (الأسعار بالريال اليمني)
  static List<Map<String, dynamic>> getTestServices(
      String userId, String userName) {
    return [
      // ═══════════════════════════════════════════════════════════
      // 🎨 تصميم (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'تصميم شعار احترافي لعلامتك التجارية',
        'description':
            'أصمم لك شعار (لوجو) احترافي يعكس هوية علامتك التجارية. ستحصل على: 3 مقترحات أولية، تعديلات غير محدودة، ملفات Vector بجميع الصيغ.',
        'category': 'تصميم',
        'estimatedValue': 25000,
        'duration': '3-5 أيام',
        'isSpecialOffer': true,
        'oldEstimatedValue': 35000.0,
        'rating': 4.9,
        'reviewsCount': 45,
        'viewsCount': 678,
        'isFeatured': true,
      },
      {
        'title': 'تصميم هوية بصرية كاملة',
        'description':
            'هوية بصرية متكاملة تشمل: شعار، بطاقة عمل، ورق رسمي، غلاف سوشيال ميديا. تصاميم عصرية تميز علامتك.',
        'category': 'تصميم',
        'estimatedValue': 80000,
        'duration': '7-10 أيام',
        'isSpecialOffer': false,
        'rating': 4.8,
        'reviewsCount': 28,
        'viewsCount': 456,
      },
      {
        'title': 'تصميم بوستات سوشيال ميديا',
        'description':
            'أصمم لك 10 بوستات احترافية لمنصات التواصل. تصاميم جذابة متوافقة مع هويتك البصرية.',
        'category': 'تصميم',
        'estimatedValue': 15000,
        'duration': '2-3 أيام',
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 67,
        'viewsCount': 892,
      },

      // ═══════════════════════════════════════════════════════════
      // 💻 برمجة (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'برمجة تطبيق موبايل (Android & iOS)',
        'description':
            'أطور لك تطبيق موبايل بـ Flutter يعمل على Android و iOS. يشمل: واجهات مستخدم، ربط API، قاعدة بيانات Firebase.',
        'category': 'برمجة',
        'estimatedValue': 500000,
        'duration': '30-45 يوم',
        'isSpecialOffer': false,
        'rating': 4.9,
        'reviewsCount': 18,
        'viewsCount': 345,
        'isFeatured': true,
      },
      {
        'title': 'تطوير موقع ووردبريس',
        'description':
            'موقع WordPress متكامل: قالب مخصص، SEO، سرعة عالية، متجاوب مع الجوال. يشمل الإعدادات ودعم شهر كامل.',
        'category': 'برمجة',
        'estimatedValue': 120000,
        'duration': '7-14 يوم',
        'isSpecialOffer': true,
        'oldEstimatedValue': 150000.0,
        'rating': 4.7,
        'reviewsCount': 34,
        'viewsCount': 567,
      },
      {
        'title': 'برمجة بوت واتساب/تلغرام',
        'description':
            'أبرمج لك بوت ذكي للواتساب أو تلغرام. يرد تلقائياً، يستقبل الطلبات. مناسب للمتاجر وخدمة العملاء.',
        'category': 'برمجة',
        'estimatedValue': 60000,
        'duration': '5-7 أيام',
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 22,
        'viewsCount': 289,
      },

      // ═══════════════════════════════════════════════════════════
      // 📸 تصوير (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'تصوير منتجات احترافي',
        'description':
            'تصوير احترافي لمنتجاتك. يشمل: 10 منتجات، خلفية بيضاء نظيفة، معالجة الصور بجودة عالية.',
        'category': 'تصوير',
        'estimatedValue': 30000,
        'duration': 'يوم واحد',
        'isSpecialOffer': false,
        'rating': 4.8,
        'reviewsCount': 31,
        'viewsCount': 445,
      },
      {
        'title': 'تصوير فيديو إعلاني',
        'description':
            'إنتاج فيديو إعلاني احترافي. يشمل: كتابة السكربت، التصوير، المونتاج. مدة 30-60 ثانية.',
        'category': 'تصوير',
        'estimatedValue': 100000,
        'duration': '5-7 أيام',
        'isSpecialOffer': true,
        'oldEstimatedValue': 130000.0,
        'rating': 4.7,
        'reviewsCount': 19,
        'viewsCount': 312,
        'isFeatured': true,
      },
      {
        'title': 'تصوير مناسبات وأحداث',
        'description':
            'تغطية تصويرية كاملة لمناسباتك: أعراس، حفلات، مؤتمرات. مصور محترف. التسليم خلال 3 أيام.',
        'category': 'تصوير',
        'estimatedValue': 150000,
        'duration': 'حسب المناسبة',
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 14,
        'viewsCount': 234,
      },

      // ═══════════════════════════════════════════════════════════
      // ✍️ كتابة وترجمة (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'كتابة محتوى تسويقي',
        'description':
            'أكتب لك محتوى تسويقي جذاب لموقعك أو منصاتك. 5 مقالات (1000 كلمة)، SEO متوافق، أسلوب مميز.',
        'category': 'كتابة وترجمة',
        'estimatedValue': 25000,
        'duration': '5-7 أيام',
        'isSpecialOffer': false,
        'rating': 4.7,
        'reviewsCount': 42,
        'viewsCount': 534,
      },
      {
        'title': 'ترجمة عربي-إنجليزي',
        'description':
            'ترجمة دقيقة من/إلى العربية والإنجليزية. جميع المجالات. سعر الصفحة 250 كلمة.',
        'category': 'كتابة وترجمة',
        'estimatedValue': 5000,
        'duration': '1-2 يوم/صفحة',
        'isSpecialOffer': true,
        'oldEstimatedValue': 8000.0,
        'rating': 4.8,
        'reviewsCount': 89,
        'viewsCount': 678,
        'isFeatured': true,
      },
      {
        'title': 'كتابة سيرة ذاتية CV',
        'description':
            'أكتب لك سيرة ذاتية احترافية. يشمل: سيرة عربية وإنجليزية، تصميم جذاب. مناسبة لجميع المجالات.',
        'category': 'كتابة وترجمة',
        'estimatedValue': 10000,
        'duration': '2-3 أيام',
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 56,
        'viewsCount': 423,
      },

      // ═══════════════════════════════════════════════════════════
      // 📈 تسويق رقمي (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'إدارة حسابات السوشيال ميديا',
        'description':
            'إدارة كاملة لحساباتك: نشر يومي، تصاميم، رد على التعليقات. انستغرام، تويتر، فيسبوك.',
        'category': 'تسويق رقمي',
        'estimatedValue': 80000,
        'duration': 'شهرياً',
        'isSpecialOffer': false,
        'rating': 4.7,
        'reviewsCount': 28,
        'viewsCount': 456,
        'isFeatured': true,
      },
      {
        'title': 'حملة إعلانية على فيسبوك',
        'description':
            'إعداد وإدارة حملة إعلانية ممولة. يشمل: دراسة الجمهور، تصميم الإعلان، تقرير نهائي.',
        'category': 'تسويق رقمي',
        'estimatedValue': 35000,
        'duration': '2 أسبوع',
        'isSpecialOffer': true,
        'oldEstimatedValue': 50000.0,
        'rating': 4.5,
        'reviewsCount': 34,
        'viewsCount': 523,
      },
      {
        'title': 'تحسين محركات البحث SEO',
        'description':
            'تحسين ترتيب موقعك في جوجل. يشمل: تحليل الموقع، كلمات مفتاحية، تقارير شهرية.',
        'category': 'تسويق رقمي',
        'estimatedValue': 60000,
        'duration': 'شهرياً',
        'isSpecialOffer': false,
        'rating': 4.4,
        'reviewsCount': 19,
        'viewsCount': 312,
      },

      // ═══════════════════════════════════════════════════════════
      // 🔧 صيانة وإصلاح (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'صيانة جوالات iPhone & Samsung',
        'description':
            'صيانة جميع أعطال الجوالات: شاشات، بطاريات، سماعات، شحن. قطع غيار أصلية، ضمان شهر.',
        'category': 'صيانة وإصلاح',
        'estimatedValue': 15000,
        'duration': 'ساعة - يوم',
        'isSpecialOffer': false,
        'rating': 4.6,
        'reviewsCount': 78,
        'viewsCount': 890,
      },
      {
        'title': 'صيانة لابتوبات وكمبيوترات',
        'description':
            'إصلاح جميع مشاكل الكمبيوتر: سرعة، فيروسات، ويندوز، هاردوير. خدمة منزلية متوفرة.',
        'category': 'صيانة وإصلاح',
        'estimatedValue': 10000,
        'duration': 'حسب العطل',
        'isSpecialOffer': true,
        'oldEstimatedValue': 15000.0,
        'rating': 4.5,
        'reviewsCount': 45,
        'viewsCount': 567,
        'isFeatured': true,
      },
      {
        'title': 'صيانة مكيفات وتنظيفها',
        'description':
            'صيانة وتنظيف مكيفات سبليت. غسيل شامل، شحن فريون، فحص الكمبرسر. أسعار منافسة.',
        'category': 'صيانة وإصلاح',
        'estimatedValue': 8000,
        'duration': 'ساعة',
        'isSpecialOffer': false,
        'rating': 4.7,
        'reviewsCount': 92,
        'viewsCount': 712,
      },

      // ═══════════════════════════════════════════════════════════
      // 📚 تدريس وتعليم (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'دروس خصوصية لغة إنجليزية',
        'description':
            'دروس إنجليزي لجميع المستويات: محادثة، قواعد، IELTS. مدرس متخصص. أونلاين أو حضوري.',
        'category': 'تدريس وتعليم',
        'estimatedValue': 5000,
        'duration': 'ساعة',
        'isSpecialOffer': false,
        'rating': 4.8,
        'reviewsCount': 67,
        'viewsCount': 789,
        'isFeatured': true,
      },
      {
        'title': 'تدريب برمجة للمبتدئين',
        'description':
            'أعلمك البرمجة من الصفر: Python, JavaScript. منهج عملي بمشاريع حقيقية. 10 حصص.',
        'category': 'تدريس وتعليم',
        'estimatedValue': 50000,
        'duration': '10 حصص',
        'isSpecialOffer': true,
        'oldEstimatedValue': 70000.0,
        'rating': 4.7,
        'reviewsCount': 34,
        'viewsCount': 456,
      },
      {
        'title': 'تحفيظ قرآن كريم أونلاين',
        'description':
            'حلقات تحفيظ قرآن وتجويد أونلاين. محفظ متخصص بإجازة. حصص فردية أو مجموعات. جميع الأعمار.',
        'category': 'تدريس وتعليم',
        'estimatedValue': 3000,
        'duration': 'ساعة',
        'isSpecialOffer': false,
        'rating': 4.9,
        'reviewsCount': 112,
        'viewsCount': 934,
      },

      // ═══════════════════════════════════════════════════════════
      // 🎵 إنتاج صوتي ومرئي (3 خدمات)
      // ═══════════════════════════════════════════════════════════
      {
        'title': 'تعليق صوتي احترافي',
        'description':
            'تعليق صوتي بصوت عربي لإعلاناتك وفيديوهاتك. جودة عالية، تسليم سريع. سعر الدقيقة.',
        'category': 'إنتاج صوتي ومرئي',
        'estimatedValue': 7000,
        'duration': '1-2 يوم',
        'isSpecialOffer': false,
        'rating': 4.8,
        'reviewsCount': 56,
        'viewsCount': 623,
        'isFeatured': true,
      },
      {
        'title': 'مونتاج فيديو احترافي',
        'description':
            'مونتاج فيديوهات يوتيوب، ريلز، إعلانات. يشمل: قص ولصق، مؤثرات، نصوص، موسيقى.',
        'category': 'إنتاج صوتي ومرئي',
        'estimatedValue': 10000,
        'duration': '2-3 أيام',
        'isSpecialOffer': true,
        'oldEstimatedValue': 15000.0,
        'rating': 4.6,
        'reviewsCount': 43,
        'viewsCount': 512,
      },
      {
        'title': 'إنتاج بودكاست كامل',
        'description':
            'إنتاج حلقة بودكاست: تسجيل، مونتاج صوتي، مقدمة وخاتمة، تصميم غلاف. جاهز للنشر.',
        'category': 'إنتاج صوتي ومرئي',
        'estimatedValue': 20000,
        'duration': '3-5 أيام',
        'isSpecialOffer': false,
        'rating': 4.5,
        'reviewsCount': 21,
        'viewsCount': 345,
      },
    ];
  }

  /// إضافة البيانات التجريبية
  static Future<void> addTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ يجب تسجيل الدخول أولاً!');
      return;
    }

    // جلب اسم المستخدم
    String userName = 'مستخدم';
    try {
      final userSnapshot = await _dbRef.child('users/${user.uid}/name').get();
      userName = userSnapshot.value?.toString() ?? 'مستخدم';
    } catch (e) {
      print('⚠️ تعذر جلب اسم المستخدم: $e');
    }

    print('═══════════════════════════════════════════════');
    print('🚀 بدء إضافة البيانات التجريبية...');
    print('👤 المستخدم: $userName (${user.uid})');
    print('═══════════════════════════════════════════════');

    // إضافة المنتجات
    int productCount = 0;
    final products = getTestProducts(user.uid, userName);
    for (final product in products) {
      try {
        final productRef = _dbRef.child('products').push();
        await productRef.set({
          ...product,
          'sellerId': user.uid,
          'userId': user.uid,
          'createdAt': ServerValue.timestamp,
          'isNegotiable': true,
        });
        productCount++;
        print('✅ منتج: ${product['name']}');
      } catch (e) {
        print('❌ فشل: ${product['name']} - $e');
      }
    }

    // إضافة الخدمات
    int serviceCount = 0;
    final services = getTestServices(user.uid, userName);
    for (final service in services) {
      try {
        final serviceRef = _dbRef.child('services').push();
        await serviceRef.set({
          ...service,
          'ownerId': user.uid,
          'ownerName': userName,
          'isAvailable': true,
          'createdAt': ServerValue.timestamp,
          'swapPreferences': <String>[],
          'images': <String>[],
          'portfolio': <String>[],
          'packages': <Map<String, dynamic>>[],
          'sellerLevel': 'intermediate',
          'completedOrders': service['reviewsCount'] ?? 0,
          'responseRate': 0.95,
          'responseTime': 'خلال ساعة',
        });
        serviceCount++;
        print('✅ خدمة: ${service['title']}');
      } catch (e) {
        print('❌ فشل: ${service['title']} - $e');
      }
    }

    print('═══════════════════════════════════════════════');
    print('🎉 اكتمل! تم إضافة:');
    print('   📦 $productCount منتج');
    print('   🔧 $serviceCount خدمة');
    print('═══════════════════════════════════════════════');
  }

  /// إضافة البيانات التجريبية للمستخدم الحالي المسجل دخوله
  /// هذه الدالة تستخدم المستخدم المسجل حالياً لتجنب مشاكل الصلاحيات
  static Future<bool> addTestDataForTargetUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ يجب تسجيل الدخول أولاً!');
      return false;
    }

    // جلب اسم المستخدم من قاعدة البيانات
    String userName = 'مستخدم';
    try {
      final userSnapshot = await _dbRef.child('users/${user.uid}/name').get();
      userName = userSnapshot.value?.toString() ?? 'مستخدم';
    } catch (e) {
      print('⚠️ تعذر جلب اسم المستخدم: $e');
    }

    print('═══════════════════════════════════════════════');
    print('🚀 بدء إضافة البيانات التجريبية...');
    print('👤 المستخدم الحالي: $userName (${user.uid})');
    print('═══════════════════════════════════════════════');

    // إضافة المنتجات
    int productCount = 0;
    final products = getTestProducts(user.uid, userName);
    for (final product in products) {
      try {
        final productRef = _dbRef.child('products').push();
        await productRef.set({
          ...product,
          'sellerId': user.uid,
          'userId': user.uid,
          'ownerId': user.uid,
          'sellerName': userName,
          'createdAt': ServerValue.timestamp,
          'isNegotiable': true,
          'status': 'active',
        });
        productCount++;
        print('✅ منتج: ${product['name']}');
      } catch (e) {
        print('❌ فشل: ${product['name']} - $e');
      }
    }

    // إضافة الخدمات
    int serviceCount = 0;
    final services = getTestServices(user.uid, userName);
    for (final service in services) {
      try {
        final serviceRef = _dbRef.child('services').push();
        await serviceRef.set({
          ...service,
          'ownerId': user.uid,
          'ownerName': userName,
          'isAvailable': true,
          'createdAt': ServerValue.timestamp,
          'swapPreferences': <String>[],
          'images': <String>[],
          'portfolio': <String>[],
          'packages': <Map<String, dynamic>>[],
          'sellerLevel': 'intermediate',
          'completedOrders': service['reviewsCount'] ?? 0,
          'responseRate': 0.95,
          'responseTime': 'خلال ساعة',
        });
        serviceCount++;
        print('✅ خدمة: ${service['title']}');
      } catch (e) {
        print('❌ فشل: ${service['title']} - $e');
      }
    }

    print('═══════════════════════════════════════════════');
    print('🎉 اكتمل! تم إضافة:');
    print('   📦 $productCount منتج');
    print('   🔧 $serviceCount خدمة');
    print('═══════════════════════════════════════════════');

    return productCount > 0 || serviceCount > 0;
  }

  /// حذف جميع بيانات المستخدم الحالي وإعادة إضافتها بالأسعار الجديدة
  static Future<bool> clearAndReseedData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ يجب تسجيل الدخول أولاً!');
      return false;
    }

    print('═══════════════════════════════════════════════');
    print('🗑️ جاري حذف البيانات القديمة...');
    print('═══════════════════════════════════════════════');

    int deletedProducts = 0;
    int deletedServices = 0;

    // حذف منتجات المستخدم
    try {
      final productsSnapshot = await _dbRef.child('products').get();
      if (productsSnapshot.exists) {
        final productsData = productsSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in productsData.entries) {
          final product = entry.value as Map<dynamic, dynamic>;
          if (product['sellerId'] == user.uid ||
              product['userId'] == user.uid) {
            await _dbRef.child('products/${entry.key}').remove();
            deletedProducts++;
            print('🗑️ حذف منتج: ${product['name']}');
          }
        }
      }
    } catch (e) {
      print('⚠️ خطأ في حذف المنتجات: $e');
    }

    // حذف خدمات المستخدم
    try {
      final servicesSnapshot = await _dbRef.child('services').get();
      if (servicesSnapshot.exists) {
        final servicesData = servicesSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in servicesData.entries) {
          final service = entry.value as Map<dynamic, dynamic>;
          if (service['ownerId'] == user.uid) {
            await _dbRef.child('services/${entry.key}').remove();
            deletedServices++;
            print('🗑️ حذف خدمة: ${service['title']}');
          }
        }
      }
    } catch (e) {
      print('⚠️ خطأ في حذف الخدمات: $e');
    }

    print('═══════════════════════════════════════════════');
    print('✅ تم حذف $deletedProducts منتج و $deletedServices خدمة');
    print('═══════════════════════════════════════════════');

    // إعادة إضافة البيانات بالأسعار الجديدة
    print('');
    print('🔄 جاري إعادة إضافة البيانات بالأسعار باليمني...');

    return await addTestDataForTargetUser();
  }

  /// تحديث أسعار المنتجات الموجودة في Firebase
  static Future<bool> updateExistingProductPrices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ يجب تسجيل الدخول أولاً!');
      return false;
    }

    print('═══════════════════════════════════════════════');
    print('💰 جاري تحديث أسعار المنتجات...');
    print('═══════════════════════════════════════════════');

    // خريطة الأسعار الجديدة بناءً على اسم المنتج
    final Map<String, Map<String, String>> newPrices = {
      'iPhone 15 Pro Max 256GB': {'price': '450000', 'oldPrice': '500000'},
      'Samsung Galaxy S24 Ultra': {'price': '380000', 'oldPrice': ''},
      'Apple AirPods Pro 2': {'price': '55000', 'oldPrice': '65000'},
      'ساعة Casio G-Shock': {'price': '18000', 'oldPrice': ''},
      'Apple Watch Series 9': {'price': '120000', 'oldPrice': '140000'},
      'ساعة Samsung Galaxy Watch 6': {'price': '75000', 'oldPrice': ''},
      'بدلة رسمية تركية': {'price': '35000', 'oldPrice': ''},
      'جاكيت جلد صناعي': {'price': '12000', 'oldPrice': '15000'},
      'طقم رياضي Nike': {'price': '8000', 'oldPrice': ''},
      'عطر بخور يمني فاخر': {'price': '5000', 'oldPrice': ''},
      'عطر عربي مركز': {'price': '8000', 'oldPrice': '10000'},
      'عطر Dior Sauvage': {'price': '45000', 'oldPrice': ''},
      'Toyota Hilux 2020': {'price': '6500000', 'oldPrice': ''},
      'Hyundai Accent 2019': {'price': '2500000', 'oldPrice': '2800000'},
      'Toyota Corolla 2021': {'price': '4200000', 'oldPrice': ''},
      'طقم كنب 7 مقاعد': {'price': '120000', 'oldPrice': '150000'},
      'طاولة سفرة 6 كراسي': {'price': '65000', 'oldPrice': ''},
      'غرفة نوم كاملة': {'price': '200000', 'oldPrice': ''},
      'مكيف سبليت 1.5 طن': {'price': '95000', 'oldPrice': '110000'},
      'ثلاجة LG 18 قدم': {'price': '180000', 'oldPrice': ''},
      'غسالة أوتوماتيك 7 كيلو': {'price': '85000', 'oldPrice': ''},
    };

    int updatedCount = 0;
    int skippedCount = 0;

    try {
      final productsSnapshot = await _dbRef.child('products').get();
      if (productsSnapshot.exists) {
        final productsData = productsSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in productsData.entries) {
          final product = entry.value as Map<dynamic, dynamic>;
          final productName = product['name']?.toString() ?? '';

          // البحث عن السعر الجديد
          if (newPrices.containsKey(productName)) {
            final priceData = newPrices[productName]!;
            final updates = <String, dynamic>{
              'price': priceData['price'],
            };

            // تحديث السعر القديم إذا كان المنتج عرض خاص
            if (priceData['oldPrice']!.isNotEmpty) {
              updates['oldPrice'] = priceData['oldPrice'];
              updates['isSpecialOffer'] = true;
            }

            await _dbRef.child('products/${entry.key}').update(updates);
            updatedCount++;
            print(
                '✅ تحديث: $productName - السعر الجديد: ${priceData['price']}');
          } else {
            skippedCount++;
            print('⏭️ تخطي: $productName (غير موجود في القائمة)');
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في تحديث المنتجات: $e');
      return false;
    }

    print('═══════════════════════════════════════════════');
    print('🎉 اكتمل التحديث!');
    print('   ✅ تم تحديث: $updatedCount منتج');
    print('   ⏭️ تم تخطي: $skippedCount منتج');
    print('═══════════════════════════════════════════════');

    return updatedCount > 0;
  }
}
