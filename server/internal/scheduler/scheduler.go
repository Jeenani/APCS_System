package scheduler

import (
	"context"
	"fmt"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/notification"
	"asutp-server/ent/notificationtype"
	"asutp-server/ent/task"
	"asutp-server/ent/taskstatus"
)

// StartDeadlineScheduler запускает фоновую горутину,
// которая раз в час проверяет приближающиеся сроки задач
// и создаёт уведомления исполнителям и создателям.
func StartDeadlineScheduler(client *ent.Client) {
	go runDeadlineCheck(client)
	// Тикер: раз в час
	ticker := time.NewTicker(1 * time.Hour)
	go func() {
		for range ticker.C {
			runDeadlineCheck(client)
		}
	}()
}

func runDeadlineCheck(client *ent.Client) {
	ctx := context.Background()
	now := time.Now()
	tomorrow := now.Add(24 * time.Hour)

	// Находим тип уведомления "deadline"
	nt, err := client.NotificationType.Query().
		Where(notificationtype.CodeEQ("deadline")).
		Only(ctx)
	if err != nil {
		fmt.Printf("SCHEDULER ERROR: deadline notification type not found: %v\n", err)
		return
	}

	// Задачи со сроком завтра или сегодня, не архивированные и не завершённые
	tasks, err := client.Task.Query().
		Where(
			task.DueDateLTE(tomorrow),
			task.DueDateGTE(now.Add(-24*time.Hour)),
			task.Not(task.HasStatusWith(taskstatus.CodeIn("archived", "completed", "cancelled"))),
		).
		WithTaskAssignees(func(q *ent.TaskAssigneeQuery) {
			q.WithUser()
		}).
		WithCreator().
		All(ctx)
	if err != nil {
		fmt.Printf("SCHEDULER ERROR: failed to query tasks: %v\n", err)
		return
	}

	for _, t := range tasks {
		hoursLeft := t.DueDate.Sub(now).Hours()
		var title, body string
		switch {
		case hoursLeft < 0:
			title = "Срок задачи истёк"
			body = fmt.Sprintf("Задача \"%s\" просрочена (срок: %s)", t.Title, t.DueDate.Format("02.01.2006"))
		case hoursLeft <= 24:
			title = "Срок задачи завтра"
			body = fmt.Sprintf("Задача \"%s\" должна быть выполнена завтра (%s)", t.Title, t.DueDate.Format("02.01.2006"))
		default:
			continue
		}

		// Уведомляем одобренных исполнителей
		for _, ta := range t.Edges.TaskAssignees {
			if ta.Status != "approved" || ta.Edges.User == nil {
				continue
			}
			// Проверяем, не отправляли ли уже за последние 24 часа
			alreadySent, _ := client.Notification.Query().
				Where(
					notification.UserID(ta.Edges.User.ID),
					notification.TaskID(t.ID),
					notification.Title(title),
					notification.CreatedAtGT(now.Add(-24*time.Hour)),
				).
				Exist(ctx)
			if alreadySent {
				continue
			}
			_, err := client.Notification.Create().
				SetUserID(ta.Edges.User.ID).
				SetTaskID(t.ID).
				SetTitle(title).
				SetBody(body).
				SetNotificationTypeID(nt.ID).
				SetScheduledAt(now).
				Save(ctx)
			if err != nil {
				fmt.Printf("SCHEDULER ERROR: failed to create deadline notification for user %d: %v\n", ta.Edges.User.ID, err)
			}
		}

		// Уведомляем создателя задачи
		if t.Edges.Creator != nil {
			alreadySent, _ := client.Notification.Query().
				Where(
					notification.UserID(t.Edges.Creator.ID),
					notification.TaskID(t.ID),
					notification.Title(title),
					notification.CreatedAtGT(now.Add(-24*time.Hour)),
				).
				Exist(ctx)
			if alreadySent {
				continue
			}
			_, err := client.Notification.Create().
				SetUserID(t.Edges.Creator.ID).
				SetTaskID(t.ID).
				SetTitle(title).
				SetBody(body).
				SetNotificationTypeID(nt.ID).
				SetScheduledAt(now).
				Save(ctx)
			if err != nil {
				fmt.Printf("SCHEDULER ERROR: failed to create deadline notification for creator %d: %v\n", t.Edges.Creator.ID, err)
			}
		}
	}
}
