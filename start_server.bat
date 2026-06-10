@echo off
chcp 65001 >nul
echo ============================================
echo    АСУТП Tasks — Запуск сервера
echo ============================================
echo.

cd /d "%~dp0server"

echo [1/3] Проверяем Go...
go version
if %errorlevel% neq 0 (
    echo ОШИБКА: Go не установлен!
    pause
    exit /b 1
)

echo.
echo [2/3] Загружаем зависимости...
go mod tidy

echo.
echo [3/3] Запускаем сервер...
echo    API: http://localhost:8080
echo    Health: http://localhost:8080/health
echo    Тестовые пользователи (пароль: __seed_pass__):
echo      chief.engineer  - Главный инженер (создает задачи)
echo      asutp.chief     - Нач. службы АСУТП (управляет выполнением)
echo      ivan.engineer   - Инженер (только просмотр)
echo      operator1       - Оператор (только просмотр)
echo      admin           - Администратор системы
echo.
echo    Нажмите Ctrl+C для остановки
echo ============================================
echo.

go run ./cmd/server/
pause
