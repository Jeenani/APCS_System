# ⚙️ Flutter .env конфигурация — Полный гайд

## Что создал?

✅ `lib/config/environment.dart` — Файл конфигурации (как `.env` для Go сервера)

**Преимущества:**
- Легко менять API URL и другие константы
- Нет Settings Screen (простая конфигурация)
- Поддерживает Feature flags
- Типобезопасно (Dart constante)
- Без зависимостей (нет flutter_dotenv)

---

## 📋 Как использовать

### **Вариант 1: ТОЛЬКО хардкод (без Settings)**

**1. Отредактировать конфиг:**

`apcs_system/lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1'; // ← измените IP
  static const bool enableServerSettings = false; // ← Settings ОТКЛЮЧЕНЫ
}
```

**2. Всё! Готово.**

```bash
cd apcs_system
flutter run

# Приложение подключится к 192.168.1.100:8080
# Settings экран НЕ будет показываться
# API URL менять только редактированием конфига
```

**Когда использовать:**
- ✅ Production (фиксированный сервер)
- ✅ Локальная разработка (не нужно менять сервер)
- ✅ Когда Settings Screen усложняет UI

---

### **Вариант 2: Хардкод + Settings Screen (гибкие)**

**1. Включить Settings в конфиге:**

`apcs_system/lib/config/environment.dart`:

```dart
class Environment {
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1'; // ← дефолт
  static const bool enableServerSettings = true; // ← Settings ВКЛЮЧЕНЫ ✅
}
```

**2. Добавить Settings в навигацию:**

`apcs_system/lib/main.dart`:

```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    // ... остальные маршруты
  }
}
```

**3. Добавить кнопку в меню:**

```dart
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, '/settings'),
    ),
  ],
)
```

**Когда использовать:**
- ✅ Разработка (часто менять сервер)
- ✅ Тестирование разных окружений
- ✅ Production с поддержкой динамической смены (редко)

---

## 📝 Полный конфиг (все опции)

```dart
// apcs_system/lib/config/environment.dart

class Environment {
  // ============================================
  // API Configuration
  // ============================================
  
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
  
  // Request timeout (в секундах)
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Повторные попытки при ошибке
  static const int maxRetries = 3;
  
  // ============================================
  // App Configuration
  // ============================================
  
  static const String appName = 'АСУТП Tasks';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true;
  
  // ============================================
  // Feature Flags (переключатели функций)
  // ============================================
  
  // ✅ Settings экран для смены сервера
  static const bool enableServerSettings = true;
  
  // ✅ QR код для быстрой конфигурации
  static const bool enableQRCodeConfig = false;
  
  // ✅ Логирование API запросов в консоль
  static const bool enableApiLogging = true;
  
  // ✅ Работа без интернета (sync когда вернётся соединение)
  static const bool enableOfflineMode = false;
}
```

---

## 🎯 Сценарии использования

### **Сценарий 1: Разработка на эмуляторе**

```dart
class Environment {
  static const String apiBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const bool enableServerSettings = true;  // менять можно
  static const bool enableApiLogging = true;      // видеть логи
}
```

### **Сценарий 2: Тестирование на реальном устройстве**

```dart
class Environment {
  static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1';
  static const bool enableServerSettings = true;  // может менять в Settings
  static const bool enableApiLogging = true;
}
```

### **Сценарий 3: Production**

```dart
class Environment {
  static const String apiBaseUrl = 'https://api.example.com/api/v1';
  static const bool enableServerSettings = false; // Settings отключены!
  static const bool enableApiLogging = false;     // без логов в production
  static const bool isDebugMode = false;
}
```

### **Сценарий 4: Staging (тестовый сервер)**

```dart
class Environment {
  static const String apiBaseUrl = 'https://staging-api.example.com/api/v1';
  static const bool enableServerSettings = false;
  static const bool enableApiLogging = true;      // логи для отладки
  static const bool isDebugMode = true;
}
```

---

## 🔧 Как использовать в коде

### **В constants.dart (уже обновлено):**

```dart
import '../config/environment.dart';

class ApiConfig {
  static const String baseUrl = Environment.apiBaseUrl;
}
```

### **В api_client.dart (уже обновлено):**

```dart
static Future<void> _loadBaseUrl() async {
  if (!Environment.enableServerSettings) {
    _baseUrl = Environment.apiBaseUrl;  // Если Settings отключены - используем конфиг
    return;
  }
  // Иначе загружаем из SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  _baseUrl = prefs.getString('server_url') ?? Environment.apiBaseUrl;
}
```

### **В любом месте в коде:**

