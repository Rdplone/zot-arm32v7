# ===== Builder Stage =====
FROM --platform=linux/arm/v7 golang:1.21-alpine AS builder
LABEL maintainer="your-email@example.com"
LABEL description="Zot Registry for ARM32v7/Raspberry Pi 2 with full features"
LABEL version="1.0"

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash git wget tar build-base make ca-certificates nodejs npm

# Clone Zot repository
WORKDIR /go/src/github.com/project-zot/zot
RUN git clone https://github.com/project-zot/zot.git . && \
    git checkout v2.1.7

# Build UI assets
WORKDIR /go/src/github.com/project-zot/zot/web
RUN npm install && npm run build

# Go build (UI and Search enabled)
WORKDIR /go/src/github.com/project-zot/zot
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
COPY --from=builder /go/src/github.com/project-zot/zot/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

# Create config WITH UI AND SEARCH ENABLED
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

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

# Set working directory
WORKDIR /var/lib/zot

# Start zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
