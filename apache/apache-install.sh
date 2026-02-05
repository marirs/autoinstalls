#!/bin/bash

# Apache Web Server Installation Script
# Comprehensive installation with module support and security hardening
# Compatible with Ubuntu, Debian, CentOS, RHEL, and Fedora

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
APACHE_VERSION=""  # Will be set dynamically based on OS
INSTALL_DIR="/opt/apache"
CONFIG_DIR="/etc/apache2"
LOG_DIR="/var/log/apache2"
WEB_ROOT="/var/www/html"
BACKUP_DIR="/opt/apache/backups"
LOG_FILE="/tmp/apache-install.log"

# Module selections
PHP_ENABLED=false
SSL_ENABLED=false
REWRITE_ENABLED=false
CACHE_ENABLED=false
PROXY_ENABLED=false
SECURITY_ENABLED=false
GZIP_ENABLED=false
EXPIRES_ENABLED=false
HEADERS_ENABLED=false
STATUS_ENABLED=false
INFO_ENABLED=false
DEFLATE_ENABLED=false
MPM_EVENT=false
MPM_WORKER=false

# OS Detection
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [[ -f /etc/debian_version ]]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${CYAN}Detected OS: $OS $VER${NC}"
}

# Get latest Apache version
get_apache_version() {
    echo -e "${CYAN}Determining Apache version for $os $os_ver...${NC}"
    
    # Get version from OS mapping
    APACHE_VERSION=$(get_apache_version_mapping)
    
    echo -e "${GREEN}Using Apache version: $APACHE_VERSION${NC}"
}

# Apache version mapping based on OS and version
get_apache_version_mapping() {
    case "$os" in
        "ubuntu")
            case "$os_ver" in
                "18.04") echo "2.4.29" ;;   # Ubuntu 18.04 Bionic
                "20.04") echo "2.4.41" ;;   # Ubuntu 20.04 Focal
                "22.04") echo "2.4.52" ;;   # Ubuntu 22.04 Jammy
                "24.04") echo "2.4.58" ;;   # Ubuntu 24.04 Noble
                *) echo "2.4.62" ;;        # Default latest
            esac
            ;;
        "debian")
            case "$os_ver" in
                "9") echo "2.4.25" ;;      # Debian 9 Stretch
                "10") echo "2.4.38" ;;     # Debian 10 Buster
                "11") echo "2.4.56" ;;     # Debian 11 Bullseye
                "12") echo "2.4.62" ;;     # Debian 12 Bookworm
                "13") echo "2.4.62" ;;     # Debian 13 Trixie (testing)
                *) echo "2.4.62" ;;        # Default latest
            esac
            ;;
        "centos")
            case "$os_ver" in
                "7") echo "2.4.6" ;;       # CentOS 7
                "8") echo "2.4.37" ;;      # CentOS 8
                "9") echo "2.4.57" ;;      # CentOS 9 Stream
                *) echo "2.4.62" ;;        # Default latest
            esac
            ;;
        "rhel")
            case "$os_ver" in
                "7") echo "2.4.6" ;;       # RHEL 7
                "8") echo "2.4.37" ;;      # RHEL 8
                "9") echo "2.4.57" ;;      # RHEL 9
                *) echo "2.4.62" ;;        # Default latest
            esac
            ;;
        "fedora")
            case "$os_ver" in
                "38") echo "2.4.57" ;;     # Fedora 38
                "39") echo "2.4.58" ;;     # Fedora 39
                "40") echo "2.4.62" ;;     # Fedora 40
                *) echo "2.4.62" ;;        # Default latest
            esac
            ;;
        *)
            echo "2.4.62" ;;            # Default latest for unknown OS
    esac
}

# Check if user is root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# System information
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)
cores=$(nproc)
architecture=$(arch)

# Install dependencies
install_dependencies() {
    echo -e "${CYAN}Installing dependencies...${NC}"
    
    case "$OS" in
        "Ubuntu"* | "Debian"*)
            apt-get update
            apt-get install -y build-essential wget curl git \
                libpcre3-dev libssl-dev zlib1g-dev \
                libxml2-dev libexpat1-dev libapr1-dev \
                libaprutil1-dev liblua5.3-dev \
                systemd systemd-sysv
            ;;
        "CentOS"* | "RHEL"* | "Fedora"*)
            yum update -y
            yum groupinstall -y "Development Tools"
            yum install -y wget curl git \
                pcre-devel openssl-devel zlib-devel \
                libxml2-devel expat-devel apr-devel \
                apr-util-devel lua-devel \
                systemd systemd-sysv
            ;;
        *)
            echo -e "${RED}Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Download and compile Apache
