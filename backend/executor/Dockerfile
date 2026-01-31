# Executor service Dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files from parent directory
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Copy source code
COPY executor/ ./executor/

# Build executor binary with cache
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -ldflags='-w -s' -o /executor ./executor/main.go

# Final stage - use Python with Docker CLI (optional)
FROM python:3.11-alpine

# Install Docker CLI (optional, for fallback to Docker if available) and wget for healthcheck
RUN apk add --no-cache docker-cli ca-certificates wget || true

# Copy executor binary with execute permissions
COPY --from=builder --chmod=0755 /executor /usr/local/bin/executor

EXPOSE 8081

CMD ["executor"]
