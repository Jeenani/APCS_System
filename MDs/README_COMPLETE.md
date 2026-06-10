# 📊 АСУТП Tasks — Система управления задачами для SCADA

Полнофункциональное приложение для управления производственными задачами с веб-сервером на Go, Flutter мобильным клиентом, PostgreSQL БД и Docker контейнеризацией.

---

## 📑 Содержание

- [Архитектура](#архитектура)
- [Быстрый старт](#быстрый-старт)
- [Установка на Ubuntu](#установка-на-ubuntu)
- [Подключение Flutter приложения](#подключение-flutter-приложения)
- [Разработка](#разработка)
- [API Документация](#api-документация)

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────┐
│                                         │
│   Flutter Mobile App (iOS/Android)      │
│   - State Management (Provider)          │
│   - JWT Authentication                   │
│   - Offline Support                      │
│                                         │
└────────────┬────────────────────────────┘
             │ HTTP/REST + JWT
             ▼
┌─────────────────────────────────────────┐
│                                         │
│   Go Server (Gin Framework)             │
│   - RESTful API (/api/v1)                │
│   - JWT & Session Management            │
│   - CORS для мобильных клиентов         │
│   - Docker-ready                        │
│                                         │
└────────────┬────────────────────────────┘
             │ TCP 5432
             ▼
┌─────────────────────────────────────────┐
│                                         │
│   PostgreSQL 16                         │
│   - 16 таблиц (Ent ORM)                 │
│   - Автомиграция                        │
│   - Seed-данные                         │
│                                         │
└─────────────────────────────────────────┘
```

**Компоненты:**

| Компонент | Технология | Версия | Назначение |
|-----------|-----------|--------|-----------|
| Backend | Go | 1.23+ | REST API сервер |
| ORM | Ent | 0.14.6 | ORM и миграции БД |
| Web Framework | Gin | 1.12 | HTTP маршруты и middleware |
| База Данных | PostgreSQL | 16 | Хранилище данных |
| Frontend | Flutter | 3.11+ | iOS/Android приложение |
| State Mgmt | Provider | 6.1 | Управление состоянием |
| Контейнеризация | Docker | - | Развёртывание |

---

## ⚡ Быстрый старт (локальная разработка Windows/Mac)

### Предварительные требования

- **Go** 1.23+ → [golang.org/dl](https://golang.org/dl)
- **PostgreSQL** 16 → [postgresql.org](https://www.postgresql.org/download)
- **Flutter** 3.11+ → [flutter.dev](https://flutter.dev/docs/get-started/install)
- **Git**

### Шаг 1: Подготовка базы данных

```bash
# Создать БД в PostgreSQL
createdb asutp_tasks

# Импортировать схему (Windows PowerShell)
psql -U postgres -d asutp_tasks -f .\database\schema.sql

# Или (Mac/Linux)
psql -U postgres -d asutp_tasks -f ./database/schema.sql
```

### Шаг 2: Запуск сервера

```bash
cd server

# Установить/обновить зависимости
go mod download
go mod tidy

# Запустить сервер
go run ./cmd/server/

# Сервер будет на http://localhost:8080/api/v1
# Автоматически выполнит миграцию и создаст тестовые данные
```

### Шаг 3: Запуск Flutter приложения

```bash
cd apcs_system

# Получить зависимости
flutter pub get

# Запустить на эмуляторе/устройстве
flutter run

# Тестовые учётные данные:
# Логин: ivan.petrov
# Пароль: __seed_pass__
```

**Готово!** Приложение подключится к серверу на `10.0.2.2:8080` (Android) или `localhost:8080` (iOS).

---

## 🐧 Установка на Ubuntu

### Сценарий 1: Локальная установка (для разработки)

#### Предварительные требования

```bash
# Ubuntu 20.04 LTS / 22.04 LTS / 24.04 LTS

sudo apt update
sudo apt install -y \
  postgresql-16 \
  postgresql-contrib-16 \
  golang-1.23 \
  git \
  curl \
  wget

# Добавить Go в PATH
export PATH=$PATH:/usr/lib/go-1.23/bin
echo 'export PATH=$PATH:/usr/lib/go-1.23/bin' >> ~/.bashrc
```

#### Установка

```bash
# 1. Создать директорию проекта
mkdir -p ~/asutp-tasks
cd ~/asutp-tasks

# 2. Клонировать репозиторий (или скопировать файлы)
git clone <your-repo-url> .
# или распаковать архив

# 3. Создать БД PostgreSQL
sudo -u postgres psql -c "CREATE DATABASE asutp_tasks;"

# 4. Импортировать схему
sudo -u postgres psql asutp_tasks < database/schema.sql

# 5. Запустить сервер
cd server
go mod download
go run ./cmd/server/

# Сервер запустится на http://localhost:8080/api/v1
```

#### Проверка сервера

```bash
# В отдельном терминале
curl http://localhost:8080/api/v1/references/categories

# Ответ:
# {"data":[...],"success":true}
```

---

### Сценарий 2: Docker (production-ready)

**Самый простой способ!** Всё работает в контейнерах.

#### Требования

- Docker 20.10+
- Docker Compose 2.0+

```bash
# Ubuntu
sudo apt install -y docker.io docker-compose

# Или установить Docker Desktop
```

#### Запуск

```bash
cd ~/asutp-tasks

# Запустить контейнеры (PostgreSQL + Go сервер)
docker-compose up -d

# Проверить статус
docker-compose ps

# Логи сервера
docker-compose logs -f server

# Проверить API
curl http://localhost:8080/api/v1/references/categories
```

#### Остановка

```bash
docker-compose down

# Удалить данные (если нужно)
docker-compose down -v
```

#### Структура Docker Compose

- **PostgreSQL** на порту `5432`
- **Go сервер** на порту `8080`
- **Volume** `pgdata` для персистентного хранилища БД
- Автоматический health-check и перезагрузка

---

## 📱 Подключение Flutter приложения

### Проблема: где находится сервер?

При разворачивании на разных платформах сервер может быть по разному адресу:

| Платформа | Адрес сервера |
|-----------|--------------|
| **Android эмулятор** | `http://10.0.2.2:8080/api/v1` |
| **iOS симулятор** | `http://localhost:8080/api/v1` |
| **Реальное устройство** | `http://<IP-СЕРВЕРА>:8080/api/v1` |
| **Ubuntu сервер** | `http://<IP-ИЛИ-HOSTNAME>:8080/api/v1` |

### Решение: обновить API URL

#### Вариант 1: Для локальной разработки (Windows/Mac)

Файл: `apcs_system/lib/core/constants.dart`

```dart
class ApiConfig {
  // Android эмулятор (значение по умолчанию)
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';
  
  // Для iOS симулятора замените на:
  // static const String baseUrl = 'http://localhost:8080/api/v1';
}
```

#### Вариант 2: Для реального Ubuntu сервера

**Найдите IP адрес сервера:**

```bash
# На Ubuntu сервере
hostname -I
# Вывод: 192.168.1.100

# Или hostname
hostname
# Вывод: my-server.local
```

**Обновите `constants.dart`:**

```dart
class ApiConfig {
  // Замените YOUR_IP_OR_HOSTNAME
  
  // Вариант A: по IP адресу
  static const String baseUrl = 'http://192.168.1.100:8080/api/v1';
  
  // Вариант B: по hostname (если сеть поддерживает)
  static const String baseUrl = 'http://my-server.local:8080/api/v1';
  
  // Вариант C: по публичному IP
  static const String baseUrl = 'http://your-public-ip:8080/api/v1';
}
```

**Затем запустите приложение:**

```bash
cd apcs_system
flutter pub get
flutter run
```

#### Вариант 3: Settings Screen (продвинутое решение)

Если нужна динамическая смена сервера (без перекомпиляции):

Создайте экран Settings с сохранением URL в SharedPreferences:

```dart
// lib/screens/settings_screen.dart
import 'package:shared_preferences/shared_preferences.dart';

class ServerSettings {
  static const String _key = 'server_url';
  
  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
  
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'http://10.0.2.2:8080/api/v1';
  }
}

// Использование в ApiClient:
static Future<Map<String, dynamic>> get(String path) async {
  final baseUrl = await ServerSettings.getServerUrl();
  final response = await http.get(
    Uri.parse('$baseUrl$path'),
    headers: _headers,
  );
  return _handleResponse(response);
}
```

---

## 🔧 Разработка

### Структура проекта

```
ASUTP_Praktik/
├── server/                    # Go REST API
│   ├── cmd/server/main.go     # Entry point
│   ├── internal/
│   │   ├── config/            # Configuration
│   │   ├── handler/           # Route handlers
│   │   ├── middleware/        # Auth middleware
│   │   └── seed/              # Тестовые данные
│   ├── ent/                   # Ent ORM (auto-generated)
│   ├── Dockerfile             # Docker image
│   ├── go.mod, go.sum         # Dependencies
│   └── .env                   # Configuration
│
├── apcs_system/               # Flutter приложение
│   ├── lib/
│   │   ├── main.dart          # Entry point
│   │   ├── core/
│   │   │   ├── constants.dart # API URLs, colors
│   │   │   └── api_client.dart# HTTP client
│   │   ├── models/            # Data models
│   │   ├── providers/         # Provider state
│   │   └── screens/           # UI screens
│   ├── pubspec.yaml           # Dependencies
│   └── test/                  # Tests
│
├── database/
│   └── schema.sql             # PostgreSQL schema
│
├── docker-compose.yml         # Контейнеризация
├── start_server.bat           # Запуск сервера (Windows)
└── README.md                  # Этот файл
```

### Запуск с горячей перезагрузкой

**Go сервер:**

```bash
cd server

# Установить air (hot reload)
go install github.com/cosmtrek/air@latest

# Запустить с hot reload
air
```

**Flutter приложение:**

```bash
cd apcs_system
flutter run
# Нажмите 'r' для hot reload, 'R' для hot restart
```

### Коммиты и правила

Используйте conventional commits:

```bash
git commit -m "feat(server): add task export endpoint"
git commit -m "fix(app): fix login form validation"
git commit -m "docs: update README with Ubuntu setup"
git commit -m "refactor(db): optimize task query"
```

---

## 🔌 API Документация

### Базовая информация

- **Base URL**: `http://localhost:8080/api/v1`
- **Content-Type**: `application/json`
- **Авторизация**: JWT Bearer Token

### Аутентификация

#### Регистрация

```bash
POST /auth/register

{
  "name": "Ivan Petrov",
  "email": "ivan@example.com",
  "password": "secure___seed_pass__"
}

# Response 201
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Ivan Petrov",
    "email": "ivan@example.com",
    "role": "user"
  }
}
```

#### Вход

```bash
POST /auth/login

{
  "email": "ivan.petrov@mail.com",
  "password": "__seed_pass__"
}

# Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "name": "Ivan Petrov",
      "email": "ivan.petrov@mail.com",
      "role": "operator"
    }
  }
}
```

#### Refresh Token

```bash
POST /auth/refresh

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}

# Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

### Задачи (Tasks)

#### Список задач

```bash
GET /tasks

# Headers
Authorization: Bearer <access_token>

# Response 200
{
  "success": true,
  "data": [
    {
      "id": 1,
      "title": "Проверить давление в резервуаре",
      "description": "Давление должно быть 2.5 атм",
      "priority": "high",
      "status": "open",
      "category": "system_monitoring",
      "assignee_id": 1,
      "created_at": "2024-06-10T10:30:00Z",
      "due_date": "2024-06-15T16:00:00Z"
    }
  ]
}
```

#### Создать задачу

```bash
POST /tasks

{
  "title": "Поправить датчик уровня",
  "description": "Датчик не показывает реальный уровень",
  "priority": "medium",
  "category": "maintenance",
  "due_date": "2024-06-20T18:00:00Z"
}

# Response 201
{
  "success": true,
  "data": {
    "id": 5,
    "title": "Поправить датчик уровня",
    ...
  }
}
```

#### Обновить задачу

```bash
PUT /tasks/:id

{
  "title": "Поправить датчик уровня (важно!)",
  "status": "in_progress",
  "progress": 50
}

# Response 200
{
  "success": true,
  "data": { ... }
}
```

#### Удалить задачу

```bash
DELETE /tasks/:id

# Response 204 (No Content)
```

### Справочники (References)

#### Приоритеты

```bash
GET /references/priorities

# Response 200
{
  "success": true,
  "data": [
    { "id": 1, "name": "high", "label": "Высокий" },
    { "id": 2, "name": "medium", "label": "Средний" },
    { "id": 3, "name": "low", "label": "Низкий" }
  ]
}
```

#### Категории

```bash
GET /references/categories

# Response 200
{
  "success": true,
  "data": [
    { "id": 1, "name": "system_monitoring", "label": "Мониторинг системы" },
    { "id": 2, "name": "maintenance", "label": "Техническое обслуживание" },
    ...
  ]
}
```

#### Статусы

```bash
GET /references/statuses

# Response 200
{
  "success": true,
  "data": [
    { "id": 1, "name": "open", "label": "Открыта" },
    { "id": 2, "name": "in_progress", "label": "В процессе" },
    { "id": 3, "name": "completed", "label": "Завершена" },
    { "id": 4, "name": "cancelled", "label": "Отменена" }
  ]
}
```

### Ошибки

```bash
# 400 Bad Request
{
  "success": false,
  "error": "Invalid input",
  "details": "Email already exists"
}

# 401 Unauthorized
{
  "success": false,
  "error": "Unauthorized",
  "details": "Invalid or expired token"
}

# 403 Forbidden
{
  "success": false,
  "error": "Forbidden",
  "details": "You don't have permission"
}

# 500 Internal Server Error
{
  "success": false,
  "error": "Internal server error"
}
```

---

## 🗄️ База данных

### Схема

16 таблиц, управляемых через Ent ORM:

**Core Tables:**
- `users` — Пользователи системы
- `tasks` — Производственные задачи
- `task_history` — История изменений задач
- `notifications` — Уведомления пользователей

**References:**
- `roles` — Роли (admin, operator, viewer)
- `priorities` — Приоритеты (high, medium, low)
- `task_statuses` — Статусы (open, in_progress, completed, cancelled)
- `task_categories` — Категории (system_monitoring, maintenance, etc.)
- `notification_types` — Типы уведомлений
- `export_types` — Форматы экспорта

**Configuration:**
- `notification_settings` — Настройки уведомлений пользователя
- `change_types` — Типы изменений
- `export_logs` — Логи экспорта
- `export_log_tasks` — Связь логов и задач
- `password_reset_tokens` — Токены для восстановления пароля
- `refresh_tokens` — Refresh токены авторизации

### Автомиграция

При запуске сервер автоматически:

1. ✅ Создаёт таблицы (если их нет)
2. ✅ Обновляет схему (если нужно)
3. ✅ Загружает seed-данные:
   - 2 пользователя (`ivan.petrov`, `maria.sidorova`)
   - 4 тестовые задачи
   - 9 категорий АСУТП

---

## 🔐 Безопасность

### JWT Tokens

- **Access Token**: действует 15 минут
- **Refresh Token**: действует 7 дней
- **Secret Key**: хранится в `.env`

### CORS

Сервер разрешает запросы со всех источников:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Origin, Content-Type, Authorization
```

### Passwords

- Пароли хешируются с `bcrypt`
- Никогда не передаются в ответах API

### Environment Variables

**Никогда** не коммитьте `.env` с реальными значениями!

```bash
# Перед коммитом
git rm --cached server/.env
git add server/.env.example
```

---

## 📋 Тестовые данные

### Пользователи

| Email | Пароль | Роль |
|-------|--------|------|
| `ivan.petrov@mail.com` | `__seed_pass__` | Operator |
| `maria.sidorova@mail.com` | `__seed_pass__` | Viewer |

### Задачи

4 задачи по разным категориям АСУТП (monitoring, maintenance, calibration, repair).

---

## 🐛 Troubleshooting

### Ошибка: "connection refused"

```
Ошибка: connect ECONNREFUSED 127.0.0.1:8080
```

**Решение:**
- Проверьте, запущен ли сервер: `curl http://localhost:8080/api/v1/references/categories`
- На Ubuntu: проверьте брандмауэр: `sudo ufw allow 8080`

### Ошибка: "database connection error"

```
Ошибка: could not connect to database
```

**Решение:**
- Проверьте PostgreSQL: `sudo systemctl status postgresql`
- Проверьте БД создана: `psql -U postgres -l | grep asutp_tasks`
- Проверьте `.env`: `DB_HOST`, `DB_USER`, `DB_PASSWORD`

### Flutter: "Failed to connect"

**Решение:**
1. Проверьте `constants.dart` → `ApiConfig.baseUrl`
2. Для Android: убедитесь используется `10.0.2.2`
3. Для реального устройства: используйте IP адрес сервера
4. На Ubuntu: найдите IP: `hostname -I`

### Docker: Контейнер не стартует

```bash
docker-compose logs server
docker-compose logs postgres
```

**Решение:**
- Проверьте порты: `sudo netstat -tulpn | grep -E :8080\|:5432`
- Удалите old containers: `docker-compose down -v`
- Запустите заново: `docker-compose up -d`

---

## 🚀 Production Deployment

### Подготовка

1. **Обновить переменные окружения:**

```bash
# server/.env
APP_MODE=production
JWT_SECRET=<JWT_SECRET>=your-very-secure-random-key-here
DB_SSLMODE=require
DB_PASSWORD=strong-password-here
```

2. **Включить HTTPS:**

Используйте nginx как reverse proxy с Let's Encrypt:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
    }
}
```

3. **Запустить с Docker:**

```bash
docker-compose -f docker-compose.yml up -d
```

4. **Мониторинг:**

```bash
docker-compose logs -f server
```

---

## 📚 Дополнительные ресурсы

- [Go Documentation](https://golang.org/doc)
- [Gin Framework](https://gin-gonic.com)
- [Ent ORM](https://entgo.io)
- [Flutter Documentation](https://flutter.dev/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs)

---

## 📄 Лицензия

MIT License © 2024 ASUTP Project

---

## 👥 Команда

Разработано как учебный проект в рамках практики по системам SCADA/АСУТП.

---

**Вопросы?** Проверьте раздел [Troubleshooting](#troubleshooting) или создайте Issue.
