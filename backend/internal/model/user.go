package model

import (
	"time"
)

type User struct {
	ID                     string     `json:"id" db:"id"`
	Email                  string     `json:"email" db:"email"`
	PasswordHash           string     `json:"-" db:"password_hash"`
	DisplayName            string     `json:"display_name" db:"display_name"`
	OAuthProvider          *string    `json:"oauth_provider,omitempty" db:"oauth_provider"`
	OAuthID                *string    `json:"-" db:"oauth_id"`
	Role                   string     `json:"role" db:"role"`
	IsTrial                bool       `json:"is_trial" db:"is_trial"`
	TrialSnippetsRemaining int        `json:"trial_snippets_remaining" db:"trial_snippets_remaining"`
	CreatedAt              time.Time  `json:"created_at" db:"created_at"`
	LastLoginAt            *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
}

type SignupRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=8"`
	DisplayName string `json:"display_name" binding:"required"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         *User  `json:"user"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}