install_apache_core() {
    echo -e "${CYAN}Installing Apache $APACHE_VERSION...${NC}"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd /tmp
    
    # Download Apache source
    if [[ ! -d "httpd-${APACHE_VERSION}" ]]; then
        wget "https://downloads.apache.org/httpd/httpd-${APACHE_VERSION}.tar.gz"
        tar -xzf "httpd-${APACHE_VERSION}.tar.gz"
    fi
    
    # Download APR and APR-util
    if [[ ! -d "apr-1.7.4" ]]; then
        wget "https://downloads.apache.org/apr/apr-1.7.4.tar.gz"
        tar -xzf "apr-1.7.4.tar.gz"
        mv apr-1.7.4 httpd-${APACHE_VERSION}/srclib/apr
    fi
    
    if [[ ! -d "apr-util-1.6.3" ]]; then
        wget "https://downloads.apache.org/apr/apr-util-1.6.3.tar.gz"
        tar -xzf "apr-util-1.6.3.tar.gz"
        mv apr-util-1.6.3 httpd-${APACHE_VERSION}/srclib/apr-util
    fi
    
    cd "httpd-${APACHE_VERSION}"
    
    # Configure build
    ./configure \
        --prefix="$INSTALL_DIR" \
        --sysconfdir="$CONFIG_DIR" \
        --enable-so \
        --enable-ssl \
        --enable-cgi \
        --enable-rewrite \
        --with-pcre \
        --with-ssl \
        --with-z \
        --enable-modules=most \
        --enable-mods-shared=reallyall \
        --enable-mpms-shared=all \
        --with-mpm=event \
        --enable-proxy \
        --enable-proxy-http \
        --enable-proxy-balancer \
        --enable-proxy-fcgi \
        --enable-cache \
        --enable-disk-cache \
        --enable-mem-cache \
        --enable-deflate \
        --enable-headers \
        --enable-expires \
        --enable-info \
        --enable-status \
        --enable-suexec \
        --with-suexec-caller=www-data \
        --with-suexec-docroot="$WEB_ROOT" \
        --with-suexec-userdir=public_html \
        --with-suexec-logfile="$LOG_DIR/suexec_log" \
        --with-suexec-uidmin=1000 \
        --with-suexec-gidmin=1000
    
    # Compile and install
    make -j$(nproc)
    make install
    
    echo -e "${GREEN}✓ Apache core installed${NC}"
}

# Create directories
create_directories() {
    echo -e "${CYAN}Creating directories...${NC}"
    
    mkdir -p "$CONFIG_DIR"/{sites-available,sites-enabled,mods-available,mods-enabled,conf-available,conf-enabled}
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$WEB_ROOT"
    mkdir -p /var/lock/apache2
    mkdir -p /var/run/apache2
    
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Create main configuration
create_main_config() {
    echo -e "${CYAN}Creating main configuration...${NC}"
    
    cat > "$CONFIG_DIR/apache2.conf" << 'EOF'
# Apache Configuration File
# Generated by AutoInstalls Apache Manager

# Server configuration
ServerRoot "/opt/apache"
PidFile "/var/run/apache2/apache2.pid"
Timeout 300
KeepAlive On
MaxKeepAliveRequests 500
KeepAliveTimeout 5

# MPM configuration
<IfModule mpm_event_module>
    ServerLimit 16
    StartServers 3
    MinSpareThreads 75
    MaxSpareThreads 250
    ThreadLimit 64
    ThreadsPerChild 25
    MaxRequestWorkers 400
    MaxConnectionsPerChild 10000
</IfModule>

# User and group
User www-data
Group www-data

# Server admin
ServerAdmin admin@localhost

# Server name
ServerName localhost

# Document root
DocumentRoot "/var/www/html"

# Directory configuration
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Require all denied
</Directory>

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Directory index
DirectoryIndex index.html index.htm index.php index.pl index.py

# Access log
ErrorLog "/var/log/apache2/error.log"
CustomLog "/var/log/apache2/access.log" combined

# Log level
LogLevel warn

# Include module configurations
IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf

# Default MIME types
TypesConfig /etc/mime.types
AddType application/x-compress .Z
AddType application/x-gzip .gz .tgz
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps

# Character encoding
AddDefaultCharset UTF-8

# Security settings
ServerTokens Prod
ServerSignature Off

# Performance settings
EnableSendfile On
EnableMMAP On
EOF
    
    echo -e "${GREEN}✓ Main configuration created${NC}"
}

# Create systemd service
create_systemd_service() {
    echo -e "${CYAN}Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/apache2.service << EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=$INSTALL_DIR/bin/apachectl start
ExecStop=$INSTALL_DIR/bin/apachectl graceful-stop
ExecReload=$INSTALL_DIR/bin/apachectl graceful
PrivateTmp=true
LimitNOFILE=infinity
LimitNPROC=infinity
LimitMEMLOCK=infinity
Restart=on-failure
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable apache2
    
    echo -e "${GREEN}✓ Systemd service created${NC}"
}

# Module configuration menu
configure_modules() {
    echo -e "${CYAN}Apache Modules Configuration${NC}"
    echo -e "${CYAN}===============================${NC}"
    echo ""
    
    echo "Select modules to enable:"
    echo "   1) PHP (mod_php)"
    echo "   2) SSL/TLS (mod_ssl)"
    echo "   3) Rewrite (mod_rewrite)"
    echo "   4) Cache (mod_cache)"
    echo "   5) Proxy (mod_proxy)"
    echo "   6) Security (mod_security)"
    echo "   7) Gzip (mod_deflate)"
    echo "   8) Expires (mod_expires)"
    echo "   9) Headers (mod_headers)"
    echo "   10) Status (mod_status)"
    echo "   11) Info (mod_info)"
    echo "   12) MPM Event (High-performance MPM)"
    echo "   13) MPM Worker (Hybrid MPM)"
    echo "   14) Install all recommended modules"
    echo "   15) Skip modules"
    echo ""
    read -p "Select an option [1-15]: " module_choice
    
    case "$module_choice" in
        1)
            PHP_ENABLED=true
            configure_php
            ;;
        2)
            SSL_ENABLED=true
            configure_ssl
            ;;
        3)
            REWRITE_ENABLED=true
            configure_rewrite
            ;;
        4)
            CACHE_ENABLED=true
            configure_cache
            ;;
        5)
            PROXY_ENABLED=true
            configure_proxy
            ;;
        6)
            SECURITY_ENABLED=true
            configure_security
            ;;
        7)
            GZIP_ENABLED=true
            configure_gzip
            ;;
        8)
            EXPIRES_ENABLED=true
            configure_expires
            ;;
        9)
            HEADERS_ENABLED=true
            configure_headers
            ;;
        10)
            STATUS_ENABLED=true
            configure_status
            ;;
        11)
            INFO_ENABLED=true
            configure_info
            ;;
        12)
            MPM_EVENT=true
            configure_mpm_event
            ;;
        13)
            MPM_WORKER=true
            configure_mpm_worker
            ;;
        14)
            install_all_modules
            ;;
        15)
            echo -e "${YELLOW}Skipping module installation${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            configure_modules
            ;;
    esac
}

