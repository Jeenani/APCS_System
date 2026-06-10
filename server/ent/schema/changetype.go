package schema

import (
	"fmt"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type ChangeType struct {
	ent.Schema
}

func (ChangeType) Fields() []ent.Field {
	return []ent.Field{
		field.String("code").
			MaxLen(30).
			NotEmpty().
			Unique().
			Validate(func(s string) error {
				valid := []string{
					"task_created", "title_changed", "description_changed",
					"due_date_changed", "priority_changed", "progress_changed",
					"status_changed", "assignee_changed",
				}
				for _, v := range valid {
					if s == v {
						return nil
					}
				}
				return fmt.Errorf("invalid change type: %s", s)
			}),
	}
}

func (ChangeType) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("task_histories", TaskHistory.Type),
	}
}
