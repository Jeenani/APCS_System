package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type RefreshToken struct {
	ent.Schema
}

func (RefreshToken) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id"),
		field.String("token_hash").
			MaxLen(255).
			NotEmpty().
			Unique(),
		field.String("device_info").
			MaxLen(500).
			Optional().
			Nillable(),
		field.Time("expires_at"),
		field.Time("revoked_at").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

func (RefreshToken) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("refresh_tokens").
			Field("user_id").
			Required().
			Unique(),
	}
}
