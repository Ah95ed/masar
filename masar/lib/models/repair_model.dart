/// نموذج عملية صيانة / إصلاح آلية
class RepairModel {
  final int id;
  final int machineryId;
  final String? machineryName;
  final String? machineryCode;
  final String issueDescription;
  final String? actionTaken;
  final double cost;
  final String status; // pending, in_progress, completed, cancelled
  final String? workshopName;
  final String? startDate;
  final String? completedDate;
  final String? notes;
  final String? createdAt;

  RepairModel({
    required this.id,
    required this.machineryId,
    this.machineryName,
    this.machineryCode,
    required this.issueDescription,
    this.actionTaken,
    this.cost = 0.0,
    this.status = 'pending',
    this.workshopName,
    this.startDate,
    this.completedDate,
    this.notes,
    this.createdAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'قيد الإصلاح';
      case 'completed':
        return 'تم الإصلاح';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  factory RepairModel.fromJson(Map<String, dynamic> json) {
    return RepairModel(
      id: int.tryParse(json['id']?.toString() ?? json['repair_id']?.toString() ?? '0') ?? 0,
      machineryId: int.tryParse(json['machinery_id']?.toString() ?? '0') ?? 0,
      machineryName: json['machinery_name']?.toString() ?? json['machinery']?.toString(),
      machineryCode: json['machinery_code']?.toString(),
      issueDescription: json['issue_description']?.toString() ?? json['description']?.toString() ?? '',
      actionTaken: json['action_taken']?.toString(),
      cost: double.tryParse(json['cost']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      workshopName: json['workshop_name']?.toString() ?? json['workshop']?.toString(),
      startDate: json['start_date']?.toString(),
      completedDate: json['completed_date']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'machinery_id': machineryId,
      'issue_description': issueDescription,
      if (actionTaken != null) 'action_taken': actionTaken,
      'cost': cost,
      'status': status,
      if (workshopName != null) 'workshop_name': workshopName,
      if (startDate != null) 'start_date': startDate,
      if (completedDate != null) 'completed_date': completedDate,
      if (notes != null) 'notes': notes,
    };
  }
}