```dart
import 'config/environment.dart';

// Получить API URL
print(Environment.apiBaseUrl);  // 'http://10.0.2.2:8080/api/v1'

// Проверить feature flag
if (Environment.enableApiLogging) {
  print('Логирование включено');
}

// Проверить режим debug
if (Environment.isDebugMode) {
  print('Режим разработки');
}

// Получить все конфиги в виде Map
print(Environment.toMap());
```

---

## 📊 Сравнение: Hardcoded vs Settings Screen vs Environment

| Способ | Простота | Гибкость | Production | Для чего |
|--------|----------|----------|-----------|---------|
| **Hardcoded в constants.dart** | ⭐⭐ | ⭐ | ❌ Плохо | Только для разработки |
| **Environment конфиг (вариант 1)** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ✅ Хорошо | Production или фиксированный сервер |
| **Settings Screen (вариант 2)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Хорошо | Разработка + Testing |
| **QR Code (опционально)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ✅ Хорошо | Production + быстрое onboarding |

---

## ⚡ Быстрый старт

### **Шаг 1: Открыть файл конфига**

```
apcs_system/lib/config/environment.dart
```

### **Шаг 2: Изменить API URL**

```dart
static const String apiBaseUrl = 'http://192.168.1.100:8080/api/v1';
```

### **Шаг 3: Выбрать режим**

```dart
// Если хотите Settings экран:
static const bool enableServerSettings = true;

// Если хотите только хардкод:
static const bool enableServerSettings = false;
```

### **Шаг 4: Запустить**

```bash
flutter run
```

---

## 🔐 Безопасность

### **Credentials в конфиге:**

❌ **НИКОГДА** не коммитьте реальные API ключи в `environment.dart`!

```dart
// ❌ ПЛОХО!
static const String apiBaseUrl = 'https://api.production.com/api/v1';
static const String apiKey = 'secret-key-12345';  // ← видно в исходнике!
```

**Решение для production:**

1. **Вариант A:** Использовать разные build-конфиги (для разных environments)
2. **Вариант B:** Загружать конфиг с сервера при старте
3. **Вариант C:** Использовать native code для credentials

Для разработки/тестирования это OK.

---

## 📚 Пример: использование Feature Flags

```dart
import 'config/environment.dart';
import 'core/api_client.dart';

class TaskProvider extends ChangeNotifier {
  Future<void> loadTasks() async {
    if (Environment.enableApiLogging) {
      print('📡 Загружаю задачи с ${ApiClient.baseUrl}');
    }
    
    try {
      final data = await ApiClient.get('/tasks');
      // ...
    } catch (e) {
      if (Environment.enableApiLogging) {
        print('❌ Ошибка: $e');
      }
      if (Environment.enableOfflineMode) {
        // Load from local cache
      }
    }
  }
}
```

---

## ✅ Чек-лист

- [ ] Открыли `lib/config/environment.dart`
- [ ] Изменили `apiBaseUrl` на нужный адрес
- [ ] Выбрали режим (`enableServerSettings` true/false)
- [ ] Запустили `flutter run`
- [ ] Приложение подключается к нужному серверу
- [ ] Всё работает! ✅

---

## 🐛 Если что-то не работает

### "Приложение всё ещё использует старый URL"

```bash
flutter clean
flutter run
```

### "Setting Screen не показывается"

Убедитесь что:
1. `enableServerSettings = true` в environment.dart
2. Settings добавлены в навигацию (main.dart)
3. Кнопка Settings видна в UI

### "API URL не меняется"

Если `enableServerSettings = false`, URL менять можно ТОЛЬКО в environment.dart (без Settings экрана).

```bash
# Отредактируйте
apcs_system/lib/config/environment.dart

# Пересоберите
flutter run
```

---

## 📖 Полная справка

**Файлы которые были обновлены:**

- ✅ `lib/config/environment.dart` — новый конфиг файл
- ✅ `lib/core/constants.dart` — обновлено для использования Environment
- ✅ `lib/core/api_client.dart` — учитывает enableServerSettings
- ✅ `lib/main.dart` — инициализирует ApiClient

**Как это работает:**

1. Приложение запускается → `main.dart` вызывает `ApiClient.initialize()`
2. ApiClient загружает URL из `environment.dart`
3. Если `enableServerSettings = true` и есть сохранённый URL в SharedPreferences → использует его
4. Если `enableServerSettings = false` → ВСЕГДА использует `environment.dart`
5. Все API запросы используют загруженный URL

---

**Готово! 🚀 Теперь конфигурация как на Go сервере!**
