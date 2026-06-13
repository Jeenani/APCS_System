package handler

import (
	"crypto/sha256"
	"crypto/tls"
	"fmt"
	"math/rand"
	"net"
	"net/http"
	"net/smtp"
	"regexp"
	"strconv"
	"time"

	"asutp-server/ent"
	"asutp-server/ent/passwordresettoken"
	"asutp-server/ent/refreshtoken"
	"asutp-server/ent/role"
	"asutp-server/ent/user"
	"asutp-server/internal/config"
	"asutp-server/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/resend/resend-go/v3"
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
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type registerRequest struct {
	Email    string `json:"email" binding:"required,email"`
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
		Where(user.EmailEQ(req.Email)).
		WithRole().
		Only(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный email или пароль"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный email или пароль"})
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
		h.cfg.JWT.Secret, u.ID, u.Email, roleName, h.cfg.JWT.AccessTTL,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	// Generate refresh token
	refreshRaw := fmt.Sprintf("%d-%s-%d", u.ID, u.Email, time.Now().UnixNano())
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
			"full_name":    u.FullName,
			"initials":     u.Initials,
			"role":         roleName,
			"avatar_color": u.AvatarColor,
			"email":        u.Email,
		},
	})
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
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
	if err := validateEmail(req.Email); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	emailExists, _ := h.client.User.Query().Where(user.EmailEQ(req.Email)).Exist(c)
	if emailExists {
		c.JSON(http.StatusConflict, gin.H{"error": "Email уже используется"})
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
		SetEmail(req.Email).
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
		"email":     u.Email,
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
		h.cfg.JWT.Secret, u.ID, u.Email, roleName, h.cfg.JWT.AccessTTL,
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

func validateFullName(name string) error {
	if len([]rune(name)) < 2 {
		return fmt.Errorf("ФИО должно содержать минимум 2 символа")
	}
	if len([]rune(name)) > 200 {
		return fmt.Errorf("ФИО не должно превышать 200 символов")
	}
	for _, r := range name {
		if r >= '0' && r <= '9' {
			return fmt.Errorf("ФИО не должно содержать цифры")
		}
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 8 {
		return fmt.Errorf("Пароль должен содержать минимум 8 символов")
	}
	var hasUpper, hasLower, hasDigit, hasSpecial bool
	for _, r := range password {
		switch {
		case r >= 'A' && r <= 'Z':
			hasUpper = true
		case r >= 'a' && r <= 'z':
			hasLower = true
		case r >= '0' && r <= '9':
			hasDigit = true
		case r >= '!' && r <= '/' || r >= ':' && r <= '@' || r >= '[' && r <= '`' || r >= '{' && r <= '~':
			hasSpecial = true
		}
	}
	if !hasUpper {
		return fmt.Errorf("Пароль должен содержать минимум одну заглавную букву")
	}
	if !hasLower {
		return fmt.Errorf("Пароль должен содержать минимум одну строчную букву")
	}
	if !hasDigit {
		return fmt.Errorf("Пароль должен содержать минимум одну цифру")
	}
	if !hasSpecial {
		return fmt.Errorf("Пароль должен содержать минимум один специальный символ")
	}
	return nil
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

func validateEmail(email string) error {
	re := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !re.MatchString(email) {
		return fmt.Errorf("Некорректный формат email")
	}
	return nil
}

func generateTempPassword() string {
	const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%"
	b := make([]byte, 12)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

func (h *AuthHandler) sendEmail(to, subject, body string) error {
	from := h.cfg.EmailFrom
	if from == "" {
		from = "noreply@missednoteserv.chickenkiller.com"
	}

	// Try SMTP first if configured
	if h.cfg.SMTP.Host != "" {
		msg := []byte("To: " + to + "\r\n" +
			"From: " + from + "\r\n" +
			"Subject: " + subject + "\r\n" +
			"MIME-Version: 1.0\r\n" +
			"Content-Type: text/plain; charset=\"utf-8\"\r\n" +
			"\r\n" +
			body + "\r\n")
		addr := h.cfg.SMTP.Host + ":" + h.cfg.SMTP.Port

		if h.cfg.SMTP.Port == "587" {
			conn, err := net.Dial("tcp", addr)
			if err != nil {
				return fmt.Errorf("smtp dial: %w", err)
			}
			defer conn.Close()

			client, err := smtp.NewClient(conn, h.cfg.SMTP.Host)
			if err != nil {
				return fmt.Errorf("smtp client: %w", err)
			}
			defer client.Close()

			if ok, _ := client.Extension("STARTTLS"); ok {
				tlsConfig := &tls.Config{ServerName: h.cfg.SMTP.Host}
				if err = client.StartTLS(tlsConfig); err != nil {
					return fmt.Errorf("smtp starttls: %w", err)
				}
			}

			if h.cfg.SMTP.User != "" && h.cfg.SMTP.Pass != "" {
				auth := smtp.PlainAuth("", h.cfg.SMTP.User, h.cfg.SMTP.Pass, h.cfg.SMTP.Host)
				if err = client.Auth(auth); err != nil {
					return fmt.Errorf("smtp auth: %w", err)
				}
			}

			if err = client.Mail(from); err != nil {
				return err
			}
			if err = client.Rcpt(to); err != nil {
				return err
			}
			w, err := client.Data()
			if err != nil {
				return err
			}
			_, err = w.Write(msg)
			if err != nil {
				return err
			}
			if err = w.Close(); err != nil {
				return err
			}
			return client.Quit()
		}

		// Plain or SSL (465)
		var auth smtp.Auth
		if h.cfg.SMTP.User != "" && h.cfg.SMTP.Pass != "" {
			auth = smtp.PlainAuth("", h.cfg.SMTP.User, h.cfg.SMTP.Pass, h.cfg.SMTP.Host)
		}
		return smtp.SendMail(addr, auth, from, []string{to}, msg)
	}

	// Fallback to Resend
	apiKey := h.cfg.ResendAPIKey
	if apiKey == "" {
		return fmt.Errorf("RESEND_API_KEY=your_resend_api_key_here не настроен")
	}
	client := resend.NewClient(apiKey)
	params := &resend.SendEmailRequest{
		From:    from,
		To:      []string{to},
		Subject: subject,
		Text:    body,
	}
	_, err := client.Emails.Send(params)
	return err
}

// ForgotPassword — user requests password reset, admin gets notified
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Укажите email"})
		return
	}

	u, err := h.client.User.Query().
		Where(user.EmailEQ(req.Email)).
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Пользователь не найден"})
		return
	}

	if u.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "У пользователя не указан email. Обратитесь к администратору."})
		return
	}

	// Check for existing pending request
	pendingExists, _ := h.client.PasswordResetToken.Query().
		Where(
			passwordresettoken.UserIDEQ(u.ID),
			passwordresettoken.StatusEQ("pending"),
			passwordresettoken.ExpiresAtGT(time.Now()),
		).
		Exist(c)
	if pendingExists {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Запрос на сброс уже отправлен. Ожидайте подтверждения администратора."})
		return
	}

	// Create token
	tokenRaw := fmt.Sprintf("%d-%s-%d", u.ID, req.Email, time.Now().UnixNano())
	tokenHash := fmt.Sprintf("%x", sha256.Sum256([]byte(tokenRaw)))
	_, err = h.client.PasswordResetToken.Create().
		SetUserID(u.ID).
		SetTokenHash(tokenHash).
		SetStatus("pending").
		SetExpiresAt(time.Now().Add(24 * time.Hour)).
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка создания запроса"})
		return
	}

	// Notify admins
	admins, _ := h.client.User.Query().
		Where(
			user.HasRoleWith(role.NameIn("admin", "chief_engineer")),
		).
		All(c)

	ntID, _ := getNotificationTypeID(h.client, c, "system")
	if ntID == 0 {
		ntID = 4
	}
	for _, admin := range admins {
		_, _ = h.client.Notification.Create().
			SetUserID(admin.ID).
			SetTitle("Запрос сброса пароля").
			SetBody(fmt.Sprintf("Пользователь %s запросил сброс пароля", u.FullName)).
			SetNotificationTypeID(ntID).
			SetScheduledAt(time.Now()).
			Save(c)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Запрос отправлен администратору на подтверждение"})
}

