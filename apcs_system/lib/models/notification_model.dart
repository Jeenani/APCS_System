class NotificationModel {
  final int id;
  final String title;
  final String? body;
  final bool isRead;
  final String scheduledAt;
  final String createdAt;
  final String? sentAt;
  final NotificationTaskModel? task;
  final String? type;
  final NotificationPriorityModel? priority;

  NotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.isRead,
    required this.scheduledAt,
    required this.createdAt,
    this.sentAt,
    this.task,
    this.type,
    this.priority,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'],
      isRead: json['is_read'] ?? false,
      scheduledAt: json['scheduled_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      sentAt: json['sent_at'],
      task: json['task'] != null ? NotificationTaskModel.fromJson(json['task']) : null,
      type: json['type'],
      priority: json['priority'] != null ? NotificationPriorityModel.fromJson(json['priority']) : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      scheduledAt: scheduledAt,
      createdAt: createdAt,
      sentAt: sentAt,
      task: task,
      type: type,
      priority: priority,
    );
  }
}

class NotificationTaskModel {
  final int id;
  final String title;

  NotificationTaskModel({
    required this.id,
    required this.title,
  });

  factory NotificationTaskModel.fromJson(Map<String, dynamic> json) {
    return NotificationTaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class NotificationPriorityModel {
  final String name;
  final String? colorHex;

  NotificationPriorityModel({
    required this.name,
    this.colorHex,
  });

  factory NotificationPriorityModel.fromJson(Map<String, dynamic> json) {
    return NotificationPriorityModel(
      name: json['name'] ?? '',
      colorHex: json['color_hex'],
    );
  }
}
