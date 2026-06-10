package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type ExportLog struct {
	ent.Schema
}

func (ExportLog) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id"),
		field.Int("export_type_id"),
		field.String("file_name").
			MaxLen(255).
			Optional().
			Nillable(),
		field.Int("record_count").
			Optional().
			Nillable(),
		field.Time("exported_at").
			Default(time.Now).
			Immutable(),
	}
}

func (ExportLog) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("export_logs").
			Field("user_id").
			Required().
			Unique(),
		edge.From("export_type", ExportType.Type).
			Ref("export_logs").
			Field("export_type_id").
			Required().
			Unique(),
		edge.To("export_log_tasks", ExportLogTask.Type),
	}
}
