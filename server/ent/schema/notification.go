package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type Notification struct {
	ent.Schema
}

func (Notification) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id"),
		field.Int("task_id").
			Optional().
			Nillable(),
		field.String("title").
			MaxLen(500).
			NotEmpty(),
		field.Text("body").
			Optional().
			Nillable(),
		field.Int("notification_type_id"),
		field.Int("priority_id").
			Optional().
			Nillable(),
		field.Bool("is_read").
			Default(false),
		field.Time("scheduled_at"),
		field.Time("sent_at").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

func (Notification) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("notifications").
			Field("user_id").
			Required().
			Unique(),
		edge.From("task", Task.Type).
			Ref("notifications").
			Field("task_id").
			Unique(),
		edge.From("notification_type", NotificationType.Type).
			Ref("notifications").
			Field("notification_type_id").
			Required().
			Unique(),
		edge.From("priority", Priority.Type).
			Ref("notifications").
			Field("priority_id").
			Unique(),
	}
}
