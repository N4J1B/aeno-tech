# 🚀 Aeno.tech Stack# 🚀 Aeno.tech Stack



Complete Docker deployment untuk **Keycloak** (sso.aeno.tech) + **SendGrid** (mail.aeno.tech) dengan Nginx reverse proxy dan PostgreSQL database.Complete Docker deployment untuk **Keycloak** (sso.aeno.tech) + **SendGrid** (mail.aeno.tech) dengan Nginx reverse proxy.



---## 🎯 Quick Start



## 📋 Table of Contents### Option 1: Quick Deploy (Recommended untuk Production)

```bash

1. [Quick Start](#-quick-start)# 1. Initial setup dengan wizard

2. [Deployment Methods](#-deployment-methods)./manage.sh setup

3. [Commands Reference](#-commands-reference)# Pilih option 1: Quick Deploy

4. [Configuration](#-configuration)

5. [SSL Setup](#-ssl-setup)# 2. Edit konfigurasi  

6. [DNS Setup](#-dns-setup)nano .env

7. [Testing](#-testing)

8. [Troubleshooting](#-troubleshooting)# 3. Start services

9. [Advanced Topics](#-advanced-topics)./manage.sh start

```

---

### Option 2: Custom Build (Untuk Kustomisasi)

## 🚀 Quick Start```bash

# 1. Clone repositories

### Option 1: Production Deploy (Recommended - 5 minutes)./manage.sh clone all

```bash

# 1. Setup dengan wizard# 2. Lakukan kustomisasi (optional)

./manage.sh setupcd keycloak/        # Edit Keycloak themes/configs

# Pilih: 1) Quick Deploycd sendgrid-inbound/  # Edit SendGrid logic/UI



# 2. Edit konfigurasi# 3. Build images

nano .env./manage.sh build all



# 3. Start services# 4. Start services

./manage.sh start./manage.sh start

```

# 4. Setup production SSL

./manage.sh ssl prod## 📦 Deployment Methods

```

Pilih metode deployment sesuai kebutuhan Anda:

### Option 2: Development with Customization

```bash| Method | Use Case | Commands |

# 1. Clone repositories|--------|----------|----------|

./manage.sh clone all| **Quick Deploy** | Production, Quick testing | `./manage.sh pull all` |

| **Custom Build** | Development, Customization | `./manage.sh clone all && ./manage.sh build all` |

# 2. (Optional) Customize

cd keycloak/         # Edit themes, configs📖 **Detail lengkap**: [docs/DEPLOYMENT_METHODS.md](docs/DEPLOYMENT_METHODS.md)

cd sendgrid-inbound/ # Edit server logic, UI

## 📖 Commands

# 3. Build and start

./manage.sh build all### Setup & Build

./manage.sh dev-mode```bash

./manage.sh start./manage.sh clone all         # Clone repositories untuk kustomisasi

```./manage.sh pull all          # Pull images dari DockerHub (quick)

./manage.sh build all         # Build images dari source

### Option 3: One-liner Demo```

```bash

./manage.sh pull all && ./manage.sh start### Deployment

``````bash

./manage.sh start             # Start all services

---./manage.sh stop              # Stop all services

./manage.sh restart           # Restart all services

## 📦 Deployment Methods./manage.sh status            # Check status

./manage.sh logs [service]    # View logs

Choose the method that fits your needs:```



| Method | Use Case | Time | Customizable | Commands |### Domain & SSL

|--------|----------|------|--------------|----------|```bash

| **Quick Deploy** | Production, Testing | 5 min | ❌ No | `./manage.sh pull all` |./manage.sh domain check      # Check DNS records

| **Custom Build** | Development, Custom features | 15-30 min | ✅ Yes | `./manage.sh clone all && ./manage.sh build all` |./manage.sh domain test       # Test endpoints

./manage.sh ssl dev           # Generate self-signed SSL (dev)

### Quick Deploy (Production Ready)./manage.sh ssl prod          # Setup Let's Encrypt SSL (prod)

- ✅ **Fastest** - Pre-built tested images from DockerHub./manage.sh ssl renew         # Renew SSL certificates

- ✅ **Reliable** - No build dependencies or compilation errors```

- ✅ **Minimal resources** - Just pull and run

- ❌ **No customization** - Uses default configurations### Development

```bash

```bash./manage.sh dev-mode          # Switch to development mode

# Pull images and start./manage.sh prod-mode         # Switch to production mode

./manage.sh pull all./manage.sh test-routing      # Test routing configuration

./manage.sh start./manage.sh nginx test        # Test nginx config

./manage.sh nginx reload      # Reload nginx

