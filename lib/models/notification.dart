class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? link;
  final int isRead;
  final String? createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.link,
    required this.isRead,
    this.createdAt,
  });

  bool get read => isRead == 1;

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    type: json['type']?.toString(),
    link: json['link']?.toString(),
    isRead: (json['is_read'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    if (type != null) 'type': type,
    if (link != null) 'link': link,
    'is_read': isRead,
  };
}