# Install all recommended modules
install_all_modules() {
    echo -e "${CYAN}Installing all recommended modules...${NC}"
    
    PHP_ENABLED=true
    SSL_ENABLED=true
    REWRITE_ENABLED=true
    CACHE_ENABLED=true
    PROXY_ENABLED=true
    SECURITY_ENABLED=true
    GZIP_ENABLED=true
    EXPIRES_ENABLED=true
    HEADERS_ENABLED=true
    STATUS_ENABLED=true
    INFO_ENABLED=true
    MPM_EVENT=true
    
    configure_php
    configure_ssl
    configure_rewrite
    configure_cache
    configure_proxy
    configure_security
    configure_gzip
    configure_expires
    configure_headers
    configure_status
    configure_info
    configure_mpm_event
    
    echo -e "${GREEN}✓ All recommended modules installed${NC}"
}

# Configure PHP
configure_php() {
    echo -e "${CYAN}Configuring PHP module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/php.conf" << 'EOF'
# PHP Configuration
<FilesMatch \.php$>
    SetHandler application/x-httpd-php
</FilesMatch>

# PHP settings
php_flag display_errors Off
php_value max_execution_time 30
php_value memory_limit 128M
php_value upload_max_filesize 8M
php_value post_max_size 8M

# Directory index
DirectoryIndex index.php index.html
EOF
    
    # Enable module
    ln -sf "$CONFIG_DIR/mods-available/php.conf" "$CONFIG_DIR/mods-enabled/php.conf"
    echo -e "${GREEN}✓ PHP configured${NC}"
}

# Configure SSL
configure_ssl() {
    echo -e "${CYAN}Configuring SSL/TLS module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/ssl.conf" << 'EOF'
# SSL Configuration
<IfModule mod_ssl.c>
    # SSL global configuration
    SSLRandomSeed startup builtin
    SSLRandomSeed connect builtin
    
    # SSL protocol settings
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    SSLCompression off
    
    # SSL session cache
    SSLSessionCache shmcb:/var/run/apache2/ssl_scache(512000)
    SSLSessionCacheTimeout 300
    
    # SSL virtual host template
    <VirtualHost _default_:443>
        ServerName localhost
        DocumentRoot "/var/www/html"
        
        SSLEngine on
        SSLCertificateFile "/etc/letsencrypt/live/domain.com/fullchain.pem"
        SSLCertificateKeyFile "/etc/letsencrypt/live/domain.com/privkey.pem"
        SSLCertificateChainFile "/etc/letsencrypt/live/domain.com/chain.pem"
        
        # SSL security headers
        Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
        Header always set X-Frame-Options DENY
        Header always set X-Content-Type-Options nosniff
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
        
        # SSL logs
        ErrorLog "/var/log/apache2/ssl_error_log"
        TransferLog "/var/log/apache2/ssl_access_log"
        LogLevel warn
    </VirtualHost>
</IfModule>
EOF
    
    # Enable module
    ln -sf "$CONFIG_DIR/mods-available/ssl.conf" "$CONFIG_DIR/mods-enabled/ssl.conf"
    echo -e "${GREEN}✓ SSL configured${NC}"
}

