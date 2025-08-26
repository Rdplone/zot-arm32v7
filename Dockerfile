# ===== Builder Stage =====
FROM --platform=linux/arm/v7 alpine:3.18 AS builder
LABEL maintainer="your-email@example.com"
LABEL description="Zot Registry for ARM32v7/Raspberry Pi 2 with full features"
LABEL version="1.0"

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash git wget tar build-base make ca-certificates curl jq

# Install Go 1.21.5 for ARMv7
RUN wget https://golang.org/dl/go1.21.5.linux-armv6l.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version

# Get latest stable release version from GitHub API (v2.1.7 as of now)
WORKDIR /build
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/project-zot/zot/releases/latest | jq -r '.tag_name') && \
    echo "Building Zot version: $LATEST_VERSION" && \
    git clone --depth 1 --branch $LATEST_VERSION https://github.com/project-zot/zot.git .

# Alternative: Manual version specification for more control
# ARG ZOT_VERSION=v2.1.5
# RUN git clone --depth 1 --branch ${ZOT_VERSION} https://github.com/project-zot/zot.git .

# Download dependencies
RUN GO111MODULE=on GOPROXY=https://proxy.golang.org,direct go mod download

# Build with full features including UI and search
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 \
    go build -ldflags '-w -s' \
    -tags 'containers_image_openpgp ui search' \
    -o zot ./cmd/zot

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

# Create config with UI and search enabled
RUN echo '{ \
  "distSpecVersion": "1.1.1", \
  "storage": { \
    "rootDirectory": "/var/lib/zot", \
    "dedupe": true, \
    "gc": true \
  }, \
  "http": { \
    "address": "0.0.0.0", \
    "port": "5000" \
  }, \
  "log": { \
    "level": "info" \
  }, \
  "extensions": { \
    "ui": { \
      "enable": true \
    }, \
    "search": { \
      "enable": true \
    } \
  } \
}' > /etc/zot/config.json && \
chown zot:zot /etc/zot/config.json

# Switch to zot user
USER zot

# Expose port
EXPOSE 5000

# Healthcheck - API endpoint'ini kontrol et
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

# Set working directory
WORKDIR /var/lib/zot

# Start zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
