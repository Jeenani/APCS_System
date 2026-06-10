# 🔒 HTTPS с Caddy — Полный гайд

## Что такое Caddy?

**Caddy** — это современный веб-сервер с:
- ✅ Автоматическим HTTPS (Let's Encrypt)
- ✅ Reverse proxy для Go сервера
- ✅ Сжатием (gzip) ответов
- ✅ Управлением сертификатами
- ✅ Логированием

---

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
```

**Результат:**
- ✅ API доступен на `https://api.example.com/api/v1`
- ✅ SSL сертификат автоматический (Let's Encrypt)
- ✅ Redirects HTTP → HTTPS
- ✅ Сжатие gzip включено

**Шаг 3: Обновить Flutter приложение**

```dart
// apcs_system/lib/core/constants.dart

class ApiConfig {
  static const String baseUrl = 'https://api.example.com/api/v1';
}
```

Затем:
```bash
cd apcs_system
flutter clean
flutter pub get
flutter run
```

---

### **Сценарий 3: VPS без домена (IP + самоподписанный сертификат)**

Если не хотите покупать домен, используйте IP адрес:

**Caddyfile:**

```caddy
192.168.1.100:443 {
  tls internal {
    on-demand
  }
  reverse_proxy localhost:8080
  encode gzip
}
```

**Запуск:**

```bash
docker-compose -f docker-compose.prod.yml up -d
```

**Flutter:**

```dart
class ApiConfig {
  // Самоподписанный сертификат = игнорировать ошибки SSL (опасно!)
  static const String baseUrl = 'https://192.168.1.100/api/v1';
}
```

⚠️ **Важно:** Для мобильного приложения нужна специальная конфигурация для самоподписанных сертификатов.

---

## 🚀 Команды управления Caddy

```bash
# Запустить Caddy с текущей конфигурацией
docker-compose -f docker-compose.prod.yml up -d caddy

# Показать логи Caddy
docker-compose -f docker-compose.prod.yml logs -f caddy

# Перезагрузить конфигурацию (без downtime)
docker exec asutp_caddy caddy reload --config /etc/caddy/Caddyfile

# Остановить Caddy
docker-compose -f docker-compose.prod.yml down

# Удалить все сертификаты и кэш
docker-compose -f docker-compose.prod.yml down -v
```

---

## 🔐 Безопасность

### Проверить SSL сертификат

```bash
# На сервере
curl -v https://api.example.com/api/v1/references/categories

# Проверить детали сертификата
openssl s_client -connect api.example.com:443 -servername api.example.com
```

### Обновление сертификата

Caddy **автоматически** обновляет сертификаты за 30 дней до истечения.

Логи обновления:
```bash
docker-compose logs caddy | grep "Renew"
```

---

## 📊 Архитектура с Caddy

```
┌─────────────────────┐
│  Flutter Mobile     │
│  https://api.ex.com │
└──────────┬──────────┘
           │ HTTPS
           ▼
┌─────────────────────┐
│   Caddy (443)       │
│ - SSL/TLS          │
│ - Reverse Proxy    │
│ - Gzip Compress    │
└──────────┬──────────┘
           │ HTTP (внутренняя сеть)
           ▼
┌─────────────────────┐
│ Go Server (8080)    │
│ - REST API          │
│ - Business Logic    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PostgreSQL (5432)  │
└─────────────────────┘
```

---

## 🐛 Troubleshooting Caddy

### Ошибка: "ACME challenge failed"

```
Error: acme: error: urn:acme:error:dns -> DNS problem
```

**Решение:**
1. Проверить DNS: `nslookup api.example.com`
2. Проверить брандмауэр: открыты ли порты 80 и 443
3. Проверить сертификат Let's Encrypt статус

```bash
# Проверить диагностику Let's Encrypt
curl https://certs.certbot.org/live/api.example.com/
```

### Ошибка: "connection refused"

```
Error: proxyprefix="reverse_proxy" -> localhost:8080: connection refused
```

**Решение:**
1. Проверить, запущен ли Go сервер: `docker-compose ps`
2. Проверить сеть: `docker network ls`
3. Проверить логи сервера: `docker-compose logs server`

### Ошибка: "port 80 already in use"

```
Error: listen tcp :80: bind: address already in use
```

**Решение:**

```bash
# Найти процесс на порту 80
sudo lsof -i :80

# Остановить его или использовать другой порт
docker-compose -f docker-compose.prod.yml down
```

---

## 📌 Рекомендации

### Для локальной разработки:
```bash
# БЕЗ Caddy — просто docker-compose
docker-compose up -d
# API: http://localhost:8080/api/v1
```

### Для production:
```bash
# С Caddy + HTTPS
docker-compose -f docker-compose.prod.yml up -d
# API: https://api.example.com/api/v1
```

### Проверка конфигурации Caddy:

```bash
# Синтаксис правильный?
docker run -it --rm caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile

# Перед тем как запустить
docker-compose config
```

---

## 🎯 Минимальный Caddy setup

Если просто нужно скрыть порт 8080 за 80/443:

```caddy
example.com {
  reverse_proxy localhost:8080
  encode gzip
}
```

Это всё! Caddy автоматически:
- ✅ Получит SSL сертификат от Let's Encrypt
- ✅ Обновит его перед истечением
- ✅ Перенаправит HTTP → HTTPS
- ✅ Сожмёт ответы

---

## 📚 Документация

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Compose](https://docs.docker.com/compose/)

**Готово! 🚀**
