import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/api_client.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ApiClient.get('/admin/users') as Map<String, dynamic>;
      setState(() {
        _users = List<Map<String, dynamic>>.from(resp['users'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return 'Администратор';
      case 'chief_engineer': return 'Главный инженер';
      case 'asutp_chief': return 'Нач. службы АСУТП';
      case 'engineer': return 'Инженер';
      case 'operator': return 'Оператор';
      default: return role;
    }
  }

  Future<void> _toggleActive(int id, bool current) async {
    await ApiClient.put('/admin/users/$id', {'is_active': !current});
    _load();
  }

  Future<void> _showEditDialog(Map<String, dynamic> u) async {
    final nameC = TextEditingController(text: u['full_name'] ?? '');
    int roleId = u['role_id'] ?? 4;
    bool isActive = u['is_active'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Редактировать пользователя'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'ФИО')),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: roleId,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Администратор')),
                  DropdownMenuItem(value: 2, child: Text('Главный инженер')),
                  DropdownMenuItem(value: 3, child: Text('Нач. службы АСУТП')),
                  DropdownMenuItem(value: 4, child: Text('Инженер')),
                  DropdownMenuItem(value: 5, child: Text('Оператор')),
                ],
                onChanged: (v) => setS(() => roleId = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Активен'),
                value: isActive,
                onChanged: (v) => setS(() => isActive = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.put('/admin/users/${u['id']}', {
                    'full_name': nameC.text.trim(),
                    'role_id': roleId,
                    'is_active': isActive,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Сохранить'),
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
        title: const Text('Удалить пользователя?'),
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
    if (confirm == true) {
      await ApiClient.delete('/admin/users/$id');
      _load();
    }
  }

  Future<void> _showCreateDialog() async {
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final nameC = TextEditingController();
    int roleId = 4;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Новый пользователь'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'ФИО')),
              const SizedBox(height: 8),
              TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              TextField(controller: passC, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: roleId,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Администратор')),
                  DropdownMenuItem(value: 2, child: Text('Главный инженер')),
                  DropdownMenuItem(value: 3, child: Text('Нач. службы АСУТП')),
                  DropdownMenuItem(value: 4, child: Text('Инженер')),
                  DropdownMenuItem(value: 5, child: Text('Оператор')),
                ],
                onChanged: (v) => setS(() => roleId = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiClient.post('/admin/users', {
                    'email': emailC.text.trim(),
                    'password': passC.text,
                    'full_name': nameC.text.trim(),
                    'role_id': roleId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Управление пользователями'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                final isActive = u['is_active'] ?? true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? AppColors.primary : Colors.grey,
                      child: Text(u['initials'] ?? '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    title: Text(u['full_name'] ?? '', style: TextStyle(decoration: isActive ? null : TextDecoration.lineThrough)),
                    subtitle: Text('${u['login']} • ${_roleLabel(u['role'] ?? '')}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary),
                          onPressed: () => _showEditDialog(u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _delete(u['id']),
                        ),
                        Switch(
                          value: isActive,
                          activeColor: AppColors.primary,
                          onChanged: (_) => _toggleActive(u['id'], isActive),
                        ),
                      ],
                    ),
                    onTap: () => _showEditDialog(u),
                  ),
                );
              },
            ),
    );
  }
}
