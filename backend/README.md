# bugdrill Backend API

High-performance Golang API service for bugdrill - A unique coding interview prep platform focused on learning patterns through debugging.

## Architecture

Clean architecture with clear separation of concerns:

```
backend/
├── cmd/
│   └── server/          # Application entrypoint
├── internal/
│   ├── config/          # Configuration management
│   ├── database/        # Database connections (Postgres, Redis)
│   ├── handler/         # HTTP request handlers
│   ├── middleware/      # Gin middlewares (auth, CORS, etc.)
│   ├── model/           # Domain models and DTOs
│   ├── repository/      # Data access layer
│   ├── router/          # Route definitions
│   └── service/         # Business logic
├── migrations/          # SQL migration files
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── go.mod
```

## Tech Stack

- **Framework**: Gin (high-performance HTTP framework)
- **Database**: PostgreSQL 15 (with JSONB for test cases)
- **Cache**: Redis 7
- **Auth**: JWT (golang-jwt/jwt)
- **Container**: Docker + Docker Compose

## Quick Start

### Prerequisites

- Go 1.21+
- Docker & Docker Compose
- Make (optional but recommended)

### 1. Clone and Setup

```bash
cd backend

# Copy environment variables
cp .env.example .env

# Edit .env if needed (defaults work for local dev)
```

### 2. Start Development Environment

**Option A: Using Make (Recommended) - Hot-Reload**
```bash
make dev
```

**Option B: Using Docker Compose directly**
```bash
docker-compose up dev
```

**Option C: Production build (no hot-reload)**
```bash
docker-compose --profile production up api
```

This will start:
- **Development container** with Go 1.21 + hot-reload (Air)
- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`
- API service on `localhost:8080` (with auto-restart on code changes)
- Delve debugger on `localhost:2345`

### 3. Verify Installation

```bash
# Health check
curl http://localhost:8080/health

# Response: {"status":"healthy","app":"bugdrill"}
```

## Development

### Running Locally (without Docker)

```bash
# Install dependencies
make install

# Run migrations manually on local DB
# (ensure PostgreSQL and Redis are running)

# Start the server
make run
```

### Development Container Features

The `dev` service in docker-compose includes:
- **Go 1.21** with all dependencies
- **Air** for hot-reload (code changes auto-restart server)
- **Delve** debugger on port 2345
- **golangci-lint** for code linting
- **Git, Make, GCC** for building dependencies
- Volume mounts for live code editing
- Go modules cache for faster rebuilds

**Accessing the dev container:**
```bash
# Open interactive shell
make docker-shell

# Or directly
make docker-dev        # Start dev container with hot-reload
make docker-shell      # Open shell in dev container
docker exec -it bugdrill-dev sh

# Inside container, you can:
go test ./...
golangci-lint run
dlv debug ./cmd/server
```

### Available Make Commands

```bash
make help              # Show all available commands
make install           # Install Go dependencies
make build             # Build the application binary
make run               # Run locally (requires local DB)
make test              # Run tests
make test-coverage     # Run tests with coverage report
make lint              # Run linter

# Docker commands
make docker-build      # Build Docker image
make docker-up         # Start all services
make docker-down       # Stop all services
make docker-logs       # View logs
make docker-clean      # Remove containers and volumes

# Database commands
make migrate-create name=add_users  # Create new migration
make db-seed           # Seed database with sample data

# Development helpers
make dev               # Start full dev environment
make stop              # Stop dev environment
make restart           # Restart all services
```

## API Endpoints

### Authentication

```
POST   /api/v1/auth/signup         - Create new user account
POST   /api/v1/auth/login          - Login with email/password
POST   /api/v1/auth/refresh        - Refresh access token
POST   /api/v1/auth/logout         - Logout (invalidate tokens)
GET    /api/v1/auth/me             - Get current user profile [Protected]
```

### Patterns & Snippets

```
GET    /api/v1/patterns                  - List all pattern categories [Protected]
GET    /api/v1/patterns/:id/snippets     - List snippets for pattern [Protected]
GET    /api/v1/snippets/:id              - Get snippet details [Protected]
POST   /api/v1/snippets/:id/execute      - Run code against test cases [Protected]
POST   /api/v1/snippets/:id/submit       - Submit solution [Protected]
POST   /api/v1/snippets/:id/hints/:tier  - Get hint (1-3) [Protected]
GET    /api/v1/users/progress            - Get user progress [Protected]
```

### Admin

```
POST   /admin/v1/snippets          - Create new snippet [Admin]
PUT    /admin/v1/snippets/:id      - Update snippet [Admin]
```

## Example Requests

### Signup

```bash
curl -X POST http://localhost:8080/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "secure123",
    "display_name": "John Doe"
  }'
```

**Response:**
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "display_name": "John Doe",
    "role": "user",
    "is_trial": false,
    "trial_snippets_remaining": 5
  }
}
```

### Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "secure123"
  }'
```

### Get Patterns (Protected)

```bash
curl http://localhost:8080/api/v1/patterns \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Two Pointers",
    "slug": "two-pointers",
    "description": "Master the two-pointer technique for array and string problems",
    "order_index": 1
  }
]
```

### Execute Code

```bash
curl -X POST http://localhost:8080/api/v1/snippets/SNIPPET_ID/execute \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def two_sum(arr, target):\n    ...",
    "language": "python"
  }'
```

## Database Schema

### Key Tables

- **users** - User accounts and authentication
- **pattern_categories** - Coding patterns (Two Pointers, DFS, etc.)
- **snippets** - Buggy code snippets with test cases
- **user_snippet_attempts** - User submission history
- **user_pattern_progress** - Aggregated progress per pattern

See [migrations/001_init_schema.sql](migrations/001_init_schema.sql) for full schema.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENV` | Environment (development/production) | `development` |
| `SERVER_PORT` | API server port | `8080` |
| `DB_HOST` | PostgreSQL host | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |
| `DB_NAME` | Database name | `bugdrill` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `JWT_ACCESS_SECRET` | JWT secret for access tokens | Required |
| `JWT_REFRESH_SECRET` | JWT secret for refresh tokens | Required |
| `JWT_ACCESS_EXPIRATION` | Access token lifetime | `15m` |
| `JWT_REFRESH_EXPIRATION` | Refresh token lifetime | `168h` (7 days) |

## Testing

```bash
# Run all tests
make test

# Run with coverage
make test-coverage

# Run specific test
go test -v ./internal/service/...
```

## Production Deployment

### Build Production Image

```bash
docker build -t bugdrill-api:v1.0.0 .
```

### Run in Production

```bash
# Set production environment variables
export ENV=production
export JWT_ACCESS_SECRET=your-strong-secret
export DB_PASSWORD=secure-password

# Run container
docker run -d \
  -p 8080:8080 \
  -e ENV=$ENV \
  -e JWT_ACCESS_SECRET=$JWT_ACCESS_SECRET \
  -e DB_PASSWORD=$DB_PASSWORD \
  bugdrill-api:v1.0.0
```

### Kubernetes Deployment

See [SYSTEM_DESIGN.md](../SYSTEM_DESIGN.md#deployment-strategy) for Kubernetes manifests.

## Project Structure Details

### Clean Architecture Layers

**1. Handler Layer** (`internal/handler/`)
- HTTP request/response handling
- Request validation
- Calls service layer

**2. Service Layer** (`internal/service/`)
- Business logic
- Orchestrates repositories
- Caching logic

**3. Repository Layer** (`internal/repository/`)
- Data access (SQL queries)
- Database interactions
- No business logic

**4. Model Layer** (`internal/model/`)
- Domain entities
- DTOs (Data Transfer Objects)
- Request/Response structures

## Security

- Passwords hashed with bcrypt (cost 12)
- JWT-based authentication
- Short-lived access tokens (15 min)
- Refresh token rotation
- CORS enabled
- Request ID tracking
- Rate limiting (future)

## Performance

- Connection pooling (25 max connections)
- Redis caching (1-hour TTL for snippets)
- Graceful shutdown
- Health check endpoints

## Contributing

1. Create feature branch
2. Make changes
3. Run tests: `make test`
4. Run linter: `make lint`
5. VS Code Dev Container Support

This project includes `.devcontainer` configuration for seamless VS Code integration:

1. Install "Dev Containers" extension in VS Code
2. Open project folder
3. Press `F1` → "Dev Containers: Reopen in Container"
4. VS Code opens inside the dev container with all tools ready

**Benefits:**
- No local Go installation needed
- Pre-configured Go extensions
- Integrated debugger
- Consistent environment across team

## Troubleshooting

### Database connection failed

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# View logs
docker logs bugdrill-postgres
```

### Redis connection failed

```bash
# Check if Redis is running
docker ps | grep redis

# Test connection
docker exec -it bugdrill-redis redis-cli ping
```

### Port already in use

```bash
# Check what's using port 8080
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Change port in .env
SERVER_PORT=8081
```

### Hot-reload not working

```bash
# Check Air logs
docker logs bugdrill-dev

# Rebuild dev container
make docker-dev-build

# Manually trigger rebuild inside container
docker exec -it bugdrill-dev air -c .air.toml
```

### Go modules not downloading

```bash
# Clear modules cache
docker volume rm bugdrill_go_modules

# Restart dev container
docker-compose restart dev
# Change port in .env
SERVER_PORT=8081
```

## License

MIT

## Contact

For questions or support, reach out to the development team.

---

**Next Steps:**
- Set up code execution service (Docker sandbox)
- Implement LLM bug injection service
- Add comprehensive test coverage
- Set up CI/CD pipeline
- Deploy to staging environment
