#!/bin/bash
# ============================================
# АСУТП Tasks — Скрипт деплоя на production
# ============================================
# Использование:
#   chmod +x deploy.sh
#   ./deploy.sh
#
# Важно: этот скрипт НЕ удаляет volumes с данными
# (БД и сертификаты Caddy сохраняются)
# ============================================

set -e

echo "=== Обновление кода ==="
git pull

echo "=== Пересборка и запуск только сервера (Caddy и Postgres не трогаем) ==="
docker compose -f docker-compose.prod.yml build --no-cache server
docker compose -f docker-compose.prod.yml up -d --no-deps server

echo "=== Проверка статуса ==="
sleep 5
docker ps

echo "=== Готово ==="
echo "Сервер: http://<IP>:8080"
echo "Health: http://<IP>:8080/health"
