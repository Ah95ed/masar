/// نموذج موقع العمل / المشروع الإنشائي للمدير
class SiteModel {
  final int id;
  final String name;
  final String? clientName;
  final String? workDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final double? budget;
  final String status; // active, completed, cancelled, halted
  final int? managerId;
  final String? description;
  final int? progress;

  SiteModel({
    required this.id,
    required this.name,
    this.clientName,
    this.workDate,
    this.startTime,
    this.endTime,
    this.location,
    this.budget,
    required this.status,
    this.managerId,
    this.description,
    this.progress,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isActive => status.toLowerCase() == 'active';

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: int.tryParse(json['id']?.toString() ?? json['site_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'موقع بدون اسم',
      clientName: json['client_name']?.toString(),
      workDate: json['work_date']?.toString() ?? json['start_date']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      location: json['location']?.toString() ?? json['address']?.toString(),
      budget: double.tryParse(json['budget']?.toString() ?? ''),
      status: json['status']?.toString().toLowerCase() ?? 'active',
      managerId: int.tryParse(json['manager_id']?.toString() ?? ''),
      description: json['description']?.toString(),
      progress: int.tryParse(json['progress']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      if (clientName != null) 'client_name': clientName,
      if (workDate != null) 'work_date': workDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (location != null) 'location': location,
      if (budget != null) 'budget': budget,
      'status': status,
      if (managerId != null) 'manager_id': managerId,
      if (description != null) 'description': description,
    };
  }
}
