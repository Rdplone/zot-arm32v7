# ===== Builder Stage =====
FROM --platform=linux/amd64 golang:1.21-alpine3.18 AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates build-base

# Set environment
ENV CGO_ENABLED=0
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct

WORKDIR /src

# Clone a known stable version
RUN git clone --depth 1 --branch v2.1.7 https://github.com/project-zot/zot.git .

# Download dependencies
RUN go mod tidy && go mod download

# Build for ARM32v7 with minimal features
RUN GOOS=linux GOARCH=arm GOARM=7 \
    go build -ldflags '-w -s' \
    -o zot ./cmd/zot

# Verify build succeeded
RUN ls -la zot

# ===== Runtime Stage =====
FROM --platform=linux/arm/v7 alpine:3.18

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
