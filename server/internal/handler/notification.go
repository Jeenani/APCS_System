package handler

import (
	"net/http"
	"strconv"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/notification"

	"github.com/gin-gonic/gin"
)

type NotificationHandler struct {
	client *ent.Client
}

func NewNotificationHandler(client *ent.Client) *NotificationHandler {
	return &NotificationHandler{client: client}
}

func (h *NotificationHandler) List(c *gin.Context) {
	userID := c.GetInt("user_id")

	query := h.client.Notification.Query().
		Where(notification.UserIDEQ(userID)).
		WithTask().
		WithNotificationType().
		WithPriority().
		Order(ent.Desc(notification.FieldCreatedAt))

	if unreadOnly := c.Query("unread"); unreadOnly == "true" {
		query = query.Where(notification.IsReadEQ(false))
	}

	notifications, err := query.All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения уведомлений"})
		return
	}

	result := make([]gin.H, 0, len(notifications))
	for _, n := range notifications {
		item := gin.H{
			"id":           n.ID,
			"title":        n.Title,
			"body":         n.Body,
			"is_read":      n.IsRead,
			"scheduled_at": n.ScheduledAt.Format(time.RFC3339),
			"created_at":   n.CreatedAt.Format(time.RFC3339),
		}
		if n.SentAt != nil {
			item["sent_at"] = n.SentAt.Format(time.RFC3339)
		}
		if n.Edges.Task != nil {
			item["task"] = gin.H{
				"id":    n.Edges.Task.ID,
				"title": n.Edges.Task.Title,
			}
		}
		if n.Edges.NotificationType != nil {
			item["type"] = n.Edges.NotificationType.Code
		}
		if n.Edges.Priority != nil {
			item["priority"] = gin.H{
				"name":      n.Edges.Priority.Name,
				"color_hex": n.Edges.Priority.ColorHex,
			}
		}
		result = append(result, item)
	}

	// Count unread
	unreadCount, _ := h.client.Notification.Query().
		Where(notification.UserIDEQ(userID), notification.IsReadEQ(false)).
		Count(c)

	c.JSON(http.StatusOK, gin.H{
		"notifications": result,
		"unread_count":  unreadCount,
	})
}

func (h *NotificationHandler) MarkRead(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	userID := c.GetInt("user_id")

	n, err := h.client.Notification.Query().
		Where(notification.IDEQ(id), notification.UserIDEQ(userID)).
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Уведомление не найдено"})
		return
	}

	h.client.Notification.UpdateOneID(n.ID).
		SetIsRead(true).
		Exec(c)

	c.JSON(http.StatusOK, gin.H{"message": "Отмечено как прочитанное"})
}

func (h *NotificationHandler) MarkAllRead(c *gin.Context) {
	userID := c.GetInt("user_id")

	h.client.Notification.Update().
		Where(notification.UserIDEQ(userID), notification.IsReadEQ(false)).
		SetIsRead(true).
		Exec(c)

	c.JSON(http.StatusOK, gin.H{"message": "Все уведомления прочитаны"})
}
