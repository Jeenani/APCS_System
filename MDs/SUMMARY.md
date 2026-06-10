# 🚀 АСУТП Tasks — Финальный гайд

## 📋 Быстрая справка

### Конфигурация (ГЛАВНОЕ!)

**Отредактировать:**
```
apcs_system/lib/config/environment.dart
```

**Выбрать API URL:**
- `http://10.0.2.2:8080/api/v1` — Android эмулятор
- `http://localhost:8080/api/v1` — iOS симулятор (Mac)
- `http://192.168.1.100:8080/api/v1` — Real device / Ubuntu (измените IP)
- `https://api.example.com/api/v1` — Production

**Выбрать режим:**
- `enableServerSettings = false` — только конфиг (production)
- `enableServerSettings = true` — конфиг + Settings экран (разработка)

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

---

## 📱 Запуск приложения

```bash
cd apcs_system

# Конфигурировать (важно!)
# Отредактируйте lib/config/environment.dart

# Запустить на эмуляторе/устройстве
flutter run

# Собрать Release APK (с подписью)
cd ..
build_release_apk.bat
# Выходной файл: asutp-tasks-release.apk
```

---

## 🔐 Тестовые учётные данные

- **Email:** `ivan.petrov@mail.com`
- **Пароль:** `__seed_pass__`

---

## 📚 Документация

| Файл | Для чего |
|------|---------|
| `README.md` | Главное меню (вы здесь) |
| `README_COMPLETE.md` | Полная документация |
| `UBUNTU_SETUP_QUICK.md` | Ubuntu (Docker/локально) |
| `FLUTTER_ENV_CONFIG.md` | Конфигурация Flutter |

---

## 🛠️ Полезные команды

### Flutter
```bash
cd apcs_system

flutter clean              # Очистить
flutter pub get            # Получить зависимости
flutter run                # Запустить на эмуляторе
flutter build apk          # Собрать debug APK
build_release_apk.bat      # Собрать release APK (Windows)
```

### Go Server
```bash
cd server

go mod download            # Получить зависимости
go run ./cmd/server/       # Запустить сервер
go build ./cmd/server/     # Собрать бинарник
```

### Docker
```bash
docker-compose up -d       # Запустить
docker-compose down        # Остановить
docker-compose logs -f     # Логи
docker-compose ps          # Статус контейнеров
```

### Database
```bash
# PostgreSQL
createdb asutp_tasks
psql -U postgres -d asutp_tasks < database/schema.sql

# Docker Compose автоматически создаёт БД
```

---

## 📊 Архитектура

```
Flutter App (iOS/Android)
    ↓ HTTP/REST + JWT
Go Server (Gin)
    ↓ TCP 5432
PostgreSQL 16
    ↓
Seed-data (2 пользователя, 4 задачи, 9 категорий)
```

---

## ✅ Что реализовано

**Backend:**
- ✅ REST API (16 endpoints)
- ✅ JWT авторизация
- ✅ 16 таблиц (Ent ORM)
- ✅ Автомиграция БД
- ✅ CORS для мобильных

**Frontend:**
- ✅ Вход/Регистрация
- ✅ Список задач
- ✅ Создание/редактирование
- ✅ История изменений
- ✅ Поиск и фильтрация
- ✅ Профиль пользователя

**DevOps:**
- ✅ Docker & Docker Compose
- ✅ Автомиграция
- ✅ Health checks
- ✅ Persistent volumes

---

## 🐛 Проблемы?

### Сервер не запускается
```bash
# Проверить PostgreSQL
sudo systemctl status postgresql

# Проверить порт 8080
sudo lsof -i :8080

# Docker логи
docker-compose logs server
```

### Flutter не подключается
```bash
# Проверить API URL
grep "apiBaseUrl" apcs_system/lib/config/environment.dart

# Проверить сервер работает
curl http://localhost:8080/api/v1/references/categories

# Пересобрать
flutter clean
flutter pub get
flutter run
```

### APK не собирается
```bash
# Очистить и заново
flutter clean
flutter pub get
build_release_apk.bat
```

---

## 📞 Полная справка

Для деталей смотрите:
- 📖 [README_COMPLETE.md](README_COMPLETE.md) — полная документация
- 🐧 [UBUNTU_SETUP_QUICK.md](UBUNTU_SETUP_QUICK.md) — Ubuntu инструкции
- ⚙️ [FLUTTER_ENV_CONFIG.md](FLUTTER_ENV_CONFIG.md) — конфигурация

---

## 🎯 Рекомендуемый порядок

1. **Конфигурировать:**
   ```
   apcs_system/lib/config/environment.dart
   ```

2. **Запустить сервер:**
   ```bash
   docker-compose up -d
   ```

3. **Запустить приложение:**
   ```bash
   cd apcs_system && flutter run
   ```

4. **Войти:**
   - Email: `ivan.petrov@mail.com`
   - Password: `__seed_pass__`

5. **Собрать APK (когда готово):**
   ```bash
   build_release_apk.bat
   ```

---

**Готово! 🚀 Приложение готово к использованию!**
