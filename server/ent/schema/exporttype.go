package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type ExportType struct {
	ent.Schema
}

func (ExportType) Fields() []ent.Field {
	return []ent.Field{
		field.String("code").
			MaxLen(20).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				for _, v := range []string{"all", "completed", "selected"} {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid export type: %s", s)
			}),
	}
}

func (ExportType) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("export_logs", ExportLog.Type),
	}
}
