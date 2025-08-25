# Zot Registry for ARM32v7/Raspberry Pi 2

[![Docker Pulls](https://img.shields.io/docker/pulls/rdplone/zot-arm32v7)](https://hub.docker.com/r/rdplone/zot-arm32v7)
[![Docker Image Size](https://img.shields.io/docker/image-size/rdplone/zot-arm32v7/latest)](https://hub.docker.com/r/rdplone/zot-arm32v7)
[![License](https://img.shields.io/github/license/project-zot/zot)](https://github.com/project-zot/zot/blob/main/LICENSE)

A lightweight, secure Docker registry implementation optimized for ARM32v7 devices like Raspberry Pi 2. Built on [Project Zot](https://github.com/project-zot/zot), this image provides a complete OCI-compliant container registry that runs efficiently on ARM-based single-board computers.

## Features

- 🏗️ **ARM32v7 Optimized**: Specifically built for Raspberry Pi 2 and similar ARM devices
- 🔒 **Secure by Default**: Runs as non-root user with minimal attack surface
- 📦 **OCI Compliant**: Full support for Docker and OCI container images
- 🚀 **Lightweight**: Based on Alpine Linux for minimal resource usage
- 📊 **Built-in Monitoring**: Health checks and comprehensive logging
- 🔧 **Easy Configuration**: Simple JSON-based configuration

## Quick Start

### Basic Usage

```bash
# Pull the image
docker pull rdplone/zot-arm32v7:latest

# Run with default configuration
docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v zot-data:/var/lib/zot \
  your-username/zot-arm32v7:latest
```

### With Custom Configuration

```bash
# Create a custom config directory
mkdir -p ./zot-config

# Create custom configuration (optional)
cat > ./zot-config/config.json << EOF
{
  "distSpecVersion": "1.1.0",
  "storage": {
    "rootDirectory": "/var/lib/zot"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000"
  },
  "log": {
    "level": "info"
  }
}
EOF

# Run with custom config
docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v ./zot-config:/etc/zot:ro \
  -v zot-data:/var/lib/zot \
  rdplone/zot-arm32v7:latest
```

## Docker Compose

```yaml
version: '3.8'

services:
  zot-registry:
    image: rdplone/zot-arm32v7:latest
    container_name: zot-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - zot-data:/var/lib/zot
      - ./config:/etc/zot:ro
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5000/v2/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s

volumes:
  zot-data:
```

## Configuration

The registry uses a JSON configuration file located at `/etc/zot/config.json`. Here's an example with common options:

```json
{
  "distSpecVersion": "1.1.0",
  "storage": {
    "rootDirectory": "/var/lib/zot",
    "dedupe": true,
    "gc": true
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "realm": "zot",
    "auth": {
      "htpasswd": {
        "path": "/etc/zot/htpasswd"
      }
    }
  },
  "log": {
    "level": "info",
    "output": "/var/log/zot.log"
  }
}
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ZOT_CONFIG` | `/etc/zot/config.json` | Path to configuration file |

## Usage Examples

### Push an Image

```bash
# Tag your image for the local registry
docker tag my-app:latest localhost:5000/my-app:latest

# Push to the registry
docker push localhost:5000/my-app:latest
```

### Pull an Image

```bash
# Pull from the registry
docker pull localhost:5000/my-app:latest
```

### List Repositories

```bash
# List all repositories
curl http://localhost:5000/v2/_catalog

# List tags for a repository
curl http://localhost:5000/v2/my-app/tags/list
```

## Security Considerations

### Authentication Setup

Create an htpasswd file for basic authentication:

```bash
# Create htpasswd file
docker run --rm httpd:alpine htpasswd -Bbn username password > htpasswd

# Mount it in your container
docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v $(pwd)/htpasswd:/etc/zot/htpasswd:ro \
  -v $(pwd)/config.json:/etc/zot/config.json:ro \
  -v zot-data:/var/lib/zot \
  rdplone/zot-arm32v7:latest
```

### HTTPS/TLS Setup

For production use, enable TLS in your configuration:

```json
{
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "tls": {
      "cert": "/etc/zot/server.crt",
      "key": "/etc/zot/server.key"
    }
  }
}
```

## Monitoring and Maintenance

### Health Check

The container includes a built-in health check that verifies the registry is responding:

```bash
# Check container health
docker ps
# Look for "healthy" status

# Manual health check
curl -f http://localhost:5000/v2/ || echo "Registry is down"
```

### Logs

```bash
# View container logs
docker logs zot-registry

# Follow logs
docker logs -f zot-registry
```

### Garbage Collection

Enable automatic garbage collection in your config:

```json
{
  "storage": {
    "rootDirectory": "/var/lib/zot",
    "gc": true,
    "gcDelay": "1h",
    "gcInterval": "24h"
  }
}
```

## Hardware Requirements

### Minimum Requirements
- **CPU**: ARM32v7 (ARMv7) processor
- **RAM**: 512MB (1GB+ recommended)
- **Storage**: 1GB+ for OS and registry data
- **Network**: Ethernet or Wi-Fi connectivity

### Recommended Hardware
- Raspberry Pi 2 Model B or newer
- Raspberry Pi 3/4 (will run in ARM32v7 compatibility mode)
- Other ARM32v7 single-board computers

## Troubleshooting

### Common Issues

1. **Permission denied errors**
   ```bash
   # Ensure proper ownership of data directory
   sudo chown -R 1000:1000 /path/to/zot-data
   ```

2. **Port already in use**
   ```bash
   # Check what's using port 5000
   sudo netstat -tulpn | grep 5000
   # Use a different port
   docker run -p 5001:5000 rdplone/zot-arm32v7:latest
   ```

3. **Out of memory on Raspberry Pi**
   ```bash
   # Increase swap space or use lighter configuration
   # Reduce log level to "error" in config
   ```

### Debug Mode

Run with debug logging:

```json
{
  "log": {
    "level": "debug"
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Build and test on ARM32v7 hardware
5. Submit a pull request

## License

This project follows the same license as [Project Zot](https://github.com/project-zot/zot). See the [LICENSE](https://github.com/project-zot/zot/blob/main/LICENSE) file for details.

## Related Projects

- [Project Zot](https://github.com/project-zot/zot) - The upstream OCI registry
- [Docker Registry](https://docs.docker.com/registry/) - Official Docker registry
- [Harbor](https://goharbor.io/) - Cloud native registry

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/rdplone/zot-arm32v7/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/rdplone/zot-arm32v7/discussions)
- 📖 **Documentation**: [Zot Documentation](https://zotregistry.io/)

---
