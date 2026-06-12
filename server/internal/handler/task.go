package handler

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/changetype"
	"asutp-server/ent/notificationtype"
	"asutp-server/ent/role"
	"asutp-server/ent/task"
	"asutp-server/ent/taskassignee"
	"asutp-server/ent/taskhistory"
	"asutp-server/ent/taskstatus"
	"asutp-server/ent/user"

	"github.com/gin-gonic/gin"
)

type TaskHandler struct {
	client *ent.Client
}

func NewTaskHandler(client *ent.Client) *TaskHandler {
	return &TaskHandler{client: client}
}

type createTaskRequest struct {
	Title       string `json:"title" binding:"required,max=500"`
	Description string `json:"description"`
	DueDate     string `json:"due_date" binding:"required"`
	PriorityID  int    `json:"priority_id" binding:"required"`
	CategoryID  *int   `json:"category_id"`
	AssignedTo  *int   `json:"assigned_to"`
	Assignees   []int  `json:"assignees"`
}

type updateTaskRequest struct {
	Title       *string `json:"title"`
	Description *string `json:"description"`
	DueDate     *string `json:"due_date"`
	PriorityID  *int    `json:"priority_id"`
	StatusID    *int    `json:"status_id"`
	CategoryID  *int    `json:"category_id"`
	Progress    *int16  `json:"progress"`
	AssignedTo  *int    `json:"assigned_to"`
	Assignees   []int   `json:"assignees"`
}

func (h *TaskHandler) List(c *gin.Context) {
	query := h.client.Task.Query().
		WithPriority().
		WithStatus().
		WithCategory().
		WithCreator().
		WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser().WithProposer().WithApprover()
		}).
		Order(ent.Desc(task.FieldCreatedAt))

	// Filters
	if statusCode := c.Query("status"); statusCode != "" {
		query = query.Where(task.HasStatusWith(taskstatus.CodeEQ(statusCode)))
	}
	if priorityID := c.Query("priority_id"); priorityID != "" {
		if pid, err := strconv.Atoi(priorityID); err == nil {
			query = query.Where(task.PriorityIDEQ(pid))
		}
	}
	if search := c.Query("search"); search != "" {
		query = query.Where(task.TitleContainsFold(search))
	}
	if categoryID := c.Query("category_id"); categoryID != "" {
		if cid, err := strconv.Atoi(categoryID); err == nil {
			query = query.Where(task.CategoryIDEQ(cid))
		}
	}

	// Sort
	switch c.Query("sort") {
	case "due_date_asc":
		query = query.Order(ent.Asc(task.FieldDueDate))
	case "due_date_desc":
		query = query.Order(ent.Desc(task.FieldDueDate))
	case "progress_asc":
		query = query.Order(ent.Asc(task.FieldProgress))
	case "progress_desc":
		query = query.Order(ent.Desc(task.FieldProgress))
	}

	tasks, err := query.All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения задач"})
		return
	}

	result := make([]gin.H, 0, len(tasks))
	for _, t := range tasks {
		result = append(result, taskToJSON(t))
	}

	c.JSON(http.StatusOK, gin.H{
		"tasks": result,
		"count": len(result),
	})
}

func (h *TaskHandler) Get(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	t, err := h.client.Task.Query().
		Where(task.IDEQ(id)).
		WithPriority().
		WithStatus().
		WithCategory().
		WithCreator().
		WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser().WithProposer().WithApprover()
		}).
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Задача не найдена"})
		return
	}

	c.JSON(http.StatusOK, taskToJSON(t))
}

