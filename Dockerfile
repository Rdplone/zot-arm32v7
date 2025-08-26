# ===== Builder Stage =====
FROM golang:1.21-alpine3.18 AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates build-base

# Set environment with multiple proxy options
ENV CGO_ENABLED=0 \
    GO111MODULE=on \
    GOPROXY="https://proxy.golang.org,https://goproxy.cn,direct" \
    GOSUMDB="sum.golang.org" \
    GOPRIVATE=""

WORKDIR /src

# Use an even older, more stable version to avoid dependency conflicts
RUN git clone --depth 1 --branch v2.1.7 https://github.com/project-zot/zot.git .

# Debug: Show go environment
RUN go env

# Debug: Show what we're working with
RUN ls -la && head -20 go.mod

# Try to fix any module issues first
RUN go mod tidy -v

# Debug: Check mod status
RUN go list -m all | head -10

# Download dependencies with verbose output
RUN go mod download -x

# Verify dependencies
RUN go mod verify

# Build for ARM32v7 with minimal features
RUN GOOS=linux GOARCH=arm GOARM=7 \
    go build -v -ldflags '-w -s' \
    -o zot ./cmd/zot

# Verify build succeeded
RUN ls -la zot

# ===== Runtime Stage =====
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache ca-certificates curl

# Create user and directories
RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

# Copy binary from builder
COPY --from=builder /src/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

# Test binary works
RUN /usr/local/bin/zot --help > /dev/null

# Create minimal config
RUN echo '{ \
  "distSpecVersion": "1.1.0-dev", \
  "storage": { \
    "rootDirectory": "/var/lib/zot", \
    "gc": true, \
    "dedupe": false \
  }, \
  "http": { \
    "address": "0.0.0.0", \
    "port": "5000" \
  }, \
  "log": { \
    "level": "info" \
  } \
}' > /etc/zot/config.json && \
chown zot:zot /etc/zot/config.json

USER zot

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

WORKDIR /var/lib/zot

CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
