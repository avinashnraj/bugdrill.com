# bugdrill - System Design Document

**Version:** 1.0  
**Date:** January 29, 2026  
**Author:** System Architecture Team

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Requirements](#requirements)
3. [High-Level Architecture](#high-level-architecture)
4. [Component Design](#component-design)
5. [Database Schema](#database-schema)
6. [API Design](#api-design)
7. [Technology Stack](#technology-stack)
8. [Scalability & Performance](#scalability--performance)
9. [Security Considerations](#security-considerations)
10. [Deployment Strategy](#deployment-strategy)
11. [Future Enhancements](#future-enhancements)

---

## Executive Summary

**bugdrill** is a mobile-first coding interview preparation platform with a unique learning approach: mastering coding patterns through debugging buggy code snippets rather than writing from scratch.

**Key Differentiators:**
- Learn by fixing bugs in invariant patterns (two-pointers, sliding window, DFS, etc.)
- Quick iteration cycles with immediate feedback
- Spaced repetition for pattern mastery
- Anonymous trial + authenticated progression tracking

**Target Scale:**
- 10K MAU initially, designed for 100K+
- ~1,500 curated code snippets across patterns
- <100ms API response times
- 99.9% availability

---

## Requirements

### Functional Requirements

**MVP Features:**
1. **User Management**
   - Anonymous access (limited trial - 5 snippets)
   - Email/password authentication
   - OAuth (Google, GitHub) for quick signup
   - User profile with progress tracking

2. **Content Delivery**
   - Browse snippets by pattern category (array, tree, graph, etc.)
   - Filter by difficulty (Beginner, Medium, Hard)
   - Display buggy code snippet with context
   - Hint system (3-tier progressive hints)

3. **Code Execution & Validation**
   - In-app code editor with syntax highlighting
   - Run code against test cases
   - Real-time feedback on correctness
   - Show expected vs actual output

4. **Progress Tracking**
   - Track attempts per snippet
   - Success/failure rates by pattern
   - Spaced repetition algorithm
   - Achievement badges

5. **Content Management**
   - Admin portal for creating/editing snippets
   - LLM-assisted bug injection
   - Manual curation and approval workflow

**Post-MVP Features:**
- Leaderboards
- Discussion forums per snippet
- User-generated content
- Daily challenges
- Collaborative debugging sessions

### Non-Functional Requirements

| Requirement | Target | Justification |
|-------------|--------|---------------|
| **Latency** | <100ms API response | Mobile UX demands |
| **Availability** | 99.9% uptime | ~43 min downtime/month acceptable for MVP |
| **Scalability** | 100K concurrent users | 10x growth buffer |
| **Data Consistency** | Eventual consistency (progress), Strong (auth) | Balance performance & correctness |
| **Code Execution** | <3s timeout, sandboxed | Security + user experience |
| **Mobile Performance** | <2s initial load | Retain trial users |

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Layer                                 │
│  ┌──────────────────┐           ┌──────────────────┐                │
│  │  React Native    │           │   Admin Portal   │                │
│  │  Mobile App      │           │   (React Web)    │                │
│  │  (iOS/Android)   │           └──────────────────┘                │
│  └──────────────────┘                                                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS/REST
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         CDN (CloudFront)                             │
│              Static Assets (JS/CSS bundles, images)                  │
│              Code Snippets Cached via API (dynamic)                  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      API Gateway (Kong/AWS ALB)                      │
│         Rate Limiting, Auth, Routing, SSL Termination                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│   Auth Service (Go)       │   │   API Service (Go)        │
│   - JWT Generation        │   │   - Business Logic        │
│   - OAuth Integration     │   │   - Content Delivery      │
│   - Session Management    │   │   - Progress Tracking     │
└───────────────────────────┘   └───────────────────────────┘
                │                           │
                │                           │
                ▼                           ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│   PostgreSQL (Primary)    │   │   Redis Cache             │
│   - User Data             │   │   - Session Store         │
│   - Snippets Metadata     │   │   - Leaderboards (future) │
│   - Progress Tracking     │   │   - Rate Limiting         │
└───────────────────────────┘   └───────────────────────────┘
                                            │
                ┌───────────────────────────┼───────────────────────┐
                ▼                           ▼                       ▼
┌───────────────────────────┐   ┌───────────────────┐   ┌──────────────────┐
│  Code Execution Service   │   │   LLM Service     │   │   S3 Storage     │
│  (Isolated Containers)    │   │   (Bug Injection) │   │   - Static Assets│
│  - Docker Sandbox         │   │   - OpenAI API    │   │   - Images/Icons │
│  - Timeout Control        │   └───────────────────┘   │   - User Avatars │
│  - Multi-language Support │                           └──────────────────┘
└───────────────────────────┘
                │
                ▼
┌───────────────────────────┐
│   Message Queue (RabbitMQ)│
│   - Async Code Execution  │
│   - Progress Events       │
│   - Analytics Pipeline    │
└───────────────────────────┘
                │
                ▼
┌───────────────────────────┐
│   Analytics Service       │
│   - User Behavior         │
│   - Pattern Effectiveness │
│   - A/B Testing           │
└───────────────────────────┘
```

### Architecture Principles

1. **Microservices (Pragmatic)**: Start with 2-3 services, split further as needed
2. **Stateless Services**: All app state in DB/cache for horizontal scaling
3. **Event-Driven**: Async processing for non-critical paths
4. **Cache-Heavy**: Snippet content rarely changes, aggressive caching
5. **Security-First**: Sandboxed execution, input validation, rate limiting

---

## Component Design

### 1. Client Layer

#### React Native Mobile App
**Technology:** React Native + TypeScript + Expo (for rapid development)

**Key Modules:**
- **Authentication Module**: JWT storage, token refresh, OAuth flows
- **Code Editor Component**: 
  - Library: `react-native-code-editor` or CodeMirror wrapper
  - Syntax highlighting for Python/JavaScript
  - Auto-save drafts to local storage
- **Progress Tracker**: Local SQLite for offline caching
- **Analytics**: Amplitude/Mixpanel integration

**Offline-First Strategy:**
- Cache 10 snippets locally
- Queue submission attempts when offline
- Sync progress on reconnect

#### Admin Portal (React Web)
**Purpose:** Content management for snippets

**Features:**
- CRUD operations on snippets
- LLM bug injection interface
- Approval workflow for auto-generated bugs
- Analytics dashboard

---

### 2. API Gateway Layer

**Technology:** Kong Gateway or AWS Application Load Balancer

**Responsibilities:**
- **Rate Limiting**: 
  - Anonymous: 10 req/min
  - Authenticated: 100 req/min
- **Authentication**: JWT validation
- **Routing**: Path-based routing to services
- **SSL Termination**: HTTPS enforcement
- **CORS**: Mobile app origin whitelisting

---

### 3. Auth Service (Golang)

**Endpoints:**
```
POST   /auth/signup              - Email/password registration
POST   /auth/login               - Email/password login
POST   /auth/oauth/google        - Google OAuth callback
POST   /auth/oauth/github        - GitHub OAuth callback
POST   /auth/refresh             - Refresh access token
POST   /auth/logout              - Invalidate refresh token
GET    /auth/me                  - Get current user profile
```

**Technology Stack:**
- **Framework**: Gin (high-performance HTTP)
- **JWT**: `golang-jwt/jwt`
- **OAuth**: `golang.org/x/oauth2`
- **Password Hashing**: bcrypt (cost factor 12)

**Security:**
- Access tokens: 15-min expiry
- Refresh tokens: 7-day expiry, stored in Redis
- HTTPS-only cookies for web (future)

---

### 4. API Service (Golang)

**Core Endpoints:**

```
# Snippet Discovery
GET    /api/v1/patterns                    - List all pattern categories
GET    /api/v1/patterns/{id}/snippets      - List snippets for pattern
GET    /api/v1/snippets/{id}               - Get snippet details
GET    /api/v1/snippets/daily              - Daily challenge snippet

# Code Execution
POST   /api/v1/snippets/{id}/execute       - Run code with test cases
POST   /api/v1/snippets/{id}/submit        - Submit final solution

# Progress Tracking
GET    /api/v1/users/progress              - User's overall progress
GET    /api/v1/users/progress/patterns     - Progress by pattern
POST   /api/v1/users/progress/sync         - Sync offline attempts

# Hints
POST   /api/v1/snippets/{id}/hints/1       - Request hint tier 1-3

# Admin (Protected)
POST   /admin/v1/snippets                  - Create snippet
PUT    /admin/v1/snippets/{id}             - Update snippet
POST   /admin/v1/snippets/{id}/bugs        - LLM bug generation
```

**Service Layers:**
```
┌──────────────────┐
│  HTTP Handlers   │ - Request validation, auth middleware
└────────┬─────────┘
         │
┌────────▼─────────┐
│  Business Logic  │ - Core domain logic, orchestration
└────────┬─────────┘
         │
┌────────▼─────────┐
│  Data Access     │ - Repository pattern, DB queries
└──────────────────┘
```

---

### 5. Code Execution Service

**Architecture:** Isolated microservice for security

**Technology:**
- **Container Runtime**: Docker Engine
- **Orchestration**: Kubernetes for auto-scaling
- **Sandboxing**: gVisor for enhanced isolation
- **Languages Supported**: Python 3.11, JavaScript (Node 18)

**Execution Flow:**
```
1. Receive code + test cases via RabbitMQ
2. Spin up ephemeral container (pre-warmed pool)
3. Copy code into container (/tmp/code.py)
4. Execute: timeout 3s, memory limit 128MB, no network
5. Capture stdout, stderr, exit code
6. Compare output with expected results
7. Return result via callback or poll endpoint
8. Destroy container
```

**Security Measures:**
- No network access
- Read-only filesystem (except /tmp)
- Resource limits (CPU: 0.5 core, RAM: 128MB)
- Syscall filtering (block file I/O beyond /tmp)
- Regular image scanning for vulnerabilities

**Performance Optimization:**
- Container pool (5 pre-warmed containers per language)
- Response time: <1s for simple code

---

### 6. LLM Service (Bug Injection)

**Purpose:** Generate variations of correct code with bugs

**Workflow:**
```
1. Admin provides correct snippet + pattern type
2. LLM Service calls OpenAI API with prompt:
   "Introduce a subtle {bug_type} bug in this {pattern} code..."
3. Generate 3 variations per snippet
4. Store in database (status: pending_review)
5. Admin reviews and approves
6. Approved bugs marked as active
```

**Prompt Template:**
```
You are an expert coding interview instructor. Given this correct implementation
of a {pattern} pattern, introduce a subtle {bug_type} bug that a beginner might make.

Bug Types: off-by-one, null check missing, wrong operator, infinite loop

Correct Code:
{code}

Requirements:
- Bug should be realistic and educational
- Code should still be syntactically valid
- Bug should break exactly 1-2 test cases
- Include a comment explaining the bug (for admin review only)
```

**Cost Optimization:**
- Cache generated bugs (reuse across similar snippets)
- Batch generation (10 snippets per API call)
- Use GPT-3.5-turbo for cost ($0.50-$2 per 1000 snippets)

---

## Database Schema

### PostgreSQL Schema (Primary)

```sql
-- Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255), -- NULL for OAuth users
    display_name VARCHAR(100),
    oauth_provider VARCHAR(20), -- 'google', 'github', NULL
    oauth_id VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user', -- 'user', 'admin'
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    is_trial BOOLEAN DEFAULT FALSE,
    trial_snippets_remaining INT DEFAULT 5
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_oauth ON users(oauth_provider, oauth_id);

-- Pattern Categories
CREATE TABLE pattern_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 'Two Pointers', 'Sliding Window'
    slug VARCHAR(100) UNIQUE NOT NULL, -- 'two-pointers'
    description TEXT,
    icon_url VARCHAR(255),
    order_index INT DEFAULT 0
);

-- Snippets
CREATE TABLE snippets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_id INT REFERENCES pattern_categories(id),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) NOT NULL, -- 'beginner', 'medium', 'hard'
    language VARCHAR(20) NOT NULL, -- 'python', 'javascript'
    
    -- Code Content
    correct_code TEXT NOT NULL, -- Original correct implementation
    buggy_code TEXT NOT NULL, -- Version with bug
    bug_type VARCHAR(50), -- 'off_by_one', 'null_check', etc.
    bug_explanation TEXT, -- What the bug is (for hints)
    
    -- Test Cases (JSON array)
    test_cases JSONB NOT NULL,
    -- [{"input": {"arr": [1,2,3]}, "expected": 6}]
    
    -- Hints (3-tier)
    hint_1 TEXT,
    hint_2 TEXT,
    hint_3 TEXT,
    
    -- Metadata
    created_by UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'pending_review', 'archived'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_snippets_pattern ON snippets(pattern_id);
CREATE INDEX idx_snippets_difficulty ON snippets(difficulty);
CREATE INDEX idx_snippets_status ON snippets(status);

-- User Progress
CREATE TABLE user_snippet_attempts (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    snippet_id UUID REFERENCES snippets(id) ON DELETE CASCADE,
    
    -- Attempt Data
    submitted_code TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    execution_time_ms INT,
    test_cases_passed INT,
    test_cases_total INT,
    
    -- Context
    hints_used INT DEFAULT 0, -- How many hints were revealed
    attempt_number INT DEFAULT 1, -- 1st attempt, 2nd, etc.
    
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_attempts_user ON user_snippet_attempts(user_id);
CREATE INDEX idx_attempts_snippet ON user_snippet_attempts(snippet_id);
CREATE INDEX idx_attempts_correct ON user_snippet_attempts(is_correct);

-- User Pattern Mastery (Aggregated)
CREATE TABLE user_pattern_progress (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    pattern_id INT REFERENCES pattern_categories(id) ON DELETE CASCADE,
    
    snippets_attempted INT DEFAULT 0,
    snippets_solved INT DEFAULT 0,
    total_attempts INT DEFAULT 0,
    avg_attempts_per_solve DECIMAL(4,2),
    
    last_practiced_at TIMESTAMP,
    next_review_at TIMESTAMP, -- Spaced repetition
    mastery_level INT DEFAULT 0, -- 0-5 scale
    
    PRIMARY KEY (user_id, pattern_id)
);

-- Refresh Tokens
CREATE TABLE refresh_tokens (
    token VARCHAR(255) PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expiry ON refresh_tokens(expires_at);
```

### Storage Strategy: Why PostgreSQL for Snippets?

**Decision:** Store code snippets in PostgreSQL JSONB, NOT S3

**Rationale:**
- **Small dataset**: ~1,500 snippets × 5-10KB = ~7.5-15MB total (trivial for Postgres)
- **Transactional integrity**: Atomic updates to snippet + metadata
- **Query performance**: Filter by pattern/difficulty without external lookups
- **Caching layer**: Redis caches snippets (1-hour TTL), so DB hit only on cache miss
- **Simpler architecture**: Single source of truth, no S3 key management
- **Low latency**: Direct DB query (~5-10ms) vs DB + S3 fetch (~20-50ms)

**When to use S3:**
- User-uploaded profile pictures (future)
- Static assets (app icons, tutorial videos)
- Large binary files (compiled test executables)

**Storage calculation:**
```
PostgreSQL snippet storage:
- 1,500 snippets × 10KB avg = 15MB
- With indexes: ~30MB
- Negligible vs typical DB size (100GB+ capacity)
```

### Redis Schema (Cache & Session)

```
# Session Storage
Key: session:{user_id}
Value: {jwt_token, metadata}
TTL: 15 minutes

# Snippet Cache
Key: snippet:{snippet_id}
Value: JSON of snippet details
TTL: 1 hour

# Pattern List Cache
Key: patterns:all
Value: JSON array of categories
TTL: 24 hours

# User Progress Cache
Key: progress:{user_id}
Value: JSON of aggregated stats
TTL: 5 minutes

# Rate Limiting
Key: ratelimit:{ip}:{endpoint}
Value: request_count
TTL: 60 seconds

# Code Execution Queue (via RabbitMQ, but track in Redis)
Key: execution:{execution_id}
Value: {status, result}
TTL: 5 minutes
```

---

## API Design

### Authentication Flow

**Signup Flow:**
```
Client                   API Gateway              Auth Service             PostgreSQL
  │                           │                        │                       │
  │ POST /auth/signup         │                        │                       │
  ├──────────────────────────►│                        │                       │
  │ {email, password}         │  Validate & Forward    │                       │
  │                           ├───────────────────────►│                       │
  │                           │                        │ Hash password (bcrypt)│
  │                           │                        │ INSERT INTO users     │
  │                           │                        ├──────────────────────►│
  │                           │                        │                       │
  │                           │                        │◄──────────────────────┤
  │                           │                        │ User created          │
  │                           │   Generate JWT tokens  │                       │
  │                           │◄───────────────────────┤                       │
  │◄──────────────────────────┤ {access_token,         │                       │
  │ 201 Created               │  refresh_token}        │                       │
```

**OAuth Flow (Google Example):**
```
1. Client redirects to Google OAuth
2. User authorizes
3. Google redirects to /auth/oauth/google?code=...
4. Auth Service exchanges code for Google profile
5. Check if user exists by oauth_id, create if not
6. Generate JWT tokens
7. Return to client
```

### Code Execution Flow

**Request:**
```json
POST /api/v1/snippets/{id}/execute
Authorization: Bearer <jwt>

{
  "code": "def two_sum(arr, target):\n    ...",
  "language": "python"
}
```

**Response:**
```json
{
  "execution_id": "exec_123abc",
  "status": "completed",
  "is_correct": false,
  "test_results": [
    {
      "test_case": 1,
      "input": {"arr": [2,7,11,15], "target": 9},
      "expected": [0, 1],
      "actual": [1, 0],
      "passed": false,
      "execution_time_ms": 23
    },
    {
      "test_case": 2,
      "input": {"arr": [3,2,4], "target": 6},
      "expected": [1, 2],
      "actual": [1, 2],
      "passed": true,
      "execution_time_ms": 18
    }
  ],
  "total_time_ms": 41,
  "stdout": "",
  "stderr": ""
}
```

**Async Execution (for long-running code):**
```json
POST /api/v1/snippets/{id}/execute
--> 202 Accepted { "execution_id": "exec_123abc" }

GET /api/v1/executions/exec_123abc
--> 200 OK { "status": "running" }

GET /api/v1/executions/exec_123abc (poll after 2s)
--> 200 OK { "status": "completed", "test_results": [...] }
```

---

## Technology Stack

### Backend Services

| Component | Technology | Justification |
|-----------|------------|---------------|
| **API Service** | Golang + Gin | High performance, low memory, excellent concurrency |
| **Database** | PostgreSQL 15 | ACID compliance, JSONB support, proven reliability |
| **Cache** | Redis 7 | In-memory speed, pub/sub for real-time features |
| **Message Queue** | RabbitMQ | Reliable async processing, dead-letter queues |
| **Container Runtime** | Docker + gVisor | Industry standard + enhanced security |
| **API Gateway** | Kong Gateway | Open-source, plugin ecosystem, performant |

### Frontend

| Component | Technology | Justification |
|-----------|------------|---------------|
| **Mobile App** | React Native + Expo | Code reuse iOS/Android, large ecosystem, OTA updates |
| **State Management** | Zustand | Lightweight, no boilerplate vs Redux |
| **Code Editor** | Monaco Editor (web) / CodeMirror (mobile) | VS Code quality, syntax highlighting |
| **Admin Portal** | React + TypeScript + Vite | Fast builds, type safety |
| **UI Library** | React Native Paper | Material Design, accessible |

### Infrastructure

| Component | Technology | Justification |
|-----------|------------|---------------|
| **Cloud Provider** | AWS (or GCP) | Mature ecosystem, global reach |
| **Container Orchestration** | Kubernetes (EKS/GKE) | Auto-scaling, self-healing |
| **CDN** | CloudFront | Low latency global content delivery |
| **Object Storage** | S3 | Static assets (images, videos), user uploads |
| **Monitoring** | Prometheus + Grafana | Open-source, powerful querying |
| **Logging** | ELK Stack (Elasticsearch, Logstash, Kibana) | Centralized logging, searchable |
| **CI/CD** | GitHub Actions | Integrated with repo, free for open-source |

### Third-Party Services

| Service | Purpose | Cost Estimate |
|---------|---------|---------------|
| **OpenAI API** | Bug injection LLM | $50-100/month (cached) |
| **Auth0** (optional) | Managed OAuth | Free tier: 7K users |
| **Sentry** | Error tracking | Free tier: 5K events/month |
| **Amplitude** | Analytics | Free tier: 10M events/month |

---

## Scalability & Performance

### Scaling Strategy

#### Phase 1: MVP (0-10K users)
```
Infrastructure:
- 2x API servers (Kubernetes pods)
- 1x PostgreSQL (RDS t3.medium)
- 1x Redis (ElastiCache t3.micro)
- 5x Code execution workers

Cost: ~$200/month
```

#### Phase 2: Growth (10K-100K users)
```
Infrastructure:
- Auto-scaling API (2-10 pods)
- PostgreSQL read replicas (1 primary + 2 replicas)
- Redis cluster (3 nodes)
- Code execution pool (10-50 workers)
- CDN for snippet content

Cost: ~$800/month
```

#### Phase 3: Scale (100K+ users)
```
Infrastructure:
- Multi-region deployment
- Database sharding by user_id
- Separate read/write databases
- Microservice split (Auth, Content, Execution)
- Dedicated analytics pipeline

Cost: $3K+/month
```

### Performance Optimizations

**1. Database Query Optimization**
```sql
-- Inefficient (N+1 query)
SELECT * FROM snippets WHERE pattern_id = 1;
-- Then for each: SELECT * FROM user_snippet_attempts...

-- Optimized (JOIN with aggregate)
SELECT 
    s.*,
    COUNT(usa.id) as attempt_count,
    SUM(CASE WHEN usa.is_correct THEN 1 ELSE 0 END) as solve_count
FROM snippets s
LEFT JOIN user_snippet_attempts usa ON s.id = usa.snippet_id
WHERE s.pattern_id = 1 AND usa.user_id = $1
GROUP BY s.id;
```

**2. Caching Strategy**
```
┌─────────────────┐
│  Client Request │
└────────┬────────┘
         │
         ▼
┌────────────────┐
│ Check Redis    │──── HIT ───► Return cached data
└────────┬───────┘
         │ MISS
         ▼
┌────────────────┐
│ Query Postgres │
└────────┬───────┘
         │
         ▼
┌────────────────┐
│ Cache in Redis │
└────────┬───────┘
         │
         ▼
    Return data
```

**Cache TTL Strategy:**
- Snippets: 1 hour (rarely change)
- User progress: 5 minutes (balance freshness vs DB load)
- Pattern categories: 24 hours (almost static)
- Session data: 15 minutes (security)

**3. Database Connection Pooling**
```go
// Golang connection pool config
db, err := sql.Open("postgres", connStr)
db.SetMaxOpenConns(25)  // Max concurrent connections
db.SetMaxIdleConns(10)  // Idle connections in pool
db.SetConnMaxLifetime(5 * time.Minute)
```

**4. API Response Pagination**
```
GET /api/v1/snippets?pattern=two-pointers&page=1&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 156,
    "has_next": true
  }
}
```

**5. Code Execution Optimization**
- Pre-warmed container pool (avoid cold start)
- Result caching: Cache execution results for identical code + test cases
- Priority queue: Premium users get faster execution

### Load Testing Targets

```
Scenario: 1,000 concurrent users
- 70% browsing snippets (cached, <50ms)
- 20% executing code (<2s)
- 10% submitting solutions (<500ms)

Target Metrics:
- P50 latency: <100ms
- P95 latency: <500ms
- P99 latency: <2s
- Error rate: <0.1%
```

---

## Security Considerations

### 1. Code Execution Security

**Threats:**
- Malicious code execution (crypto mining, DOS)
- Data exfiltration
- Container escape

**Mitigations:**
```
✓ gVisor sandbox (user-space kernel)
✓ No network access
✓ Resource limits (CPU, RAM, disk)
✓ Timeout (3s max)
✓ Syscall filtering
✓ Regular security scanning (Trivy)
✓ Ephemeral containers (no state persistence)
```

### 2. Authentication & Authorization

**JWT Security:**
- Short-lived access tokens (15 min)
- Refresh token rotation
- Token invalidation on logout
- HTTPS-only transmission

**API Security:**
```go
// Rate limiting middleware
func RateLimitMiddleware(limit int) gin.HandlerFunc {
    limiter := rate.NewLimiter(rate.Limit(limit), limit*2)
    return func(c *gin.Context) {
        if !limiter.Allow() {
            c.JSON(429, gin.H{"error": "Too many requests"})
            c.Abort()
            return
        }
        c.Next()
    }
}
```

### 3. Input Validation

**Code Injection Prevention:**
```go
// Validate code length
if len(code) > 10000 {
    return errors.New("code too long")
}

// Sanitize for SQL injection (use parameterized queries)
db.Query("SELECT * FROM snippets WHERE id = $1", snippetID)

// Prevent path traversal
if strings.Contains(filename, "..") {
    return errors.New("invalid filename")
}
```

### 4. Data Privacy

- **Password Storage**: bcrypt with cost factor 12
- **PII Encryption**: Encrypt email at rest (optional for MVP)
- **GDPR Compliance**: User data export/deletion endpoints
- **Audit Logging**: Track all admin actions

### 5. API Security Headers

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000
Content-Security-Policy: default-src 'self'
```

---

## Deployment Strategy

### CI/CD Pipeline

```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  GitHub Actions     │
│  - Run tests        │
│  - Lint code        │
│  - Security scan    │
└──────┬──────────────┘
       │ All checks pass
       ▼
┌─────────────────────┐
│  Build Docker Image │
│  - Tag: sha-abc123  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Push to Registry   │
│  (ECR / Docker Hub) │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Deploy to K8s      │
│  - Staging first    │
│  - Run smoke tests  │
│  - Blue/green prod  │
└─────────────────────┘
```

### Kubernetes Deployment

**API Service Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
    spec:
      containers:
      - name: api
        image: bugdrill/api:latest
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: host
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Environment Strategy

| Environment | Purpose | Update Frequency |
|-------------|---------|------------------|
| **Development** | Local dev with Docker Compose | Continuous |
| **Staging** | Pre-prod testing, same config as prod | On merge to main |
| **Production** | Live users | Weekly releases (Tue/Thu) |

### Rollback Strategy

```bash
# Automated rollback on health check failure
kubectl rollout undo deployment/api-service

# Manual rollback to specific version
kubectl rollout undo deployment/api-service --to-revision=3
```

### Monitoring & Alerting

**Key Metrics:**
```
# Application Metrics
- Request rate (req/s)
- Error rate (%)
- Response time (P50, P95, P99)
- Active users

# Infrastructure Metrics
- CPU/Memory utilization
- Database connection pool size
- Redis hit/miss ratio
- Code execution queue length

# Business Metrics
- Signup conversion rate
- Trial-to-paid conversion
- Daily active users (DAU)
- Average snippets solved per user
```

**Alerts (PagerDuty/Slack):**
```
CRITICAL:
- API error rate > 1%
- Database down
- Code execution service unresponsive

WARNING:
- P95 latency > 1s
- Database connections > 80% pool
- Redis memory > 90%
```

---

## Future Enhancements

### Phase 2 Features

**1. Social Features**
- Leaderboards (Redis sorted sets)
- User profiles with badges
- Discussion threads per snippet (forum-like)
- Share progress on social media

**2. Advanced Learning**
- Adaptive difficulty (ML model for personalization)
- Video explanations for patterns
- Live 1-on-1 mentorship sessions
- Company-specific pattern tracks (FAANG focused)

**3. Content Expansion**
- System design snippets (architecture bugs)
- SQL query debugging
- Multi-language support (Java, C++, Go)

### Phase 3 Features

**1. Team/Enterprise**
- Company accounts with team dashboards
- Interview simulation mode (timed challenges)
- Custom snippet creation for interview panels
- Analytics for hiring managers

**2. Mobile Enhancements**
- Voice-guided hints
- AR mode (gamification)
- Offline mode with 50+ cached snippets

**3. AI Integration**
- GPT-4 powered personalized hints
- Code review feedback
- Automatic difficulty adjustment
- Generate custom practice sets based on weak patterns

---

## Cost Breakdown (MVP)

### Infrastructure (Monthly)

| Service | Configuration | Cost |
|---------|--------------|------|
| **AWS EC2** (API servers) | 2x t3.medium | $60 |
| **RDS PostgreSQL** | db.t3.medium | $70 |
| **ElastiCache Redis** | cache.t3.micro | $15 |
| **EKS** (Kubernetes) | Control plane + 3 nodes | $80 |
| **S3** | 10GB static assets | $0.23 |
| **CloudFront** | 1TB transfer | $85 |
| **Load Balancer** | ALB | $20 |
| **Monitoring** | CloudWatch | $10 |
| **Total Infrastructure** | | **~$340** |

### Third-Party Services

| Service | Cost |
|---------|------|
| OpenAI API | $50 |
| Sentry | Free |
| Amplitude | Free |
| **Total Services** | **$50** |

**Total MVP Cost: ~$400/month**

---

## Conclusion

This system design balances:
- **Scalability**: Horizontally scalable from day one
- **Security**: Multi-layered defense for code execution
- **Performance**: <100ms API responses with aggressive caching
- **Cost**: MVP runnable at <$500/month
- **Developer Experience**: Clear separation of concerns, testable architecture

**Key Architectural Decisions:**
1. **Golang backend**: Performance + simplicity
2. **React Native**: Fast mobile development, code reuse
3. **PostgreSQL**: Strong consistency for user data
4. **Redis**: Speed for caching and sessions
5. **Sandboxed execution**: Security-first approach

**Interview Talking Points:**
- "Designed for 10x scale from MVP"
- "Microservices where needed, monolith where simpler"
- "Security-first code execution with gVisor"
- "Event-driven architecture for async processing"
- "Cache-heavy for read-optimized workload"

---

**Next Steps:**
1. Review and validate design decisions
2. Set up project structure and scaffolding
3. Implement core API endpoints
4. Build React Native mobile prototype
5. Deploy MVP to staging environment

