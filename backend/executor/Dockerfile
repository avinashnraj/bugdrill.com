# Executor service Dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git

# Copy go mod files from parent directory
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY executor/ ./executor/

# Build executor binary
RUN CGO_ENABLED=0 GOOS=linux go build -o /executor ./executor/main.go

# Final stage - use Docker-in-Docker
FROM docker:24-dind

# Install ca-certificates and wget for healthcheck
RUN apk add --no-cache ca-certificates wget

# Copy executor binary
COPY --from=builder /executor /usr/local/bin/executor

EXPOSE 8081

CMD ["executor"]
