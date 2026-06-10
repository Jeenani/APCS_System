#!/bin/bash
# ============================================
# АСУТП Tasks — Запуск Docker (Linux/Mac)
# ============================================

set -e

echo "============================================"
echo "   АСУТП Tasks — Docker Compose"
echo "============================================"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Проверка Docker
echo -n "[1/3] Проверяем Docker... "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Docker не установлен!${NC}"
    echo "Установите Docker: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Проверка Docker Compose
echo -n "[2/3] Проверяем Docker Compose... "
if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Docker Compose не установлен!${NC}"
    echo "Установите Docker Compose: https://docs.docker.com/compose/install"
    exit 1
fi

cd "$(dirname "$0")"

# Меню команд
case "${1:-up}" in
    up)
        echo "[3/3] Запускаем контейнеры..."
        echo ""
        docker compose up -d
        echo ""
        echo -e "${GREEN}✓ Контейнеры запущены!${NC}"
        echo ""
        sleep 2
        echo "Статус:"
        docker compose ps
        echo ""
        echo -e "${BLUE}API доступен на: http://localhost:8080/api/v1${NC}"
        echo -e "${BLUE}PostgreSQL на: localhost:5432${NC}"
        echo ""
        echo "Логи сервера:"
        docker compose logs -f server
        ;;
    
    down)
        echo "Останавливаем контейнеры..."
        docker compose down
        echo -e "${GREEN}✓ Контейнеры остановлены${NC}"
        ;;
    
    logs)
        docker compose logs -f server
        ;;
    
    ps)
        docker compose ps
        ;;
    
    rebuild)
        echo "Пересобираем образы..."
        docker compose down -v
        docker compose build --no-cache
        docker compose up -d
        echo -e "${GREEN}✓ Готово!${NC}"
        docker compose logs -f server
        ;;
    
    clean)
        echo -e "${YELLOW}⚠ Удаляем все контейнеры и volumes (БД будет удалена!)${NC}"
        read -p "Вы уверены? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down -v
            echo -e "${GREEN}✓ Очищено${NC}"
        fi
        ;;
    
    *)
        echo "Использование:"
        echo "  $0 up              Запустить контейнеры"
        echo "  $0 down            Остановить контейнеры"
        echo "  $0 logs            Показать логи сервера"
        echo "  $0 ps              Статус контейнеров"
        echo "  $0 rebuild         Пересобрать образы и запустить"
        echo "  $0 clean           Удалить контейнеры и volumes"
        ;;
esac
