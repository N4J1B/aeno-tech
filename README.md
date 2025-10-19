# 🚀 Aeno.tech Stack
Complete Docker deployment untuk **Keycloak** (sso.aeno.tech) + **SendGrid** (mail.aeno.tech) dengan Nginx reverse proxy dan PostgreSQL database.

---

# 📋 Table of Content

1. [Quick Start](#-quick-start)

2. [Deployment Methods](#-deployment-methods)

3. [Commands Reference](#-commands-reference)

4. [Configuration](#-configuration)

5. [SSL Setup](#-ssl-setup) 

6. [DNS Setup](#-dns-setup)

7. [Testing](#-testing)

8. [Troubleshooting](#-troubleshooting)

9. [Advanced Topics](#-advanced-topics)
---

# 🚀 Quick Start

## 🌐 **Any Domain Support** 
**This stack works with ANY domain you own!** `aeno.tech` is just an example.

### Step 0: Configure Your Domain (30 seconds)
```bash
# 1. Copy environment file
cp .env.example .env

# 2. Edit with your domain
nano .env

# Change these lines:
BASE_DOMAIN=yourdomain.com        # Your domain
ADMIN_EMAIL=admin@yourdomain.com  # Your email
```

**DNS Required:** Point these to your server IP:
- `sso.yourdomain.com` → `YOUR_SERVER_IP`  
- `mail.yourdomain.com` → `YOUR_SERVER_IP`

---

## Option 1: Production Deploy (Recommended - 5 minutes)

```bash
# 1. Setup dengan wizard (will configure domain automatically)
./manage.sh setup

# 2. Start services
./manage.sh start

# 4. Setup production SSL
./manage.sh ssl prod
```

## Option 2: Development with Customization

```bash
# 1. Clone repositories
./manage.sh clone all

# 2. (Optional) Customize
cd keycloak/         # Edit themes, configs
cd sendgrid-inbound/ # Edit server logic, UI

# 3. Build and start
./manage.sh build all
./manage.sh dev-mode
./manage.sh start
```

## Option 3: One-liner Demo

```bash
./manage.sh pull all && ./manage.sh start
```

---

## 📦 Deployment Methods

Pilih metode deployment sesuai kebutuhan Anda:

| Method | Use Case | Commands |
|--------|----------|----------|
| **Quick Deploy** | Production, Quick testing | `./manage.sh pull all` |
| **Custom Build** | Development, Customization | `./manage.sh clone all && ./manage.sh build all` |

📖 **Detail lengkap**: [docs/DEPLOYMENT_METHODS.md](docs/DEPLOYMENT_METHODS.md)

### Quick Deploy (Production Ready)
- ✅ **Fastest** - Pre-built tested images from DockerHub
- ✅ **Reliable** - No build dependencies or compilation errors
- ✅ **Minimal resources** - Just pull and run
- ❌ **No customization** - Uses default configurations

```bash
# Pull images and start
./manage.sh pull all
./manage.sh start

# Images used:
# - n4j1b/keycloak:latest
# - n4j1b/sendgrid-inbound:latest
```

### Custom Build (Full Control)
- ✅ **Customizable** - Full access to source code
- ✅ **Development friendly** - Make changes and test locally
- ✅ **Git workflow** - Version control for modifications
- ❌ **Longer setup** - Need to clone and build

```bash
# Clone, customize, and build
./manage.sh clone all

# Customize Keycloak (optional)
cd keycloak/
nano themes/custom-theme/login.ftl
git commit -am "Custom theme"

# Customize SendGrid (optional)
cd ../sendgrid-inbound/
nano server-clean.js
nano public/dashboard.html
git commit -am "Custom UI"

# Build and deploy
./manage.sh build all
./manage.sh start
```

---
```bash
./manage.sh domain check
```

---

## 📖 Commands Reference

### Setup & Build
```bash
./manage.sh setup              # Interactive setup wizard
./manage.sh clone all          # Clone repositories for customization
./manage.sh pull all           # Pull pre-built images (quick)
./manage.sh build all          # Build from source
```

### Deployment
```bash
./manage.sh start              # Start all services
./manage.sh stop               # Stop all services
./manage.sh restart            # Restart all services
./manage.sh status             # Check container status
./manage.sh logs [service]     # View logs (all or specific)
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
./manage.sh domain configure   # Configure domain from .env variables
./manage.sh domain check       # Check DNS records
./manage.sh domain test        # Test endpoints
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
# Domain Configuration (🌐 New: Dynamic Domain Support)
BASE_DOMAIN=yourdomain.com           # Your base domain
SSO_SUBDOMAIN=sso                    # SSO subdomain (optional, default: sso)
MAIL_SUBDOMAIN=mail                  # Mail subdomain (optional, default: mail)  
ADMIN_EMAIL=admin@yourdomain.com     # Admin email for SSL

# Database
POSTGRES_PASSWORD="your_secure_password"
KEYCLOAK_ADMIN_PASSWORD="your_admin_password"
SENDGRID_WEB_PASSWORD="your_web_password"

# Legacy (will be auto-configured from BASE_DOMAIN)
KEYCLOAK_HOSTNAME=https://sso.yourdomain.com
LETSENCRYPT_EMAIL=admin@yourdomain.com
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
Point these domains to your server IP (replace with your actual domain):
```
sso.yourdomain.com   → YOUR_SERVER_IP
mail.yourdomain.com  → YOUR_SERVER_IP
```

**Example for different domains:**
```bash
# For BASE_DOMAIN=example.com
sso.example.com   → YOUR_SERVER_IP  
mail.example.com  → YOUR_SERVER_IP

# For BASE_DOMAIN=mycompany.org  
sso.mycompany.org  → YOUR_SERVER_IP
mail.mycompany.org → YOUR_SERVER_IP
```

### Verification
```bash
# Check DNS resolution for your domain
./manage.sh domain check

# Test endpoints for your domain
./manage.sh domain test

# Manual check (replace with your domain)
dig +short A sso.yourdomain.com
dig +short A mail.yourdomain.com
```

### Local Testing (Development)
Add to `/etc/hosts` for local testing (replace with your domain):
```bash
# For your custom domain
127.0.0.1 sso.yourdomain.com mail.yourdomain.com

# Example for different domains
127.0.0.1 sso.example.com mail.example.com
127.0.0.1 sso.mycompany.org mail.mycompany.org
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

## 🔄 Migration from aeno.tech

If you have existing deployment with hardcoded `aeno.tech` domains:

### Easy Migration
```bash
# 1. Update your .env file
cp .env.example .env.new
nano .env.new  # Set your BASE_DOMAIN

# 2. Backup current config
cp .env .env.backup
cp config/nginx/nginx.conf config/nginx/nginx.conf.backup
cp docker-compose.yml docker-compose.yml.backup

# 3. Replace with new config
mv .env.new .env
./manage.sh domain configure

# 4. Update DNS and restart
./manage.sh restart
```

### Manual Migration
```bash
# Replace in all config files
sed -i 's/aeno\.tech/yourdomain.com/g' .env
sed -i 's/sso\.aeno\.tech/sso.yourdomain.com/g' config/nginx/nginx.conf
sed -i 's/mail\.aeno\.tech/mail.yourdomain.com/g' config/nginx/nginx.conf
sed -i 's/sso\.aeno\.tech/sso.yourdomain.com/g' docker-compose.yml
sed -i 's/mail\.aeno\.tech/mail.yourdomain.com/g' docker-compose.yml
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