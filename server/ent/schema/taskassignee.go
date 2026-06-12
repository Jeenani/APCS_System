package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type TaskAssignee struct {
	ent.Schema
}

func (TaskAssignee) Fields() []ent.Field {
	return []ent.Field{
		field.String("status").
			MaxLen(20).
			Default("pending").
			NotEmpty(),
		field.Time("approved_at").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
		field.Int("task_id"),
		field.Int("user_id"),
		field.Int("proposer_id"),
		field.Int("approver_id").
			Optional().
			Nillable(),
	}
}

func (TaskAssignee) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("task", Task.Type).
			Ref("task_assignees").
			Field("task_id").
			Required().
			Unique(),
		edge.From("user", User.Type).
			Ref("task_assignee_entries").
			Field("user_id").
			Required().
			Unique(),
		edge.From("proposer", User.Type).
			Ref("proposed_assignees").
			Field("proposer_id").
			Required().
			Unique(),
		edge.From("approver", User.Type).
			Ref("approved_assignees").
			Field("approver_id").
			Unique(),
	}
}