# Images used:```

# - n4j1b/keycloak-custom:latest

# - n4j1b/sendgrid-inbound:latest### Help

``````bash

./manage.sh help              # Show all available commands

### Custom Build (Full Control)```

- ✅ **Customizable** - Full access to source code

- ✅ **Development friendly** - Make changes and test locally## 🌐 URLs

- ✅ **Git workflow** - Version control for modifications

- ❌ **Longer setup** - Need to clone and build- **Keycloak**: https://sso.aeno.tech

- **SendGrid**: https://mail.aeno.tech

```bash

# Clone, customize, and build## 📚 Documentation

./manage.sh clone all

- 📖 [Complete Documentation](docs/README.md)

# Customize Keycloak (optional)- 🚀 [Deployment Methods](docs/DEPLOYMENT_METHODS.md)

cd keycloak/- 🔒 [SSL Configuration](docs/SSL_PRODUCTION_ISSUES.md)

nano themes/custom-theme/login.ftl- 🌐 [Domain & Routing](docs/ROUTING_ISSUE_RESOLUTION.md)

git commit -am "Custom theme"- 🏗️ [Nginx Structure](docs/NGINX_STRUCTURE.md)



# Customize SendGrid (optional)  ## 🗂️ Structure

cd ../sendgrid-inbound/

nano server-clean.js```

nano public/dashboard.htmlaeno-tech/

git commit -am "Custom UI"├── manage.sh              # 🎛️ Main management script (all-in-one)

├── docker-compose.yml     # 🐳 Docker configuration  

# Build and deploy├── .env.example          # 📝 Environment template

./manage.sh build all├── config/               # ⚙️ All configurations

./manage.sh start│   ├── nginx/           # 🌐 Nginx configs & SSL

```│   └── init-sendgrid-db.sql

├── docs/                # 📚 Documentation

---│   ├── DEPLOYMENT_METHODS.md

│   ├── SSL_PRODUCTION_ISSUES.md

## 📖 Commands Reference│   └── ROUTING_ISSUE_RESOLUTION.md

├── keycloak/            # 🔐 Keycloak source (clone)

### Setup & Build└── sendgrid-inbound/    # 📧 SendGrid source (clone)

```bash```

./manage.sh setup              # Interactive setup wizard

./manage.sh clone all          # Clone repositories for customization## ⚡ DNS Setup

./manage.sh pull all           # Pull pre-built images (quick)

./manage.sh build all          # Build from sourceAdd DNS A records pointing to your server IP:

``````

sso.aeno.tech  → YOUR_SERVER_IP

### Deploymentmail.aeno.tech → YOUR_SERVER_IP

```bash```

./manage.sh start              # Start all services

./manage.sh stop               # Stop all services  Verify DNS:

./manage.sh restart            # Restart all services```bash

./manage.sh status             # Check container status./manage.sh domain check

./manage.sh logs [service]     # View logs (all or specific)```
```

### Testing & Utilities
```bash
./manage.sh test-all           # Comprehensive deployment tests
./manage.sh test-routing       # Test domain routing
./manage.sh quick-ref          # Show quick reference card
./manage.sh nginx test         # Test nginx configuration
```

### SSL & Domain
```bash
./manage.sh dev-mode           # Development mode (self-signed SSL)
./manage.sh prod-mode          # Production mode (Let's Encrypt)
./manage.sh ssl dev            # Generate self-signed certificates
./manage.sh ssl prod           # Get Let's Encrypt certificates
./manage.sh ssl renew          # Renew SSL certificates
./manage.sh domain check       # Check DNS configuration
./manage.sh domain test        # Test all endpoints
```

### Database
```bash
./manage.sh db init            # Initialize SendGrid database
./manage.sh db backup          # Backup all databases
./manage.sh db restore [file]  # Restore from backup
./manage.sh db status          # Check database connection
```

### Maintenance
```bash
./manage.sh clean              # Clean unused images/volumes
./manage.sh update             # Update all services
./manage.sh config             # Show current configuration
./manage.sh help               # Show all commands
```

---

## ⚙️ Configuration

### Environment Variables (.env)

Copy and configure the environment file:
```bash
cp .env.example .env
nano .env
```

**Required Variables:**
```bash
# Database
POSTGRES_PASSWORD="your_secure_password"
KEYCLOAK_ADMIN_PASSWORD="your_admin_password"
SENDGRID_WEB_PASSWORD="your_web_password"

# Domain (for production)
KEYCLOAK_HOSTNAME=https://sso.aeno.tech
LETSENCRYPT_EMAIL=admin@aeno.tech
```

**Optional Variables:**
```bash
# Docker Images (for custom repositories)
KEYCLOAK_IMAGE="your-username/keycloak-custom:latest"
SENDGRID_IMAGE="your-username/sendgrid-inbound:latest"

