import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class ResetRequestsScreen extends StatefulWidget {
  const ResetRequestsScreen({super.key});

  @override
  State<ResetRequestsScreen> createState() => _ResetRequestsScreenState();
}

class _ResetRequestsScreenState extends State<ResetRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient.get('/admin/reset-requests');
      if (response is List) {
        setState(() => _requests = response);
      } else {
        setState(() => _error = 'Неверный формат ответа');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка подключения');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApiClient.post('/admin/reset-requests/$id/approve', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подтверждено. Временный пароль отправлен на email.')),
        );
      }
      _loadRequests();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reject(int id) async {
    try {
      await ApiClient.post('/admin/reset-requests/$id/reject', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запрос отклонён')),
        );
      }
      _loadRequests();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы на сброс пароля'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequests,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет активных запросов',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final user = req['user'] ?? {};
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          (user['full_name']?.toString() ?? '?').substring(0, 1),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['full_name']?.toString() ?? 'Неизвестно',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                            ),
                                            Text(
                                              'Email: ${user['email']?.toString() ?? '-'}',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Запрос от: ${req['created_at']?.toString().substring(0, 10) ?? '-'}',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _reject(req['id']),
                                          icon: const Icon(Icons.close, size: 18),
                                          label: const Text('Отклонить'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _approve(req['id']),
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Подтвердить'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
