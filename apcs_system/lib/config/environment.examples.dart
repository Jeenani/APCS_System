// ============================================
// АСУТП Tasks — Конфигурация для Flutter
// 
// Примеры для РАЗНЫХ СЦЕНАРИЕВ
// Выберите нужный и скопируйте в lib/config/environment.dart
// ============================================

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 1: РАЗРАБОТКА НА ANDROID ЭМУЛЯТОРЕ (по умолчанию)
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true;
  
  static const bool enableServerSettings = true;    // ✅ Можно менять
  static const bool enableQRCodeConfig = false;
  static const bool enableApiLogging = true;        // ✅ Видеть логи
  static const bool enableOfflineMode = false;
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 2: РАЗРАБОТКА НА iOS СИМУЛЯТОРЕ (Mac)
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  static const String apiBaseUrl = 'http://localhost:8080/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true;
  
  static const bool enableServerSettings = true;    // ✅ Можно менять
  static const bool enableQRCodeConfig = false;
  static const bool enableApiLogging = true;        // ✅ Видеть логи
  static const bool enableOfflineMode = false;
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 3: ТЕСТИРОВАНИЕ НА РЕАЛЬНОМ УСТРОЙСТВЕ + UBUNTU СЕРВЕР
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  // Замените 192.168.1.100 на IP адрес вашего Ubuntu сервера
  static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true;
  
  static const bool enableServerSettings = true;    // ✅ Можно менять в Settings
  static const bool enableQRCodeConfig = true;      // ✅ QR для быстрой смены
  static const bool enableApiLogging = true;        // ✅ Видеть логи
  static const bool enableOfflineMode = true;       // ✅ Offline support
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 4: PRODUCTION (фиксированный сервер, без Settings)
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  static const String apiBaseUrl = 'https://api.example.com/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = false;            // ❌ Production!
  
  static const bool enableServerSettings = false;   // ❌ Settings ОТКЛЮЧЕНЫ
  static const bool enableQRCodeConfig = false;
  static const bool enableApiLogging = false;       // ❌ Без логов
  static const bool enableOfflineMode = true;       // ✅ Offline support
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 5: STAGING (тестовый сервер)
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  static const String apiBaseUrl = 'https://staging-api.example.com/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks (Staging)';
  static const String appVersion = '1.0.0-staging';
  static const bool isDebugMode = true;
  
  static const bool enableServerSettings = false;   // ❌ Settings отключены
  static const bool enableQRCodeConfig = false;
  static const bool enableApiLogging = true;        // ✅ Видеть логи для отладки
  static const bool enableOfflineMode = false;
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// СЦЕНАРИЙ 6: PRODUCTION С ПОДДЕРЖКОЙ ДИНАМИЧЕСКОЙ СМЕНЫ (редко)
// ════════════════════════════════════════════════════════════════

/*
class Environment {
  static const String apiBaseUrl = 'https://api.example.com/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = false;
  
  static const bool enableServerSettings = true;    // ✅ Settings доступны
  static const bool enableQRCodeConfig = true;      // ✅ QR код доступен
  static const bool enableApiLogging = false;       // ❌ Без логов
  static const bool enableOfflineMode = true;       // ✅ Offline support
  
  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
  static Map<String, dynamic> toMap() { /* ... */ }
}
*/

// ════════════════════════════════════════════════════════════════
// КАК ИСПОЛЬЗОВАТЬ ЭТОТ ФАЙЛ
// ════════════════════════════════════════════════════════════════

/*

1. Выберите нужный сценарий выше (1-6)

2. Скопируйте класс Environment из нужного сценария

3. Откройте: apcs_system/lib/config/environment.dart

4. Замените содержимое класса Environment на скопированный код

5. Обновите параметры если нужно (IP адрес, домен, версия и т.д.)

6. Запустите приложение:
   flutter clean
   flutter run

*/

