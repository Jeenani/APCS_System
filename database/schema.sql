-- ============================================================
--  АСУТП Tasks — PostgreSQL Database Schema
--  Версия: 3.0
--  Нормализация: 3NF
--  Архитектурный принцип: каждый enum = отдельная таблица-сущность,
--  CHECK живёт на name/code ВНУТРИ этой таблицы.
--  Основные таблицы ссылаются через FK (role_id, priority_id и т.д.)
--
--  Что НЕ здесь (делается в ent / Go):
--    - updated_at              → ent UpdateTime()
--    - генерация initials      → ent BeforeCreate hook
--    - создание notification_settings → ent hook
--    - история изменений задач → ent interceptors
--    - авто-статус progress=100 → ent Validator
--    - планировщик уведомлений → Go service layer
--    - поиск / агрегаты        → ent predicates
-- ============================================================


-- ============================================================
-- РАЗДЕЛ 1: СПРАВОЧНИКИ-СУЩНОСТИ
-- Каждый справочник — отдельная таблица.
-- CHECK на name/code защищает от случайных значений вне схемы.
-- ============================================================

-- 1.1 Роли пользователей
CREATE TABLE roles (
    id   SMALLSERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE,

    CONSTRAINT chk_roles_name
        CHECK (name IN ('admin', 'chief_engineer', 'asutp_chief', 'engineer', 'operator'))
);

COMMENT ON TABLE roles IS 'Роли: admin | chief_engineer | asutp_chief | engineer | operator';

-- 1.2 Приоритеты задач
CREATE TABLE priorities (
    id         SMALLSERIAL PRIMARY KEY,
    name       VARCHAR(10) NOT NULL UNIQUE,
    color_hex  VARCHAR(7)  NOT NULL,
    sort_order SMALLINT    NOT NULL UNIQUE,

    CONSTRAINT chk_priorities_name
        CHECK (name IN ('high', 'medium', 'low'))
);

COMMENT ON TABLE priorities IS 'Приоритеты: high | medium | low; color_hex — для UI';

-- 1.3 Статусы задач
CREATE TABLE task_status (
    id          SMALLSERIAL PRIMARY KEY,
    code        VARCHAR(20) NOT NULL UNIQUE,
    is_terminal BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT chk_task_status_code
        CHECK (code IN ('new', 'in_progress', 'completed', 'cancelled'))
);

COMMENT ON TABLE task_status IS 'Статусы жизненного цикла задачи; is_terminal=TRUE у completed/cancelled';

-- 1.4 Типы изменений в истории
CREATE TABLE change_types (
    id   SMALLSERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,

    CONSTRAINT chk_change_types_code CHECK (
        code IN (
            'task_created', 'title_changed', 'description_changed',
            'due_date_changed', 'priority_changed', 'progress_changed',
            'status_changed', 'assignee_changed'
        )
    )
);

COMMENT ON TABLE change_types IS 'Типы событий в истории изменений задачи';

-- 1.5 Типы уведомлений
CREATE TABLE notification_types (
    id   SMALLSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,

    CONSTRAINT chk_notification_types_code
        CHECK (code IN ('reminder', 'deadline', 'update', 'system'))
);

COMMENT ON TABLE notification_types IS 'Типы уведомлений: reminder | deadline | update | system';

-- 1.6 Типы экспорта
CREATE TABLE export_types (
    id   SMALLSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,

    CONSTRAINT chk_export_types_code
        CHECK (code IN ('all', 'completed', 'selected'))
);

COMMENT ON TABLE export_types IS 'Типы CSV-экспорта: all | completed | selected';

-- 1.7 Категории задач (тематика АСУТП/SCADA)
-- Отдельная таблица т.к. имеет доп. атрибуты: icon_identifier, description
CREATE TABLE task_categories (
    id              SMALLSERIAL  PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    icon_identifier VARCHAR(100) NOT NULL,
    description     TEXT
);

COMMENT ON TABLE task_categories IS 'Категории задач SCADA/PLC (Датчики, Клапаны, ПЛК…)';


