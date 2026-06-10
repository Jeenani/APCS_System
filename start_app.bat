@echo off
chcp 65001 >nul
echo ============================================
echo    АСУТП Tasks — Запуск Flutter
echo ============================================
echo.

cd /d "%~dp0apcs_system"

echo [1/3] Проверяем Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ОШИБКА: Flutter не установлен!
    pause
    exit /b 1
)

echo.
echo [2/3] Загружаем зависимости...
flutter pub get

echo.
echo [3/3] Запускаем приложение...
echo    Убедитесь что сервер запущен (start_server.bat)
echo ============================================
echo.

flutter run
pause
