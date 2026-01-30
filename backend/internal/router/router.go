package router

import (
	"net/http"

	"github.com/bugdrill/backend/internal/config"
	"github.com/bugdrill/backend/internal/database"
	"github.com/bugdrill/backend/internal/handler"
	"github.com/bugdrill/backend/internal/middleware"
	"github.com/bugdrill/backend/internal/repository"
	"github.com/bugdrill/backend/internal/service"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func SetupRouter(cfg *config.Config, db *database.DB, redis *redis.Client) *gin.Engine {
	if cfg.Server.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())
	r.Use(middleware.RequestID())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"app":    cfg.App.Name,
		})
	})

	r.GET("/ready", func(c *gin.Context) {
		// Check database connection
		if err := db.Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "not ready",
				"error":  "database unavailable",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ready"})
	})

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	patternRepo := repository.NewPatternRepository(db)
	snippetRepo := repository.NewSnippetRepository(db)

	// Initialize services
	executorService := service.NewExecutorService()
	authService := service.NewAuthService(cfg, userRepo, redis)
	snippetService := service.NewSnippetService(snippetRepo, patternRepo, redis, executorService)

	// Initialize handlers
	authHandler := handler.NewAuthHandler(authService)
	snippetHandler := handler.NewSnippetHandler(snippetService)

	// API routes
	v1 := r.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/signup", authHandler.Signup)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", authHandler.Logout)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(cfg))
		{
			// User profile
			protected.GET("/auth/me", authHandler.GetProfile)

			// Patterns
			protected.GET("/patterns", snippetHandler.ListPatterns)
			protected.GET("/patterns/:id/snippets", snippetHandler.ListSnippetsByPattern)

			// Snippets
			protected.GET("/snippets/:id", snippetHandler.GetSnippet)
			protected.POST("/snippets/:id/execute", snippetHandler.ExecuteCode)
			protected.POST("/snippets/:id/submit", snippetHandler.SubmitSolution)
			protected.POST("/snippets/:id/hints/:tier", snippetHandler.GetHint)

			// Progress
			protected.GET("/users/progress", snippetHandler.GetUserProgress)
		}

		// Admin routes (future)
		admin := v1.Group("/admin")
		admin.Use(middleware.AuthMiddleware(cfg))
		admin.Use(middleware.AdminMiddleware())
		{
			admin.POST("/snippets", snippetHandler.CreateSnippet)
			admin.PUT("/snippets/:id", snippetHandler.UpdateSnippet)
		}
	}

	return r
}
