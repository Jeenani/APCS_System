package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type Priority struct {
	ent.Schema
}

func (Priority) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			MaxLen(10).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				for _, v := range []string{"high", "medium", "low"} {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid priority: %s", s)
			}),
		field.String("color_hex").
			MaxLen(7).
			NotEmpty(),
		field.Int16("sort_order").
			Unique(),
	}
}

func (Priority) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("tasks", Task.Type),
		edge.To("notifications", Notification.Type),
	}
}
