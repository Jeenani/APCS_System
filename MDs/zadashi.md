cd /opt/APCS_System
git pull
docker compose -f docker-compose.prod.yml down
docker volume rm $(docker volume ls -q | grep pgdata)
docker compose -f docker-compose.prod.yml up -d --build
Что реализовано — Субзадачи (parent-child)
Схема БД:

tasks.parent_id — nullable FK на tasks.id
Self-referential edge: parent ↔ children
parent_id != id (проверка в коде)
Защита от циклических ссылок при обновлении
Server API:

Эндпоинт	Изменение
POST /tasks	Принимает parent_id — создаёт подзадачу
PUT /tasks/:id	Принимает parent_id (0 = отвязать), проверяет циклы
GET /tasks	По умолчанию только top-level задачи (parent_id IS NULL). ?parent_id=X — дети конкретной задачи. ?include_subtasks=true — все
GET /tasks/:id	Загружает parent и children с деталями
DELETE /tasks/:id	Блокирует удаление, если у задачи есть дети
Flutter UI:

Детали задачи — показывает:
Ссылку на родительскую задачу (если есть)
Список подзадач с прогрессом и статусом
Кнопку «Создать подзадачу» (для canManageTasks)
Создание задачи — если открыто из деталей задачи, передаётся parent_id, заголовок меняется на «Создание подзадачи»
Иерархия теперь работает так:



Главный инженер создаёт: "Сделать систему кранов"
  → Нач. службы АСУТП открывает её → "Создать подзадачу"
    → "Купить кран" (parent_id = система кранов)
    → "Установить кран" (parent_id = система кранов)
    → "Подключить кран" (parent_id = система кранов)
Все подзадачи отображаются внутри родительской задачи. На главном экране по умолчанию только top-level задачи.

Пересоберите APK после деплоя сервера, если нужно.