# Configure Rewrite
configure_rewrite() {
    echo -e "${CYAN}Configuring Rewrite module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/rewrite.conf" << 'EOF'
# Rewrite Configuration
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Common rewrite rules
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php [QSA,L]
    
    # WordPress-like rules
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
    
    # Custom URL patterns
    RewriteRule ^about/?$ about.html [L]
    RewriteRule ^contact/?$ contact.html [L]
    RewriteRule ^products/([0-9]+)/?$ product.php?id=$1 [L]
    RewriteRule ^blog/([a-zA-Z0-9-]+)/?$ blog.php?slug=$1 [L]
</IfModule>
EOF
    
    # Enable module
    ln -sf "$CONFIG_DIR/mods-available/rewrite.conf" "$CONFIG_DIR/mods-enabled/rewrite.conf"
    echo -e "${GREEN}✓ Rewrite configured${NC}"
}

# Configure Cache
configure_cache() {
    echo -e "${CYAN}Configuring Cache module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/cache.conf" << 'EOF'
# Cache Configuration
<IfModule mod_cache.c>
    CacheQuickHandler off
    CacheLock on
    CacheLockPath "/var/cache/apache2/mod_cache-lock"
    CacheLockMaxAge 5
    
    # Cache disk storage
    CacheEnable disk /
    CacheRoot "/var/cache/apache2/mod_cache_disk"
    CacheDirLevels 2
    CacheDirLength 1
    
    # Cache settings
    CacheMaxFileSize 1000000
    CacheMinFileSize 1
    CacheIgnoreHeaders Set-Cookie
    CacheIgnoreNoLastMod On
    CacheDefaultExpire 3600
    CacheMaxExpire 86400
    
    # Cache specific file types
    <FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
        CacheEnable disk
        ExpiresActive on
        ExpiresDefault "access plus 1 year"
    </FilesMatch>
</IfModule>
EOF
    
    mkdir -p /var/cache/apache2/mod_cache-lock
    mkdir -p /var/cache/apache2/mod_cache_disk
    ln -sf "$CONFIG_DIR/mods-available/cache.conf" "$CONFIG_DIR/mods-enabled/cache.conf"
    echo -e "${GREEN}✓ Cache configured${NC}"
}

# Configure Proxy
configure_proxy() {
    echo -e "${CYAN}Configuring Proxy module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/proxy.conf" << 'EOF'
# Proxy Configuration
<IfModule mod_proxy.c>
    ProxyRequests Off
    ProxyPreserveHost On
    
    # Proxy to backend application
    ProxyPass /api/ http://127.0.0.1:8080/api/
    ProxyPassReverse /api/ http://127.0.0.1:8080/api/
    
    # Proxy to another application
    ProxyPass /app/ http://127.0.0.1:3000/
    ProxyPassReverse /app/ http://127.0.0.1:3000/
    
    # Load balancer configuration
    <Proxy "balancer://mycluster">
        BalancerMember http://127.0.0.1:8080
        BalancerMember http://127.0.0.1:8081
        ProxySet lbmethod=byrequests
    </Proxy>
    
    ProxyPass /balancer/ balancer://mycluster/
    ProxyPassReverse /balancer/ balancer://mycluster/
    
    # WebSocket proxy
    ProxyPass /ws/ ws://127.0.0.1:8080/ws/
    ProxyPassReverse /ws/ ws://127.0.0.1:8080/ws/
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/proxy.conf" "$CONFIG_DIR/mods-enabled/proxy.conf"
    echo -e "${GREEN}✓ Proxy configured${NC}"
}

# Configure Security
configure_security() {
    echo -e "${CYAN}Configuring Security module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/security.conf" << 'EOF'
# Security Configuration
<IfModule mod_security.c>
    SecRuleEngine On
    SecRequestBodyAccess On
    SecResponseBodyAccess On
    SecResponseBodyMimeType text/plain text/html text/xml application/xml
    
    # Basic security rules
    SecRule REQUEST_METHOD "!^(GET|HEAD|POST|PUT|DELETE|OPTIONS)$" \
        "id:1001,phase:1,deny,status:405"
    
    SecRule REQUEST_HEADERS:User-Agent "^(nmap|nikto|sqlmap|w3af|acunetix)$" \
        "id:1002,phase:1,deny,status:403"
    
    SecRule ARGS "@detectSQLi" \
        "id:1003,phase:2,block,msg:'SQL Injection Attack Detected',logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}'"
    
    SecRule ARGS "@detectXSS" \
        "id:1004,phase:2,block,msg:'XSS Attack Detected',logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}'"
    
    # File upload security
    SecRule FILES_TMPNAMES "@inspectFile /opt/apache/bin/modsec-clamscan" \
        "id:1005,phase:2,deny,status:403"
    
    # Request size limits
    SecRequestBodyNoFilesLimit 13107200
    SecRequestBodyLimit 13107200
    SecRequestBodyInMemoryLimit 131072
</IfModule>

# Additional security headers
<IfModule mod_headers.c>
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</IfModule>

# Hide server information
ServerTokens Prod
ServerSignature Off
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/security.conf" "$CONFIG_DIR/mods-enabled/security.conf"
    echo -e "${GREEN}✓ Security configured${NC}"
}

