package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"asutp-server/ent"
	"asutp-server/internal/config"
	"asutp-server/internal/handler"
	"asutp-server/internal/middleware"
	"asutp-server/internal/seed"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Ошибка загрузки конфигурации: %v", err)
	}

	var client *ent.Client
	for i := 0; i < 10; i++ {
		client, err = ent.Open("postgres", cfg.DB.DSN())
		if err == nil {
			break
		}
		log.Printf("Ожидание БД (попытка %d/10): %v", i+1, err)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		log.Fatalf("Ошибка подключения к БД: %v", err)
	}
	defer client.Close()

	ctx := context.Background()
	for i := 0; i < 10; i++ {
		err = client.Schema.Create(ctx)
		if err == nil {
			break
		}
		log.Printf("Ожидание миграции (попытка %d/10): %v", i+1, err)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		log.Fatalf("Ошибка миграции БД: %v", err)
	}
	if err := seed.Run(ctx, client); err != nil {
		log.Fatalf("Ошибка seed: %v", err)
	}

	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	authH := handler.NewAuthHandler(client, cfg)
	taskH := handler.NewTaskHandler(client)
	notifH := handler.NewNotificationHandler(client)
	profileH := handler.NewProfileHandler(client)
	refH := handler.NewReferenceHandler(client)
	adminH := handler.NewAdminHandler(client)

	api := r.Group("/api/v1")

	// ========== ПУБЛИЧНЫЕ ==========
	auth := api.Group("/auth")
	auth.POST("/login", authH.Login)
	auth.POST("/register", authH.Register)
	auth.POST("/refresh", authH.RefreshToken)

	refs := api.Group("/references")
	refs.GET("/priorities", refH.GetPriorities)
	refs.GET("/statuses", refH.GetStatuses)
	refs.GET("/categories", refH.GetCategories)
	refs.GET("/roles", refH.GetRoles)

	// ========== АВТОРИЗОВАННЫЕ (все роли — просмотр) ==========
	allAuth := api.Group("")
	allAuth.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
	allAuth.POST("/auth/logout", authH.Logout)
	allAuth.GET("/tasks", taskH.List)       // Все видят задачи
	allAuth.GET("/tasks/:id", taskH.Get)    // Все видят детали
	allAuth.GET("/tasks/:id/history", taskH.History) // Все видят историю
	allAuth.GET("/my-kpi", taskH.GetKPI)
	allAuth.GET("/notifications", notifH.List)
	allAuth.PUT("/notifications/:id/read", notifH.MarkRead)
	allAuth.PUT("/notifications/read-all", notifH.MarkAllRead)
	allAuth.GET("/profile", profileH.GetProfile)
	allAuth.PUT("/profile/notification-settings", profileH.UpdateNotificationSettings)
	allAuth.GET("/references/assignees", refH.GetAssignees)

	// ========== TASK MANAGERS (chief_engineer, asutp_chief, admin) ==========
	taskMgr := api.Group("")
	taskMgr.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
	taskMgr.Use(middleware.RequireTaskManager())
	taskMgr.POST("/tasks", taskH.Create)
	taskMgr.PUT("/tasks/:id", taskH.Update)
	taskMgr.GET("/export/csv", taskH.ExportCSV)
	taskMgr.POST("/tasks/:id/confirm-completion", taskH.ConfirmCompletion)

	// ========== TASK COMPLETER (operator, asutp_chief, admin) ==========
	completer := api.Group("")
	completer.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
	completer.Use(middleware.RequireRole("admin", "asutp_chief", "operator"))
	completer.POST("/tasks/:id/complete", taskH.CompleteTask)

	// ========== APPROVER (chief_engineer, admin) ==========
	approver := api.Group("")
	approver.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
	approver.Use(middleware.RequireApprover())
	approver.DELETE("/tasks/:id", taskH.Delete)
	approver.POST("/tasks/:id/assignees/:assignee_id/approve", taskH.ApproveAssignee)
	approver.POST("/tasks/:id/assignees/:assignee_id/reject", taskH.RejectAssignee)

	// ========== ТОЛЬКО ADMIN ==========
	adminApi := api.Group("/admin")
	adminApi.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
	adminApi.Use(middleware.RequireAdmin())
	adminApi.GET("/users", adminH.ListUsers)
	adminApi.POST("/users", adminH.CreateUser)
	adminApi.PUT("/users/:id", adminH.UpdateUser)
	adminApi.DELETE("/users/:id", adminH.DeleteUser)
	adminApi.POST("/categories", adminH.CreateCategory)
	adminApi.PUT("/categories/:id", adminH.UpdateCategory)
	adminApi.DELETE("/categories/:id", adminH.DeleteCategory)

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "АСУТП Tasks API", "mode": cfg.AppMode})
	})

	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("АСУТП Tasks API [%s] → %s", cfg.AppMode, addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Ошибка запуска: %v", err)
	}
}
