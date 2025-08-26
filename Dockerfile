# Alternative approach - use official binary if available
FROM --platform=linux/arm/v7 alpine:3.18 AS download

# Install curl and jq for downloading
RUN apk add --no-cache curl jq

WORKDIR /tmp

# Try to download pre-built binary first
RUN curl -s https://api.github.com/repos/project-zot/zot/releases/latest > latest.json && \
    VERSION=$(jq -r '.tag_name' latest.json) && \
    echo "Latest version: $VERSION" && \
    curl -L "https://github.com/project-zot/zot/releases/download/$VERSION/zot-linux-arm-minimal" -o zot-arm || \
    echo "Pre-built ARM binary not available, will build from source"

# Check if we got a binary
RUN if [ -f zot-arm ]; then \
        chmod +x zot-arm && \
        file zot-arm && \
        echo "Downloaded pre-built binary"; \
    else \
        echo "No pre-built binary available"; \
    fi

# ===== Builder Stage (fallback if no pre-built binary) =====
FROM --platform=linux/amd64 golang:1.21-alpine3.18 AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set simple environment
ENV CGO_ENABLED=0
ENV GO111MODULE=on

WORKDIR /src

# Clone a known stable version
RUN git clone --depth 1 --branch v2.1.7 https://github.com/project-zot/zot.git .

# Simple dependency download
RUN go mod tidy
RUN go mod download

# Build minimal version (without UI/search for reliability)
RUN GOOS=linux GOARCH=arm GOARM=7 \
    go build -ldflags '-w -s' \
    -o zot ./cmd/zot

# ===== Runtime Stage =====
FROM --platform=linux/arm/v7 alpine:3.18

RUN apk add --no-cache ca-certificates curl

# Create user and directories
RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

# Copy binary (prefer downloaded, fallback to built)
COPY --from=download /tmp/zot-arm* /tmp/ || true
COPY --from=builder /src/zot /tmp/zot-built || true

# Install the binary
RUN if [ -f /tmp/zot-arm ]; then \
        cp /tmp/zot-arm /usr/local/bin/zot; \
        echo "Using downloaded binary"; \
    elif [ -f /tmp/zot-built ]; then \
        cp /tmp/zot-built /usr/local/bin/zot; \
        echo "Using built binary"; \
    else \
        echo "No binary available" && exit 1; \
    fi && \
    chmod +x /usr/local/bin/zot

# Test binary
RUN /usr/local/bin/zot --help

# Create minimal config
RUN echo '{ \
  "distSpecVersion": "1.1.0-dev", \
  "storage": { \
    "rootDirectory": "/var/lib/zot", \
    "gc": true \
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
