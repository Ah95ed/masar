import 'package:masar/core/network/api_exception.dart';

/// خدمة إدارة الوضع التجريبي (Demo Mode) للمعاينة والاختبار بدون خادم لتطبيق Maxlond Management
class DemoService {
  DemoService._();
  static final DemoService instance = DemoService._();

  bool isDemoMode = false;
  String currentRole = 'admin'; // admin فقط لتطبيق الإدارة

  // بيانات المدير العام الحالي
  Map<String, dynamic> get currentUserJson {
    return {
      'id': 1,
      'username': 'admin_maxlond',
      'full_name': 'م. عمر الناصري (المدير العام)',
      'role': 'admin',
      'email': 'admin@maxlond.com',
      'phone': '07700000001',
      'is_active': true,
      'status': 'active',
    };
  }

  // قائمة المستخدمين
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'id': 1,
      'username': 'admin_maxlond',
      'full_name': 'م. عمر الناصري',
      'role': 'admin',
      'email': 'admin@maxlond.com',
      'phone': '07700000001',
      'is_active': true,
      'status': 'active',
    },
    {
      'id': 101,
      'username': 'eng_ali',
      'full_name': 'م. علي الجبوري',
      'role': 'engineer',
      'email': 'ali@maxlond.com',
      'phone': '07801234567',
      'is_active': true,
      'status': 'active',
    },
    {
      'id': 102,
      'username': 'eng_hassan',
      'full_name': 'م. حسن الكعبي',
      'role': 'engineer',
      'email': 'hassan@maxlond.com',
      'phone': '07712345678',
      'is_active': true,
      'status': 'active',
    },
    {
      'id': 103,
      'username': 'eng_sara',
      'full_name': 'م. سارة الحمداني',
      'role': 'engineer',
      'email': 'sara@maxlond.com',
      'phone': '07723456789',
      'is_active': true,
      'status': 'active',
    },
    {
      'id': 201,
      'username': 'acc_mustafa',
      'full_name': 'مصطفى العبيدي',
      'role': 'accountant',
      'email': 'accountant@maxlond.com',
      'phone': '07823456789',
      'is_active': true,
      'status': 'active',
    },
  ];

  // متصدرو الأداء الهندسي اليوم
  final List<Map<String, dynamic>> _demoTopEngineers = [
    {
      'engineer_id': 101,
      'full_name': 'م. علي الجبوري',
      'score': 98.5,
      'activity_count': 14,
      'completed_tasks': 5,
    },
    {
      'engineer_id': 103,
      'full_name': 'م. سارة الحمداني',
      'score': 94.0,
      'activity_count': 11,
      'completed_tasks': 4,
    },
    {
      'engineer_id': 102,
      'full_name': 'م. حسن الكعبي',
      'score': 89.2,
      'activity_count': 9,
      'completed_tasks': 3,
    },
  ];

  // المواقع الإنشائية
  final List<Map<String, dynamic>> _demoSites = [
    {
      'id': 1,
      'name': 'مشروع برج مكسلوند التجاري',
      'client_name': 'شركة الأفق للاستثمار العقاري',
      'work_date': '2026-01-15',
      'start_time': '07:30',
      'end_time': '16:30',
      'location': 'حي المنصور، بغداد',
      'budget': 3500000.0,
      'status': 'active',
      'manager_id': 1,
      'description': 'إنشاء برج تجاري بارتفاع 24 طابقاً مع موقف سيارات سفلي ثلاثي الطوابق.',
      'progress': 68,
    },
    {
      'id': 2,
      'name': 'مجمع الفرات السكني - المرحلة 2',
      'client_name': 'هيئة الإسكان المدني',
      'work_date': '2026-03-01',
      'start_time': '08:00',
      'end_time': '17:00',
      'location': 'الكرادة، شارع المسبح',
      'budget': 2200000.0,
      'status': 'active',
      'manager_id': 1,
      'description': 'تنفيذ 8 عمارات سكنية مع شبكات البنية التحتية والحدائق.',
      'progress': 42,
    },
    {
      'id': 3,
      'name': 'تطوير طريق المرور السريع قطاع 4',
      'client_name': 'دائرة الطرق والجسور',
      'work_date': '2025-10-01',
      'start_time': '06:00',
      'end_time': '18:00',
      'location': 'المدخل الجنوبي، المحطة 14',
      'budget': 1850000.0,
      'status': 'active',
      'manager_id': 1,
      'description': 'توسيع المسار وإكساء طبقة رابطة وسطحية مع إنارة ذكية.',
      'progress': 85,
    },
  ];

  // خطط العمل / المهام
  final List<Map<String, dynamic>> _demoTasks = [
    {
      'id': 10,
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'title': 'صب خرسانة القواعد والأساسات',
      'description': 'إشراف على صب خرسانة الأساس C35 وتأكيد أخذ المكعبات القياسية للاختبار.',
      'assigned_to': 101,
      'assigned_to_name': 'م. علي الجبوري',
      'is_broadcast': 0,
      'priority': 'high',
      'status': 'in_progress',
      'progress': 65,
      'created_at': '2026-10-01 08:00',
    },
    {
      'id': 11,
      'site_id': 2,
      'site_name': 'مجمع الفرات السكني - المرحلة 2',
      'title': 'تركيب حديد تسليح أعمدة الطابق الأول',
      'description': 'تدقيق تربيط أساور الأعمدة ومسافات التوزيع حسب المخططات.',
      'assigned_to': 103,
      'assigned_to_name': 'م. سارة الحمداني',
      'is_broadcast': 0,
      'priority': 'urgent',
      'status': 'in_progress',
      'progress': 40,
      'created_at': '2026-10-02 09:30',
    },
    {
      'id': 12,
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'title': 'تفتيش إجراءات السلامة الميدانية العامة',
      'description': 'تعميم تفتيش وفحص جميع السقالات وشبكات الحماية لجميع الفرق الهندسية.',
      'assigned_to': null,
      'assigned_to_name': 'تعميم للجميع',
      'is_broadcast': 1,
      'priority': 'high',
      'status': 'pending',
      'progress': 0,
      'created_at': '2026-10-03 08:00',
    },
  ];

  // الآليات
  final List<Map<String, dynamic>> _demoMachinery = [
    {
      'id': 1,
      'name': 'حفارة هيدروليكية CAT 320D',
      'code': 'CAT-EX-01',
      'type': 'حفارة مجنزرة',
      'status': 'operational',
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'plate_number': 'بغداد 45120 أ',
      'operator_name': 'كريم هادي',
    },
    {
      'id': 2,
      'name': 'رافعة برجية ليبهير 550 EC-H',
      'code': 'LBH-CR-02',
      'type': 'رافعة برجية 12 طن',
      'status': 'operational',
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'plate_number': 'رافعة ثابتة',
      'operator_name': 'أحمد صباح',
    },
    {
      'id': 3,
      'name': 'مضخة خرسانة مرسيدس شاوينغ 42م',
      'code': 'SCH-PMP-03',
      'type': 'مضخة خرسانة متحركة',
      'status': 'under_maintenance',
      'site_id': 2,
      'site_name': 'مجمع الفرات السكني - المرحلة 2',
      'plate_number': 'بابل 18450 ب',
      'operator_name': 'حيدر عبد الله',
    },
  ];

  // عمليات الصيانة
  final List<Map<String, dynamic>> _demoRepairs = [
    {
      'id': 1,
      'machinery_id': 3,
      'machinery_name': 'مضخة خرسانة مرسيدس شاوينغ 42م',
      'machinery_code': 'SCH-PMP-03',
      'issue_description': 'تسريب زيت هيدروليكي في ذراع التوزيع الرئيسي وضعف الضغط.',
      'action_taken': 'استبدال مانع التسريب وخراطيم الضغط العالي مع فحص الصمامات.',
      'cost': 1450.0,
      'status': 'in_progress',
      'workshop_name': 'ورشة الهيدروليك المركزية',
      'start_date': '2026-10-02',
      'completed_date': null,
      'notes': 'قطع الغيار أصلية بانتظار التجربة النهائية غداً.',
      'created_at': '2026-10-02 10:00',
    },
    {
      'id': 2,
      'machinery_id': 1,
      'machinery_name': 'حفارة هيدروليكية CAT 320D',
      'machinery_code': 'CAT-EX-01',
      'issue_description': 'تبديل فلاتر ديزل وزيوت صيانة دورية 500 ساعة.',
      'action_taken': 'تم إنجاز الصيانة الدورية وتبديل زيت المحرك وفلاتر الهواء.',
      'cost': 420.0,
      'status': 'completed',
      'workshop_name': 'فريق الصيانة الميداني',
      'start_date': '2026-09-25',
      'completed_date': '2026-09-25',
      'notes': 'الحالة ممتازة وجاهزة للعمل المكثف.',
      'created_at': '2026-09-25 14:00',
    },
  ];

  // أصناف المخزن
  final List<Map<String, dynamic>> _demoWarehouseCategories = [
    {'id': 1, 'name': 'مواد بناء أساسية', 'description': 'إسمنت، حديد، رمل، بحص'},
    {'id': 2, 'name': 'مواد عزل وحماية', 'description': 'عوازل مائية وحرارية وبيتومين'},
    {'id': 3, 'name': 'كهربائيات وتمديدات', 'description': 'كابلات وقواطع ومحولات'},
  ];

  final List<Map<String, dynamic>> _demoWarehouseItems = [
    {
      'id': 1,
      'name': 'إسمنت بورتلاندي مقاوم للأملاح',
      'code': 'MAT-CMT-01',
      'category_id': 1,
      'category_name': 'مواد بناء أساسية',
      'unit': 'كيس 50 كغم',
      'current_stock': 850.0,
      'min_stock': 200.0,
      'unit_price': 6.5,
      'status': 'active',
      'location': 'المستودع الرئيسي - رصيف 1',
    },
    {
      'id': 2,
      'name': 'حديد تسليح عالي المقاومة 16 ملم',
      'code': 'MAT-STL-16',
      'category_id': 1,
      'category_name': 'مواد بناء أساسية',
      'unit': 'طن',
      'current_stock': 35.0,
      'min_stock': 10.0,
      'unit_price': 850.0,
      'status': 'active',
      'location': 'الساحة المفتوحة A',
    },
    {
      'id': 3,
      'name': 'رولات عزل مائي ممبرين 4 ملم',
      'code': 'MAT-ISO-04',
      'category_id': 2,
      'category_name': 'مواد عزل وحماية',
      'unit': 'رول',
      'current_stock': 12.0,
      'min_stock': 20.0,
      'unit_price': 38.0,
      'status': 'active',
      'location': 'مستودع العوازل - قطاع B',
    },
  ];

  final List<Map<String, dynamic>> _demoWarehouseMoves = [
    {
      'id': 1,
      'item_id': 1,
      'item_name': 'إسمنت بورتلاندي مقاوم للأملاح',
      'move_type': 'out',
      'quantity': 150.0,
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'notes': 'صرف لأعمال صب خرسانة القواعد',
      'created_at': '2026-10-02 09:00',
      'created_by': 'مصطفى العبيدي',
    },
    {
      'id': 2,
      'item_id': 2,
      'item_name': 'حديد تسليح عالي المقاومة 16 ملم',
      'move_type': 'in',
      'quantity': 25.0,
      'site_id': null,
      'site_name': null,
      'notes': 'توريد جديد من شركة الحديد الوطنية بموجب فاتورة #8821',
      'created_at': '2026-10-01 11:30',
      'created_by': 'مصطفى العبيدي',
    },
  ];

  // الحسابات والمالية
  final List<Map<String, dynamic>> _demoAccounts = [
    {
      'id': 1010,
      'code': '1010',
      'name': 'الصندوق الرئيسي - الإدارة',
      'type': 'asset',
      'balance': 185000.0,
      'description': 'النقدية المتوفرة في خزينة الإدارة العامة',
      'has_journal_entries': true,
    },
    {
      'id': 1020,
      'code': '1020',
      'name': 'حساب المصرف التجاري العراقي',
      'type': 'asset',
      'balance': 1420000.0,
      'description': 'الحساب الجاري التشغيلي للمشاريع',
      'has_journal_entries': true,
    },
    {
      'id': 5010,
      'code': '5010',
      'name': 'مصروفات وقود ومحروقات الآليات',
      'type': 'expense',
      'balance': 48500.0,
      'description': 'تكاليف وقود الديزل والبنزين للمعدات والمولدات',
      'has_journal_entries': true,
    },
    {
      'id': 5020,
      'code': '5020',
      'name': 'أجور عمالة ومقاولي باطن',
      'type': 'expense',
      'balance': 96200.0,
      'description': 'مستحقات العمالة اليومية وفرق الصب والحدادة',
      'has_journal_entries': true,
    },
    {
      'id': 4010,
      'code': '4010',
      'name': 'إيرادات مستخلصات المشاريع المعتمدة',
      'type': 'revenue',
      'balance': 2850000.0,
      'description': 'الدفعات المستلمة من أصحاب العمل والعملاء',
      'has_journal_entries': true,
    },
  ];

  final List<Map<String, dynamic>> _demoJournalEntries = [
    {
      'id': 1,
      'entry_number': 'JV-2026-00142',
      'date': '2026-10-02',
      'description': 'إثبات مصروفات التقرير اليومي المعتمد #500 لمجمع الفرات',
      'total_amount': 240.0,
      'is_posted': true,
      'site_id': 2,
      'site_name': 'مجمع الفرات السكني - المرحلة 2',
      'created_at': '2026-10-02 18:00',
      'created_by': 'النظام التلقائي (اعتماد تقرير)',
      'lines': [
        {
          'account_id': 5010,
          'account_name': 'مصروفات وقود ومحروقات الآليات',
          'account_code': '5010',
          'debit': 240.0,
          'credit': 0.0,
          'description': 'نقل أخشاب وقوالب',
        },
        {
          'account_id': 1010,
          'account_name': 'الصندوق الرئيسي - الإدارة',
          'account_code': '1010',
          'debit': 0.0,
          'credit': 240.0,
          'description': 'صرف من الصندوق للمهندس',
        },
      ],
    },
  ];

  // التقارير اليومية للمراجعة
  final List<Map<String, dynamic>> _demoReports = [
    {
      'id': 501,
      'site_id': 1,
      'site_name': 'مشروع برج مكسلوند التجاري',
      'report_date': '2026-10-02',
      'weather': 'مشمس ومعتدل',
      'temperature': 29.0,
      'workers_count': 22,
      'machinery_count': 4,
      'work_done': 'استكمال أعمال الحدادة لجدران القص وصب الجزء الجنوبي من اللبشة الأساسية.',
      'issues': 'تأخر شاحنة توريد البحص مدة ساعة في الصباح.',
      'materials_used': '12 طن حديد تسليح، 140 م³ خرسانة جاهزة C35.',
      'safety_notes': 'التزام كامل بارتداء الخوذ والأحذية الواقية ولا توجد أي حوادث.',
      'progress_percent': 68,
      'status': 'pending_approval',
      'engineer_id': 101,
      'engineer_name': 'م. علي الجبوري',
      'created_at': '2026-10-02 17:30',
      'admin_notes': null,
      'expenses': [
        {
          'item_name': 'وقود ديزل للمولدات والآليات',
          'category': 'fuel',
          'quantity': 350.0,
          'unit_price': 1.5,
          'notes': 'تعبئة من محطة التوزيع المعتمدة',
        },
        {
          'item_name': 'سلك ربط مسامير ومستهلكات نجارة',
          'category': 'materials',
          'quantity': 15.0,
          'unit_price': 20.0,
          'notes': 'شراء مباشر بموجب وصل',
        },
      ],
      'receipts': [
        {
          'id': 1,
          'file_url': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600',
          'file_name': 'receipt_diesel_site1.jpg',
          'uploaded_at': '2026-10-02 17:32',
          'amount': 525.0,
        },
      ],
    },
    {
      'id': 500,
      'site_id': 2,
      'site_name': 'مجمع الفرات السكني - المرحلة 2',
      'report_date': '2026-10-01',
      'weather': 'صحو',
      'temperature': 31.5,
      'workers_count': 18,
      'machinery_count': 2,
      'work_done': 'تجهيز قوالب الخشب للأعمدة وتثبيت الدعائم الشاقولية.',
      'issues': null,
      'materials_used': 'أخشاب بليوود جديدة، زيت عزل قوالب.',
      'safety_notes': 'فحص السقالات وتأمين منصات العمل العلوية.',
      'progress_percent': 40,
      'status': 'approved',
      'engineer_id': 103,
      'engineer_name': 'م. سارة الحمداني',
      'created_at': '2026-10-01 16:45',
      'admin_notes': 'تم الاعتماد وإنشاء القيد المحاسبي بنجاح.',
      'expenses': [
        {
          'item_name': 'نقل أخشاب وقوالب من المستودع',
          'category': 'transport',
          'quantity': 2.0,
          'unit_price': 120.0,
          'notes': 'أجور شاحنة النقل الخارجي',
        },
      ],
      'receipts': [],
    },
  ];

  // الإشعارات
  final List<Map<String, dynamic>> _demoNotifications = [
    {
      'id': 201,
      'title': 'تقرير بانتظار الاعتماد',
      'message': 'قام م. علي الجبوري برفع التقرير اليومي لمشروع برج مكسلوند للمراجعة.',
      'is_read': false,
      'created_at': 'منذ ساعة',
      'type': 'report',
    },
    {
      'id': 202,
      'title': 'تنبيه مخزون منخفض',
      'message': 'رولات عزل مائي ممبرين وصلت إلى 12 رول (الحد الأدنى 20).',
      'is_read': false,
      'created_at': 'منذ 3 ساعات',
      'type': 'warehouse',
    },
    {
      'id': 203,
      'title': 'صيانة آلية جارية',
      'message': 'مضخة الخرسانة 42م في ورشة الصيانة الهيدروليكية المركزية.',
      'is_read': true,
      'created_at': 'منذ يومين',
      'type': 'machinery',
    },
  ];

  /// معالجة طلبات GET في الوضع التجريبي
  dynamic handleGet(String route, Map<String, String>? queryParams) {
    switch (route) {
      case 'me':
        return currentUserJson;

      case 'dashboard':
        return {
          'sites': _demoSites.where((s) => s['status'] != 'cancelled').length,
          'engineers': _demoUsers.where((u) => u['role'] == 'engineer').length,
          'machinery': _demoMachinery.length,
          'pending_reports': _demoReports.where((r) => r['status'] == 'pending_approval').length,
          'inventory_value': _demoWarehouseItems.fold<double>(
            0.0,
            (sum, item) => sum + ((item['current_stock'] as num) * (item['unit_price'] as num)),
          ),
          'today_top_engineers': _demoTopEngineers,
        };

      case 'sites':
        return _demoSites;

      case 'tasks':
        var filtered = List<Map<String, dynamic>>.from(_demoTasks);
        if (queryParams != null) {
          if (queryParams.containsKey('site_id')) {
            final sid = int.tryParse(queryParams['site_id'] ?? '');
            if (sid != null) {
              filtered = filtered.where((t) => t['site_id'] == sid).toList();
            }
          }
          if (queryParams.containsKey('status') && queryParams['status'] != 'all') {
            final st = queryParams['status']!.toLowerCase();
            filtered = filtered.where((t) => t['status'] == st).toList();
          }
        }
        return filtered;

      case 'reports':
        if (queryParams != null && queryParams.containsKey('id')) {
          final id = int.tryParse(queryParams['id'] ?? '');
          final rep = _demoReports.firstWhere(
            (r) => r['id'] == id,
            orElse: () => throw ApiException(statusCode: 404, message: 'التقرير غير موجود'),
          );
          return rep;
        }
        var repList = List<Map<String, dynamic>>.from(_demoReports);
        if (queryParams != null) {
          if (queryParams.containsKey('status') && queryParams['status'] != 'all') {
            final st = queryParams['status']!.toLowerCase();
            repList = repList.where((r) => r['status'] == st).toList();
          }
          if (queryParams.containsKey('site_id')) {
            final sid = int.tryParse(queryParams['site_id'] ?? '');
            if (sid != null) {
              repList = repList.where((r) => r['site_id'] == sid).toList();
            }
          }
        }
        return repList;

      case 'users':
        return _demoUsers;

      case 'machinery':
        return _demoMachinery;

      case 'warehouse-items':
        return _demoWarehouseItems;

      case 'warehouse-categories':
        return _demoWarehouseCategories;

      case 'warehouse-moves':
        return _demoWarehouseMoves;

      case 'repairs':
        if (queryParams != null && queryParams.containsKey('id')) {
          final rid = int.tryParse(queryParams['id'] ?? '');
          return _demoRepairs.firstWhere(
            (r) => r['id'] == rid,
            orElse: () => throw ApiException(statusCode: 404, message: 'سجل الصيانة غير موجود'),
          );
        }
        return _demoRepairs;

      case 'accounts':
        return _demoAccounts;

      case 'journal':
        return _demoJournalEntries;

      case 'financial':
        final totalRev = _demoAccounts
            .where((a) => a['type'] == 'revenue')
            .fold<double>(0.0, (s, a) => s + (a['balance'] as num).toDouble());
        final totalExp = _demoAccounts
            .where((a) => a['type'] == 'expense')
            .fold<double>(0.0, (s, a) => s + (a['balance'] as num).toDouble());
        final totalAssets = _demoAccounts
            .where((a) => a['type'] == 'asset')
            .fold<double>(0.0, (s, a) => s + (a['balance'] as num).toDouble());
        return {
          'total_revenues': totalRev,
          'total_expenses': totalExp,
          'net_profit': totalRev - totalExp,
          'total_assets': totalAssets,
          'total_liabilities': 0.0,
          'total_entries_count': _demoJournalEntries.length,
        };

      case 'notifications':
        return _demoNotifications;

      default:
        return {'success': true};
    }
  }

  /// معالجة طلبات POST في الوضع التجريبي
  dynamic handlePost(String route, Map<String, dynamic>? body) {
    switch (route) {
      case 'login':
        return {
          'token': 'demo_bearer_token_maxlond_admin',
          'token_type': 'Bearer',
          'expires_in': 86400,
          'user': currentUserJson,
        };

      case 'logout':
        return {'success': true};

      case 'site-save':
        if (body != null) {
          final id = body['id'] != null ? int.tryParse(body['id'].toString()) : null;
          if (id != null && id > 0) {
            final idx = _demoSites.indexWhere((s) => s['id'] == id);
            if (idx != -1) {
              _demoSites[idx] = {..._demoSites[idx], ...body};
              return {'success': true, 'message': 'تم تحديث بيانات الموقع بنجاح.'};
            }
          }
          final newSite = Map<String, dynamic>.from(body);
          newSite['id'] = _demoSites.length + 1;
          newSite['status'] = newSite['status'] ?? 'active';
          newSite['progress'] = newSite['progress'] ?? 0;
          _demoSites.add(newSite);
          return {'success': true, 'id': newSite['id'], 'message': 'تم إنشاء الموقع بنجاح.'};
        }
        return {'success': true};

      case 'site-cancel':
        if (body != null && body.containsKey('site_id')) {
          final sid = int.tryParse(body['site_id'].toString());
          final idx = _demoSites.indexWhere((s) => s['id'] == sid);
          if (idx != -1) {
            _demoSites[idx]['status'] = 'cancelled';
            return {'success': true, 'message': 'تم أرشفة الموقع وإلغاؤه بنجاح مع الحفاظ على السجل التاريخي.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'الموقع غير موجود');

      case 'site-delete':
        if (body != null && body.containsKey('site_id')) {
          final sid = int.tryParse(body['site_id'].toString());
          final idx = _demoSites.indexWhere((s) => s['id'] == sid);
          if (idx != -1) {
            _demoSites.removeAt(idx);
            return {'success': true, 'message': 'تم حذف الموقع نهائياً.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'الموقع غير موجود');

      case 'work-plan-save':
        if (body != null) {
          final existingId = body['id'] != null ? int.tryParse(body['id'].toString()) : (body['task_id'] != null ? int.tryParse(body['task_id'].toString()) : null);
          if (existingId != null && existingId > 0) {
            final idx = _demoTasks.indexWhere((t) => t['id'] == existingId);
            if (idx != -1) {
              final isBroadcast = body['is_broadcast'] == 1 || body['is_broadcast'] == true;
              String assignedName = _demoTasks[idx]['assigned_to_name'] ?? 'تعميم للجميع';
              if (!isBroadcast && body['assigned_to'] != null) {
                final eng = _demoUsers.firstWhere(
                  (u) => u['id'] == body['assigned_to'],
                  orElse: () => {'full_name': 'مهندس مخصص'},
                );
                assignedName = eng['full_name'];
              }
              _demoTasks[idx] = {
                ..._demoTasks[idx],
                'title': body['title'] ?? _demoTasks[idx]['title'],
                'description': body['description'] ?? _demoTasks[idx]['description'],
                'assigned_to': isBroadcast ? null : (body['assigned_to'] ?? _demoTasks[idx]['assigned_to']),
                'assigned_to_name': isBroadcast ? 'تعميم للجميع' : assignedName,
                'is_broadcast': isBroadcast ? 1 : 0,
                'priority': body['priority'] ?? _demoTasks[idx]['priority'],
                if (body['status'] != null) 'status': body['status'],
              };
              return {'success': true, 'message': 'تم تعديل خطة العمل بنجاح.'};
            }
          }

          final newId = 100 + _demoTasks.length + 1;
          final siteId = body['site_id'];
          final siteName = _demoSites.firstWhere(
            (s) => s['id'] == siteId,
            orElse: () => {'name': 'موقع رقم $siteId'},
          )['name'];

          final isBroadcast = body['is_broadcast'] == 1 || body['is_broadcast'] == true;
          String assignedName = 'تعميم للجميع';
          if (!isBroadcast && body['assigned_to'] != null) {
            final eng = _demoUsers.firstWhere(
              (u) => u['id'] == body['assigned_to'],
              orElse: () => {'full_name': 'مهندس مخصص'},
            );
            assignedName = eng['full_name'];
          }

          final newTask = {
            'id': newId,
            'site_id': siteId,
            'site_name': siteName,
            'title': body['title'],
            'description': body['description'] ?? '',
            'assigned_to': isBroadcast ? null : body['assigned_to'],
            'assigned_to_name': assignedName,
            'is_broadcast': isBroadcast ? 1 : 0,
            'priority': body['priority'] ?? 'medium',
            'status': 'pending',
            'progress': 0,
            'created_at': 'اليوم',
          };
          _demoTasks.insert(0, newTask);
          return {'success': true, 'id': newId, 'message': 'تم حفظ خطة العمل بنجاح.'};
        }
        return {'success': true};

      case 'work-plan-cancel':
        if (body != null && body.containsKey('task_id')) {
          final tid = int.tryParse(body['task_id'].toString());
          final idx = _demoTasks.indexWhere((t) => t['id'] == tid);
          if (idx != -1) {
            _demoTasks[idx]['status'] = 'cancelled';
            return {'success': true, 'message': 'تم إلغاء خطة العمل بنجاح.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'خطة العمل غير موجودة');

      case 'work-plan-delete':
        if (body != null && body.containsKey('task_id')) {
          final tid = int.tryParse(body['task_id'].toString());
          final idx = _demoTasks.indexWhere((t) => t['id'] == tid);
          if (idx != -1) {
            _demoTasks.removeAt(idx);
            return {'success': true, 'message': 'تم حذف خطة العمل نهائياً.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'خطة العمل غير موجودة');

      case 'report-update':
        if (body != null && (body.containsKey('id') || body.containsKey('report_id'))) {
          final rid = int.tryParse((body['id'] ?? body['report_id']).toString());
          final idx = _demoReports.indexWhere((r) => r['id'] == rid);
          if (idx != -1) {
            _demoReports[idx] = {
              ..._demoReports[idx],
              if (body['work_done'] != null) 'work_done': body['work_done'],
              if (body['workers_count'] != null) 'workers_count': body['workers_count'],
              if (body['machinery_count'] != null) 'machinery_count': body['machinery_count'],
              if (body['progress_percent'] != null) 'progress_percent': body['progress_percent'],
              if (body['issues'] != null) 'issues': body['issues'],
              if (body['materials_used'] != null) 'materials_used': body['materials_used'],
              if (body['safety_notes'] != null) 'safety_notes': body['safety_notes'],
              if (body['admin_notes'] != null) 'admin_notes': body['admin_notes'],
              if (body['status'] != null) 'status': body['status'],
            };
            return {'success': true, 'message': 'تم تعديل بيانات التقرير بنجاح.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'التقرير غير موجود');

      case 'report-delete':
        if (body != null && body.containsKey('report_id')) {
          final rid = int.tryParse(body['report_id'].toString());
          final idx = _demoReports.indexWhere((r) => r['id'] == rid);
          if (idx != -1) {
            _demoReports.removeAt(idx);
            return {'success': true, 'message': 'تم حذف التقرير بنجاح.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'التقرير غير موجود');

      case 'report-review':
        if (body != null && body.containsKey('report_id')) {
          final rid = int.tryParse(body['report_id'].toString());
          final idx = _demoReports.indexWhere((r) => r['id'] == rid);
          if (idx != -1) {
            final currentRep = _demoReports[idx];
            if (currentRep['status'] == 'approved') {
              throw ApiException(
                statusCode: 409,
                message: 'لا يمكن تعديل أو إعادة مراجعة تقرير تم اعتماده مسبقاً.',
              );
            }
            final decision = body['decision']?.toString().toLowerCase();
            final adminNotes = body['admin_notes']?.toString();

            _demoReports[idx]['status'] = decision == 'approved' ? 'approved' : 'rejected';
            _demoReports[idx]['admin_notes'] = adminNotes;

            // إذا كان الاعتماد، نقوم بإنشاء قيد اليومية تلقائياً
            if (decision == 'approved') {
              final expTotal = (currentRep['expenses'] as List).fold<double>(
                0.0,
                (s, e) => s + ((e['quantity'] as num) * (e['unit_price'] as num)),
              );
              if (expTotal > 0) {
                _demoJournalEntries.insert(0, {
                  'id': _demoJournalEntries.length + 1,
                  'entry_number': 'JV-AUTO-${DateTime.now().millisecondsSinceEpoch}',
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'description': 'إثبات مصروفات التقرير المعتمد #${currentRep['id']}',
                  'total_amount': expTotal,
                  'is_posted': true,
                  'site_id': currentRep['site_id'],
                  'site_name': currentRep['site_name'],
                  'created_at': 'الآن',
                  'created_by': 'النظام (اعتماد التقرير)',
                  'lines': [
                    {
                      'account_id': 5010,
                      'account_name': 'مصروفات تشغيلية',
                      'account_code': '5010',
                      'debit': expTotal,
                      'credit': 0.0,
                      'description': 'مصروفات التقرير #${currentRep['id']}',
                    },
                    {
                      'account_id': 1010,
                      'account_name': 'الصندوق الرئيسي',
                      'account_code': '1010',
                      'debit': 0.0,
                      'credit': expTotal,
                      'description': 'صرف من الصندوق للمشروع',
                    },
                  ],
                });
              }
            }

            return {
              'success': true,
              'message': decision == 'approved'
                  ? 'تم اعتماد التقرير وإدراج قيود المصروفات بنجاح.'
                  : 'تم رفض التقرير وإعادته للمهندس مع الملاحظات.',
            };
          }
        }
        throw ApiException(statusCode: 404, message: 'التقرير غير موجود');

      case 'user-save':
        if (body != null) {
          final id = body['id'] != null ? int.tryParse(body['id'].toString()) : null;
          if (id != null && id > 0) {
            final idx = _demoUsers.indexWhere((u) => u['id'] == id);
            if (idx != -1) {
              _demoUsers[idx]['full_name'] = body['full_name'] ?? _demoUsers[idx]['full_name'];
              _demoUsers[idx]['email'] = body['email'] ?? _demoUsers[idx]['email'];
              _demoUsers[idx]['phone'] = body['phone'] ?? _demoUsers[idx]['phone'];
              _demoUsers[idx]['role'] = body['role'] ?? _demoUsers[idx]['role'];
              return {'success': true, 'message': 'تم تحديث بيانات المستخدم بنجاح.'};
            }
          } else {
            // التحقق من كلمة المرور 10 أحرف على الأقل
            final pass = body['password']?.toString() ?? '';
            if (pass.length < 10) {
              throw ApiException(
                statusCode: 422,
                message: 'كلمة المرور يجب أن لا تقل عن 10 أحرف وأرقام للأمان.',
              );
            }
            final newId = 100 + _demoUsers.length + 1;
            final newUser = {
              'id': newId,
              'username': body['username'],
              'full_name': body['full_name'],
              'role': body['role'] ?? 'engineer',
              'email': body['email'],
              'phone': body['phone'],
              'is_active': true,
              'status': 'active',
            };
            _demoUsers.add(newUser);
            return {'success': true, 'id': newId, 'message': 'تم إنشاء المستخدم بنجاح.'};
          }
        }
        return {'success': true};

      case 'user-status':
        if (body != null && body.containsKey('user_id')) {
          final uid = int.tryParse(body['user_id'].toString());
          if (uid == 1) {
            throw ApiException(
              statusCode: 403,
              message: 'غير مسموح بتعطيل حساب المدير العام الحالي!',
            );
          }
          final idx = _demoUsers.indexWhere((u) => u['id'] == uid);
          if (idx != -1) {
            final st = body['status']?.toString().toLowerCase() ?? 'active';
            _demoUsers[idx]['status'] = st;
            _demoUsers[idx]['is_active'] = (st == 'active');
            return {'success': true, 'message': 'تم تغيير حالة المستخدم بنجاح.'};
          }
        }
        throw ApiException(statusCode: 404, message: 'المستخدم غير موجود');

      case 'machinery-save':
        if (body != null) {
          final id = body['id'] != null ? int.tryParse(body['id'].toString()) : null;
          if (id != null && id > 0) {
            final idx = _demoMachinery.indexWhere((m) => m['id'] == id);
            if (idx != -1) {
              _demoMachinery[idx] = {..._demoMachinery[idx], ...body};
              return {'success': true, 'message': 'تم تحديث الآلية بنجاح.'};
            }
          }
          final newM = Map<String, dynamic>.from(body);
          newM['id'] = _demoMachinery.length + 1;
          _demoMachinery.add(newM);
          return {'success': true, 'id': newM['id'], 'message': 'تمت إضافة الآلية بنجاح.'};
        }
        return {'success': true};

      case 'machinery-status':
        if (body != null && body.containsKey('machinery_id')) {
          final mid = int.tryParse(body['machinery_id'].toString());
          final idx = _demoMachinery.indexWhere((m) => m['id'] == mid);
          if (idx != -1) {
            _demoMachinery[idx]['status'] = body['status'];
            return {'success': true, 'message': 'تم تحديث حالة تشغيل الآلية.'};
          }
        }
        return {'success': true};

      case 'warehouse-item-save':
        if (body != null) {
          final id = body['id'] != null ? int.tryParse(body['id'].toString()) : null;
          if (id != null && id > 0) {
            final idx = _demoWarehouseItems.indexWhere((i) => i['id'] == id);
            if (idx != -1) {
              _demoWarehouseItems[idx] = {..._demoWarehouseItems[idx], ...body};
              return {'success': true, 'message': 'تم تحديث الصنف المخزني.'};
            }
          }
          final newI = Map<String, dynamic>.from(body);
          newI['id'] = _demoWarehouseItems.length + 1;
          _demoWarehouseItems.add(newI);
          return {'success': true, 'id': newI['id'], 'message': 'تم حفظ الصنف بنجاح.'};
        }
        return {'success': true};

      case 'warehouse-category-save':
        if (body != null) {
          final newCat = {
            'id': _demoWarehouseCategories.length + 1,
            'name': body['name'],
            'description': body['description'],
          };
          _demoWarehouseCategories.add(newCat);
          return {'success': true, 'message': 'تم حفظ فئة المخزن.'};
        }
        return {'success': true};

      case 'warehouse-item-status':
        if (body != null && body.containsKey('item_id')) {
          final iid = int.tryParse(body['item_id'].toString());
          final idx = _demoWarehouseItems.indexWhere((i) => i['id'] == iid);
          if (idx != -1) {
            _demoWarehouseItems[idx]['status'] = body['status'];
            return {'success': true, 'message': 'تم تحديث حالة الصنف.'};
          }
        }
        return {'success': true};

      case 'warehouse-move-create':
        if (body != null) {
          final iid = int.tryParse(body['item_id'].toString()) ?? 0;
          final qty = double.tryParse(body['quantity'].toString()) ?? 0.0;
          final moveType = body['move_type']?.toString().toLowerCase() ?? 'out';

          final itemIdx = _demoWarehouseItems.indexWhere((i) => i['id'] == iid);
          if (itemIdx != -1) {
            double currentStock = (_demoWarehouseItems[itemIdx]['current_stock'] as num).toDouble();
            if (moveType == 'out' && currentStock < qty) {
              throw ApiException(
                statusCode: 422,
                message: 'الكمية المطلوبة للصرف أكبر من الرصيد المتوفر في المخزن ($currentStock)!',
              );
            }
            if (moveType == 'out') {
              _demoWarehouseItems[itemIdx]['current_stock'] = currentStock - qty;
            } else {
              _demoWarehouseItems[itemIdx]['current_stock'] = currentStock + qty;
            }

            final newMove = {
              'id': _demoWarehouseMoves.length + 1,
              'item_id': iid,
              'item_name': _demoWarehouseItems[itemIdx]['name'],
              'move_type': moveType,
              'quantity': qty,
              'site_id': body['site_id'],
              'site_name': body['site_id'] != null ? 'مشروع مكسلوند' : null,
              'notes': body['notes'],
              'created_at': 'الآن',
              'created_by': 'المدير العام',
            };
            _demoWarehouseMoves.insert(0, newMove);
            return {'success': true, 'message': 'تم تسجيل الحركة المخزنية بنجاح.'};
          }
        }
        return {'success': true};

      case 'repair-create':
        if (body != null) {
          final newR = Map<String, dynamic>.from(body);
          newR['id'] = _demoRepairs.length + 1;
          newR['status'] = 'pending';
          newR['created_at'] = 'اليوم';
          _demoRepairs.insert(0, newR);
          return {'success': true, 'id': newR['id'], 'message': 'تم إنشاء أمر الصيانة بنجاح.'};
        }
        return {'success': true};

      case 'repair-update':
      case 'repair-status':
        if (body != null && body.containsKey('repair_id')) {
          final rid = int.tryParse(body['repair_id'].toString());
          final idx = _demoRepairs.indexWhere((r) => r['id'] == rid);
          if (idx != -1) {
            _demoRepairs[idx] = {..._demoRepairs[idx], ...body};
            return {'success': true, 'message': 'تم تحديث سجل الصيانة.'};
          }
        }
        return {'success': true};

      case 'account-save':
        if (body != null) {
          final id = body['id'] != null ? int.tryParse(body['id'].toString()) : null;
          if (id != null && id > 0) {
            final idx = _demoAccounts.indexWhere((a) => a['id'] == id);
            if (idx != -1) {
              _demoAccounts[idx] = {..._demoAccounts[idx], ...body};
              return {'success': true, 'message': 'تم تحديث بيانات الحساب.'};
            }
          }
          final newA = Map<String, dynamic>.from(body);
          newA['id'] = int.tryParse(body['code']?.toString() ?? '') ?? (_demoAccounts.length + 100);
          newA['balance'] = 0.0;
          newA['has_journal_entries'] = false;
          _demoAccounts.add(newA);
          return {'success': true, 'message': 'تمت إضافة الحساب إلى دليل الحسابات.'};
        }
        return {'success': true};

      case 'account-delete':
        if (body != null && body.containsKey('account_id')) {
          final aid = int.tryParse(body['account_id'].toString());
          final acc = _demoAccounts.firstWhere(
            (a) => a['id'] == aid,
            orElse: () => throw ApiException(statusCode: 404, message: 'الحساب غير موجود'),
          );
          if (acc['has_journal_entries'] == true) {
            throw ApiException(
              statusCode: 409,
              message: 'لا يمكن حذف الحساب نظراً لارتباطه بقيود يومية سابقة!',
            );
          }
          _demoAccounts.removeWhere((a) => a['id'] == aid);
          return {'success': true, 'message': 'تم حذف الحساب بنجاح.'};
        }
        throw ApiException(statusCode: 400, message: 'مطلوب معرّف الحساب');

      case 'journal-create':
        if (body != null) {
          final lines = body['lines'] as List? ?? [];
          double totalDebit = 0;
          double totalCredit = 0;
          for (var l in lines) {
            totalDebit += double.tryParse(l['debit']?.toString() ?? '0') ?? 0;
            totalCredit += double.tryParse(l['credit']?.toString() ?? '0') ?? 0;
          }
          if ((totalDebit - totalCredit).abs() > 0.01) {
            throw ApiException(
              statusCode: 422,
              message: 'القيد غير متوازن! مجموع المدين ($totalDebit) يجب أن يتطابق مع مجموع الدائن ($totalCredit).',
            );
          }
          final newEntry = {
            'id': _demoJournalEntries.length + 1,
            'entry_number': 'JV-${DateTime.now().millisecondsSinceEpoch}',
            'date': body['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
            'description': body['description'],
            'total_amount': totalDebit,
            'is_posted': true,
            'site_id': body['site_id'],
            'lines': lines,
            'created_at': 'الآن',
            'created_by': 'المدير العام',
          };
          _demoJournalEntries.insert(0, newEntry);
          return {'success': true, 'message': 'تم ترحيل قيد اليومية بنجاح.'};
        }
        return {'success': true};

      case 'notification-read':
        if (body != null && body.containsKey('notification_id')) {
          final nid = int.tryParse(body['notification_id'].toString());
          final idx = _demoNotifications.indexWhere((n) => n['id'] == nid);
          if (idx != -1) {
            _demoNotifications[idx]['is_read'] = true;
          }
        }
        return {'success': true};

      case 'notification-read-all':
        for (var n in _demoNotifications) {
          n['is_read'] = true;
        }
        return {'success': true, 'message': 'تم تعيين جميع الإشعارات كمقروءة.'};

      default:
        return {'success': true};
    }
  }

  /// معالجة رفع الإيصال في الوضع التجريبي
  dynamic handleUploadReceipt(int reportId, String fileName) {
    return {
      'success': true,
      'message': 'تم رفع الإيصال ($fileName) للتقرير #$reportId بنجاح في الوضع التجريبي.',
    };
  }
}
