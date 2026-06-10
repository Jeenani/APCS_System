#!/bin/bash
# ============================================
# АСУТП Tasks — Запуск сервера (Linux/Mac)
# ============================================

set -e

echo "============================================"
echo "   АСУТП Tasks — Запуск Go сервера"
echo "============================================"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Проверка Go
echo -n "[1/4] Проверяем Go... "
if command -v go &> /dev/null; then
    go_version=$(go version | awk '{print $3}')
    echo -e "${GREEN}✓ $go_version${NC}"
else
    echo -e "${RED}✗ Go не установлен!${NC}"
    echo "Установите Go: https://golang.org/dl"
    exit 1
fi

# Проверка PostgreSQL
echo -n "[2/4] Проверяем PostgreSQL... "
if command -v psql &> /dev/null; then
    psql_version=$(psql --version | awk '{print $3}')
    echo -e "${GREEN}✓ версия $psql_version${NC}"
else
    echo -e "${RED}✗ PostgreSQL не установлен!${NC}"
    echo "Установите PostgreSQL: https://www.postgresql.org/download"
    exit 1
fi

# Проверка БД
echo -n "[3/4] Проверяем базу данных... "
if PGPASSWORD=${DB_PASSWORD:-postgres} psql -h ${DB_HOST:-localhost} -U ${DB_USER:-postgres} -l | grep -q asutp_tasks; then
    echo -e "${GREEN}✓ БД asutp_tasks существует${NC}"
else
    echo -e "${YELLOW}⚠ БД не существует, создаём...${NC}"
    PGPASSWORD=${DB_PASSWORD:-postgres} createdb -h ${DB_HOST:-localhost} -U ${DB_USER:-postgres} asutp_tasks
    PGPASSWORD=${DB_PASSWORD:-postgres} psql -h ${DB_HOST:-localhost} -U ${DB_USER:-postgres} -d asutp_tasks -f ./database/schema.sql
    echo -e "${GREEN}✓ БД создана и инициализирована${NC}"
fi

# Переходим в папку сервера
echo "[4/4] Переходим в папку сервера..."
cd "$(dirname "$0")/server"

# Загружаем зависимости
echo ""
echo "Загружаем зависимости..."
go mod download
go mod tidy

# Запускаем сервер
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Сервер запускается на :8080${NC}"
echo -e "${GREEN}   API: http://localhost:8080/api/v1${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

go run ./cmd/server/
