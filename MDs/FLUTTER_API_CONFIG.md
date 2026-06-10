# 📱 Flutter: 3 способа подключения к серверу

## 1️⃣ **Hardcoded URL (текущий вариант — не рекомендуется)**

```dart
// constants.dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';
}
```

**Проблемы:**
- ❌ Нельзя менять без перекомпиляции
- ❌ Привязан к Android эмулятору
- ❌ Не подходит для production

**Используйте только если:** локально на эмуляторе и не планируете менять

---

## 2️⃣ **Settings Screen (рекомендуется для большинства)**

✅ Создан файл: `lib/screens/settings_screen.dart`

**Как работает:**

1. **Первый запуск:**
   - Приложение использует `ApiConfig.baseUrl`
   - На главном экране есть кнопка "Настройки"

2. **В Settings:**
   - Пользователь вводит URL сервера
   - Приложение проверяет доступность (`testConnection`)
   - URL сохраняется в `SharedPreferences`

3. **При перезапуске:**
   - Приложение загружает сохранённый URL
   - Использует его для всех запросов

**Код использования:**

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.initialize();  // Загружает сохранённый URL
  runApp(const AsutpTasksApp());
}

// api_client.dart
static Future<void> testConnection(String url) async {
  // Проверяет доступность сервера перед сохранением
}
```

**Интеграция в навигацию:**

```dart
// Добавьте в вкладки/меню приложения
MaterialApp(
  onGenerateRoute: (settings) {
    switch (settings.name) {
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      // ... другие маршруты
    }
  },
)
```

**Преимущества:**
- ✅ Пользователь может менять сервер без перекомпиляции
- ✅ Поддержка разных окружений (dev, staging, production)
- ✅ Удобно для тестирования
- ✅ Сохранение между запусками приложения

---

## 3️⃣ **QR Code Scanning (для production)**

Альтернатива для быстрой настройки по QR коду:

```dart
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ServerConfigQRScreen extends StatefulWidget {
  @override
  State<ServerConfigQRScreen> createState() => _ServerConfigQRScreenState();
}

class _ServerConfigQRScreenState extends State<ServerConfigQRScreen> {
  final qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканировать QR код сервера')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      // scanData.code содержит URL сервера
      await ServerSettings.setServerUrl(scanData.code!);
      Navigator.pop(context);
    });
  }
}
```

**Когда использовать:**
- Production с множеством пользователей
- Администраторы раздают QR коды
- Упрощает onboarding

**Генерация QR кода:**

```bash
# Используйте любой генератор, например:
https://www.qr-code-generator.com/

# Данные: http://192.168.1.100:8080/api/v1
# или: https://api.example.com/api/v1
```

---

## 🎯 Сравнение 3 способов

| Способ | Простота | Гибкость | Для чего | Файл |
|--------|----------|----------|---------|------|
| **Hardcoded** | ⭐⭐⭐⭐⭐ | ⭐ | Разработка на эмуляторе | `constants.dart` |
| **Settings Screen** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Production / Разработка | `settings_screen.dart` ✅ |
| **QR Code** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Production с TA | `qr_config_screen.dart` |

---

## 🚀 Как вбить Settings Screen в приложение

### Шаг 1: Добавить в pubspec.yaml (если нужна QR поддержка)

```yaml
dependencies:
  qr_code_scanner: ^1.0.1  # опционально
```

### Шаг 2: Добавить Settings в навигацию

`lib/main.dart`:

```dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    // ...
  }
}
```

### Шаг 3: Добавить кнопку в меню

Пример в главном меню / AppBar:

```dart
AppBar(
  title: const Text('АСУТП Tasks'),
  actions: [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, '/settings'),
    ),
  ],
)
```

### Шаг 4: Инициализировать ApiClient при старте

`lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.initialize();  // ← Добавьте это
  runApp(const AsutpTasksApp());
}
```

---

## 🔄 Как работает сохранение URL

```
1. Первый запуск приложения
   ↓
2. main.dart вызывает ApiClient.initialize()
   ↓
3. ApiClient загружает URL из SharedPreferences
   (если нет → использует ApiConfig.baseUrl)
   ↓
4. Пользователь открывает Settings
   ↓
5. Вводит новый URL (например: http://192.168.1.100:8080/api/v1)
   ↓
6. ApiClient.testConnection() проверяет доступность
   ↓
7. Если OK → URL сохраняется в SharedPreferences
   ↓
8. Все последующие запросы используют новый URL
   ↓
9. При закрытии/открытии приложения URL восстанавливается
```

---

## 📝 Примеры URL для разных сценариев

```dart
// 1. Android эмулятор (по умолчанию)
'http://10.0.2.2:8080/api/v1'

// 2. iOS симулятор на Mac
'http://localhost:8080/api/v1'

// 3. Реальное устройство + локальный Ubuntu сервер
'http://192.168.1.100:8080/api/v1'

// 4. Production с доменом (Caddy + Let's Encrypt)
'https://api.example.com/api/v1'

// 5. Production с IP + самоподписанный сертификат
'https://1.2.3.4/api/v1'

// 6. Localhost из настроек скрипта
'http://my-server.local:8080/api/v1'
```

---

## ⚡ Быстрый старт

```bash
# 1. Файлы уже созданы/обновлены:
#    - lib/screens/settings_screen.dart  ✅ (новый)
#    - lib/core/api_client.dart          ✅ (обновлён)
#    - lib/main.dart                     ✅ (обновлён)
#    - lib/core/constants.dart           ✅ (обновлён)

# 2. Запустить приложение
cd apcs_system
flutter clean
flutter pub get
flutter run

# 3. Открыть Settings (кнопка с ⚙️ иконкой)

# 4. Ввести IP/домен сервера

# 5. Проверить подключение
```

---

## 🐛 Если что-то не работает

### "Ошибка подключения к серверу"

```dart
// Проверить URL в constants.dart
ApiConfig.baseUrl  // Should be valid

// Проверить, что сервер работает
curl http://localhost:8080/api/v1/references/categories
```

### "URL не сохранился"

```dart
// SharedPreferences может требовать инициализации
// Убедитесь что вызвали:
await ApiClient.initialize();  // в main()
```

### "Всё ещё использует старый URL"

```bash
# Очистить приложение
flutter clean
flutter pub get
flutter run

# Или удалить SharedPreferences в коде:
await ServerSettings.clearServerUrl();
```

---

## ✅ Финальный чек-лист

- [ ] Файл `lib/screens/settings_screen.dart` добавлен
- [ ] Файл `lib/core/api_client.dart` обновлён
- [ ] Файл `lib/main.dart` инициализирует ApiClient
- [ ] Settings экран добавлен в навигацию
- [ ] Кнопка Settings добавлена в UI
- [ ] `flutter run` — приложение запускается
- [ ] Settings открывается, можно менять URL
- [ ] URL сохраняется между перезапусками

---

**Готово! 🚀 Теперь можно менять сервер прямо из приложения без перекомпиляции.**
