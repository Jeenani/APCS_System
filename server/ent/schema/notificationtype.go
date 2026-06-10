package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type NotificationType struct {
	ent.Schema
}

func (NotificationType) Fields() []ent.Field {
	return []ent.Field{
		field.String("code").
			MaxLen(20).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				for _, v := range []string{"reminder", "deadline", "update", "system"} {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid notification type: %s", s)
			}),
	}
}

func (NotificationType) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("notifications", Notification.Type),
	}
}
