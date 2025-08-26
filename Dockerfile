# ===== Builder Stage =====
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates build-base

# Set environment
ENV CGO_ENABLED=0 \
    GO111MODULE=on \
    GOPROXY="https://proxy.golang.org,https://goproxy.cn,direct"

WORKDIR /src

# Clone Zot v2.1.7
RUN git clone --depth 1 --branch v2.1.7 https://github.com/project-zot/zot.git .

# Show Go version
RUN go version

# Download dependencies
RUN go mod tidy && go mod download

# Build for ARM32v7
RUN GOOS=linux GOARCH=arm GOARM=7 \
    go build -v -ldflags '-w -s' \
    -tags 'containers_image_openpgp ui search' \
    -o zot ./cmd/zot

# ===== Runtime Stage =====
FROM alpine:3.18

RUN apk add --no-cache ca-certificates curl

RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

COPY --from=builder /src/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

RUN /usr/local/bin/zot --help > /dev/null

# Enhanced config for v2.1.7
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
      "enable": true, \
      "cve": { \
        "updateInterval": "2h" \
      } \
    } \
  } \
}' > /etc/zot/config.json && \
chown zot:zot /etc/zot/config.json

USER zot
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/v2/ || exit 1

WORKDIR /var/lib/zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