# Configure Gzip
configure_gzip() {
    echo -e "${CYAN}Configuring Gzip compression...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/gzip.conf" << 'EOF'
# Gzip Compression Configuration
<IfModule mod_deflate.c>
    # Enable compression
    SetOutputFilter DEFLATE
    
    # Compress specific file types
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE application/json
    
    # Compression level
    DeflateCompressionLevel 6
    
    # Exclude already compressed content
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
    
    # Browser compatibility
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    Header append Vary User-Agent env=!dont-vary
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/gzip.conf" "$CONFIG_DIR/mods-enabled/gzip.conf"
    echo -e "${GREEN}✓ Gzip configured${NC}"
}

# Configure Expires
configure_expires() {
    echo -e "${CYAN}Configuring Expires headers...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/expires.conf" << 'EOF'
# Expires Headers Configuration
<IfModule mod_expires.c>
    ExpiresActive On
    
    # Default expiration
    ExpiresDefault "access plus 1 month"
    
    # HTML documents
    ExpiresByType text/html "access plus 1 hour"
    
    # CSS and JavaScript
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType application/x-javascript "access plus 1 year"
    
    # Images
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType image/x-icon "access plus 1 year"
    
    # Fonts
    ExpiresByType font/woff "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType application/font-woff "access plus 1 year"
    ExpiresByType application/font-woff2 "access plus 1 year"
    
    # PDF and documents
    ExpiresByType application/pdf "access plus 1 month"
    ExpiresByType application/msword "access plus 1 month"
    
    # Flash
    ExpiresByType application/x-shockwave-flash "access plus 1 month"
    
    # RSS feeds
    ExpiresByType application/rss+xml "access plus 1 hour"
    ExpiresByType application/atom+xml "access plus 1 hour"
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/expires.conf" "$CONFIG_DIR/mods-enabled/expires.conf"
    echo -e "${GREEN}✓ Expires configured${NC}"
}

# Configure Headers
configure_headers() {
    echo -e "${CYAN}Configuring Headers module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/headers.conf" << 'EOF'
# Headers Configuration
<IfModule mod_headers.c>
    # Security headers
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Cache control headers
    Header set Cache-Control "public, max-age=31536000"
    <FilesMatch "\.(html|htm|php)$">
        Header set Cache-Control "no-cache, must-revalidate"
    </FilesMatch>
    
    # Remove server signature
    Header unset Server
    Header unset X-Powered-By
    
    # CORS headers
    Header set Access-Control-Allow-Origin "*"
    Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header set Access-Control-Allow-Headers "Content-Type, Authorization"
    
    # Content type protection
    Header set X-Content-Type-Options nosniff
    
    # Download headers
    <FilesMatch "\.(pdf|zip|doc|docx|xls|xlsx|ppt|pptx)$">
        Header set Content-Disposition attachment
    </FilesMatch>
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/headers.conf" "$CONFIG_DIR/mods-enabled/headers.conf"
    echo -e "${GREEN}✓ Headers configured${NC}"
}

# Configure Status
configure_status() {
    echo -e "${CYAN}Configuring Status module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/status.conf" << 'EOF'
# Status Configuration
<IfModule mod_status.c>
    ExtendedStatus On
    <Location "/server-status">
        SetHandler server-status
        Require local
    </Location>
    
    # Status page with detailed information
    <Location "/server-info">
        SetHandler server-info
        Require local
    </Location>
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/status.conf" "$CONFIG_DIR/mods-enabled/status.conf"
    echo -e "${GREEN}✓ Status configured${NC}"
}

# Configure Info
configure_info() {
    echo -e "${CYAN}Configuring Info module...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/info.conf" << 'EOF'
# Info Configuration
<IfModule mod_info.c>
    <Location "/server-info">
        SetHandler server-info
        Require local
    </Location>
    
    # Add server information
    AddModuleInfo mod_ssl.c "SSL/TLS Module for secure connections"
    AddModuleInfo mod_rewrite.c "URL rewriting engine"
    AddModuleInfo mod_cache.c "Caching module for performance"
    AddModuleInfo mod_proxy.c "Proxy module for reverse proxy"
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/info.conf" "$CONFIG_DIR/mods-enabled/info.conf"
    echo -e "${GREEN}✓ Info configured${NC}"
}

# Configure MPM Event
configure_mpm_event() {
    echo -e "${CYAN}Configuring MPM Event...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/mpm_event.conf" << 'EOF'
# MPM Event Configuration
<IfModule mpm_event_module>
    ServerLimit 16
    StartServers 3
    MinSpareThreads 75
    MaxSpareThreads 250
    ThreadLimit 64
    ThreadsPerChild 25
    MaxRequestWorkers 400
    MaxConnectionsPerChild 10000
    
    # Async request handling
    AsyncRequestWorkerFactor 2
    MaxMemFree 2048
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/mpm_event.conf" "$CONFIG_DIR/mods-enabled/mpm_event.conf"
    echo -e "${GREEN}✓ MPM Event configured${NC}"
}

