import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';

class TaskHistoryScreen extends StatefulWidget {
  final int taskId;
  const TaskHistoryScreen({super.key, required this.taskId});

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await context.read<TaskProvider>().getHistory(widget.taskId);
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  IconData _changeIcon(String? type) {
    switch (type) {
      case 'task_created': return Icons.add_circle_outline;
      case 'title_changed': return Icons.edit;
      case 'description_changed': return Icons.description;
      case 'due_date_changed': return Icons.calendar_today;
      case 'priority_changed': return Icons.flag;
      case 'progress_changed': return Icons.trending_up;
      case 'status_changed': return Icons.swap_horiz;
      case 'assignee_changed': return Icons.person;
      default: return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('История изменений'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Нет записей в истории', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final h = _history[i];
                    final changeType = h['change_type'] as String? ?? '';
                    final displayText = h['display_text'] as String? ?? 'Изменение';
                    final changedAt = h['changed_at'] as String? ?? '';
                    final user = h['user'] as Map<String, dynamic>?;

                    String dateStr = '';
                    if (changedAt.isNotEmpty) {
                      final dt = DateTime.tryParse(changedAt);
                      if (dt != null) {
                        dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_changeIcon(changeType), color: AppColors.primary, size: 18),
                              ),
                              if (i < _history.length - 1)
                                Container(width: 2, height: 40, color: AppColors.divider),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayText, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (user != null) ...[
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            user['initials'] ?? '?',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(user['full_name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
