package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type TaskStatus struct {
	ent.Schema
}

func (TaskStatus) Fields() []ent.Field {
	return []ent.Field{
		field.String("code").
			MaxLen(20).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				for _, v := range []string{"new", "in_progress", "completed", "cancelled", "archived"} {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid task status: %s", s)
			}),
		field.Bool("is_terminal").
			Default(false),
	}
}

func (TaskStatus) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("tasks", Task.Type),
	}
}