# Configure MPM Worker
configure_mpm_worker() {
    echo -e "${CYAN}Configuring MPM Worker...${NC}"
    
    cat > "$CONFIG_DIR/mods-available/mpm_worker.conf" << 'EOF'
# MPM Worker Configuration
<IfModule mpm_worker_module>
    ServerLimit 16
    StartServers 2
    MinSpareThreads 25
    MaxSpareThreads 75
    ThreadLimit 64
    ThreadsPerChild 25
    MaxRequestWorkers 400
    MaxConnectionsPerChild 10000
    
    # Process management
    ThreadStackSize 65536
</IfModule>
EOF
    
    ln -sf "$CONFIG_DIR/mods-available/mpm_worker.conf" "$CONFIG_DIR/mods-enabled/mpm_worker.conf"
    echo -e "${GREEN}✓ MPM Worker configured${NC}"
}

# Create sample virtual host
create_sample_vhost() {
    echo -e "${CYAN}Creating sample virtual host...${NC}"
    
    cat > "$CONFIG_DIR/sites-available/000-default.conf" << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    ServerAdmin admin@localhost
    DocumentRoot "/var/www/html"
    
    ErrorLog "/var/log/apache2/error.log"
    CustomLog "/var/log/apache2/access.log" combined
    
    # Directory configuration
    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Security headers
    <IfModule mod_headers.c>
        Header always set X-Frame-Options DENY
        Header always set X-Content-Type-Options nosniff
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
    </IfModule>
</VirtualHost>
EOF
    
    # Enable default site
    ln -sf "$CONFIG_DIR/sites-available/000-default.conf" "$CONFIG_DIR/sites-enabled/000-default.conf"
    
    echo -e "${GREEN}✓ Sample virtual host created${NC}"
}

# Security hardening
security_hardening() {
    echo -e "${CYAN}Applying security hardening...${NC}"
    
    # Set proper permissions
    chown -R www-data:www-data "$WEB_ROOT"
    chown -R www-data:www-data "$LOG_DIR"
    chown -R root:root "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    chmod 644 "$CONFIG_DIR"/*.conf
    chmod 750 "$LOG_DIR"
    
    # Create security configuration
    cat > "$CONFIG_DIR/conf-available/security.conf" << 'EOF'
# Security Hardening Configuration

# Hide server version
ServerTokens Prod
ServerSignature Off

# Disable HTTP TRACE method
TraceEnable Off

# Disable HTTP OPTIONS method
<LimitExcept GET POST HEAD>
    Require all denied
</LimitExcept>

# Protect sensitive files
<FilesMatch "^\.">
    Require all denied
</FilesMatch>

<FilesMatch "^(config|configuration|settings|backup|backup\.sql|\.bak|\.old)$">
    Require all denied
</FilesMatch>

# Protect .htaccess and .htpasswd
<Files ~ "^\.ht">
    Require all denied
</Files>

# Limit request size
LimitRequestBody 10485760

# Timeout settings
Timeout 30
KeepAliveTimeout 5

# Disable server signature on error pages
ServerSignature Off

# Clickjacking protection
Header always set X-Frame-Options DENY

# MIME type sniffing protection
Header always set X-Content-Type-Options nosniff

# XSS protection
Header always set X-XSS-Protection "1; mode=block"

# Content Security Policy
Header always set Content-Security-Policy "default-src 'self'"

# Referrer policy
Header always set Referrer-Policy "strict-origin-when-cross-origin"
EOF
    
    ln -sf "$CONFIG_DIR/conf-available/security.conf" "$CONFIG_DIR/conf-enabled/security.conf"
    
    echo -e "${GREEN}✓ Security hardening applied${NC}"
}

# Create logrotate configuration
create_logrotate() {
    echo -e "${CYAN}Creating logrotate configuration...${NC}"
    
    cat > /etc/logrotate.d/apache2 << 'EOF'
/var/log/apache2/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    sharedscripts
    postrotate
        if /etc/init.d/apache2 status > /dev/null ; then \
            /opt/apache/bin/apachectl graceful > /dev/null; \
        fi;
    endscript
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi; \
    endscript
}
EOF
    
    echo -e "${GREEN}✓ Logrotate configuration created${NC}"
}

