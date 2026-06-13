package handler

import (
	"net/http"
	"strconv"

	"asutp-server/ent"
	"asutp-server/ent/user"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// AdminHandler — управление пользователями и справочниками (только admin)
type AdminHandler struct {
	client *ent.Client
}

func NewAdminHandler(client *ent.Client) *AdminHandler {
	return &AdminHandler{client: client}
}

// ==================== ПОЛЬЗОВАТЕЛИ ====================

func (h *AdminHandler) ListUsers(c *gin.Context) {
	users, err := h.client.User.Query().
		WithRole().
		Order(ent.Asc(user.FieldID)).
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения пользователей"})
		return
	}

	result := make([]gin.H, 0, len(users))
	for _, u := range users {
		roleName := ""
		if u.Edges.Role != nil {
			roleName = u.Edges.Role.Name
		}
		result = append(result, gin.H{
			"id":        u.ID,
			"login":     u.Login,
			"full_name": u.FullName,
			"initials":  u.Initials,
			"role":      roleName,
			"is_active": u.IsActive,
			"created_at": u.CreatedAt,
		})
	}
	c.JSON(http.StatusOK, gin.H{"users": result, "count": len(result)})
}

func (h *AdminHandler) CreateUser(c *gin.Context) {
	var req struct {
		Login    string `json:"login" binding:"required"`
		Password string `json:"password" binding:"required,min=6"`
		FullName string `json:"full_name" binding:"required"`
		RoleID   int    `json:"role_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте корректность данных"})
		return
	}

	if err := validateFullName(req.FullName); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := validatePassword(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	exists, _ := h.client.User.Query().Where(user.LoginEQ(req.Login)).Exist(c)
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "Логин уже занят"})
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	initials := generateInitials(req.FullName)

	u, err := h.client.User.Create().
		SetLogin(req.Login).
		SetPasswordHash(string(hash)).
		SetFullName(req.FullName).
		SetInitials(initials).
		SetRoleID(req.RoleID).
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания пользователя"})
		return
	}

	// Создаём настройки уведомлений
	h.client.NotificationSetting.Create().SetUserID(u.ID).Save(c)

	c.JSON(http.StatusCreated, gin.H{
		"id":        u.ID,
		"login":     u.Login,
		"full_name": u.FullName,
		"initials":  u.Initials,
	})
}

func (h *AdminHandler) UpdateUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	var req struct {
		FullName *string `json:"full_name"`
		RoleID   *int    `json:"role_id"`
		IsActive *bool   `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте данные"})
		return
	}

	builder := h.client.User.UpdateOneID(id)
	if req.FullName != nil {
		builder = builder.SetFullName(*req.FullName).SetInitials(generateInitials(*req.FullName))
	}
	if req.RoleID != nil {
		builder = builder.SetRoleID(*req.RoleID)
	}
	if req.IsActive != nil {
		builder = builder.SetIsActive(*req.IsActive)
	}

	if _, err := builder.Save(c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Пользователь обновлён"})
}

func (h *AdminHandler) DeleteUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	// Деактивируем, не удаляем
	h.client.User.UpdateOneID(id).SetIsActive(false).Save(c)
	c.JSON(http.StatusOK, gin.H{"message": "Пользователь деактивирован"})
}

// ==================== СПРАВОЧНИКИ ====================

// --- Категории задач ---
func (h *AdminHandler) CreateCategory(c *gin.Context) {
	var req struct {
		Name           string `json:"name" binding:"required"`
		IconIdentifier string `json:"icon_identifier" binding:"required"`
		Description    string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте данные"})
		return
	}

	builder := h.client.TaskCategory.Create().
		SetName(req.Name).
		SetIconIdentifier(req.IconIdentifier)
	if req.Description != "" {
		builder = builder.SetDescription(req.Description)
	}

	cat, err := builder.Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания категории"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": cat.ID, "name": cat.Name})
}

func (h *AdminHandler) UpdateCategory(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	var req struct {
		Name           *string `json:"name"`
		IconIdentifier *string `json:"icon_identifier"`
		Description    *string `json:"description"`
		IsActive       *bool   `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте данные"})
		return
	}

	builder := h.client.TaskCategory.UpdateOneID(id)
	if req.Name != nil {
		builder = builder.SetName(*req.Name)
	}
	if req.IconIdentifier != nil {
		builder = builder.SetIconIdentifier(*req.IconIdentifier)
	}
	if req.Description != nil {
		builder = builder.SetDescription(*req.Description)
	}
	if req.IsActive != nil {
		builder = builder.SetIsActive(*req.IsActive)
	}

	if _, err := builder.Save(c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Категория обновлена"})
}

func (h *AdminHandler) DeleteCategory(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}
	if err := h.client.TaskCategory.DeleteOneID(id).Exec(c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка удаления"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Категория удалена"})
}
