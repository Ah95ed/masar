class Account {
  final int id;
  final String code;
  final String name;
  final String type; // asset, liability, equity, revenue, expense
  final int? parentId;
  final String? parentName;
  final double balance;
  final int isActive;

  Account({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.parentName,
    this.balance = 0.0,
    required this.isActive,
  });

  bool get active => isActive == 1;

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

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: (json['id'] as num?)?.toInt() ?? 0,
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString().toLowerCase() ?? 'asset',
    parentId: (json['parent_id'] as num?)?.toInt(),
    parentName: json['parent_name']?.toString(),
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    isActive: (json['is_active'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type,
    if (parentId != null) 'parent_id': parentId,
    'is_active': isActive,
  };
}