func (h *TaskHandler) Create(c *gin.Context) {
	var req createTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте корректность данных", "details": err.Error()})
		return
	}

	dueDate, err := time.Parse("2006-01-02", req.DueDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Укажите корректную дату (YYYY-MM-DD)"})
		return
	}

	userID := c.GetInt("user_id")

	// Get "new" status
	newStatus, err := h.client.TaskStatus.Query().
		Where(taskstatus.CodeEQ("new")).
		Only(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения статуса"})
		return
	}

	tx, err := h.client.Tx(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка транзакции"})
		return
	}

	builder := tx.Task.Create().
		SetTitle(req.Title).
		SetDueDate(dueDate).
		SetPriorityID(req.PriorityID).
		SetStatusID(newStatus.ID).
		SetCreatedBy(userID)

	if req.Description != "" {
		builder = builder.SetDescription(req.Description)
	}
	if req.CategoryID != nil {
		builder = builder.SetCategoryID(*req.CategoryID)
	}
	if req.AssignedTo != nil {
		builder = builder.SetAssignedTo(*req.AssignedTo)
	}

	t, err := builder.Save(c)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания задачи"})
		return
	}

	// Get proposer role
	proposer, err := tx.User.Query().Where(user.IDEQ(userID)).WithRole().Only(c)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения роли"})
		return
	}
	canDirectAssign := proposer.Edges.Role != nil && (proposer.Edges.Role.Name == "asutp_chief" || proposer.Edges.Role.Name == "admin")

	// Create assignees
	for _, assigneeID := range req.Assignees {
		builder := tx.TaskAssignee.Create().
			AddTaskIDs(t.ID).
			AddUserIDs(assigneeID).
			AddProposerIDs(userID)
		if canDirectAssign {
			builder = builder.
				SetStatus("approved").
				AddApproverIDs(userID).
				SetApprovedAt(time.Now())
		}
		_, err := builder.Save(c)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка назначения исполнителей"})
			return
		}
	}

	// Notify asutp_chief about new proposals only from chief_engineer
	if len(req.Assignees) > 0 && !canDirectAssign {
		_ = h.notifyApprovers(c, t.ID, t.Title, userID)
	}

	// Create history entry
	taskCreatedType, _ := getChangeTypeID(tx.Client(), c, "task_created")
	if taskCreatedType > 0 {
		tx.TaskHistory.Create().
			SetTaskID(t.ID).
			SetChangedBy(userID).
			SetChangeTypeID(taskCreatedType).
			SetDisplayText("Задача создана").
			Save(c)
	}

	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения"})
		return
	}

	// Reload with edges
	t, _ = h.client.Task.Query().
		Where(task.IDEQ(t.ID)).
		WithPriority().
		WithStatus().
		WithCategory().
		WithCreator().
		WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser()
		}).
		Only(c)

	c.JSON(http.StatusCreated, taskToJSON(t))
}

