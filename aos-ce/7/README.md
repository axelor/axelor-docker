# Axelor Open Suite - Community Edition Docker Image - AOP 7.+

## Overview

The `aos-ce` (Axelor Open Suite Community Edition) Docker image provides a production ready containerized version of the Axelor Open Suite ERP application. This image is built using a multi-stage approach, combining the power of the Axelor application builder with a lightweight Alpine Linux runtime environment.

## Architecture

### Build Stage
- **Base Image**: `axelor/app-builder:latest`
- **Source**: Axelor Open Suite webapp and modules from GitHub
- **Build Process**: Gradle-based compilation with WAR file generation

### Runtime Stage
- **Base Image**: Alpine Linux 3.22
- **Application Server**: Apache Tomcat 9.0.100
- **Java Runtime**: OpenJDK 11
- **Database Client**: PostgreSQL 16 client
- **User**: Non-root user `axelor` (UID: 1000, GID: 1000)

## Features

- **Development Mode**: Configurable development environment
- **Database Integration**: PostgreSQL support with automatic extension setup
- **Health Monitoring**: Built-in health check endpoint
- **Data Persistence**: Configurable data directories for exports and attachments
- **Post-Startup Scripts**: Extensible initialization system
- **Metadata Management**: Automatic metadata restoration
- **Timezone Support**: Configurable timezone (default: Europe/Paris)

## Building the Image

### Build Command

To build the image locally, use the following command:

```bash
docker build -t axelor/aos-ce:latest .
```

### Build Arguments

The image supports several build arguments for customization:

#### Primary Build Arguments

- `AOP_VERSION`: Version of the Axelor application builder image (default: `latest`)
  - Controls which version of the build tools and dependencies are used
  - Should match the target Axelor Open Suite version compatibility

- `AOS_VERSION`: Version or branch of Axelor Open Suite to build (default: `master`)
  - Specifies which branch/tag of the source code to clone and build
  - Common values: `master`, `dev`, or specific version tags like `v7.0.0`

#### Example with Custom Build Arguments

```bash
# Build with specific versions
docker build \
  --build-arg AOP_VERSION=6.1 \
  --build-arg AOS_VERSION=7.0.0 \
  -t axelor/aos-ce:7.0.0 .

# Build development version
docker build \
  --build-arg AOS_VERSION=dev \
  -t axelor/aos-ce:dev .
```

#### Additional Build Arguments

- `UID`: User ID for the axelor user (default: `1000`)
- `GID`: Group ID for the axelor user (default: `1000`)
- `TOMCAT_VERSION`: Apache Tomcat version (default: `9.0.100`)

## Configuration

### Environment Variables

#### Database Configuration
- `PGHOST`: PostgreSQL host (default: `postgres`)
- `PGPORT`: PostgreSQL port (default: `5432`)
- `PGUSER`: PostgreSQL username (default: `axelor`)
- `PGPASSWORD`: PostgreSQL password (default: `axelor`)
- `PGDATABASE`: PostgreSQL database name (default: `axelor`)

#### Application Configuration
- `APP_USER`: Application admin username (default: `admin`)
- `APP_PASS`: Application admin password (default: `admin`)
- `APP_NAME`: Application name (optional)
- `APP_LANGUAGE`: Application language (default: `en`)
- `APP_DEMO_DATA`: Enable demo data loading (default: `false`)
- `APP_LOAD_APPS`: Studio apps to install (optional)
- `DEV_MODE`: Enable development mode (default: `true`)
- `ENABLE_QUARTZ`: Enable Quartz scheduler (default: `false`)

#### Memory Configuration
- `JAVA_XMS`: Initial heap size (optional)
- `JAVA_XMX`: Maximum heap size (optional)

#### Data Directories
- `APP_DATA_EXPORTS_DIR`: Export files directory (default: `/data/exports`)
- `APP_DATA_ATTACHMENTS_DIR`: Attachment files directory (default: `/data/attachments`)

#### Security
- `ENCRYPTION_PASSWORD`: Encryption password for sensitive data (optional)

#### Additional Configuration
- `ADDITIONAL_PROPERTIES`: Additional application properties (optional).  
  **Format:** `key=value` line by line, no space, no comments, no extra lines.

## Usage

### Docker Compose (Recommended)

```yaml
services:
  app:
    image: axelor/aos-ce:latest
    environment:
      - PGHOST=postgres
      - PGPORT=5432
      - PGUSER=axelor
      - PGPASSWORD=axelor
      - PGDATABASE=axelor
      - DEV_MODE=true
      - JAVA_XMX=4096m
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 1800s
    depends_on:
      - postgres
    volumes:
      - app_data:/data

  postgres:
    image: "postgres:16"
    environment:
      - POSTGRES_USER=axelor
      - POSTGRES_PASSWORD=axelor
      - POSTGRES_DB=axelor
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  app_data:
  postgres_data:
```

### Docker Run Command

```bash
docker run -d \
  --name axelor-aos-ce \
  -p 8080:8080 \
  -e PGHOST=postgres \
  -e PGUSER=axelor \
  -e PGPASSWORD=axelor \
  -e PGDATABASE=axelor \
  -e JAVA_XMX=4096m \
  -v axelor_data:/data \
  axelor/aos-ce:latest
```

## Startup Process

1. **Configuration**: Application properties are dynamically updated based on environment variables
2. **Database Wait**: The container waits for PostgreSQL to be available
3. **Database Setup**: PostgreSQL extensions (unaccent) are installed if needed
4. **Tomcat Start**: The application server starts with the configured parameters
5. **Post-Startup**: Initialization scripts are executed, including metadata restoration

## Health Check

The image includes a built-in health check endpoint accessible at:
- **URL**: `http://localhost:8080/health`
- **Method**: GET
- **Response**: HTTP 200 when healthy

## Data Persistence

The image uses `/data` as the base directory for persistent data:
- `/data/exports`: Application export files
- `/data/attachments`: File attachments
- `/data/.first_start_completed`: First startup marker

## Ports

- **8080**: Main application HTTP port

## Logging

- **Development Mode**: DEBUG level logging
- **Production Mode**: INFO level logging

## Security Considerations

- Runs as non-root user `axelor`
- Default credentials should be changed in production
- Database connections should use secure passwords
- Consider using Docker secrets for sensitive information

## Extending the Image

### Custom Post-Startup Scripts

Place executable scripts in `/usr/local/bin/post-startup.d/` to extend the initialization process. Scripts are executed in alphabetical order after the application starts.

### Custom Configuration

Use the `ADDITIONAL_PROPERTIES` environment variable to add custom application properties:

```bash
ADDITIONAL_PROPERTIES="custom.property1=value1
custom.property2=value2"
```

## Support

For issues and questions:
- **Documentation**: [Axelor Documentation](https://docs.axelor.com)
- **Forum**: [Axelor Forum](https://forum.axelor.com)
- **Source Code**: [GitHub Repository](https://github.com/axelor/axelor-open-suite)

## License

This image is based on Axelor Open Suite Community Edition, which is licensed under the AGPL v3 license. 