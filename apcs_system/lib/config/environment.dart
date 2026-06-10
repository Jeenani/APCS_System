// ============================================
// АСУТП Tasks — Конфигурация для Flutter
// ============================================
// 
// Editайте этот файл чтобы менять API URL, API key, и другие константы
// БЕЗ перекомпиляции Dart кода (нужна только пересборка приложения)

class Environment {
  // ============================================
  // API Configuration
  // ============================================
  
  /// API Base URL для подключения к серверу
  /// 
  /// Примеры:
  /// - 'http://10.0.2.2:8080/api/v1'    (Android эмулятор)
  /// - 'http://localhost:8080/api/v1'   (iOS симулятор на Mac)
  /// - 'http://192.168.1.100:8080/api/v1' (Реальное устройство + Ubuntu сервер)
  /// - 'https://api.example.com/api/v1' (Production)
  static const String apiBaseUrl = 'https://missednoteserv.chickenkiller.com/api/v1';
  
  /// Request timeout (в секундах)
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Повторное подключение при ошибке
  static const int maxRetries = 3;
  
  // ============================================
  // App Configuration
  // ============================================
  
  /// Название приложения
  static const String appName = 'АСУТП Tasks';
  
  /// Версия приложения
  static const String appVersion = '1.0.0';
  
  /// Режим разработки
  static const bool isDebugMode = true;
  
  // ============================================
  // Feature Flags
  // ============================================
  
  /// Включить Settings экран для смены сервера
  static const bool enableServerSettings = false;
  
  /// Включить QR код сканирование для конфига
  static const bool enableQRCodeConfig = false;
  
  /// Включить логирование API запросов
  static const bool enableApiLogging = true;
  
  /// Включить offline режим (sync когда будет соединение)
  static const bool enableOfflineMode = false;
  
  // ============================================
  // Утилиты
  // ============================================
  
  /// Получить полный API URL для endpoint'а
  static String getApiUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }
  
  /// Получить значение конфига по ключу (если добавляете динамические)
  static Map<String, dynamic> toMap() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'requestTimeout': requestTimeout.inSeconds,
      'maxRetries': maxRetries,
      'appName': appName,
      'appVersion': appVersion,
      'isDebugMode': isDebugMode,
      'enableServerSettings': enableServerSettings,
      'enableQRCodeConfig': enableQRCodeConfig,
      'enableApiLogging': enableApiLogging,
      'enableOfflineMode': enableOfflineMode,
    };
  }
}
