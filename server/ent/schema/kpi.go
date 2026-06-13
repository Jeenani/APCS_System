package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type Kpi struct {
	ent.Schema
}

func (Kpi) Fields() []ent.Field {
	return []ent.Field{
		field.Int("task_id"),
		field.Int("user_id"),
		field.Float("score").
			Min(0).
			Max(100),
		field.Bool("is_confirmed").
			Default(false),
		field.Time("confirmed_at").
			Optional().
			Nillable(),
		field.Int("confirmed_by").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

func (Kpi) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("task", Task.Type).
			Ref("kpis").
			Field("task_id").
			Required().
			Unique(),
		edge.From("user", User.Type).
			Ref("kpis").
			Field("user_id").
			Required().
			Unique(),
		edge.From("confirmer", User.Type).
			Ref("confirmed_kpis").
			Field("confirmed_by").
			Unique(),
	}
}
