import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description ?? '');
    _dueDate = DateTime.tryParse(widget.task.dueDate) ?? DateTime.now();
    _priorityId = widget.task.priority?.id ?? 1;
    _statusId = widget.task.status?.id ?? 1;
    _progress = widget.task.progress.toDouble();
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
      firstDate: DateTime(2020),
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

    final success = await context.read<TaskProvider>().updateTask(widget.task.id, data);
    setState(() => _saving = false);

    if (success && mounted) Navigator.pop(context);
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
