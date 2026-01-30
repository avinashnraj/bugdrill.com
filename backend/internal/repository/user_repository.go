package repository

import (
	"database/sql"
	"fmt"

	"github.com/bugdrill/backend/internal/database"
	"github.com/bugdrill/backend/internal/model"
)

type UserRepository struct {
	db *database.DB
}

func NewUserRepository(db *database.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *model.User) error {
	query := `
		INSERT INTO users (id, email, password_hash, display_name, role, is_trial, trial_snippets_remaining)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING created_at
	`
	return r.db.QueryRow(
		query,
		user.ID,
		user.Email,
		user.PasswordHash,
		user.DisplayName,
		user.Role,
		user.IsTrial,
		user.TrialSnippetsRemaining,
	).Scan(&user.CreatedAt)
}

func (r *UserRepository) GetByEmail(email string) (*model.User, error) {
	user := &model.User{}
	query := `
		SELECT id, email, password_hash, display_name, oauth_provider, oauth_id, 
		       role, is_trial, trial_snippets_remaining, created_at, last_login_at
		FROM users
		WHERE email = $1
	`
	err := r.db.QueryRow(query, email).Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.OAuthProvider,
		&user.OAuthID,
		&user.Role,
		&user.IsTrial,
		&user.TrialSnippetsRemaining,
		&user.CreatedAt,
		&user.LastLoginAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return user, err
}

func (r *UserRepository) GetByID(id string) (*model.User, error) {
	user := &model.User{}
	query := `
		SELECT id, email, password_hash, display_name, oauth_provider, oauth_id,
		       role, is_trial, trial_snippets_remaining, created_at, last_login_at
		FROM users
		WHERE id = $1
	`
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Email,
		&user.PasswordHash,
		&user.DisplayName,
		&user.OAuthProvider,
		&user.OAuthID,
		&user.Role,
		&user.IsTrial,
		&user.TrialSnippetsRemaining,
		&user.CreatedAt,
		&user.LastLoginAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return user, err
}

func (r *UserRepository) UpdateLastLogin(userID string) error {
	query := `UPDATE users SET last_login_at = NOW() WHERE id = $1`
	_, err := r.db.Exec(query, userID)
	return err
}
