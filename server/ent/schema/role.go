package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type Role struct {
	ent.Schema
}

func (Role) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			MaxLen(30).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				for _, v := range []string{"admin", "chief_engineer", "asutp_chief", "engineer", "operator"} {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid role: %s", s)
			}),
	}
}

func (Role) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("users", User.Type),
	}
}
