import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/task_model.dart';
import '../models/kpi_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TaskProvider>().loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _TasksTab(),
          _NotificationsTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task), label: 'Задачи'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Уведомления'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
      floatingActionButton: _currentIndex <= 1 && (context.watch<AuthProvider>().user?.canCreateMainTasks ?? false)
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/create-task'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ===================== HOME TAB =====================
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
      case 'icon_inspection': return Icons.visibility;
      case 'icon_cleaning': return Icons.cleaning_services;
      case 'icon_firmware': return Icons.system_update;
      case 'icon_security': return Icons.security;
      default: return Icons.category;
    }
  }

  Color _colorFromIndex(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      const Color(0xFF0288D1),
      AppColors.primaryDark,
      const Color(0xFF7B1FA2),
      AppColors.warning,
      AppColors.error,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().loadTasks(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(user?.initials ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Добро пожаловать!', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        Text(user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/search'),
                    icon: const Icon(Icons.search, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Статистика
              Consumer<TaskProvider>(
                builder: (_, tp, __) {
                  final tasks = tp.tasks.where((t) => t.status?.code != 'archived').toList();
                  final total = tasks.length;
                  final completed = tasks.where((t) => t.status?.code == 'completed').length;
                  final inProgress = tasks.where((t) => t.status?.code == 'in_progress').length;
                  final newTasks = tasks.where((t) => t.status?.code == 'new').length;

                  return Row(
                    children: [
                      _StatCard(label: 'Всего', value: '$total', color: AppColors.primary, icon: Icons.assignment),
                      const SizedBox(width: 10),
                      _StatCard(label: 'В работе', value: '$inProgress', color: AppColors.warning, icon: Icons.pending_actions),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Новые', value: '$newTasks', color: AppColors.accent, icon: Icons.fiber_new),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Готово', value: '$completed', color: AppColors.success, icon: Icons.check_circle_outline),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Компоненты АСУТП (кликабельные для фильтрации)
              const Text('Компоненты АСУТП', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Нажмите для фильтрации задач', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: _loadingCategories
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _categories.isEmpty
                        ? const Center(child: Text('Нет категорий', style: TextStyle(fontSize: 12, color: Colors.grey)))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: _categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final cat = entry.value;
                              final catId = cat['id'] as int?;
                              final catName = cat['name'] as String? ?? '';
                              final iconId = cat['icon_identifier'] as String?;
                              final color = _colorFromIndex(index);
                              final isSelected = _selectedCategoryId == catId;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedCategoryId == catId) {
                                      _selectedCategoryId = null;
                                      context.read<TaskProvider>().loadTasks();
                                    } else {
                                      _selectedCategoryId = catId;
                                      context.read<TaskProvider>().loadTasks();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isSelected ? color : color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: isSelected ? Border.all(color: color, width: 2) : null,
                                        ),
                                        child: Icon(_iconFromIdentifier(iconId), color: isSelected ? Colors.white : color, size: 28),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(catName, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 20),

              // Задачи
              Row(
                children: [
                  Text(
                    _selectedCategoryId != null ? 'Задачи по категории' : 'Активные задачи',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedCategoryId != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedCategoryId = null);
                        context.read<TaskProvider>().loadTasks();
                      },
                      child: const Text('Сбросить', style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<TaskProvider>(
                builder: (_, tp, __) {
                  if (tp.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                  var tasks = tp.tasks.where((t) => t.status?.code != 'archived').toList();
                  if (_selectedCategoryId != null) {
                    tasks = tasks.where((t) => t.category?.id == _selectedCategoryId).toList();
                  }
                  if (tasks.isEmpty) return const _EmptyState();
                  return Column(
                    children: tasks.take(10).map((t) => TaskCard(task: t)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ===================== TASK CARD (public for reuse) =====================
class TaskCard extends StatelessWidget {
  final TaskModel task;
  const TaskCard({super.key, required this.task});

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
      case 'icon_inspection': return Icons.visibility;
      case 'icon_cleaning': return Icons.cleaning_services;
      case 'icon_firmware': return Icons.system_update;
      case 'icon_security': return Icons.security;
      default: return Icons.task;
    }
  }

  Color _priorityColor(String? name) {
    switch (name) {
      case 'high': return AppColors.priorityHigh;
      case 'medium': return AppColors.priorityMedium;
      case 'low': return AppColors.priorityLow;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/task-detail', arguments: task.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_categoryIcon(task.category?.iconIdentifier), color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (task.category != null)
                          Text(task.category!.name, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority?.name).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority?.label ?? '',
                      style: TextStyle(fontSize: 11, color: _priorityColor(task.priority?.name), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(task.dueDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(task.status?.label ?? '', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                  const Spacer(),
                  Text('${task.progress}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_priorityColor(task.priority?.name)),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== TASKS TAB =====================
class _TasksTab extends StatefulWidget {
  const _TasksTab();

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Задачи', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, '/search')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Активные'),
                  selected: !_showArchived,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _showArchived = false);
                      context.read<TaskProvider>().loadTasks();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Архив'),
                  selected: _showArchived,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _showArchived = true);
                      context.read<TaskProvider>().loadTasks(archived: true);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (_, tp, __) {
                if (tp.isLoading) return const Center(child: CircularProgressIndicator());
                if (tp.tasks.isEmpty) return _EmptyState(archived: _showArchived);
                return RefreshIndicator(
                  onRefresh: () => _showArchived
                      ? context.read<TaskProvider>().loadTasks(archived: true)
                      : context.read<TaskProvider>().loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tp.tasks.length,
                    itemBuilder: (_, i) => TaskCard(task: tp.tasks[i]),
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

// ===================== NOTIFICATIONS TAB =====================
class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Уведомления', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Нет новых уведомлений', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== PROFILE TAB =====================
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  KpiSummary? _kpiSummary;
  bool _loadingKpi = false;

  @override
  void initState() {
    super.initState();
    _loadKpi();
  }

  Future<void> _loadKpi() async {
    setState(() => _loadingKpi = true);
    final summary = await context.read<TaskProvider>().getMyKpi();
    if (mounted) {
      setState(() {
        _kpiSummary = summary;
        _loadingKpi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tasks = context.watch<TaskProvider>().tasks;
    final total = tasks.length;
    final completed = tasks.where((t) => t.status?.code == 'completed' || t.status?.code == 'archived').length;
    final inProgress = total - completed;
    final kpiAvg = _kpiSummary?.average ?? 0.0;
    final kpiColor = kpiAvg >= 80 ? AppColors.success : kpiAvg >= 50 ? AppColors.warning : Colors.red;
    final isAdmin = user?.isAdmin ?? false;
    final canExport = user?.canExport ?? false;
    final canManage = user?.canManageTasks ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(user?.initials ?? '?', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(user?.fullName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.roleLabel ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                _StatCard(label: 'Всего', value: '$total', color: AppColors.primary, icon: Icons.assignment),
                const SizedBox(width: 10),
                _StatCard(label: 'Готово', value: '$completed', color: AppColors.success, icon: Icons.check_circle),
                const SizedBox(width: 10),
                _StatCard(label: 'В работе', value: '$inProgress', color: AppColors.warning, icon: Icons.pending),
              ],
            ),
            const SizedBox(height: 20),

            // KPI circle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Мой KPI', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  if (_loadingKpi)
                    const SizedBox(
                      width: 100, height: 100,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 6)),
                    )
                  else
                    SizedBox(
                      width: 100, height: 100,
                      child: Stack(fit: StackFit.expand, children: [
                        CircularProgressIndicator(value: kpiAvg / 100, strokeWidth: 8, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(kpiColor)),
                        Center(child: Text('${kpiAvg.round()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kpiColor))),
                      ]),
                    ),
                  const SizedBox(height: 8),
                  if (_kpiSummary != null)
                    Text(
                      'Начислений: ${_kpiSummary!.totalCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _MenuItem(icon: Icons.notifications_outlined, label: 'Настройки уведомлений', onTap: () => Navigator.pushNamed(context, '/notification-settings')),
            _MenuItem(icon: Icons.analytics_outlined, label: 'Подробный KPI', onTap: () => Navigator.pushNamed(context, '/kpi')),
            if (canExport)
              _MenuItem(icon: Icons.download, label: 'Экспорт данных (CSV)', onTap: () => Navigator.pushNamed(context, '/csv-exports')),

            // Админ-панель
            if (isAdmin || user?.role == 'chief_engineer') ...[
              const SizedBox(height: 8),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Администрирование', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ),
              if (isAdmin)
                _MenuItem(icon: Icons.people_outline, label: 'Управление пользователями', onTap: () => Navigator.pushNamed(context, '/admin/users')),
              if (isAdmin)
                _MenuItem(icon: Icons.category_outlined, label: 'Управление справочниками', onTap: () => Navigator.pushNamed(context, '/admin/categories')),
              if (isAdmin)
                _MenuItem(icon: Icons.lock_reset_outlined, label: 'Запросы на сброс пароля', onTap: () => Navigator.pushNamed(context, '/admin/reset-requests')),
            ],

            _MenuItem(icon: Icons.help_outline, label: 'Справка', onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'АИТ Прософт-Системы',
                applicationVersion: '1.0.0',
                children: [
                  const Text('Приложение для управления задачами в системах промышленной автоматизации (SCADA/PLC).'),
                  const SizedBox(height: 8),
                  const Text('Оператор — диспетчерское управление задачами.\nИнженер — обслуживание и настройка.\nАдминистратор — конфигурация системы.'),
                ],
              );
            }),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Выйти из аккаунта', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool archived;
  const _EmptyState({this.archived = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(
                archived ? Icons.archive_outlined : Icons.dns_outlined,
                size: 60,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              archived ? 'Архив пуст' : 'Задач пока нет',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              archived
                  ? 'Здесь будут задачи после\nподтверждения выполнения'
                  : 'Создайте первую задачу для вашего\nобъекта автоматизации',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            if (!archived && (context.watch<AuthProvider>().user?.canCreateMainTasks ?? false))
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-task'),
                icon: const Icon(Icons.add),
                label: const Text('Создать задачу'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
          ],
        ),
      ),
    );
  }
}
