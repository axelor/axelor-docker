# Goovee Docker Image

A production-ready Docker image for Goovee, a Next.js application built with modern web technologies. This image provides a complete containerized solution for running Goovee applications with PostgreSQL database integration and various third-party service configurations.

## Overview

This Docker image is built using a multi-stage approach optimized for production deployments. It includes:
- Next.js application with standalone output
- PostgreSQL database connectivity
- Multi-tenancy support
- Integration with Mattermost
- Social media platform configurations
- Secure non-root user execution

## Image Details

- **Base Image**: `node:22`
- **Architecture**: Multi-stage build for optimized image size
- **Package Manager**: pnpm with frozen lockfile
- **User**: Non-root user (node:node)
- **Port**: 3000

## Prerequisites

- Docker Engine 20.10 or later
- PostgreSQL database server

## Environment Variables

### Database Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `PGHOST` | `postgres` | PostgreSQL host |
| `PGPORT` | `5432` | PostgreSQL port |
| `PGUSER` | `axelor` | PostgreSQL username |
| `PGPASSWORD` | `axelor` | PostgreSQL password |
| `PGDATABASE` | `axelor` | PostgreSQL database name |
| `DATABASE_URL` | Auto-generated | Complete database connection string |

### Application Configuration

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `DATA_STORAGE` | `/data/attachments` | File attachment storage path |
| `MULTI_TENANCY` | `false` | Enable multi-tenant support |
| `INCLUDE_LANGUAGE` | `true` | Include language translations |

### Public URLs

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `GOOVEE_PUBLIC_HOST` | `http://localhost:3000` | Public application URL |
| `GOOVEE_PUBLIC_AOS_URL` | `http://localhost:8080` | AOS service URL |
| `NEXTAUTH_URL` | `http://localhost:3000` | NextAuth callback URL |

### Third-party Integrations

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `GOOVEE_PUBLIC_MATTERMOST_HOST` | `http://mattermost:8065` | Mattermost server URL |
| `GOOVEE_PUBLIC_MATTERMOST_WEBSOCKET_URL` | `ws://mattermost:8065/api/v4/websocket` | Mattermost WebSocket URL |
| `GOOVEE_PUBLIC_LINKEDIN_URL` | `https://www.linkedin.com` | LinkedIn profile URL |
| `GOOVEE_PUBLIC_TWITTER_URL` | `https://x.com` | Twitter/X profile URL |
| `GOOVEE_PUBLIC_INSTAGRAM_URL` | `https://www.instagram.com` | Instagram profile URL |
| `GOOVEE_PUBLIC_WHATSAPP_URL` | `https://web.whatsapp.com` | WhatsApp contact URL |

## Quick Start

### Using Docker Run

```bash
docker run -d \
  --name goovee \
  -p 3000:3000 \
  -e PGHOST=your-postgres-host \
  -e PGUSER=your-db-user \
  -e PGPASSWORD=your-db-password \
  -e PGDATABASE=your-database \
  -e GOOVEE_PUBLIC_HOST=http://your-domain.com \
  -v /path/to/attachments:/data/attachments \
  axelor/goovee:latest
```

### Using Docker Compose

```yaml
version: '3.8'

services:
  goovee:
    image: axelor/goovee:latest
    ports:
      - "3000:3000"
    environment:
      PGHOST: postgres
      PGUSER: axelor
      PGPASSWORD: axelor
      PGDATABASE: axelor
      GOOVEE_PUBLIC_HOST: http://localhost:3000
      GOOVEE_PUBLIC_AOS_URL: http://localhost:8080
    volumes:
      - attachments:/data/attachments
    depends_on:
      - postgres

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: axelor
      POSTGRES_PASSWORD: axelor
      POSTGRES_DB: axelor
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  attachments:
  postgres_data:
```

## Volumes

| Path | Description |
|------|-------------|
| `/data/attachments` | File attachment storage directory |

## Exposed Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `3000` | HTTP | Main application port |

## Security Features

- Non-root user execution (UID/GID 1001)
- Production-optimized Next.js standalone output
- Secure environment variable handling

## Health Check

The application serves health status at the root endpoint. You can add a health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1
```

## Development vs Production

This image is optimized for production use with:
- Telemetry disabled by default
- Standalone Next.js output for minimal dependencies
- Optimized layer caching in multi-stage build
- Security hardening with non-root user

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Verify PostgreSQL server is running and accessible
   - Check database credentials and network connectivity
   - Ensure database exists and user has proper permissions

2. **File Upload Issues**
   - Verify `/data/attachments` volume is properly mounted
   - Check file system permissions
   - Ensure sufficient disk space

3. **Application Not Accessible**
   - Verify port 3000 is exposed and not blocked by firewall
   - Check if another service is using port 3000
   - Verify `HOSTNAME` and `PORT` environment variables

## Building from Source

```bash
git clone git@github.com:axelor/axelor-docker.git
cd axelor-docker/goovee
docker build -t axelor/goovee:latest .
```

## Support

For issues and questions:
- **Documentation**: [Axelor Documentation](https://docs.axelor.com)
- **Forum**: [Axelor Forum](https://forum.axelor.com)
- **Source Code**: [GitHub Repository](https://github.com/axelor/axelor-open-suite)

## License

This image is based on Goovee, which is licensed under the Sustainable Use License.