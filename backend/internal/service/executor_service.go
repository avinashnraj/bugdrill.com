package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

type ExecutorService struct {
	baseURL string
	client  *http.Client
}

type ExecuteRequest struct {
	Code       string   `json:"code"`
	Language   string   `json:"language"`
	TestCases  []string `json:"test_cases,omitempty"`
	TimeoutSec int      `json:"timeout_sec,omitempty"`
}

type ExecuteResponse struct {
	Success       bool         `json:"success"`
	Stdout        string       `json:"stdout"`
	Stderr        string       `json:"stderr"`
	ExitCode      int          `json:"exit_code"`
	ExecutionTime int          `json:"execution_time_ms"`
	Error         string       `json:"error,omitempty"`
	TestResults   []TestResult `json:"test_results,omitempty"`
}

type TestResult struct {
	Input    string `json:"input"`
	Expected string `json:"expected"`
	Actual   string `json:"actual"`
	Passed   bool   `json:"passed"`
}

func NewExecutorService() *ExecutorService {
	baseURL := os.Getenv("EXECUTOR_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8082" // Fallback for local development
	}

	return &ExecutorService{
		baseURL: baseURL,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (s *ExecutorService) Execute(req ExecuteRequest) (*ExecuteResponse, error) {
	// Default timeout
	if req.TimeoutSec == 0 {
		req.TimeoutSec = 10
	}

	jsonData, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := s.client.Post(
		s.baseURL+"/execute",
		"application/json",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to call executor: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var execResp ExecuteResponse
	if err := json.Unmarshal(body, &execResp); err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}

	return &execResp, nil
}

func (s *ExecutorService) HealthCheck() error {
	resp, err := s.client.Get(s.baseURL + "/health")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("executor service unhealthy: %d", resp.StatusCode)
	}

	return nil
}
