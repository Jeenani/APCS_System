package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type User struct {
	ent.Schema
}

func (User) Fields() []ent.Field {
	return []ent.Field{
		field.String("login").
			MaxLen(100).
			NotEmpty().
			Unique(),
		field.String("password_hash").
			MaxLen(255).
			NotEmpty().
			Sensitive(),
		field.String("full_name").
			MaxLen(200).
			NotEmpty(),
		field.String("initials").
			MaxLen(10).
			NotEmpty(),
		field.Int("role_id"),
		field.String("avatar_color").
			MaxLen(7).
			Default("#1565C0"),
		field.Bool("is_active").
			Default(true),
		field.Time("last_login_at").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now),
	}
}

func (User) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("role", Role.Type).
			Ref("users").
			Field("role_id").
			Required().
			Unique(),
		edge.To("notification_setting", NotificationSetting.Type).
			Unique(),
		edge.To("created_tasks", Task.Type),
		edge.To("assigned_tasks", Task.Type),
		edge.To("task_assignee_entries", TaskAssignee.Type),
		edge.To("proposed_assignees", TaskAssignee.Type),
		edge.To("approved_assignees", TaskAssignee.Type),
		edge.To("task_histories", TaskHistory.Type),
		edge.To("notifications", Notification.Type),
		edge.To("export_logs", ExportLog.Type),
		edge.To("password_reset_tokens", PasswordResetToken.Type),
		edge.To("refresh_tokens", RefreshToken.Type),
		edge.To("kpis", Kpi.Type),
		edge.To("confirmed_kpis", Kpi.Type),
	}
}
