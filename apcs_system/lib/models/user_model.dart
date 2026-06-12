class UserModel {
  final int id;
  final String login;
  final String fullName;
  final String initials;
  final String role;
  final String avatarColor;

  UserModel({
    required this.id,
    required this.login,
    required this.fullName,
    required this.initials,
    required this.role,
    required this.avatarColor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      login: json['login'] ?? '',
      fullName: json['full_name'] ?? '',
      initials: json['initials'] ?? '',
      role: json['role'] ?? '',
      avatarColor: json['avatar_color'] ?? '#1565C0',
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Администратор системы';
      case 'chief_engineer':
        return 'Главный инженер';
      case 'asutp_chief':
        return 'Начальник службы АСУТП';
      case 'engineer':
        return 'Инженер АСУТП';
      case 'operator':
        return 'Оператор';
      default:
        return role;
    }
  }

  /// Может создавать/редактировать задачи и менять прогресс
  bool get canManageTasks =>
      role == 'admin' || role == 'chief_engineer' || role == 'asutp_chief';

  /// Может экспортировать CSV
  bool get canExport =>
      role == 'admin' || role == 'chief_engineer' || role == 'asutp_chief';

  /// Может одобрять/отклонять назначения исполнителей
  bool get canApproveAssignees =>
      role == 'admin' || role == 'chief_engineer';

  /// Администратор системы
  bool get isAdmin => role == 'admin';
}