# Development
DEV_MODE=false
DEBUG=false
```

### Service URLs
- **Keycloak Admin**: https://sso.aeno.tech/admin
- **SendGrid Dashboard**: https://mail.aeno.tech/dashboard.html
- **PostgreSQL**: localhost:5432 (external) or shared_postgres:5432 (internal)

### Default Credentials
| Service | Username | Password | Notes |
|---------|----------|----------|--------|
| Keycloak Admin | `admin` | `KEYCLOAK_ADMIN_PASSWORD` | Set in .env |
| SendGrid Web | `SENDGRID_WEB_USERNAME` | `SENDGRID_WEB_PASSWORD` | Set in .env |
| PostgreSQL | `postgres` | `POSTGRES_PASSWORD` | Set in .env |

---

## 🔒 SSL Setup

### Development (Self-signed)
For local development and testing:
```bash
# Generate and use self-signed certificates
./manage.sh dev-mode

# Access with SSL warnings (safe to ignore for dev)
# https://sso.aeno.tech
# https://mail.aeno.tech
```

### Production (Let's Encrypt)
For production with valid SSL certificates:
```bash
# Prerequisites: DNS must point to your server
./manage.sh domain check

# Get Let's Encrypt certificates
./manage.sh ssl prod

# Switch to production mode
./manage.sh prod-mode

# Auto-renewal (add to crontab)
./manage.sh ssl renew
```

### Certificate Management
```bash
# Check certificate status
openssl x509 -in config/nginx/ssl/sso.aeno.tech.crt -text -noout

# Certificate locations
config/nginx/ssl/
├── dev/                    # Self-signed certificates
├── prod/                   # Let's Encrypt certificates
├── sso.aeno.tech.crt      # Current certificate (symlink)
└── sso.aeno.tech.key      # Current private key (symlink)
```

---

## 🌐 DNS Setup

### DNS Records Required
Point these domains to your server IP:
```
sso.aeno.tech  → YOUR_SERVER_IP
mail.aeno.tech → YOUR_SERVER_IP
```

### Verification
```bash
# Check DNS resolution
./manage.sh domain check

# Test endpoints
./manage.sh domain test

# Manual check
dig +short A sso.aeno.tech
dig +short A mail.aeno.tech
```

### Local Testing (Development)
Add to `/etc/hosts` for local testing:
```
127.0.0.1 sso.aeno.tech mail.aeno.tech
```

---

## 🧪 Testing

### Comprehensive Tests
```bash
# Run all tests
./manage.sh test-all
```

Tests include:
- Docker installation and version
- Docker Compose availability
- Environment file validation
- Docker images presence
- Running containers status
- SSL certificates validity
- Network connectivity
- Database connectivity
- HTTP/HTTPS endpoint responses

### Specific Tests
```bash
# Test routing configuration
./manage.sh test-routing

# Test nginx configuration
./manage.sh nginx test

# Check service status
./manage.sh status

# View logs
./manage.sh logs                # All services
./manage.sh logs keycloak       # Keycloak only
./manage.sh logs sendgrid-app   # SendGrid only
./manage.sh logs nginx          # Nginx only
```

### Manual Testing
```bash
# Test Keycloak
curl -k https://sso.aeno.tech/

# Test SendGrid
curl -k https://mail.aeno.tech/

# Test with proper domain headers
curl -k -H "Host: sso.aeno.tech" https://localhost/
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Docker image not found"
```bash
# Quick fix: Pull from DockerHub
./manage.sh pull all

# Or build from source
./manage.sh clone all
./manage.sh build all
```

#### 2. "Port already in use"
```bash
# Check what's using ports
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
```

#### 3. "SSL certificate error"
```bash
# Regenerate dev certificates
./manage.sh dev-mode

# Or setup production
./manage.sh ssl prod
```

#### 4. "Database connection failed"
```bash
# Check database status
./manage.sh db status

# Restart database
docker compose restart shared_postgres

# Initialize SendGrid database
./manage.sh db init
```

#### 5. "502 Bad Gateway"
```bash
# Check backend connectivity
./manage.sh test-routing

# Check nginx configuration
./manage.sh nginx test

# View error logs
./manage.sh logs nginx

# Restart services
./manage.sh restart
```

