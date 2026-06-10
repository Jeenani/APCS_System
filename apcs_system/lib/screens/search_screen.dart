import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedPriority;
  String _sortBy = 'due_date_desc';
  List<TaskModel> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _results = context.read<TaskProvider>().tasks;
  }

  void _search() async {
    setState(() => _loading = true);

    final taskProv = context.read<TaskProvider>();
    int? priorityId;
    if (_selectedPriority == 'high') priorityId = 1;
    if (_selectedPriority == 'medium') priorityId = 2;
    if (_selectedPriority == 'low') priorityId = 3;

    await taskProv.loadTasks(
      search: _searchController.text.trim(),
      sort: _sortBy,
      priorityId: priorityId,
    );

    setState(() {
      _results = taskProv.tasks;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      default: return Icons.task;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Поиск и фильтрация'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Поиск задач...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'Все', selected: _selectedPriority == null, onTap: () { setState(() => _selectedPriority = null); _search(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Высокий', selected: _selectedPriority == 'high', color: AppColors.priorityHigh, onTap: () { setState(() => _selectedPriority = 'high'); _search(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Средний', selected: _selectedPriority == 'medium', color: AppColors.priorityMedium, onTap: () { setState(() => _selectedPriority = 'medium'); _search(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Низкий', selected: _selectedPriority == 'low', color: AppColors.priorityLow, onTap: () { setState(() => _selectedPriority = 'low'); _search(); }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Сортировка:', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'due_date_desc', child: Text('По дедлайну ↓')),
                    DropdownMenuItem(value: 'due_date_asc', child: Text('По дедлайну ↑')),
                    DropdownMenuItem(value: 'progress_desc', child: Text('По прогрессу ↓')),
                    DropdownMenuItem(value: 'progress_asc', child: Text('По прогрессу ↑')),
                  ],
                  onChanged: (v) { setState(() => _sortBy = v!); _search(); },
                ),
                const Spacer(),
                Text('Найдено: ${_results.length}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(child: Text('Ничего не найдено', style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final t = _results[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () => Navigator.pushNamed(context, '/task-detail', arguments: t.id),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_categoryIcon(t.category?.iconIdentifier), color: AppColors.primary, size: 20),
                              ),
                              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Row(
                                children: [
                                  Text(t.dueDate, style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _priorityColor(t.priority?.name), shape: BoxShape.circle)),
                                  const Spacer(),
                                  Text('${t.progress}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (color ?? AppColors.primary) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color ?? AppColors.primary),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: selected ? Colors.white : (color ?? AppColors.primary), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
