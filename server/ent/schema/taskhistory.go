package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type TaskHistory struct {
	ent.Schema
}

func (TaskHistory) Fields() []ent.Field {
	return []ent.Field{
		field.Int("task_id"),
		field.Int("changed_by"),
		field.Int("change_type_id"),
		field.String("field_name").
			MaxLen(100).
			Optional().
			Nillable(),
		field.Text("old_value").
			Optional().
			Nillable(),
		field.Text("new_value").
			Optional().
			Nillable(),
		field.String("display_text").
			MaxLen(500).
			Optional().
			Nillable(),
		field.Time("changed_at").
			Default(time.Now).
			Immutable(),
	}
}

func (TaskHistory) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("task", Task.Type).
			Ref("histories").
			Field("task_id").
			Required().
			Unique(),
		edge.From("user", User.Type).
			Ref("task_histories").
			Field("changed_by").
			Required().
			Unique(),
		edge.From("change_type", ChangeType.Type).
			Ref("task_histories").
			Field("change_type_id").
			Required().
			Unique(),
	}
}