-- ============================================================
-- РАЗДЕЛ 2: ПОЛЬЗОВАТЕЛИ
-- ============================================================

CREATE TABLE users (
    id            SERIAL      PRIMARY KEY,
    login         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(200) NOT NULL,
    initials      VARCHAR(10)  NOT NULL,
    role_id       SMALLINT     NOT NULL REFERENCES roles(id),
    avatar_color  VARCHAR(7)   NOT NULL DEFAULT '#1565C0',
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN users.password_hash IS 'bcrypt / argon2 — не хранить открытый пароль';
COMMENT ON COLUMN users.initials      IS 'Вычисляется на уровне приложения (ent BeforeCreate hook)';

-- Настройки уведомлений (1:1 с users).
-- Вынесено отдельно по 3NF: атрибуты зависят только от user_id.
CREATE TABLE notification_settings (
    user_id                INTEGER  PRIMARY KEY
                               REFERENCES users(id) ON DELETE CASCADE,
    push_enabled           BOOLEAN  NOT NULL DEFAULT TRUE,
    sound_enabled          BOOLEAN  NOT NULL DEFAULT TRUE,
    vibration_enabled      BOOLEAN  NOT NULL DEFAULT FALSE,
    reminder_days_before   SMALLINT NOT NULL DEFAULT 3,
    quiet_hours_start      TIME     NOT NULL DEFAULT '22:00',
    quiet_hours_end        TIME     NOT NULL DEFAULT '08:00',
    notify_high_priority   BOOLEAN  NOT NULL DEFAULT TRUE,
    notify_medium_priority BOOLEAN  NOT NULL DEFAULT TRUE,
    notify_low_priority    BOOLEAN  NOT NULL DEFAULT FALSE,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_reminder_days CHECK (reminder_days_before IN (1, 3, 7))
);

COMMENT ON TABLE notification_settings IS '1:1 настройки уведомлений — создаются ent-хуком при регистрации';


-- ============================================================
-- РАЗДЕЛ 3: ЗАДАЧИ
-- ============================================================

CREATE TABLE tasks (
    id          SERIAL      PRIMARY KEY,
    title       VARCHAR(500) NOT NULL,
    description TEXT,
    due_date    DATE         NOT NULL,
    priority_id SMALLINT     NOT NULL REFERENCES priorities(id),
    status_id   SMALLINT     NOT NULL REFERENCES task_status(id),
    category_id SMALLINT              REFERENCES task_categories(id) ON DELETE SET NULL,
    progress    SMALLINT     NOT NULL DEFAULT 0,
    created_by  INTEGER      NOT NULL REFERENCES users(id),
    assigned_to INTEGER               REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_tasks_progress CHECK (progress >= 0 AND progress <= 100)
);

COMMENT ON COLUMN tasks.progress IS '0–100 %; авто-смена status_id на completed — в ent Validator';


-- ============================================================
-- РАЗДЕЛ 4: ИСТОРИЯ ИЗМЕНЕНИЙ (append-only лог)
-- ============================================================

CREATE TABLE task_history (
    id             BIGSERIAL   PRIMARY KEY,
    task_id        INTEGER     NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    changed_by     INTEGER     NOT NULL REFERENCES users(id),
    change_type_id SMALLINT    NOT NULL REFERENCES change_types(id),
    field_name     VARCHAR(100),
    old_value      TEXT,
    new_value      TEXT,
    display_text   VARCHAR(500),
    changed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE task_history IS 'Неизменяемый лог изменений задач; записи создаются ent-хуками';


-- ============================================================
-- РАЗДЕЛ 5: УВЕДОМЛЕНИЯ
-- ============================================================

CREATE TABLE notifications (
    id                   BIGSERIAL   PRIMARY KEY,
    user_id              INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    task_id              INTEGER              REFERENCES tasks(id) ON DELETE SET NULL,
    title                VARCHAR(500) NOT NULL,
    body                 TEXT,
    notification_type_id SMALLINT    NOT NULL REFERENCES notification_types(id),
    priority_id          SMALLINT             REFERENCES priorities(id),
    is_read              BOOLEAN     NOT NULL DEFAULT FALSE,
    scheduled_at         TIMESTAMPTZ NOT NULL,
    sent_at              TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN notifications.scheduled_at IS 'Когда отправить (читает Go-планировщик)';
COMMENT ON COLUMN notifications.sent_at      IS 'NULL = ещё не отправлено';


-- ============================================================
-- РАЗДЕЛ 6: ЭКСПОРТ И БЕЗОПАСНОСТЬ
-- ============================================================

CREATE TABLE export_logs (
    id             SERIAL      PRIMARY KEY,
    user_id        INTEGER     NOT NULL REFERENCES users(id),
    export_type_id SMALLINT    NOT NULL REFERENCES export_types(id),
    file_name      VARCHAR(255),
    record_count   INTEGER,
    exported_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE export_logs IS 'Аудит CSV-экспортов';

-- Связь экспорта с конкретными задачами (только при export_type = selected).
-- ON DELETE RESTRICT: нельзя удалить задачу, вошедшую в аудит-экспорт — сохраняем историю.
CREATE TABLE export_log_tasks (
    export_log_id INTEGER NOT NULL REFERENCES export_logs(id) ON DELETE CASCADE,
    task_id       INTEGER NOT NULL REFERENCES tasks(id)       ON DELETE RESTRICT,

    PRIMARY KEY (export_log_id, task_id)
);

COMMENT ON TABLE export_log_tasks IS 'M:N — какие задачи вошли в конкретный экспорт (только для type=selected)';

CREATE TABLE password_reset_tokens (
    id         SERIAL       PRIMARY KEY,
    user_id    INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ  NOT NULL,
    used_at    TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN password_reset_tokens.token_hash IS 'SHA-256 от реального одноразового токена';

CREATE TABLE refresh_tokens (
    id          BIGSERIAL    PRIMARY KEY,
    user_id     INTEGER      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  VARCHAR(255) NOT NULL UNIQUE,
    device_info VARCHAR(500),
    expires_at  TIMESTAMPTZ  NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN refresh_tokens.revoked_at IS 'NULL = токен активен';


-- ============================================================
-- РАЗДЕЛ 7: ИНДЕКСЫ
-- ============================================================

CREATE INDEX idx_users_role_id          ON users(role_id);

CREATE INDEX idx_tasks_assigned_to      ON tasks(assigned_to);
CREATE INDEX idx_tasks_created_by       ON tasks(created_by);
CREATE INDEX idx_tasks_status_id        ON tasks(status_id);
CREATE INDEX idx_tasks_priority_id      ON tasks(priority_id);
CREATE INDEX idx_tasks_due_date         ON tasks(due_date);
CREATE INDEX idx_tasks_category_id      ON tasks(category_id);

CREATE INDEX idx_tasks_title_fts ON tasks
    USING GIN (to_tsvector('russian', title));
CREATE INDEX idx_tasks_desc_fts ON tasks
    USING GIN (to_tsvector('russian', COALESCE(description, '')));

CREATE INDEX idx_task_history_task_id    ON task_history(task_id);
CREATE INDEX idx_task_history_changed_at ON task_history(changed_at DESC);

CREATE INDEX idx_notifications_user_id      ON notifications(user_id);
CREATE INDEX idx_notifications_task_id      ON notifications(task_id);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at)
    WHERE sent_at IS NULL;
CREATE INDEX idx_notifications_unread       ON notifications(user_id, is_read)
    WHERE is_read = FALSE;

CREATE INDEX idx_refresh_tokens_user_active ON refresh_tokens(user_id)
    WHERE revoked_at IS NULL;
CREATE INDEX idx_pwd_reset_tokens_user_id   ON password_reset_tokens(user_id);

CREATE INDEX idx_export_log_tasks_task_id ON export_log_tasks(task_id);


-- ============================================================
-- НАЧАЛЬНЫЕ ДАННЫЕ: seed.go (создаёт справочники, пользователей и задачи)
-- ============================================================
