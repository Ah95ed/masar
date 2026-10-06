class RepairPart {
  final int id;
  final String partName;
  final double quantity;
  final double unitPrice;

  RepairPart({
    required this.id,
    required this.partName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory RepairPart.fromJson(Map<String, dynamic> json) => RepairPart(
    id: (json['id'] as num?)?.toInt() ?? 0,
    partName: json['part_name']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'part_name': partName,
    'quantity': quantity,
    'unit_price': unitPrice,
  };
}

class Repair {
  final int id;
  final int machineryId;
  final String? machineryName;
  final String title;
  final String? description;
  final String problemType;
  final String priority;
  final String status;
  final String? technicianName;
  final String? workshop;
  final double laborCost;
  final double partsCost;
  final double totalCost;
  final List<RepairPart> parts;
  final String? createdAt;

  Repair({
    required this.id,
    required this.machineryId,
    this.machineryName,
    required this.title,
    this.description,
    required this.problemType,
    required this.priority,
    required this.status,
    this.technicianName,
    this.workshop,
    this.laborCost = 0.0,
    this.partsCost = 0.0,
    this.totalCost = 0.0,
    this.parts = const [],
    this.createdAt,
  });

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'in_progress':
        return 'قيد الإصلاح';
      case 'pending':
      default:
        return 'بانتظار الصيانة';
    }
  }

  factory Repair.fromJson(Map<String, dynamic> json) {
    var rawParts = json['parts'];
    List<RepairPart> partsList = [];
    if (rawParts is List) {
      partsList = rawParts.map((e) => RepairPart.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return Repair(
      id: (json['id'] as num?)?.toInt() ?? 0,
      machineryId: (json['machinery_id'] as num?)?.toInt() ?? 0,
      machineryName: json['machinery_name']?.toString() ?? json['machinery']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      problemType: json['problem_type']?.toString() ?? 'mechanical',
      priority: json['priority']?.toString().toLowerCase() ?? 'medium',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      technicianName: json['technician_name']?.toString(),
      workshop: json['workshop']?.toString(),
      laborCost: (json['labor_cost'] as num?)?.toDouble() ?? 0.0,
      partsCost: (json['parts_cost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      parts: partsList,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'machinery_id': machineryId,
    'title': title,
    'status': status,
  };
}