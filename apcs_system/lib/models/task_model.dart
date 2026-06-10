class TaskModel {
  final int id;
  final String title;
  final String? description;
  final String dueDate;
  final int progress;
  final String createdAt;
  final String updatedAt;
  final PriorityModel? priority;
  final StatusModel? status;
  final CategoryModel? category;
  final CreatorModel? creator;
  final CreatorModel? assignee;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.priority,
    this.status,
    this.category,
    this.creator,
    this.assignee,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['due_date'] ?? '',
      progress: json['progress'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      priority: json['priority'] != null
          ? PriorityModel.fromJson(json['priority'])
          : null,
      status: json['status'] != null
          ? StatusModel.fromJson(json['status'])
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      creator: json['creator'] != null
          ? CreatorModel.fromJson(json['creator'])
          : null,
      assignee: json['assignee'] != null
          ? CreatorModel.fromJson(json['assignee'])
          : null,
    );
  }
}

class PriorityModel {
  final int id;
  final String name;
  final String colorHex;

  PriorityModel({required this.id, required this.name, required this.colorHex});

  factory PriorityModel.fromJson(Map<String, dynamic> json) {
    return PriorityModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      colorHex: json['color_hex'] ?? '#999999',
    );
  }

  String get label {
    switch (name) {
      case 'high':
        return 'Высокий';
      case 'medium':
        return 'Средний';
      case 'low':
        return 'Низкий';
      default:
        return name;
    }
  }
}

class StatusModel {
  final int id;
  final String code;
  final bool isTerminal;

  StatusModel({required this.id, required this.code, required this.isTerminal});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      isTerminal: json['is_terminal'] ?? false,
    );
  }

  String get label {
    switch (code) {
      case 'new':
        return 'Новая';
      case 'in_progress':
        return 'В процессе';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      default:
        return code;
    }
  }
}

class CategoryModel {
  final int id;
  final String name;
  final String iconIdentifier;
  final String? description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconIdentifier,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconIdentifier: json['icon_identifier'] ?? '',
      description: json['description'],
    );
  }
}

class CreatorModel {
  final int id;
  final String fullName;
  final String initials;

  CreatorModel({required this.id, required this.fullName, required this.initials});

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      initials: json['initials'] ?? '',
    );
  }
}
