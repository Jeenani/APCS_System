package config

import (
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	AppMode      string
	DB           DBConfig
	Server       ServerConfig
	JWT          JWTConfig
	ResendAPIKey string
	EmailFrom    string
	SMTP         SMTPConfig
}

type SMTPConfig struct {
	Host string
	Port string
	User string
	Pass string
}

type DBConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
	SSLMode  string
}

func (d DBConfig) DSN() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		d.Host, d.Port, d.User, d.Password, d.Name, d.SSLMode,
	)
}

type ServerConfig struct {
	Port string
}

type JWTConfig struct {
	Secret     string
	AccessTTL  time.Duration
	RefreshTTL time.Duration
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	accessTTL, err := time.ParseDuration(getEnv("JWT_ACCESS_TTL", "15m"))
	if err != nil {
		accessTTL = 15 * time.Minute
	}
	refreshTTL, err := time.ParseDuration(getEnv("JWT_REFRESH_TTL", "168h"))
	if err != nil {
		refreshTTL = 168 * time.Hour
	}

	return &Config{
		AppMode: getEnv("APP_MODE", "local"),
		DB: DBConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "5432"),
			User:     getEnv("DB_USER", "postgres"),
			Password: getEnv("DB_PASSWORD", "postgres"),
			Name:     getEnv("DB_NAME", "asutp_tasks"),
			SSLMode:  getEnv("DB_SSLMODE", "disable"),
		},
		Server: ServerConfig{
			Port: getEnv("SERVER_PORT", "8080"),
		},
		JWT: JWTConfig{
			Secret:     getEnv("JWT_SECRET=<JWT_SECRET>", "asutp-secret-key"),
			AccessTTL:  accessTTL,
			RefreshTTL: refreshTTL,
		},
		ResendAPIKey: getEnv("RESEND_API_KEY=your_resend_api_key_here", ""),
		EmailFrom:    getEnv("EMAIL_FROM", "noreply@missednoteserv.chickenkiller.com"),
		SMTP: SMTPConfig{
			Host: getEnv("SMTP_HOST", ""),
			Port: getEnv("SMTP_PORT", "587"),
			User: getEnv("SMTP_USER", ""),
			Pass: getEnv("SMTP_PASS=<SMTP_PASS>", ""),
		},
	}, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