func (h *TaskHandler) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	var req updateTaskRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте корректность данных"})
		return
	}

	existing, err := h.client.Task.Get(c, id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Задача не найдена"})
		return
	}

	userID := c.GetInt("user_id")
	tx, err := h.client.Tx(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка транзакции"})
		return
	}

	builder := tx.Task.UpdateOneID(id)

	if req.Title != nil && *req.Title != existing.Title {
		changeID, _ := getChangeTypeID(tx.Client(), c, "title_changed")
		if changeID > 0 {
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("title").SetOldValue(existing.Title).SetNewValue(*req.Title).
				SetDisplayText(fmt.Sprintf("Название: %s → %s", existing.Title, *req.Title)).
				Save(c)
		}
		builder = builder.SetTitle(*req.Title)
	}

	if req.Description != nil {
		changeID, _ := getChangeTypeID(tx.Client(), c, "description_changed")
		if changeID > 0 {
			oldDesc := ""
			if existing.Description != nil {
				oldDesc = *existing.Description
			}
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("description").SetOldValue(oldDesc).SetNewValue(*req.Description).
				SetDisplayText("Описание изменено").
				Save(c)
		}
		builder = builder.SetDescription(*req.Description)
	}

	if req.DueDate != nil {
		dueDate, err := time.Parse("2006-01-02", *req.DueDate)
		if err == nil {
			changeID, _ := getChangeTypeID(tx.Client(), c, "due_date_changed")
			if changeID > 0 {
				tx.TaskHistory.Create().
					SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
					SetFieldName("due_date").
					SetOldValue(existing.DueDate.Format("2006-01-02")).
					SetNewValue(*req.DueDate).
					SetDisplayText(fmt.Sprintf("Срок: %s → %s", existing.DueDate.Format("02.01.2006"), dueDate.Format("02.01.2006"))).
					Save(c)
			}
			builder = builder.SetDueDate(dueDate)
		}
	}

	if req.PriorityID != nil && *req.PriorityID != existing.PriorityID {
		changeID, _ := getChangeTypeID(tx.Client(), c, "priority_changed")
		if changeID > 0 {
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("priority_id").
				SetOldValue(strconv.Itoa(existing.PriorityID)).
				SetNewValue(strconv.Itoa(*req.PriorityID)).
				SetDisplayText("Приоритет изменён").
				Save(c)
		}
		builder = builder.SetPriorityID(*req.PriorityID)
	}

	if req.StatusID != nil && *req.StatusID != existing.StatusID {
		changeID, _ := getChangeTypeID(tx.Client(), c, "status_changed")
		if changeID > 0 {
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("status_id").
				SetOldValue(strconv.Itoa(existing.StatusID)).
				SetNewValue(strconv.Itoa(*req.StatusID)).
				SetDisplayText("Статус изменён").
				Save(c)
		}
		builder = builder.SetStatusID(*req.StatusID)
	}

	if req.Progress != nil && *req.Progress != existing.Progress {
		changeID, _ := getChangeTypeID(tx.Client(), c, "progress_changed")
		if changeID > 0 {
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("progress").
				SetOldValue(fmt.Sprintf("%d%%", existing.Progress)).
				SetNewValue(fmt.Sprintf("%d%%", *req.Progress)).
				SetDisplayText(fmt.Sprintf("Прогресс: %d%% → %d%%", existing.Progress, *req.Progress)).
				Save(c)
		}
		builder = builder.SetProgress(*req.Progress)

		// Auto-complete at 100%
		if *req.Progress == 100 {
			completedStatus, err := h.client.TaskStatus.Query().
				Where(taskstatus.CodeEQ("completed")).Only(c)
			if err == nil {
				builder = builder.SetStatusID(completedStatus.ID)
			}
		}
	}

	if req.CategoryID != nil {
		builder = builder.SetCategoryID(*req.CategoryID)
	}

	if req.AssignedTo != nil {
		changeID, _ := getChangeTypeID(tx.Client(), c, "assignee_changed")
		if changeID > 0 {
			tx.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("assigned_to").
				SetDisplayText("Исполнитель изменён").
				Save(c)
		}
		builder = builder.SetAssignedTo(*req.AssignedTo)
	}

	// Update assignees
	if len(req.Assignees) > 0 {
		// Get user role
		updater, err := tx.User.Query().Where(user.IDEQ(userID)).WithRole().Only(c)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения роли"})
			return
		}
		canDirectAssign := updater.Edges.Role != nil && (updater.Edges.Role.Name == "asutp_chief" || updater.Edges.Role.Name == "admin")

		// Delete existing assignees for this task
		taskWithAssignees, err := tx.Task.Query().Where(task.IDEQ(id)).WithTaskAssignees().Only(c)
		if err != nil {
			fmt.Printf("ERROR: loading task with assignees: %v\n", err)
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка загрузки задачи"})
			return
		}
		for _, ta := range taskWithAssignees.Edges.TaskAssignees {
			if err := tx.TaskAssignee.DeleteOneID(ta.ID).Exec(c); err != nil {
				fmt.Printf("ERROR: deleting assignee %d: %v\n", ta.ID, err)
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка удаления старых назначений"})
				return
			}
		}

		for _, assigneeID := range req.Assignees {
			b := tx.TaskAssignee.Create().
				AddTaskIDs(id).
				AddUserIDs(assigneeID).
				AddProposerIDs(userID)
			if canDirectAssign {
				b = b.SetStatus("approved").AddApproverIDs(userID).SetApprovedAt(time.Now())
			}
			_, err := b.Save(c)
			if err != nil {
				fmt.Printf("ERROR: creating assignee for user %d on task %d: %v\n", assigneeID, id, err)
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка назначения исполнителей"})
				return
			}
		}

		if !canDirectAssign {
			_ = h.notifyApprovers(c, id, existing.Title, userID)
		}
	}

	if _, err := builder.Save(c); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления задачи"})
		return
	}

	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения"})
		return
	}

	// Reload
	t, _ := h.client.Task.Query().
		Where(task.IDEQ(id)).
		WithPriority().WithStatus().WithCategory().WithCreator().WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser().WithProposer().WithApprover()
		}).
		Only(c)

	c.JSON(http.StatusOK, taskToJSON(t))
}

