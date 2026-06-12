import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../providers/task_provider.dart';

class CreateTaskScreen extends StatefulWidget {
  final int? parentId;
  const CreateTaskScreen({super.key, this.parentId});

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
  List<Map<String, dynamic>> _availableAssignees = [];
  final Set<int> _selectedAssignees = {};
  bool _loadingAssignees = false;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignees();
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final resp = await ApiClient.get('/references/categories');
      if (resp is List) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            resp.map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)),
          );
          _loadingCategories = false;
        });
      } else {
        setState(() => _loadingCategories = false);
      }
    } catch (e) {
      setState(() => _loadingCategories = false);
    }
  }

  IconData _iconFromIdentifier(String? id) {
    switch (id) {
      case 'icon_sensor': return Icons.speed;
      case 'icon_plc': return Icons.memory;
      case 'icon_hmi': return Icons.monitor;
      case 'icon_valve': return Icons.toggle_on;
      case 'icon_pump': return Icons.water_drop;
      case 'icon_level': return Icons.straighten;
      case 'icon_plc_rack': return Icons.dns;
      case 'icon_scada': return Icons.dashboard;
      case 'icon_equipment': return Icons.build;
      default: return Icons.category;
    }
  }

  Future<void> _loadAssignees() async {
    setState(() => _loadingAssignees = true);
    final assignees = await context.read<TaskProvider>().getAssignees();
    if (mounted) {
      setState(() {
        _availableAssignees = assignees;
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
    if (_selectedAssignees.isNotEmpty) {
      data['assignees'] = _selectedAssignees.toList();
    }
    if (widget.parentId != null) {
      data['parent_id'] = widget.parentId;
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
        title: Text(widget.parentId != null ? 'Создание подзадачи' : 'Создание задачи'),
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
              if (_loadingCategories)
                const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_categories.isEmpty)
                Text('Нет доступных категорий', style: TextStyle(fontSize: 13, color: Colors.grey[600]))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final catId = cat['id'] as int?;
                    final isSelected = _categoryId == catId;
                    return GestureDetector(
                      onTap: () => setState(() => _categoryId = catId),
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
                            Icon(_iconFromIdentifier(cat['icon_identifier'] as String?), size: 16, color: isSelected ? Colors.white : AppColors.primary),
                            const SizedBox(width: 6),
                            Text(cat['name'] as String? ?? '', style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
