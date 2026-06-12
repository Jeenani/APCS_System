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
	}
}

func (TaskAssignee) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("task", Task.Type).
			Required(),
		edge.To("user", User.Type).
			Required(),
		edge.To("proposer", User.Type).
			Required(),
		edge.To("approver", User.Type),
	}
}