func (h *TaskHandler) ApproveAssignee(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID задачи"})
		return
	}
	assigneeID, err := strconv.Atoi(c.Param("assignee_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID назначения"})
		return
	}

	userID := c.GetInt("user_id")

	ta, err := h.client.TaskAssignee.Query().
		Where(taskassignee.IDEQ(assigneeID)).
		WithProposer().
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Назначение не найдено"})
		return
	}

	if ta.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Назначение уже обработано"})
		return
	}

	_, err = h.client.TaskAssignee.UpdateOneID(assigneeID).
		SetStatus("approved").
		AddApproverIDs(userID).
		SetApprovedAt(time.Now()).
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка одобрения"})
		return
	}

	// Notify proposer
	if len(ta.Edges.Proposer) > 0 {
		ntID, _ := getNotificationTypeID(h.client, c, "system")
		if ntID == 0 {
			ntID = 4
		}
		_, err := h.client.Notification.Create().
			SetUserID(ta.Edges.Proposer[0].ID).
			SetTaskID(id).
			SetTitle("Исполнитель одобрен").
			SetBody(fmt.Sprintf("Ваш предложенный исполнитель для задачи одобрен")).
			SetNotificationTypeID(ntID).
			SetScheduledAt(time.Now()).
			Save(c)
		if err != nil {
			fmt.Printf("ERROR: failed to create approval notification: %v\n", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Исполнитель одобрен"})
}

func (h *TaskHandler) RejectAssignee(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID задачи"})
		return
	}
	assigneeID, err := strconv.Atoi(c.Param("assignee_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID назначения"})
		return
	}

	ta, err := h.client.TaskAssignee.Query().
		Where(taskassignee.IDEQ(assigneeID)).
		WithProposer().
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Назначение не найдено"})
		return
	}

	if ta.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Назначение уже обработано"})
		return
	}

	_, err = h.client.TaskAssignee.UpdateOneID(assigneeID).
		SetStatus("rejected").
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка отклонения"})
		return
	}

	// Notify proposer
	if len(ta.Edges.Proposer) > 0 {
		ntID, _ := getNotificationTypeID(h.client, c, "system")
		if ntID == 0 {
			ntID = 4
		}
		_, err := h.client.Notification.Create().
			SetUserID(ta.Edges.Proposer[0].ID).
			SetTaskID(id).
			SetTitle("Исполнитель отклонён").
			SetBody(fmt.Sprintf("Ваш предложенный исполнитель для задачи отклонён")).
			SetNotificationTypeID(ntID).
			SetScheduledAt(time.Now()).
			Save(c)
		if err != nil {
			fmt.Printf("ERROR: failed to create reject notification: %v\n", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Исполнитель отклонён"})
}

func (h *TaskHandler) Delete(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	if err := h.client.Task.DeleteOneID(id).Exec(c); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Задача не найдена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Задача удалена"})
}

func (h *TaskHandler) History(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	histories, err := h.client.TaskHistory.Query().
		Where(taskhistory.TaskIDEQ(id)).
		WithUser().
		WithChangeType().
		Order(ent.Desc(taskhistory.FieldChangedAt)).
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения истории"})
		return
	}

	result := make([]gin.H, 0, len(histories))
	for _, h := range histories {
		item := gin.H{
			"id":           h.ID,
			"changed_at":   h.ChangedAt.Format(time.RFC3339),
			"display_text": h.DisplayText,
			"field_name":   h.FieldName,
			"old_value":    h.OldValue,
			"new_value":    h.NewValue,
		}
		if h.Edges.User != nil {
			item["user"] = gin.H{
				"id":        h.Edges.User.ID,
				"full_name": h.Edges.User.FullName,
				"initials":  h.Edges.User.Initials,
			}
		}
		if h.Edges.ChangeType != nil {
			item["change_type"] = h.Edges.ChangeType.Code
		}
		result = append(result, item)
	}

	c.JSON(http.StatusOK, gin.H{"history": result})
}

func (h *TaskHandler) ExportCSV(c *gin.Context) {
	tasks, err := h.client.Task.Query().
		WithPriority().WithStatus().WithCategory().WithCreator().WithAssignee().
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения задач"})
		return
	}

	c.Header("Content-Type", "text/csv; charset=utf-8")
	c.Header("Content-Disposition", "attachment; filename=tasks_export.csv")

	// BOM for Excel
	c.Writer.Write([]byte{0xEF, 0xBB, 0xBF})

	w := csv.NewWriter(c.Writer)
	w.Comma = ';'

	w.Write([]string{"ID", "Название", "Описание", "Срок", "Приоритет", "Статус", "Категория", "Прогресс", "Автор", "Исполнитель", "Создана"})

	for _, t := range tasks {
		desc := ""
		if t.Description != nil {
			desc = *t.Description
		}
		priority := ""
		if t.Edges.Priority != nil {
			priority = t.Edges.Priority.Name
		}
		status := ""
		if t.Edges.Status != nil {
			status = t.Edges.Status.Code
		}
		category := ""
		if t.Edges.Category != nil {
			category = t.Edges.Category.Name
		}
		creator := ""
		if t.Edges.Creator != nil {
			creator = t.Edges.Creator.FullName
		}
		assignee := ""
		if t.Edges.Assignee != nil {
			assignee = t.Edges.Assignee.FullName
		}

		w.Write([]string{
			strconv.Itoa(t.ID),
			t.Title,
			desc,
			t.DueDate.Format("02.01.2006"),
			priority,
			status,
			category,
			fmt.Sprintf("%d%%", t.Progress),
			creator,
			assignee,
			t.CreatedAt.Format("02.01.2006 15:04"),
		})
	}

	w.Flush()
}