# Create management tools
create_management_tools() {
    echo -e "${CYAN}Creating management tools...${NC}"
    
    # Apache monitor
    cat > /usr/local/bin/apache-monitor << 'EOF'
#!/bin/bash
# Apache Monitoring Tool

echo "=================================="
echo "    Apache Server Status        "
echo "=================================="

# Check if Apache is running
if systemctl is-active --quiet apache2; then
    echo -e "Status: \e[32mRunning\e[0m"
else
    echo -e "Status: \e[31mStopped\e[0m"
fi

# Show version
if [ -f /opt/apache/bin/apachectl ]; then
    echo "Version: $(/opt/apache/bin/apachectl -v 2>&1 | head -n1)"
fi

# Show uptime
if [ -f /var/run/apache2/apache2.pid ]; then
    PID=$(cat /var/run/apache2/apache2.pid)
    if [ -n "$PID" ]; then
        echo "PID: $PID"
        echo "Uptime: $(ps -o etime= -p $PID | tr -d ' ')"
    fi
fi

# Show connections
echo "Active Connections: $(ss -tn state established '( dport = :http or dport = :https )' | wc -l)"

# Show memory usage
if [ -n "$PID" ]; then
    echo "Memory Usage: $(ps -o rss= -p $PID | tr -d ' ') KB"
fi

echo ""
echo "Recent Log Entries:"
tail -n 5 /var/log/apache2/error.log 2>/dev/null || echo "No error logs available"
EOF

    # Apache reload
    cat > /usr/local/bin/apache-reload << 'EOF'
#!/bin/bash
# Graceful Apache Reload

if systemctl is-active --quiet apache2; then
    echo "Reloading Apache configuration..."
    if /opt/apache/bin/apachectl graceful; then
        echo -e "\e[32m✓ Apache reloaded successfully\e[0m"
    else
        echo -e "\e[31m✗ Failed to reload Apache\e[0m"
        exit 1
    fi
else
    echo "Apache is not running. Starting..."
    if systemctl start apache2; then
        echo -e "\e[32m✓ Apache started successfully\e[0m"
    else
        echo -e "\e[31m✗ Failed to start Apache\e[0m"
        exit 1
    fi
fi
EOF

    # Apache backup
    cat > /usr/local/bin/apache-backup << 'EOF'
#!/bin/bash
# Apache Configuration Backup

BACKUP_DIR="/opt/apache/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/apache-config-$TIMESTAMP.tar.gz"

echo "Creating Apache configuration backup..."

mkdir -p "$BACKUP_DIR"

# Backup configuration files
tar -czf "$BACKUP_FILE" \
    /etc/apache2/ \
    /var/www/html/ \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "\e[32m✓ Backup created: $BACKUP_FILE\e[0m"
    
    # Keep only last 10 backups
    find "$BACKUP_DIR" -name "apache-config-*.tar.gz" -type f | sort -r | tail -n +11 | xargs rm -f
else
    echo -e "\e[31m✗ Backup failed\e[0m"
    exit 1
fi
EOF

    # Make tools executable
    chmod +x /usr/local/bin/apache-*
    
    echo -e "${GREEN}✓ Management tools created${NC}"
}

