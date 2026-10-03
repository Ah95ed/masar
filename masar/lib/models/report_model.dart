import 'expense_model.dart';

/// مرفق إيصال المصروفات للتقرير
class ReceiptModel {
  final int? id;
  final String fileUrl;
  final String? fileName;
  final String? uploadedAt;
  final double? amount;

  ReceiptModel({
    this.id,
    required this.fileUrl,
    this.fileName,
    this.uploadedAt,
    this.amount,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      fileUrl: json['file_url']?.toString() ?? json['url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? json['name']?.toString(),
      uploadedAt: json['uploaded_at']?.toString() ?? json['created_at']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (amount != null) 'amount': amount,
    };
  }
}

/// نموذج التقرير اليومي المعروض في واجهة الإدارة للمراجعة والاعتماد
class ReportModel {
  final int? id;
  final int siteId;
  final String? siteName;
  final String reportDate; // YYYY-MM-DD
  final String? weather;
  final double? temperature;
  final int workersCount;
  final int machineryCount;
  final String workDone;
  final String? issues;
  final String? materialsUsed;
  final String? safetyNotes;
  final int progressPercent;
  final String status; // 'pending', 'pending_approval', 'approved', 'rejected'
  final int? engineerId;
  final String? engineerName;
  final String? createdAt;
  final String? adminNotes;
  final List<ExpenseModel> expenses;
  final List<ReceiptModel> receipts;

  ReportModel({
    this.id,
    required this.siteId,
    this.siteName,
    required this.reportDate,
    this.weather,
    this.temperature,
    required this.workersCount,
    required this.machineryCount,
    required this.workDone,
    this.issues,
    this.materialsUsed,
    this.safetyNotes,
    required this.progressPercent,
    this.status = 'pending_approval',
    this.engineerId,
    this.engineerName,
    this.createdAt,
    this.adminNotes,
    this.expenses = const [],
    this.receipts = const [],
  });

  bool get isApproved =>
      status.toLowerCase() == 'approved' ||
      status.toLowerCase() == 'معتمد' ||
      status.toLowerCase() == 'locked';

  bool get isRejected => status.toLowerCase() == 'rejected' || status.toLowerCase() == 'مرفوض';

  bool get isPending => !isApproved && !isRejected;

  double get totalExpenses =>
      expenses.fold(0.0, (acc, item) => acc + item.total);

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    List<ExpenseModel> parsedExpenses = [];
    if (json['expenses'] != null && json['expenses'] is List) {
      parsedExpenses = (json['expenses'] as List)
          .map((e) => ExpenseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<ReceiptModel> parsedReceipts = [];
    if (json['receipts'] != null && json['receipts'] is List) {
      parsedReceipts = (json['receipts'] as List)
          .map((e) => ReceiptModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return ReportModel(
      id: int.tryParse(json['id']?.toString() ?? json['report_id']?.toString() ?? ''),
      siteId: int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      reportDate: json['report_date']?.toString() ?? '',
      weather: json['weather']?.toString(),
      temperature: double.tryParse(json['temperature']?.toString() ?? ''),
      workersCount: int.tryParse(json['workers_count']?.toString() ?? '0') ?? 0,
      machineryCount: int.tryParse(json['machinery_count']?.toString() ?? '0') ?? 0,
      workDone: json['work_done']?.toString() ?? '',
      issues: json['issues']?.toString(),
      materialsUsed: json['materials_used']?.toString(),
      safetyNotes: json['safety_notes']?.toString(),
      progressPercent: int.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending_approval',
      engineerId: int.tryParse(json['engineer_id']?.toString() ?? ''),
      engineerName: json['engineer_name']?.toString() ?? json['engineer']?.toString(),
      createdAt: json['created_at']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      expenses: parsedExpenses,
      receipts: parsedReceipts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'site_id': siteId,
      'report_date': reportDate,
      if (weather != null && weather!.trim().isNotEmpty) 'weather': weather!.trim(),
      if (temperature != null) 'temperature': temperature,
      'workers_count': workersCount,
      'machinery_count': machineryCount,
      'work_done': workDone,
      if (issues != null && issues!.trim().isNotEmpty) 'issues': issues!.trim(),
      if (materialsUsed != null && materialsUsed!.trim().isNotEmpty)
        'materials_used': materialsUsed!.trim(),
      if (safetyNotes != null && safetyNotes!.trim().isNotEmpty)
        'safety_notes': safetyNotes!.trim(),
      'progress_percent': progressPercent,
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'receipts': receipts.map((r) => r.toJson()).toList(),
    };
  }
}
