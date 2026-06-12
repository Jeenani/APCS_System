import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/api_client.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiClient.get('/references/categories');
      if (resp is List) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(
            resp.map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)),
          );
          _loading = false;
        });
      } else if (resp is Map<String, dynamic> && resp['data'] is List) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(resp['data']);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  final Map<String, IconData> _iconOptions = const {
    'icon_sensor': Icons.speed,
    'icon_plc': Icons.memory,
    'icon_hmi': Icons.monitor,
    'icon_valve': Icons.toggle_on,
    'icon_pump': Icons.water_drop,
    'icon_level': Icons.straighten,
    'icon_plc_rack': Icons.dns,
    'icon_scada': Icons.dashboard,
    'icon_equipment': Icons.build,
  };

  Future<void> _showCreateDialog() async {
    final nameC = TextEditingController();
    String selectedIcon = 'icon_sensor';
    final descC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Новая категория'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Название')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedIcon,
                decoration: const InputDecoration(labelText: 'Иконка'),
                items: _iconOptions.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Row(
                      children: [
                        Icon(e.value, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(e.key),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setS(() => selectedIcon = v!),
              ),
              const SizedBox(height: 16),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Описание')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.post('/admin/categories', {
                    'name': nameC.text.trim(),
                    'icon_identifier': selectedIcon,
                    'description': descC.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить категорию?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiClient.delete('/admin/categories/$id');
      _load();
    }
  }

  IconData _getIcon(String? iconId) {
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
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Справочники: Категории'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final c = _categories[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(_getIcon(c['icon_identifier']), color: AppColors.primary),
                    ),
                    title: Text(c['name'] ?? ''),
                    subtitle: Text(c['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _delete(c['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
