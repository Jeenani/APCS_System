package handler

import (
	"net/http"

	"asutp-server/ent"
	"asutp-server/ent/notificationsetting"
	"asutp-server/ent/task"
	"asutp-server/ent/taskstatus"
	"asutp-server/ent/user"

	"github.com/gin-gonic/gin"
)

type ProfileHandler struct {
	client *ent.Client
}

func NewProfileHandler(client *ent.Client) *ProfileHandler {
	return &ProfileHandler{client: client}
}

func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userID := c.GetInt("user_id")

	u, err := h.client.User.Query().
		Where(user.IDEQ(userID)).
		WithRole().
		WithNotificationSetting().
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Пользователь не найден"})
		return
	}

	// Stats
	totalTasks, _ := h.client.Task.Query().
		Where(task.Or(task.CreatedByEQ(userID), task.AssignedToEQ(userID))).
		Count(c)

	completedTasks, _ := h.client.Task.Query().
		Where(
			task.Or(task.CreatedByEQ(userID), task.AssignedToEQ(userID)),
			task.HasStatusWith(taskstatus.CodeEQ("completed")),
		).
		Count(c)

	inProgressTasks := totalTasks - completedTasks
	completionPercent := 0
	if totalTasks > 0 {
		completionPercent = (completedTasks * 100) / totalTasks
	}

	roleName := ""
	roleLabel := ""
	if u.Edges.Role != nil {
		roleName = u.Edges.Role.Name
		switch roleName {
		case "admin":
			roleLabel = "Администратор системы"
		case "chief_engineer":
			roleLabel = "Главный инженер"
		case "asutp_chief":
			roleLabel = "Начальник службы АСУТП"
		case "engineer":
			roleLabel = "Инженер АСУТП"
		case "operator":
			roleLabel = "Оператор"
		}
	}

	result := gin.H{
		"id":           u.ID,
		"login":        u.Login,
		"full_name":    u.FullName,
		"initials":     u.Initials,
		"role":         roleName,
		"role_label":   roleLabel,
		"avatar_color": u.AvatarColor,
		"stats": gin.H{
			"total":              totalTasks,
			"completed":          completedTasks,
			"in_progress":        inProgressTasks,
			"completion_percent": completionPercent,
		},
	}

	if u.Edges.NotificationSetting != nil {
		ns := u.Edges.NotificationSetting
		result["notification_settings"] = gin.H{
			"push_enabled":           ns.PushEnabled,
			"sound_enabled":          ns.SoundEnabled,
			"vibration_enabled":      ns.VibrationEnabled,
			"reminder_days_before":   ns.ReminderDaysBefore,
			"quiet_hours_start":      ns.QuietHoursStart,
			"quiet_hours_end":        ns.QuietHoursEnd,
			"notify_high_priority":   ns.NotifyHighPriority,
			"notify_medium_priority": ns.NotifyMediumPriority,
			"notify_low_priority":    ns.NotifyLowPriority,
		}
	}

	c.JSON(http.StatusOK, result)
}

type updateSettingsRequest struct {
	PushEnabled          *bool   `json:"push_enabled"`
	SoundEnabled         *bool   `json:"sound_enabled"`
	VibrationEnabled     *bool   `json:"vibration_enabled"`
	ReminderDaysBefore   *int16  `json:"reminder_days_before"`
	QuietHoursStart      *string `json:"quiet_hours_start"`
	QuietHoursEnd        *string `json:"quiet_hours_end"`
	NotifyHighPriority   *bool   `json:"notify_high_priority"`
	NotifyMediumPriority *bool   `json:"notify_medium_priority"`
	NotifyLowPriority    *bool   `json:"notify_low_priority"`
}

func (h *ProfileHandler) UpdateNotificationSettings(c *gin.Context) {
	userID := c.GetInt("user_id")

	var req updateSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте корректность данных"})
		return
	}

	ns, err := h.client.NotificationSetting.Query().
		Where(notificationsetting.UserIDEQ(userID)).
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Настройки не найдены"})
		return
	}

	builder := h.client.NotificationSetting.UpdateOneID(ns.ID)

	if req.PushEnabled != nil {
		builder = builder.SetPushEnabled(*req.PushEnabled)
	}
	if req.SoundEnabled != nil {
		builder = builder.SetSoundEnabled(*req.SoundEnabled)
	}
	if req.VibrationEnabled != nil {
		builder = builder.SetVibrationEnabled(*req.VibrationEnabled)
	}
	if req.ReminderDaysBefore != nil {
		builder = builder.SetReminderDaysBefore(*req.ReminderDaysBefore)
	}
	if req.QuietHoursStart != nil {
		builder = builder.SetQuietHoursStart(*req.QuietHoursStart)
	}
	if req.QuietHoursEnd != nil {
		builder = builder.SetQuietHoursEnd(*req.QuietHoursEnd)
	}
	if req.NotifyHighPriority != nil {
		builder = builder.SetNotifyHighPriority(*req.NotifyHighPriority)
	}
	if req.NotifyMediumPriority != nil {
		builder = builder.SetNotifyMediumPriority(*req.NotifyMediumPriority)
	}
	if req.NotifyLowPriority != nil {
		builder = builder.SetNotifyLowPriority(*req.NotifyLowPriority)
	}

	if _, err := builder.Save(c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения настроек"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Настройки сохранены"})
}
