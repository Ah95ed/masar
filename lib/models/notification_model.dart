/// نموذج إشعار المستخدم
class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;
  final String? type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.type,
  });

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    bool? isRead,
    String? createdAt,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawIsRead = json['is_read'];
    final bool parsedIsRead = rawIsRead == true ||
        rawIsRead == 1 ||
        rawIsRead == '1' ||
        rawIsRead == 'true';

    return NotificationModel(
      id: int.tryParse(json['id']?.toString() ?? json['notification_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'إشعار جديد',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      isRead: parsedIsRead,
      createdAt: json['created_at']?.toString() ?? json['date']?.toString(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt,
      'type': type,
    };
  }
}
