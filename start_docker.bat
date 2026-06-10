@echo off
chcp 65001 >nul
echo ============================================
echo    АСУТП Tasks — Docker Compose
echo ============================================
echo.
echo Запуск PostgreSQL + Go сервер в Docker...
echo.

cd /d "%~dp0"
docker compose up --build -d

echo.
echo ============================================
echo    Сервисы запущены:
echo    PostgreSQL: localhost:5432
echo    API:        http://localhost:8080
echo    Health:     http://localhost:8080/health
echo ============================================
echo.
echo    docker compose logs -f   — логи
echo    docker compose down      — остановить
echo.
pause
