import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/task_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _dueDate;
  int _priorityId = 1;
  int? _categoryId;
  bool _saving = false;

  final _categories = [
    {'id': 1, 'name': 'Датчики', 'icon': Icons.speed},
    {'id': 2, 'name': 'Контроллеры', 'icon': Icons.memory},
    {'id': 3, 'name': 'Панели оператора', 'icon': Icons.monitor},
    {'id': 4, 'name': 'Клапаны', 'icon': Icons.toggle_on},
    {'id': 5, 'name': 'Насосы', 'icon': Icons.water_drop},
    {'id': 6, 'name': 'Уровнемеры', 'icon': Icons.straighten},
    {'id': 7, 'name': 'PLC', 'icon': Icons.dns},
    {'id': 8, 'name': 'SCADA', 'icon': Icons.dashboard},
    {'id': 9, 'name': 'Контроль оборудования', 'icon': Icons.build},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите срок выполнения')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'due_date': '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
      'priority_id': _priorityId,
    };
    if (_descController.text.trim().isNotEmpty) {
      data['description'] = _descController.text.trim();
    }
    if (_categoryId != null) {
      data['category_id'] = _categoryId;
    }

    final success = await context.read<TaskProvider>().createTask(data);
    setState(() => _saving = false);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Создание задачи'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Название задачи *',
                  hintText: 'Например: Проверка датчиков давления',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Поле обязательно для заполнения';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Подробное описание задачи...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Due date
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Срок выполнения *', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text(
                            _dueDate != null
                                ? '${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}'
                                : 'Выберите дату',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _dueDate != null ? AppColors.textPrimary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Priority
              const Text('Приоритет', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PriorityButton(label: 'Высокий', color: AppColors.priorityHigh, selected: _priorityId == 1, onTap: () => setState(() => _priorityId = 1)),
                  const SizedBox(width: 8),
                  _PriorityButton(label: 'Средний', color: AppColors.priorityMedium, selected: _priorityId == 2, onTap: () => setState(() => _priorityId = 2)),
                  const SizedBox(width: 8),
                  _PriorityButton(label: 'Низкий', color: AppColors.priorityLow, selected: _priorityId == 3, onTap: () => setState(() => _priorityId = 3)),
                ],
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Категория АСУТП', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _categoryId == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = cat['id'] as int),
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
                          Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                          const SizedBox(width: 6),
                          Text(cat['name'] as String, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save button
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
                      : const Text('Сохранить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityButton({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.grey[300]!, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
