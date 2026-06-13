package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type Task struct {
	ent.Schema
}

func (Task) Fields() []ent.Field {
	return []ent.Field{
		field.String("title").
			MaxLen(500).
			NotEmpty(),
		field.Text("description").
			Optional().
			Nillable(),
		field.Time("due_date"),
		field.Int("priority_id"),
		field.Int("status_id"),
		field.Int("category_id").
			Optional().
			Nillable(),
		field.Int16("progress").
			Default(0).
			Min(0).
			Max(100),
		field.Int("created_by"),
		field.Int("assigned_to").
			Optional().
			Nillable(),
		field.Int("parent_id").
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

func (Task) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("priority", Priority.Type).
			Ref("tasks").
			Field("priority_id").
			Required().
			Unique(),
		edge.From("status", TaskStatus.Type).
			Ref("tasks").
			Field("status_id").
			Required().
			Unique(),
		edge.From("category", TaskCategory.Type).
			Ref("tasks").
			Field("category_id").
			Unique(),
		edge.From("creator", User.Type).
			Ref("created_tasks").
			Field("created_by").
			Required().
			Unique(),
		edge.From("assignee", User.Type).
			Ref("assigned_tasks").
			Field("assigned_to").
			Unique(),
		edge.To("children", Task.Type).
			From("parent").
			Field("parent_id").
			Unique(),
		edge.To("task_assignees", TaskAssignee.Type),
		edge.To("histories", TaskHistory.Type),
		edge.To("notifications", Notification.Type),
		edge.To("kpis", Kpi.Type),
	}
}
