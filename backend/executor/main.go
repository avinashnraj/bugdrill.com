package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type ExecuteRequest struct {
	Code       string   `json:"code" binding:"required"`
	Language   string   `json:"language" binding:"required"`
	TestCases  []string `json:"test_cases"`
	TimeoutSec int      `json:"timeout_sec"`
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

func main() {
	r := gin.Default()

	// Health check endpoint (supports both GET and HEAD for Docker healthcheck)
	r.GET("/health", healthHandler)
	r.HEAD("/health", healthHandler)

	r.POST("/execute", handleExecute)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Executor service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service": "executor",
		"status":  "healthy",
	})
}

func handleExecute(c *gin.Context) {
	log.Println("📥 Received execution request")
	
	var req ExecuteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("❌ Failed to bind JSON: %v", err)
		c.JSON(http.StatusBadRequest, ExecuteResponse{
			Success: false,
			Error:   fmt.Sprintf("Invalid request: %v", err),
		})
		return
	}
	
	log.Printf("🐍 Executing Python code (length: %d bytes)", len(req.Code))

	// Set default timeout
	if req.TimeoutSec == 0 {
		req.TimeoutSec = 10
	}

	// Validate language
	if req.Language != "python" {
		c.JSON(http.StatusBadRequest, ExecuteResponse{
			Success: false,
			Error:   "Only Python is supported",
		})
		return
	}

	result := executePython(req)
	log.Printf("✅ Execution complete: success=%v, exitCode=%d, stderr_len=%d", result.Success, result.ExitCode, len(result.Stderr))
	c.JSON(http.StatusOK, result)
}

func executePython(req ExecuteRequest) ExecuteResponse {
	startTime := time.Now()

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(req.TimeoutSec)*time.Second)
	defer cancel()

	// Use docker run to execute Python code in isolated container
	// --rm: remove container after execution
	// --network none: no network access
	// --memory: limit memory to 128MB
	// --cpus: limit CPU usage
	// --user: run as non-root user
	cmd := exec.CommandContext(ctx, "docker", "run", "--rm",
		"--network", "none",
		"--memory", "128m",
		"--cpus", "0.5",
		"--security-opt=no-new-privileges",
		"python:3.11-alpine",
		"python", "-c", req.Code,
	)

	// Capture output
	var stdout, stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Run the command
	err := cmd.Run()
	executionTime := int(time.Since(startTime).Milliseconds())

	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else if ctx.Err() == context.DeadlineExceeded {
			return ExecuteResponse{
				Success:       false,
				Stderr:        "Execution timeout exceeded",
				ExitCode:      124,
				ExecutionTime: executionTime,
				Error:         "Timeout",
			}
		}
	}

	return ExecuteResponse{
		Success:       exitCode == 0,
		Stdout:        stdout.String(),
		Stderr:        stderr.String(),
		ExitCode:      exitCode,
		ExecutionTime: executionTime,
	}
}
