# 🚀 БЫСТРАЯ НАСТРОЙКА UBUNTU

## Сценарий 1: Docker (самый простой!)

```bash
# 1. Установить зависимости
sudo chmod +x setup_ubuntu.sh
sudo ./setup_ubuntu.sh

# 2. Запустить контейнеры
chmod +x start_docker.sh
./start_docker.sh up

# ✅ API готов на http://localhost:8080/api/v1
```

## Сценарий 2: Локально (для разработки)

```bash
# 1. Установить Go + PostgreSQL
sudo chmod +x setup_ubuntu.sh
sudo ./setup_ubuntu.sh

# 2. Создать БД
sudo -u postgres createdb asutp_tasks
sudo -u postgres psql asutp_tasks < database/schema.sql

# 3. Запустить сервер
chmod +x start_server.sh
./start_server.sh

# ✅ API готов на http://localhost:8080/api/v1
```

## Подключить Flutter приложение

### Вариант A: IP адрес

```bash
# 1. Найти IP сервера
hostname -I
# Вывод: 192.168.1.100

# 2. Обновить в Flutter (apcs_system/lib/core/constants.dart)
# Замените:
# static const String baseUrl = 'http://192.168.1.100:8080/api/v1';

# 3. Или использовать интерактивный конфигуратор
chmod +x configure_flutter.sh
./configure_flutter.sh
```

### Вариант B: Hostname

```bash
# 1. Найти hostname
hostname
# Вывод: my-server

# 2. Использовать в Flutter
# static const String baseUrl = 'http://my-server.local:8080/api/v1';
```

## 📋 Тестовые учётные данные

- **Email**: ivan.petrov@mail.com
- **Пароль**: __seed_pass__

---

## 📁 Файлы после обновления

✅ `README_COMPLETE.md` — Полная документация (установка, API, troubleshooting)  
✅ `README.md` — Краткое введение  
✅ `start_server.sh` — Запуск Go сервера на Linux  
✅ `start_docker.sh` — Управление Docker контейнерами  
✅ `setup_ubuntu.sh` — Автоматическая установка на Ubuntu  
✅ `configure_flutter.sh` — Интерактивная настройка API URL  
✅ `apcs_system/lib/core/constants.dart` — Обновлена с комментариями  
✅ `.gitignore` — Улучшен для всех компонентов  
✅ `server/.gitignore` — Уточнен с защитой .env  

---

## ✅ Что решено

### ✓ Сервер на Ubuntu
Go сервер **100% совместим** с Ubuntu. Оба варианта готовы:
- Локальная установка (Go + PostgreSQL вручную)
- Docker (всё в контейнерах)

### ✓ Подключение Flutter
Обновлена конфигурация с поддержкой разных окружений:
- Android эмулятор → `10.0.2.2:8080`
- iOS симулятор → `localhost:8080`
- Реальное устройство/Ubuntu → IP или hostname

Добавлен конфигуратор `configure_flutter.sh` для удобной смены URL.

### ✓ .gitignore
Проверен и расширен:
- ✅ Защита `.env` файлов (credentials никогда не коммитятся)
- ✅ Все специфичные для Flutter/Go файлы
- ✅ Временные файлы, логи, build-артефакты
- ✅ IDE файлы (.vscode, .idea)
- ✅ OS-специфичные файлы (.DS_Store, Thumbs.db)

### ✓ Документация
**README_COMPLETE.md** содержит:
- 🏗️ Архитектура проекта
- ⚡ Быстрый старт
- 🐧 Инструкции для Ubuntu
- 📱 Подключение Flutter приложения
- 🔌 API документация
- 🗄️ Схема БД
- 🐛 Troubleshooting
- 🚀 Production deployment

---

## 🎯 Как использовать скрипты

```bash
# Сделать исполняемыми
chmod +x *.sh

# Linux/Mac
./start_server.sh           # Запустить Go сервер
./start_docker.sh up        # Запустить Docker
./start_docker.sh logs      # Показать логи
./start_docker.sh down      # Остановить Docker
./setup_ubuntu.sh           # Установить зависимости
./configure_flutter.sh      # Настроить Flutter API URL
```

---

## 🔐 Важно: Защита credentials

**`.env` файлы никогда не коммитятся!**

Если случайно закоммитили:
```bash
git rm --cached server/.env
git commit -m "Remove .env from history"

# Переписать всю историю (опасно!)
# git filter-branch --tree-filter 'rm -f server/.env'
```

---

## 📝 Следующие шаги

1. **Для быстрого старта**: `sudo ./setup_ubuntu.sh`
2. **Для Docker**: `./start_docker.sh up`
3. **Настроить Flutter**: `./configure_flutter.sh`
4. **Полная информация**: Смотрите `README_COMPLETE.md`

**Готово! 🚀**
