#!/bin/bash

# 🚀 Aeno.tech Docker Stack Manager
# Unified script untuk manage seluruh deployment

set -e

# Configuration
DOMAIN="aeno.tech"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# GitHub Repositories
KEYCLOAK_REPO="https://github.com/N4J1B/keycloak.git"
SENDGRID_REPO="https://github.com/N4J1B/sendgrid-inbound.git"

# DockerHub Images
KEYCLOAK_IMAGE="n4j1b/keycloak-custom:latest"
SENDGRID_IMAGE="n4j1b/sendgrid-inbound:latest"

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji functions
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Banner
show_banner() {
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                   🚀 Aeno.tech Stack Manager                  ║"
    echo "║                                                               ║"
    echo "║  Keycloak (sso.aeno.tech) + SendGrid (mail.aeno.tech)        ║"
    echo "║  + PostgreSQL + Nginx Reverse Proxy                          ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

# Help function
show_help() {
    show_banner
    echo "Usage: $0 [CATEGORY] [COMMAND]"
    echo ""
    echo "📦 Setup & Build Commands:"
    echo "  clone keycloak      Clone Keycloak repository untuk kustomisasi"
    echo "  clone sendgrid      Clone SendGrid repository untuk kustomisasi"
    echo "  clone all           Clone semua repositories"
    echo "  build keycloak      Build Keycloak image dari source"
    echo "  build sendgrid      Build SendGrid image dari source"
    echo "  build all           Build semua images dari source"
    echo "  pull keycloak       Pull Keycloak image dari DockerHub"
    echo "  pull sendgrid       Pull SendGrid image dari DockerHub"
    echo "  pull all            Pull semua images dari DockerHub"
    echo ""
    echo "🚀 Deployment Commands:"
    echo "  start               Start semua services"
    echo "  stop                Stop semua services"
    echo "  restart             Restart semua services"
    echo "  status              Show status containers dan services"
    echo "  logs [service]      Show logs (optional: specific service)"
    echo ""
    echo "🗄️  Database Commands:"
    echo "  db init             Setup database SendGrid"
    echo "  db backup           Backup semua databases"
    echo "  db restore [file]   Restore database dari backup"
    echo "  db status           Check database connection"
    echo ""
    echo "🌐 Domain & SSL Commands:"
    echo "  domain check        Check DNS records dan connectivity"
    echo "  domain test         Test semua endpoints dan performance"
    echo "  ssl dev             Generate self-signed SSL (development)"
    echo "  ssl prod            Setup Let's Encrypt SSL (production)"
    echo "  ssl renew           Renew SSL certificates"
    echo ""
    echo "🔧 Maintenance Commands:"
    echo "  setup               Initial setup (copy env, generate SSL)"
    echo "  clean               Clean up unused images dan volumes"
    echo "  update              Update images dan restart services"
    echo "  config              Show current configuration"
    echo ""
    echo "🧪 Testing & Development Commands:"
    echo "  test-routing            Test domain routing configuration" 
    echo "  test-all               Run comprehensive deployment tests"
    echo "  quick-ref              Show quick reference card"
    echo "  dev-mode               Switch to development mode (HTTPS with self-signed certs)"
    echo "  prod-mode              Switch to production mode (HTTPS with Let's Encrypt)"
    echo "  nginx test             Test nginx configuration"
    echo "  nginx reload           Reload nginx configuration"
    echo ""
    echo "🔧 Debug & Maintenance Commands:"
    echo "  debug ssl               Debug SSL dan certificates"
    echo "  debug domain            Debug domain dan DNS"
    echo "  clean                   Clean Docker system"
    echo "  config                  Show current configuration"
    echo "  update                  Update semua services"
    echo ""
    echo "📋 Examples:"
    echo "  $0 setup            # Initial setup (interactive wizard)"
    echo "  $0 pull all         # Quick deploy dari DockerHub"
    echo "  $0 clone all        # Clone untuk kustomisasi" 
    echo "  $0 start            # Start all services"
    echo "  $0 test-all         # Run comprehensive tests"
    echo "  $0 quick-ref        # Show quick reference card"
    echo "  $0 ssl prod         # Setup production SSL"
    echo "  $0 domain check     # Check DNS"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    local missing=false
    
    command -v docker >/dev/null 2>&1 || { error "Docker tidak ditemukan"; missing=true; }
    
    # Check Docker Compose (v2 preferred, fallback to v1)
    if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
        error "Docker Compose tidak ditemukan"
        missing=true
    fi
    
    if [ "$missing" = true ]; then
        error "Prerequisites tidak terpenuhi. Install Docker dan Docker Compose terlebih dahulu."
        exit 1
    fi
}

# Check environment file
check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        error "File $ENV_FILE tidak ditemukan!"
        info "Copy config/env.example ke .env dan isi konfigurasi yang diperlukan:"
        echo "   cp config/env.example .env"
        echo "   nano .env"
        exit 1
    fi
    
    # Check required variables
    source "$ENV_FILE"
    local missing_vars=()
    
    [ -z "$POSTGRES_DB" ] && missing_vars+=("POSTGRES_DB")
    [ -z "$POSTGRES_USER" ] && missing_vars+=("POSTGRES_USER") 
    [ -z "$POSTGRES_PASSWORD" ] && missing_vars+=("POSTGRES_PASSWORD")
    [ -z "$KEYCLOAK_HOSTNAME" ] && missing_vars+=("KEYCLOAK_HOSTNAME")
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error "Environment variables berikut belum di-set:"
        printf '  - %s\n' "${missing_vars[@]}"
        exit 1
    fi
}

