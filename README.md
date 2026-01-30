# bugdrill

A mobile-first coding interview preparation platform that teaches algorithmic patterns through debugging, not writing code from scratch.

## 🎯 Overview

bugdrill takes a unique approach to interview prep: instead of solving problems from scratch, you learn patterns by fixing intentionally buggy code. This method accelerates pattern recognition and helps you internalize common pitfalls.

**Key Features:**
- 🐛 Learn by debugging - faster pattern recognition
- 📱 Mobile-first design - practice anywhere
- 🎯 Pattern-based learning - two pointers, sliding window, DFS, BFS, etc.
- 🔄 Spaced repetition - retain what you learn
- 📊 Progress tracking - see your improvement
- 🆓 Anonymous trial - try before you commit

## 🏗️ Architecture

```
bugdrill/
├── backend/              # Go API server
│   ├── cmd/             # Application entrypoint
│   ├── internal/        # Core business logic
│   ├── migrations/      # Database schemas
│   ├── helm/            # Kubernetes deployment
│   └── tests/           # Integration tests
└── SYSTEM_DESIGN.md     # Detailed architecture docs
```

## 🛠️ Tech Stack

**Backend:**
- Go 1.21+ with Gin framework
- PostgreSQL 15 (persistent storage)
- Redis 7 (caching & sessions)
- JWT authentication

**Infrastructure:**
- Docker & Docker Compose
- Kubernetes (Helm charts)
- K3d for local testing

## 🚀 Quick Start

### Prerequisites
- Go 1.21+
- Docker & Docker Compose
- Make

### Running Locally

```bash
cd backend

# Start dependencies
make docker-up

# Run the server
make run

# API available at http://localhost:8080
```

### Running Tests

```bash
# Unit tests
make test

# Integration tests with Docker
make test-docker

# K3d cluster tests
make test-k3d
```

## 📖 Documentation

- [System Design](SYSTEM_DESIGN.md) - Comprehensive architecture documentation
- [Backend README](backend/README.md) - API development guide
- [K3d Testing](backend/K3D_TESTING.md) - Kubernetes testing setup
- [API Collection](backend/InterviewPal_API.postman_collection.json) - Postman collection

## 🗺️ Roadmap

**MVP (Current):**
- ✅ User authentication (email/password, OAuth)
- ✅ Pattern-based snippet browsing
- ✅ Code execution & validation
- ✅ Progress tracking
- 🚧 Hint system
- 🚧 Spaced repetition algorithm

**Post-MVP:**
- Leaderboards
- Community discussions
- User-generated content
- Daily challenges
- Collaborative debugging

## 🔒 Security

- JWT-based authentication
- Rate limiting on all endpoints
- Sandboxed code execution (planned)
- CORS policies
- Environment-based secrets

## 📊 Performance Targets

- API response time: <100ms
- Code execution timeout: 3s
- Uptime: 99.9%
- Concurrent users: 100K+

## 📝 License

Private repository - All rights reserved

---

**Built with ❤️ for developers who learn by doing**
