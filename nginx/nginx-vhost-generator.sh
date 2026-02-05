#!/bin/bash

# Nginx Virtual Host Generator
# Interactive tool for generating and managing Nginx virtual hosts

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"
CYELLOW="${CSI}1;33m"

# Configuration
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
NGINX_CONF="/etc/nginx/nginx.conf"
LOG_FILE="/tmp/nginx-vhost-generator.log"

# Default values
DEFAULT_SERVER_NAME="example.com"
DEFAULT_ROOT_PATH="/var/www/example.com/html"
DEFAULT_SSL_CERT_PATH="/etc/ssl/certs"
DEFAULT_SSL_KEY_PATH="/etc/ssl/private"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Nginx Virtual Host Generator${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function check_nginx_installation() {
    echo -e "${CCYAN}Checking Nginx installation...${CEND}"
    
    if ! command -v nginx >/dev/null 2>&1; then
        echo -e "${CRED}✗ Nginx is not installed${CEND}"
        echo -e "${CYAN}Please install Nginx first using: ${CEND}cd nginx && sudo ./nginx-install.sh"
        exit 1
    fi
    
    if [ ! -d "$NGINX_SITES_AVAILABLE" ]; then
        echo -e "${CRED}✗ Nginx sites-available directory not found: $NGINX_SITES_AVAILABLE${CEND}"
        echo -e "${CYAN}Please ensure Nginx is properly installed${CEND}"
        exit 1
    fi
    
    if [ ! -d "$NGINX_SITES_ENABLED" ]; then
        echo -e "${CRED}✗ Nginx sites-enabled directory not found: $NGINX_SITES_ENABLED${CEND}"
        echo -e "${CYAN}Please ensure Nginx is properly installed${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}✓ Nginx installation verified${CEND}"
    echo -e "${CCYAN}Sites available: $NGINX_SITES_AVAILABLE${CEND}"
    echo -e "${CCYAN}Sites enabled: $NGINX_SITES_ENABLED${CEND}"
    echo ""
}

function get_available_ips() {
    echo -e "${CCYAN}Detecting available IP addresses...${CEND}"
    
    local ipv4_ips=()
    local ipv6_ips=()
    
    # Get IPv4 addresses
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            ipv4_ips+=("$line")
        fi
    done < <(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1')
    
    # Get IPv6 addresses
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            ipv6_ips+=("$line")
        fi
    done < <(ip -6 addr show | grep -oP '(?<=inet6\s)[\da-f:]+' | grep -v '::1' | grep -v '^fe80')
    
    # Store IPs in global arrays
    AVAILABLE_IPV4=("${ipv4_ips[@]}")
    AVAILABLE_IPV6=("${ipv6_ips[@]}")
}

function select_ip_address() {
    echo ""
    echo -e "${CCYAN}Select IP address for the virtual host:${CEND}"
    echo "  0. Listen on all addresses (default)"
    
    for i in "${!AVAILABLE_IPV4[@]}"; do
        echo "  $((i+1)). ${AVAILABLE_IPV4[i]} (IPv4)"
    done
    
    local ipv6_offset=${#AVAILABLE_IPV4[@]}
    for i in "${!AVAILABLE_IPV6[@]}"; do
        echo "  $((ipv6_offset+i+1)). ${AVAILABLE_IPV6[i]} (IPv6)"
    done
    
    local total_ips=$((${#AVAILABLE_IPV4[@]} + ${#AVAILABLE_IPV6[@]}))
    local max_choice=$total_ips
    
    while true; do
        read -p "Enter your choice (0-$max_choice): " ip_choice
        
        if [[ "$ip_choice" =~ ^[0-9]+$ ]] && [ "$ip_choice" -ge 0 ] && [ "$ip_choice" -le $max_choice ]; then
            break
        else
            echo -e "${CRED}Invalid choice. Please enter a number between 0 and $max_choice${CEND}"
        fi
    done
    
    if [ "$ip_choice" -eq 0 ]; then
        SELECTED_IP=""
        IP_TYPE="all"
    elif [ "$ip_choice" -le ${#AVAILABLE_IPV4[@]} ]; then
        SELECTED_IP="${AVAILABLE_IPV4[$((ip_choice-1))]}"
        IP_TYPE="ipv4"
    else
        local ipv6_index=$((ip_choice - ${#AVAILABLE_IPV4[@]} - 1))
        SELECTED_IP="${AVAILABLE_IPV6[$ipv6_index]}"
        IP_TYPE="ipv6"
    fi
    
    echo -e "${CGREEN}Selected IP: ${SELECTED_IP:-All addresses}${CEND}"
}

function get_user_input() {
    echo -e "${CCYAN}Virtual Host Configuration${CEND}"
    echo ""
    
    # Server name
    read -p "Enter server name (domain): " server_name
    if [ -z "$server_name" ]; then
        server_name="$DEFAULT_SERVER_NAME"
    fi
    
    # Alternative names
    read -p "Enter alternative server names (space separated, optional): " server_aliases
    
    # Document root
    read -p "Enter document root path [$DEFAULT_ROOT_PATH]: " document_root
    if [ -z "$document_root" ]; then
        document_root="$DEFAULT_ROOT_PATH"
    fi
    
    # SSL configuration
    echo ""
    echo -e "${CCYAN}SSL Configuration:${CEND}"
    read -p "Enable SSL/TLS? (y/n): " enable_ssl
    
    if [[ "$enable_ssl" =~ ^[Yy]$ ]]; then
        SSL_ENABLED=true
        
        # SSL certificate paths
        read -p "SSL certificate path [$DEFAULT_SSL_CERT_PATH/$server_name.crt]: " ssl_cert_path
        if [ -z "$ssl_cert_path" ]; then
            ssl_cert_path="$DEFAULT_SSL_CERT_PATH/$server_name.crt"
        fi
        
        read -p "SSL private key path [$DEFAULT_SSL_KEY_PATH/$server_name.key]: " ssl_key_path
        if [ -z "$ssl_key_path" ]; then
            ssl_key_path="$DEFAULT_SSL_KEY_PATH/$server_name.key"
        fi
        
        # HTTPS only
        read -p "Enable HTTPS only (redirect HTTP to HTTPS)? (y/n): " https_only
        if [[ "$https_only" =~ ^[Yy]$ ]]; then
            HTTPS_ONLY=true
        else
            HTTPS_ONLY=false
        fi
    else
        SSL_ENABLED=false
        HTTPS_ONLY=false
    fi
    
    # PHP support
    echo ""
    read -p "Enable PHP support? (y/n): " enable_php
    if [[ "$enable_php" =~ ^[Yy]$ ]]; then
        PHP_ENABLED=true
    else
        PHP_ENABLED=false
    fi
    
    # Security headers
    echo ""
    read -p "Enable security headers? (y/n): " enable_security
    if [[ "$enable_security" =~ ^[Yy]$ ]]; then
        SECURITY_ENABLED=true
    else
        SECURITY_ENABLED=false
    fi
    
    # Rate limiting
    read -p "Enable rate limiting? (y/n): " enable_rate_limit
    if [[ "$enable_rate_limit" =~ ^[Yy]$ ]]; then
        RATE_LIMIT_ENABLED=true
        read -p "Rate limit requests per second (default 10): " rate_limit_rps
        if [ -z "$rate_limit_rps" ]; then
            rate_limit_rps="10"
        fi
        read -p "Rate limit burst (default 20): " rate_limit_burst
        if [ -z "$rate_limit_burst" ]; then
            rate_limit_burst="20"
        fi
    else
        RATE_LIMIT_ENABLED=false
    fi
}

function generate_vhost_config() {
    local vhost_file="$NGINX_SITES_AVAILABLE/$server_name"
    
    echo -e "${CCYAN}Generating virtual host configuration...${CEND}"
    
    # Create the virtual host file
    cat > "$vhost_file" << EOF
# Virtual Host: $server_name
# Generated on: $(date)
# Document Root: $document_root

EOF

    # Add HTTP server block (if not HTTPS only)
    if [ "$HTTPS_ONLY" = false ]; then
        cat >> "$vhost_file" << EOF
server {
    listen 80;
EOF
        
        if [ "$IP_TYPE" = "ipv4" ]; then
            echo "    listen $SELECTED_IP:80;" >> "$vhost_file"
        elif [ "$IP_TYPE" = "ipv6" ]; then
            echo "    listen [$SELECTED_IP]:80;" >> "$vhost_file"
        fi
        
        cat >> "$vhost_file" << EOF
    server_name $server_name$([ -n "$server_aliases" ] && echo " $server_aliases");
    
    # Security headers
EOF
        
        if [ "$SECURITY_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF
        fi
        
        if [ "$RATE_LIMIT_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    
    # Rate limiting
    limit_req zone=\$server_name burst=$rate_limit_burst nodelay;
EOF
        fi
        
        cat >> "$vhost_file" << EOF
    
    # Root directory
    root $document_root;
    index index.html index.htm index.php;
    
    # Logging
    access_log /var/log/nginx/${server_name}_access.log;
    error_log /var/log/nginx/${server_name}_error.log;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ =404;
    }
EOF
        
        if [ "$PHP_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
EOF
        fi
        
        cat >> "$vhost_file" << EOF
    
    # Security: Hide Nginx version
    server_tokens off;
    
    # Security: Block common exploits
    location ~* \.(aspx|asp|php|jsp|cgi)$ {
        deny all;
    }
}
EOF
    fi
    
    # Add HTTPS server block if SSL is enabled
    if [ "$SSL_ENABLED" = true ]; then
        cat >> "$vhost_file" << EOF

# HTTPS server block
server {
    listen 443 ssl http2;
EOF
        
        if [ "$IP_TYPE" = "ipv4" ]; then
            echo "    listen $SELECTED_IP:443 ssl http2;" >> "$vhost_file"
        elif [ "$IP_TYPE" = "ipv6" ]; then
            echo "    listen [$SELECTED_IP]:443 ssl http2;" >> "$vhost_file"
        fi
        
        cat >> "$vhost_file" << EOF
    server_name $server_name$([ -n "$server_aliases" ] && echo " $server_aliases");
    
    # SSL configuration
    ssl_certificate $ssl_cert_path;
    ssl_certificate_key $ssl_key_path;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;
    
    # Modern SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Security headers
EOF
        
        if [ "$SECURITY_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
EOF
        fi
        
        if [ "$RATE_LIMIT_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    
    # Rate limiting
    limit_req zone=\$server_name burst=$rate_limit_burst nodelay;
EOF
        fi
        
        cat >> "$vhost_file" << EOF
    
    # Root directory
    root $document_root;
    index index.html index.htm index.php;
    
    # Logging
    access_log /var/log/nginx/${server_name}_access.log;
    error_log /var/log/nginx/${server_name}_error.log;
    
    # Main location block
    location / {
        try_files \$uri \$uri/ =404;
    }
EOF
        
        if [ "$PHP_ENABLED" = true ]; then
            cat >> "$vhost_file" << EOF
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
EOF
        fi
        
        cat >> "$vhost_file" << EOF
    
    # Security: Hide Nginx version
    server_tokens off;
    
    # Security: Block common exploits
    location ~* \.(aspx|asp|php|jsp|cgi)$ {
        deny all;
    }
}
EOF
        
        # Add HTTP to HTTPS redirect if HTTPS only
        if [ "$HTTPS_ONLY" = true ]; then
            cat >> "$vhost_file" << EOF

# HTTP to HTTPS redirect
server {
    listen 80;
EOF
            if [ "$IP_TYPE" = "ipv4" ]; then
                echo "    listen $SELECTED_IP:80;" >> "$vhost_file"
            elif [ "$IP_TYPE" = "ipv6" ]; then
                echo "    listen [$SELECTED_IP]:80;" >> "$vhost_file"
            fi
            
            cat >> "$vhost_file" << EOF
    server_name $server_name$([ -n "$server_aliases" ] && echo " $server_aliases");
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}
EOF
        fi
    fi
    
    echo -e "${CGREEN}✓ Virtual host configuration generated: $vhost_file${CEND}"
}

function create_document_root() {
    if [ ! -d "$document_root" ]; then
        echo -e "${CCYAN}Creating document root directory...${CEND}"
        mkdir -p "$document_root"
        chown -R www-data:www-data "$document_root"
        chmod -R 755 "$document_root"
        
        # Create a default index file
        cat > "$document_root/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $server_name</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 1rem;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to $server_name</h1>
        <p>This virtual host is working correctly!</p>
        <p>Generated on: $(date)</p>
EOF
        
        if [ "$SSL_ENABLED" = true ]; then
            cat >> "$document_root/index.html" << EOF
        <p>🔒 SSL/TLS is enabled</p>
EOF
        fi
        
        cat >> "$document_root/index.html" << EOF
    </div>
</body>
</html>
EOF
        
        echo -e "${CGREEN}✓ Document root created: $document_root${CEND}"
    else
        echo -e "${CYAN}Document root already exists: $document_root${CEND}"
    fi
}

function test_nginx_config() {
    echo -e "${CCYAN}Testing Nginx configuration...${CEND}"
    
    if nginx -t >> "$LOG_FILE" 2>&1; then
        echo -e "${CGREEN}✓ Nginx configuration test passed${CEND}"
        return 0
    else
        echo -e "${CRED}✗ Nginx configuration test failed${CEND}"
        echo -e "${CYAN}Check the log file: $LOG_FILE${CEND}"
        return 1
    fi
}

function reload_nginx() {
    echo -e "${CCYAN}Reloading Nginx...${CEND}"
    
    if systemctl reload nginx >> "$LOG_FILE" 2>&1; then
        echo -e "${CGREEN}✓ Nginx reloaded successfully${CEND}"
        return 0
    else
        echo -e "${CRED}✗ Failed to reload Nginx${CEND}"
        echo -e "${CYAN}Check the log file: $LOG_FILE${CEND}"
        return 1
    fi
}

function list_available_vhosts() {
    echo -e "${CCYAN}Available virtual hosts:${CEND}"
    echo ""
    
    local vhosts=()
    while IFS= read -r -d '' file; do
        vhosts+=("$(basename "$file")")
    done < <(find "$NGINX_SITES_AVAILABLE" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
    
    if [ ${#vhosts[@]} -eq 0 ]; then
        echo -e "${CYAN}No virtual hosts found in $NGINX_SITES_AVAILABLE${CEND}"
        return 1
    fi
    
    for i in "${!vhosts[@]}"; do
        local status="Disabled"
        if [ -L "$NGINX_SITES_ENABLED/${vhosts[i]}" ]; then
            status="Enabled"
        fi
        echo "  $((i+1)). ${vhosts[i]} - $status"
    done
    
    return 0
}

function list_disabled_vhosts() {
    echo -e "${CCYAN}Disabled virtual hosts (available but not enabled):${CEND}"
    echo ""
    
    local disabled_vhosts=()
    local enabled_vhosts=()
    
    # Get enabled vhosts
    while IFS= read -r -d '' file; do
        if [ -L "$file" ]; then
            enabled_vhosts+=("$(basename "$file")")
        fi
    done < <(find "$NGINX_SITES_ENABLED" -maxdepth 1 -type l -print0 2>/dev/null)
    
    # Get available vhosts and find disabled ones
    local index=1
    while IFS= read -r -d '' file; do
        local vhost_name="$(basename "$file")"
        local is_enabled=false
        
        for enabled in "${enabled_vhosts[@]}"; do
            if [ "$vhost_name" = "$enabled" ]; then
                is_enabled=true
                break
            fi
        done
        
        if [ "$is_enabled" = false ]; then
            disabled_vhosts+=("$vhost_name")
            echo "  $index. $vhost_name"
            ((index++))
        fi
    done < <(find "$NGINX_SITES_AVAILABLE" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
    
    if [ ${#disabled_vhosts[@]} -eq 0 ]; then
        echo -e "${CYAN}No disabled virtual hosts found${CEND}"
        return 1
    fi
    
    return 0
}

function enable_vhost() {
    list_disabled_vhosts
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo ""
    read -p "Enter the number of the virtual host to enable (0 to cancel): " choice
    
    if [ "$choice" = "0" ]; then
        echo -e "${CYAN}Cancelled${CEND}"
        return 0
    fi
    
    local disabled_vhosts=()
    local enabled_vhosts=()
    
    # Get enabled vhosts
    while IFS= read -r -d '' file; do
        if [ -L "$file" ]; then
            enabled_vhosts+=("$(basename "$file")")
        fi
    done < <(find "$NGINX_SITES_ENABLED" -maxdepth 1 -type l -print0 2>/dev/null)
    
    # Get disabled vhosts
    local index=1
    while IFS= read -r -d '' file; do
        local vhost_name="$(basename "$file")"
        local is_enabled=false
        
        for enabled in "${enabled_vhosts[@]}"; do
            if [ "$vhost_name" = "$enabled" ]; then
                is_enabled=true
                break
            fi
        done
        
        if [ "$is_enabled" = false ]; then
            disabled_vhosts+=("$vhost_name")
            if [ "$index" -eq "$choice" ]; then
                selected_vhost="$vhost_name"
                break
            fi
            ((index++))
        fi
    done < <(find "$NGINX_SITES_AVAILABLE" -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
    
    if [ -z "$selected_vhost" ]; then
        echo -e "${CRED}Invalid selection${CEND}"
        return 1
    fi
    
    echo -e "${CCYAN}Enabling virtual host: $selected_vhost${CEND}"
    
    # Create symbolic link
    if ln -s "../sites-available/$selected_vhost" "$NGINX_SITES_ENABLED/$selected_vhost" 2>> "$LOG_FILE"; then
        echo -e "${CGREEN}✓ Virtual host enabled: $selected_vhost${CEND}"
        
        # Test and reload Nginx
        if test_nginx_config; then
            reload_nginx
            echo -e "${CGREEN}✓ Virtual host is now active${CEND}"
        else
            echo -e "${CRED}✗ Configuration test failed, removing symlink${CEND}"
            rm -f "$NGINX_SITES_ENABLED/$selected_vhost"
            return 1
        fi
    else
        echo -e "${CRED}✗ Failed to enable virtual host${CEND}"
        return 1
    fi
}

function generate_vhost() {
    echo -e "${CCYAN}=== Generate New Virtual Host ===${CEND}"
    echo ""
    
    get_available_ips
    select_ip_address
    get_user_input
    generate_vhost_config
    create_document_root
    
    # Test configuration
    if test_nginx_config; then
        reload_nginx
        echo ""
        echo -e "${CGREEN}✓ Virtual host generated successfully!${CEND}"
        echo -e "${CCYAN}Configuration file: $NGINX_SITES_AVAILABLE/$server_name${CEND}"
        echo -e "${CCYAN}Document root: $document_root${CEND}"
        
        if [ "$SSL_ENABLED" = true ]; then
            echo -e "${CYAN}SSL Certificate: $ssl_cert_path${CEND}"
            echo -e "${CYAN}SSL Private Key: $ssl_key_path${CEND}"
        fi
        
        echo ""
        echo -e "${CYAN}To enable this virtual host, run this script again and choose option 2${CEND}"
    else
        echo -e "${CRED}✗ Failed to generate virtual host${CEND}"
        echo -e "${CYAN}Check the log file: $LOG_FILE${CEND}"
        return 1
    fi
}

function show_menu() {
    echo -e "${CBLUE}Main Menu:${CEND}"
    echo "  1. Generate new virtual host"
    echo "  2. Enable available virtual host"
    echo "  3. List all virtual hosts"
    echo "  4. Test Nginx configuration"
    echo "  5. Exit"
    echo ""
}

function main() {
    show_header
    check_nginx_installation
    
    while true; do
        show_menu
        read -p "Enter your choice (1-5): " choice
        
        case $choice in
            1)
                echo ""
                generate_vhost
                echo ""
                ;;
            2)
                echo ""
                enable_vhost
                echo ""
                ;;
            3)
                echo ""
                list_available_vhosts
                echo ""
                ;;
            4)
                echo ""
                test_nginx_config && reload_nginx
                echo ""
                ;;
            5)
                echo -e "${CGREEN}Goodbye!${CEND}"
                exit 0
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please enter a number between 1 and 5${CEND}"
                echo ""
                ;;
        esac
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${CRED}This script requires root privileges${CEND}"
    echo -e "${CYAN}Please run with sudo: sudo $0${CEND}"
    exit 1
fi

# Create log file
touch "$LOG_FILE"

# Run main function
main "$@"