# ===============================
# CLONE COMMANDS
# ===============================

clone_keycloak() {
    info "Cloning Keycloak repository untuk kustomisasi..."
    
    if [ -d "keycloak/.git" ]; then
        warning "Keycloak repository sudah ada. Update repository..."
        cd keycloak
        git pull origin main || git pull origin master
        cd ..
        success "Keycloak repository updated"
    else
        if [ -d "keycloak" ]; then
            warning "Folder keycloak sudah ada tapi bukan git repository. Backup dan clone ulang..."
            mv keycloak "keycloak_backup_$(date +%Y%m%d_%H%M%S)"
        fi
        
        git clone "$KEYCLOAK_REPO" keycloak
        success "Keycloak repository berhasil di-clone"
        info "📝 Sekarang Anda bisa melakukan kustomisasi di folder keycloak/"
        info "Setelah selesai kustomisasi, jalankan: $0 build keycloak"
    fi
}

clone_sendgrid() {
    info "Cloning SendGrid repository untuk kustomisasi..."
    
    if [ -d "sendgrid-inbound/.git" ]; then
        warning "SendGrid repository sudah ada. Update repository..."
        cd sendgrid-inbound
        git pull origin main || git pull origin master
        cd ..
        success "SendGrid repository updated"
    else
        if [ -d "sendgrid-inbound" ]; then
            warning "Folder sendgrid-inbound sudah ada tapi bukan git repository. Backup dan clone ulang..."
            mv sendgrid-inbound "sendgrid-inbound_backup_$(date +%Y%m%d_%H%M%S)"
        fi
        
        git clone "$SENDGRID_REPO" sendgrid-inbound
        success "SendGrid repository berhasil di-clone"
        info "📝 Sekarang Anda bisa melakukan kustomisasi di folder sendgrid-inbound/"
        info "Setelah selesai kustomisasi, jalankan: $0 build sendgrid"
    fi
}

clone_all() {
    info "Cloning semua repositories untuk kustomisasi..."
    clone_keycloak
    echo ""
    clone_sendgrid
    echo ""
    success "Semua repositories berhasil di-clone"
    info "📝 Next steps:"
    echo "  1. Lakukan kustomisasi di folder keycloak/ atau sendgrid-inbound/"
    echo "  2. Build images: $0 build all"
    echo "  3. Start services: $0 start"
}

# ===============================
# PULL COMMANDS (Quick Deploy)
# ===============================

pull_keycloak() {
    info "Pulling Keycloak image dari DockerHub..."
    docker pull "$KEYCLOAK_IMAGE"
    
    # Tag as local image name for docker-compose compatibility
    docker tag "$KEYCLOAK_IMAGE" mykeycloak:latest
    
    success "Keycloak image berhasil di-pull dari DockerHub"
    info "Image siap digunakan untuk deployment cepat"
}

pull_sendgrid() {
    info "Pulling SendGrid image dari DockerHub..."
    docker pull "$SENDGRID_IMAGE"
    
    # Tag as local image name for docker-compose compatibility
    docker tag "$SENDGRID_IMAGE" sendgrid-inbound:latest
    
    success "SendGrid image berhasil di-pull dari DockerHub"
    info "Image siap digunakan untuk deployment cepat"
}

pull_all() {
    info "Pulling semua images dari DockerHub untuk quick deploy..."
    pull_keycloak
    echo ""
    pull_sendgrid
    echo ""
    success "Semua images berhasil di-pull"
    info "🚀 Quick Deploy ready! Jalankan: $0 start"
}

# ===============================
# BUILD COMMANDS
# ===============================

build_keycloak() {
    info "Building Keycloak image dari source..."
    
    if [ ! -d "keycloak" ]; then
        error "Folder keycloak tidak ditemukan!"
        info "Clone repository terlebih dahulu: $0 clone keycloak"
        info "Atau gunakan image dari DockerHub: $0 pull keycloak"
        exit 1
    fi
    
    if [ -f "keycloak/Dockerfile" ]; then
        cd keycloak
        docker build -t mykeycloak:latest .
        cd ..
        success "Keycloak image berhasil di-build dari source"
    else
        error "Dockerfile tidak ditemukan di folder keycloak/"
        exit 1
    fi
}

build_sendgrid() {
    info "Building SendGrid image dari source..."
    
    if [ ! -d "sendgrid-inbound" ]; then
        error "Folder sendgrid-inbound tidak ditemukan!"
        info "Clone repository terlebih dahulu: $0 clone sendgrid"
        info "Atau gunakan image dari DockerHub: $0 pull sendgrid"
        exit 1
    fi
    
    if [ -f "sendgrid-inbound/Dockerfile" ]; then
        cd sendgrid-inbound
        docker build -t sendgrid-inbound:latest .
        cd ..
        success "SendGrid image berhasil di-build dari source"
    else
        error "Dockerfile tidak ditemukan di folder sendgrid-inbound/"
        exit 1
    fi
}

