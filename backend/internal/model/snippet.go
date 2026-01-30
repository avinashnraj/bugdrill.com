package model

import (
	"database/sql/driver"
	"encoding/json"
	"time"
)

type PatternCategory struct {
	ID          int     `json:"id" db:"id"`
	Name        string  `json:"name" db:"name"`
	Slug        string  `json:"slug" db:"slug"`
	Description string  `json:"description" db:"description"`
	IconURL     *string `json:"icon_url,omitempty" db:"icon_url"`
	OrderIndex  int     `json:"order_index" db:"order_index"`
}

type Snippet struct {
	ID             string    `json:"id" db:"id"`
	PatternID      int       `json:"pattern_id" db:"pattern_id"`
	Title          string    `json:"title" db:"title"`
	Description    string    `json:"description" db:"description"`
	Difficulty     string    `json:"difficulty" db:"difficulty"`
	Language       string    `json:"language" db:"language"`
	CorrectCode    string    `json:"correct_code" db:"correct_code"`
	BuggyCode      string    `json:"buggy_code" db:"buggy_code"`
	BugType        string    `json:"bug_type" db:"bug_type"`
	BugExplanation string    `json:"bug_explanation" db:"bug_explanation"`
	TestCases      TestCases `json:"test_cases" db:"test_cases"`
	Hint1          string    `json:"hint_1" db:"hint_1"`
	Hint2          string    `json:"hint_2" db:"hint_2"`
	Hint3          string    `json:"hint_3" db:"hint_3"`
	CreatedBy      string    `json:"created_by" db:"created_by"`
	Status         string    `json:"status" db:"status"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time `json:"updated_at" db:"updated_at"`
}

type TestCase struct {
	Input    map[string]interface{} `json:"input"`
	Expected interface{}            `json:"expected"`
}

type TestCases []TestCase

// Scan implements sql.Scanner for JSONB
func (tc *TestCases) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return nil
	}
	return json.Unmarshal(bytes, tc)
}

// Value implements driver.Valuer for JSONB
func (tc TestCases) Value() (driver.Value, error) {
	return json.Marshal(tc)
}

type ExecuteCodeRequest struct {
	Code     string `json:"code" binding:"required"`
	Language string `json:"language" binding:"required"`
}

type ExecuteCodeResponse struct {
	ExecutionID string       `json:"execution_id"`
	Status      string       `json:"status"`
	IsCorrect   bool         `json:"is_correct"`
	TestResults []TestResult `json:"test_results"`
	TotalTimeMS int          `json:"total_time_ms"`
	Stdout      string       `json:"stdout"`
	Stderr      string       `json:"stderr"`
}

type TestResult struct {
	TestCase        int         `json:"test_case"`
	Input           interface{} `json:"input"`
	Expected        interface{} `json:"expected"`
	Actual          interface{} `json:"actual"`
	Passed          bool        `json:"passed"`
	ExecutionTimeMS int         `json:"execution_time_ms"`
}
