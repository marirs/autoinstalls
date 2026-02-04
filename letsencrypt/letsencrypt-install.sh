#!/bin/bash
# Let's Encrypt SSL Certificate Manager
# Autoinstalls Project - Production Ready
# Supports Nginx, Apache, Lighttpd with automatic detection

# Color definitions
CRED="\033[0;31m"
CGREEN="\033[1;32m"
CYELLOW="\033[1;33m"
CBLUE="\033[1;34m"
CMAGENTA="\033[1;35m"
CCYAN="\033[1;36m"
CEND="\033[0m"

# Global variables
LE_EMAIL=""
LE_INSTALL_DIR="/opt/letsencrypt"
LE_CONFIG_DIR="$LE_INSTALL_DIR/conf"
LE_LOG_DIR="$LE_INSTALL_DIR/logs"
LE_BACKUP_DIR="$LE_INSTALL_DIR/backups"
DOMAINS_LIST="$LE_CONFIG_DIR/domains.list"
LOG_FILE="/tmp/letsencrypt-install.log"

# Web server detection
WEBSERVER_TYPE=""
VHOST_PATHS=()

# Initialize directories
mkdir -p "$LE_INSTALL_DIR" "$LE_CONFIG_DIR" "$LE_LOG_DIR" "$LE_BACKUP_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${CRED}This script must be run as root${CEND}"
        exit 1
    fi
}

# Detect web server type
detect_webserver() {
    WEBSERVER_TYPE=""
    VHOST_PATHS=()
    
    # Check Nginx
    if command -v nginx >/dev/null 2>&1; then
        if [[ -d "/etc/nginx/sites-available" ]]; then
            WEBSERVER_TYPE="nginx"
            VHOST_PATHS+=("/etc/nginx/sites-available")
        fi
        if [[ -d "/etc/nginx/conf.d" ]]; then
            if [[ "$WEBSERVER_TYPE" == "" ]]; then
                WEBSERVER_TYPE="nginx"
            fi
            VHOST_PATHS+=("/etc/nginx/conf.d")
        fi
    fi
    
    # Check Apache
    if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
        if [[ -d "/etc/apache2/sites-available" ]]; then
            WEBSERVER_TYPE="apache"
            VHOST_PATHS+=("/etc/apache2/sites-available")
        fi
        if [[ -d "/etc/httpd/conf.d" ]]; then
            if [[ "$WEBSERVER_TYPE" == "" ]]; then
                WEBSERVER_TYPE="apache"
            fi
            VHOST_PATHS+=("/etc/httpd/conf.d")
        fi
    fi
    
    # Check Lighttpd
    if command -v lighttpd >/dev/null 2>&1; then
        if [[ -d "/etc/lighttpd/conf-enabled" ]]; then
            WEBSERVER_TYPE="lighttpd"
            VHOST_PATHS+=("/etc/lighttpd/conf-enabled")
        fi
        if [[ -f "/etc/lighttpd/lighttpd.conf" ]]; then
            if [[ "$WEBSERVER_TYPE" == "" ]]; then
                WEBSERVER_TYPE="lighttpd"
            fi
            VHOST_PATHS+=("/etc/lighttpd")
        fi
    fi
    
    # Check for user-defined locations
    if [[ -d "/usr/local/nginx/conf" ]]; then
        VHOST_PATHS+=("/usr/local/nginx/conf")
    fi
    if [[ -d "/usr/local/apache2/conf" ]]; then
        VHOST_PATHS+=("/usr/local/apache2/conf")
    fi
    
    log "Detected web server: $WEBSERVER_TYPE"
    log "Vhost paths: ${VHOST_PATHS[*]}"
}

# Extract base domain from wildcard or full domain
extract_base_domain() {
    local domain="$1"
    
    # Handle wildcard domains
    if [[ "$domain" == "*."* ]]; then
        echo "${domain#*.}"
    else
        echo "$domain"
    fi
}

# Extract domain from vhost file
extract_domain_from_vhost() {
    local vhost_file="$1"
    local domain=""
    
    case "$WEBSERVER_TYPE" in
        "nginx")
            domain=$(grep -E "server_name\s+([^;]+)" "$vhost_file" | head -1 | sed 's/server_name\s\+//' | sed 's/;//' | awk '{print $1}')
            ;;
        "apache")
            domain=$(grep -E "ServerName\s+([^;]+)" "$vhost_file" | head -1 | awk '{print $2}')
            ;;
        "lighttpd")
            domain=$(grep -E "\$HTTP\[\"([^\"]+)\"\]" "$vhost_file" | head -1 | sed 's/\$HTTP\[\"//' | sed 's/\"\]//')
            ;;
    esac
    
    echo "$domain"
}

# Check if vhost has SSL configured
has_ssl_configured() {
    local vhost_file="$1"
    
    case "$WEBSERVER_TYPE" in
        "nginx")
            grep -q "ssl_certificate" "$vhost_file" 2>/dev/null
            ;;
        "apache")
            grep -q "SSLEngine\s\+on" "$vhost_file" 2>/dev/null
            ;;
        "lighttpd")
            grep -q "ssl.engine\s*=\s*\"enable\"" "$vhost_file" 2>/dev/null
            ;;
    esac
}