build_all() {
    info "Building semua images dari source..."
    
    local has_error=false
    
    if [ -d "keycloak" ]; then
        build_keycloak || has_error=true
    else
        warning "Folder keycloak tidak ada, skip building Keycloak"
        info "Gunakan: $0 clone keycloak atau $0 pull keycloak"
    fi
    
    echo ""
    
    if [ -d "sendgrid-inbound" ]; then
        build_sendgrid || has_error=true
    else
        warning "Folder sendgrid-inbound tidak ada, skip building SendGrid"
        info "Gunakan: $0 clone sendgrid atau $0 pull sendgrid"
    fi
    
    if [ "$has_error" = false ]; then
        success "Semua images berhasil di-build"
    else
        warning "Beberapa images gagal di-build. Periksa error di atas."
    fi
}

# ===============================
# DEPLOYMENT COMMANDS
# ===============================

start_services() {
    check_env
    info "Starting services..."
    docker compose -f "$COMPOSE_FILE" up -d
    success "Services berhasil dijalankan"
    echo ""
    show_status
}

stop_services() {
    info "Stopping services..."
    docker compose -f "$COMPOSE_FILE" down
    success "Services berhasil dihentikan"
}

restart_services() {
    info "Restarting services..."
    docker compose -f "$COMPOSE_FILE" restart
    success "Services berhasil di-restart"
}

show_status() {
    echo "📊 Container Status:"
    echo "==================="
    docker compose -f "$COMPOSE_FILE" ps
    echo ""
    
    echo "🗄️  Database Status:"
    echo "===================="
    if docker exec shared_postgres pg_isready -U postgres >/dev/null 2>&1; then
        success "PostgreSQL: Ready"
    else
        error "PostgreSQL: Not ready"
    fi
    echo ""
    
    echo "🌐 Service URLs:"
    echo "================"
    echo "  Keycloak: https://sso.aeno.tech"
    echo "  SendGrid: https://mail.aeno.tech"
    echo "  Nginx: http://localhost (direct access)"
    echo ""
}

show_logs() {
    local service=$1
    if [ -n "$service" ]; then
        info "Menampilkan logs untuk service: $service"
        docker compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        info "Menampilkan logs semua services..."
        docker compose -f "$COMPOSE_FILE" logs -f
    fi
}

# ===============================
# DATABASE COMMANDS
# ===============================

init_database() {
    info "Setting up SendGrid database..."
    if [ -f "config/init-sendgrid-db.sql" ]; then
        docker exec -i shared_postgres psql -U postgres -d postgres < config/init-sendgrid-db.sql
        success "SendGrid database berhasil di-setup"
    else
        error "File config/init-sendgrid-db.sql tidak ditemukan"
        exit 1
    fi
}

backup_database() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    info "Creating database backup..."
    
    # Backup all databases
    docker exec shared_postgres pg_dumpall -U postgres > "$backup_dir/all_databases.sql"
    
    # Backup individual databases
    docker exec shared_postgres pg_dump -U postgres keycloak_db > "$backup_dir/keycloak.sql"
    docker exec shared_postgres pg_dump -U postgres sendgrid_emails > "$backup_dir/sendgrid.sql"
    
    success "Backup created in: $backup_dir"
}

restore_database() {
    local backup_file=$1
    if [ -z "$backup_file" ]; then
        error "Backup file tidak dispesifikasi"
        echo "Usage: $0 db restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file tidak ditemukan: $backup_file"
        exit 1
    fi
    
    warning "Restoring database akan menghapus data yang ada!"
    read -p "Lanjutkan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker exec -i shared_postgres psql -U postgres < "$backup_file"
        success "Database berhasil di-restore"
    else
        info "Restore dibatalkan"
    fi
}

check_database() {
    info "Checking database status..."
    
    if docker exec shared_postgres pg_isready -U postgres >/dev/null 2>&1; then
        success "PostgreSQL: Connected"
        
        # Show database info
        echo ""
        echo "Database Information:"
        docker exec shared_postgres psql -U postgres -c "\l" | grep -E "(keycloak|sendgrid)"
    else
        error "PostgreSQL: Connection failed"
    fi
}

# ===============================
# DOMAIN & SSL COMMANDS
# ===============================

check_domain() {
    info "Checking DNS records dan connectivity..."
    
    local server_ip
    server_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "Unknown")
    info "Server IP: $server_ip"
    echo ""
    
    local subdomains=("sso" "mail")
    for subdomain in "${subdomains[@]}"; do
        local full_domain="${subdomain}.${DOMAIN}"
        echo "🔍 Checking $full_domain:"
        
        # DNS resolution
        if ip=$(dig +short A "$full_domain" 2>/dev/null); then
            if [ -n "$ip" ]; then
                success "  DNS: $ip"
                
                # Compare with server IP
                if [ "$ip" = "$server_ip" ]; then
                    success "  DNS points to this server ✓"
                else
                    warning "  DNS points to different IP: $ip"
                fi
            else
                error "  DNS: No IP found"
            fi
        else
            error "  DNS: Resolution failed"
        fi
        echo ""
    done
}

