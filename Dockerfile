# ===== Builder Stage =====
FROM arm32v7/alpine:3.19 AS builder

LABEL maintainer="your-email@example.com"
LABEL description="Zot Registry for ARM32v7/Raspberry Pi 2"
LABEL version="1.0"

# Install build dependencies
RUN apk add --no-cache bash git wget tar build-base make

# Install Go 1.24.6 for ARMv7
RUN wget https://golang.org/dl/go1.24.6.linux-armv6l.tar.gz -O /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# Verify Go version
RUN go version

# Clone Zot repository
WORKDIR /build
RUN git clone https://github.com/project-zot/zot.git .
RUN GO111MODULE=on GOPROXY=https://proxy.golang.org,direct go mod download

# Build Zot binary for ARMv7
RUN GOOS=linux GOARCH=arm go build -o zot ./cmd/zot

# ===== Runtime Stage =====
FROM arm32v7/alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata wget

# Create zot user and directories
RUN addgroup -g 1000 zot && \
    adduser -D -s /bin/sh -u 1000 -G zot zot && \
    mkdir -p /etc/zot /var/lib/zot && \
    chown -R zot:zot /etc/zot /var/lib/zot

# Copy built binary from builder
COPY --from=builder /build/zot /usr/local/bin/zot
RUN chmod +x /usr/local/bin/zot

# Create default config
RUN echo '{ \
  "distSpecVersion": "1.1.0", \
  "storage": { "rootDirectory": "/var/lib/zot" }, \
  "http": { "address": "0.0.0.0", "port": "5000" }, \
  "log": { "level": "info" } \
}' > /etc/zot/config.json && \
chown zot:zot /etc/zot/config.json

# Switch to zot user
USER zot

# Expose port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/v2/ || exit 1

# Set working directory
WORKDIR /var/lib/zot

# Start zot
CMD ["/usr/local/bin/zot", "serve", "/etc/zot/config.json"]
