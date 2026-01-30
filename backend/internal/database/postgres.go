package database

import (
	"database/sql"
	"fmt"

	"github.com/bugdrill/backend/internal/config"
	_ "github.com/lib/pq"
)

type DB struct {
	*sql.DB
}

func NewPostgresDB(cfg config.DatabaseConfig) (*DB, error) {
	db, err := sql.Open("postgres", cfg.DSN())
	if err != nil {
		return nil, fmt.Errorf("error opening database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * 60) // 5 minutes

	// Verify connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("error pinging database: %w", err)
	}

	return &DB{db}, nil
}