test_domain() {
    info "Testing domain endpoints dan performance..."
    
    local services=(
        "sso:Keycloak:8443"
        "mail:SendGrid:3000"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r subdomain service_name port <<< "$service_info"
        local full_domain="${subdomain}.${DOMAIN}"
        
        echo "🧪 Testing $service_name ($full_domain):"
        
        # Test HTTP
        if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "http://$full_domain/" 2>/dev/null); then
            if [ "$response" -eq 200 ] || [[ "$response" =~ ^30[0-9]$ ]]; then
                success "  HTTP: $response"
            else
                warning "  HTTP: $response"
            fi
        else
            error "  HTTP: Failed"
        fi
        
        # Test HTTPS
        if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k "https://$full_domain/" 2>/dev/null); then
            if [ "$response" -eq 200 ] || [[ "$response" =~ ^30[0-9]$ ]]; then
                success "  HTTPS: $response"
            else
                warning "  HTTPS: $response"
            fi
        else
            error "  HTTPS: Failed"
        fi
        
        # Performance test
        if time_total=$(curl -s -o /dev/null -w "%{time_total}" --connect-timeout 10 "http://$full_domain/" 2>/dev/null); then
            success "  Response time: ${time_total}s"
        fi
        
        echo ""
    done
}

setup_dev_ssl() {
    info "Generating self-signed SSL certificates for development..."
    
    mkdir -p config/nginx/ssl/dev
    
    local domains=("sso.${DOMAIN}" "mail.${DOMAIN}" "default")
    
    for domain in "${domains[@]}"; do
        info "Generating certificate for $domain..."
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "config/nginx/ssl/dev/${domain}.key" \
            -out "config/nginx/ssl/dev/${domain}.crt" \
            -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Aeno Tech/OU=Development/CN=${domain}" \
            2>/dev/null
    done
    
    # Create symlinks to current certificates location
    cd config/nginx/ssl
    for cert in dev/*.crt dev/*.key; do
        filename=$(basename "$cert")
        ln -sf "$cert" "$filename" 2>/dev/null || true
    done
    cd ../../..
    
    success "Development SSL certificates generated and linked"
}

setup_prod_ssl() {
    info "Setting up Let's Encrypt SSL certificates for production..."
    
    # Create certbot directories
    mkdir -p config/nginx/certbot/{www,conf}
    mkdir -p config/nginx/ssl/prod
    
    # Switch to HTTP-only nginx temporarily
    if docker ps -q -f name=nginx_proxy >/dev/null; then
        docker compose -f "$COMPOSE_FILE" stop nginx
    fi
    
    # Start nginx dengan HTTP config untuk challenge
    docker compose -f "$COMPOSE_FILE" up -d nginx
    
    local subdomains=("sso" "mail")
    local email="${LETSENCRYPT_EMAIL:-admin@${DOMAIN}}"
    
    for subdomain in "${subdomains[@]}"; do
        local full_domain="${subdomain}.${DOMAIN}"
        info "Getting certificate for $full_domain..."
        
        docker run --rm --name certbot \
            -v "$(pwd)/config/nginx/certbot/conf:/etc/letsencrypt" \
            -v "$(pwd)/config/nginx/certbot/www:/var/www/certbot" \
            certbot/certbot \
            certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email "$email" \
            --agree-tos \
            --no-eff-email \
            -d "$full_domain" \
            --non-interactive || warning "Failed to get certificate for $full_domain"
        
        # Copy certificates to prod folder
        if [ -f "config/nginx/certbot/conf/live/$full_domain/fullchain.pem" ]; then
            cp "config/nginx/certbot/conf/live/$full_domain/fullchain.pem" "config/nginx/ssl/prod/$full_domain.crt"
            cp "config/nginx/certbot/conf/live/$full_domain/privkey.pem" "config/nginx/ssl/prod/$full_domain.key"
            success "Certificate obtained for $full_domain"
        fi
    done
    
    # Link production certificates
    switch_to_prod_mode
    success "Production SSL setup completed"
}

renew_ssl() {
    info "Renewing SSL certificates..."
    
    docker run --rm --name certbot \
        -v "$(pwd)/config/nginx/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/config/nginx/certbot/www:/var/www/certbot" \
        certbot/certbot renew --quiet
    
    # Copy renewed certificates
    for domain in "sso.${DOMAIN}" "mail.${DOMAIN}"; do
        if [ -f "config/nginx/certbot/conf/live/$domain/fullchain.pem" ]; then
            cp "config/nginx/certbot/conf/live/$domain/fullchain.pem" "config/nginx/ssl/$domain.crt"
            cp "config/nginx/certbot/conf/live/$domain/privkey.pem" "config/nginx/ssl/$domain.key"
        fi
    done
    
    # Reload nginx
    docker compose -f "$COMPOSE_FILE" exec nginx nginx -s reload
    success "SSL certificates renewed"
}

switch_to_prod_nginx() {
    info "Switching to production nginx configuration..."
    
    # Update docker-compose to use production config
    sed -i 's|nginx-dev.conf|nginx.conf|g' "$COMPOSE_FILE"
    
    # Restart nginx
    docker compose -f "$COMPOSE_FILE" restart nginx
    success "Switched to production configuration"
}

# ===============================
# MAINTENANCE COMMANDS  
# ===============================

initial_setup() {
    info "Running initial setup..."
    
    # Copy environment file
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "./env.example" ]; then
            cp ./env.example "$ENV_FILE"
            warning "Environment file copied. Please edit $ENV_FILE dengan konfigurasi Anda!"
            info "Edit dengan: nano $ENV_FILE"
        else
            error "File env.example tidak ditemukan"
            exit 1
        fi
    else
        info "Environment file sudah ada"
    fi
    
    # Generate development SSL
    setup_dev_ssl
    
    # Ask user for deployment method
    echo ""
    echo "🎯 Pilih metode deployment:"
    echo "  1) Quick Deploy - Pull images dari DockerHub (recommended untuk production)"
    echo "  2) Custom Build - Clone repositories untuk kustomisasi"
    echo "  3) Skip - Saya akan setup images secara manual"
    echo ""
    read -p "Pilihan (1/2/3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            info "Quick Deploy dipilih..."
            pull_all
            ;;
        2)
            info "Custom Build dipilih..."
            clone_all
            echo ""
            info "Repositories telah di-clone. Lakukan kustomisasi jika diperlukan."
            read -p "Build images sekarang? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                build_all
            else
                info "Skip building. Build nanti dengan: $0 build all"
            fi
            ;;
        3)
            info "Skip image setup. Setup manual images dengan:"
            echo "  - Quick: $0 pull all"
            echo "  - Custom: $0 clone all && $0 build all"
            ;;
        *)
            warning "Pilihan tidak valid. Skip image setup."
            ;;
    esac
    
    success "Initial setup completed!"
    echo ""
    info "📋 Next steps:"
    echo "  1. Edit $ENV_FILE dengan konfigurasi Anda"
    echo "  2. Jalankan: $0 start"
    echo "  3. Setup DNS records (lihat docs/README.md)"
    echo "  4. Setup production SSL: $0 ssl prod"
}

clean_system() {
    warning "Cleaning up unused Docker images dan volumes..."
    
    read -p "Lanjutkan cleanup? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -f
        docker volume prune -f
        success "Cleanup completed"
    else
        info "Cleanup dibatalkan"
    fi
}

update_stack() {
    info "Updating stack..."
    
    # Pull latest base images
    docker compose -f "$COMPOSE_FILE" pull
    
    # Rebuild custom images
    build_all
    
    # Restart services
    restart_services
    
    success "Stack updated"
}

show_config() {
    info "Current Configuration:"
    echo "====================="
    
    if [ -f "$ENV_FILE" ]; then
        echo "Environment Variables:"
        grep -E "^[A-Z_]+=" "$ENV_FILE" | sed 's/=.*/=***/' || echo "  (no variables found)"
        echo ""
    fi
    
    echo "Docker Compose File: $COMPOSE_FILE"
    echo "Domain: $DOMAIN"
    echo ""
    
    if docker ps -q -f name=nginx_proxy >/dev/null; then
        echo "Nginx Configuration:"
        docker exec nginx_proxy nginx -T 2>/dev/null | grep -E "server_name|listen" | head -10
    fi
}

