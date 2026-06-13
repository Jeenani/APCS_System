import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskModel? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final task = await context.read<TaskProvider>().getTask(widget.taskId);
    setState(() {
      _task = task;
      _loading = false;
    });
  }

  Color _priorityColor(String? name) {
    switch (name) {
      case 'high': return AppColors.priorityHigh;
      case 'medium': return AppColors.priorityMedium;
      case 'low': return AppColors.priorityLow;
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String? iconId) {
    switch (iconId) {
      case 'icon_sensor': return Icons.speed;
      case 'icon_plc': return Icons.memory;
      case 'icon_hmi': return Icons.monitor;
      case 'icon_valve': return Icons.toggle_on;
      case 'icon_pump': return Icons.water_drop;
      case 'icon_level': return Icons.straighten;
      case 'icon_plc_rack': return Icons.dns;
      case 'icon_scada': return Icons.dashboard;
      case 'icon_equipment': return Icons.build;
      default: return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Детали задачи'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_task != null)
            Builder(builder: (context) {
              final user = context.watch<AuthProvider>().user;
              final canEdit = user != null && (
                user.role == 'admin' ||
                user.role == 'chief_engineer' ||
                (user.role == 'asutp_chief' && _task!.creator?.id == user.id)
              );
              if (!canEdit) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/edit-task', arguments: _task);
                  _loadTask();
                },
              );
            }),
          if (_task != null && (context.watch<AuthProvider>().user?.canApproveAssignees ?? false))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Удалить задачу?'),
                    content: const Text('Это действие нельзя отменить'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await context.read<TaskProvider>().deleteTask(_task!.id);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
              ? const Center(child: Text('Задача не найдена'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + category
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_categoryIcon(_task!.category?.iconIdentifier), color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_task!.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      if (_task!.category != null)
                                        Text(_task!.category!.name, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status & Priority
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              label: 'Статус',
                              value: _task!.status?.label ?? '',
                              icon: Icons.flag_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              label: 'Приоритет',
                              value: _task!.priority?.label ?? '',
                              icon: Icons.priority_high,
                              valueColor: _priorityColor(_task!.priority?.name),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Due date & Progress
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              label: 'Срок выполнения',
                              value: _task!.dueDate,
                              icon: Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoCard(
                              label: 'Прогресс',
                              value: '${_task!.progress}%',
                              icon: Icons.trending_up,
                              valueColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Выполнение', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('${_task!.progress}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _task!.progress / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(_priorityColor(_task!.priority?.name)),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      if (_task!.description != null && _task!.description!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Описание', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Text(_task!.description!, style: TextStyle(color: Colors.grey[700], height: 1.5)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Assignees
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Исполнители', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            if (_task!.assignees.isEmpty)
                              Text('Не назначены', style: TextStyle(color: Colors.grey[600]))
                            else
                              ..._task!.assignees.map((ta) {
                                final canApprove = context.read<AuthProvider>().user?.canApproveAssignees ?? false;
                                final isPending = ta.status == 'pending';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isPending
                                            ? Colors.orange
                                            : ta.status == 'approved'
                                                ? Colors.green
                                                : Colors.red,
                                        child: Text(
                                          ta.user?.initials ?? '?',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ta.user?.fullName ?? 'Неизвестно',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                            ),
                                            Text(
                                              ta.statusLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPending
                                                    ? Colors.orange[700]
                                                    : ta.status == 'approved'
                                                        ? Colors.green[700]
                                                        : Colors.red[700],
                                              ),
                                            ),
                                            if (ta.proposedBy != null)
                                              Text(
                                                'Предложил: ${ta.proposedBy!.fullName}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (canApprove && isPending) ...[
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          tooltip: 'Одобрить',
                                          onPressed: () async {
                                            final ok = await context.read<TaskProvider>().approveAssignee(_task!.id, ta.id);
                                            if (ok && mounted) _loadTask();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                          tooltip: 'Отклонить',
                                          onPressed: () async {
                                            final ok = await context.read<TaskProvider>().rejectAssignee(_task!.id, ta.id);
                                            if (ok && mounted) _loadTask();
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Parent task link
                      if (_task!.parentId != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Родительская задача', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => Navigator.pushReplacementNamed(context, '/task-detail', arguments: _task!.parentId),
                                child: Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _task!.parentId.toString(),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_task!.parentId != null) const SizedBox(height: 12),

                      // Subtasks
                      if (_task!.children.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Подзадачи (${_task!.children.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._task!.children.map((child) {
                                return InkWell(
                                  onTap: () => Navigator.pushNamed(context, '/task-detail', arguments: child.id),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${child.progress}%',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(child.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                              Text(
                                                child.status?.label ?? '',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      if (_task!.children.isNotEmpty) const SizedBox(height: 12),

                      // Create subtask button (only for top-level tasks, not subtasks)
                      if (_task!.parentId == null && (context.watch<AuthProvider>().user?.canCreateSubtasks ?? false))
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/create-task', arguments: _task!.id);
                              _loadTask();
                            },
                            icon: const Icon(Icons.add_task),
                            label: const Text('Создать подзадачу'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (_task!.parentId == null && (context.watch<AuthProvider>().user?.canCreateSubtasks ?? false)) const SizedBox(height: 12),

                      // Mark as completed button (operator, asutp_chief, admin)
                      if (_task!.status?.code != 'completed' && ['admin', 'asutp_chief', 'operator'].contains(context.watch<AuthProvider>().user?.role))
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Отметить выполненной?'),
                                  content: const Text('Задача будет переведена в статус "Выполнена"'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Отметить')),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                final success = await context.read<TaskProvider>().completeTask(_task!.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Задача отмечена выполненной' : 'Ошибка: ${context.read<TaskProvider>().error ?? ''}'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  _loadTask();
                                }
                              }
                            },
                            icon: const Icon(Icons.done_all),
                            label: const Text('Отметить выполненной'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (_task!.status?.code != 'completed' && ['admin', 'asutp_chief', 'operator'].contains(context.watch<AuthProvider>().user?.role)) const SizedBox(height: 12),

                      // Confirm completion button (KPI award — asutp_chief, admin)
                      if (_task!.status?.code == 'completed' && (context.watch<AuthProvider>().user?.role == 'asutp_chief' || context.watch<AuthProvider>().user?.role == 'admin'))
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Подтвердить выполнение?'),
                                  content: const Text('Начислить KPI исполнителям'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Подтвердить')),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                final success = await context.read<TaskProvider>().confirmCompletion(_task!.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Выполнение подтверждено, KPI начислен' : 'Ошибка: ${context.read<TaskProvider>().error ?? ''}'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  _loadTask();
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Подтвердить выполнение'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      if (_task!.status?.code == 'completed' && (context.watch<AuthProvider>().user?.role == 'asutp_chief' || context.watch<AuthProvider>().user?.role == 'admin')) const SizedBox(height: 12),

                      // History button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/task-history', arguments: _task!.id),
                          icon: const Icon(Icons.history),
                          label: const Text('История изменений'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoCard({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
