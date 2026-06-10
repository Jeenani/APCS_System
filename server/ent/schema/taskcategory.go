package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type TaskCategory struct {
	ent.Schema
}

func (TaskCategory) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			MaxLen(100).
			NotEmpty().
			Unique(),
		field.String("icon_identifier").
			MaxLen(100).
			NotEmpty(),
		field.Text("description").
			Optional().
			Nillable(),
	}
}

func (TaskCategory) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("tasks", Task.Type),
	}
}
