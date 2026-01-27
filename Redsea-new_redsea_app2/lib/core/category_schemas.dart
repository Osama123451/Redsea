/// مخطط مواصفات التصنيفات
/// يحتوي على تعريف الحقول المطلوبة لكل تصنيف
final Map<String, Map<String, Map<String, dynamic>>> categorySchemas = {
  "الهواتف الذكية": {
    "المعالج": {
      "type": "text",
      "required": true,
      "label": "نوع المعالج",
      "hint": "مثال: A17 Pro"
    },
    "سعة الرام": {
      "type": "number",
      "required": true,
      "label": "الرام (GB)",
      "hint": "مثال: 8"
    },
    "سعة التخزين": {
      "type": "number",
      "required": true,
      "label": "التخزين (GB)",
      "hint": "مثال: 256"
    },
    "دقة الكاميرا": {
      "type": "text",
      "required": false,
      "label": "الكاميرا (MP)",
      "hint": "مثال: 48 ميجابكسل"
    }
  },
  "أجهزة اللابتوب": {
    "كرت الشاشة": {
      "type": "text",
      "required": true,
      "label": "كرت الشاشة",
      "hint": "مثال: RTX 4060"
    },
    "حجم الشاشة": {
      "type": "number",
      "required": true,
      "label": "حجم الشاشة (بوصة)",
      "hint": "مثال: 15.6"
    },
    "نظام التشغيل": {
      "type": "list",
      "required": true,
      "label": "نظام التشغيل",
      "options": ["Windows", "macOS", "Linux", "ChromeOS", "بدون نظام"]
    }
  },
  "الساعات الذكية": {
    "توافق النظام": {
      "type": "list",
      "required": true,
      "label": "التوافق",
      "options": ["iOS", "Android", "الكل"]
    },
    "مقاومة الماء": {
      "type": "boolean",
      "required": true,
      "label": "مقاومة للماء"
    }
  },
  "السماعات اللاسلكية": {
    "عمر البطارية": {
      "type": "number",
      "required": true,
      "label": "عمر البطارية (ساعة)",
      "hint": "مثال: 20"
    },
    "إصدار البلوتوث": {
      "type": "number",
      "required": false,
      "label": "إصدار البلوتوث",
      "hint": "مثال: 5.3"
    }
  },
  "التلفزيونات": {
    "دقة الشاشة": {
      "type": "list",
      "required": true,
      "label": "الدقة",
      "options": ["4K", "8K", "FHD", "HD"]
    },
    "تقنية العرض": {
      "type": "list",
      "required": true,
      "label": "التقنية",
      "options": ["OLED", "QLED", "LED", "LCD"]
    }
  },
  "الكاميرات": {
    "نوع المستشعر": {
      "type": "text",
      "required": true,
      "label": "نوع المستشعر",
      "hint": "مثال: Full Frame"
    },
    "دقة الفيديو": {
      "type": "text",
      "required": true,
      "label": "دقة الفيديو",
      "hint": "مثال: 4K 60fps"
    }
  },
  "الثلاجات": {
    "السعة": {
      "type": "number",
      "required": true,
      "label": "السعة (لتر)",
      "hint": "مثال: 500"
    },
    "نظام التبريد": {
      "type": "list",
      "required": true,
      "label": "نظام التبريد",
      "options": ["Inverter", "عادي", "بخار"]
    }
  },
  "غسالات الملابس": {
    "سعة التحميل": {
      "type": "number",
      "required": true,
      "label": "الوزن (كجم)",
      "hint": "مثال: 7"
    },
    "عدد البرامج": {
      "type": "number",
      "required": false,
      "label": "عدد البرامج",
      "hint": "مثال: 12"
    }
  },
  "المكيفات": {
    "قوة التبريد": {
      "type": "text",
      "required": true,
      "label": "القوة (BTU)",
      "hint": "مثال: 18000 وحدة"
    },
    "نوع الفريون": {
      "type": "text",
      "required": false,
      "label": "نوع الفريون",
      "hint": "مثال: R410A"
    }
  },
  "الميكروويف": {
    "القوة": {
      "type": "number",
      "required": true,
      "label": "القوة (واط)",
      "hint": "مثال: 1000"
    },
    "خاصية الشواء": {"type": "boolean", "required": true, "label": "يوجد شواية"}
  },
  "صانعات القهوة": {
    "ضغط المضخة": {
      "type": "number",
      "required": false,
      "label": "الضغط (بار)",
      "hint": "مثال: 15"
    },
    "نوع القهوة": {
      "type": "list",
      "required": true,
      "label": "نوع القهوة",
      "options": ["كبسولات", "بودرة", "حبوب", "متعدد"]
    }
  },
  "القلايات الهوائية": {
    "الحجم": {
      "type": "number",
      "required": true,
      "label": "الحجم (لتر)",
      "hint": "مثال: 4.5"
    },
    "شاشة رقمية": {"type": "boolean", "required": false, "label": "شاشة رقمية"}
  },
  "المكانس الكهربائية": {
    "قوة الشفط": {
      "type": "number",
      "required": true,
      "label": "القوة (واط)",
      "hint": "مثال: 2000"
    },
    "نوع الخزان": {
      "type": "list",
      "required": true,
      "label": "نوع الخزان",
      "options": ["كيس", "حاوية", "بدون كيس"]
    }
  },
  "الطابعات": {
    "نوع الطباعة": {
      "type": "list",
      "required": true,
      "label": "النوع",
      "options": ["ليزر", "حبر سائل (Inkjet)", "نقطية"]
    },
    "طباعة ملونة": {"type": "boolean", "required": true, "label": "طباعة ملونة"}
  },
  "الراوترات": {
    "معيار الواي فاي": {
      "type": "text",
      "required": true,
      "label": "المعيار",
      "hint": "مثال: WiFi 6"
    },
    "السرعة القصوى": {
      "type": "text",
      "required": true,
      "label": "السرعة",
      "hint": "مثال: 3000 Mbps"
    }
  },
  "القمصان الرجالية": {
    "المقاس": {
      "type": "list",
      "required": true,
      "label": "المقاس",
      "options": ["S", "M", "L", "XL", "XXL", "3XL"]
    },
    "نوع القماش": {
      "type": "text",
      "required": true,
      "label": "القماش",
      "hint": "مثال: قطن 100%"
    }
  },
  "الأحذية الرياضية": {
    "مقاس القدم": {
      "type": "number",
      "required": true,
      "label": "المقاس (EU)",
      "hint": "مثال: 42"
    },
    "مادة النعل": {
      "type": "text",
      "required": false,
      "label": "مادة النعل",
      "hint": "مثال: مريح"
    }
  },
  "الفساتين": {
    "الطول": {
      "type": "list",
      "required": true,
      "label": "الطول",
      "options": ["طويل", "قصير", "ميدي"]
    },
    "المناسبة": {
      "type": "list",
      "required": false,
      "label": "المناسبة",
      "options": ["سهرة", "كاجوال", "عمل", "حفلة"]
    }
  },
  "حقائب الظهر": {
    "عدد الجيوب": {
      "type": "number",
      "required": false,
      "label": "عدد الجيوب",
      "hint": "مثال: 3"
    },
    "مقاومة الماء": {
      "type": "boolean",
      "required": true,
      "label": "مقاومة للماء"
    }
  },
  "النظارات الشمسية": {
    "نوع العدسة": {
      "type": "list",
      "required": true,
      "label": "العدسة",
      "options": ["مستقطبة", "عادية", "UV400"]
    },
    "مادة الإطار": {
      "type": "list",
      "required": true,
      "label": "الإطار",
      "options": ["معدن", "بلاستيك", "تيتانيوم"]
    }
  },
  "العطور": {
    "الحجم": {
      "type": "number",
      "required": true,
      "label": "الحجم (مل)",
      "hint": "مثال: 100"
    },
    "التركيز": {
      "type": "list",
      "required": true,
      "label": "التركيز",
      "options": ["Parfum", "EDP", "EDT", "Cologne"]
    }
  },
  "كريمات البشرة": {
    "نوع البشرة": {
      "type": "list",
      "required": true,
      "label": "البشرة المناسبة",
      "options": ["جميع الأنواع", "دهنية", "جافة", "مختلطة", "حساسة"]
    },
    "عامل الحماية SPF": {
      "type": "number",
      "required": false,
      "label": "SPF",
      "hint": "مثال: 50"
    }
  },
  "الساعات الكلاسيكية": {
    "مادة السوار": {
      "type": "list",
      "required": true,
      "label": "السوار",
      "options": ["جلد", "ستانلس ستيل", "قماش", "سيليكون"]
    },
    "نوع الماكينة": {
      "type": "list",
      "required": true,
      "label": "الحركة",
      "options": ["كوارتز (بطارية)", "أوتوماتيك", "ميكانيكي"]
    }
  },
  "الدراجات الهوائية": {
    "عدد السرعات": {
      "type": "number",
      "required": true,
      "label": "عدد السرعات",
      "hint": "مثال: 21"
    },
    "نوع الفرامل": {
      "type": "list",
      "required": true,
      "label": "الفرامل",
      "options": ["عادي", "ديسك", "هيدروليك"]
    }
  },
  "أطقم الكنب": {
    "عدد المقاعد": {
      "type": "number",
      "required": true,
      "label": "عدد المقاعد",
      "hint": "مثال: 5"
    },
    "نوع الحشوة": {
      "type": "text",
      "required": false,
      "label": "الحشوة",
      "hint": "مثال: إسفنج مضغوط"
    }
  },
  "طاولات الطعام": {
    "عدد الكراسي": {
      "type": "number",
      "required": true,
      "label": "عدد الكراسي",
      "hint": "مثال: 6"
    },
    "شكل الطاولة": {
      "type": "list",
      "required": true,
      "label": "الشكل",
      "options": ["مستطيل", "دائري", "مربع", "بيضاوي"]
    }
  },
  "مراتب السرير": {
    "درجة القساوة": {
      "type": "list",
      "required": true,
      "label": "القساوة",
      "options": ["لين", "متوسط", "قاسي", "قاسي جداً"]
    },
    "نظام النوابض": {
      "type": "list",
      "required": false,
      "label": "النوابض",
      "options": ["متصلة", "منفصلة", "بدون نوابض (طبية)"]
    }
  },
  "الإضاءة المنزلية": {
    "نوع اللمبة": {
      "type": "list",
      "required": true,
      "label": "النوع",
      "options": ["LED", "هالوجين", "توفير", "فتيل"]
    },
    "لون الإضاءة": {
      "type": "list",
      "required": true,
      "label": "اللون",
      "options": ["أبيض", "أصفر (Warm)", "شمسي (Neutral)", "RGB"]
    }
  },
  "أواني الطبخ": {
    "المادة": {
      "type": "list",
      "required": true,
      "label": "المادة",
      "options": ["تيفال", "جرانيت", "سيراميك", "ستانلس ستيل", "ألمنيوم"]
    },
    "آمن للغسالة": {
      "type": "boolean",
      "required": true,
      "label": "آمن لغسالة الصحون"
    }
  },
  "السكاكين": {
    "طول الشفرة": {
      "type": "number",
      "required": true,
      "label": "الطول (سم)",
      "hint": "مثال: 20"
    },
    "الاستخدام": {
      "type": "text",
      "required": false,
      "label": "الاستخدام",
      "hint": "مثال: شيف، تقطيع، خبز"
    }
  },
  "ألعاب التركيب (Lego)": {
    "عدد القطع": {
      "type": "number",
      "required": true,
      "label": "عدد القطع",
      "hint": "مثال: 500"
    },
    "الفئة العمرية": {
      "type": "text",
      "required": true,
      "label": "العمر",
      "hint": "مثال: +6"
    }
  },
  "أجهزة الجري": {
    "الوزن الأقصى": {
      "type": "number",
      "required": true,
      "label": "تحمل الوزن (كجم)",
      "hint": "مثال: 120"
    },
    "السرعة القصوى": {
      "type": "number",
      "required": true,
      "label": "السرعة القصوى",
      "hint": "مثال: 16 كم/س"
    }
  },
  "أجهزة التخييم": {
    "عدد الأشخاص": {
      "type": "number",
      "required": true,
      "label": "السعة (أشخاص)",
      "hint": "مثال: 4"
    },
    "الوزن": {
      "type": "number",
      "required": false,
      "label": "الوزن (كجم)",
      "hint": "مثال: 5.2"
    }
  },
  "الآلات الموسيقية": {
    "النوع": {
      "type": "list",
      "required": true,
      "label": "التصنيف",
      "options": ["وترية", "إيقاعية", "نفخ", "لوفية"]
    },
    "مادة الصنع": {
      "type": "text",
      "required": false,
      "label": "المادة",
      "hint": "مثال: خشب الماهوجني"
    }
  },
  "طعام الحيوانات": {
    "المكونات الأساسية": {
      "type": "text",
      "required": true,
      "label": "المكونات",
      "hint": "مثال: دجاج وأرز"
    },
    "العمر المستهدف": {
      "type": "list",
      "required": true,
      "label": "الفئة",
      "options": ["جرو/صغير", "بالغ", "كبير في السن", "جميع الأعمار"]
    }
  },
  "مستلزمات المواليد": {
    "المادة": {
      "type": "text",
      "required": true,
      "label": "المادة",
      "hint": "مثال: سيليكون طبي"
    },
    "خالي من BPA": {"type": "boolean", "required": true, "label": "خالي من BPA"}
  },
  "زيوت المحركات": {
    "اللزوجة": {
      "type": "text",
      "required": true,
      "label": "اللزوجة",
      "hint": "مثال: 5W-30"
    },
    "النوع": {
      "type": "list",
      "required": true,
      "label": "النوع",
      "options": ["تخليقي بالكامل", "نصف تخليقي", "معدني"]
    }
  },
  "إطارات السيارات": {
    "مقاس الجنط": {
      "type": "number",
      "required": true,
      "label": "المقاس",
      "hint": "مثال: 17"
    },
    "سنة الصنع": {
      "type": "number",
      "required": true,
      "label": "السنة",
      "hint": "مثال: 2024"
    }
  },
  "البطاريات الجافة": {
    "المقاس": {
      "type": "list",
      "required": true,
      "label": "المقاس",
      "options": ["AA", "AAA", "C", "D", "9V"]
    },
    "قابلة للشحن": {"type": "boolean", "required": true, "label": "قابلة للشحن"}
  },
  "الأدوات اليدوية": {
    "الاستخدام": {
      "type": "text",
      "required": true,
      "label": "الاستخدام",
      "hint": "مثال: نجارة"
    },
    "مادة القبضة": {
      "type": "text",
      "required": false,
      "label": "مادة المقبض",
      "hint": "مثال: مطاط مريح"
    }
  },
  "الكتب": {
    "عدد الصفحات": {
      "type": "number",
      "required": true,
      "label": "عدد الصفحات",
      "hint": "مثال: 200"
    },
    "نوع الغلاف": {
      "type": "list",
      "required": true,
      "label": "الغلاف",
      "options": ["ورقي", "كرتون مقوى", "ديجيتال"]
    }
  },
  "القرطاسية": {
    "اللون": {
      "type": "text",
      "required": true,
      "label": "اللون",
      "hint": "مثال: أزرق"
    },
    "الكمية": {
      "type": "number",
      "required": true,
      "label": "الكمية في العبوة",
      "hint": "مثال: 12"
    }
  },
  "مكملات البروتين": {
    "الوزن": {
      "type": "number",
      "required": true,
      "label": "الوزن (كجم)",
      "hint": "مثال: 2.2"
    },
    "النكهة": {
      "type": "text",
      "required": true,
      "label": "النكهة",
      "hint": "مثال: شوكولاتة"
    }
  },
  "معدات الصيد": {
    "طول القصبة": {
      "type": "number",
      "required": true,
      "label": "الطول (متر)",
      "hint": "مثال: 3.5"
    },
    "قوة التحمل": {
      "type": "number",
      "required": false,
      "label": "التحمل (كجم)",
      "hint": "مثال: 10"
    }
  },
  "الحقائب المدرسية": {
    "عدد السحابات": {
      "type": "number",
      "required": false,
      "label": "عدد السحابات/الجيوب",
      "hint": "مثال: 3"
    },
    "مكان لابتوب": {
      "type": "boolean",
      "required": true,
      "label": "يوجد جيب لابتوب"
    }
  },
  "الشاشات الاحترافية": {
    "معدل التحديث": {
      "type": "number",
      "required": true,
      "label": "الهيرتز (Hz)",
      "hint": "مثال: 144"
    },
    "وقت الاستجابة": {
      "type": "text",
      "required": true,
      "label": "الاستجابة",
      "hint": "مثال: 1ms"
    }
  },
  "الباور بانك": {
    "السعة": {
      "type": "number",
      "required": true,
      "label": "السعة (mAh)",
      "hint": "مثال: 20000"
    },
    "عدد المنافذ": {
      "type": "number",
      "required": true,
      "label": "عدد المنافذ",
      "hint": "مثال: 3"
    }
  },
  "مكبرات الصوت": {
    "القوة": {
      "type": "number",
      "required": true,
      "label": "القوة (واط RMS)",
      "hint": "مثال: 40"
    },
    "الاتصال": {
      "type": "list",
      "required": true,
      "label": "الاتصال",
      "options": ["بلوتوث", "AUX", "WiFi", "متعدد"]
    }
  },
  "كبائن الاستحمام": {
    "المادة": {
      "type": "list",
      "required": true,
      "label": "المادة",
      "options": ["زجاج مقسى", "أكريليك", "بلاستيك"]
    },
    "الأبعاد": {
      "type": "text",
      "required": true,
      "label": "الأبعاد (سم)",
      "hint": "مثال: 90x90"
    }
  },
  "الخزائن الحديدية": {
    "نوع القفل": {
      "type": "list",
      "required": true,
      "label": "القفل",
      "options": ["مفتاح", "رقمي", "بصمة", "مزدوج"]
    },
    "مقاومة الحريق": {
      "type": "boolean",
      "required": true,
      "label": "مقاوم للحريق"
    }
  }
};
