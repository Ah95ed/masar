class ReportExpense {
  final int id;
  final String itemName;
  final String category;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? notes;

  ReportExpense({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.notes,
  });

  factory ReportExpense.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ReportExpense(
      id: parseInt(json['id']),
      itemName: json['item_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      quantity: parseDouble(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      total: parseDouble(json['total']),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_name': itemName,
    'category': category,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total': total,
    if (notes != null) 'notes': notes,
  };
}

class ReportReceipt {
  final int id;
  final String filePath;
  final String originalName;
  final String? fileType;
  final int? fileSize;

  ReportReceipt({
    required this.id,
    required this.filePath,
    required this.originalName,
    this.fileType,
    this.fileSize,
  });

  factory ReportReceipt.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return ReportReceipt(
      id: parseInt(json['id']),
      filePath: json['file_path']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? '',
      fileType: json['file_type']?.toString(),
      fileSize: json['file_size'] != null ? parseInt(json['file_size']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_path': filePath,
    'original_name': originalName,
    if (fileType != null) 'file_type': fileType,
    if (fileSize != null) 'file_size': fileSize,
  };
}

class Report {
  final int id;
  final int siteId;
  final String? siteName;
  final int engineerId;
  final String? engineerName;
  final String reportDate;
  final String? weather;
  final double? temperature;
  final int workersCount;
  final int machineryCount;
  final String workDone;
  final String? issues;
  final String? materialsUsed;
  final String? safetyNotes;
  final int progressPercent;
  final String status; // submitted, approved, rejected
  final String? adminNotes;
  final List<ReportExpense> expenses;
  final List<ReportReceipt> receipts;
  final String? createdAt;

  Report({
    required this.id,
    required this.siteId,
    this.siteName,
    required this.engineerId,
    this.engineerName,
    required this.reportDate,
    this.weather,
    this.temperature,
    this.workersCount = 0,
    this.machineryCount = 0,
    required this.workDone,
    this.issues,
    this.materialsUsed,
    this.safetyNotes,
    this.progressPercent = 0,
    required this.status,
    this.adminNotes,
    this.expenses = const [],
    this.receipts = const [],
    this.createdAt,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isSubmitted => status.toLowerCase() == 'submitted' || status.toLowerCase() == 'pending';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'submitted':
      case 'pending':
      default:
        return 'بانتظار المراجعة';
    }
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double? parseDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    var rawExpenses = json['expenses'];
    List<ReportExpense> expList = [];
    if (rawExpenses is List) {
      expList = rawExpenses.map((e) => ReportExpense.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    var rawReceipts = json['receipts'];
    List<ReportReceipt> recList = [];
    if (rawReceipts is List) {
      recList = rawReceipts.map((e) => ReportReceipt.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return Report(
      id: parseInt(json['id']),
      siteId: parseInt(json['site_id']),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      engineerId: parseInt(json['engineer_id']),
      engineerName: json['engineer_name']?.toString() ?? json['full_name']?.toString(),
      reportDate: json['report_date']?.toString() ?? '',
      weather: json['weather']?.toString(),
      temperature: parseDoubleOrNull(json['temperature']),
      workersCount: parseInt(json['workers_count']),
      machineryCount: parseInt(json['machinery_count']),
      workDone: json['work_done']?.toString() ?? '',
      issues: json['issues']?.toString(),
      materialsUsed: json['materials_used']?.toString(),
      safetyNotes: json['safety_notes']?.toString(),
      progressPercent: parseInt(json['progress_percent'], parseInt(json['progress'])),
      status: json['status']?.toString().toLowerCase() ?? 'submitted',
      adminNotes: json['admin_notes']?.toString(),
      expenses: expList,
      receipts: recList,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'site_id': siteId,
    'report_date': reportDate,
    'status': status,
    'admin_notes': adminNotes,
  };
}
