class Site {
  final int id;
  final String code;
  final String name;
  final String clientName;
  final String? workDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final double budget;
  final String status;
  final int? managerId;
  final String? description;

  Site({
    required this.id,
    required this.code,
    required this.name,
    required this.clientName,
    this.workDate,
    this.startTime,
    this.endTime,
    this.location,
    this.budget = 0.0,
    required this.status,
    this.managerId,
    this.description,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'planning':
        return 'قيد التخطيط';
      case 'paused':
        return 'متوقف مؤقتاً';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: (json['id'] as num?)?.toInt() ?? 0,
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    clientName: json['client_name']?.toString() ?? '',
    workDate: json['work_date']?.toString(),
    startTime: json['start_time']?.toString(),
    endTime: json['end_time']?.toString(),
    location: json['location']?.toString(),
    budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
    status: json['status']?.toString().toLowerCase() ?? 'active',
    managerId: (json['manager_id'] as num?)?.toInt(),
    description: json['description']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'client_name': clientName,
    if (workDate != null) 'work_date': workDate,
    if (startTime != null) 'start_time': startTime,
    if (endTime != null) 'end_time': endTime,
    if (location != null) 'location': location,
    'budget': budget,
    'status': status,
    if (managerId != null) 'manager_id': managerId,
    if (description != null) 'description': description,
  };
}