// ════════════════════════════════════════════════════════════════
// ТАБЛИЦА БЫСТРОГО ВЫБОРА
// ════════════════════════════════════════════════════════════════

/*

Вопрос: Какой сценарий выбрать?

┌────────────────────────────────────┬──────────────────────┐
│ Что я делаю?                       │ Сценарий              │
├────────────────────────────────────┼──────────────────────┤
│ Разработка на Windows/Mac          │ #1 Android Emulator  │
│ Разработка на Mac                  │ #2 iOS Simulator     │
│ Тестирование на реальном телефоне  │ #3 Real Device       │
│ Production (готовый сервер)        │ #4 Production        │
│ Staging (тестовый сервер)          │ #5 Staging           │
│ Production гибкий (редко)          │ #6 Production Flex   │
└────────────────────────────────────┴──────────────────────┘

*/

// ════════════════════════════════════════════════════════════════
// ПАРАМЕТРЫ ДЛЯ КАЖДОГО СЦЕНАРИЯ
// ════════════════════════════════════════════════════════════════

/*

apiBaseUrl:
  #1 (Android)     → 'http://10.0.2.2:8080/api/v1'
  #2 (iOS)         → 'http://localhost:8080/api/v1'
  #3 (Real Device) → 'http://192.168.1.100:8080/api/v1'
  #4 (Prod)        → 'https://api.example.com/api/v1'
  #5 (Staging)     → 'https://staging-api.example.com/api/v1'
  #6 (Prod Flex)   → 'https://api.example.com/api/v1'

enableServerSettings:
  #1 (Разработка)  → true  (можно менять в Settings)
  #2 (Разработка)  → true  (можно менять в Settings)
  #3 (Тестирование) → true (можно менять в Settings)
  #4 (Production)  → false (Settings отключены!)
  #5 (Staging)     → false (Settings отключены!)
  #6 (Prod Flex)   → true  (Settings доступны)

enableApiLogging:
  #1 (Разработка)  → true  (видеть логи)
  #2 (Разработка)  → true  (видеть логи)
  #3 (Тестирование) → true (видеть логи)
  #4 (Production)  → false (без логов в боевой системе)
  #5 (Staging)     → true  (видеть логи для отладки)
  #6 (Prod Flex)   → false (без логов)

enableOfflineMode:
  #1-3 (Разработка) → false или true (зависит от нужно ли)
  #4-6 (Production) → true (для надёжности)

*/

// ════════════════════════════════════════════════════════════════
// ПРИМЕРЫ ЗАМЕНЫ IP АДРЕСА
// ════════════════════════════════════════════════════════════════

/*

Вы установили Ubuntu сервер и хотите подключиться:

1. На Ubuntu сервере, найдите IP адрес:
   $ hostname -I
   Вывод: 192.168.1.100

2. В environment.dart, замените:
   OLD: static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
   NEW: static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1';

3. Готово! Приложение подключится к вашему Ubuntu серверу.

Примечание: IP адрес может отличаться в зависимости от вашей сети.
Если не работает, проверьте:
  1. Пингуется ли сервер: ping 192.168.1.100
  2. Запущен ли Go сервер: telnet 192.168.1.100 8080
  3. Открыта ли сеть (firewall): sudo ufw allow 8080

*/

// ════════════════════════════════════════════════════════════════
// ПРИМЕРЫ ЗАМЕНЫ ДОМЕННОГО ИМЕНИ (production)
// ════════════════════════════════════════════════════════════════

/*

Вы настроили Caddy и имеете доменное имя:

1. В environment.dart, замените:
   OLD: static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
   NEW: static const String apiBaseUrl = 'https://api.example.com/api/v1';

2. Убедитесь что DNS правильно настроена:
   $ nslookup api.example.com
   Должно вернуть IP адрес вашего сервера

3. Если работает HTTPS, убедитесь что сертификат валидный:
   $ curl https://api.example.com/api/v1/references/categories

4. Готово!

*/