# Create test page
create_test_page() {
    echo -e "${CYAN}Creating test page...${NC}"
    
    cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apache Server - Installation Complete!</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        .header { text-align: center; color: #333; }
        .success { color: #28a745; }
        .info { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .module { background: #e9ecef; padding: 10px; margin: 5px 0; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="header">
        <h1 class="success">🚀 Apache Installation Complete!</h1>
        <p>Your powerful and flexible web server is ready to serve content.</p>
    </div>
    
    <div class="info">
        <h2>📋 Server Information</h2>
        <p><strong>Server:</strong> Apache HTTP Server</p>
        <p><strong>Document Root:</strong> /var/www/html</p>
        <p><strong>Configuration:</strong> /etc/apache2/</p>
        <p><strong>Logs:</strong> /var/log/apache2/</p>
    </div>
    
    <div class="info">
        <h2>🔧 Management Commands</h2>
        <p><code>apache-monitor</code> - Check server status</p>
        <p><code>apache-reload</code> - Reload configuration</p>
        <p><code>apache-backup</code> - Backup configurations</p>
        <p><code>systemctl status apache2</code> - Service status</p>
    </div>
    
    <div class="info">
        <h2>🌟 Next Steps</h2>
        <p>1. Configure your virtual hosts in <code>/etc/apache2/sites-available/</code></p>
        <p>2. Set up SSL certificates with Let's Encrypt</p>
        <p>3. Configure PHP/FastCGI if needed</p>
        <p>4. Test your applications</p>
    </div>
    
    <div class="info">
        <h2>📊 Server Status</h2>
        <p><strong>Current Time:</strong> <script>document.write(new Date().toLocaleString());</script></p>
        <p><strong>Server Software:</strong> <?php echo $_SERVER['SERVER_SOFTWARE']; ?></p>
        <p><strong>Request Method:</strong> <?php echo $_SERVER['REQUEST_METHOD']; ?></p>
    </div>
</body>
</html>
EOF
    
    chown www-data:www-data "$WEB_ROOT/index.html"
    
    echo -e "${GREEN}✓ Test page created${NC}"
}

# Test configuration
test_configuration() {
    echo -e "${CYAN}Testing Apache configuration...${NC}"
    
    # Test configuration syntax
    if "$INSTALL_DIR/bin/apachectl" configtest; then
        echo -e "${GREEN}✓ Configuration test passed${NC}"
    else
        echo -e "${RED}✗ Configuration test failed${NC}"
        return 1
    fi
}

# Start and enable Apache
start_apache() {
    echo -e "${CYAN}Starting Apache service...${NC}"
    
    if systemctl start apache2; then
        echo -e "${GREEN}✓ Apache started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start Apache${NC}"
        return 1
    fi
    
    # Enable on boot
    systemctl enable apache2
    
    # Wait a moment for startup
    sleep 2
    
    # Check if running
    if systemctl is-active --quiet apache2; then
        echo -e "${GREEN}✓ Apache is running${NC}"
    else
        echo -e "${RED}✗ Apache failed to start${NC}"
        return 1
    fi
}

# Show completion message
show_completion() {
    echo ""
    echo "========================================"
    echo "   Apache Installation Complete!       "
    echo "========================================"
    echo ""
    echo -e "${GREEN}Apache Version: $APACHE_VERSION${NC}"
    echo -e "${GREEN}Installation Directory: $INSTALL_DIR${NC}"
    echo -e "${GREEN}Configuration Directory: $CONFIG_DIR${NC}"
    echo -e "${GREEN}Web Root: $WEB_ROOT${NC}"
    echo -e "${GREEN}Log Directory: $LOG_DIR${NC}"
    echo ""
    
    echo "🔧 Enabled Modules:"
    [[ "$PHP_ENABLED" == true ]] && echo -e "   ${GREEN}✓ PHP (mod_php)${NC}"
    [[ "$SSL_ENABLED" == true ]] && echo -e "   ${GREEN}✓ SSL/TLS (mod_ssl)${NC}"
    [[ "$REWRITE_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Rewrite (mod_rewrite)${NC}"
    [[ "$CACHE_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Cache (mod_cache)${NC}"
    [[ "$PROXY_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Proxy (mod_proxy)${NC}"
    [[ "$SECURITY_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Security (mod_security)${NC}"
    [[ "$GZIP_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Gzip (mod_deflate)${NC}"
    [[ "$EXPIRES_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Expires (mod_expires)${NC}"
    [[ "$HEADERS_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Headers (mod_headers)${NC}"
    [[ "$STATUS_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Status (mod_status)${NC}"
    [[ "$INFO_ENABLED" == true ]] && echo -e "   ${GREEN}✓ Info (mod_info)${NC}"
    [[ "$MPM_EVENT" == true ]] && echo -e "   ${GREEN}✓ MPM Event (High-performance)${NC}"
    [[ "$MPM_WORKER" == true ]] && echo -e "   ${GREEN}✓ MPM Worker (Hybrid)${NC}"
    
    echo ""
    echo "🔧 Management Commands:"
    echo -e "   ${CYAN}apache-monitor${NC}    - Check server status"
    echo -e "   ${CYAN}apache-reload${NC}     - Reload configuration"
    echo -e "   ${CYAN}apache-backup${NC}     - Backup configurations"
    echo -e "   ${CYAN}systemctl status apache2${NC} - Service status"
    
    echo ""
    echo "🌐 Access your server:"
    echo -e "   ${CYAN}http://your-domain.com${NC} - Test page"
    [[ "$STATUS_ENABLED" == true ]] && echo -e "   ${CYAN}http://your-domain.com/server-status${NC} - Server status"
    [[ "$INFO_ENABLED" == true ]] && echo -e "   ${CYAN}http://your-domain.com/server-info${NC} - Server information"
    
    echo ""
    echo "📁 Important Files:"
    echo -e "   ${CYAN}$CONFIG_DIR/apache2.conf${NC} - Main configuration"
    echo -e "   ${CYAN}$CONFIG_DIR/sites-available/${NC} - Virtual hosts"
    echo -e "   ${CYAN}$CONFIG_DIR/mods-available/${NC} - Module configurations"
    echo -e "   ${CYAN}$LOG_DIR/error.log${NC} - Error log"
    echo -e "   ${CYAN}$LOG_DIR/access.log${NC} - Access log"
    
    echo ""
    echo "🔒 Security Features Applied:"
    echo -e "   ${GREEN}✓ Secure file permissions${NC}"
    echo -e "   ${GREEN}✓ Security headers${NC}"
    echo -e "   ${GREEN}✓ Server version hidden${NC}"
    echo -e "   ${GREEN}✓ Request size limits${NC}"
    echo -e "   ${GREEN}✓ Access restrictions${NC}"
    
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. Configure your virtual hosts"
    echo "   2. Set up SSL certificates"
    echo "   3. Deploy your applications"
    echo "   4. Monitor server performance"
    
    echo ""
    echo -e "${GREEN}🎉 Apache is ready for production use!${NC}"
}

# Main installation function
main() {
    echo "========================================"
    echo "    Apache Web Server Installer        "
    echo "========================================"
    echo ""
    
    check_root
    detect_os
    get_apache_version
    install_dependencies
    install_apache_core
    create_directories
    create_main_config
    configure_modules
    create_sample_vhost
    security_hardening
    create_logrotate
    create_management_tools
    create_test_page
    test_configuration
    start_apache
    show_completion
}

# Run main function
main "$@" 2>&1 | tee "$LOG_FILE"
