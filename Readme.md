# 📊 АСУТП Tasks — Система управления задачами

**Go REST API + Flutter приложение + PostgreSQL + Docker**

---

## ⚡ Быстрый старт

### 🖥️ **Сервер (Windows/Mac/Ubuntu)**

```bash
# Локально
cd server && go run ./cmd/server/

# Или Docker
docker-compose up -d
```

**API:** `http://localhost:8080/api/v1`  
**Тестовые данные:** `ivan.petrov` / `__seed_pass__`

---
## 🏗️ Запуск сервера

### Вариант 1: Docker (рекомендуется)
```bash
docker-compose up -d
# API: http://localhost:8080/api/v1
```

### Вариант 2: Локально
```bash
cd server
go run ./cmd/server/
# API: http://localhost:8080/api/v1
```

### Вариант 3: Ubuntu
```bash
cd ~
sudo chmod +x *.sh
./setup_ubuntu.sh     # установка
./start_docker.sh up  # запуск
# или: ./start_server.sh
```


## 📍 Три сценария использования

### **Сценарий 1: Локальное тестирование (БЕЗ Caddy)**

```bash
# Просто запустите текущий docker-compose
docker-compose up -d

# API доступен на: http://localhost:8080/api/v1
```

**Когда использовать:**
- Локальная разработка на Windows/Mac
- Мобильное приложение на эмуляторе/симуляторе

---

### **Сценарий 2: Ubuntu + Caddy (с HTTPS)**

**Требования:**
- Доменное имя (например `api.example.com`)
- VPS/сервер с открытыми портами 80 и 443
- DNS A запись, указывающая на IP сервера

**Шаг 1: Обновить Caddyfile**

Отредактируйте `Caddyfile`:

```caddy
# Замените example.com на ваш домен
example.com, www.example.com {
  reverse_proxy localhost:8080 {
    header_up Host {http.request.host}
    header_up X-Forwarded-For {http.request.remote.host}
  }
  encode gzip
}
```

**Шаг 2: Запустить Docker Compose с Caddy**

```bash
# Включить Caddy в docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Проверить статус
docker-compose logs -f caddy

# Проверить доступность
curl https://api.example.com/api/v1/references/categories

docker compose -f docker-compose.prod.yml build --no-cache server
docker compose -f docker-compose.prod.yml up -d server
```

**Результат:**
- ✅ API доступен на `https://api.example.com/api/v1`
- ✅ SSL сертификат автоматический (Let's Encrypt)
- ✅ Redirects HTTP → HTTPS
- ✅ Сжатие gzip включено


### 📱 **Flutter приложение**

```bash
cd apcs_system

# Конфигурация сервера
# Отредактируйте: lib/config/environment.dart
# Примеры:
#   - Android эмулятор: http://10.0.2.2:8080/api/v1
#   - Real device: http://192.168.1.100:8080/api/v1
#   - Production: https://api.example.com/api/v1

# Запустить на эмуляторе/устройстве
flutter run

# Собрать Release APK (с подписью)
..\build_release_apk.bat
flutter build apk --release --split-per-abi
flutter build apk --release --split-per-abi
```

**Выходной файл:** `asutp-tasks-release.apk`

---

## 📚 Документация

| Документ | Для чего |
|----------|---------|
| [README_COMPLETE.md](README_COMPLETE.md) | Полная документация (архитектура, API, Troubleshooting) |
| [UBUNTU_SETUP_QUICK.md](UBUNTU_SETUP_QUICK.md) | Установка на Ubuntu (локально или Docker) |
| [FLUTTER_ENV_CONFIG.md](FLUTTER_ENV_CONFIG.md) | Конфигурация Flutter (.env параметры) |

---

## 📂 Структура

```
ASUTP_Praktik/
├── server/              # Go REST API (Gin + Ent ORM)
├── apcs_system/         # Flutter приложение
├── database/            # PostgreSQL схема
├── docker-compose.yml   # Docker контейнеры
├── build_release_apk.bat # Сборка APK релиза
└── *.md                 # Документация
```

---

## 🛠️ Требования

- **Go** 1.23+ — [golang.org/dl](https://golang.org/dl)
- **PostgreSQL** 16 — [postgresql.org](https://www.postgresql.org/download)
- **Flutter** 3.11+ — [flutter.dev](https://flutter.dev)
- **Docker** (опционально) — [docker.com](https://www.docker.com)

---

## 🚀 Что реализовано

✅ **Backend:**
- REST API с JWT авторизацией
- 16 таблиц (Ent ORM)
- Автомиграция + seed-данные
- CORS для мобильных клиентов

✅ **Frontend:**
- Вход/Регистрация
- Управление задачами
- История изменений
- Уведомления
- Поиск и фильтрация

✅ **DevOps:**
- Docker & Docker Compose
- Автомиграция БД
- Health checks
- Persistent volumes

---

## 📝 Следующие шаги

1. **Конфигурация:** Отредактируйте `apcs_system/lib/config/environment.dart`
2. **Сервер:** `docker-compose up -d` или `cd server && go run ./cmd/server/`
3. **Приложение:** `cd apcs_system && flutter run`
4. **Release APK:** `build_release_apk.bat`
5. **Подробнее:** Смотрите [README_COMPLETE.md](README_COMPLETE.md)

**
