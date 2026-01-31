# ============================================
# API Target
# ============================================
FROM golang:1.21-alpine AS api-builder

RUN apk add --no-cache git make

WORKDIR /app

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -ldflags='-w -s' -o main ./cmd/server

FROM alpine:latest AS api

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=api-builder /app/main .
RUN chmod +x ./main

EXPOSE 8080

CMD ["./main"]

# ============================================
# Executor Target
# ============================================
FROM golang:1.22-alpine AS executor-builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY executor/ ./executor/

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -ldflags='-w -s' -o /executor ./executor/main.go

FROM python:3.11-alpine AS executor

RUN apk add --no-cache docker-cli ca-certificates wget || true

COPY --from=executor-builder --chmod=0755 /executor /usr/local/bin/executor

EXPOSE 8081

CMD ["executor"]

# ============================================
# Tests Target
# ============================================
FROM golang:1.22-alpine AS tests

WORKDIR /app

RUN apk add --no-cache git curl

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY internal/ ./internal/
COPY tests/ ./tests/

WORKDIR /app/tests

CMD ["go", "test", "-v"]
