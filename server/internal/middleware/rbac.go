package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Роли АСУТП:
//   admin          — Администратор системы (конфигурация, пользователи, справочники)
//   chief_engineer — Главный инженер (создаёт задачи, контролирует прогресс)
//   asutp_chief    — Начальник службы АСУТП (управляет выполнением задач, меняет прогресс)
//   engineer       — Инженер (только просмотр задач и уведомления)
//   operator       — Оператор (только просмотр, эксплуатация)

// RequireRole проверяет наличие одной из разрешённых ролей
func RequireRole(roles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole, exists := c.Get("role")
		if !exists {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "Роль не определена"})
			return
		}

		roleName, ok := userRole.(string)
		if !ok {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"error": "Ошибка определения роли"})
			return
		}

		for _, allowed := range roles {
			if roleName == allowed {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error": "Недостаточно прав для выполнения операции",
		})
	}
}

// RequireAdmin — только администратор системы
func RequireAdmin() gin.HandlerFunc {
	return RequireRole("admin")
}

// RequireTaskManager — может создавать/редактировать задачи и менять прогресс
// Главный инженер, Нач. службы АСУТП, Администратор
func RequireTaskManager() gin.HandlerFunc {
	return RequireRole("admin", "chief_engineer", "asutp_chief")
}

// RequireExport — может экспортировать данные
// Главный инженер, Нач. службы АСУТП, Администратор
func RequireExport() gin.HandlerFunc {
	return RequireRole("admin", "chief_engineer", "asutp_chief")
}

// RequireApprover — может одобрять/отклонять назначения
// Главный инженер, Администратор
func RequireApprover() gin.HandlerFunc {
	return RequireRole("admin", "chief_engineer")
}

// CanManageTasks проверяет может ли роль управлять задачами
func CanManageTasks(role string) bool {
	return role == "admin" || role == "chief_engineer" || role == "asutp_chief"
}
