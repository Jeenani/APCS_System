import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/api_client.dart';

class ServerSettings {
  static const String _serverUrlKey = 'server_url';
  
  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }
  
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? ApiConfig.baseUrl;
  }
  
  static Future<void> clearServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverUrlKey);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  String _currentUrl = ApiConfig.baseUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadServerUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadServerUrl() async {
    final url = await ServerSettings.getServerUrl();
    setState(() {
      _currentUrl = url;
      _urlController.text = url;
      _isLoading = false;
    });
  }

  Future<void> _saveServerUrl() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showError('URL не может быть пустым');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('URL должен начинаться с http:// или https://');
      return;
    }

    try {
      // Проверяем доступность сервера
      await ApiClient.testConnection(url);
      
      await ServerSettings.setServerUrl(url);
      setState(() => _currentUrl = url);
      
      _showSuccess('Сервер успешно добавлен');
    } catch (e) {
      _showError('Ошибка подключения: $e');
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _urlController.text = ApiConfig.baseUrl);
    await ServerSettings.clearServerUrl();
    setState(() => _currentUrl = ApiConfig.baseUrl);
    _showSuccess('Установлено значение по умолчанию');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки сервера'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Текущий сервер =====
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущий сервер',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentUrl,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== Ввод нового URL =====
            const Text(
              'Новый адрес сервера',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Например: http://192.168.1.100:8080/api/v1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 24),

            // ===== Кнопки =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveServerUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Сохранить и проверить',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetToDefault,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Вернуть по умолчанию',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1565C0)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ===== Справка =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Справка',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Форматы адреса:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildHelpItem(
                    '• По IP:',
                    'http://192.168.1.100:8080/api/v1',
                  ),
                  _buildHelpItem(
                    '• По hostname:',
                    'http://my-server.local:8080/api/v1',
                  ),
                  _buildHelpItem(
                    '• По домену:',
                    'https://api.example.com/api/v1',
                  ),
                  _buildHelpItem(
                    '• Локально (Mac):',
                    'http://localhost:8080/api/v1',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Важно: без /api/v1 не будет работать!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
    );
  }
}
