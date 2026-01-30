package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/bugdrill/backend/internal/model"
	"github.com/bugdrill/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

type SnippetService struct {
	snippetRepo *repository.SnippetRepository
	patternRepo *repository.PatternRepository
	redis       *redis.Client
}

func NewSnippetService(
	snippetRepo *repository.SnippetRepository,
	patternRepo *repository.PatternRepository,
	redis *redis.Client,
) *SnippetService {
	return &SnippetService{
		snippetRepo: snippetRepo,
		patternRepo: patternRepo,
		redis:       redis,
	}
}

func (s *SnippetService) GetPatterns() ([]model.PatternCategory, error) {
	ctx := context.Background()
	cacheKey := "patterns:all"

	// Try cache first
	cached, err := s.redis.Get(ctx, cacheKey).Result()
	if err == nil {
		var patterns []model.PatternCategory
		if err := json.Unmarshal([]byte(cached), &patterns); err == nil {
			return patterns, nil
		}
	}

	// Cache miss - fetch from DB
	patterns, err := s.patternRepo.GetAll()
	if err != nil {
		return nil, err
	}

	// Cache the result
	data, _ := json.Marshal(patterns)
	s.redis.Set(ctx, cacheKey, data, 24*time.Hour)

	return patterns, nil
}

func (s *SnippetService) GetSnippetsByPattern(patternID int, difficulty string) ([]model.Snippet, error) {
	return s.snippetRepo.GetByPatternID(patternID, difficulty)
}

func (s *SnippetService) GetSnippet(snippetID string) (*model.Snippet, error) {
	ctx := context.Background()
	cacheKey := fmt.Sprintf("snippet:%s", snippetID)

	// Try cache first
	cached, err := s.redis.Get(ctx, cacheKey).Result()
	if err == nil {
		var snippet model.Snippet
		if err := json.Unmarshal([]byte(cached), &snippet); err == nil {
			return &snippet, nil
		}
	}

	// Cache miss - fetch from DB
	snippet, err := s.snippetRepo.GetByID(snippetID)
	if err != nil {
		return nil, err
	}

	// Cache the result
	data, _ := json.Marshal(snippet)
	s.redis.Set(ctx, cacheKey, data, 1*time.Hour)

	return snippet, nil
}

func (s *SnippetService) ExecuteCode(snippetID, code, language string) (*model.ExecuteCodeResponse, error) {
	// Get snippet to access test cases
	snippet, err := s.GetSnippet(snippetID)
	if err != nil {
		return nil, err
	}

	// TODO: Implement actual code execution
	// For now, return a mock response
	response := &model.ExecuteCodeResponse{
		ExecutionID: fmt.Sprintf("exec_%d", time.Now().Unix()),
		Status:      "completed",
		IsCorrect:   false,
		TestResults: []model.TestResult{},
		TotalTimeMS: 42,
		Stdout:      "",
		Stderr:      "",
	}

	// Run against test cases (simplified mock)
	for i, tc := range snippet.TestCases {
		response.TestResults = append(response.TestResults, model.TestResult{
			TestCase:        i + 1,
			Input:           tc.Input,
			Expected:        tc.Expected,
			Actual:          tc.Expected, // Mock: assume correct for now
			Passed:          true,
			ExecutionTimeMS: 10,
		})
	}

	return response, nil
}

func (s *SnippetService) CreateSnippet(snippet *model.Snippet) error {
	return s.snippetRepo.Create(snippet)
}
