package seed

import (
	"context"
	"fmt"
	"log"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/changetype"
	"asutp-server/ent/exporttype"
	"asutp-server/ent/notificationsetting"
	"asutp-server/ent/notificationtype"
	"asutp-server/ent/priority"
	"asutp-server/ent/role"
	"asutp-server/ent/taskcategory"
	"asutp-server/ent/taskstatus"
	"asutp-server/ent/user"

	"golang.org/x/crypto/bcrypt"
)

// getOrCreateRole возвращает роль по имени, создавая при необходимости
func getOrCreateRole(ctx context.Context, client *ent.Client, name string) (*ent.Role, error) {
	r, err := client.Role.Query().Where(role.NameEQ(name)).Only(ctx)
	if ent.IsNotFound(err) {
		r, err = client.Role.Create().SetName(name).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("role %s: %w", name, err)
	}
	return r, nil
}

// getOrCreatePriority возвращает приоритет по имени, создавая при необходимости
func getOrCreatePriority(ctx context.Context, client *ent.Client, name, color string, order int16) (*ent.Priority, error) {
	p, err := client.Priority.Query().Where(priority.NameEQ(name)).Only(ctx)
	if ent.IsNotFound(err) {
		p, err = client.Priority.Create().SetName(name).SetColorHex(color).SetSortOrder(order).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("priority %s: %w", name, err)
	}
	return p, nil
}

// getOrCreateTaskStatus возвращает статус по коду, создавая при необходимости
func getOrCreateTaskStatus(ctx context.Context, client *ent.Client, code string, terminal bool) (*ent.TaskStatus, error) {
	s, err := client.TaskStatus.Query().Where(taskstatus.CodeEQ(code)).Only(ctx)
	if ent.IsNotFound(err) {
		s, err = client.TaskStatus.Create().SetCode(code).SetIsTerminal(terminal).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("status %s: %w", code, err)
	}
	return s, nil
}

// getOrCreateChangeType возвращает тип изменения по коду, создавая при необходимости
func getOrCreateChangeType(ctx context.Context, client *ent.Client, code string) (*ent.ChangeType, error) {
	ct, err := client.ChangeType.Query().Where(changetype.CodeEQ(code)).Only(ctx)
	if ent.IsNotFound(err) {
		ct, err = client.ChangeType.Create().SetCode(code).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("change_type %s: %w", code, err)
	}
	return ct, nil
}

// getOrCreateNotificationType возвращает тип уведомления по коду, создавая при необходимости
func getOrCreateNotificationType(ctx context.Context, client *ent.Client, code string) (*ent.NotificationType, error) {
	nt, err := client.NotificationType.Query().Where(notificationtype.CodeEQ(code)).Only(ctx)
	if ent.IsNotFound(err) {
		nt, err = client.NotificationType.Create().SetCode(code).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("notification_type %s: %w", code, err)
	}
	return nt, nil
}

// getOrCreateExportType возвращает тип экспорта по коду, создавая при необходимости
func getOrCreateExportType(ctx context.Context, client *ent.Client, code string) (*ent.ExportType, error) {
	et, err := client.ExportType.Query().Where(exporttype.CodeEQ(code)).Only(ctx)
	if ent.IsNotFound(err) {
		et, err = client.ExportType.Create().SetCode(code).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("export_type %s: %w", code, err)
	}
	return et, nil
}

// getOrCreateTaskCategory возвращает категорию по имени, создавая при необходимости
func getOrCreateTaskCategory(ctx context.Context, client *ent.Client, name, icon, desc string) (*ent.TaskCategory, error) {
	c, err := client.TaskCategory.Query().Where(taskcategory.NameEQ(name)).Only(ctx)
	if ent.IsNotFound(err) {
		c, err = client.TaskCategory.Create().SetName(name).SetIconIdentifier(icon).SetDescription(desc).Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("category %s: %w", name, err)
	}
	return c, nil
}