// GetResetRequests — admin view
func (h *AuthHandler) GetResetRequests(c *gin.Context) {
	roleVal, _ := c.Get("role")
	roleName, _ := roleVal.(string)
	if roleName != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Недостаточно прав"})
		return
	}

	requests, err := h.client.PasswordResetToken.Query().
		Where(passwordresettoken.StatusEQ("pending")).
		WithUser(func(q *ent.UserQuery) {
			q.WithRole()
		}).
		Order(ent.Desc(passwordresettoken.FieldCreatedAt)).
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка загрузки запросов"})
		return
	}

	result := make([]gin.H, 0)
	for _, r := range requests {
		item := gin.H{
			"id":         r.ID,
			"status":     r.Status,
			"created_at": r.CreatedAt,
			"expires_at": r.ExpiresAt,
		}
		if r.Edges.User != nil {
			item["user"] = gin.H{
				"id":        r.Edges.User.ID,
				"full_name": r.Edges.User.FullName,
				"email":     "",
			}
			if r.Edges.User.Email != "" {
				item["user"].(gin.H)["email"] = r.Edges.User.Email
			}
		}
		result = append(result, item)
	}
	c.JSON(http.StatusOK, result)
}

// ApproveReset — admin approves and sends temp password via SMTP
func (h *AuthHandler) ApproveReset(c *gin.Context) {
	roleVal, _ := c.Get("role")
	roleName, _ := roleVal.(string)
	if roleName != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Недостаточно прав"})
		return
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	token, err := h.client.PasswordResetToken.Query().
		Where(passwordresettoken.IDEQ(id)).
		WithUser().
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Запрос не найден"})
		return
	}

	if token.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Запрос уже обработан"})
		return
	}

	u := token.Edges.User
	if u.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "У пользователя нет email"})
		return
	}

	// Generate temp password
	tempPass := generateTempPassword()
	hash, err := bcrypt.GenerateFromPassword([]byte(tempPass), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации пароля"})
		return
	}

	// Update user password
	if err = h.client.User.UpdateOneID(u.ID).
		SetPasswordHash(string(hash)).
		Exec(c); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления пароля"})
		return
	}

	// Send email
	subject := "Восстановление пароля АСУТП Tasks"
	body := fmt.Sprintf("Здравствуйте, %s!\n\nАдминистратор подтвердил восстановление пароля.\n\nВаш временный пароль: %s\n\nРекомендуем сменить его после входа в систему.\n\n---\nАСУТП Tasks", u.FullName, tempPass)
	if err := h.sendEmail(u.Email, subject, body); err != nil {
		fmt.Printf("ERROR sending email: %v\n", err)
		// Even if email fails, password was changed. Log it.
	}

	// Mark token approved
	_, err = h.client.PasswordResetToken.UpdateOneID(id).
		SetStatus("approved").
		SetUsedAt(time.Now()).
		Save(c)
	if err != nil {
		fmt.Printf("ERROR updating token status: %v\n", err)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Восстановление подтверждено. Временный пароль отправлен на email."})
}

// RejectReset — admin rejects request
func (h *AuthHandler) RejectReset(c *gin.Context) {
	roleVal, _ := c.Get("role")
	roleName, _ := roleVal.(string)
	if roleName != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Недостаточно прав"})
		return
	}

	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ID"})
		return
	}

	token, err := h.client.PasswordResetToken.Query().
		Where(passwordresettoken.IDEQ(id)).
		WithUser().
		Only(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Запрос не найден"})
		return
	}

	if token.Status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Запрос уже обработан"})
		return
	}

	_, err = h.client.PasswordResetToken.UpdateOneID(id).
		SetStatus("rejected").
		Save(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления"})
		return
	}

	// Notify user
	ntID, _ := getNotificationTypeID(h.client, c, "system")
	if ntID == 0 {
		ntID = 4
	}
	_, _ = h.client.Notification.Create().
		SetUserID(token.Edges.User.ID).
		SetTitle("Запрос сброса пароля отклонён").
		SetBody("Администратор отклонил ваш запрос на восстановление пароля. Обратитесь к нему лично.").
		SetNotificationTypeID(ntID).
		SetScheduledAt(time.Now()).
		Save(c)

	c.JSON(http.StatusOK, gin.H{"message": "Запрос отклонён"})
}
