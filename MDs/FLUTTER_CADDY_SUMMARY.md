# 📋 ФИНАЛЬНЫЙ ОТВЕТ: Flutter API + Caddy

## 📱 Как в Flutter сделать динамический IP/домен?

### **✅ Решение: Settings Screen + SharedPreferences**

**Что сделал:**

1. **Создал Settings экран** (`lib/screens/settings_screen.dart`)
   - Пользователь может менять IP/домен сервера
   - Автоматическая проверка доступности (`testConnection`)
   - Красивый UI с подсказками и примерами

2. **Обновил ApiClient** (`lib/core/api_client.dart`)
   - Теперь использует динамический URL из SharedPreferences
   - Метод `ApiClient.initialize()` загружает сохранённый URL при старте

3. **Обновил main.dart** (`lib/main.dart`)
   - Инициализирует ApiClient при запуске приложения
   - Загружает сохранённый URL

**Как это работает:**

```
1. Первый запуск приложение 
   → использует baseUrl из constants.dart (10.0.2.2:8080)

2. Пользователь откры Settings
   → вводит новый URL (например: 192.168.1.100:8080)

3. Нажимает "Сохранить"
   → ApiClient проверяет доступность
   → если OK → сохраняет в SharedPreferences

4. При следующем запуске
   → ApiClient загружает сохранённый URL
   → использует его для всех запросов

5. Пользователь может менять сервер когда угодно
   → без перекомпиляции приложения ✅
```

**Преимущества:**
- ✅ Нет hardcoded адресов
- ✅ Пользователь может менять сервер в приложении
- ✅ Поддерживает Android, iOS, Windows, Linux, Web
- ✅ Работает с IP, hostname и доменами
- ✅ Работает с HTTP и HTTPS
- ✅ Сохраняется между запусками

---

### **Как использовать Settings**

**В навигации приложения:**

```dart
// main.dart
onGenerateRoute: (settings) {
  switch (settings.name) {
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    // ... остальные маршруты
  }
}
```

**Кнопка в AppBar:**

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

**Примеры URL которые можно вводить:**

| Сценарий | URL |
|----------|-----|
| Android эмулятор | `http://10.0.2.2:8080/api/v1` |
| iOS симулятор | `http://localhost:8080/api/v1` |
| Реальное устройство + локальный сервер | `http://192.168.1.100:8080/api/v1` |
| Production с доменом (HTTPS) | `https://api.example.com/api/v1` |

---

## 🔒 Caddy — нужен ли?

### **Краткий ответ:**

| Сценарий | Нужен ли? | Почему |
|----------|----------|-------|
| Локальная разработка (Windows/Mac) | ❌ Нет | Прямое подключение OK |
| Docker на Ubuntu локально | ❌ Нет | Порт 8080 открыт, не нужен proxy |
| **Production с HTTPS** | **✅ Да** | Безопасность + автоматический SSL |

### **Когда нужен Caddy:**

```
Хотите:
- HTTPS (защищённое соединение)
- Автоматический SSL сертификат (Let's Encrypt)
- Скрыть порт 8080 за портом 443/80
- Production-ready setup
→ Используйте Caddy
```

### **Когда НЕ нужен Caddy:**

```
Работаете:
- Локально на Windows/Mac
- На Ubuntu тестово (HTTP OK)
- Через VPN (защита уже есть)
→ Caddy не обязателен
```

---

### **Если нужен Caddy:**

**Создал:**
1. ✅ `docker-compose.prod.yml` — конфиг для production с Caddy
2. ✅ `Caddyfile` — конфигурация Caddy для разных сценариев
3. ✅ `CADDY_HTTPS_GUIDE.md` — полный гайд по HTTPS

**Как запустить с Caddy:**

```bash
# Отредактировать Caddyfile, заменить example.com на ваш домен
nano Caddyfile

# Запустить с Caddy
docker-compose -f docker-compose.prod.yml up -d

# API будет на: https://api.example.com/api/v1
# SSL сертификат автоматический от Let's Encrypt
```

**В Flutter обновить:**

```dart
// constants.dart
class ApiConfig {
  static const String baseUrl = 'https://api.example.com/api/v1';
}
```

---

## 📊 Архитектура

### **БЕЗ Caddy (текущая для разработки):**

```
Flutter App
    ↓ HTTP
Go Server (8080)
    ↓
PostgreSQL
```

### **С Caddy (production):**

```
Flutter App
    ↓ HTTPS
Caddy (443)  ← SSL сертификат, reverse proxy
    ↓ HTTP (внутренняя сеть)
Go Server (8080)
    ↓
PostgreSQL
```

---

## ✅ Что я создал/обновил

### Для Flutter динамического конфига:

| Файл | Статус | Что сделано |
|------|--------|-----------|
| `lib/screens/settings_screen.dart` | ✅ Новый | Settings экран для смены сервера |
| `lib/core/api_client.dart` | ✅ Обновлён | Динамический URL + testConnection |
| `lib/main.dart` | ✅ Обновлён | Инициализация ApiClient |
| `FLUTTER_API_CONFIG.md` | ✅ Новый | Полный гайд |

### Для HTTPS с Caddy:

| Файл | Статус | Что сделано |
|------|--------|-----------|
| `docker-compose.prod.yml` | ✅ Новый | Production конфиг с Caddy |
| `Caddyfile` | ✅ Новый | 4 варианта конфигурации |
| `CADDY_HTTPS_GUIDE.md` | ✅ Новый | Полный гайд по Caddy + HTTPS |

---

## 🚀 Быстрый старт

### **1. Settings Screen (3 минуты)**

```bash
cd apcs_system
flutter clean
flutter pub get
flutter run

# В приложении: иконка ⚙️ → Settings
# Вводите IP/домен и сохраняйте
```

### **2. Caddy (5 минут, если нужен)**

```bash
# Отредактировать Caddyfile
# Заменить example.com на ваш домен

docker-compose -f docker-compose.prod.yml up -d

# Проверить
curl https://api.example.com/api/v1/references/categories
```

---

## 📌 Рекомендации

### **Для разработки:**
```
✅ Используйте Settings Screen (уже готов)
❌ Caddy не нужен
🎯 Все URL будут сохранены в приложении
```

### **Для production:**
```
✅ Используйте Settings Screen (для пользователей)
✅ Используйте Caddy (для HTTPS)
✅ Используйте QR код для onboarding (опционально)
🎯 Безопасно и масштабируемо
```

---

## 🎯 Итог

| Вопрос | Ответ |
|--------|-------|
| **Как сделать динамический IP/домен в Flutter?** | ✅ Settings Screen + SharedPreferences (уже готов) |
| **Нужен ли Caddy?** | ✅ Да, для production HTTPS. Нет, для локальной разработки |
| **Все ли файлы готовы?** | ✅ Да, всё создано и обновлено |
| **Как начать использовать?** | ✅ `flutter run` и откройте Settings в приложении |

---

**Готово! 🚀 Теперь приложение полностью гибко настраивается без перекомпиляции!**

Для деталей смотрите:
- 📱 [`FLUTTER_API_CONFIG.md`](FLUTTER_API_CONFIG.md) — гайд по Settings
- 🔒 [`CADDY_HTTPS_GUIDE.md`](CADDY_HTTPS_GUIDE.md) — гайд по HTTPS
- 📖 [`README_COMPLETE.md`](README_COMPLETE.md) — полная документация