// getOrCreateUser возвращает пользователя по логину, создавая при необходимости
func getOrCreateUser(ctx context.Context, client *ent.Client, login, fullName, initials string, roleID int, passwordHash string) (*ent.User, error) {
	u, err := client.User.Query().Where(user.LoginEQ(login)).Only(ctx)
	if ent.IsNotFound(err) {
		u, err = client.User.Create().
			SetLogin(login).
			SetPasswordHash(passwordHash).
			SetFullName(fullName).
			SetInitials(initials).
			SetRoleID(roleID).
			Save(ctx)
	}
	if err != nil {
		return nil, fmt.Errorf("user %s: %w", login, err)
	}
	return u, nil
}

func Run(ctx context.Context, client *ent.Client) error {
	// Если задачи уже есть — пропускаем (остальные справочники уже на месте)
	taskCount, err := client.Task.Query().Count(ctx)
	if err != nil {
		return fmt.Errorf("ошибка проверки задач: %w", err)
	}
	if taskCount > 0 {
		log.Println("Seed: задачи уже существуют, пропускаем")
		return nil
	}

	log.Println("Seed: заполняем справочники и задачи...")

	// Roles
	roleAdmin, err := getOrCreateRole(ctx, client, "admin")
	if err != nil {
		return err
	}
	roleChiefEng, err := getOrCreateRole(ctx, client, "chief_engineer")
	if err != nil {
		return err
	}
	roleAsutpChief, err := getOrCreateRole(ctx, client, "asutp_chief")
	if err != nil {
		return err
	}
	roleEngineer, err := getOrCreateRole(ctx, client, "engineer")
	if err != nil {
		return err
	}
	roleOperator, err := getOrCreateRole(ctx, client, "operator")
	if err != nil {
		return err
	}

	// Priorities
	prioHigh, err := getOrCreatePriority(ctx, client, "high", "#E53935", 1)
	if err != nil {
		return err
	}
	prioMedium, err := getOrCreatePriority(ctx, client, "medium", "#F9A825", 2)
	if err != nil {
		return err
	}
	if _, err := getOrCreatePriority(ctx, client, "low", "#2E7D32", 3); err != nil {
		return err
	}

	// Task Statuses
	statusNew, err := getOrCreateTaskStatus(ctx, client, "new", false)
	if err != nil {
		return err
	}
	statusInProgress, err := getOrCreateTaskStatus(ctx, client, "in_progress", false)
	if err != nil {
		return err
	}
	if _, err := getOrCreateTaskStatus(ctx, client, "completed", true); err != nil {
		return err
	}
	if _, err := getOrCreateTaskStatus(ctx, client, "cancelled", true); err != nil {
		return err
	}

	// Change Types
	for _, code := range []string{
		"task_created", "title_changed", "description_changed",
		"due_date_changed", "priority_changed", "progress_changed",
		"status_changed", "assignee_changed",
	} {
		if _, err := getOrCreateChangeType(ctx, client, code); err != nil {
			return err
		}
	}

	// Notification Types
	for _, code := range []string{"reminder", "deadline", "update", "system"} {
		if _, err := getOrCreateNotificationType(ctx, client, code); err != nil {
			return err
		}
	}

	// Export Types
	for _, code := range []string{"all", "completed", "selected"} {
		if _, err := getOrCreateExportType(ctx, client, code); err != nil {
			return err
		}
	}

	// Task Categories
	categories := []struct{ name, icon, desc string }{
		{"Датчики", "icon_sensor", "Датчики давления, температуры, расхода, вибрации"},
		{"Контроллеры", "icon_plc", "Программирование и обслуживание ПЛК"},
		{"Панели оператора", "icon_hmi", "HMI / SCADA-панели"},
		{"Клапаны", "icon_valve", "Регулирующая и запорная арматура"},
		{"Насосы", "icon_pump", "Насосное оборудование"},
		{"Уровнемеры", "icon_level", "Приборы измерения уровня"},
		{"PLC", "icon_plc_rack", "Стойки и модули ПЛК"},
		{"SCADA", "icon_scada", "Системы диспетчерского управления"},
		{"Контроль оборудования", "icon_equipment", "Общий контроль и техобслуживание"},
	}
	catMap := make(map[string]*ent.TaskCategory)
	for _, cat := range categories {
		c, err := getOrCreateTaskCategory(ctx, client, cat.name, cat.icon, cat.desc)
		if err != nil {
			return err
		}
		catMap[cat.name] = c
	}

	hash, err := bcrypt.GenerateFromPassword([]byte("__seed_pass__"), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("seed bcrypt: %w", err)
	}

	// Users (GetOrCreate — не пересоздаём если уже есть)
	userChiefEng, err := getOrCreateUser(ctx, client, "chief.engineer", "Сергей Волков", "СВ", roleChiefEng.ID, string(hash))
	if err != nil {
		return err
	}
	userAsutpChief, err := getOrCreateUser(ctx, client, "asutp.chief", "Иван Петров", "ИП", roleAsutpChief.ID, string(hash))
	if err != nil {
		return err
	}
	userEngineer, err := getOrCreateUser(ctx, client, "ivan.engineer", "Алексей Сидоров", "АС", roleEngineer.ID, string(hash))
	if err != nil {
		return err
	}
	userOperator, err := getOrCreateUser(ctx, client, "operator1", "Мария Козлова", "МК", roleOperator.ID, string(hash))
	if err != nil {
		return err
	}
	userAdmin, err := getOrCreateUser(ctx, client, "admin", "Администратор Системы", "АС", roleAdmin.ID, string(hash))
	if err != nil {
		return err
	}

	// Notification Settings (только если ещё нет)
	for _, u := range []*ent.User{userChiefEng, userAsutpChief, userEngineer, userOperator, userAdmin} {
		exists, _ := client.NotificationSetting.Query().Where(notificationsetting.UserIDEQ(u.ID)).Exist(ctx)
		if !exists {
			if _, err := client.NotificationSetting.Create().SetUserID(u.ID).Save(ctx); err != nil {
				return fmt.Errorf("seed notification_setting user %d: %w", u.ID, err)
			}
		}
	}

	// Задачи (создаёт Главный инженер, назначает Нач. службы АСУТП)
	type taskData struct {
		title, desc, dueDate string
		priority             *ent.Priority
		status               *ent.TaskStatus
		category             string
		progress             int16
		assignedTo           int
	}

	sampleTasks := []taskData{
		{
			"Проверка датчиков давления",
			"Проверить работоспособность и калибровку датчиков давления на всех участках.",
			"2025-07-25", prioHigh, statusInProgress, "Датчики", 75, userAsutpChief.ID,
		},
		{
			"Обновление ПО контроллера",
			"Обновить прошивку ПЛК Siemens S7-300 на участке №2.",
			"2025-07-28", prioMedium, statusInProgress, "Контроллеры", 40, userAsutpChief.ID,
		},
		{
			"Калибровка уровнемеров",
			"Провести поверку уровнемеров в резервуарах 1–4.",
			"2025-07-30", prioMedium, statusInProgress, "Уровнемеры", 20, userAsutpChief.ID,
		},
		{
			"Проверка шкафов управления",
			"Визуальный осмотр и проверка монтажа в шкафах управления насосной станции.",
			"2025-08-01", prioHigh, statusNew, "Контроль оборудования", 0, userAsutpChief.ID,
		},
	}

	for _, td := range sampleTasks {
		dueDate, err := time.Parse("2006-01-02", td.dueDate)
		if err != nil {
			return fmt.Errorf("seed task parse date %s: %w", td.dueDate, err)
		}
		builder := client.Task.Create().
			SetTitle(td.title).SetDescription(td.desc).SetDueDate(dueDate).
			SetPriorityID(td.priority.ID).SetStatusID(td.status.ID).
			SetProgress(td.progress).
			SetCreatedBy(userChiefEng.ID).
			SetAssignedTo(td.assignedTo)
		if cat, ok := catMap[td.category]; ok {
			builder = builder.SetCategoryID(cat.ID)
		}
		if _, err := builder.Save(ctx); err != nil {
			return fmt.Errorf("seed task %s: %w", td.title, err)
		}
	}

	log.Println("Seed: данные успешно загружены")
	log.Println("Seed: Тестовые пользователи (пароль: __seed_pass__):")
	log.Println("  chief.engineer   — Главный инженер")
	log.Println("  asutp.chief      — Нач. службы АСУТП")
	log.Println("  ivan.engineer    — Инженер")
	log.Println("  operator1        — Оператор")
	log.Println("  admin            — Администратор")

	return nil
}
