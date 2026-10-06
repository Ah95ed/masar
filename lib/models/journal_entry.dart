class JournalLine {
  final int id;
  final int accountId;
  final String? accountCode;
  final String? accountName;
  final double debit;
  final double credit;
  final String? description;

  JournalLine({
    required this.id,
    required this.accountId,
    this.accountCode,
    this.accountName,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) => JournalLine(
    id: (json['id'] as num?)?.toInt() ?? 0,
    accountId: (json['account_id'] as num?)?.toInt() ?? 0,
    accountCode: json['account_code']?.toString(),
    accountName: json['account_name']?.toString(),
    debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
    credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
    description: json['description']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'account_id': accountId,
    'debit': debit,
    'credit': credit,
    if (description != null) 'description': description,
  };
}

class JournalEntry {
  final int id;
  final String entryNumber;
  final String entryDate;
  final String description;
  final int? siteId;
  final String? siteName;
  final double totalDebit;
  final double totalCredit;
  final String status;
  final List<JournalLine> lines;

  JournalEntry({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    required this.description,
    this.siteId,
    this.siteName,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    required this.status,
    this.lines = const [],
  });

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    var rawLines = json['lines'];
    List<JournalLine> parsedLines = [];
    if (rawLines is List) {
      parsedLines = rawLines.map((e) => JournalLine.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return JournalEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      entryNumber: json['entry_number']?.toString() ?? '',
      entryDate: json['entry_date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      siteId: (json['site_id'] as num?)?.toInt(),
      siteName: json['site_name']?.toString(),
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'posted',
      lines: parsedLines,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entry_number': entryNumber,
    'entry_date': entryDate,
    'description': description,
    if (siteId != null) 'site_id': siteId,
    'total_debit': totalDebit,
    'total_credit': totalCredit,
    'status': status,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}