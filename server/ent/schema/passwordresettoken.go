package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type PasswordResetToken struct {
	ent.Schema
}

func (PasswordResetToken) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id"),
		field.String("token_hash").
			MaxLen(255).
			NotEmpty().
			Unique(),
		field.Time("expires_at"),
		field.Time("used_at").
			Optional().
			Nillable(),
		field.Time("created_at").
			Default(time.Now).
			Immutable(),
	}
}

func (PasswordResetToken) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("password_reset_tokens").
			Field("user_id").
			Required().
			Unique(),
	}
}
