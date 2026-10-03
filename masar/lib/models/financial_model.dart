/// نموذج الحساب المالي (دليل الحسابات)
class AccountModel {
  final int id;
  final String code;
  final String name;
  final String type; // asset (أصول), liability (خصوم), equity (حقوق الملكية), revenue (إيرادات), expense (مصروفات)
  final double balance;
  final String? description;
  final bool hasJournalEntries;

  AccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.description,
    this.hasJournalEntries = false,
  });

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'asset':
        return 'أصول';
      case 'liability':
        return 'خصوم';
      case 'equity':
        return 'حقوق ملكية';
      case 'revenue':
        return 'إيرادات';
      case 'expense':
        return 'مصروفات';
      default:
        return type;
    }
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: int.tryParse(json['id']?.toString() ?? json['account_id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'حساب بدون اسم',
      type: json['type']?.toString().toLowerCase() ?? 'expense',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString(),
      hasJournalEntries: json['has_journal_entries'] == true ||
          json['has_journal_entries'] == 1 ||
          json['has_journal_entries'] == '1' ||
          (int.tryParse(json['entries_count']?.toString() ?? '0') ?? 0) > 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'code': code,
      'name': name,
      'type': type,
      if (description != null) 'description': description,
    };
  }
}

/// سطر طرف قيد اليومية (مدين أو دائن)
class JournalLineModel {
  final int? id;
  final int accountId;
  final String? accountName;
  final String? accountCode;
  final double debit; // مدين
  final double credit; // دائن
  final String? description;

  JournalLineModel({
    this.id,
    required this.accountId,
    this.accountName,
    this.accountCode,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });

  factory JournalLineModel.fromJson(Map<String, dynamic> json) {
    return JournalLineModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      accountId: int.tryParse(json['account_id']?.toString() ?? '0') ?? 0,
      accountName: json['account_name']?.toString() ?? json['account']?.toString(),
      accountCode: json['account_code']?.toString(),
      debit: double.tryParse(json['debit']?.toString() ?? '0') ?? 0.0,
      credit: double.tryParse(json['credit']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'debit': debit,
      'credit': credit,
      if (description != null) 'description': description,
    };
  }
}

/// نموذج قيد اليومية
class JournalEntryModel {
  final int id;
  final String entryNumber;
  final String date;
  final String description;
  final double totalAmount;
  final bool isPosted;
  final int? siteId;
  final String? siteName;
  final List<JournalLineModel> lines;
  final String? createdAt;
  final String? createdBy;

  JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.date,
    required this.description,
    this.totalAmount = 0.0,
    this.isPosted = true,
    this.siteId,
    this.siteName,
    this.lines = const [],
    this.createdAt,
    this.createdBy,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    List<JournalLineModel> parsedLines = [];
    if (json['lines'] != null && json['lines'] is List) {
      parsedLines = (json['lines'] as List)
          .map((l) => JournalLineModel.fromJson(Map<String, dynamic>.from(l)))
          .toList();
    }

    return JournalEntryModel(
      id: int.tryParse(json['id']?.toString() ?? json['entry_id']?.toString() ?? '0') ?? 0,
      entryNumber: json['entry_number']?.toString() ?? json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? json['entry_date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? json['amount']?.toString() ?? '0') ?? 0.0,
      isPosted: json['is_posted'] != false && json['is_posted'] != 0 && json['status'] != 'draft',
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      lines: parsedLines,
      createdAt: json['created_at']?.toString(),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'date': date,
      'description': description,
      if (siteId != null) 'site_id': siteId,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }
}

/// الملخص المالي
class FinancialSummaryModel {
  final double totalRevenues;
  final double totalExpenses;
  final double netProfit;
  final double totalAssets;
  final double totalLiabilities;
  final int totalEntriesCount;

  FinancialSummaryModel({
    this.totalRevenues = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalAssets = 0.0,
    this.totalLiabilities = 0.0,
    this.totalEntriesCount = 0,
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    double parse(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;
    int parseInt(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;

    return FinancialSummaryModel(
      totalRevenues: parse(json['total_revenues'] ?? json['revenues']),
      totalExpenses: parse(json['total_expenses'] ?? json['expenses']),
      netProfit: parse(json['net_profit'] ?? json['profit']),
      totalAssets: parse(json['total_assets'] ?? json['assets']),
      totalLiabilities: parse(json['total_liabilities'] ?? json['liabilities']),
      totalEntriesCount: parseInt(json['total_entries_count'] ?? json['entries_count']),
    );
  }
}
