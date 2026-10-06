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
  });

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

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: (json['id'] as num?)?.toInt() ?? 0,
    siteId: (json['site_id'] as num?)?.toInt() ?? 0,
    siteName: json['site_name']?.toString() ?? json['site']?.toString(),
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString(),
    assignedTo: (json['assigned_to'] as num?)?.toInt(),
    assignedToName: json['assigned_to_name']?.toString() ?? json['engineer_name']?.toString(),
    isBroadcast: json['is_broadcast'] == true || json['is_broadcast'] == 1 || json['is_broadcast'] == '1',
    priority: json['priority']?.toString().toLowerCase() ?? 'medium',
    status: json['status']?.toString().toLowerCase() ?? 'pending',
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at']?.toString(),
  );

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
  };
}