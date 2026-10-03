# تطبيق SpacePoint لإدارة المقاولات والمشاريع المدنية (Flutter)

تطبيق متكامل مبني بإطار العمل Flutter باللغة العربية والاتجاه الكامل (RTL) متوافق مع نظام **SpacePoint** لإدارة المقاولات والمشاريع الميدانية، ومعتمد حصرياً على الـ REST API الموثق دون أي افتراضات خارج النطاق.

---

## 🏛️ بنية المشروع (Layered Architecture)

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # تعريف المسارات، الثوابت، والتصنيفات
│   ├── network/
│   │   ├── api_client.dart             # عميل HTTP المركزي، ترويسات التوكن والـ Multipart
│   │   └── api_exception.dart          # إدارة استثناءات الخادم وترجمة الأخطاء للعربية
│   ├── storage/
│   │   └── secure_storage_service.dart # التخزين الآمن المشفر للتوكن والإعدادات
│   ├── theme/
│   │   └── app_theme.dart              # تصميم Material 3 ونظام الألوان الإنشائي الفاخر
│   └── utils/
│       └── arabic_helpers.dart         # ترجمة الحالات، الأولويات، الفئات والتنسيقات
├── models/
│   ├── user_model.dart                 # نموذج المستخدم وصلاحيات الدور
│   ├── dashboard_model.dart            # مؤشرات الإشراف (المدير) والإنجاز (المهندس)
│   ├── site_model.dart                 # بيانات مواقع العمل الإنشائية
│   ├── machinery_model.dart            # بيانات الآليات والمعدات الثقيلة
│   ├── task_model.dart                 # بيانات المهام والتحديثات الميدانية
│   ├── expense_model.dart              # بنود المصروفات اليومية
│   ├── report_model.dart               # التقرير اليومي الشامل للموقع
│   └── notification_model.dart         # نموذج الإشعارات وتحديث القراءة
├── services/
│   ├── auth_service.dart               # تسجيل الدخول، الجلسة، والتحقق
│   ├── dashboard_service.dart          # جلب مؤشرات لوحة التحكم
│   ├── sites_service.dart              # قراءة المواقع الإنشائية
│   ├── machinery_service.dart          # قراءة الآليات والمعدات
│   ├── tasks_service.dart              # قراءة المهام وتحديث التقدم (خاص بالمهندس)
│   ├── reports_service.dart            # استعراض التقارير، إنشاؤها، ورفع الإيصالات
│   └── notifications_service.dart      # استعراض الإشعارات وتعليمها كمقروء
├── providers/
│   ├── auth_provider.dart              # إدارة حالة الجلسة، الصلاحيات، وحالة الحساب
│   ├── dashboard_provider.dart         # تزويد شاشة المؤشرات بالبيانات
│   ├── sites_machinery_provider.dart   # إدارة بيانات المواقع والآليات
│   ├── tasks_provider.dart             # إدارة قائمة المهام والفلترة والتحديث المحلي
│   ├── reports_provider.dart           # إدارة التقارير وحالات القفل 409
│   └── notifications_provider.dart     # إدارة الإشعارات وتحديث العداد
├── views/
│   ├── auth/
│   │   ├── login_screen.dart           # شاشة الدخول مع ضبط رابط الخادم
│   │   └── approval_pending_screen.dart # شاشة 403 انتظار الموافقة والاعتماد
│   ├── home/
│   │   └── home_scaffold.dart          # الهيكل المتكيف وشريط التنقل حسب الدور
│   ├── dashboard/
│   │   └── dashboard_screen.dart       # لوحة المؤشرات حسب الدور (مدير / مهندس)
│   ├── sites_machinery/
│   │   └── sites_machinery_screen.dart # تبويبات استعراض المواقع والآليات
│   ├── tasks/
│   │   └── tasks_screen.dart           # تصفية المهام ونموذج تحديث التقدم للمهندس
│   ├── reports/
│   │   ├── reports_screen.dart         # قائمة التقارير والمراجعة البصرية
│   │   ├── create_report_screen.dart   # نموذج التقرير اليومي وحاسبة المصروفات
│   │   └── upload_receipt_dialog.dart  # رفع الإيصال (JPEG, PNG, WebP, PDF <= 5MB)
│   ├── notifications/
│   │   └── notifications_screen.dart   # قائمة الإشعارات وتعليم المقروء
│   └── widgets/
│       ├── loading_widget.dart         # مؤشر تحميل موحد
│       ├── error_view.dart             # واجهة الخطأ مع زر إعادة المحاولة
│       ├── empty_view.dart             # واجهة الفراغ
│       ├── status_badge.dart           # شارات الحالات الملونة
│       └── responsive_container.dart   # استجابة مثالية للهاتف واللوحي
└── main.dart                           # نقطة الانطلاق وإعداد اللغات والـ Providers
```

---

## 🚀 تعليمات التشغيل (Running Instructions)

1. **تثبيت الحزم والاعتماديات:**
   ```bash
   flutter pub get
   ```

2. **تشغيل الاختبارات التلقائية:**
   ```bash
   flutter test
   ```

3. **التحقق من الكود والجودة:**
   ```bash
   flutter analyze
   ```

4. **تشغيل التطبيق على الهاتف أو المحاكي أو الحاسوب:**
   ```bash
   flutter run
   ```

---

## 🔒 المصادقة والأمان

- يتم تخزين التوكن في التخزين الآمن المشفر (`flutter_secure_storage`).
- إرفاق ترويسة `Authorization: Bearer <token>` وترويسة `Accept: application/json` تلقائياً في كل طلب محمي.
- عند استجابة الخادم بـ `401 Unauthorized`، يتم مسح التوكن فوراً وتحويل المستخدم إلى شاشة الدخول مع إظهار رسالة واضحة للمستخدم.
- عند استجابة الخادم بـ `403 Forbidden` الخاصة بعدم اعتماد الحساب، يتم توجيه المستخدم تلقائياً إلى **شاشة انتظار الموافقة والاعتماد** مع خيار إعادة التحقق وزر تسجيل الخروج.
- التزام صارم بعدم تسجيل أو طباعة كلمات المرور أو التوكن في الكونسول.
- إمكانية تعديل رابط الخادم مباشرة من شاشة تسجيل الدخول عبر أيقونة الإعدادات العلوية، أو عبر `AppConstants.defaultBaseUrl`.
