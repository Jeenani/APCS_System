package schema

import (
	"fmt"
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

type NotificationSetting struct {
	ent.Schema
}

func (NotificationSetting) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").
			Unique(),
		field.Bool("push_enabled").
			Default(true),
		field.Bool("sound_enabled").
			Default(true),
		field.Bool("vibration_enabled").
			Default(false),
		field.Int16("reminder_days_before").
			Default(3).
			Validate(func(v int16) error {
				for _, d := range []int16{1, 3, 7} {
					if v == d {
						return nil
					}
				}
				return fmt.Errorf("reminder_days_before must be 1, 3, or 7")
			}),
		field.String("quiet_hours_start").
			Default("22:00"),
		field.String("quiet_hours_end").
			Default("08:00"),
		field.Bool("notify_high_priority").
			Default(true),
		field.Bool("notify_medium_priority").
			Default(true),
		field.Bool("notify_low_priority").
			Default(false),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now),
	}
}

func (NotificationSetting) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("notification_setting").
			Field("user_id").
			Required().
			Unique(),
	}
}
