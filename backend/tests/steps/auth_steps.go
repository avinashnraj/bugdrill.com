package steps

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/cucumber/godog"
)

type APIContext struct {
	BaseURL        string
	Response       *http.Response
	ResponseBody   map[string]interface{}
	RawResponse    []byte
	AccessToken    string
	RefreshToken   string
	OldAccessToken string
	HTTPClient     *http.Client
}

func NewAPIContext() *APIContext {
	baseURL := os.Getenv("API_BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	return &APIContext{
		BaseURL: baseURL,
		HTTPClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Background steps
func (ctx *APIContext) theAPIIsHealthyAndRunning() error {
	resp, err := ctx.HTTPClient.Get(ctx.BaseURL + "/health")
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("API is not healthy, status: %d", resp.StatusCode)
	}

	// Wait a bit to ensure API is fully ready
	time.Sleep(1 * time.Second)
	return nil
}

// Signup steps
func (ctx *APIContext) iSignupWithEmailAndPassword(email, password string) error {
	payload := map[string]string{
		"email":        email,
		"password":     password,
		"display_name": "Test User",
	}

	return ctx.makeJSONRequest("POST", "/api/v1/auth/signup", payload, nil)
}

func (ctx *APIContext) theSignupShouldBeSuccessful() error {
	if ctx.Response.StatusCode != http.StatusCreated {
		return fmt.Errorf("expected status 201, got %d: %v", ctx.Response.StatusCode, ctx.ResponseBody)
	}
	return nil
}

func (ctx *APIContext) iShouldReceiveAnAccessToken() error {
	token, ok := ctx.ResponseBody["access_token"].(string)
	if !ok || token == "" {
		return fmt.Errorf("access_token not found in response")
	}
	ctx.AccessToken = token
	return nil
}

func (ctx *APIContext) iShouldReceiveARefreshToken() error {
	token, ok := ctx.ResponseBody["refresh_token"].(string)
	if !ok || token == "" {
		return fmt.Errorf("refresh_token not found in response")
	}
	ctx.RefreshToken = token
	return nil
}

// Login steps
func (ctx *APIContext) iLoginWithEmailAndPassword(email, password string) error {
	payload := map[string]string{
		"email":    email,
		"password": password,
	}

	return ctx.makeJSONRequest("POST", "/api/v1/auth/login", payload, nil)
}

func (ctx *APIContext) theLoginShouldBeSuccessful() error {
	if ctx.Response.StatusCode != http.StatusOK {
		return fmt.Errorf("expected status 200, got %d: %v", ctx.Response.StatusCode, ctx.ResponseBody)
	}
	return nil
}

// Profile steps
func (ctx *APIContext) iRequestMyProfileWithTheAccessToken() error {
	headers := map[string]string{
		"Authorization": "Bearer " + ctx.AccessToken,
	}
	return ctx.makeJSONRequest("GET", "/api/v1/auth/me", nil, headers)
}

func (ctx *APIContext) iShouldSeeMyProfileInformation() error {
	if ctx.Response.StatusCode != http.StatusOK {
		return fmt.Errorf("expected status 200, got %d", ctx.Response.StatusCode)
	}

	if _, ok := ctx.ResponseBody["id"]; !ok {
		return fmt.Errorf("profile missing 'id' field")
	}

	return nil
}

func (ctx *APIContext) myEmailShouldBe(expectedEmail string) error {
	email, ok := ctx.ResponseBody["email"].(string)
	if !ok {
		return fmt.Errorf("email not found in response")
	}

	if email != expectedEmail {
		return fmt.Errorf("expected email %s, got %s", expectedEmail, email)
	}

	return nil
}

// Pattern listing steps
func (ctx *APIContext) iHaveAValidUserAccountWithPassword(email, password string) error {
	// Create account
	if err := ctx.iSignupWithEmailAndPassword(email, password); err != nil {
		return err
	}

	// Login to get fresh token
	if err := ctx.iLoginWithEmailAndPassword(email, password); err != nil {
		return err
	}

	return ctx.iShouldReceiveAnAccessToken()
}

func (ctx *APIContext) iListAllCodingPatterns() error {
	headers := map[string]string{
		"Authorization": "Bearer " + ctx.AccessToken,
	}
	return ctx.makeJSONRequest("GET", "/api/v1/patterns", nil, headers)
}

func (ctx *APIContext) iShouldSeeAtLeastPatterns(count int) error {
	// First try to get patterns from ResponseBody map
	patterns, ok := ctx.ResponseBody["patterns"].([]interface{})
	if !ok {
		// Response might be array directly - use raw response
		var directPatterns []interface{}
		if err := json.Unmarshal(ctx.RawResponse, &directPatterns); err != nil {
			return fmt.Errorf("failed to unmarshal patterns: %w (body: %s)", err, string(ctx.RawResponse))
		}
		patterns = directPatterns
	}

	if len(patterns) < count {
		return fmt.Errorf("expected at least %d patterns, got %d", count, len(patterns))
	}

	return nil
}

func (ctx *APIContext) thePatternsShouldInclude(patternName string) error {
	if !strings.Contains(string(ctx.RawResponse), patternName) {
		return fmt.Errorf("pattern '%s' not found in response", patternName)
	}
	return nil
}

// Unauthorized access steps
func (ctx *APIContext) iTryToListPatternsWithoutAuthentication() error {
	return ctx.makeJSONRequest("GET", "/api/v1/patterns", nil, nil)
}

func (ctx *APIContext) iShouldReceiveAUnauthorizedError() error {
	if ctx.Response.StatusCode != http.StatusUnauthorized {
		return fmt.Errorf("expected status 401, got %d", ctx.Response.StatusCode)
	}
	return nil
}

// Token refresh steps
func (ctx *APIContext) iHaveLoggedInAsWithPassword(email, password string) error {
	if err := ctx.iSignupWithEmailAndPassword(email, password); err != nil {
		// Might already exist, try login
		if err := ctx.iLoginWithEmailAndPassword(email, password); err != nil {
			return err
		}
	}

	if err := ctx.iShouldReceiveAnAccessToken(); err != nil {
		return err
	}

	ctx.OldAccessToken = ctx.AccessToken
	return ctx.iShouldReceiveARefreshToken()
}

func (ctx *APIContext) iUseMyRefreshTokenToGetANewAccessToken() error {
	// Sleep for 1 second to ensure different timestamp (JWT has 1-second precision)
	time.Sleep(1 * time.Second)

	payload := map[string]string{
		"refresh_token": ctx.RefreshToken,
	}

	return ctx.makeJSONRequest("POST", "/api/v1/auth/refresh", payload, nil)
}

func (ctx *APIContext) iShouldReceiveANewAccessToken() error {
	return ctx.iShouldReceiveAnAccessToken()
}

func (ctx *APIContext) theNewTokenShouldBeDifferentFromTheOldToken() error {
	if ctx.AccessToken == ctx.OldAccessToken {
		return fmt.Errorf("new token is same as old token")
	}
	return nil
}

// Helper methods
func (ctx *APIContext) makeJSONRequest(method, path string, payload interface{}, headers map[string]string) error {
	url := ctx.BaseURL + path

	var body io.Reader
	var requestJSON []byte
	if payload != nil {
		var err error
		requestJSON, err = json.MarshalIndent(payload, "", "  ")
		if err != nil {
			return err
		}
		body = bytes.NewBuffer(requestJSON)
	}

	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return err
	}

	req.Header.Set("Content-Type", "application/json")
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	// Log request
	fmt.Printf("\n┌─────────────────────────────────────────────────────────────\n")
	fmt.Printf("│ REQUEST: %s %s\n", method, path)
	fmt.Printf("├─────────────────────────────────────────────────────────────\n")
	if len(headers) > 0 {
		fmt.Printf("│ Headers:\n")
		for key, value := range headers {
			if key == "Authorization" && len(value) > 20 {
				fmt.Printf("│   %s: %s...%s\n", key, value[:20], value[len(value)-10:])
			} else {
				fmt.Printf("│   %s: %s\n", key, value)
			}
		}
	}
	if requestJSON != nil {
		fmt.Printf("│ Body:\n")
		for _, line := range strings.Split(string(requestJSON), "\n") {
			fmt.Printf("│   %s\n", line)
		}
	}
	fmt.Printf("└─────────────────────────────────────────────────────────────\n")

	resp, err := ctx.HTTPClient.Do(req)
	if err != nil {
		return err
	}

	ctx.Response = resp

	// Parse response body
	if resp.Body != nil {
		bodyBytes, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		// Store raw response
		ctx.RawResponse = bodyBytes

		// Reset body for potential re-reads
		resp.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		if len(bodyBytes) > 0 {
			// Try to unmarshal as object first
			json.Unmarshal(bodyBytes, &ctx.ResponseBody)
		}

		// Log response
		fmt.Printf("\n┌─────────────────────────────────────────────────────────────\n")
		fmt.Printf("│ RESPONSE: %d %s\n", resp.StatusCode, http.StatusText(resp.StatusCode))
		fmt.Printf("├─────────────────────────────────────────────────────────────\n")
		if len(bodyBytes) > 0 {
			// Pretty print JSON
			var prettyJSON bytes.Buffer
			if err := json.Indent(&prettyJSON, bodyBytes, "│   ", "  "); err == nil {
				fmt.Printf("│ Body:\n")
				fmt.Printf("│   %s\n", prettyJSON.String())
			} else {
				// Not valid JSON, print as-is
				fmt.Printf("│ Body: %s\n", string(bodyBytes))
			}
		}
		fmt.Printf("└─────────────────────────────────────────────────────────────\n\n")
	}

	return nil
}

