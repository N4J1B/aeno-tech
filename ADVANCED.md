# 🔧 Advanced Configuration & Troubleshooting

Advanced topics untuk **Aeno.tech Stack** - custom configurations, performance tuning, dan troubleshooting mendalam.

---

## 📋 Table of Contents

1. [Nginx Configuration](#-nginx-configuration)
2. [Database Management](#-database-management)
3. [GitHub Actions CI/CD](#-github-actions-cicd)
4. [Performance Optimization](#-performance-optimization)
5. [Security Hardening](#-security-hardening)
6. [Custom Keycloak Setup](#-custom-keycloak-setup)
7. [SendGrid Customization](#-sendgrid-customization)
8. [Multi-Environment Setup](#-multi-environment-setup)
9. [Backup & Recovery](#-backup--recovery)
10. [Advanced Troubleshooting](#-advanced-troubleshooting)

---

## 🌐 Nginx Configuration

### Custom Nginx Config

Edit `config/nginx/nginx.conf` untuk kustomisasi:

```nginx
# Performance tuning
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;

# SSL optimization
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!aNULL:!MD5:!DSS;

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;

# Custom headers
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
```

### SSL Certificate Management

#### Custom SSL Certificates
```bash
# Generate custom certificates
mkdir -p config/nginx/ssl/custom
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout config/nginx/ssl/custom/domain.key \
  -out config/nginx/ssl/custom/domain.crt

# Update nginx to use custom certs
ln -sf custom/domain.crt config/nginx/ssl/sso.aeno.tech.crt
ln -sf custom/domain.key config/nginx/ssl/sso.aeno.tech.key
```

#### Wildcard SSL with Let's Encrypt
```bash
# DNS challenge for wildcard certificate
docker run --rm --name certbot \
  -v "$(pwd)/config/nginx/certbot/conf:/etc/letsencrypt" \
  certbot/certbot certonly \
  --manual \
  --preferred-challenges dns \
  --email admin@aeno.tech \
  --agree-tos \
  -d "*.aeno.tech"
```

### Load Balancing

For multiple backend instances:

```nginx
upstream keycloak_backend {
    server keycloak1:8443;
    server keycloak2:8443;
    least_conn;
}

upstream sendgrid_backend {
    server sendgrid-app1:3000;
    server sendgrid-app2:3000;
    ip_hash;
}
```

---

## 🗄️ Database Management

### PostgreSQL Tuning

Edit PostgreSQL configuration for production:

```sql
-- config/postgres-custom.conf
shared_buffers = '256MB'
effective_cache_size = '1GB'  
work_mem = '4MB'
maintenance_work_mem = '64MB'
checkpoint_completion_target = 0.9
wal_buffers = '16MB'
default_statistics_target = 100
```

Apply configuration:
```bash
# Mount custom config in docker-compose.yml
volumes:
  - ./config/postgres-custom.conf:/etc/postgresql/postgresql.conf
```

### Database Migration

#### Backup Strategies
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$DATE"
mkdir -p "$BACKUP_DIR"

# Full backup
docker exec shared_postgres pg_dumpall -U postgres > "$BACKUP_DIR/full_backup.sql"

# Individual databases
docker exec shared_postgres pg_dump -U postgres keycloak_db > "$BACKUP_DIR/keycloak.sql"
docker exec shared_postgres pg_dump -U postgres sendgrid_emails > "$BACKUP_DIR/sendgrid.sql"

# Compress backups
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

# Keep only last 7 days
find backups/ -name "*.tar.gz" -mtime +7 -delete
```

#### Point-in-Time Recovery
```bash
# Enable WAL archiving
echo "wal_level = replica" >> config/postgres-custom.conf
echo "archive_mode = on" >> config/postgres-custom.conf
echo "archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'" >> config/postgres-custom.conf
```

### Database Monitoring
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity;

-- Check database sizes
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database;

-- Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

---

## 🤖 GitHub Actions CI/CD

### Complete CI/CD Pipeline

File: `.github/workflows/complete-pipeline.yml`

```yaml
name: Complete CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

env:
  REGISTRY: docker.io
  KEYCLOAK_IMAGE: n4j1b/keycloak-custom
  SENDGRID_IMAGE: n4j1b/sendgrid-inbound

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Test docker-compose syntax
        run: docker-compose config -q
        
      - name: Test nginx configuration
        run: |
          docker run --rm -v $(pwd)/config/nginx:/etc/nginx:ro \
            nginx:alpine nginx -t
            
      - name: Test environment template
        run: |
          cp .env.example .env
          # Validate required variables exist
          grep -q "POSTGRES_PASSWORD" .env
          grep -q "KEYCLOAK_ADMIN_PASSWORD" .env

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run security scan
        uses: securecodewarrior/github-action-add-sarif@v1
        with:
          sarif-file: 'security-scan-results.sarif'

  build-keycloak:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: contains(github.event.head_commit.message, '[build keycloak]') || github.event_name == 'release'
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
          
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
        
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.KEYCLOAK_IMAGE }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=raw,value=latest,enable={{is_default_branch}}
            
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./keycloak
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: [build-keycloak, build-sendgrid]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
      - name: Deploy to staging
        run: |
          # Deploy to staging server
          ssh ${{ secrets.STAGING_HOST }} "cd /opt/aeno-tech && ./manage.sh pull all && ./manage.sh restart"

  deploy-production:
    needs: [build-keycloak, build-sendgrid]
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    environment: production
    steps:
      - name: Deploy to production
        run: |
          # Deploy to production server
          ssh ${{ secrets.PRODUCTION_HOST }} "cd /opt/aeno-tech && ./manage.sh pull all && ./manage.sh restart"
```

### Multi-Stage Docker Builds

Optimize Docker builds dengan multi-stage:

```dockerfile
# Keycloak Dockerfile
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM quay.io/keycloak/keycloak:latest AS production
COPY --from=builder /app/target/*.jar /opt/keycloak/providers/
RUN /opt/keycloak/bin/kc.sh build
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]
```

---

## ⚡ Performance Optimization

### Container Resource Limits

Update `docker-compose.yml`:

```yaml
services:
  keycloak:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
    environment:
      - JAVA_OPTS=-Xms512m -Xmx1536m
      
  shared_postgres:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 256M
    command: >
      postgres
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c maintenance_work_mem=64MB
```

### Nginx Performance Tuning

```nginx
# config/nginx/nginx.conf
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    # Enable compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/javascript application/xml+rss 
               application/json;
    
    # Enable caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Connection pooling
    upstream keycloak {
        server keycloak:8443;
        keepalive 32;
    }
}
```

### Keycloak Performance

```bash
# Keycloak environment variables for performance
KEYCLOAK_OPTS="-Xms1024m -Xmx2048m"
KC_DB_POOL_INITIAL_SIZE=10
KC_DB_POOL_MAX_SIZE=25
KC_DB_POOL_MIN_SIZE=5
```

### Database Connection Pooling

```yaml
# docker-compose.yml
services:
  pgbouncer:
    image: pgbouncer/pgbouncer:latest
    environment:
      - DATABASES_HOST=shared_postgres
      - DATABASES_PORT=5432
      - DATABASES_USER=postgres
      - DATABASES_PASSWORD=${POSTGRES_PASSWORD}
      - POOL_MODE=transaction
      - DEFAULT_POOL_SIZE=25
      - MAX_CLIENT_CONN=100
    ports:
      - "6432:5432"
```

---

## 🔐 Security Hardening

### Container Security

```yaml
# docker-compose.yml security options
services:
  keycloak:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/cache
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
```

### Network Security

```yaml
# Create custom networks
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true

services:
  nginx:
    networks:
      - frontend
      - backend
      
  keycloak:
    networks:
      - backend
```

### Secrets Management

```bash
# Use Docker secrets instead of environment variables
echo "super_secret_password" | docker secret create postgres_password -
echo "admin_password" | docker secret create keycloak_admin_password -
```

```yaml
# docker-compose.yml
secrets:
  postgres_password:
    external: true
  keycloak_admin_password:
    external: true

services:
  shared_postgres:
    secrets:
      - postgres_password
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
```

### SSL Security

```nginx
# Strong SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Security headers
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

---

## 🔐 Custom Keycloak Setup

### Custom Themes

```bash
# Create custom theme structure
mkdir -p keycloak/themes/aeno-custom/{login,account,email}

# Copy base theme
cp -r keycloak/themes/base/login/* keycloak/themes/aeno-custom/login/

# Customize login page
cat > keycloak/themes/aeno-custom/login/theme.properties << EOF
parent=base
import=common/keycloak

styles=css/login.css css/custom.css

# Custom properties
kcLogoIdP-aeno=Aeno SSO
kcFormCardClass=card-pf form-horizontal
EOF
```

### Custom Providers

```java
// keycloak/src/main/java/CustomAuthenticator.java
public class CustomAuthenticator implements Authenticator {
    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Custom authentication logic
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        String username = formData.getFirst("username");
        String password = formData.getFirst("password");
        
        // Validate against custom system
        if (validateCustomAuth(username, password)) {
            context.success();
        } else {
            context.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
        }
    }
}
```

### Keycloak Extensions

```xml
<!-- keycloak/pom.xml -->
<dependencies>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-core</artifactId>
        <version>${keycloak.version}</version>
    </dependency>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-server-spi</artifactId>
        <version>${keycloak.version}</version>
    </dependency>
</dependencies>
```

### Database Initialization

```sql
-- keycloak/init-custom.sql
-- Custom realm setup
INSERT INTO REALM (ID, NAME, ENABLED, SSL_REQUIRED) 
VALUES ('aeno-realm', 'aeno', true, 'EXTERNAL');

-- Custom client
INSERT INTO CLIENT (ID, CLIENT_ID, REALM_ID, ENABLED, PROTOCOL) 
VALUES ('aeno-client', 'aeno-app', 'aeno-realm', true, 'openid-connect');
```

---

## 📧 SendGrid Customization

### Custom API Endpoints

```javascript
// sendgrid-inbound/routes/custom.js
const express = require('express');
const router = express.Router();

// Custom webhook handler
router.post('/webhook/custom', async (req, res) => {
    try {
        const emailData = req.body;
        
        // Process custom email logic
        await processCustomEmail(emailData);
        
        res.status(200).json({ status: 'success' });
    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Custom email templates
router.get('/templates/:templateId', async (req, res) => {
    const template = await getCustomTemplate(req.params.templateId);
    res.json(template);
});

module.exports = router;
```

### Database Schema Extensions

```sql
-- sendgrid-inbound/database/extensions.sql
-- Custom tables for enhanced functionality
CREATE TABLE IF NOT EXISTS email_analytics (
    id SERIAL PRIMARY KEY,
    message_id VARCHAR(255) UNIQUE NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    recipient_email VARCHAR(255),
    custom_data JSONB
);

CREATE INDEX idx_email_analytics_message_id ON email_analytics(message_id);
CREATE INDEX idx_email_analytics_timestamp ON email_analytics(timestamp);

-- Email templates
CREATE TABLE IF NOT EXISTS custom_templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    html_content TEXT,
    plain_content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Custom Dashboard

```html
<!-- sendgrid-inbound/public/custom-dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Custom Email Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div id="analytics-chart">
        <canvas id="emailChart"></canvas>
    </div>
    
    <script>
    // Custom analytics visualization
    async function loadAnalytics() {
        const response = await fetch('/api/analytics');
        const data = await response.json();
        
        const ctx = document.getElementById('emailChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Emails Processed',
                    data: data.values,
                    borderColor: 'rgb(75, 192, 192)',
                    tension: 0.1
                }]
            }
        });
    }
    
    loadAnalytics();
    </script>
</body>
</html>
```

---

## 🌍 Multi-Environment Setup

### Environment-Specific Configurations

```bash
# environments/production/.env
POSTGRES_PASSWORD="production_secure_password"
KEYCLOAK_HOSTNAME=https://sso.aeno.tech
LETSENCRYPT_EMAIL=admin@aeno.tech
DEBUG=false

# environments/staging/.env
POSTGRES_PASSWORD="staging_password"
KEYCLOAK_HOSTNAME=https://sso-staging.aeno.tech
LETSENCRYPT_EMAIL=staging@aeno.tech
DEBUG=true

# environments/development/.env
POSTGRES_PASSWORD="dev_password"
KEYCLOAK_HOSTNAME=https://localhost:8443
DEBUG=true
DEV_MODE=true
```

### Environment Switching Script

```bash
#!/bin/bash
# scripts/switch-env.sh

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 [production|staging|development]"
    exit 1
fi

if [ ! -d "environments/$ENVIRONMENT" ]; then
    echo "Environment $ENVIRONMENT not found"
    exit 1
fi

# Backup current environment
if [ -f ".env" ]; then
    cp .env ".env.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Switch environment
cp "environments/$ENVIRONMENT/.env" .env
cp "environments/$ENVIRONMENT/docker-compose.override.yml" . 2>/dev/null || true

echo "Switched to $ENVIRONMENT environment"
echo "Run: ./manage.sh restart"
```

### Docker Compose Overrides

```yaml
# environments/production/docker-compose.override.yml
version: '3.8'

services:
  keycloak:
    deploy:
      resources:
        limits:
          memory: 2G
    environment:
      - KC_LOG_LEVEL=WARN
      
  nginx:
    deploy:
      replicas: 2
      
# environments/development/docker-compose.override.yml
services:
  keycloak:
    ports:
      - "8080:8080"  # Direct access for debugging
    environment:
      - KC_LOG_LEVEL=DEBUG
      - KC_DEV_MODE=true
```

---

## 💾 Backup & Recovery

### Automated Backup System

```bash
#!/bin/bash
# scripts/backup-system.sh

BACKUP_ROOT="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"

mkdir -p "$BACKUP_DIR"

# Database backup
./manage.sh db backup "$BACKUP_DIR/database"

# Configuration backup
tar -czf "$BACKUP_DIR/config.tar.gz" config/

# SSL certificates backup
tar -czf "$BACKUP_DIR/ssl.tar.gz" config/nginx/ssl/

# Docker images backup
docker save n4j1b/keycloak-custom:latest | gzip > "$BACKUP_DIR/keycloak-image.tar.gz"
docker save n4j1b/sendgrid-inbound:latest | gzip > "$BACKUP_DIR/sendgrid-image.tar.gz"

# Cleanup old backups (keep 30 days)
find "$BACKUP_ROOT" -type d -mtime +30 -exec rm -rf {} \;

echo "Backup completed: $BACKUP_DIR"
```

### Disaster Recovery

```bash
#!/bin/bash
# scripts/disaster-recovery.sh

BACKUP_DIR=$1
if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

# Stop services
./manage.sh stop

# Restore configuration
tar -xzf "$BACKUP_DIR/config.tar.gz"
tar -xzf "$BACKUP_DIR/ssl.tar.gz"

# Restore Docker images
docker load < "$BACKUP_DIR/keycloak-image.tar.gz"
docker load < "$BACKUP_DIR/sendgrid-image.tar.gz"

# Restore database
./manage.sh db restore "$BACKUP_DIR/database/all_databases.sql"

# Start services
./manage.sh start

echo "Recovery completed from: $BACKUP_DIR"
```

---

## 🔍 Advanced Troubleshooting

### Performance Monitoring

```bash
# Monitor container resources
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Monitor nginx access patterns
tail -f /var/log/nginx/access.log | awk '{print $1, $7, $9}' | sort | uniq -c | sort -nr

# Database performance monitoring
docker exec shared_postgres psql -U postgres -c "
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation 
FROM pg_stats 
WHERE tablename = 'your_table';"
```

### Log Analysis

```bash
# Centralized logging with ELK stack
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.0
    environment:
      - discovery.type=single-node
      
  logstash:
    image: docker.elastic.co/logstash/logstash:7.15.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      
  kibana:
    image: docker.elastic.co/kibana/kibana:7.15.0
    ports:
      - "5601:5601"
```

### Network Troubleshooting

```bash
# Test container networking
docker exec nginx_proxy ping keycloak
docker exec nginx_proxy nslookup keycloak
docker exec nginx_proxy netstat -tulnp

# Test SSL connectivity
openssl s_client -connect sso.aeno.tech:443 -servername sso.aeno.tech

# Test HTTP/2 support
curl -I --http2 https://sso.aeno.tech/

# Monitor network traffic
docker exec nginx_proxy tcpdump -i eth0 -n
```

### Database Troubleshooting

```sql
-- Check locks
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Check connection pools
SELECT 
    datname,
    numbackends,
    xact_commit,
    xact_rollback 
FROM pg_stat_database;
```

---

## 📊 Monitoring & Alerting

### Prometheus Monitoring

```yaml
# monitoring/docker-compose.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

### Health Check Endpoints

```javascript
// sendgrid-inbound/routes/health.js
router.get('/health', async (req, res) => {
    const health = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        checks: {
            database: await checkDatabase(),
            redis: await checkRedis(),
            external_api: await checkExternalAPI()
        }
    };
    
    const isHealthy = Object.values(health.checks).every(check => check.status === 'ok');
    res.status(isHealthy ? 200 : 503).json(health);
});
```

---

**🎉 Advanced configuration complete! Anda sekarang memiliki setup yang robust dan production-ready.**

Untuk kembali ke panduan utama, lihat [README.md](README.md).