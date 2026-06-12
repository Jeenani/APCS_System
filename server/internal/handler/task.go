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
	ParentID    *int   `json:"parent_id"`
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
	ParentID    *int    `json:"parent_id"`
}

func (h *TaskHandler) List(c *gin.Context) {
	query := h.client.Task.Query().
		WithPriority().
		WithStatus().
		WithCategory().
		WithCreator().
		WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser()
		}).
		WithChildren().
		Order(ent.Desc(task.FieldCreatedAt))

	// Engineers only see tasks they created or are approved assignees on
	userID := c.GetInt("user_id")
	if roleVal, ok := c.Get("role"); ok {
		if roleName, ok := roleVal.(string); ok && roleName == "engineer" {
			query = query.Where(task.Or(
				task.CreatedByEQ(userID),
				task.HasTaskAssigneesWith(
					taskassignee.UserIDEQ(userID),
					taskassignee.StatusEQ("approved"),
				),
			))
		}
	}

	// Parent filter: default top-level only, unless specific parent_id requested
	if parentID := c.Query("parent_id"); parentID != "" {
		if pid, err := strconv.Atoi(parentID); err == nil {
			query = query.Where(task.ParentIDEQ(pid))
		}
	} else if c.Query("include_subtasks") != "true" {
		query = query.Where(task.ParentIDIsNil())
	}

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
			q.WithUser()
		}).
		WithParent(func(q *ent.TaskQuery) {
			q.WithPriority().WithStatus().WithCategory()
		}).
		WithChildren(func(q *ent.TaskQuery) {
			q.WithPriority().WithStatus().WithCreator()
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

	// Validate parent_id if provided
	if req.ParentID != nil {
		parentExists, err := tx.Task.Query().Where(task.IDEQ(*req.ParentID)).Exist(c)
		if err != nil || !parentExists {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Родительская задача не найдена"})
			return
		}
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
	if req.ParentID != nil {
		builder = builder.SetParentID(*req.ParentID)
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
	canDirectAssign := proposer.Edges.Role != nil && (proposer.Edges.Role.Name == "chief_engineer" || proposer.Edges.Role.Name == "asutp_chief" || proposer.Edges.Role.Name == "admin")

	// Create assignees
	for _, assigneeID := range req.Assignees {
		builder := tx.TaskAssignee.Create().
			SetTaskID(t.ID).
			SetUserID(assigneeID).
			SetProposerID(userID)
		if canDirectAssign {
			builder = builder.
				SetStatus("approved").
				SetApproverID(userID).
				SetApprovedAt(time.Now())
		}
		_, err := builder.Save(c)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка назначения исполнителей"})
			return
		}
	}

	// Notify chief_engineer about new proposals only from non-direct assigners
	if len(req.Assignees) > 0 && !canDirectAssign {
		_ = h.notifyApprovers(c, t.ID, t.Title, userID)
	}

	// Recalculate parent progress if this is a subtask
	if req.ParentID != nil {
		if err := h.recalculateParentProgress(tx, c, *req.ParentID); err != nil {
			fmt.Printf("ERROR recalculating parent progress after create: %v\n", err)
		}
	}

	// Create history entry
	taskCreatedType, _ := getChangeTypeID(tx.Client(), c, "task_created")
	if taskCreatedType > 0 {
		h.client.TaskHistory.Create().
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
	t, err = h.client.Task.Query().
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
	if err != nil {
		fmt.Printf("ERROR reloading task after create: %v\n", err)
		c.JSON(http.StatusCreated, gin.H{
			"id": t.ID, "title": t.Title, "due_date": t.DueDate.Format("2006-01-02"),
			"progress": t.Progress, "created_at": t.CreatedAt.Format(time.RFC3339),
			"updated_at": t.UpdatedAt.Format(time.RFC3339),
		})
		return
	}

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
			h.client.TaskHistory.Create().
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
			h.client.TaskHistory.Create().
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
				h.client.TaskHistory.Create().
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
			h.client.TaskHistory.Create().
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
			h.client.TaskHistory.Create().
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
			h.client.TaskHistory.Create().
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
			h.client.TaskHistory.Create().
				SetTaskID(id).SetChangedBy(userID).SetChangeTypeID(changeID).
				SetFieldName("assigned_to").
				SetDisplayText("Исполнитель изменён").
				Save(c)
		}
		builder = builder.SetAssignedTo(*req.AssignedTo)
	}

	// Update parent_id
	if req.ParentID != nil {
		// Prevent self-parenting
		if *req.ParentID == id {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Задача не может быть родителем самой себя"})
			return
		}
		// Prevent circular reference: check if proposed parent is a descendant
		if *req.ParentID != 0 {
			parentExists, err := tx.Task.Query().Where(task.IDEQ(*req.ParentID)).Exist(c)
			if err != nil || !parentExists {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Родительская задача не найдена"})
				return
			}
			// Simple circular check: walk up the parent chain
			currentParentID := *req.ParentID
			visited := map[int]bool{id: true}
			for currentParentID != 0 {
				if visited[currentParentID] {
					c.JSON(http.StatusBadRequest, gin.H{"error": "Циклическая ссылка в родительских задачах"})
					return
				}
				visited[currentParentID] = true
				p, err := tx.Task.Query().Where(task.IDEQ(currentParentID)).Select(task.FieldParentID).Only(c)
				if err != nil {
					break
				}
				if p.ParentID == nil {
					break
				}
				currentParentID = *p.ParentID
			}
			builder = builder.SetParentID(*req.ParentID)
		} else {
			builder = builder.ClearParentID()
		}
	}

	// Update assignees
	if req.Assignees != nil {
		// Get user role
		updater, err := tx.User.Query().Where(user.IDEQ(userID)).WithRole().Only(c)
		if err != nil {
			fmt.Printf("ERROR getting user role: userID=%d, err=%v\n", userID, err)
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения роли"})
			return
		}
		canDirectAssign := updater.Edges.Role != nil && (updater.Edges.Role.Name == "chief_engineer" || updater.Edges.Role.Name == "asutp_chief" || updater.Edges.Role.Name == "admin")

		// Load existing assignees for this task
		taskWithAssignees, err := tx.Task.Query().Where(task.IDEQ(id)).WithTaskAssignees().Only(c)
		if err != nil {
			fmt.Printf("ERROR: loading task with assignees: %v\n", err)
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка загрузки задачи"})
			return
		}

		// Track which users already have approved/rejected entries (preserve decisions)
		existingDecisions := make(map[int]string) // userID -> status
		for _, ta := range taskWithAssignees.Edges.TaskAssignees {
			existingDecisions[ta.UserID] = ta.Status
			// Only delete pending proposals; approved/rejected stay intact
			if ta.Status == "pending" {
				if err := tx.TaskAssignee.DeleteOneID(ta.ID).Exec(c); err != nil {
					fmt.Printf("ERROR: deleting pending assignee %d: %v\n", ta.ID, err)
					tx.Rollback()
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка удаления старых назначений"})
					return
				}
			}
		}

		for _, assigneeID := range req.Assignees {
			// Skip if user already has an approved/rejected decision
			if status, ok := existingDecisions[assigneeID]; ok && status != "pending" {
				continue
			}
			b := tx.TaskAssignee.Create().
				SetTaskID(id).
				SetUserID(assigneeID).
				SetProposerID(userID)
			if canDirectAssign {
				b = b.SetStatus("approved").SetApproverID(userID).SetApprovedAt(time.Now())
			}
			_, err := b.Save(c)
			if err != nil {
				fmt.Printf("ERROR: creating assignee for user %d on task %d: %v\n", assigneeID, id, err)
				tx.Rollback()
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка назначения исполнителей"})
				return
			}
		}

		if !canDirectAssign && len(req.Assignees) > 0 {
			_ = h.notifyApprovers(c, id, existing.Title, userID)
		}
	}

	if _, err := builder.Save(c); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления задачи"})
		return
	}

	// Recalculate parent progress for any affected parents
	parentsToRecalc := make(map[int]struct{})
	if existing.ParentID != nil {
		parentsToRecalc[*existing.ParentID] = struct{}{}
	}
	// After save, reload to get the potentially new parent_id
	updatedTask, _ := tx.Task.Get(c, id)
	if updatedTask != nil && updatedTask.ParentID != nil {
		parentsToRecalc[*updatedTask.ParentID] = struct{}{}
	}
	for pid := range parentsToRecalc {
		if err := h.recalculateParentProgress(tx, c, pid); err != nil {
			fmt.Printf("ERROR recalculating parent progress after update: %v\n", err)
		}
	}

	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения"})
		return
	}

	// Reload
	tReload, err := h.client.Task.Query().
		Where(task.IDEQ(id)).
		WithPriority().WithStatus().WithCategory().WithCreator().WithAssignee().
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser()
		}).
		Only(c)
	if err != nil {
		fmt.Printf("ERROR reloading task after update: %v\n", err)
		c.JSON(http.StatusOK, taskToJSON(existing))
		return
	}

	c.JSON(http.StatusOK, taskToJSON(tReload))
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
		SetApproverID(userID).
		SetApprovedAt(time.Now()).
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка одобрения"})
		return
	}

	// Notify proposer
	if ta.Edges.Proposer != nil {
		ntID, _ := getNotificationTypeID(h.client, c, "system")
		if ntID == 0 {
			ntID = 4
		}
		_, err := h.client.Notification.Create().
			SetUserID(ta.Edges.Proposer.ID).
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
	if ta.Edges.Proposer != nil {
		ntID, _ := getNotificationTypeID(h.client, c, "system")
		if ntID == 0 {
			ntID = 4
		}
		_, err := h.client.Notification.Create().
			SetUserID(ta.Edges.Proposer.ID).
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

	// Check if task has children
	hasChildren, err := h.client.Task.Query().Where(task.HasChildren()).Where(task.IDEQ(id)).Exist(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка проверки подзадач"})
		return
	}
	if hasChildren {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Нельзя удалить задачу с подзадачами. Сначала удалите подзадачи."})
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
	if t.ParentID != nil {
		result["parent_id"] = *t.ParentID
	}
	if t.Edges.Parent != nil {
		result["parent"] = gin.H{
			"id":    t.Edges.Parent.ID,
			"title": t.Edges.Parent.Title,
		}
		if t.Edges.Parent.Edges.Status != nil {
			result["parent"].(gin.H)["status"] = t.Edges.Parent.Edges.Status.Code
		}
	}
	if len(t.Edges.Children) > 0 {
		children := make([]gin.H, 0, len(t.Edges.Children))
		for _, child := range t.Edges.Children {
			item := gin.H{
				"id":       child.ID,
				"title":    child.Title,
				"progress": child.Progress,
				"due_date": child.DueDate.Format("2006-01-02"),
			}
			if child.Edges.Status != nil {
				item["status"] = gin.H{
					"code": child.Edges.Status.Code,
				}
			}
			if child.Edges.Creator != nil {
				item["creator"] = gin.H{
					"id":        child.Edges.Creator.ID,
					"full_name": child.Edges.Creator.FullName,
					"initials":  child.Edges.Creator.Initials,
				}
			}
			children = append(children, item)
		}
		result["children"] = children
		result["children_count"] = len(children)
	}

	// New: proposed/approved assignees
	assignees := make([]gin.H, 0, len(t.Edges.TaskAssignees))
	for _, ta := range t.Edges.TaskAssignees {
		item := gin.H{
			"id":     ta.ID,
			"status": ta.Status,
		}
		if ta.Edges.User != nil {
			item["user"] = gin.H{
				"id":        ta.Edges.User.ID,
				"full_name": ta.Edges.User.FullName,
				"initials":  ta.Edges.User.Initials,
			}
		}
		if ta.Edges.Proposer != nil {
			item["proposed_by"] = gin.H{
				"id":        ta.Edges.Proposer.ID,
				"full_name": ta.Edges.Proposer.FullName,
			}
		}
		if ta.Edges.Approver != nil {
			item["approved_by"] = gin.H{
				"id":        ta.Edges.Approver.ID,
				"full_name": ta.Edges.Approver.FullName,
			}
			if ta.ApprovedAt != nil {
				item["approved_at"] = ta.ApprovedAt.Format(time.RFC3339)
			}
		}
		assignees = append(assignees, item)
	}
	result["assignees"] = assignees

	return result
}

func (h *TaskHandler) notifyApprovers(c *gin.Context, taskID int, taskTitle string, proposerID int) error {
	// Find chief_engineer and admin users to notify
	approvers, err := h.client.User.Query().
		Where(user.HasRoleWith(role.NameIn("chief_engineer", "admin"))).
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

func (h *TaskHandler) recalculateParentProgress(tx *ent.Tx, c *gin.Context, parentID int) error {
	children, err := tx.Task.Query().Where(task.ParentIDEQ(parentID)).All(c)
	if err != nil {
		return err
	}
	if len(children) == 0 {
		return nil
	}

	var total int16
	for _, child := range children {
		total += child.Progress
	}
	avg := int16(total / int16(len(children)))

	_, err = tx.Task.UpdateOneID(parentID).SetProgress(avg).Save(c)
	if err != nil {
		return err
	}

	// Recurse to grandparent
	p, err := tx.Task.Get(c, parentID)
	if err != nil {
		return err
	}
	if p.ParentID != nil {
		return h.recalculateParentProgress(tx, c, *p.ParentID)
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
