package seed

import (
	"context"
	"log"
	"time"

	"asutp-server/ent"

	"golang.org/x/crypto/bcrypt"
)

func Run(ctx context.Context, client *ent.Client) error {
	count, _ := client.Role.Query().Count(ctx)
	if count > 0 {
		log.Println("Seed: данные уже существуют, пропускаем")
		return nil
	}

	log.Println("Seed: заполняем справочники...")

	// Roles (5 ролей АСУТП)
	roleAdmin, _ := client.Role.Create().SetName("admin").Save(ctx)
	roleChiefEng, _ := client.Role.Create().SetName("chief_engineer").Save(ctx)
	roleAsutpChief, _ := client.Role.Create().SetName("asutp_chief").Save(ctx)
	roleEngineer, _ := client.Role.Create().SetName("engineer").Save(ctx)
	roleOperator, _ := client.Role.Create().SetName("operator").Save(ctx)

	// Priorities
	prioHigh, _ := client.Priority.Create().SetName("high").SetColorHex("#E53935").SetSortOrder(1).Save(ctx)
	prioMedium, _ := client.Priority.Create().SetName("medium").SetColorHex("#F9A825").SetSortOrder(2).Save(ctx)
	_, _ = client.Priority.Create().SetName("low").SetColorHex("#2E7D32").SetSortOrder(3).Save(ctx)

	// Task Statuses
	statusNew, _ := client.TaskStatus.Create().SetCode("new").SetIsTerminal(false).Save(ctx)
	statusInProgress, _ := client.TaskStatus.Create().SetCode("in_progress").SetIsTerminal(false).Save(ctx)
	_, _ = client.TaskStatus.Create().SetCode("completed").SetIsTerminal(true).Save(ctx)
	_, _ = client.TaskStatus.Create().SetCode("cancelled").SetIsTerminal(true).Save(ctx)

	// Change Types
	for _, code := range []string{
		"task_created", "title_changed", "description_changed",
		"due_date_changed", "priority_changed", "progress_changed",
		"status_changed", "assignee_changed",
	} {
		client.ChangeType.Create().SetCode(code).Save(ctx)
	}

	// Notification Types
	for _, code := range []string{"reminder", "deadline", "update", "system"} {
		client.NotificationType.Create().SetCode(code).Save(ctx)
	}

	// Export Types
	for _, code := range []string{"all", "completed", "selected"} {
		client.ExportType.Create().SetCode(code).Save(ctx)
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
		c, _ := client.TaskCategory.Create().
			SetName(cat.name).SetIconIdentifier(cat.icon).SetDescription(cat.desc).Save(ctx)
		catMap[cat.name] = c
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte("__seed_pass__"), bcrypt.DefaultCost)

	// Главный инженер — ставит задачи
	userChiefEng, _ := client.User.Create().
		SetLogin("chief.engineer").
		SetPasswordHash(string(hash)).
		SetFullName("Сергей Волков").
		SetInitials("СВ").
		SetRoleID(roleChiefEng.ID).
		Save(ctx)

	// Начальник службы АСУТП — управляет выполнением
	userAsutpChief, _ := client.User.Create().
		SetLogin("asutp.chief").
		SetPasswordHash(string(hash)).
		SetFullName("Иван Петров").
		SetInitials("ИП").
		SetRoleID(roleAsutpChief.ID).
		Save(ctx)

	// Инженер — только просмотр
	userEngineer, _ := client.User.Create().
		SetLogin("ivan.engineer").
		SetPasswordHash(string(hash)).
		SetFullName("Алексей Сидоров").
		SetInitials("АС").
		SetRoleID(roleEngineer.ID).
		Save(ctx)

	// Оператор — эксплуатация
	userOperator, _ := client.User.Create().
		SetLogin("operator1").
		SetPasswordHash(string(hash)).
		SetFullName("Мария Козлова").
		SetInitials("МК").
		SetRoleID(roleOperator.ID).
		Save(ctx)

	// Администратор
	userAdmin, _ := client.User.Create().
		SetLogin("admin").
		SetPasswordHash(string(hash)).
		SetFullName("Администратор Системы").
		SetInitials("АС").
		SetRoleID(roleAdmin.ID).
		Save(ctx)

	// Notification Settings
	for _, u := range []*ent.User{userChiefEng, userAsutpChief, userEngineer, userOperator, userAdmin} {
		client.NotificationSetting.Create().SetUserID(u.ID).Save(ctx)
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
		dueDate, _ := time.Parse("2006-01-02", td.dueDate)
		builder := client.Task.Create().
			SetTitle(td.title).SetDescription(td.desc).SetDueDate(dueDate).
			SetPriorityID(td.priority.ID).SetStatusID(td.status.ID).
			SetProgress(td.progress).
			SetCreatedBy(userChiefEng.ID). // Главный инженер создаёт
			SetAssignedTo(td.assignedTo)   // Начальник службы АСУТП исполняет
		if cat, ok := catMap[td.category]; ok {
			builder = builder.SetCategoryID(cat.ID)
		}
		builder.Save(ctx)
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
