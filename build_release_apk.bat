@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================
REM АСУТП Tasks — Build Release APK with Signing
REM ============================================

color 0A
cls

echo.
echo ============================================
echo    АСУТП Tasks — Сборка Release APK
echo ============================================
echo.

cd /d "%~dp0apcs_system"

REM ============================================
REM Проверка Flutter
REM ============================================

echo [1/5] Проверяем Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo ОШИБКА: Flutter не установлен!
    echo Установите Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✓ Flutter OK

REM ============================================
REM Очистка
REM ============================================

echo.
echo [2/5] Очищаем проект...
flutter clean >nul
flutter pub get >nul
echo ✓ Очищено

REM ============================================
REM Сборка Release APK
REM ============================================

echo.
echo [3/5] Собираем Release APK...
flutter build apk --release
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo ОШИБКА: Не удалось собрать APK!
    pause
    exit /b 1
)
echo ✓ APK собран

REM ============================================
REM Информация о выходном файле
REM ============================================

echo.
echo [4/5] Локализуем APK...
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk
set OUTPUT_PATH=..\..\asutp-tasks-release.apk

if exist "%APK_PATH%" (
    copy "%APK_PATH%" "%OUTPUT_PATH%" >nul
    echo ✓ APK скопирован
) else (
    color 0C
    echo ОШИБКА: APK не найден в %APK_PATH%
    pause
    exit /b 1
)

REM ============================================
REM Информация для пользователя
REM ============================================

echo.
echo [5/5] Завершение...
echo.
echo ============================================
echo    ✓ Release APK готов!
echo ============================================
echo.

echo Путь к APK:
echo   %CD%\%APK_PATH%
echo.

for /F "tokens=*" %%a in ('dir /b "%APK_PATH%"') do (
    for /F "tokens=*" %%b in ('powershell -Command "(Get-Item '%APK_PATH%').length / 1MB"') do (
        echo Размер: %%b MB
    )
)
echo.

echo Как установить на устройство:
echo   1. Подключите Android устройство через USB
echo   2. Включите USB Debug режим
echo   3. Запустите: adb install "%APK_PATH%"
echo.

echo Для подписи с пользовательским ключом:
echo   1. Создайте ключ: keytool -genkey -v -keystore my-release-key.keystore ^
echo      -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
echo   2. Отредактируйте этот батник и добавьте параметр:
echo      flutter build apk --release --signing-key-path my-release-key.keystore
echo.

color 0B
echo ✓ Успешно!
color 0A

echo.
pause
