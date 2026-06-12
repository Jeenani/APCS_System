package handler

import (
	"net/http"

	"asutp-server/ent"
	"asutp-server/ent/role"
	"asutp-server/ent/user"

	"github.com/gin-gonic/gin"
)

type ReferenceHandler struct {
	client *ent.Client
}

func NewReferenceHandler(client *ent.Client) *ReferenceHandler {
	return &ReferenceHandler{client: client}
}

func (h *ReferenceHandler) GetPriorities(c *gin.Context) {
	items, err := h.client.Priority.Query().
		Order(ent.Asc("sort_order")).
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка"})
		return
	}

	result := make([]gin.H, 0, len(items))
	for _, p := range items {
		result = append(result, gin.H{
			"id":         p.ID,
			"name":       p.Name,
			"color_hex":  p.ColorHex,
			"sort_order": p.SortOrder,
		})
	}
	c.JSON(http.StatusOK, result)
}

func (h *ReferenceHandler) GetStatuses(c *gin.Context) {
	items, err := h.client.TaskStatus.Query().All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка"})
		return
	}

	result := make([]gin.H, 0, len(items))
	for _, s := range items {
		result = append(result, gin.H{
			"id":          s.ID,
			"code":        s.Code,
			"is_terminal": s.IsTerminal,
		})
	}
	c.JSON(http.StatusOK, result)
}

func (h *ReferenceHandler) GetCategories(c *gin.Context) {
	items, err := h.client.TaskCategory.Query().All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка"})
		return
	}

	result := make([]gin.H, 0, len(items))
	for _, cat := range items {
		item := gin.H{
			"id":              cat.ID,
			"name":            cat.Name,
			"icon_identifier": cat.IconIdentifier,
			"is_active":       cat.IsActive,
		}
		if cat.Description != nil {
			item["description"] = *cat.Description
		}
		result = append(result, item)
	}
	c.JSON(http.StatusOK, result)
}

func (h *ReferenceHandler) GetRoles(c *gin.Context) {
	items, err := h.client.Role.Query().All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка"})
		return
	}

	result := make([]gin.H, 0, len(items))
	for _, r := range items {
		result = append(result, gin.H{
			"id":   r.ID,
			"name": r.Name,
		})
	}
	c.JSON(http.StatusOK, result)
}

func (h *ReferenceHandler) GetAssignees(c *gin.Context) {
	items, err := h.client.User.Query().
		Where(user.HasRoleWith(role.NameIn("chief_engineer", "engineer", "asutp_chief"))).
		Where(user.IsActiveEQ(true)).
		WithRole().
		All(c)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка"})
		return
	}

	result := make([]gin.H, 0, len(items))
	for _, u := range items {
		item := gin.H{
			"id":         u.ID,
			"full_name":  u.FullName,
			"initials":   u.Initials,
			"role_id":    u.RoleID,
			"role_name":  u.Edges.Role.Name,
		}
		result = append(result, item)
	}
	c.JSON(http.StatusOK, result)
}
