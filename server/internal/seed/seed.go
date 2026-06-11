package seed

import (
	"context"
	"fmt"
	"log"
	"time"

	"asutp-server/ent"

	"golang.org/x/crypto/bcrypt"
)

func Run(ctx context.Context, client *ent.Client) error {
	count, err := client.Role.Query().Count(ctx)
	if err != nil {
		return fmt.Errorf("ошибка проверки ролей: %w", err)
	}
	if count > 0 {
		log.Println("Seed: данные уже существуют, пропускаем")
		return nil
	}

	log.Println("Seed: заполняем справочники...")

	// Roles (5 ролей АСУТП)
	roleAdmin, err := client.Role.Create().SetName("admin").Save(ctx)
	if err != nil {
		return fmt.Errorf("seed role admin: %w", err)
	}
	roleChiefEng, err := client.Role.Create().SetName("chief_engineer").Save(ctx)
	if err != nil {
		return fmt.Errorf("seed role chief_engineer: %w", err)
	}
	roleAsutpChief, err := client.Role.Create().SetName("asutp_chief").Save(ctx)
	if err != nil {
		return fmt.Errorf("seed role asutp_chief: %w", err)
	}
	roleEngineer, err := client.Role.Create().SetName("engineer").Save(ctx)
	if err != nil {
		return fmt.Errorf("seed role engineer: %w", err)
	}
	roleOperator, err := client.Role.Create().SetName("operator").Save(ctx)
	if err != nil {
		return fmt.Errorf("seed role operator: %w", err)
	}

	// Priorities
	prioHigh, err := client.Priority.Create().SetName("high").SetColorHex("#E53935").SetSortOrder(1).Save(ctx)
	if err != nil {
		return fmt.Errorf("seed priority high: %w", err)
	}
	prioMedium, err := client.Priority.Create().SetName("medium").SetColorHex("#F9A825").SetSortOrder(2).Save(ctx)
	if err != nil {
		return fmt.Errorf("seed priority medium: %w", err)
	}
	if _, err := client.Priority.Create().SetName("low").SetColorHex("#2E7D32").SetSortOrder(3).Save(ctx); err != nil {
		return fmt.Errorf("seed priority low: %w", err)
	}

	// Task Statuses
	statusNew, err := client.TaskStatus.Create().SetCode("new").SetIsTerminal(false).Save(ctx)
	if err != nil {
		return fmt.Errorf("seed status new: %w", err)
	}
	statusInProgress, err := client.TaskStatus.Create().SetCode("in_progress").SetIsTerminal(false).Save(ctx)
	if err != nil {
		return fmt.Errorf("seed status in_progress: %w", err)
	}
	if _, err := client.TaskStatus.Create().SetCode("completed").SetIsTerminal(true).Save(ctx); err != nil {
		return fmt.Errorf("seed status completed: %w", err)
	}
	if _, err := client.TaskStatus.Create().SetCode("cancelled").SetIsTerminal(true).Save(ctx); err != nil {
		return fmt.Errorf("seed status cancelled: %w", err)
	}

	// Change Types
	for _, code := range []string{
		"task_created", "title_changed", "description_changed",
		"due_date_changed", "priority_changed", "progress_changed",
		"status_changed", "assignee_changed",
	} {
		if _, err := client.ChangeType.Create().SetCode(code).Save(ctx); err != nil {
			return fmt.Errorf("seed change_type %s: %w", code, err)
		}
	}

	// Notification Types
	for _, code := range []string{"reminder", "deadline", "update", "system"} {
		if _, err := client.NotificationType.Create().SetCode(code).Save(ctx); err != nil {
			return fmt.Errorf("seed notification_type %s: %w", code, err)
		}
	}

	// Export Types
	for _, code := range []string{"all", "completed", "selected"} {
		if _, err := client.ExportType.Create().SetCode(code).Save(ctx); err != nil {
			return fmt.Errorf("seed export_type %s: %w", code, err)
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
		c, err := client.TaskCategory.Create().
			SetName(cat.name).SetIconIdentifier(cat.icon).SetDescription(cat.desc).Save(ctx)
		if err != nil {
			return fmt.Errorf("seed category %s: %w", cat.name, err)
		}
		catMap[cat.name] = c
	}

	hash, err := bcrypt.GenerateFromPassword([]byte("__seed_pass__"), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("seed bcrypt: %w", err)
	}

	// Главный инженер — ставит задачи
	userChiefEng, err := client.User.Create().
		SetLogin("chief.engineer").
		SetPasswordHash(string(hash)).
		SetFullName("Сергей Волков").
		SetInitials("СВ").
		SetRoleID(roleChiefEng.ID).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("seed user chief.engineer: %w", err)
	}

	// Начальник службы АСУТП — управляет выполнением
	userAsutpChief, err := client.User.Create().
		SetLogin("asutp.chief").
		SetPasswordHash(string(hash)).
		SetFullName("Иван Петров").
		SetInitials("ИП").
		SetRoleID(roleAsutpChief.ID).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("seed user asutp.chief: %w", err)
	}

	// Инженер — только просмотр
	userEngineer, err := client.User.Create().
		SetLogin("ivan.engineer").
		SetPasswordHash(string(hash)).
		SetFullName("Алексей Сидоров").
		SetInitials("АС").
		SetRoleID(roleEngineer.ID).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("seed user ivan.engineer: %w", err)
	}

	// Оператор — эксплуатация
	userOperator, err := client.User.Create().
		SetLogin("operator1").
		SetPasswordHash(string(hash)).
		SetFullName("Мария Козлова").
		SetInitials("МК").
		SetRoleID(roleOperator.ID).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("seed user operator1: %w", err)
	}

	// Администратор
	userAdmin, err := client.User.Create().
		SetLogin("admin").
		SetPasswordHash(string(hash)).
		SetFullName("Администратор Системы").
		SetInitials("АС").
		SetRoleID(roleAdmin.ID).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("seed user admin: %w", err)
	}

	// Notification Settings
	for _, u := range []*ent.User{userChiefEng, userAsutpChief, userEngineer, userOperator, userAdmin} {
		if _, err := client.NotificationSetting.Create().SetUserID(u.ID).Save(ctx); err != nil {
			return fmt.Errorf("seed notification_setting user %d: %w", u.ID, err)
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
			SetCreatedBy(userChiefEng.ID). // Главный инженер создаёт
			SetAssignedTo(td.assignedTo)   // Начальник службы АСУТП исполняет
		if cat, ok := catMap[td.category]; ok {
			builder = builder.SetCategoryID(cat.ID)
		}
		if _, err := builder.Save(ctx); err != nil {
			return fmt.Errorf("seed task %s: %w", td.title, err)
		}
	}

	log.Println("Seed: данные успешно загружены")
	log.Println("Seed: Тестовые пользователи (пароль: __seed_pass__):")
	log.Println("  chief.engineer   — Главный инженер (создаёт задачи)")
	log.Println("  asutp.chief      — Нач. службы АСУТП (управляет выполнением)")
	log.Println("  ivan.engineer    — Инженер (только просмотр)")
	log.Println("  operator1        — Оператор (только просмотр)")
	log.Println("  admin            — Администратор (конфигурация системы)")
	_ = roleOperator
	_ = userEngineer
	_ = userOperator
	_ = userAdmin

	return nil
}