func InitializeScenario(ctx *godog.ScenarioContext) {
	apiCtx := NewAPIContext()

	ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
		apiCtx = NewAPIContext()
		return ctx, nil
	})

	// Background
	ctx.Step(`^the API is healthy and running$`, apiCtx.theAPIIsHealthyAndRunning)

	// Signup
	ctx.Step(`^I signup with email "([^"]*)" and password "([^"]*)"$`, apiCtx.iSignupWithEmailAndPassword)
	ctx.Step(`^the signup should be successful$`, apiCtx.theSignupShouldBeSuccessful)

	// Tokens
	ctx.Step(`^I should receive an access token$`, apiCtx.iShouldReceiveAnAccessToken)
	ctx.Step(`^I should receive a refresh token$`, apiCtx.iShouldReceiveARefreshToken)

	// Login
	ctx.Step(`^I login with email "([^"]*)" and password "([^"]*)"$`, apiCtx.iLoginWithEmailAndPassword)
	ctx.Step(`^the login should be successful$`, apiCtx.theLoginShouldBeSuccessful)

	// Profile
	ctx.Step(`^I request my profile with the access token$`, apiCtx.iRequestMyProfileWithTheAccessToken)
	ctx.Step(`^I should see my profile information$`, apiCtx.iShouldSeeMyProfileInformation)
	ctx.Step(`^my email should be "([^"]*)"$`, apiCtx.myEmailShouldBe)

	// Patterns
	ctx.Step(`^I have a valid user account "([^"]*)" with password "([^"]*)"$`, apiCtx.iHaveAValidUserAccountWithPassword)
	ctx.Step(`^I list all coding patterns$`, apiCtx.iListAllCodingPatterns)
	ctx.Step(`^I should see at least (\d+) patterns$`, apiCtx.iShouldSeeAtLeastPatterns)
	ctx.Step(`^the patterns should include "([^"]*)"$`, apiCtx.thePatternsShouldInclude)

	// Unauthorized
	ctx.Step(`^I try to list patterns without authentication$`, apiCtx.iTryToListPatternsWithoutAuthentication)
	ctx.Step(`^I should receive a (\d+) unauthorized error$`, apiCtx.iShouldReceiveAUnauthorizedError)

	// Token refresh
	ctx.Step(`^I have logged in as "([^"]*)" with password "([^"]*)"$`, apiCtx.iHaveLoggedInAsWithPassword)
	ctx.Step(`^I use my refresh token to get a new access token$`, apiCtx.iUseMyRefreshTokenToGetANewAccessToken)
	ctx.Step(`^I should receive a new access token$`, apiCtx.iShouldReceiveANewAccessToken)
	ctx.Step(`^the new token should be different from the old token$`, apiCtx.theNewTokenShouldBeDifferentFromTheOldToken)
}
