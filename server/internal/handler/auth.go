package handler

import (
	"crypto/sha256"
	"fmt"
	"net/http"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/refreshtoken"
	"asutp-server/ent/user"
	"asutp-server/internal/config"
	"asutp-server/internal/middleware"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	client *ent.Client
	cfg    *config.Config
}

func NewAuthHandler(client *ent.Client, cfg *config.Config) *AuthHandler {
	return &AuthHandler{client: client, cfg: cfg}
}

type loginRequest struct {
	Login    string `json:"login" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type registerRequest struct {
	Login    string `json:"login" binding:"required,min=3,max=100"`
	Password string `json:"password" binding:"required,min=6"`
	FullName string `json:"full_name" binding:"required"`
	RoleID   int    `json:"role_id" binding:"required"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный формат данных"})
		return
	}

	u, err := h.client.User.Query().
		Where(user.LoginEQ(req.Login)).
		WithRole().
		Only(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный логин или пароль"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный логин или пароль"})
		return
	}

	if !u.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Аккаунт деактивирован"})
		return
	}

	roleName := ""
	if u.Edges.Role != nil {
		roleName = u.Edges.Role.Name
	}

	accessToken, err := middleware.GenerateAccessToken(
		h.cfg.JWT.Secret, u.ID, u.Login, roleName, h.cfg.JWT.AccessTTL,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	// Generate refresh token
	refreshRaw := fmt.Sprintf("%d-%s-%d", u.ID, u.Login, time.Now().UnixNano())
	refreshHash := fmt.Sprintf("%x", sha256.Sum256([]byte(refreshRaw)))

	_, err = h.client.RefreshToken.Create().
		SetUserID(u.ID).
		SetTokenHash(refreshHash).
		SetExpiresAt(time.Now().Add(h.cfg.JWT.RefreshTTL)).
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания refresh token"})
		return
	}

	// Update last_login_at
	h.client.User.UpdateOneID(u.ID).
		SetLastLoginAt(time.Now()).
		Exec(c)

	c.JSON(http.StatusOK, gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshHash,
		"user": gin.H{
			"id":           u.ID,
			"login":        u.Login,
			"full_name":    u.FullName,
			"initials":     u.Initials,
			"role":         roleName,
			"avatar_color": u.AvatarColor,
		},
	})
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Проверьте корректность данных"})
		return
	}

	// Check duplicate login
	exists, _ := h.client.User.Query().Where(user.LoginEQ(req.Login)).Exist(c)
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "Логин уже занят"})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка хеширования пароля"})
		return
	}

	initials := generateInitials(req.FullName)

	tx, err := h.client.Tx(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка транзакции"})
		return
	}

	u, err := tx.User.Create().
		SetLogin(req.Login).
		SetPasswordHash(string(hash)).
		SetFullName(req.FullName).
		SetInitials(initials).
		SetRoleID(req.RoleID).
		Save(c)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания пользователя"})
		return
	}

	// Create notification settings
	_, err = tx.NotificationSetting.Create().
		SetUserID(u.ID).
		Save(c)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания настроек"})
		return
	}

	if err := tx.Commit(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":        u.ID,
		"login":     u.Login,
		"full_name": u.FullName,
		"initials":  u.Initials,
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Требуется refresh_token"})
		return
	}

	rt, err := h.client.RefreshToken.Query().
		Where(
			refreshtoken.TokenHashEQ(req.RefreshToken),
			refreshtoken.RevokedAtIsNil(),
			refreshtoken.ExpiresAtGT(time.Now()),
		).
		WithUser(func(q *ent.UserQuery) {
			q.WithRole()
		}).
		Only(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Недействительный refresh token"})
		return
	}

	u := rt.Edges.User
	roleName := ""
	if u.Edges.Role != nil {
		roleName = u.Edges.Role.Name
	}

	accessToken, err := middleware.GenerateAccessToken(
		h.cfg.JWT.Secret, u.ID, u.Login, roleName, h.cfg.JWT.AccessTTL,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token": accessToken,
	})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Требуется refresh_token"})
		return
	}

	now := time.Now()
	h.client.RefreshToken.Update().
		Where(refreshtoken.TokenHashEQ(req.RefreshToken)).
		SetRevokedAt(now).
		Exec(c)

	c.JSON(http.StatusOK, gin.H{"message": "Выход выполнен"})
}

func generateInitials(fullName string) string {
	runes := []rune(fullName)
	if len(runes) == 0 {
		return "?"
	}
	initials := string(runes[0])
	for i, r := range runes {
		if r == ' ' && i+1 < len(runes) {
			initials += string(runes[i+1])
			break
		}
	}
	return initials
}
