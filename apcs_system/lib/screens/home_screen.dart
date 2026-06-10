import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/task_model.dart';
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
      floatingActionButton: _currentIndex <= 1 && (context.watch<AuthProvider>().user?.canManageTasks ?? false)
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/create-task'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ===================== КОМПОНЕНТЫ АСУТП =====================
class _AsutpComponent {
  final String name;
  final IconData icon;
  final Color color;
  final int? categoryId;

  const _AsutpComponent({required this.name, required this.icon, required this.color, this.categoryId});
}

const _asutpComponents = [
  _AsutpComponent(name: 'Датчики', icon: Icons.speed, color: AppColors.primary, categoryId: 1),
  _AsutpComponent(name: 'Контроллеры', icon: Icons.memory, color: AppColors.accent, categoryId: 2),
  _AsutpComponent(name: 'Клапаны', icon: Icons.toggle_on, color: AppColors.success, categoryId: 4),
  _AsutpComponent(name: 'Насосы', icon: Icons.water_drop, color: Color(0xFF0288D1), categoryId: 5),
  _AsutpComponent(name: 'ПЛК', icon: Icons.dns, color: AppColors.primaryDark, categoryId: 7),
  _AsutpComponent(name: 'SCADA', icon: Icons.monitor, color: Color(0xFF7B1FA2), categoryId: 8),
];

// ===================== HOME TAB =====================
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int? _selectedCategoryId;

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
                  final tasks = tp.tasks;
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
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _asutpComponents.map((comp) {
                    final isSelected = _selectedCategoryId == comp.categoryId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedCategoryId == comp.categoryId) {
                            _selectedCategoryId = null;
                            context.read<TaskProvider>().loadTasks();
                          } else {
                            _selectedCategoryId = comp.categoryId;
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
                                color: isSelected ? comp.color : comp.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected ? Border.all(color: comp.color, width: 2) : null,
                              ),
                              child: Icon(comp.icon, color: isSelected ? Colors.white : comp.color, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(comp.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
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
                  var tasks = tp.tasks;
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
class _TasksTab extends StatelessWidget {
  const _TasksTab();

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
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (_, tp, __) {
                if (tp.isLoading) return const Center(child: CircularProgressIndicator());
                if (tp.tasks.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  onRefresh: () => tp.loadTasks(),
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
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  Future<void> _exportCSV(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Экспорт CSV...')));
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/export/csv'),
        headers: {'Authorization': 'Bearer ${ApiClient.accessToken}'},
      );
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/tasks_export.csv');
        await file.writeAsBytes(response.bodyBytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Сохранено: ${file.path}')));
        }
      } else if (response.statusCode == 403) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Недостаточно прав для экспорта')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tasks = context.watch<TaskProvider>().tasks;
    final total = tasks.length;
    final completed = tasks.where((t) => t.status?.code == 'completed').length;
    final inProgress = total - completed;
    final percent = total > 0 ? ((completed * 100) / total).round() : 0;
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

            // Completion circle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text('Мои показатели', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 100, height: 100,
                    child: Stack(fit: StackFit.expand, children: [
                      CircularProgressIndicator(value: percent / 100, strokeWidth: 8, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                      Center(child: Text('$percent%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _MenuItem(icon: Icons.notifications_outlined, label: 'Настройки уведомлений', onTap: () => Navigator.pushNamed(context, '/notification-settings')),
            _MenuItem(icon: Icons.history, label: 'История активности', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выберите задачу для просмотра истории')));
            }),
            if (canExport)
              _MenuItem(icon: Icons.download, label: 'Экспорт данных (CSV)', onTap: () => _exportCSV(context)),

            // Админ-панель
            if (isAdmin) ...[
              const SizedBox(height: 8),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Администрирование', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ),
              _MenuItem(icon: Icons.people_outline, label: 'Управление пользователями', onTap: () => Navigator.pushNamed(context, '/admin/users')),
              _MenuItem(icon: Icons.category_outlined, label: 'Управление справочниками', onTap: () => Navigator.pushNamed(context, '/admin/categories')),
            ],

            _MenuItem(icon: Icons.help_outline, label: 'Справка', onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'АСУТП Tasks',
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
  const _EmptyState();
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
              child: const Icon(Icons.dns_outlined, size: 60, color: AppColors.primaryLight),
            ),
            const SizedBox(height: 20),
            const Text('Задач пока нет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Создайте первую задачу для вашего\nобъекта автоматизации', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 20),
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