func taskToJSON(t *ent.Task) gin.H {
	result := gin.H{
		"id":         t.ID,
		"title":      t.Title,
		"due_date":   t.DueDate.Format("2006-01-02"),
		"progress":   t.Progress,
		"created_at": t.CreatedAt.Format(time.RFC3339),
		"updated_at": t.UpdatedAt.Format(time.RFC3339),
	}

	if t.Description != nil {
		result["description"] = *t.Description
	}

	if t.Edges.Priority != nil {
		result["priority"] = gin.H{
			"id":        t.Edges.Priority.ID,
			"name":      t.Edges.Priority.Name,
			"color_hex": t.Edges.Priority.ColorHex,
		}
	}
	if t.Edges.Status != nil {
		result["status"] = gin.H{
			"id":          t.Edges.Status.ID,
			"code":        t.Edges.Status.Code,
			"is_terminal": t.Edges.Status.IsTerminal,
		}
	}
	if t.Edges.Category != nil {
		result["category"] = gin.H{
			"id":              t.Edges.Category.ID,
			"name":            t.Edges.Category.Name,
			"icon_identifier": t.Edges.Category.IconIdentifier,
		}
	}
	if t.Edges.Creator != nil {
		result["creator"] = gin.H{
			"id":        t.Edges.Creator.ID,
			"full_name": t.Edges.Creator.FullName,
			"initials":  t.Edges.Creator.Initials,
		}
	}
	if t.Edges.Assignee != nil {
		result["assignee"] = gin.H{
			"id":        t.Edges.Assignee.ID,
			"full_name": t.Edges.Assignee.FullName,
			"initials":  t.Edges.Assignee.Initials,
		}
	}

	// New: proposed/approved assignees
	assignees := make([]gin.H, 0, len(t.Edges.TaskAssignees))
	for _, ta := range t.Edges.TaskAssignees {
		item := gin.H{
			"id":     ta.ID,
			"status": ta.Status,
		}
		if len(ta.Edges.User) > 0 {
			item["user"] = gin.H{
				"id":        ta.Edges.User[0].ID,
				"full_name": ta.Edges.User[0].FullName,
				"initials":  ta.Edges.User[0].Initials,
			}
		}
		if len(ta.Edges.Proposer) > 0 {
			item["proposed_by"] = gin.H{
				"id":        ta.Edges.Proposer[0].ID,
				"full_name": ta.Edges.Proposer[0].FullName,
			}
		}
		if len(ta.Edges.Approver) > 0 {
			item["approved_by"] = gin.H{
				"id":        ta.Edges.Approver[0].ID,
				"full_name": ta.Edges.Approver[0].FullName,
			}
			item["approved_at"] = ta.ApprovedAt.Format(time.RFC3339)
		}
		assignees = append(assignees, item)
	}
	result["assignees"] = assignees

	return result
}

func (h *TaskHandler) notifyApprovers(c *gin.Context, taskID int, taskTitle string, proposerID int) error {
	// Find asutp_chief and admin users
	approvers, err := h.client.User.Query().
		Where(user.HasRoleWith(role.NameIn("asutp_chief", "admin"))).
		All(c)
	if err != nil {
		return err
	}

	ntID, _ := getNotificationTypeID(h.client, c, "system")
	if ntID == 0 {
		ntID = 4 // fallback
	}

	for _, u := range approvers {
		if u.ID == proposerID {
			continue // Don't notify self
		}
		_, err := h.client.Notification.Create().
			SetUserID(u.ID).
			SetTaskID(taskID).
			SetTitle("Новое назначение на задачу").
			SetBody(fmt.Sprintf("Задача \"%s\" — предложены исполнители", taskTitle)).
			SetNotificationTypeID(ntID).
			SetScheduledAt(time.Now()).
			Save(c)
		if err != nil {
			fmt.Printf("ERROR: failed to create notification for user %d: %v\n", u.ID, err)
		}
	}
	return nil
}

func getChangeTypeID(client *ent.Client, c *gin.Context, code string) (int, error) {
	ct, err := client.ChangeType.Query().
		Where(changetype.CodeEQ(code)).
		Only(c)
	if err != nil {
		return 0, err
	}
	return ct.ID, nil
}

func getNotificationTypeID(client *ent.Client, c *gin.Context, code string) (int, error) {
	nt, err := client.NotificationType.Query().
		Where(notificationtype.CodeEQ(code)).
		Only(c)
	if err != nil {
		return 0, err
	}
	return nt.ID, nil
}
