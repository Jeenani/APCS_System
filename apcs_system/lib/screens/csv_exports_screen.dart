import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class CsvExportsScreen extends StatefulWidget {
  const CsvExportsScreen({super.key});

  @override
  State<CsvExportsScreen> createState() => _CsvExportsScreenState();
}

class _CsvExportsScreenState extends State<CsvExportsScreen> {
  List<File> _files = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _getExportsDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${baseDir.path}/APCS_System/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    return exportsDir;
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final dir = await _getExportsDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.csv'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _createExport() async {
    setState(() => _exporting = true);
    try {
      final response = await ApiClient.client.get(
        Uri.parse('${ApiConfig.baseUrl}/export/csv'),
        headers: {'Authorization': 'Bearer ${ApiClient.accessToken}'},
      );
      if (response.statusCode == 200) {
        final dir = await _getExportsDir();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${dir.path}/tasks_export_$timestamp.csv');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV экспорт создан')),
          );
        }
        await _loadFiles();
      } else if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Недостаточно прав для экспорта')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка экспорта: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _openFile(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
      );
    }
  }

  Future<void> _shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Экспорт задач CSV',
    );
  }

  Future<void> _deleteFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text('Удалить ${file.path.split('/').last}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await file.delete();
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Экспорты CSV'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFiles,
              child: _files.isEmpty
                  ? _EmptyExports(onCreate: _createExport, exporting: _exporting)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _files.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _exporting ? null : _createExport,
                                icon: _exporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: Text(_exporting ? 'Создание...' : 'Создать новый экспорт'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        final file = _files[index - 1];
                        final fileName = file.path.split('/').last;
                        final modified = file.lastModifiedSync();
                        final size = file.lengthSync();
                        final sizeKb = (size / 1024).toStringAsFixed(1);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.table_chart, color: AppColors.primary),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${DateFormat('dd.MM.yyyy HH:mm').format(modified)} \u2022 $sizeKb KB',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                  tooltip: 'Открыть',
                                  onPressed: () => _openFile(file),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 20),
                                  tooltip: 'Поделиться',
                                  onPressed: () => _shareFile(file),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                  tooltip: 'Удалить',
                                  onPressed: () => _deleteFile(file),
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

class _EmptyExports extends StatelessWidget {
  final VoidCallback onCreate;
  final bool exporting;
  const _EmptyExports({required this.onCreate, required this.exporting});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Нет экспортов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Создайте CSV-файл с задачами\nи управляйте им здесь',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: exporting ? null : onCreate,
              icon: exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download),
              label: Text(exporting ? 'Создание...' : 'Создать экспорт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
