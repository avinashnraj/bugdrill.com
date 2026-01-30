# Development Guide

## Running Tests Inside Dev Container

The development container now includes everything needed to run functional tests.

### Quick Start

1. **Start the dev environment:**
   ```bash
   make dev
   ```

2. **Run tests from host:**
   ```bash
   # Run functional tests
   make test-functional

   # Run unit tests
   make test-unit

   # Run all tests
   make test-all
   ```

3. **Or access the dev container and run tests:**
   ```bash
   make dev-shell

   # Inside container:
   make -f Makefile.test test
   ```

### Available Commands Inside Container

```bash
# Unit tests
go test -v ./internal/...

# Functional tests (BDD)
cd tests && go test -v

# With coverage
go test -v -race -coverprofile=coverage.out ./internal/...
go tool cover -html=coverage.out

# Specific feature
cd tests && go test -v -godog.tags="@auth"
```

### Test Environment Variables

Inside the dev container, these are automatically set:
- `API_BASE_URL=http://localhost:8080`
- `DB_HOST=postgres`
- `REDIS_HOST=redis`

### File Structure

```
backend/
├── tests/
│   ├── features/
│   │   └── auth.feature        # Gherkin scenarios
│   ├── steps/
│   │   └── auth_steps.go       # Step implementations
│   └── main_test.go            # Test runner
├── scripts/
│   └── run-tests.sh            # Test execution script
└── Makefile.test               # Test-specific targets
```

### Debugging Tests

1. **View API logs:**
   ```bash
   tail -f /tmp/air.log
   ```

2. **Check API health:**
   ```bash
   curl http://localhost:8080/health
   ```

3. **Manual API testing:**
   ```bash
   # Sign up
   curl -X POST http://localhost:8080/api/v1/auth/signup \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"Test123!@#"}'

   # Login
   curl -X POST http://localhost:8080/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"Test123!@#"}'
   ```

4. **Check database:**
   ```bash
   # Install psql if needed
   apk add postgresql-client

   # Connect to database
   psql -h postgres -U postgres -d bugdrill

   # List users
   SELECT id, email, created_at FROM users;
   ```

### Adding New Tests

1. **Create feature file** in `tests/features/`:
   ```gherkin
   Feature: Snippet Management
     Scenario: Get snippet by ID
       Given I am logged in
       When I request snippet with ID 1
       Then I should see the snippet code
   ```

2. **Implement steps** in `tests/steps/`:
   ```go
   func (a *APIContext) iRequestSnippetWithID(id int) error {
       // Implementation
   }
   ```

3. **Run the test:**
   ```bash
   cd tests && go test -v
   ```

### Tips

- Tests run against the live API server (port 8080)
- Database is shared with dev environment
- Use unique test data (timestamps, UUIDs) to avoid conflicts
- Clean up test data in `After` hooks if needed

### Outside Container (Host)

If you want to run tests from your host machine:

```bash
# Run functional tests in Docker Compose
docker-compose run --rm functional-tests

# Or use the PowerShell script
.\scripts\test-docker.ps1
```