# ===============================
# NGINX & ROUTING COMMANDS
# ===============================

test_nginx_config() {
    info "Testing nginx configuration..."
    
    if docker ps -q -f name=nginx_proxy >/dev/null; then
        if docker exec nginx_proxy nginx -t >/dev/null 2>&1; then
            success "Nginx configuration is valid"
        else
            error "Nginx configuration has errors:"
            docker exec nginx_proxy nginx -t
            return 1
        fi
    else
        error "Nginx container not running"
        return 1
    fi
}

reload_nginx() {
    info "Reloading nginx configuration..."
    
    if test_nginx_config; then
        docker exec nginx_proxy nginx -s reload
        success "Nginx reloaded successfully"
    else
        error "Cannot reload - configuration has errors"
        return 1
    fi
}

test_routing() {
    info "Testing domain routing configuration..."
    
    # Check if containers are running
    if ! docker ps -q -f name=nginx_proxy >/dev/null; then
        error "Nginx container not running. Start services first: $0 start"
        return 1
    fi
    
    echo ""
    echo "🧪 Testing HTTPS routing:"
    echo "========================="
    
    # Test sso.aeno.tech
    echo "Testing sso.aeno.tech..."
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k -H "Host: sso.aeno.tech" "https://localhost/" 2>/dev/null); then
        if [ "$response" -eq 200 ] || [[ "$response" =~ ^30[0-9]$ ]]; then
            success "  ✓ sso.aeno.tech responds with HTTPS $response"
        else
            warning "  ⚠ sso.aeno.tech responds with HTTPS $response"
        fi
    else
        error "  ✗ sso.aeno.tech failed to respond"
    fi
    
    # Test mail.aeno.tech
    echo "Testing mail.aeno.tech..."
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -k -H "Host: mail.aeno.tech" "https://localhost/" 2>/dev/null); then
        if [ "$response" -eq 200 ] || [[ "$response" =~ ^30[0-9]$ ]]; then
            success "  ✓ mail.aeno.tech responds with HTTPS $response"
        else
            warning "  ⚠ mail.aeno.tech responds with HTTPS $response"
        fi
    else
        error "  ✗ mail.aeno.tech failed to respond"
    fi
    
    echo ""
    echo "🔍 Testing HTTP→HTTPS redirect:"
    echo "==============================="
    
    # Test HTTP redirect for sso.aeno.tech
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -H "Host: sso.aeno.tech" "http://localhost/" 2>/dev/null); then
        if [ "$response" -eq 301 ]; then
            success "  ✓ sso.aeno.tech HTTP redirects to HTTPS (301)"
        else
            warning "  ⚠ sso.aeno.tech HTTP responds with $response (expected 301)"
        fi
    else
        error "  ✗ sso.aeno.tech HTTP failed"
    fi
    
    # Test HTTP redirect for mail.aeno.tech
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -H "Host: mail.aeno.tech" "http://localhost/" 2>/dev/null); then
        if [ "$response" -eq 301 ]; then
            success "  ✓ mail.aeno.tech HTTP redirects to HTTPS (301)"
        else
            warning "  ⚠ mail.aeno.tech HTTP responds with $response (expected 301)"
        fi
    else
        error "  ✗ mail.aeno.tech HTTP failed"
    fi
    
    echo ""
    echo "🔍 Testing backend connectivity:"
    echo "==============================="
    
    # Test Keycloak backend directly
    if docker exec nginx_proxy curl -k -s --max-time 10 "https://keycloak:8443/" >/dev/null 2>&1; then
        success "  ✓ Keycloak backend (keycloak:8443) reachable"
    else
        error "  ✗ Keycloak backend (keycloak:8443) unreachable"
    fi
    
    # Test SendGrid backend directly
    if docker exec nginx_proxy curl -s --max-time 10 "http://sendgrid-app:3000/" >/dev/null 2>&1; then
        success "  ✓ SendGrid backend (sendgrid-app:3000) reachable"
    else
        error "  ✗ SendGrid backend (sendgrid-app:3000) unreachable"
    fi
    
    echo ""
    echo "📋 SSL Certificate info:"
    echo "========================"
    for domain in "sso.aeno.tech" "mail.aeno.tech"; do
        if [ -f "config/nginx/ssl/$domain.crt" ]; then
            local issuer=$(openssl x509 -in "config/nginx/ssl/$domain.crt" -text -noout | grep "Issuer:" | sed 's/.*CN=//' | cut -d',' -f1)
            local expiry=$(openssl x509 -in "config/nginx/ssl/$domain.crt" -enddate -noout | cut -d= -f2)
            echo "  $domain:"
            echo "    Issuer: $issuer"
            echo "    Expires: $expiry"
        fi
    done
    
    echo ""
    info "💡 To test with proper domains, add these to your /etc/hosts:"
    echo "  127.0.0.1 sso.aeno.tech"
    echo "  127.0.0.1 mail.aeno.tech"
    echo ""
    info "🌐 Then access:"
    echo "  https://sso.aeno.tech   (Keycloak)"
    echo "  https://mail.aeno.tech  (SendGrid)"
}

