import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _dueDate;
  late int _priorityId;
  late int _statusId;
  late double _progress;
  bool _saving = false;
  List<Map<String, dynamic>> _availableAssignees = [];
  final Set<int> _selectedAssignees = {};
  bool _loadingAssignees = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description ?? '');
    _dueDate = DateTime.tryParse(widget.task.dueDate) ?? DateTime.now();
    _priorityId = widget.task.priority?.id ?? 1;
    _statusId = widget.task.status?.id ?? 1;
    _progress = widget.task.progress.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssignees());
  }

  Future<void> _loadAssignees() async {
    setState(() => _loadingAssignees = true);
    final assignees = await context.read<TaskProvider>().getAssignees();
    if (mounted) {
      final existingIds = widget.task.assignees
          .map((a) => a.user?.id)
          .where((id) => id != null)
          .toSet();
      setState(() {
        _availableAssignees = assignees.where((u) {
          final id = u['id'] as int?;
          return id != null && !existingIds.contains(id);
        }).toList();
        _loadingAssignees = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'due_date': '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
      'priority_id': _priorityId,
      'status_id': _statusId,
      'progress': _progress.round(),
    };
    data['assignees'] = _selectedAssignees.toList();
    debugPrint('Update task body: $data');

    final success = await context.read<TaskProvider>().updateTask(widget.task.id, data);
    setState(() => _saving = false);

    if (!mounted) return;

    if (!success) {
      final errorMsg = context.read<TaskProvider>().error ?? 'Ошибка сохранения';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      return;
    }

    final userRole = context.read<AuthProvider>().user?.role;
    final hadAssignees = _selectedAssignees.isNotEmpty;
    String message;
    if (hadAssignees) {
      if (userRole == 'chief_engineer' || userRole == 'asutp_chief' || userRole == 'admin') {
        message = 'Исполнители назначены';
      } else {
        message = 'Запрос на назначение отправлен руководителям';
      }
    } else {
      message = 'Задача обновлена';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Редактирование задачи'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Название задачи',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_dueDate.day.toString().padLeft(2, '0')}.${_dueDate.month.toString().padLeft(2, '0')}.${_dueDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Priority
            const Text('Приоритет', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Высокий')),
                ButtonSegment(value: 2, label: Text('Средний')),
                ButtonSegment(value: 3, label: Text('Низкий')),
              ],
              selected: {_priorityId},
              onSelectionChanged: (s) => setState(() => _priorityId = s.first),
            ),
            const SizedBox(height: 16),

            // Status
            const Text('Статус', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Новая')),
                ButtonSegment(value: 2, label: Text('В работе')),
                ButtonSegment(value: 3, label: Text('Готово')),
                ButtonSegment(value: 4, label: Text('Отмена')),
              ],
              selected: {_statusId},
              onSelectionChanged: (s) => setState(() => _statusId = s.first),
            ),
            const SizedBox(height: 16),

            // Progress slider
            const Text('Прогресс', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_progress.round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _progress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    label: '${_progress.round()}%',
                    onChanged: (v) => setState(() => _progress = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assignees
            const Text('Исполнители', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_loadingAssignees)
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_availableAssignees.isEmpty)
              Text('Нет доступных исполнителей', style: TextStyle(fontSize: 13, color: Colors.grey[600]))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAssignees.map((u) {
                  final id = u['id'] as int;
                  final isSelected = _selectedAssignees.contains(id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedAssignees.remove(id);
                      } else {
                        _selectedAssignees.add(id);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.person_outline,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            u['full_name'] as String,
                            style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Сохранить изменения', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
