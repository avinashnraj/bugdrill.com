package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
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

	// Build test results by running each test case
	testResults := []model.TestResult{}
	allPassed := true

	if !execResp.Success || execResp.ExitCode != 0 {
		// Code failed to compile/run, all test cases fail
		for i, tc := range snippet.TestCases {
			testResults = append(testResults, model.TestResult{
				TestCase:        i + 1,
				Input:           tc.Input,
				Expected:        tc.Expected,
				Actual:          execResp.Stderr,
				Passed:          false,
				ExecutionTimeMS: execResp.ExecutionTime,
			})
		}
		allPassed = false
	} else {
		// Code ran successfully, extract function name and run each test case
		funcName := extractFunctionName(code, language)

		for i, tc := range snippet.TestCases {
			// Build test harness code that calls the function with test input
			testCode := buildPythonTestHarness(code, funcName, tc.Input)
			log.Printf("[TEST] Test case %d: funcName=%s", i+1, funcName)
			log.Printf("[CODE] Generated test code:\n%s", testCode)

			testExecReq := ExecuteRequest{
				Code:       testCode,
				Language:   language,
				TimeoutSec: 10,
			}

			testResp, err := s.executorService.Execute(testExecReq)

			var actualOutput interface{}
			var passed bool

			if err != nil || !testResp.Success {
				// Test case execution failed
				passed = false
				if testResp != nil {
					actualOutput = testResp.Stderr
					log.Printf("[FAIL] Test case %d failed: %s", i+1, testResp.Stderr)
				} else {
					actualOutput = fmt.Sprintf("Error: %v", err)
					log.Printf("[ERROR] Test case %d error: %v", i+1, err)
				}
			} else {
				// Parse and compare outputs
				actualOutput = strings.TrimSpace(testResp.Stdout)
				// Convert expected value to JSON for comparison
				expectedJSON, _ := json.Marshal(tc.Expected)
				expectedStr := string(expectedJSON)
				actualStr := fmt.Sprintf("%v", actualOutput)
				passed = compareOutputs(expectedStr, actualStr)
				log.Printf("[RESULT] Test case %d: expected='%s', actual='%s', passed=%v", i+1, expectedStr, actualStr, passed)
			}

			testResults = append(testResults, model.TestResult{
				TestCase:        i + 1,
				Input:           tc.Input,
				Expected:        tc.Expected,
				Actual:          actualOutput,
				Passed:          passed,
				ExecutionTimeMS: testResp.ExecutionTime,
			})

			if !passed {
				allPassed = false
			}
		}
	}

	isCorrect := allPassed

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

// Helper function to extract function name from Python code
func extractFunctionName(code, language string) string {
	if language != "python" {
		return ""
	}

	// Look for "def functionName(" pattern
	lines := strings.Split(code, "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "def ") {
			// Extract function name
			parts := strings.Split(trimmed, "(")
			if len(parts) > 0 {
				funcDef := strings.TrimSpace(parts[0])
				funcName := strings.TrimPrefix(funcDef, "def ")
				return strings.TrimSpace(funcName)
			}
		}
	}
	return ""
}

// Helper function to build Python test harness
func buildPythonTestHarness(userCode, funcName string, testInput interface{}) string {
	// Convert testInput map to Python function call
	inputMap, ok := testInput.(map[string]interface{})
	if !ok {
		return userCode + "\nprint('Error: invalid test input')"
	}

	// Build function call arguments in order
	// For now, hardcode common parameter order (nums, target)
	// TODO: Make this more generic by parsing function signature
	args := []string{}
	if nums, ok := inputMap["nums"]; ok {
		args = append(args, formatPythonValue(nums))
	}
	if target, ok := inputMap["target"]; ok {
		args = append(args, formatPythonValue(target))
	}
	// For string parameter
	if s, ok := inputMap["s"]; ok {
		args = append(args, formatPythonValue(s))
	}

	// Create test harness
	harness := fmt.Sprintf(`%s

# Test harness
import json
result = %s(%s)
print(json.dumps(result))
`, userCode, funcName, strings.Join(args, ", "))

	return harness
}

// Helper to format Go values as Python literals
func formatPythonValue(value interface{}) string {
	switch v := value.(type) {
	case []interface{}:
		items := make([]string, len(v))
		for i, item := range v {
			items[i] = formatPythonValue(item)
		}
		return "[" + strings.Join(items, ", ") + "]"
	case string:
		return fmt.Sprintf("'%s'", v)
	case float64:
		// Check if it's an integer
		if v == float64(int(v)) {
			return fmt.Sprintf("%d", int(v))
		}
		return fmt.Sprintf("%f", v)
	default:
		return fmt.Sprintf("%v", v)
	}
}

// Helper to compare expected and actual outputs
func compareOutputs(expected, actual string) bool {
	// Normalize whitespace
	expected = strings.TrimSpace(expected)
	actual = strings.TrimSpace(actual)

	// Try exact match first
	if expected == actual {
		return true
	}

	// Try JSON comparison (for lists, dicts, etc.)
	// Both expected and actual should be JSON strings
	var expectedJSON, actualJSON interface{}
	err1 := json.Unmarshal([]byte(actual), &actualJSON)
	err2 := json.Unmarshal([]byte(expected), &expectedJSON)

	if err1 == nil && err2 == nil {
		// Compare the unmarshaled objects
		expectedBytes, _ := json.Marshal(expectedJSON)
		actualBytes, _ := json.Marshal(actualJSON)
		return string(expectedBytes) == string(actualBytes)
	}

	return false
}
