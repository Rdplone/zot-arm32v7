# ===== Builder Stage =====
FROM --platform=linux/amd64 golang:1.21-alpine3.18 AS builder
LABEL maintainer="your-email@example.com"
LABEL description="Zot Registry for ARM32v7/Raspberry Pi 2 with full features"
LABEL version="1.0"

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash git wget tar build-base make ca-certificates curl jq \
    && rm -rf /var/cache/apk/*

# Set Go environment variables for better dependency resolution
ENV GO111MODULE=on \
    GOPROXY=https://proxy.golang.org,direct \
    GOSUMDB=sum.golang.org \
    GOPRIVATE="" \
    CGO_ENABLED=0

# Verify Go version
RUN go version

WORKDIR /build

# Use a specific stable version instead of latest to avoid dependency issues
ARG ZOT_VERSION=v2.1.7
RUN echo "Building Zot version: $ZOT_VERSION" && \
    git clone --depth 1 --branch ${ZOT_VERSION} https://github.com/project-zot/zot.git .

# Alternative: Get latest version (uncomment if you want latest)
# RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/project-zot/zot/releases/latest | jq -r '.tag_name') && \
#     echo "Building Zot version: $LATEST_VERSION" && \
#     git clone --depth 1 --branch $LATEST_VERSION https://github.com/project-zot/zot.git .

# Download dependencies step by step
RUN echo "Cleaning module cache..." && go clean -modcache

RUN echo "Downloading Go modules (attempt 1)..." && \
    go mod download || echo "First download attempt failed"

RUN echo "Trying with alternative proxy..." && \
    GOPROXY=https://goproxy.cn,direct go mod download || echo "Second download attempt failed"

RUN echo "Final download attempt with direct..." && \
    GOPROXY=direct go mod download

# Verify dependencies
RUN go mod verify

# Build with full features for ARM32v7
RUN echo "Building zot binary for ARM32v7..." && \
    GOOS=linux GOARCH=arm GOARM=7 \
    go build -v -ldflags '-w -s -extldflags "-static"' \
    -tags 'containers_image_openpgp' \
    -o zot ./cmd/zot

# Verify the binary was built correctly
RUN file zot && ls -la zot

# ===== Runtime Stage =====
FROM --platform=linux/arm/v7 alpine:3.18

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    ca-certificates tzdata curl file && \
    rm -rf /var/cache/apk/*

# Create zot user and directories
RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

# Copy built binary from builder
COPY --from=builder /build/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

# Verify the binary architecture
RUN file /usr/local/bin/zot

# Test the binary works
RUN /usr/local/bin/zot --help > /dev/null 2>&1

# Create basic config (without UI/search for stability)
RUN echo '{ \
  "distSpecVersion": "1.1.0-dev", \
  "storage": { \
    "rootDirectory": "/var/lib/zot", \
    "dedupe": false, \
    "gc": true, \
    "gcDelay": "1h", \
    "gcInterval": "24h" \
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

# Switch to zot user
USER zot

# Expose port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

# Set working directory
WORKDIR /var/lib/zot

# Start zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
