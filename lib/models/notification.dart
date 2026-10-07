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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    int parseRead(dynamic v) {
      if (v == null) return 0;
      if (v == true || v == 1 || v == '1') return 1;
      return 0;
    }

    return NotificationItem(
      id: parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      link: json['link']?.toString(),
      isRead: parseRead(json['is_read']),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    if (type != null) 'type': type,
    if (link != null) 'link': link,
    'is_read': isRead,
  };
}