### Diagnostic Commands
```bash
# Complete system check
./manage.sh test-all

# Check individual components
./manage.sh status               # Containers
./manage.sh domain check         # DNS
./manage.sh nginx test          # Nginx config
./manage.sh db status           # Database
./manage.sh test-routing        # Routing

# View configurations
./manage.sh config              # Current config
docker compose config           # Docker compose config
./manage.sh quick-ref          # Command reference
```

### Log Analysis
```bash
# View all logs
./manage.sh logs

# Follow logs in real-time
./manage.sh logs | grep ERROR

# Service-specific logs
./manage.sh logs keycloak | tail -50
./manage.sh logs sendgrid-app | grep -i error
./manage.sh logs nginx | grep -E "(error|404|502)"
```

---

## 🏗️ Advanced Topics

For advanced configuration, troubleshooting, and customization, see [ADVANCED.md](ADVANCED.md).

Topics covered in advanced guide:
- Custom nginx configurations
- Database tuning and migration
- GitHub Actions CI/CD setup
- Performance optimization
- Security hardening
- Backup and restore strategies
- Multi-environment deployment
- Custom Keycloak themes and providers
- SendGrid customization and API integration

---

## 📁 Project Structure

```
aeno-tech/
├── manage.sh              # 🎛️ All-in-one management script
├── docker-compose.yml     # 🐳 Docker services definition
├── .env.example          # 📝 Environment template
├── README.md             # 📖 Complete user guide (this file)
├── ADVANCED.md           # 🔧 Advanced configuration & troubleshooting
├── config/               # ⚙️ All configurations
│   ├── nginx/           # 🌐 Nginx configs & SSL certificates
│   │   ├── nginx.conf   # Main nginx configuration
│   │   └── ssl/         # SSL certificates storage
│   └── init-sendgrid-db.sql  # SendGrid database schema
├── .github/              # 🤖 GitHub Actions workflows (optional)
│   └── workflows/
│       └── docker-build.yml
├── keycloak/             # 🔐 Keycloak source (created after: ./manage.sh clone keycloak)
└── sendgrid-inbound/     # 📧 SendGrid source (created after: ./manage.sh clone sendgrid)
```

---

## 🎯 Common Workflows

### First Time Production Deployment
```bash
git clone <your-repo>
cd aeno-tech
./manage.sh setup          # Choose Quick Deploy
nano .env                  # Configure environment
./manage.sh start          # Start services
./manage.sh domain check   # Verify DNS
./manage.sh ssl prod       # Setup SSL
./manage.sh test-all       # Verify deployment
```

### Development Environment
```bash
git clone <your-repo>
cd aeno-tech
./manage.sh clone all      # Get source code
./manage.sh build all      # Build custom images
./manage.sh dev-mode       # Setup dev SSL
./manage.sh start          # Start services
./manage.sh test-routing   # Test configuration
```

### Regular Maintenance
```bash
# Update production
./manage.sh pull all       # Get latest images
./manage.sh restart        # Restart with new images
./manage.sh db backup      # Backup data

# Update development
cd keycloak && git pull && cd ..
cd sendgrid-inbound && git pull && cd ..
./manage.sh build all      # Rebuild
./manage.sh restart        # Restart services
```

### Troubleshooting Workflow
```bash
./manage.sh test-all       # Comprehensive check
./manage.sh status         # Check containers
./manage.sh logs           # Check logs
./manage.sh nginx test     # Test nginx
./manage.sh test-routing   # Test routing
```

---

## 📞 Getting Help

### Built-in Help
```bash
./manage.sh help           # All commands
./manage.sh quick-ref      # Quick reference card
./manage.sh test-all       # System diagnostics
```

### Documentation
- **README.md** (this file) - Complete user guide
- **ADVANCED.md** - Advanced configuration and troubleshooting
- Comments in `manage.sh` - Code documentation
- Comments in `docker-compose.yml` - Service documentation

### Community & Support
- Check logs: `./manage.sh logs`
- Run diagnostics: `./manage.sh test-all`
- Test configuration: `./manage.sh test-routing`

---

## 🚀 Quick Commands Summary

```bash
# Setup
./manage.sh setup              # Interactive wizard

# Deploy (choose one)
./manage.sh pull all           # Quick: Pull pre-built images
./manage.sh clone all          # Custom: Clone source code
./manage.sh build all          # Custom: Build images

# Manage
./manage.sh start              # Start services
./manage.sh status             # Check status
./manage.sh logs               # View logs

# Test
./manage.sh test-all           # Comprehensive tests
./manage.sh quick-ref          # Command reference

# SSL
./manage.sh dev-mode           # Development SSL
./manage.sh ssl prod           # Production SSL

# Help
./manage.sh help               # All commands
```

---

**🎉 You're all set! Choose your deployment method and get started in minutes!**