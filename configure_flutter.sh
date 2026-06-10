#!/bin/bash
# ============================================
# АСУТП Tasks — Утилита для настройки Flutter
# ============================================

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONSTANTS_FILE="apcs_system/lib/core/constants.dart"

show_menu() {
    echo ""
    echo "============================================"
    echo "   АСУТП Tasks — Конфигуратор Flutter"
    echo "============================================"
    echo ""
    echo "Выберите целевое окружение:"
    echo ""
    echo "1) Android эмулятор (локально)"
    echo "2) iOS симулятор (локально на Mac)"
    echo "3) По IP адресу (физ. устройство / Ubuntu)"
    echo "4) По hostname (локальная сеть)"
    echo "5) Показать текущую конфигурацию"
    echo "0) Выход"
    echo ""
}

update_api_url() {
    local new_url="$1"
    local description="$2"
    
    echo ""
    echo "Обновляю конфигурацию..."
    
    # Создаём backup
    cp "$CONSTANTS_FILE" "$CONSTANTS_FILE.backup"
    
    # Обновляем URL
    sed -i "s|static const String baseUrl = .*|static const String baseUrl = 'http://$new_url:8080/api/v1';|g" "$CONSTANTS_FILE"
    
    echo -e "${GREEN}✓ Конфигурация обновлена!${NC}"
    echo "   Окружение: $description"
    echo "   URL: http://$new_url:8080/api/v1"
    echo ""
    echo "Бэкап сохранён в: $CONSTANTS_FILE.backup"
    echo ""
    echo "Далее выполните:"
    echo "  cd apcs_system"
    echo "  flutter pub get"
    echo "  flutter run"
}

show_current() {
    echo ""
    echo "Текущая конфигурация в $CONSTANTS_FILE:"
    echo ""
    grep "static const String baseUrl" "$CONSTANTS_FILE" | head -1
    echo ""
}

# Основной цикл
while true; do
    show_menu
    read -p "Выберите опцию (0-5): " choice
    
    case $choice in
        1)
            echo ""
            echo "Android эмулятор (10.0.2.2 — специальный адрес)"
            update_api_url "10.0.2.2" "Android эмулятор"
            ;;
        
        2)
            echo ""
            echo "iOS симулятор (localhost)"
            update_api_url "localhost" "iOS симулятор"
            ;;
        
        3)
            echo ""
            read -p "Введите IP адрес сервера (например 192.168.1.100): " ip_addr
            
            # Валидация IP
            if [[ ! $ip_addr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo -e "${RED}✗ Неверный IP адрес${NC}"
                continue
            fi
            
            update_api_url "$ip_addr" "IP адрес: $ip_addr"
            
            echo -e "${BLUE}💡 Совет:${NC}"
            echo "   На Ubuntu сервере найдите IP:"
            echo "   $ hostname -I"
            ;;
        
        4)
            echo ""
            read -p "Введите hostname (например my-server.local): " hostname
            
            update_api_url "$hostname" "Hostname: $hostname"
            
            echo -e "${BLUE}💡 Совет:${NC}"
            echo "   На Ubuntu сервере найдите hostname:"
            echo "   $ hostname"
            ;;
        
        5)
            show_current
            ;;
        
        0)
            echo ""
            echo "До свидания! 👋"
            exit 0
            ;;
        
        *)
            echo -e "${RED}✗ Неверный выбор${NC}"
            ;;
    esac
done
