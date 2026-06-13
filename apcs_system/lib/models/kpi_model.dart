class KpiModel {
  final int id;
  final int taskId;
  final double score;
  final bool isConfirmed;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final KpiTaskModel? task;

  KpiModel({
    required this.id,
    required this.taskId,
    required this.score,
    required this.isConfirmed,
    this.confirmedAt,
    required this.createdAt,
    this.task,
  });

  factory KpiModel.fromJson(Map<String, dynamic> json) {
    return KpiModel(
      id: json['id'] ?? 0,
      taskId: json['task_id'] ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      isConfirmed: json['is_confirmed'] ?? false,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      task: json['task'] != null ? KpiTaskModel.fromJson(json['task']) : null,
    );
  }
}

class KpiTaskModel {
  final int id;
  final String title;
  final String? status;

  KpiTaskModel({
    required this.id,
    required this.title,
    this.status,
  });

  factory KpiTaskModel.fromJson(Map<String, dynamic> json) {
    return KpiTaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'],
    );
  }
}

class KpiSummary {
  final List<KpiModel> kpis;
  final double average;
  final int totalCount;

  KpiSummary({
    required this.kpis,
    required this.average,
    required this.totalCount,
  });

  factory KpiSummary.fromJson(Map<String, dynamic> json) {
    return KpiSummary(
      kpis: (json['kpis'] as List<dynamic>? ?? [])
          .map((e) => KpiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      totalCount: json['total_count'] ?? 0,
    );
  }
}
