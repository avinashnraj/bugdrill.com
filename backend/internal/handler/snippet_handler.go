package handler

import (
	"net/http"
	"strconv"

	"github.com/bugdrill/backend/internal/model"
	"github.com/bugdrill/backend/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SnippetHandler struct {
	snippetService *service.SnippetService
}

func NewSnippetHandler(snippetService *service.SnippetService) *SnippetHandler {
	return &SnippetHandler{snippetService: snippetService}
}

func (h *SnippetHandler) ListPatterns(c *gin.Context) {
	patterns, err := h.snippetService.GetPatterns()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch patterns"})
		return
	}

	c.JSON(http.StatusOK, patterns)
}

func (h *SnippetHandler) ListSnippetsByPattern(c *gin.Context) {
	patternID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pattern ID"})
		return
	}

	difficulty := c.Query("difficulty")

	snippets, err := h.snippetService.GetSnippetsByPattern(patternID, difficulty)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch snippets"})
		return
	}

	c.JSON(http.StatusOK, snippets)
}

func (h *SnippetHandler) GetSnippet(c *gin.Context) {
	snippetID := c.Param("id")

	snippet, err := h.snippetService.GetSnippet(snippetID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Snippet not found"})
		return
	}

	// Don't send the correct code to the client
	snippet.CorrectCode = ""

	c.JSON(http.StatusOK, snippet)
}

func (h *SnippetHandler) ExecuteCode(c *gin.Context) {
	snippetID := c.Param("id")

	var req model.ExecuteCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.snippetService.ExecuteCode(snippetID, req.Code, req.Language)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Code execution failed"})
		return
	}

	c.JSON(http.StatusOK, result)
}

func (h *SnippetHandler) SubmitSolution(c *gin.Context) {
	snippetID := c.Param("id")
	userID := c.GetString("user_id")

	var req model.ExecuteCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.snippetService.ExecuteCode(snippetID, req.Code, req.Language)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Code execution failed"})
		return
	}

	// TODO: Store submission in database
	_ = userID // Will be used when storing attempts

	c.JSON(http.StatusOK, result)
}

func (h *SnippetHandler) GetHint(c *gin.Context) {
	snippetID := c.Param("id")
	tier := c.Param("tier")

	snippet, err := h.snippetService.GetSnippet(snippetID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Snippet not found"})
		return
	}

	var hint string
	switch tier {
	case "1":
		hint = snippet.Hint1
	case "2":
		hint = snippet.Hint2
	case "3":
		hint = snippet.Hint3
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid hint tier"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"hint": hint, "tier": tier})
}

func (h *SnippetHandler) GetUserProgress(c *gin.Context) {
	// TODO: Implement progress tracking
	c.JSON(http.StatusOK, gin.H{
		"total_snippets_attempted": 0,
		"total_snippets_solved":    0,
		"patterns":                 []interface{}{},
	})
}

func (h *SnippetHandler) CreateSnippet(c *gin.Context) {
	var snippet model.Snippet
	if err := c.ShouldBindJSON(&snippet); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	snippet.ID = uuid.New().String()
	userID := c.GetString("user_id")
	snippet.CreatedBy = &userID
	snippet.Status = "active"

	if err := h.snippetService.CreateSnippet(&snippet); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create snippet"})
		return
	}

	c.JSON(http.StatusCreated, snippet)
}

func (h *SnippetHandler) UpdateSnippet(c *gin.Context) {
	// TODO: Implement update logic
	c.JSON(http.StatusNotImplemented, gin.H{"error": "Not implemented yet"})
}