switch_to_dev_mode() {
    info "Switching to development mode (HTTPS with self-signed certificates)..."
    
    # Generate development SSL certificates
    setup_dev_ssl
    
    # Link development certificates
    cd config/nginx/ssl
    for domain in "sso.${DOMAIN}" "mail.${DOMAIN}" "default"; do
        if [ -f "dev/${domain}.crt" ]; then
            ln -sf "dev/${domain}.crt" "${domain}.crt"
            ln -sf "dev/${domain}.key" "${domain}.key"
        fi
    done
    cd ../../..
    
    # Restart nginx if running
    if docker ps -q -f name=nginx_proxy >/dev/null; then
        docker compose -f "$COMPOSE_FILE" restart nginx
        success "Nginx restarted with development certificates"
    fi
    
    echo ""
    success "Development mode activated!"
    echo ""
    info "🌐 Available endpoints (HTTPS with self-signed certificates):"
    echo "  https://sso.aeno.tech   → Keycloak"
    echo "  https://mail.aeno.tech  → SendGrid"
    echo ""
    info "💡 Add to /etc/hosts for local testing:"
    echo "  127.0.0.1 sso.aeno.tech mail.aeno.tech"
    echo ""
    info "🔒 Browser akan menampilkan warning untuk self-signed certificates - itu normal untuk development"
    warning "🔒 Browser will show certificate warnings for self-signed certificates"
    info "For development, you can safely ignore these warnings or click 'Advanced' → 'Proceed'"
}

switch_to_prod_mode() {
    info "Switching to production mode (HTTPS with Let's Encrypt certificates)..."
    
    # Check if production SSL certificates exist
    if [ ! -f "config/nginx/ssl/prod/sso.aeno.tech.crt" ] || [ ! -f "config/nginx/ssl/prod/mail.aeno.tech.crt" ]; then
        warning "Production SSL certificates not found. Setting up..."
        setup_prod_ssl
        return
    fi
    
    # Link production certificates
    cd config/nginx/ssl
    for domain in "sso.${DOMAIN}" "mail.${DOMAIN}" "default"; do
        if [ -f "prod/${domain}.crt" ]; then
            ln -sf "prod/${domain}.crt" "${domain}.crt"
            ln -sf "prod/${domain}.key" "${domain}.key"
        fi
    done
    cd ../../..
    
    # Restart nginx if running
    if docker ps -q -f name=nginx_proxy >/dev/null; then
        docker compose -f "$COMPOSE_FILE" restart nginx
        success "Nginx restarted with production certificates"
    fi
    
    echo ""
    success "Production mode activated!"
    echo ""
    info "🌐 Available endpoints (HTTPS with Let's Encrypt certificates):"
    echo "  https://sso.aeno.tech   → Keycloak"
    echo "  https://mail.aeno.tech  → SendGrid"
    echo ""
    info "🔒 SSL certificates will be automatically renewed"
}