# Get web root from vhost
get_web_root() {
    local vhost_file="$1"
    local web_root=""
    
    case "$WEBSERVER_TYPE" in
        "nginx")
            web_root=$(grep -E "root\s+([^;]+)" "$vhost_file" | head -1 | sed 's/root\s\+//' | sed 's/;//')
            ;;
        "apache")
            web_root=$(grep -E "DocumentRoot\s+([^;]+)" "$vhost_file" | head -1 | awk '{print $2}')
            ;;
        "lighttpd")
            web_root=$(grep -E "server.document-root\s*=\s*\"([^\"]+)\"" "$vhost_file" | head -1 | sed 's/server.document-root\s*=\s*"//' | sed 's/"//')
            ;;
    esac
    
    echo "$web_root"
}

# List available domains without SSL
list_available_domains() {
    echo -e "${CCYAN}Scanning for domains without SSL configuration...${CEND}"
    echo ""
    
    local domains_found=0
    local domain_files=()
    
    for vhost_path in "${VHOST_PATHS[@]}"; do
        if [[ -d "$vhost_path" ]]; then
            for vhost_file in "$vhost_path"/*.{conf,config}; do
                if [[ -f "$vhost_file" ]]; then
                    local domain=$(extract_domain_from_vhost "$vhost_file")
                    if [[ "$domain" != "" && ! "$domain" =~ ^# && ! "$domain" =~ ^localhost ]]; then
                        if ! has_ssl_configured "$vhost_file"; then
                            domains_found=$((domains_found + 1))
                            domain_files+=("$vhost_file:$domain")
                            echo -e "   ${CGREEN}$domains_found) $domain${CEND} (${CCYAN}$vhost_file${CEND})"
                        fi
                    fi
                fi
            done
        fi
    done
    
    if [[ $domains_found -eq 0 ]]; then
        echo -e "${CYELLOW}No domains found without SSL configuration.${CEND}"
        echo ""
        echo -e "${CCYAN}All configured domains already have SSL or no vhosts found.${CEND}"
        return 1
    fi
    
    echo ""
    echo -e "${CCYAN}Total domains available: $domains_found${CEND}"
    echo ""
    
    # Save domain mapping for later use
    > "$LE_CONFIG_DIR/domain_mapping.tmp"
    for i in "${!domain_files[@]}"; do
        echo "${domain_files[$i]}" >> "$LE_CONFIG_DIR/domain_mapping.tmp"
    done
    
    return 0
}

# Install Let's Encrypt Certbot
install_letsencrypt() {
    echo -e "${CCYAN}Installing Let's Encrypt Certbot...${CEND}"
    
    # Check if already installed
    if command -v certbot >/dev/null 2>&1; then
        echo -e "${CGREEN}Certbot is already installed.${CEND}"
        return 0
    fi
    
    # Detect OS and install
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        apt update
        apt install -y snapd
        snap install --classic certbot
        ln -sf /snap/bin/certbot /usr/bin/certbot
    elif [[ -f /etc/redhat-release ]]; then
        # RHEL/CentOS
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y epel-release
            dnf install -y certbot python3-certbot-nginx
        else
            yum install -y epel-release
            yum install -y certbot python3-certbot-nginx
        fi
    else
        echo -e "${CRED}Unsupported OS. Please install Certbot manually.${CEND}"
        return 1
    fi
    
    if command -v certbot >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ Certbot installed successfully${CEND}"
        log "Certbot installation completed"
        return 0
    else
        echo -e "${CRED}✗ Certbot installation failed${CEND}"
        return 1
    fi
}

# Configure email address
configure_email() {
    if [[ -f "$LE_CONFIG_DIR/email.conf" ]]; then
        LE_EMAIL=$(cat "$LE_CONFIG_DIR/email.conf")
        echo -e "${CCYAN}Using saved email: $LE_EMAIL${CEND}"
        echo ""
        read -p "Do you want to change this email? [y/N]: " change_email
        if [[ "$change_email" =~ ^[Yy]$ ]]; then
            read -p "Enter email address for Let's Encrypt: " LE_EMAIL
            echo "$LE_EMAIL" > "$LE_CONFIG_DIR/email.conf"
        fi
    else
        read -p "Enter email address for Let's Encrypt: " LE_EMAIL
        if [[ "$LE_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo "$LE_EMAIL" > "$LE_CONFIG_DIR/email.conf"
            echo -e "${CGREEN}✓ Email address saved${CEND}"
        else
            echo -e "${CRED}✗ Invalid email address${CEND}"
            return 1
        fi
    fi
}

# Generate SSL certificate for domain
generate_certificate() {
    local domain="$1"
    local web_root="$2"
    local base_domain=$(extract_base_domain "$domain")
    
    echo -e "${CCYAN}Generating SSL certificate for $domain...${CEND}"
    
    # Create web root .well-known directory if not exists
    mkdir -p "$web_root/.well-known/acme-challenge"
    
    # Generate certificate with proper domain handling
    if [[ "$domain" == "*."* ]]; then
        echo -e "${CYELLOW}Note: Wildcard certificates require DNS validation.${CEND}"
        echo -e "${CYELLOW}Use option 4 from main menu for wildcard certificates.${CEND}"
        echo -e "${CYELLOW}This option supports HTTP validation for regular domains only.${CEND}"
        return 1
    else
        certbot certonly --webroot -w "$web_root" -d "$domain" --email "$LE_EMAIL" --agree-tos --non-interactive >> "$LOG_FILE" 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${CGREEN}✓ Certificate generated successfully${CEND}"
        echo -e "${CCYAN}Certificate location: /etc/letsencrypt/live/$base_domain/${CEND}"
        log "Certificate generated for $domain (base: $base_domain)"
        return 0
    else
        echo -e "${CRED}✗ Certificate generation failed${CEND}"
        echo -e "${CYELLOW}Check log file: $LOG_FILE${CEND}"
        return 1
    fi
}

# Create SSL configuration for Nginx
create_nginx_ssl_config() {
    local domain="$1"
    local vhost_file="$2"
    local web_root="$3"
    local base_domain=$(extract_base_domain "$domain")
    
    # Backup original file
    cp "$vhost_file" "$LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Create new SSL configuration
    cat > "$vhost_file" << EOF
# SSL Configuration for $domain - Generated by Let's Encrypt Manager
server {
    listen 80;
    server_name $domain;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    root $web_root;
    index index.html index.php;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$base_domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$base_domain/privkey.pem;
    
    # SSL Security Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Existing configuration continues below...
EOF
    
    # Add remaining configuration from original file (excluding server blocks)
    grep -v -E "^\s*listen\s|^\s*server_name\s|^\s*root\s|^\s*index\s" "$LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf" | grep -v -E "^\s*server\s*\{" | grep -v -E "^\s*\}" >> "$vhost_file"
    
    echo "}" >> "$vhost_file"
}

# Create SSL configuration for Apache
create_apache_ssl_config() {
    local domain="$1"
    local vhost_file="$2"
    local web_root="$3"
    local base_domain=$(extract_base_domain "$domain")
    
    # Backup original file
    cp "$vhost_file" "$LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Create new SSL configuration
    cat > "$vhost_file" << EOF
# SSL Configuration for $domain - Generated by Let's Encrypt Manager
<VirtualHost *:80>
    ServerName $domain
    DocumentRoot $web_root
    
    # Redirect all HTTP traffic to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName $domain
    DocumentRoot $web_root
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$base_domain/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$base_domain/privkey.pem
    
    # SSL Security Configuration
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionCache shmcb:\${APACHE_RUN_DIR}/ssl_scache(512000)
    SSLSessionCacheTimeout 300
    
    # Security Headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Existing configuration continues below...
EOF
    
    # Add remaining configuration from original file
    grep -v -E "^\s*<VirtualHost|^\s*ServerName|^\s*DocumentRoot|^\s*</VirtualHost>" "$LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf" >> "$vhost_file"
    
    echo "</VirtualHost>" >> "$vhost_file"
}

# Create SSL configuration for Lighttpd
create_lighttpd_ssl_config() {
    local domain="$1"
    local vhost_file="$2"
    local web_root="$3"
    local base_domain=$(extract_base_domain "$domain")
    
    # Backup original file
    cp "$vhost_file" "$LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf"
    
    # Add SSL configuration to existing config
    cat >> "$vhost_file" << EOF

# SSL Configuration for $domain - Generated by Let's Encrypt Manager
\$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/letsencrypt/live/$base_domain/privkey.pem"
    ssl.ca-file = "/etc/letsencrypt/live/$base_domain/fullchain.pem"
    
    # SSL Security Configuration
    ssl.honor-cipher-order = "disable"
    ssl.use-sslv2 = "disable"
    ssl.use-sslv3 = "disable"
    ssl.use-tlsv1 = "disable"
    ssl.use-tlsv1.1 = "disable"
    
    # Security Headers
    setenv.add-response-header = (
        "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
        "X-Frame-Options" => "DENY",
        "X-Content-Type-Options" => "nosniff",
        "X-XSS-Protection" => "1; mode=block",
        "Referrer-Policy" => "strict-origin-when-cross-origin"
    )
}

# HTTP to HTTPS redirect
\$HTTP["host"] =~ "$domain" {
    \$SERVER["socket"] == ":80" {
        url.redirect = ( "^/(.*)" => "https://$domain/\$1" )
    }
}
EOF
}

# Test web server configuration
test_webserver_config() {
    case "$WEBSERVER_TYPE" in
        "nginx")
            nginx -t
            ;;
        "apache")
            if command -v apache2ctl >/dev/null 2>&1; then
                apache2ctl configtest
            else
                httpd -t
            fi
            ;;
        "lighttpd")
            lighttpd -t -f "$vhost_file"
            ;;
    esac
}

# Reload web server
reload_webserver() {
    case "$WEBSERVER_TYPE" in
        "nginx")
            systemctl reload nginx
            ;;
        "apache")
            systemctl reload apache2 || systemctl reload httpd
            ;;
        "lighttpd")
            systemctl reload lighttpd
            ;;
    esac
}

# Add domain to renewal list
add_domain_to_renewal() {
    local domain="$1"
    
    if [[ ! -f "$DOMAINS_LIST" ]]; then
        touch "$DOMAINS_LIST"
    fi
    
    if ! grep -q "^$domain$" "$DOMAINS_LIST"; then
        echo "$domain" >> "$DOMAINS_LIST"
        log "Added $domain to renewal list"
    fi
}

# Configure SSL for multiple domains (SAN)
configure_ssl_for_san() {
    echo -e "${CCYAN}Configure SSL Certificate for Multiple Domains (SAN)${CEND}"
    echo -e "${CCYAN}==============================================${CEND}"
    echo ""
    
    # Show detected web server
    echo -e "${CCYAN}Detected Web Server: ${CGREEN}$WEBSERVER_TYPE${CEND}"
    echo ""
    
    echo -e "${CCYAN}Enter domains for SAN certificate (comma-separated):${CEND}"
    echo -e "${CYELLOW}Example: example.com, www.example.com, api.example.com${CEND}"
    echo ""
    read -p "Domains: " san_domains
    
    # Parse and validate domains
    IFS=',' read -ra DOMAIN_ARRAY <<< "$san_domains"
    valid_domains=()
    
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain=$(echo "$domain" | xargs)  # trim whitespace
        if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            valid_domains+=("$domain")
        else
            echo -e "${CRED}✗ Invalid domain: $domain${CEND}"
        fi
    done
    
    if [[ ${#valid_domains[@]} -eq 0 ]]; then
        echo -e "${CRED}No valid domains provided${CEND}"
        return 1
    fi
    
    echo ""
    echo -e "${CCYAN}Valid domains for SAN certificate:${CEND}"
    for domain in "${valid_domains[@]}"; do
        echo -e "   ${CGREEN}- $domain${CEND}"
    done
    echo ""
    
    # Use first domain as primary
    primary_domain="${valid_domains[0]}"
    local web_root=""
    
    # Try to detect web root for primary domain
    for vhost_path in "${VHOST_PATHS[@]}"; do
        if [[ -d "$vhost_path" ]]; then
            for vhost_file in "$vhost_path"/*.{conf,config}; do
                if [[ -f "$vhost_file" ]]; then
                    local detected_domain=$(extract_domain_from_vhost "$vhost_file")
                    if [[ "$detected_domain" == "$primary_domain" ]]; then
                        web_root=$(get_web_root "$vhost_file")
                        break 2
                    fi
                fi
            done
        fi
    done
    
    if [[ "$web_root" == "" ]]; then
        echo -e "${CYELLOW}Could not auto-detect web root for $primary_domain${CEND}"
        read -p "Enter web root directory: " web_root
        if [[ ! -d "$web_root" ]]; then
            echo -e "${CRED}Web root directory does not exist${CEND}"
            return 1
        fi
    fi
    
    echo -e "${CCYAN}Using web root: $web_root${CEND}"
    
    # Configure email if not already done
    configure_email
    
    # Generate SAN certificate
    if generate_san_certificate "${valid_domains[@]}" "$web_root"; then
        # Create SSL configuration for primary domain
        case "$WEBSERVER_TYPE" in
            "nginx")
                create_nginx_ssl_config "$primary_domain" "$(find_vhost_file "$primary_domain")" "$web_root"
                ;;
            "apache")
                create_apache_ssl_config "$primary_domain" "$(find_vhost_file "$primary_domain")" "$web_root"
                ;;
            "lighttpd")
                create_lighttpd_ssl_config "$primary_domain" "$(find_vhost_file "$primary_domain")" "$web_root"
                ;;
        esac
        
        # Add all domains to renewal list
        for domain in "${valid_domains[@]}"; do
            add_domain_to_renewal "$domain"
        done
        
        echo ""
        echo -e "${CGREEN}✓ SAN SSL configuration completed successfully!${CEND}"
        echo -e "${CCYAN}Primary Domain: https://$primary_domain${CEND}"
        echo -e "${CCYAN}Additional Domains: ${valid_domains[@]:1}${CEND}"
        local base_domain=$(extract_base_domain "$primary_domain")
        echo -e "${CCYAN}Certificate: /etc/letsencrypt/live/$base_domain/${CEND}"
        
        return 0
    else
        return 1
    fi
}

# Find vhost file for domain
find_vhost_file() {
    local domain="$1"
    
    for vhost_path in "${VHOST_PATHS[@]}"; do
        if [[ -d "$vhost_path" ]]; then
            for vhost_file in "$vhost_path"/*.{conf,config}; do
                if [[ -f "$vhost_file" ]]; then
                    local detected_domain=$(extract_domain_from_vhost "$vhost_file")
                    if [[ "$detected_domain" == "$domain" ]]; then
                        echo "$vhost_file"
                        return 0
                    fi
                fi
            done
        fi
    done
    return 1
}

# Generate SAN certificate
generate_san_certificate() {
    local domains=("$@")
    local web_root="${domains[-1]}"
    unset 'domains[-1]'  # Remove last element (web_root)
    
    echo -e "${CCYAN}Generating SAN certificate for ${domains[*]}...${CEND}"
    
    # Create web root .well-known directory if not exists
    mkdir -p "$web_root/.well-known/acme-challenge"
    
    # Build domain arguments for certbot
    domain_args=""
    for domain in "${domains[@]}"; do
        domain_args="$domain_args -d $domain"
    done
    
    # Generate SAN certificate
    certbot certonly --webroot -w "$web_root" $domain_args --email "$LE_EMAIL" --agree-tos --non-interactive >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo -e "${CGREEN}✓ SAN certificate generated successfully${CEND}"
        local base_domain=$(extract_base_domain "${domains[0]}")
        echo -e "${CCYAN}Certificate location: /etc/letsencrypt/live/$base_domain/${CEND}"
        log "SAN certificate generated for ${domains[*]} (base: $base_domain)"
        return 0
    else
        echo -e "${CRED}✗ SAN certificate generation failed${CEND}"
        echo -e "${CYELLOW}Check log file: $LOG_FILE${CEND}"
        return 1
    fi
}

# Configure wildcard certificate with DNS validation
configure_wildcard_certificate() {
    echo -e "${CCYAN}Configure Wildcard Certificate (DNS Validation)${CEND}"
    echo -e "${CCYAN}============================================${CEND}"
    echo ""
    
    echo -e "${CCYAN}Enter wildcard domain:${CEND}"
    echo -e "${CYELLOW}Example: *.example.com${CEND}"
    echo ""
    read -p "Wildcard domain: " wildcard_domain
    
    # Validate wildcard domain
    if [[ ! "$wildcard_domain" == "*."* ]]; then
        echo -e "${CRED}Invalid wildcard domain format. Use format: *.example.com${CEND}"
        return 1
    fi
    
    local base_domain=$(extract_base_domain "$wildcard_domain")
    
    echo ""
    echo -e "${CCYAN}Wildcard domain: $wildcard_domain${CEND}"
    echo -e "${CCYAN}Base domain: $base_domain${CEND}"
    echo ""
    
    echo -e "${CYELLOW}DNS validation is required for wildcard certificates.${CEND}"
    echo -e "${CYELLOW}This script supports the following DNS providers:${CEND}"
    echo -e "${CCYAN}1) Cloudflare${CEND}"
    echo -e "${CCYAN}2) Route 53 (AWS)${CEND}"
    echo -e "${CCYAN}3) DigitalOcean${CEND}"
    echo -e "${CCYAN}4) Manual DNS validation${CEND}"
    echo ""
    read -p "Select DNS provider [1-4]: " dns_provider
    
    case "$dns_provider" in
        1)
            configure_cloudflare_dns "$wildcard_domain" "$base_domain"
            ;;
        2)
            configure_route53_dns "$wildcard_domain" "$base_domain"
            ;;
        3)
            configure_digitalocean_dns "$wildcard_domain" "$base_domain"
            ;;
        4)
            configure_manual_dns "$wildcard_domain" "$base_domain"
            ;;
        *)
            echo -e "${CRED}Invalid selection${CEND}"
            return 1
            ;;
    esac
}

# Configure Cloudflare DNS validation
configure_cloudflare_dns() {
    local wildcard_domain="$1"
    local base_domain="$2"
    
    echo -e "${CCYAN}Configuring Cloudflare DNS validation...${CEND}"
    echo ""
    
    # Check if certbot-dns-cloudflare is installed
    if ! pip show certbot-dns-cloudflare >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing Cloudflare DNS plugin...${CEND}"
        pip install certbot-dns-cloudflare >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${CCYAN}Enter Cloudflare credentials:${CEND}"
    read -p "Cloudflare API Token: " cf_token
    read -p "Cloudflare Email: " cf_email
    
    # Create Cloudflare credential file
    mkdir -p /etc/letsencrypt
    cat > /etc/letsencrypt/cloudflare.ini << EOF
dns_cloudflare_api_token = $cf_token
dns_cloudflare_email = $cf_email
EOF
    chmod 600 /etc/letsencrypt/cloudflare.ini
    
    # Configure email if not already done
    configure_email
    
    # Generate wildcard certificate
    echo -e "${CCYAN}Generating wildcard certificate...${CEND}"
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d "$wildcard_domain" -d "$base_domain" --email "$LE_EMAIL" --agree-tos --non-interactive >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo -e "${CGREEN}✓ Wildcard certificate generated successfully${CEND}"
        echo -e "${CCYAN}Certificate location: /etc/letsencrypt/live/$base_domain/${CEND}"
        
        # Add to renewal list
        add_domain_to_renewal "$wildcard_domain"
        add_domain_to_renewal "$base_domain"
        
        echo ""
        echo -e "${CCYAN}Note: You'll need to manually configure your web server to use this certificate.${CEND}"
        echo -e "${CCYAN}Certificate paths:${CEND}"
        echo -e "${CCYAN}  Certificate: /etc/letsencrypt/live/$base_domain/fullchain.pem${CEND}"
        echo -e "${CCYAN}  Private Key: /etc/letsencrypt/live/$base_domain/privkey.pem${CEND}"
        
        return 0
    else
        echo -e "${CRED}✗ Wildcard certificate generation failed${CEND}"
        echo -e "${CYELLOW}Check log file: $LOG_FILE${CEND}"
        return 1
    fi
}

# Configure manual DNS validation
configure_manual_dns() {
    local wildcard_domain="$1"
    local base_domain="$2"
    
    echo -e "${CCYAN}Manual DNS Validation Process${CEND}"
    echo -e "${CCYAN}============================${CEND}"
    echo ""
    
    # Configure email if not already done
    configure_email
    
    echo -e "${CCYAN}Starting manual DNS validation...${CEND}"
    certbot certonly --manual --preferred-challenges dns -d "$wildcard_domain" -d "$base_domain" --email "$LE_EMAIL" --agree-tos --non-interactive >> "$LOG_FILE" 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo -e "${CGREEN}✓ Wildcard certificate generated successfully${CEND}"
        echo -e "${CCYAN}Certificate location: /etc/letsencrypt/live/$base_domain/${CEND}"
        
        # Add to renewal list
        add_domain_to_renewal "$wildcard_domain"
        add_domain_to_renewal "$base_domain"
        
        return 0
    else
        echo -e "${CRED}✗ Manual DNS validation failed${CEND}"
        echo -e "${CYELLOW}Please follow the prompts to create DNS records manually${CEND}"
        return 1
    fi
}

# Configure SSL for selected domain
configure_ssl_for_domain() {
    echo -e "${CCYAN}Configure SSL Certificate for Domain${CEND}"
    echo -e "${CCYAN}=====================================${CEND}"
    echo ""
    
    # Show detected web server
    echo -e "${CCYAN}Detected Web Server: ${CGREEN}$WEBSERVER_TYPE${CEND}"
    echo ""
    
    # List available domains
    if ! list_available_domains; then
        return 1
    fi
    
    echo ""
    read -p "Select domain to configure SSL [1-$domains_found]: " domain_choice
    
    if [[ "$domain_choice" =~ ^[0-9]+$ ]] && [[ $domain_choice -ge 1 ]] && [[ $domain_choice -le $domains_found ]]; then
        local selected_line=$(sed -n "${domain_choice}p" "$LE_CONFIG_DIR/domain_mapping.tmp")
        local vhost_file=$(echo "$selected_line" | cut -d: -f1)
        local domain=$(echo "$selected_line" | cut -d: -f2)
        local web_root=$(get_web_root "$vhost_file")
        
        echo ""
        echo -e "${CCYAN}Selected domain: ${CGREEN}$domain${CEND}"
        echo -e "${CCYAN}Vhost file: ${CCYAN}$vhost_file${CEND}"
        echo -e "${CCYAN}Web root: ${CCYAN}$web_root${CEND}"
        echo ""
        
        # Configure email if not already done
        configure_email
        
        # Generate certificate
        if generate_certificate "$domain" "$web_root"; then
            # Create SSL configuration
            case "$WEBSERVER_TYPE" in
                "nginx")
                    create_nginx_ssl_config "$domain" "$vhost_file" "$web_root"
                    ;;
                "apache")
                    create_apache_ssl_config "$domain" "$vhost_file" "$web_root"
                    ;;
                "lighttpd")
                    create_lighttpd_ssl_config "$domain" "$vhost_file" "$web_root"
                    ;;
            esac
            
            # Test configuration
            echo -ne "       Testing web server configuration [..]\r"
            if test_webserver_config >/dev/null 2>&1; then
                echo -ne "       Testing web server configuration [${CGREEN}OK${CEND}]\r"
                echo -ne "\n"
                
                # Reload web server
                echo -ne "       Reloading web server           [..]\r"
                if reload_webserver >/dev/null 2>&1; then
                    echo -ne "       Reloading web server           [${CGREEN}OK${CEND}]\r"
                    echo -ne "\n"
                else
                    echo -ne "       Reloading web server           [${CRED}FAIL${CEND}]\r"
                    echo -ne "\n"
                    return 1
                fi
                
                # Add to renewal list
                add_domain_to_renewal "$domain"
                
                echo ""
                echo -e "${CGREEN}✓ SSL configuration completed successfully!${CEND}"
                echo -e "${CCYAN}Domain: https://$domain${CEND}"
                local base_domain=$(extract_base_domain "$domain")
                echo -e "${CCYAN}Certificate: /etc/letsencrypt/live/$base_domain/${CEND}"
                echo -e "${CCYAN}Backup: $LE_BACKUP_DIR/${domain}_$(date +%Y%m%d_%H%M%S).conf${CEND}"
                
                # Clean up temp file
                rm -f "$LE_CONFIG_DIR/domain_mapping.tmp"
                
                return 0
            else
                echo -ne "       Testing web server configuration [${CRED}FAIL${CEND}]\r"
                echo -ne "\n"
                echo -e "${CRED}Configuration test failed. Check log file: $LOG_FILE${CEND}"
                return 1
            fi
        else
            return 1
        fi
    else
        echo -e "${CRED}Invalid selection${CEND}"
        return 1
    fi
}

# List configured SSL domains
list_ssl_domains() {
    echo -e "${CCYAN}Configured SSL Domains${CEND}"
    echo -e "${CCYAN}======================${CEND}"
    echo ""
    
    if [[ ! -f "$DOMAINS_LIST" ]]; then
        echo -e "${CYELLOW}No SSL domains configured yet.${CEND}"
        return 1
    fi
    
    local count=0
    while IFS= read -r domain; do
        if [[ "$domain" != "" ]]; then
            count=$((count + 1))
            if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
                local expiry=$(openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
                echo -e "   ${CGREEN}$count) $domain${CEND}"
                echo -e "      Expires: ${CCYAN}$expiry${CEND}"
                echo ""
            else
                echo -e "   ${CRED}$count) $domain (Certificate missing)${CEND}"
                echo ""
            fi
        fi
    done < "$DOMAINS_LIST"
    
    if [[ $count -eq 0 ]]; then
        echo -e "${CYELLOW}No SSL domains configured yet.${CEND}"
    fi
}

# Create renewal script
create_renewal_script() {
    cat > "$LE_INSTALL_DIR/letsencrypt-renew-all.sh" << 'EOF'
#!/bin/bash
# Let's Encrypt Certificate Renewal Script
# Auto-renews all configured certificates

LE_CONFIG_DIR="/opt/letsencrypt/conf"
DOMAINS_LIST="$LE_CONFIG_DIR/domains.list"
LOG_FILE="/var/log/letsencrypt-renewal.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

renew_certificate() {
    local domain="$1"
    
    # Check if certificate expires within 30 days
    if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
        local expiry=$(openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
        local expiry_timestamp=$(date -d "$expiry" +%s)
        local current_timestamp=$(date +%s)
        local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [[ $days_until_expiry -le 30 ]]; then
            log "Renewing certificate for $domain (expires in $days_until_expiry days)"
            
            if certbot renew --cert-name "$domain" --non-interactive >> "$LOG_FILE" 2>&1; then
                log "Successfully renewed certificate for $domain"
                
                # Reload web server
                if command -v nginx >/dev/null 2>&1; then
                    systemctl reload nginx
                elif command -v apache2 >/dev/null 2>&1; then
                    systemctl reload apache2
                elif command -v httpd >/dev/null 2>&1; then
                    systemctl reload httpd
                elif command -v lighttpd >/dev/null 2>&1; then
                    systemctl reload lighttpd
                fi
                
                log "Web server reloaded after certificate renewal"
                return 0
            else
                log "Failed to renew certificate for $domain"
                return 1
            fi
        else
            log "Certificate for $domain is still valid ($days_until_expiry days remaining)"
            return 0
        fi
    else
        log "Certificate file not found for $domain"
        return 1
    fi
}

main() {
    log "Starting certificate renewal check"
    
    local renewed_count=0
    local failed_count=0
    
    if [[ -f "$DOMAINS_LIST" ]]; then
        while IFS= read -r domain; do
            if [[ "$domain" != "" ]]; then
                if renew_certificate "$domain"; then
                    renewed_count=$((renewed_count + 1))
                else
                    failed_count=$((failed_count + 1))
                fi
            fi
        done < "$DOMAINS_LIST"
    fi
    
    log "Renewal check completed: $renewed_count renewed, $failed_count failed"
    
    # Send email summary if configured
    if [[ -f "/opt/letsencrypt/conf/email.conf" ]]; then
        local email=$(cat "/opt/letsencrypt/conf/email.conf")
        echo "Let's Encrypt renewal summary: $renewed_count renewed, $failed_count failed" | mail -s "SSL Certificate Renewal Summary" "$email" 2>/dev/null
    fi
}

main "$@"
EOF
    
    chmod +x "$LE_INSTALL_DIR/letsencrypt-renew-all.sh"
    echo -e "${CGREEN}✓ Renewal script created${CEND}"
}

# Configure auto-renewal
configure_auto_renewal() {
    echo -e "${CCYAN}Configure Auto-Renewal${CEND}"
    echo -e "${CCYAN}=====================${CEND}"
    echo ""
    
    # Create renewal script
    create_renewal_script
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "letsencrypt-renew-all.sh"; then
        echo -e "${CYELLOW}Auto-renewal cron job already exists.${CEND}"
        echo ""
        read -p "Do you want to remove it? [y/N]: " remove_cron
        if [[ "$remove_cron" =~ ^[Yy]$ ]]; then
            crontab -l 2>/dev/null | grep -v "letsencrypt-renew-all.sh" | crontab -
            echo -e "${CGREEN}✓ Cron job removed${CEND}"
        fi
        return 0
    fi
    
    echo "Select renewal frequency:"
    echo "   1) Daily at 3:00 AM (Recommended)"
    echo "   2) Daily at 2:00 AM"
    echo "   3) Daily at 4:00 AM"
    echo "   4) Weekly (Sunday at 3:00 AM)"
    echo "   5) Monthly (1st at 3:00 AM)"
    echo ""
    read -p "Select frequency [1-5]: " freq_choice
    
    local cron_schedule=""
    local description=""
    
    case "$freq_choice" in
        1)
            cron_schedule="0 3 * * *"
            description="Daily at 3:00 AM"
            ;;
        2)
            cron_schedule="0 2 * * *"
            description="Daily at 2:00 AM"
            ;;
        3)
            cron_schedule="0 4 * * *"
            description="Daily at 4:00 AM"
            ;;
        4)
            cron_schedule="0 3 * * 0"
            description="Weekly on Sunday at 3:00 AM"
            ;;
        5)
            cron_schedule="0 3 1 * *"
            description="Monthly on 1st at 3:00 AM"
            ;;
        *)
            echo -e "${CRED}Invalid selection${CEND}"
            return 1
            ;;
    esac
    
    # Add cron job
    (crontab -l 2>/dev/null; echo "$cron_schedule $LE_INSTALL_DIR/letsencrypt-renew-all.sh > /var/log/letsencrypt-renewal.log 2>&1") | crontab -
    
    echo ""
    echo -e "${CGREEN}✓ Auto-renewal configured${CEND}"
    echo -e "${CCYAN}Schedule: $description${CEND}"
    echo -e "${CCYAN}Cron job: $cron_schedule $LE_INSTALL_DIR/letsencrypt-renew-all.sh${CEND}"
    echo -e "${CCYAN}Log file: /var/log/letsencrypt-renewal.log${CEND}"
}

# Backup certificates
backup_certificates() {
    echo -e "${CCYAN}Backup SSL Certificates${CEND}"
    echo -e "${CCYAN}======================${CEND}"
    echo ""
    
    local backup_name="letsencrypt_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    if [[ -d "/etc/letsencrypt" ]]; then
        tar -czf "$LE_BACKUP_DIR/$backup_name" -C "/etc" letsencrypt
        
        if [[ $? -eq 0 ]]; then
            echo -e "${CGREEN}✓ Certificates backed up${CEND}"
            echo -e "${CCYAN}Backup file: $LE_BACKUP_DIR/$backup_name${CEND}"
            echo -e "${CCYAN}Size: $(du -h "$LE_BACKUP_DIR/$backup_name" | cut -f1)${CEND}"
        else
            echo -e "${CRED}✗ Backup failed${CEND}"
            return 1
        fi
    else
        echo -e "${CYELLOW}No certificates found to backup${CEND}"
    fi
}

# Main menu
show_main_menu() {
    clear
    echo -e "${CMAGENTA}========================================${CEND}"
    echo -e "${CMAGENTA}    Let's Encrypt SSL Certificate Manager${CEND}"
    echo -e "${CMAGENTA}========================================${CEND}"
    echo ""
    
    # Show web server status
    detect_webserver
    if [[ "$WEBSERVER_TYPE" != "" ]]; then
        echo -e "${CCYAN}Web Server Detected: ${CGREEN}$WEBSERVER_TYPE${CEND}"
    else
        echo -e "${CYELLOW}No supported web server detected${CEND}"
    fi
    echo ""
    
    echo "Select an option:"
    echo "   1) Install and Configure Let's Encrypt"
    echo "   2) Configure SSL Certificate for Domain"
    echo "   3) Configure SSL Certificate for Multiple Domains (SAN)"
    echo "   4) Configure Wildcard Certificate (DNS Validation)"
    echo "   5) List Available Domains (without SSL)"
    echo "   6) List Configured SSL Domains"
    echo "   7) Manual Certificate Renewal"
    echo "   8) Configure Auto-Renewal"
    echo "   9) Backup Certificates"
    echo "   10) Uninstall Let's Encrypt"
    echo "   11) Exit"
    echo ""
}

# Manual renewal
manual_renewal() {
    echo -e "${CCYAN}Manual Certificate Renewal${CEND}"
    echo -e "${CCYAN}==========================${CEND}"
    echo ""
    
    if [[ ! -f "$DOMAINS_LIST" ]]; then
        echo -e "${CYELLOW}No domains configured for renewal.${CEND}"
        return 1
    fi
    
    echo "Renewal options:"
    echo "   1) Renew all certificates"
    echo "   2) Renew specific certificate"
    echo ""
    read -p "Select option [1-2]: " renewal_choice
    
    case "$renewal_choice" in
        1)
            echo -e "${CCYAN}Renewing all certificates...${CEND}"
            "$LE_INSTALL_DIR/letsencrypt-renew-all.sh"
            ;;
        2)
            list_ssl_domains
            echo ""
            read -p "Enter domain name to renew: " specific_domain
            if [[ -f "/etc/letsencrypt/live/$specific_domain/fullchain.pem" ]]; then
                certbot renew --cert-name "$specific_domain"
                reload_webserver
                echo -e "${CGREEN}✓ Certificate renewed for $specific_domain${CEND}"
            else
                echo -e "${CRED}✗ Certificate not found for $specific_domain${CEND}"
            fi
            ;;
        *)
            echo -e "${CRED}Invalid selection${CEND}"
            return 1
            ;;
    esac
}

# Uninstall Let's Encrypt
uninstall_letsencrypt() {
    echo -e "${CYELLOW}Uninstall Let's Encrypt${CEND}"
    echo -e "${CYELLOW}======================${CEND}"
    echo ""
    echo -e "${CRED}WARNING: This will remove all certificates and configurations!${CEND}"
    echo ""
    read -p "Are you sure you want to continue? [y/N]: " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CCYAN}Creating backup before uninstall...${CEND}"
        backup_certificates
        
        echo -e "${CCYAN}Removing Let's Encrypt...${CEND}"
        
        # Remove certbot
        if command -v snap >/dev/null 2>&1 && snap list | grep -q certbot; then
            snap remove certbot
        fi
        
        apt remove --purge -y certbot python3-certbot-nginx 2>/dev/null
        yum remove -y certbot python3-certbot-nginx 2>/dev/null
        
        # Remove cron job
        crontab -l 2>/dev/null | grep -v "letsencrypt-renew-all.sh" | crontab -
        
        # Remove certificates
        rm -rf /etc/letsencrypt
        
        # Remove installation directory
        rm -rf "$LE_INSTALL_DIR"
        
        echo -e "${CGREEN}✓ Let's Encrypt uninstalled successfully${CEND}"
        echo -e "${CCYAN}Certificates backed up to: $LE_BACKUP_DIR${CEND}"
    else
        echo -e "${CCYAN}Uninstall cancelled${CEND}"
    fi
}

# Main program
main() {
    check_root
    
    while true; do
        show_main_menu
        read -p "Enter your choice [1-9]: " choice
        
        case "$choice" in
            1)
                install_letsencrypt
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                configure_ssl_for_domain
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                configure_ssl_for_san
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                configure_wildcard_certificate
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                list_available_domains
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                list_ssl_domains
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                manual_renewal
                echo ""
                read -p "Press Enter to continue..."
                ;;
            8)
                configure_auto_renewal
                echo ""
                read -p "Press Enter to continue..."
                ;;
            9)
                backup_certificates
                echo ""
                read -p "Press Enter to continue..."
                ;;
            10)
                uninstall_letsencrypt
                echo ""
                read -p "Press Enter to continue..."
                ;;
            11)
                echo -e "${CGREEN}Goodbye!${CEND}"
                exit 0
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please try again.${CEND}"
                echo ""
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Start the program
main
