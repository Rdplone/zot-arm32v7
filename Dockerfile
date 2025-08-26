# ===== Builder Stage =====
FROM --platform=linux/amd64 golang:1.21-alpine3.18 AS builder
LABEL maintainer="your-email@example.com"
LABEL description="Zot Registry for ARM32v7/Raspberry Pi 2 with full features"
LABEL version="1.0"

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash git wget tar build-base make ca-certificates curl jq

# Verify Go version and cross-compilation support
RUN go version

# Get latest stable release version from GitHub API
WORKDIR /build
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/project-zot/zot/releases/latest | jq -r '.tag_name') && \
    echo "Building Zot version: $LATEST_VERSION" && \
    git clone --depth 1 --branch $LATEST_VERSION https://github.com/project-zot/zot.git .

# Alternative: Manual version specification for more control
# ARG ZOT_VERSION=v2.1.7
# RUN git clone --depth 1 --branch ${ZOT_VERSION} https://github.com/project-zot/zot.git .

# Download dependencies
RUN GO111MODULE=on GOPROXY=https://proxy.golang.org,direct go mod download

# Build with full features including UI and search for ARM32v7
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 \
    go build -ldflags '-w -s -extldflags "-static"' \
    -tags 'containers_image_openpgp ui search' \
    -o zot ./cmd/zot

# Verify the binary was built correctly
RUN file zot && ls -la zot

# ===== Runtime Stage =====
FROM --platform=linux/arm/v7 alpine:3.18

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    ca-certificates tzdata curl && \
    rm -rf /var/cache/apk/*

# Create zot user and directories
RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

# Copy built binary from builder
COPY --from=builder /build/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

# Verify the binary works on ARM
RUN /usr/local/bin/zot --help > /dev/null 2>&1 || echo "Binary verification failed"

# Create config with UI and search enabled
RUN echo '{ \
  "distSpecVersion": "1.1.1", \
  "storage": { \
    "rootDirectory": "/var/lib/zot", \
    "dedupe": true, \
    "gc": true, \
    "gcDelay": "1h", \
    "gcInterval": "24h" \
  }, \
  "http": { \
    "address": "0.0.0.0", \
    "port": "5000", \
    "realm": "zot", \
    "tls": { \
      "cert": "", \
      "key": "" \
    } \
  }, \
  "log": { \
    "level": "info", \
    "output": "/tmp/zot.log" \
  }, \
  "extensions": { \
    "ui": { \
      "enable": true \
    }, \
    "search": { \
      "enable": true, \
      "cve": { \
        "updateInterval": "2h" \
      } \
    }, \
    "metrics": { \
      "enable": false, \
      "prometheus": { \
        "path": "/metrics" \
      } \
    } \
  } \
}' > /etc/zot/config.json && \
chown zot:zot /etc/zot/config.json

# Switch to zot user
USER zot

# Expose port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

# Set working directory
WORKDIR /var/lib/zot

# Start zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
