package service

import (
	"context"
	"fmt"
	"time"

	"github.com/bugdrill/backend/internal/config"
	"github.com/bugdrill/backend/internal/middleware"
	"github.com/bugdrill/backend/internal/model"
	"github.com/bugdrill/backend/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	cfg      *config.Config
	userRepo *repository.UserRepository
	redis    *redis.Client
}

func NewAuthService(cfg *config.Config, userRepo *repository.UserRepository, redis *redis.Client) *AuthService {
	return &AuthService{
		cfg:      cfg,
		userRepo: userRepo,
		redis:    redis,
	}
}

func (s *AuthService) Signup(req *model.SignupRequest) (*model.AuthResponse, error) {
	// Check if user already exists
	_, err := s.userRepo.GetByEmail(req.Email)
	if err == nil {
		return nil, fmt.Errorf("user with this email already exists")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &model.User{
		ID:                     uuid.New().String(),
		Email:                  req.Email,
		PasswordHash:           string(hashedPassword),
		DisplayName:            req.DisplayName,
		Role:                   "user",
		IsTrial:                false,
		TrialSnippetsRemaining: s.cfg.App.TrialSnippets,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate tokens
	accessToken, refreshToken, err := s.generateTokens(user)
	if err != nil {
		return nil, err
	}

	// Store refresh token in Redis
	if err := s.storeRefreshToken(user.ID, refreshToken); err != nil {
		return nil, err
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) Login(req *model.LoginRequest) (*model.AuthResponse, error) {
	// Get user by email
	user, err := s.userRepo.GetByEmail(req.Email)
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// Update last login
	_ = s.userRepo.UpdateLastLogin(user.ID)

	// Generate tokens
	accessToken, refreshToken, err := s.generateTokens(user)
	if err != nil {
		return nil, err
	}

	// Store refresh token
	if err := s.storeRefreshToken(user.ID, refreshToken); err != nil {
		return nil, err
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) RefreshToken(tokenString string) (*model.AuthResponse, error) {
	// Validate refresh token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return []byte(s.cfg.JWT.RefreshSecret), nil
	})

	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid refresh token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid token claims")
	}

	userID := claims["user_id"].(string)

	// Check if token exists in Redis
	ctx := context.Background()
	exists, err := s.redis.Exists(ctx, fmt.Sprintf("refresh_token:%s", userID)).Result()
	if err != nil || exists == 0 {
		return nil, fmt.Errorf("refresh token not found or expired")
	}

	// Get user
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, err
	}

	// Generate new tokens
	accessToken, newRefreshToken, err := s.generateTokens(user)
	if err != nil {
		return nil, err
	}

	// Store new refresh token
	if err := s.storeRefreshToken(user.ID, newRefreshToken); err != nil {
		return nil, err
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) Logout(userID string) error {
	ctx := context.Background()
	return s.redis.Del(ctx, fmt.Sprintf("refresh_token:%s", userID)).Err()
}

func (s *AuthService) GetUserByID(userID string) (*model.User, error) {
	return s.userRepo.GetByID(userID)
}

func (s *AuthService) generateTokens(user *model.User) (string, string, error) {
	// Generate access token
	accessClaims := &middleware.Claims{
		UserID:  user.ID,
		Email:   user.Email,
		Role:    user.Role,
		IsTrial: user.IsTrial,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.cfg.JWT.AccessExpiration)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessTokenString, err := accessToken.SignedString([]byte(s.cfg.JWT.AccessSecret))
	if err != nil {
		return "", "", err
	}

	// Generate refresh token
	refreshClaims := jwt.MapClaims{
		"user_id": user.ID,
		"exp":     time.Now().Add(s.cfg.JWT.RefreshExpiration).Unix(),
	}

	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshTokenString, err := refreshToken.SignedString([]byte(s.cfg.JWT.RefreshSecret))
	if err != nil {
		return "", "", err
	}

	return accessTokenString, refreshTokenString, nil
}

func (s *AuthService) storeRefreshToken(userID, token string) error {
	ctx := context.Background()
	key := fmt.Sprintf("refresh_token:%s", userID)
	return s.redis.Set(ctx, key, token, s.cfg.JWT.RefreshExpiration).Err()
}