# ===============================
# TESTING & UTILITIES COMMANDS
# ===============================

run_comprehensive_tests() {
    info "Running comprehensive deployment tests..."
    echo ""
    
    local has_error=false
    
    # Test 1: Docker
    info "Test 1: Checking Docker..."
    if command -v docker >/dev/null 2>&1; then
        success "Docker installed: $(docker --version | head -1)"
    else
        error "Docker not installed"
        has_error=true
    fi
    
    # Test 2: Docker Compose
    info "Test 2: Checking Docker Compose..."
    if docker compose version >/dev/null 2>&1; then
        success "Docker Compose v2 installed"
    elif command -v docker-compose >/dev/null 2>&1; then
        success "Docker Compose v1 installed"
    else
        error "Docker Compose not installed"
        has_error=true
    fi
    
    # Test 3: Environment file
    echo ""
    info "Test 3: Checking environment file..."
    if [ -f "$ENV_FILE" ]; then
        success ".env file exists"
        
        # Check required variables
        source "$ENV_FILE"
        local missing=()
        [ -z "$POSTGRES_PASSWORD" ] && missing+=("POSTGRES_PASSWORD")
        [ -z "$KEYCLOAK_ADMIN_PASSWORD" ] && missing+=("KEYCLOAK_ADMIN_PASSWORD")
        [ -z "$SENDGRID_WEB_PASSWORD" ] && missing+=("SENDGRID_WEB_PASSWORD")
        
        if [ ${#missing[@]} -eq 0 ]; then
            success "All required environment variables set"
        else
            warning "Missing environment variables: ${missing[*]}"
        fi
    else
        warning ".env file not found - run: $0 setup"
    fi
    
    # Test 4: Docker images
    echo ""
    info "Test 4: Checking Docker images..."
    if docker images -q mykeycloak:latest >/dev/null 2>&1 && [ -n "$(docker images -q mykeycloak:latest)" ]; then
        success "Keycloak image exists"
    else
        warning "Keycloak image not found - run: $0 pull keycloak or $0 build keycloak"
    fi
    
    if docker images -q sendgrid-inbound:latest >/dev/null 2>&1 && [ -n "$(docker images -q sendgrid-inbound:latest)" ]; then
        success "SendGrid image exists"
    else
        warning "SendGrid image not found - run: $0 pull sendgrid or $0 build sendgrid"
    fi
    
    # Test 5: Running containers
    echo ""
    info "Test 5: Checking running containers..."
    if docker ps -q -f name=keycloak >/dev/null 2>&1 && [ -n "$(docker ps -q -f name=keycloak_app)" ]; then
        success "Keycloak container running"
    else
        warning "Keycloak container not running"
    fi
    
    if docker ps -q -f name=sendgrid-app >/dev/null 2>&1 && [ -n "$(docker ps -q -f name=sendgrid_app)" ]; then
        success "SendGrid container running"
    else
        warning "SendGrid container not running"
    fi
    
    if docker ps -q -f name=nginx_proxy >/dev/null 2>&1 && [ -n "$(docker ps -q -f name=nginx_proxy)" ]; then
        success "Nginx container running"
    else
        warning "Nginx container not running"
    fi
    
    if docker ps -q -f name=shared_postgres >/dev/null 2>&1 && [ -n "$(docker ps -q -f name=shared_postgres)" ]; then
        success "PostgreSQL container running"
    else
        warning "PostgreSQL container not running"
    fi
    
    # Test 6: SSL Certificates
    echo ""
    info "Test 6: Checking SSL certificates..."
    if [ -f "config/nginx/ssl/sso.aeno.tech.crt" ]; then
        local expiry=$(openssl x509 -in config/nginx/ssl/sso.aeno.tech.crt -enddate -noout 2>/dev/null | cut -d= -f2)
        success "sso.aeno.tech certificate exists (expires: $expiry)"
    else
        warning "sso.aeno.tech certificate not found"
    fi
    
    if [ -f "config/nginx/ssl/mail.aeno.tech.crt" ]; then
        local expiry=$(openssl x509 -in config/nginx/ssl/mail.aeno.tech.crt -enddate -noout 2>/dev/null | cut -d= -f2)
        success "mail.aeno.tech certificate exists (expires: $expiry)"
    else
        warning "mail.aeno.tech certificate not found"
    fi
    
    # Summary
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                    📊 Test Summary                       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ "$has_error" = true ]; then
        error "Some critical components missing"
    else
        success "All tests completed"
    fi
    
    info "💡 Next steps:"
    echo "  - Check status: $0 status"
    echo "  - View logs: $0 logs"
    echo "  - Test routing: $0 test-routing"
    echo "  - Quick reference: $0 quick-ref"
}

show_quick_reference() {
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║            🚀 Aeno.tech Stack - Quick Reference Card            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📦 SETUP & BUILD"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Production (Quick):"
    echo "    $0 pull all          Pull pre-built images from DockerHub"
    echo ""
    echo "  Development (Custom):"
    echo "    $0 clone all         Clone source from GitHub"
    echo "    $0 build all         Build custom images"
    echo ""
    echo "  Interactive:"
    echo "    $0 setup             Setup wizard (recommended)"
    echo ""
    echo "🚀 DEPLOYMENT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  $0 start               Start all services"
    echo "  $0 stop                Stop all services"
    echo "  $0 restart             Restart all services"
    echo "  $0 status              Show container status"
    echo "  $0 logs [service]      View logs (all or specific)"
    echo ""
    echo "🧪 TESTING"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  $0 test-all            Comprehensive deployment tests"
    echo "  $0 test-routing        Test domain routing"
    echo "  $0 nginx test          Test nginx configuration"
    echo ""
    echo "🔒 SSL & DOMAIN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  $0 dev-mode            Development (self-signed SSL)"
    echo "  $0 prod-mode           Production (Let's Encrypt)"
    echo "  $0 ssl prod            Get Let's Encrypt certificates"
    echo "  $0 domain check        Check DNS configuration"
    echo ""
    echo "💡 COMMON WORKFLOWS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  First Deploy (Production):"
    echo "    $0 setup             # Choose option 1: Quick Deploy"
    echo "    nano .env            # Configure environment"
    echo "    $0 start             # Start services"
    echo "    $0 ssl prod          # Setup production SSL"
    echo ""
    echo "  First Deploy (Development):"
    echo "    $0 clone all         # Clone repositories"
    echo "    $0 build all         # Build images"
    echo "    $0 dev-mode          # Setup dev SSL"
    echo "    $0 start             # Start services"
    echo ""
    echo "🌐 SERVICE URLS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Keycloak:     https://sso.aeno.tech"
    echo "  SendGrid:     https://mail.aeno.tech"
    echo ""
    echo "🆘 HELP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  $0 help                Show all commands"
    echo "  $0 quick-ref           Show this reference card"
    echo "  $0 status              Check status"
    echo "  $0 logs                View logs"
}

# ===============================
# DEVELOPMENT COMMANDS
# ===============================

dev_start() {
    info "Starting development environment..."
    
    # Ensure development SSL exists
    setup_dev_ssl
    
    # Use development nginx config
    sed -i 's|nginx.conf|nginx-dev.conf|g' "$COMPOSE_FILE"
    
    # Start services
    start_services
    
    info "Development environment ready!"
    echo ""
    info "Test URLs (add to /etc/hosts if needed):"
    echo "  http://sso.aeno.tech"
    echo "  http://mail.aeno.tech"
}

dev_stop() {
    info "Stopping development environment..."
    stop_services
}

dev_reset() {
    warning "Resetting development environment akan menghapus semua data!"
    read -p "Lanjutkan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker compose -f "$COMPOSE_FILE" down -v
        docker volume prune -f
        success "Development environment reset"
        info "Jalankan '$0 dev start' untuk memulai ulai"
    else
        info "Reset dibatalkan"
    fi
}

# ===============================
# MAIN SCRIPT LOGIC
# ===============================

main() {
    # Check prerequisites
    check_prerequisites
    
    # Parse arguments
    local category=$1
    local command=$2
    
    case "$category" in
        "clone")
            case "$command" in
                "keycloak") clone_keycloak ;;
                "sendgrid") clone_sendgrid ;;
                "all") clone_all ;;
                *) error "Unknown clone command. Use: keycloak, sendgrid, all" ;;
            esac
            ;;
        "pull")
            case "$command" in
                "keycloak") pull_keycloak ;;
                "sendgrid") pull_sendgrid ;;
                "all") pull_all ;;
                *) error "Unknown pull command. Use: keycloak, sendgrid, all" ;;
            esac
            ;;
        "build")
            case "$command" in
                "keycloak") build_keycloak ;;
                "sendgrid") build_sendgrid ;;
                "all") build_all ;;
                *) error "Unknown build command. Use: keycloak, sendgrid, all" ;;
            esac
            ;;
        "start")
            start_services
            ;;
        "stop") 
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$command"
            ;;
        "db")
            case "$command" in
                "init") init_database ;;
                "backup") backup_database ;;
                "restore") restore_database "$3" ;;
                "status") check_database ;;
                *) error "Unknown db command. Use: init, backup, restore, status" ;;
            esac
            ;;
        "domain")
            case "$command" in
                "check") check_domain ;;
                "test") test_domain ;;
                *) error "Unknown domain command. Use: check, test" ;;
            esac
            ;;
        "ssl")
            case "$command" in
                "dev") setup_dev_ssl ;;
                "prod") setup_prod_ssl ;;
                "renew") renew_ssl ;;
                *) error "Unknown ssl command. Use: dev, prod, renew" ;;
            esac
            ;;
        "setup")
            initial_setup
            ;;
        "clean")
            clean_system
            ;;
        "update")
            update_stack
            ;;
        "config")
            show_config
            ;;
        "nginx")
            case "$command" in
                "test") test_nginx_config ;;
                "reload") reload_nginx ;;
                *) error "Unknown nginx command. Use: test, reload" ;;
            esac
            ;;
        "test-routing")
            test_routing
            ;;
        "test-all")
            run_comprehensive_tests
            ;;
        "quick-ref")
            show_quick_reference
            ;;
        "dev-mode")
            switch_to_dev_mode
            ;;
        "prod-mode") 
            switch_to_prod_mode
            ;;
        "dev")
            case "$command" in
                "start") dev_start ;;
                "stop") dev_stop ;;
                "reset") dev_reset ;;
                *) error "Unknown dev command. Use: start, stop, reset" ;;
            esac
            ;;
        "help"|""|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"