@echo off
chcp 65001 >nul
color 0A
cls

REM ============================================
REM АСУТП Tasks — Quick Start
REM ============================================

echo.
echo ============================================
echo    АСУТП Tasks — Быстрый старт
echo ============================================
echo.

:MENU
echo Выберите действие:
echo.
echo 1) Запустить Docker (PostgreSQL + Go сервер)
echo 2) Запустить Flutter приложение
echo 3) Собрать Release APK
echo 4) Очистить документы для релиза
echo 5) Показать статус контейнеров Docker
echo 6) Остановить Docker
echo 0) Выход
echo.

set /p choice="Введите номер (0-6): "

if "%choice%"=="1" goto docker_up
if "%choice%"=="2" goto flutter_run
if "%choice%"=="3" goto build_apk
if "%choice%"=="4" goto cleanup
if "%choice%"=="5" goto docker_status
if "%choice%"=="6" goto docker_down
if "%choice%"=="0" goto end

echo Неверный выбор!
goto menu

REM ============================================

:docker_up
echo.
echo Запускаю Docker контейнеры...
docker-compose up -d
echo.
echo ✓ Docker запущен!
echo   API: http://localhost:8080/api/v1
echo   Тестовые данные: ivan.petrov / __seed_pass__
echo.
pause
goto menu

REM ============================================

:flutter_run
echo.
echo ⚠️  ПЕРЕД ЗАПУСКОМ:
echo   1. Отредактируйте: apcs_system\lib\config\environment.dart
echo   2. Проверьте apiBaseUrl (правильный сервер)
echo.
pause

cd /d "%~dp0apcs_system"
flutter run
cd /d "%~dp0"
goto menu

REM ============================================

:build_apk
echo.
echo Собираю Release APK...
echo.
call build_release_apk.bat
goto menu

REM ============================================

:cleanup
echo.
echo Удаляю лишние документы...
echo.
call cleanup_docs.bat
goto menu

REM ============================================

:docker_status
echo.
docker-compose ps
echo.
pause
goto menu

REM ============================================

:docker_down
echo.
echo Останавливаю Docker контейнеры...
docker-compose down
echo.
echo ✓ Docker остановлен!
echo.
pause
goto menu

REM ============================================

:end
echo.
echo До свидания! 👋
echo.
pause
