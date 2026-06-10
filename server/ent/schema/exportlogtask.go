package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type ExportLogTask struct {
	ent.Schema
}

func (ExportLogTask) Fields() []ent.Field {
	return []ent.Field{
		field.Int("export_log_id"),
		field.Int("task_id"),
	}
}

func (ExportLogTask) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("export_log", ExportLog.Type).
			Ref("export_log_tasks").
			Field("export_log_id").
			Required().
			Unique(),
		edge.To("task", Task.Type).
			Field("task_id").
			Required().
			Unique(),
	}
}
