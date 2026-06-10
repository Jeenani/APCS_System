import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import '../config/environment.dart';

class ApiClient {
  static String? _accessToken;
  static String? _refreshToken;
  static String? _baseUrl;

  // ============================================
  // Инициализация
  // ============================================
  
  static Future<void> initialize() async {
    await loadTokens();
    await _loadBaseUrl();
  }

  static Future<void> _loadBaseUrl() async {
    // Если Settings отключены в конфиге, всегда используем Environment значение
    if (!Environment.enableServerSettings) {
      _baseUrl = Environment.apiBaseUrl;
      return;
    }
    
    // Если Settings включены, загружаем из SharedPreferences (если сохранено)
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('server_url') ?? Environment.apiBaseUrl;
  }

  static String get baseUrl => _baseUrl ?? Environment.apiBaseUrl;

  // ============================================
  // Управление токенами
  // ============================================

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  static bool get isAuthenticated => _accessToken != null;
  static String? get accessToken => _accessToken;

  // ============================================
  // Тестирование соединения
  // ============================================

  static Future<void> testConnection(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse('$url/references/categories'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Сервер вернул ошибку: ${response.statusCode}');
      }

      // Сохраняем URL если проверка прошла
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', url);
      _baseUrl = url;
    } catch (e) {
      throw Exception('Невозможно подключиться к серверу: $e');
    }
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ============================================
  // HTTP методы
  // ============================================

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['error'] ?? 'Ошибка сервера',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
