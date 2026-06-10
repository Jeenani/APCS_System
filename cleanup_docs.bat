@echo off
chcp 65001 >nul

REM ============================================
REM Удаление ненужных документов
REM ============================================

echo.
echo Удаляю лишние файлы документации...
echo.

cd /d "%~dp0"

REM Удаляем лишние .md файлы (оставляем только нужные)
del /Q "CADDY_HTTPS_GUIDE.md" 2>nul && echo ✓ Удален CADDY_HTTPS_GUIDE.md
del /Q "CHANGES_SUMMARY.md" 2>nul && echo ✓ Удален CHANGES_SUMMARY.md
del /Q "FLUTTER_API_CONFIG.md" 2>nul && echo ✓ Удален FLUTTER_API_CONFIG.md
del /Q "FLUTTER_CADDY_SUMMARY.md" 2>nul && echo ✓ Удален FLUTTER_CADDY_SUMMARY.md
del /Q "SETTINGS_SCREEN_DEMO.txt" 2>nul && echo ✓ Удален SETTINGS_SCREEN_DEMO.txt
del /Q "FLUTTER_ENV_SUMMARY.txt" 2>nul && echo ✓ Удален FLUTTER_ENV_SUMMARY.txt

REM Удаляем лишние sh скрипты (оставляем важные)
del /Q "configure_flutter.sh" 2>nul && echo ✓ Удален configure_flutter.sh
del /Q "setup_ubuntu.sh" 2>nul && echo ✓ Удален setup_ubuntu.sh
del /Q "start_app.bat" 2>nul && echo ✓ Удален start_app.bat
del /Q "start_app.sh" 2>nul && echo ✓ Удален start_app.sh

REM Удаляем примеры
del /Q "apcs_system\lib\config\environment.examples.dart" 2>nul && echo ✓ Удален environment.examples.dart

echo.
echo ============================================
echo    Очистка завершена!
echo ============================================
echo.

echo Оставлены файлы:
echo   - README.md (главный)
echo   - README_COMPLETE.md (полная документация)
echo   - UBUNTU_SETUP_QUICK.md (для Ubuntu)
echo   - FLUTTER_ENV_CONFIG.md (конфигурация)
echo   - build_release_apk.bat (сборка APK)
echo   - start_server.sh / start_docker.sh (запуск)
echo.

pause
