class Task {
  final int id;
  final int siteId;
  final String? siteName;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assignedToName;
  final bool isBroadcast;
  final String priority;
  final String status;
  final int progress;
  final String? createdAt;
  final int workersCount;
  final int machineryCount;
  final double? temperature;
  final String? weather;
  final String? note;
  final String? updatedByName;

  Task({
    required this.id,
    required this.siteId,
    this.siteName,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    this.isBroadcast = false,
    required this.priority,
    required this.status,
    this.progress = 0,
    this.createdAt,
    this.workersCount = 0,
    this.machineryCount = 0,
    this.temperature,
    this.weather,
    this.note,
    this.updatedByName,
  });

  String get engineerName => (updatedByName != null && updatedByName!.trim().isNotEmpty)
      ? updatedByName!
      : ((assignedToName != null && assignedToName!.trim().isNotEmpty)
          ? assignedToName!
          : (isBroadcast ? 'مهندسو الموقع' : 'مهندس غير محدد'));

  String get effectiveNote => (note != null && note!.trim().isNotEmpty)
      ? note!
      : ((description != null && description!.trim().isNotEmpty) ? description! : '-');

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'عاجلة جداً';
      case 'high':
        return 'عالية';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      default:
        return priority;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'review':
        return 'قيد المراجعة';
      case 'done':
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      case 'pending':
      default:
        return 'قيد الانتظار';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
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

    return Task(
      id: parseInt(json['id']),
      siteId: parseInt(json['site_id']),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      assignedTo: json['assigned_to'] != null ? parseInt(json['assigned_to']) : null,
      assignedToName: json['assigned_to_name']?.toString() ?? json['engineer_name']?.toString(),
      isBroadcast: json['is_broadcast'] == true || json['is_broadcast'] == 1 || json['is_broadcast'] == '1',
      priority: json['priority']?.toString().toLowerCase() ?? 'medium',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      progress: parseInt(json['progress'], 0),
      createdAt: json['created_at']?.toString(),
      workersCount: parseInt(json['workers_count'] ?? json['workers'], 0),
      machineryCount: parseInt(json['machinery_count'] ?? json['machinery'], 0),
      temperature: parseDoubleOrNull(json['temperature']),
      weather: json['weather']?.toString(),
      note: json['note']?.toString() ?? json['engineer_notes']?.toString() ?? json['notes']?.toString(),
      updatedByName: json['updated_by_name']?.toString() ?? json['engineer_name']?.toString() ?? json['full_name']?.toString(),
    );
  }

  Task copyWith({
    int? id,
    int? siteId,
    String? siteName,
    String? title,
    String? description,
    int? assignedTo,
    String? assignedToName,
    bool? isBroadcast,
    String? priority,
    String? status,
    int? progress,
    String? createdAt,
    int? workersCount,
    int? machineryCount,
    double? temperature,
    String? weather,
    String? note,
    String? updatedByName,
  }) {
    return Task(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      workersCount: workersCount ?? this.workersCount,
      machineryCount: machineryCount ?? this.machineryCount,
      temperature: temperature ?? this.temperature,
      weather: weather ?? this.weather,
      note: note ?? this.note,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'site_id': siteId,
    'title': title,
    if (description != null) 'description': description,
    if (assignedTo != null) 'assigned_to': assignedTo,
    'is_broadcast': isBroadcast,
    'priority': priority,
    'status': status,
    'progress': progress,
    'workers_count': workersCount,
    'machinery_count': machineryCount,
    if (temperature != null) 'temperature': temperature,
    if (weather != null) 'weather': weather,
    if (note != null) 'note': note,
    if (updatedByName != null) 'updated_by_name': updatedByName,
  };
}
