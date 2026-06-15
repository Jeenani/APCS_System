# АСУТП Tasks

Система управления задачами для службы АСУТП. Backend на Go (Gin + Ent ORM), мобильное приложение на Flutter, PostgreSQL в Docker.

## Быстрый старт

Сервер:
```bash
cd server && go run ./cmd/server/
# или
docker-compose up -d
```
API: `http://localhost:8080/api/v1`

Flutter:
```bash
cd apcs_system
flutter run
```

Перед запуском отредактируйте `apcs_system/lib/config/environment.dart` — укажите IP сервера.

## Требования

- Go 1.23+
- PostgreSQL 16 (или Docker)
- Flutter 3.11+

## Структура

```
server/          # Go REST API
apcs_system/     # Flutter приложение
database/        # PostgreSQL схема
docker-compose.yml
deploy.sh        # Деплой на сервер
```

## Роли

- `admin` — полный доступ
- `chief_engineer` — создает задачи, контролирует
- `asutp_chief` — создает подзадачи, управляет выполнением
- `engineer` — выполняет задачи
- `operator` — предлагает исполнителей в подзадачи

## Деплой

```bash
cp server/.env.example server/.env
# Заполните .env (SMTP, JWT_SECRET=<JWT_SECRET>, DB_PASSWORD)

chmod +x deploy.sh
./deploy.sh
```

Для HTTPS отредактируйте `Caddyfile` (см. `docker-compose.prod.yml`).

## Что реализовано

Backend:
- JWT авторизация
- CRUD задач с подзадачами
- Ролевая модель
- Назначение исполнителей (с одобрением)
- KPI и архивация
- Email-уведомления (SMTP)

Flutter:
- Авторизация
- Список задач с фильтрами
- Детали, редактирование, подзадачи
- Уведомления
- Экспорт CSV

## Настройка

1. Заполните `server/.env` (шаблон в `.env.example`)
2. Укажите API URL в `apcs_system/lib/config/environment.dart`
3. Для релиза APK: `build_release_apk.bat`
