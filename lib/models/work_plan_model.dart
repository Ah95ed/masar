/// نموذج خطة العمل / المهمة
class WorkPlanModel {
  final int id;
  final int siteId;
  final String? siteName;
  final String title;
  final String? description;
  final int? assignedTo;
  final String? assignedToName;
  final bool isBroadcast;
  final String priority; // low, medium, high, urgent
  final String status; // pending, in_progress, completed, cancelled
  final int progress;
  final String? createdAt;

  WorkPlanModel({
    required this.id,
    required this.siteId,
    this.siteName,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedToName,
    this.isBroadcast = false,
    this.priority = 'medium',
    this.status = 'pending',
    this.progress = 0,
    this.createdAt,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isCompleted => status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';

  factory WorkPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkPlanModel(
      id: int.tryParse(json['id']?.toString() ?? json['task_id']?.toString() ?? '0') ?? 0,
      siteId: int.tryParse(json['site_id']?.toString() ?? '0') ?? 0,
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      title: json['title']?.toString() ?? 'خطة بدون عنوان',
      description: json['description']?.toString(),
      assignedTo: int.tryParse(json['assigned_to']?.toString() ?? json['engineer_id']?.toString() ?? ''),
      assignedToName: json['assigned_to_name']?.toString() ?? json['engineer_name']?.toString(),
      isBroadcast: json['is_broadcast'] == true || json['is_broadcast'] == 1 || json['is_broadcast'] == '1',
      priority: json['priority']?.toString().toLowerCase() ?? 'medium',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      progress: int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toSaveJson() {
    return {
      'site_id': siteId,
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (assignedTo != null && !isBroadcast) 'assigned_to': assignedTo,
      'is_broadcast': isBroadcast ? 1 : 0,
      'priority': priority,
    };
  }
}

// التوافق مع الاسم القديم
typedef TaskModel = WorkPlanModel;
