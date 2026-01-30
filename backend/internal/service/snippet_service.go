package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/bugdrill/backend/internal/model"
	"github.com/bugdrill/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

type SnippetService struct {
	snippetRepo     *repository.SnippetRepository
	patternRepo     *repository.PatternRepository
	redis           *redis.Client
	executorService *ExecutorService
}

func NewSnippetService(
	snippetRepo *repository.SnippetRepository,
	patternRepo *repository.PatternRepository,
	redis *redis.Client,
	executorService *ExecutorService,
) *SnippetService {
	return &SnippetService{
		snippetRepo:     snippetRepo,
		patternRepo:     patternRepo,
		redis:           redis,
		executorService: executorService,
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
	log.Printf("🔵 ExecuteCode called: snippetID=%s, codeLength=%d, language=%s", snippetID, len(code), language)
	
	// Get snippet to access test cases
	snippet, err := s.GetSnippet(snippetID)
	if err != nil {
		log.Printf("❌ Failed to get snippet: %v", err)
		return nil, err
	}

	log.Printf("🔵 Snippet retrieved, calling executor service...")
	
	// Execute code using executor service
	execReq := ExecuteRequest{
		Code:       code,
		Language:   language,
		TimeoutSec: 10,
	}

	execResp, err := s.executorService.Execute(execReq)
	if err != nil {
		log.Printf("❌ Executor service failed: %v", err)
		return nil, fmt.Errorf("execution failed: %w", err)
	}
	
	log.Printf("✅ Executor returned: success=%v, exitCode=%d", execResp.Success, execResp.ExitCode)

	// snippet.TestCases is already parsed as []TestCase, convert to []map[string]interface{}
	testCases := []map[string]interface{}{}
	for _, tc := range snippet.TestCases {
		testCases = append(testCases, map[string]interface{}{
			"input":    tc.Input,
			"expected": tc.Expected,
		})
	}

	// Build test results (simplified - just shows the test cases)
	// TODO: Actually run each test case separately and validate output
	testResults := []model.TestResult{}
	for i, tc := range testCases {
		testResults = append(testResults, model.TestResult{
			TestCase:        i + 1,
			Input:           tc["input"],
			Expected:        tc["expected"],
			Actual:          tc["expected"], // Mock: Using expected as actual for now
			Passed:          execResp.Success && execResp.ExitCode == 0,
			ExecutionTimeMS: execResp.ExecutionTime,
		})
	}

	// Determine overall correctness
	// For now, it's correct if the code executed successfully (exit code 0)
	isCorrect := execResp.Success && execResp.ExitCode == 0

	response := &model.ExecuteCodeResponse{
		ExecutionID: fmt.Sprintf("exec_%d", time.Now().Unix()),
		Status:      "completed",
		IsCorrect:   isCorrect,
		TestResults: testResults,
		TotalTimeMS: execResp.ExecutionTime,
		Stdout:      execResp.Stdout,
		Stderr:      execResp.Stderr,
	}

	return response, nil
}

func (s *SnippetService) CreateSnippet(snippet *model.Snippet) error {
	return s.snippetRepo.Create(snippet)
}
