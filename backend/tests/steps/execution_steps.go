package steps

import (
	"encoding/json"
	"fmt"
	"strings"
)

// Execution context
type ExecutionContext struct {
	CurrentSnippet   map[string]interface{}
	ExecutionResult  map[string]interface{}
	LastExecutionID  string
}

// Seed sample snippets
func (ctx *APIContext) iHaveSeededTheSampleSnippets() error {
	// Snippets are seeded via migrations, just verify they exist
	headers := map[string]string{
		"Authorization": "Bearer " + ctx.AccessToken,
	}
	
	if err := ctx.makeJSONRequest("GET", "/api/v1/patterns/1/snippets", nil, headers); err != nil {
		return err
	}

	if ctx.Response.StatusCode != 200 {
		return fmt.Errorf("failed to fetch snippets: status %d", ctx.Response.StatusCode)
	}

	return nil
}

// Get first snippet for a pattern
func (ctx *APIContext) iGetTheFirstSnippetForPattern(patternID int) error {
	headers := map[string]string{
		"Authorization": "Bearer " + ctx.AccessToken,
	}

	endpoint := fmt.Sprintf("/api/v1/patterns/%d/snippets", patternID)
	if err := ctx.makeJSONRequest("GET", endpoint, nil, headers); err != nil {
		return err
	}

	if ctx.Response.StatusCode != 200 {
		return fmt.Errorf("failed to get snippets: status %d", ctx.Response.StatusCode)
	}

	// Parse response
	var snippets []interface{}
	if err := json.Unmarshal(ctx.RawResponse, &snippets); err != nil {
		return fmt.Errorf("failed to parse snippets: %w", err)
	}

	if len(snippets) == 0 {
		return fmt.Errorf("no snippets found for pattern %d", patternID)
	}

	// Get the first snippet details
	firstSnippet := snippets[0].(map[string]interface{})
	snippetID := firstSnippet["id"].(string)

	// Fetch full snippet details
	endpoint = fmt.Sprintf("/api/v1/snippets/%s", snippetID)
	if err := ctx.makeJSONRequest("GET", endpoint, nil, headers); err != nil {
		return err
	}

	if ctx.Response.StatusCode != 200 {
		return fmt.Errorf("failed to get snippet details: status %d", ctx.Response.StatusCode)
	}

	// Store current snippet
	if ctx.CurrentSnippet == nil {
		ctx.CurrentSnippet = make(map[string]interface{})
	}
	
	var snippet map[string]interface{}
	if err := json.Unmarshal(ctx.RawResponse, &snippet); err != nil {
		return fmt.Errorf("failed to parse snippet: %w", err)
	}
	
	ctx.CurrentSnippet = snippet

	return nil
}

// Execute buggy code
func (ctx *APIContext) iExecuteTheBuggyCodeForThatSnippet() error {
	if ctx.CurrentSnippet == nil {
		return fmt.Errorf("no current snippet")
	}

	snippetID := ctx.CurrentSnippet["id"].(string)
	buggyCode := ctx.CurrentSnippet["buggy_code"].(string)

	return ctx.executeCode(snippetID, buggyCode, "python")
}

// Execute correct code
func (ctx *APIContext) iExecuteTheCorrectCodeForThatSnippet() error {
	if ctx.CurrentSnippet == nil {
		return fmt.Errorf("no current snippet")
	}

	snippetID := ctx.CurrentSnippet["id"].(string)
	
	// The API intentionally doesn't return correct_code to prevent cheating
	// For testing purposes, we'll use the known correct solution for "Two Sum Sorted"
	correctCode := `def twoSum(nums: list[int], target: int) -> list[int]:
    left, right = 0, len(nums) - 1
    while left < right:
        current_sum = nums[left] + nums[right]
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1
        else:
            right -= 1
    return [-1, -1]`

	return ctx.executeCode(snippetID, correctCode, "python")
}

// Execute invalid code
func (ctx *APIContext) iExecuteInvalidPythonCode() error {
	if ctx.CurrentSnippet == nil {
		return fmt.Errorf("no current snippet")
	}

	snippetID := ctx.CurrentSnippet["id"].(string)
	invalidCode := "this is not valid python syntax!!!"

	return ctx.executeCode(snippetID, invalidCode, "python")
}

// Helper to execute code
func (ctx *APIContext) executeCode(snippetID, code, language string) error {
	headers := map[string]string{
		"Authorization": "Bearer " + ctx.AccessToken,
	}

	payload := map[string]interface{}{
		"code":     code,
		"language": language,
	}

	endpoint := fmt.Sprintf("/api/v1/snippets/%s/execute", snippetID)
	if err := ctx.makeJSONRequest("POST", endpoint, payload, headers); err != nil {
		return err
	}

	// Store execution result
	if err := json.Unmarshal(ctx.RawResponse, &ctx.ExecutionResult); err != nil {
		return fmt.Errorf("failed to parse execution result: %w", err)
	}

	return nil
}

// Verify execution completed
func (ctx *APIContext) theExecutionShouldComplete() error {
	if ctx.Response.StatusCode != 200 {
		return fmt.Errorf("expected status 200, got %d: %s", ctx.Response.StatusCode, string(ctx.RawResponse))
	}

	if ctx.ExecutionResult == nil {
		return fmt.Errorf("no execution result")
	}

	status, ok := ctx.ExecutionResult["status"].(string)
	if !ok || status != "completed" {
		return fmt.Errorf("execution status is not 'completed': %v", ctx.ExecutionResult["status"])
	}

	return nil
}

// Verify execution is correct
func (ctx *APIContext) theExecutionShouldBeCorrect() error {
	isCorrect, ok := ctx.ExecutionResult["is_correct"].(bool)
	if !ok {
		return fmt.Errorf("is_correct field not found or wrong type")
	}

	if !isCorrect {
		return fmt.Errorf("execution was not correct")
	}

	return nil
}

// Verify execution is not correct
func (ctx *APIContext) theExecutionShouldNotBeCorrect() error {
	isCorrect, ok := ctx.ExecutionResult["is_correct"].(bool)
	if !ok {
		return fmt.Errorf("is_correct field not found or wrong type")
	}

	if isCorrect {
		return fmt.Errorf("execution should not be correct but it was")
	}

	return nil
}

// Verify execution output
func (ctx *APIContext) iShouldSeeExecutionOutput() error {
	_, hasStdout := ctx.ExecutionResult["stdout"]
	_, hasStderr := ctx.ExecutionResult["stderr"]

	if !hasStdout && !hasStderr {
		return fmt.Errorf("no stdout or stderr in execution result")
	}

	return nil
}

// Verify stderr has error
func (ctx *APIContext) iShouldSeeAnErrorInStderr() error {
	stderr, ok := ctx.ExecutionResult["stderr"].(string)
	if !ok {
		return fmt.Errorf("stderr field not found or wrong type")
	}

	if strings.TrimSpace(stderr) == "" {
		return fmt.Errorf("stderr is empty, expected error message")
	}

	return nil
}

// Verify test passed
func (ctx *APIContext) theTestShouldHavePassed() error {
	// Check if execution was successful
	isCorrect, ok := ctx.ExecutionResult["is_correct"].(bool)
	if !ok || !isCorrect {
		return fmt.Errorf("test did not pass")
	}

	return nil
}
