#!/bin/bash
# ============================================
# АСУТП Tasks — Автоматическая установка на Ubuntu
# ============================================

set -e

echo "============================================"
echo "   АСУТП Tasks — Установка на Ubuntu"
echo "============================================"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Проверка прав администратора
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}✗ Скрипт требует права администратора (sudo)${NC}"
   echo "Запустите: sudo $0"
   exit 1
fi

# Определение версии Ubuntu
. /etc/os-release
echo "Обнаружена ОС: $PRETTY_NAME"
echo ""

# Выбор сценария
echo "Выберите вариант установки:"
echo "1) Локально (разработка)"
echo "2) Docker (production-ready)"
echo ""
read -p "Введите вариант (1 или 2): " VARIANT

case $VARIANT in
    1)
        echo ""
        echo "=== Установка локально ==="
        echo ""
        
        # Обновляем систему
        echo "[1/5] Обновляем систему..."
        apt update
        apt upgrade -y
        
        # Устанавливаем Go
        echo "[2/5] Устанавливаем Go..."
        apt install -y golang-1.23 golang-1.23-src golang-1.23-doc
        
        # Устанавливаем PostgreSQL
        echo "[3/5] Устанавливаем PostgreSQL..."
        apt install -y postgresql-16 postgresql-contrib-16
        
        # Запускаем PostgreSQL
        echo "[4/5] Запускаем PostgreSQL..."
        systemctl start postgresql
        systemctl enable postgresql
        
        # Добавляем Go в PATH
        echo "[5/5] Конфигурируем окружение..."
        echo 'export PATH=$PATH:/usr/lib/go-1.23/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
        source ~/.bashrc
        
        echo ""
        echo -e "${GREEN}✓ Установка завершена!${NC}"
        echo ""
        echo "Следующие шаги:"
        echo "1. Создайте БД: sudo -u postgres createdb asutp_tasks"
        echo "2. Импортируйте схему: sudo -u postgres psql asutp_tasks < database/schema.sql"
        echo "3. Запустите сервер: ./start_server.sh"
        echo ""
        ;;
    
    2)
        echo ""
        echo "=== Установка Docker ==="
        echo ""
        
        # Обновляем систему
        echo "[1/4] Обновляем систему..."
        apt update
        apt upgrade -y
        
        # Устанавливаем Docker
        echo "[2/4] Устанавливаем Docker..."
        apt install -y docker.io
        systemctl start docker
        systemctl enable docker
        
        # Устанавливаем Docker Compose
        echo "[3/4] Устанавливаем Docker Compose..."
        apt install -y docker-compose
        
        # Добавляем текущего пользователя в группу docker (опционально)
        echo "[4/4] Конфигурируем Docker..."
        if [[ -n "$SUDO_USER" ]]; then
            usermod -aG docker $SUDO_USER
            echo "⚠ Пользователь $SUDO_USER добавлен в группу docker"
            echo "  Запустите новую сессию для применения изменений"
        fi
        
        echo ""
        echo -e "${GREEN}✓ Установка завершена!${NC}"
        echo ""
        echo "Следующие шаги:"
        echo "1. Запустите контейнеры: ./start_docker.sh up"
        echo "2. API будет на http://localhost:8080/api/v1"
        echo ""
        ;;
    
    *)
        echo -e "${RED}✗ Неверный выбор${NC}"
        exit 1
        ;;
esac

echo "=== Дополнительная информация ==="
echo ""
echo "📖 Полная документация: README_COMPLETE.md"
echo "🔧 Конфигурация сервера: server/.env"
echo "📱 Подключение приложения: apcs_system/lib/core/constants.dart"
echo ""
echo "Вопросы? Смотрите Troubleshooting в README_COMPLETE.md"
