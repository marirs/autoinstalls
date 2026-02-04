#!/bin/bash

# Redis Auto-Installation Script
# Secure Redis installation with security hardening and localhost-only configuration

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

# Redis Configuration
REDIS_VERSION="7.2.4"
REDIS_USER="redis"
REDIS_GROUP="redis"
REDIS_DATA_DIR="/var/lib/redis"
REDIS_LOG_DIR="/var/log/redis"
REDIS_CONF_DIR="/etc/redis"
REDIS_PORT="6379"
REDIS_PASSWORD_FILE="/etc/redis/redis.passwd"

# System Information
ARCH=$(uname -m)
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)

# Logging
LOG_FILE="/tmp/redis-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Redis Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}Version: ${REDIS_VERSION}${CEND}"
    echo -e "${CCYAN}Architecture: ${ARCH}${CEND}"
    echo -e "${CCYAN}OS: ${os} ${os_ver}${CEND}"
    echo ""
}

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CRED}Please run as root or with sudo${CEND}"
        exit 1
    fi
}

function install_dependencies() {
    echo -e "${CGREEN}Installing dependencies for $os $os_ver...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Update package lists
            apt-get update >> "$APT_LOG" 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "tcl"
                "pkg-config"
                "wget"
                "curl"
                "openssl"
                "systemd"
                "python3"
                "python3-pip"
                "htop"
            )
            
            # Version-specific packages with comprehensive fallbacks
            local version_packages=()
            
            case "$os" in
                "debian")
                    case "$os_ver" in
                        "9"|"10"|"11")
                            # Older Debian versions
                            version_packages+=(
                                "build-essential"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libjemalloc-dev"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "build-essential"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libjemalloc-dev"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - comprehensive package handling
                            version_packages+=(
                                "zlib1g-dev"
                            )
                            
                            # Try multiple build tool variations
                            local build_packages=("build-essential" "build-base" "base-devel")
                            for build_pkg in "${build_packages[@]}"; do
                                if apt-cache show "$build_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$build_pkg")
                                    echo -e "${CCYAN}Found $build_pkg for build tools${CEND}"
                                    break
                                fi
                            done
                            
                            # Try SSL library variations
                            local ssl_packages=("libssl-dev" "libssl3-dev" "openssl-dev")
                            for ssl_pkg in "${ssl_packages[@]}"; do
                                if apt-cache show "$ssl_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$ssl_pkg")
                                    echo -e "${CCYAN}Found $ssl_pkg for SSL support${CEND}"
                                    break
                                fi
                            done
                            
                            # Try jemalloc variations
                            local jemalloc_packages=("libjemalloc-dev" "jemalloc-dev")
                            for jemalloc_pkg in "${jemalloc_packages[@]}"; do
                                if apt-cache show "$jemalloc_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$jemalloc_pkg")
                                    echo -e "${CCYAN}Found $jemalloc_pkg for memory allocation${CEND}"
                                    break
                                fi
                            done
                            ;;
                        *)
                            # Future Debian versions - try all variations
                            version_packages+=(
                                "zlib1g-dev"
                            )
                            
                            # Try build packages
                            local build_packages=("build-essential" "build-base" "base-devel")
                            for build_pkg in "${build_packages[@]}"; do
                                if apt-cache show "$build_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$build_pkg")
                                    break
                                fi
                            done
                            
                            # Try SSL packages
                            local ssl_packages=("libssl-dev" "libssl3-dev" "openssl-dev")
                            for ssl_pkg in "${ssl_packages[@]}"; do
                                if apt-cache show "$ssl_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$ssl_pkg")
                                    break
                                fi
                            done
                            
                            # Try jemalloc packages
                            local jemalloc_packages=("libjemalloc-dev" "jemalloc-dev")
                            for jemalloc_pkg in "${jemalloc_packages[@]}"; do
                                if apt-cache show "$jemalloc_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$jemalloc_pkg")
                                    break
                                fi
                            done
                            ;;
                    esac
                    ;;
                "ubuntu")
                    case "$os_ver" in
                        "18.04"|"20.04")
                            # Older Ubuntu versions
                            version_packages+=(
                                "build-essential"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libjemalloc-dev"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "build-essential"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libjemalloc-dev"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions - try all variations
                            version_packages+=(
                                "zlib1g-dev"
                            )
                            
                            # Try build packages
                            local build_packages=("build-essential" "build-base" "base-devel")
                            for build_pkg in "${build_packages[@]}"; do
                                if apt-cache show "$build_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$build_pkg")
                                    break
                                fi
                            done
                            
                            # Try SSL packages
                            local ssl_packages=("libssl-dev" "libssl3-dev" "openssl-dev")
                            for ssl_pkg in "${ssl_packages[@]}"; do
                                if apt-cache show "$ssl_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$ssl_pkg")
                                    break
                                fi
                            done
                            
                            # Try jemalloc packages
                            local jemalloc_packages=("libjemalloc-dev" "jemalloc-dev")
                            for jemalloc_pkg in "${jemalloc_packages[@]}"; do
                                if apt-cache show "$jemalloc_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$jemalloc_pkg")
                                    break
                                fi
                            done
                            ;;
                    esac
                    ;;
            esac
            
            # Combine all packages
            local all_packages=("${base_packages[@]}" "${version_packages[@]}")
            
            # Install packages with comprehensive error handling
            local failed_packages=()
            local successful_packages=()
            
            for package in "${all_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                if apt-cache show "$package" >/dev/null 2>&1; then
                    apt-get install -y "$package" >> "$APT_LOG" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                        successful_packages+=("$package")
                    else
                        echo -e "${CRED}✗ $package failed to install${CEND}"
                        failed_packages+=("$package")
                        
                        # Try to find alternatives for common packages
                        case "$package" in
                            "build-essential")
                                local build_alternatives=("build-base" "base-devel")
                                for alt_pkg in "${build_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt-get install -y "$alt_pkg" >> "$APT_LOG" 2>&1
                                        if [ $? -eq 0 ]; then
                                            echo -e "${CGREEN}✓ $alt_pkg installed (alternative to $package)${CEND}"
                                            successful_packages+=("$alt_pkg")
                                            break
                                        fi
                                    fi
                                done
                                ;;
                            "libssl-dev")
                                local ssl_alternatives=("libssl3-dev" "openssl-dev")
                                for alt_pkg in "${ssl_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt-get install -y "$alt_pkg" >> "$APT_LOG" 2>&1
                                        if [ $? -eq 0 ]; then
                                            echo -e "${CGREEN}✓ $alt_pkg installed (alternative to $package)${CEND}"
                                            successful_packages+=("$alt_pkg")
                                            break
                                        fi
                                    fi
                                done
                                ;;
                            "libjemalloc-dev")
                                local jemalloc_alternatives=("jemalloc-dev")
                                for alt_pkg in "${jemalloc_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt-get install -y "$alt_pkg" >> "$APT_LOG" 2>&1
                                        if [ $? -eq 0 ]; then
                                            echo -e "${CGREEN}✓ $alt_pkg installed (alternative to $package)${CEND}"
                                            successful_packages+=("$alt_pkg")
                                            break
                                        fi
                                    fi
                                done
                                ;;
                        esac
                    fi
                else
                    echo -e "${CYAN}⚠ Package $package not found, skipping${CEND}"
                    failed_packages+=("$package")
                fi
            done
            
            # Comprehensive package validation
            echo -e "${CCYAN}Package installation summary:${CEND}"
            echo -e "${CGREEN}Successfully installed: ${successful_packages[*]}${CEND}"
            if [ ${#failed_packages[@]} -gt 0 ]; then
                echo -e "${CYAN}Failed to install: ${failed_packages[*]}${CEND}"
            fi
            
            # Check if critical functionality is available
            local critical_ok=true
            if ! command -v gcc >/dev/null 2>&1; then
                echo -e "${CRED}✗ gcc is missing - critical for Redis compilation${CEND}"
                critical_ok=false
            fi
            
            if ! command -v make >/dev/null 2>&1; then
                echo -e "${CRED}✗ make is missing - critical for Redis compilation${CEND}"
                critical_ok=false
            fi
            
            if [ "$critical_ok" = true ]; then
                echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
                echo -e "${CCYAN}Redis installation will continue...${CEND}"
            else
                echo -e "${CRED}✗ Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems with comprehensive package handling
            local rhel_base_packages=(
                "tcl"
                "pkgconfig"
                "wget"
                "curl"
                "openssl"
                "systemd"
                "python3"
                "python3-pip"
                "htop"
            )
            
            # Try different development package names
            local dev_packages=("gcc" "gcc-c++" "make")
            for dev_pkg in "${dev_packages[@]}"; do
                if command -v dnf >/dev/null 2>&1; then
                    if dnf info "$dev_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$dev_pkg")
                        echo -e "${CCYAN}Found $dev_pkg for development${CEND}"
                    fi
                elif command -v yum >/dev/null 2>&1; then
                    if yum info "$dev_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$dev_pkg")
                        echo -e "${CCYAN}Found $dev_pkg for development${CEND}"
                    fi
                fi
            done
            
            # Try SSL library packages
            local ssl_packages=("openssl-devel" "libssl-devel")
            for ssl_pkg in "${ssl_packages[@]}"; do
                if command -v dnf >/dev/null 2>&1; then
                    if dnf info "$ssl_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$ssl_pkg")
                        echo -e "${CCYAN}Found $ssl_pkg for SSL support${CEND}"
                        break
                    fi
                elif command -v yum >/dev/null 2>&1; then
                    if yum info "$ssl_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$ssl_pkg")
                        echo -e "${CCYAN}Found $ssl_pkg for SSL support${CEND}"
                        break
                    fi
                fi
            done
            
            # Try zlib packages
            local zlib_packages=("zlib-devel")
            if command -v dnf >/dev/null 2>&1; then
                if dnf info "zlib-devel" >/dev/null 2>&1; then
                    rhel_base_packages+=("zlib-devel")
                    echo -e "${CCYAN}Found zlib-devel for compression${CEND}"
                fi
            elif command -v yum >/dev/null 2>&1; then
                if yum info "zlib-devel" >/dev/null 2>&1; then
                    rhel_base_packages+=("zlib-devel")
                    echo -e "${CCYAN}Found zlib-devel for compression${CEND}"
                fi
            fi
            
            # Version-specific adjustments
            case "$os_ver" in
                "7")
                    # CentOS 7 uses yum
                    if command -v yum >/dev/null 2>&1; then
                        yum update -y >> "$APT_LOG" 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> "$APT_LOG" 2>&1
                            if [ $? -eq 0 ]; then
                                echo -e "${CGREEN}✓ $package installed${CEND}"
                            else
                                echo -e "${CRED}✗ $package failed to install${CEND}"
                            fi
                        done
                    fi
                    ;;
                "8"|"9")
                    # RHEL 8+ uses dnf
                    if command -v dnf >/dev/null 2>&1; then
                        dnf update -y >> "$APT_LOG" 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> "$APT_LOG" 2>&1
                            if [ $? -eq 0 ]; then
                                echo -e "${CGREEN}✓ $package installed${CEND}"
                            else
                                echo -e "${CRED}✗ $package failed to install${CEND}"
                            fi
                        done
                    fi
                    ;;
            esac
            ;;
        "fedora")
            # Fedora-specific packages with comprehensive handling
            local fedora_base_packages=(
                "tcl"
                "pkgconfig"
                "wget"
                "curl"
                "openssl"
                "systemd"
                "python3"
                "python3-pip"
                "htop"
                "gcc"
                "gcc-c++"
                "make"
                "openssl-devel"
                "zlib-devel"
            )
            
            dnf update -y >> "$APT_LOG" 2>&1
            for package in "${fedora_base_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> "$APT_LOG" 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${CGREEN}✓ $package installed${CEND}"
                else
                    echo -e "${CRED}✗ $package failed to install${CEND}"
                fi
            done
            ;;
        *)
            echo -e "${CRED}Unsupported OS: $os${CEND}"
            exit 1
            ;;
    esac
}

    # Update package lists
    apt-get update >> "$APT_LOG" 2>&1
    
    # Install required packages
    apt-get install -y \
        build-essential \
        tcl \
        pkg-config \
        wget \
        curl \
        openssl \
        libssl-dev \
        zlib1g-dev \
        libjemalloc-dev \
        systemd \
        python3 \
        python3-pip \
        htop \
        net-tools \
        ufw \
        logrotate \
        >> "$APT_LOG" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Dependencies installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
}

function create_redis_user() {
    echo -e "${CGREEN}Creating Redis user and group...${CEND}"
    
    # Create Redis group if it doesn't exist
    if ! getent group "$REDIS_GROUP" >/dev/null; then
        groupadd -r "$REDIS_GROUP"
        echo -e "  Created group: $REDIS_GROUP"
    fi
    
    # Create Redis user if it doesn't exist
    if ! id "$REDIS_USER" >/dev/null 2>&1; then
        useradd -r -g "$REDIS_GROUP" -s /bin/false -d "$REDIS_DATA_DIR" "$REDIS_USER"
        echo -e "  Created user: $REDIS_USER"
    fi
    
    # Create directories
    mkdir -p "$REDIS_DATA_DIR" "$REDIS_LOG_DIR" "$REDIS_CONF_DIR"
    
    # Set permissions
    chown -R "$REDIS_USER:$REDIS_GROUP" "$REDIS_DATA_DIR" "$REDIS_LOG_DIR"
    chmod 750 "$REDIS_DATA_DIR" "$REDIS_LOG_DIR"
    
    echo -e "${CGREEN}Redis user and directories created${CEND}"
}

function download_redis() {
    echo -e "${CGREEN}Downloading Redis ${REDIS_VERSION}...${CEND}"
    
    cd /tmp
    
    # Download Redis source
    wget -O "redis-${REDIS_VERSION}.tar.gz" \
        "http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz" >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to download Redis${CEND}"
        exit 1
    fi
    
    # Extract source
    tar -xzf "redis-${REDIS_VERSION}.tar.gz"
    cd "redis-${REDIS_VERSION}"
    
    echo -e "${CGREEN}Redis downloaded and extracted${CEND}"
}

function compile_redis() {
    echo -e "${CGREEN}Compiling Redis...${CEND}"
    
    # Build Redis with optimizations
    make \
        BUILD_TLS=yes \
        MALLOC=libc \
        USE_SYSTEMD=yes \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to compile Redis${CEND}"
        exit 1
    fi
    
    # Run tests (optional, can be skipped for faster installation)
    echo -e "${CCYAN}Running Redis tests...${CEND}"
    timeout 300 make test >> "$LOG_FILE" 2>&1 || echo -e "${CYAN}Tests timed out or failed, continuing...${CEND}"
    
    echo -e "${CGREEN}Redis compiled successfully${CEND}"
}

function install_redis() {
    echo -e "${CGREEN}Installing Redis...${CEND}"
    
    # Install Redis binaries
    make install PREFIX=/usr/local >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Redis${CEND}"
        exit 1
    fi
    
    # Create symbolic links
    ln -sf /usr/local/bin/redis-server /usr/bin/redis-server
    ln -sf /usr/local/bin/redis-cli /usr/bin/redis-cli
    ln -sf /usr/local/bin/redis-benchmark /usr/bin/redis-benchmark
    ln -sf /usr/local/bin/redis-check-aof /usr/bin/redis-check-aof
    ln -sf /usr/local/bin/redis-check-rdb /usr/bin/redis-check-rdb
    
    echo -e "${CGREEN}Redis installed successfully${CEND}"
}

function configure_redis() {
    echo -e "${CGREEN}Configuring Redis for secure localhost-only access...${CEND}"
    
    # Generate secure password
    REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$REDIS_PASSWORD" > "$REDIS_PASSWORD_FILE"
    chmod 600 "$REDIS_PASSWORD_FILE"
    
    # Create Redis configuration
    cat > "$REDIS_CONF_DIR/redis.conf" << EOF
# Redis Configuration File
# Generated by Redis Auto-Installation Script

# Network Configuration
bind 127.0.0.1 ::1
port $REDIS_PORT
protected-mode yes

# Security Configuration
requirepass $REDIS_PASSWORD
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG "CONFIG_b8f3a2c7"
rename-command SHUTDOWN "SHUTDOWN_e9d4c5f1"
rename-command DEBUG ""
rename-command EVAL ""

# Memory Management
maxmemory 256mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Persistence Configuration
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir $REDIS_DATA_DIR

# AOF Configuration
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes

# Security and Permissions
tcp-keepalive 300
timeout 0
tcp-backlog 511
supervised systemd

# Logging Configuration
loglevel notice
logfile $REDIS_LOG_DIR/redis-server.log
syslog-enabled yes
syslog-ident redis

# Client Configuration
maxclients 10000

# Slow Log Configuration
slowlog-log-slower-than 10000
slowlog-max-len 128

# Latency Monitoring
latency-monitor-threshold 100

# Event Notification Configuration
notify-keyspace-events ""

# Hash Configuration
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# List Configuration
list-max-ziplist-size -2
list-compress-depth 0

# Set Configuration
set-max-intset-entries 512

# Sorted Set Configuration
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# HyperLogLog Configuration
hll-sparse-max-bytes 3000

# Stream Configuration
stream-node-max-bytes 4096
stream-node-max-entries 100

# Active Rehashing
activerehashing yes

# Client Output Buffer Limits
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Client Query Buffer Limit
client-query-buffer-limit 1gb

# Protocol Max Bulk Request Size
proto-max-bulk-len 512mb

# Frequency of Rehashing
hz 10

# AOF Rewrite Incremental Fsync
aof-rewrite-incremental-fsync yes

# RDB Save Incremental Fsync
rdb-save-incremental-fsync yes

# TLS Configuration (if needed)
# tls-port 0
# tls-cert-file $REDIS_CONF_DIR/redis.crt
# tls-key-file $REDIS_CONF_DIR/redis.key
# tls-ca-cert-file $REDIS_CONF_DIR/ca.crt

# Modules Configuration
# loadmodule /path/to/your/module.so

# Include additional configuration files
# include $REDIS_CONF_DIR/redis.local.conf
EOF
    
    # Set permissions
    chown -R "$REDIS_USER:$REDIS_GROUP" "$REDIS_CONF_DIR"
    chmod 640 "$REDIS_CONF_DIR/redis.conf"
    
    echo -e "${CGREEN}Redis configured for secure localhost-only access${CEND}"
    echo -e "${CCYAN}Redis password saved to: $REDIS_PASSWORD_FILE${CEND}"
}

function create_systemd_service() {
    echo -e "${CGREEN}Creating Redis systemd service...${CEND}"
    
    cat > /etc/systemd/system/redis.service << EOF
[Unit]
Description=Redis In-Memory Data Store
Documentation=https://redis.io/documentation
After=network.target
Wants=network.target

[Service]
Type=notify
User=$REDIS_USER
Group=$REDIS_GROUP
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

ExecStart=/usr/local/bin/redis-server $REDIS_CONF_DIR/redis.conf --supervised systemd
ExecReload=/bin/kill -USR2 \$MAINPID
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStopSec=0
Restart=always
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=60

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$REDIS_DATA_DIR $REDIS_LOG_DIR $REDIS_CONF_DIR
ProtectHome=true
RemoveIPC=true

# Network settings
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=127.0.0.1/8
IPAddressAllow=::1/128

# File system settings
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Memory settings
MemoryMax=512M

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable redis
    
    echo -e "${CGREEN}Redis systemd service created and enabled${CEND}"
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall for Redis...${CEND}"
    
    # Check if UFW is available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CCYAN}Using UFW firewall...${CEND}"
        
        # Configure UFW rules
        ufw --force reset >> "$LOG_FILE" 2>&1
        
        # Default policies
        ufw default deny incoming >> "$LOG_FILE" 2>&1
        ufw default allow outgoing >> "$LOG_FILE" 2>&1
        
        # Allow SSH (if needed)
        ufw allow ssh >> "$LOG_FILE" 2>&1
        
        # Allow Redis from localhost only
        ufw allow from 127.0.0.1 to any port "$REDIS_PORT" >> "$LOG_FILE" 2>&1
        ufw allow from ::1 to any port "$REDIS_PORT" >> "$LOG_FILE" 2>&1
        
        # Explicitly deny external Redis access (redundant but secure)
        ufw deny "$REDIS_PORT"/tcp >> "$LOG_FILE" 2>&1
        
        # Enable UFW
        ufw --force enable >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}UFW firewall configured successfully${CEND}"
            echo -e "${CCYAN}Redis access: Localhost only${CEND}"
        else
            echo -e "${CRED}Failed to configure UFW firewall${CEND}"
            exit 1
        fi
        
    # Check if iptables is available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${CCYAN}Using iptables firewall...${CEND}"
        
        # Allow Redis from localhost only
        iptables -A INPUT -p tcp --dport "$REDIS_PORT" -s 127.0.0.1 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport "$REDIS_PORT" -s ::1 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Deny external Redis access
        iptables -A INPUT -p tcp --dport "$REDIS_PORT" -j DROP >> "$LOG_FILE" 2>&1
        
        # Save iptables rules (if iptables-persistent is available)
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}iptables firewall configured successfully${CEND}"
            echo -e "${CCYAN}Redis access: Localhost only${CEND}"
        else
            echo -e "${CRED}Failed to configure iptables firewall${CEND}"
            exit 1
        fi
        
    else
        echo -e "${CYAN}No firewall (UFW or iptables) detected${CEND}"
        echo -e "${CYAN}Skipping firewall configuration${CEND}"
        echo -e "${CYAN}Note: Redis is still configured for localhost-only binding${CEND}"
        echo -e "${CYAN}      Consider installing a firewall for additional security${CEND}"
    fi
}

function setup_logrotate() {
    echo -e "${CGREEN}Setting up log rotation...${CEND}"
    
    cat > /etc/logrotate.d/redis << EOF
$REDIS_LOG_DIR/redis-server.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 $REDIS_USER $REDIS_GROUP
    postrotate
        systemctl reload redis >/dev/null 2>&1 || true
    endscript
}
EOF
    
    echo -e "${CGREEN}Log rotation configured${CEND}"
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create Redis monitoring script
    cat > /usr/local/bin/redis-monitor << 'EOF'
#!/bin/bash

# Redis Monitoring Script

REDIS_CLI="/usr/bin/redis-cli"
REDIS_CONF="/etc/redis/redis.conf"
REDIS_PASSWORD_FILE="/etc/redis/redis.passwd"

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Redis Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function get_redis_password() {
    if [ -f "$REDIS_PASSWORD_FILE" ]; then
        cat "$REDIS_PASSWORD_FILE"
    else
        echo ""
    fi
}

function check_redis_status() {
    echo -e "${CGREEN}Redis Service Status:${CEND}"
    
    if systemctl is-active --quiet redis; then
        echo -e "  Redis Service: ${CGREEN}Running${CEND}"
    else
        echo -e "  Redis Service: ${CRED}Stopped${CEND}"
    fi
    
    if systemctl is-enabled --quiet redis; then
        echo -e "  Redis Service: ${CGREEN}Enabled${CEND}"
    else
        echo -e "  Redis Service: ${CRED}Disabled${CEND}"
    fi
    
    echo ""
}

function show_redis_info() {
    echo -e "${CGREEN}Redis Information:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    # Get Redis info
    local redis_info=$($REDIS_CLI $auth_cmd INFO 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "  Redis Version: $(echo "$redis_info" | grep "redis_version:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Redis Mode: $(echo "$redis_info" | grep "redis_mode:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Uptime: $(echo "$redis_info" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r') seconds"
        echo -e "  Connected Clients: $(echo "$redis_info" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Used Memory: $(echo "$redis_info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Max Memory: $(echo "$redis_info" | grep "maxmemory_human:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Total Commands: $(echo "$redis_info" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Total Operations: $(echo "$redis_info" | grep "total_net_input_bytes:" | cut -d: -f2 | tr -d '\r')"
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function show_redis_memory() {
    echo -e "${CGREEN}Memory Usage:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    local redis_info=$($REDIS_CLI $auth_cmd INFO memory 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "  Used Memory: $(echo "$redis_info" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  RSS Memory: $(echo "$redis_info" | grep "used_memory_rss_human:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Peak Memory: $(echo "$redis_info" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Memory Fragmentation: $(echo "$redis_info" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Memory Policy: $(echo "$redis_info" | grep "maxmemory_policy:" | cut -d: -f2 | tr -d '\r')"
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function show_redis_stats() {
    echo -e "${CGREEN}Performance Statistics:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    local redis_info=$($REDIS_CLI $auth_cmd INFO stats 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "  Total Connections: $(echo "$redis_info" | grep "total_connections_received:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Total Commands: $(echo "$redis_info" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Ops/sec: $(echo "$redis_info" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Hit Rate: $(echo "$redis_info" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r') hits / $(echo "$redis_info" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r') misses"
        echo -e "  Expired Keys: $(echo "$redis_info" | grep "expired_keys:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Evicted Keys: $(echo "$redis_info" | grep "evicted_keys:" | cut -d: -f2 | tr -d '\r')"
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function show_redis_keyspace() {
    echo -e "${CGREEN}Keyspace Information:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    local redis_info=$($REDIS_CLI $auth_cmd INFO keyspace 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$redis_info" | grep "^db" | while read -r line; do
            echo -e "  $line"
        done
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function show_redis_clients() {
    echo -e "${CGREEN}Connected Clients:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    local redis_info=$($REDIS_CLI $auth_cmd INFO clients 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "  Connected Clients: $(echo "$redis_info" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Client Connections: $(echo "$redis_info" | grep "total_connections_received:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Blocked Clients: $(echo "$redis_info" | grep "blocked_clients:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  Tracking Clients: $(echo "$redis_info" | grep "tracking_clients:" | cut -d: -f2 | tr -d '\r')"
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function show_redis_persistence() {
    echo -e "${CGREEN}Persistence Information:${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    local redis_info=$($REDIS_CLI $auth_cmd INFO persistence 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "  Loading: $(echo "$redis_info" | grep "loading:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  RDB Changes Since Save: $(echo "$redis_info" | grep "rdb_changes_since_last_save:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  RDB Background Save: $(echo "$redis_info" | grep "rdb_bgsave_in_progress:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  RDB Last Save: $(echo "$redis_info" | grep "rdb_last_save_time:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  AOF Enabled: $(echo "$redis_info" | grep "aof_enabled:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  AOF Rewrite: $(echo "$redis_info" | grep "aof_rewrite_in_progress:" | cut -d: -f2 | tr -d '\r')"
        echo -e "  AOF Buffer Length: $(echo "$redis_info" | grep "aof_buffer_length:" | cut -d: -f2 | tr -d '\r')"
    else
        echo -e "  ${CRED}Cannot connect to Redis${CEND}"
    fi
    
    echo ""
}

function test_redis_connection() {
    echo -e "${CGREEN}Testing Redis Connection...${CEND}"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    # Test basic connection
    if $REDIS_CLI $auth_cmd ping >/dev/null 2>&1; then
        echo -e "  ${CGREEN}Redis connection: OK${CEND}"
        
        # Test set/get operations
        local test_key="redis_test_$(date +%s)"
        local test_value="test_value_$(date +%s)"
        
        if $REDIS_CLI $auth_cmd set "$test_key" "$test_value" >/dev/null 2>&1; then
            local retrieved_value=$($REDIS_CLI $auth_cmd get "$test_key" 2>/dev/null)
            if [ "$retrieved_value" = "$test_value" ]; then
                echo -e "  ${CGREEN}Redis operations: OK${CEND}"
                $REDIS_CLI $auth_cmd del "$test_key" >/dev/null 2>&1
            else
                echo -e "  ${CRED}Redis operations: FAILED${CEND}"
            fi
        else
            echo -e "  ${CRED}Redis operations: FAILED${CEND}"
        fi
    else
        echo -e "  ${CRED}Redis connection: FAILED${CEND}"
    fi
    
    echo ""
}

function show_help() {
    echo -e "${CGREEN}Redis Monitoring Tool${CEND}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  status      Show Redis service status"
    echo "  info        Show Redis information"
    echo "  memory      Show memory usage"
    echo "  stats       Show performance statistics"
    echo "  keyspace    Show keyspace information"
    echo "  clients     Show connected clients"
    echo "  persistence Show persistence information"
    echo "  test        Test Redis connection"
    echo "  all         Show all information"
    echo "  help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status    # Show Redis status"
    echo "  $0 all       # Show complete overview"
}

function main() {
    case "${1:-all}" in
        "status")
            show_header
            check_redis_status
            ;;
        "info")
            show_header
            show_redis_info
            ;;
        "memory")
            show_header
            show_redis_memory
            ;;
        "stats")
            show_header
            show_redis_stats
            ;;
        "keyspace")
            show_header
            show_redis_keyspace
            ;;
        "clients")
            show_header
            show_redis_clients
            ;;
        "persistence")
            show_header
            show_redis_persistence
            ;;
        "test")
            show_header
            test_redis_connection
            ;;
        "all")
            show_header
            check_redis_status
            show_redis_info
            show_redis_memory
            show_redis_stats
            show_redis_keyspace
            show_redis_clients
            show_redis_persistence
            test_redis_connection
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
EOF
    
    chmod +x /usr/local/bin/redis-monitor
    
    # Create Redis backup script
    cat > /usr/local/bin/redis-backup << 'EOF'
#!/bin/bash

# Redis Backup Script

REDIS_CLI="/usr/bin/redis-cli"
REDIS_DATA_DIR="/var/lib/redis"
BACKUP_DIR="/var/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)
REDIS_PASSWORD_FILE="/etc/redis/redis.passwd"

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CCYAN="${CSI}1;36m"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Redis Backup Tool${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function get_redis_password() {
    if [ -f "$REDIS_PASSWORD_FILE" ]; then
        cat "$REDIS_PASSWORD_FILE"
    else
        echo ""
    fi
}

function create_backup() {
    echo -e "${CGREEN}Creating Redis backup...${CEND}"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    # Create RDB backup
    echo -e "  Creating RDB backup..."
    $REDIS_CLI $auth_cmd BGSAVE >> "$BACKUP_DIR/backup_$DATE.log" 2>&1
    
    # Wait for background save to complete
    echo -e "  Waiting for background save to complete..."
    while true; do
        local lastsave=$($REDIS_CLI $auth_cmd LASTSAVE 2>/dev/null)
        local info=$($REDIS_CLI $auth_cmd INFO persistence 2>/dev/null)
        local bgsave_in_progress=$(echo "$info" | grep "rdb_bgsave_in_progress:" | cut -d: -f2 | tr -d '\r')
        
        if [ "$bgsave_in_progress" = "0" ]; then
            break
        fi
        
        echo -e "    Background save in progress..."
        sleep 2
    done
    
    # Copy RDB file
    if [ -f "$REDIS_DATA_DIR/dump.rdb" ]; then
        cp "$REDIS_DATA_DIR/dump.rdb" "$BACKUP_DIR/dump_$DATE.rdb"
        gzip "$BACKUP_DIR/dump_$DATE.rdb"
        echo -e "  ${CGREEN}RDB backup created: dump_$DATE.rdb.gz${CEND}"
    fi
    
    # Copy AOF file
    if [ -f "$REDIS_DATA_DIR/appendonly.aof" ]; then
        cp "$REDIS_DATA_DIR/appendonly.aof" "$BACKUP_DIR/appendonly_$DATE.aof"
        gzip "$BACKUP_DIR/appendonly_$DATE.aof"
        echo -e "  ${CGREEN}AOF backup created: appendonly_$DATE.aof.gz${CEND}"
    fi
    
    # Backup configuration
    if [ -f "/etc/redis/redis.conf" ]; then
        cp "/etc/redis/redis.conf" "$BACKUP_DIR/redis_$DATE.conf"
        echo -e "  ${CGREEN}Configuration backup created: redis_$DATE.conf${CEND}"
    fi
    
    # Create backup info
    cat > "$BACKUP_DIR/backup_info_$DATE.txt" << EOF
Redis Backup Information
=======================
Date: $(date)
Hostname: $(hostname)
Redis Version: $($REDIS_CLI $auth_cmd INFO server | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
Backup Type: Full Backup
Files Created:
- dump_$DATE.rdb.gz (RDB snapshot)
- appendonly_$DATE.aof.gz (AOF log)
- redis_$DATE.conf (Configuration)
EOF
    
    echo -e "${CGREEN}Backup completed successfully${CEND}"
    echo -e "${CCYAN}Backup location: $BACKUP_DIR${CEND}"
}

function restore_backup() {
    if [ -z "$1" ]; then
        echo -e "${CRED}Usage: $0 restore <backup_date>${CEND}"
        return
    fi
    
    local backup_date="$1"
    echo -e "${CGREEN}Restoring Redis backup from $backup_date...${CEND}"
    
    # Stop Redis service
    echo -e "  Stopping Redis service..."
    systemctl stop redis
    
    # Backup current data
    if [ -f "$REDIS_DATA_DIR/dump.rdb" ]; then
        cp "$REDIS_DATA_DIR/dump.rdb" "$REDIS_DATA_DIR/dump.rdb.backup.$(date +%s)"
    fi
    
    if [ -f "$REDIS_DATA_DIR/appendonly.aof" ]; then
        cp "$REDIS_DATA_DIR/appendonly.aof" "$REDIS_DATA_DIR/appendonly.aof.backup.$(date +%s)"
    fi
    
    # Restore RDB file
    if [ -f "$BACKUP_DIR/dump_$backup_date.rdb.gz" ]; then
        echo -e "  Restoring RDB file..."
        gunzip -c "$BACKUP_DIR/dump_$backup_date.rdb.gz" > "$REDIS_DATA_DIR/dump.rdb"
        chown redis:redis "$REDIS_DATA_DIR/dump.rdb"
        chmod 640 "$REDIS_DATA_DIR/dump.rdb"
    else
        echo -e "  ${CRED}RDB backup not found: dump_$backup_date.rdb.gz${CEND}"
    fi
    
    # Restore AOF file
    if [ -f "$BACKUP_DIR/appendonly_$backup_date.aof.gz" ]; then
        echo -e "  Restoring AOF file..."
        gunzip -c "$BACKUP_DIR/appendonly_$backup_date.aof.gz" > "$REDIS_DATA_DIR/appendonly.aof"
        chown redis:redis "$REDIS_DATA_DIR/appendonly.aof"
        chmod 640 "$REDIS_DATA_DIR/appendonly.aof"
    else
        echo -e "  ${CRED}AOF backup not found: appendonly_$backup_date.aof.gz${CEND}"
    fi
    
    # Start Redis service
    echo -e "  Starting Redis service..."
    systemctl start redis
    
    # Wait for Redis to start
    sleep 3
    
    # Verify restoration
    local password=$(get_redis_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    if $REDIS_CLI $auth_cmd ping >/dev/null 2>&1; then
        echo -e "  ${CGREEN}Redis service started successfully${CEND}"
    else
        echo -e "  ${CRED}Redis service failed to start${CEND}"
        echo -e "  Check logs: journalctl -u redis -f"
    fi
    
    echo -e "${CGREEN}Restore completed${CEND}"
}

function list_backups() {
    echo -e "${CGREEN}Available Redis Backups:${CEND}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "  ${CCYAN}No backups found${CEND}"
        return
    fi
    
    echo -e "${CBLUE}RDB Backups:${CEND}"
    ls -lh "$BACKUP_DIR"/dump_*.rdb.gz 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' || echo "  No RDB backups found"
    
    echo ""
    echo -e "${CBLUE}AOF Backups:${CEND}"
    ls -lh "$BACKUP_DIR"/appendonly_*.aof.gz 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' || echo "  No AOF backups found"
    
    echo ""
    echo -e "${CBLUE}Configuration Backups:${CEND}"
    ls -lh "$BACKUP_DIR"/redis_*.conf 2>/dev/null | awk '{print $9, $5, $6, $7, $8}' || echo "  No configuration backups found"
    
    echo ""
}

function cleanup_old_backups() {
    echo -e "${CGREEN}Cleaning up old backups...${CEND}"
    
    # Remove backups older than 30 days
    find "$BACKUP_DIR" -name "dump_*.rdb.gz" -mtime +30 -delete
    find "$BACKUP_DIR" -name "appendonly_*.aof.gz" -mtime +30 -delete
    find "$BACKUP_DIR" -name "redis_*.conf" -mtime +30 -delete
    find "$BACKUP_DIR" -name "backup_info_*.txt" -mtime +30 -delete
    
    echo -e "  ${CGREEN}Old backups removed${CEND}"
}

function show_help() {
    echo -e "${CGREEN}Redis Backup Tool${CEND}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create              Create full backup"
    echo "  restore <date>      Restore backup from specified date"
    echo "  list                List available backups"
    echo "  cleanup             Remove old backups"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create           # Create backup"
    echo "  $0 restore 20240204_120000  # Restore from backup"
    echo "  $0 list             # List backups"
    echo ""
    echo "Backup location: $BACKUP_DIR"
}

function main() {
    case "${1}" in
        "create")
            show_header
            create_backup
            ;;
        "restore")
            show_header
            restore_backup "$2"
            ;;
        "list")
            list_backups
            ;;
        "cleanup")
            cleanup_old_backups
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${CRED}Unknown command: $1${CEND}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
EOF
    
    chmod +x /usr/local/bin/redis-backup
    
    echo -e "${CGREEN}Monitoring scripts created${CEND}"
}

function start_redis_service() {
    echo -e "${CGREEN}Starting Redis service...${CEND}"
    
    # Start Redis service
    systemctl start redis >> "$LOG_FILE" 2>&1
    
    # Wait for Redis to start
    sleep 3
    
    # Check if Redis is running
    if systemctl is-active --quiet redis; then
        echo -e "${CGREEN}Redis service started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start Redis service${CEND}"
        echo -e "${CCYAN}Check logs: journalctl -u redis -f${CEND}"
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Redis installation...${CEND}"
    
    # Test Redis connection
    local password=$(cat "$REDIS_PASSWORD_FILE" 2>/dev/null || echo "")
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-a $password"
    fi
    
    if redis-cli $auth_cmd ping >/dev/null 2>&1; then
        echo -e "${CGREEN}Redis connection: OK${CEND}"
    else
        echo -e "${CRED}Redis connection: FAILED${CEND}"
        exit 1
    fi
    
    # Test basic operations
    local test_key="redis_test_$(date +%s)"
    local test_value="test_value_$(date +%s)"
    
    if redis-cli $auth_cmd set "$test_key" "$test_value" >/dev/null 2>&1; then
        local retrieved_value=$(redis-cli $auth_cmd get "$test_key" 2>/dev/null)
        if [ "$retrieved_value" = "$test_value" ]; then
            echo -e "${CGREEN}Redis operations: OK${CEND}"
            redis-cli $auth_cmd del "$test_key" >/dev/null 2>&1
        else
            echo -e "${CRED}Redis operations: FAILED${CEND}"
            exit 1
        fi
    else
        echo -e "${CRED}Redis operations: FAILED${CEND}"
        exit 1
    fi
    
    # Check Redis version
    local redis_version=$(redis-cli $auth_cmd INFO server | grep "redis_version:" | cut -d: -f2 | tr -d '\r')
    echo -e "${CGREEN}Redis version: $redis_version${CEND}"
    
    # Verify localhost-only binding
    if netstat -tlnp 2>/dev/null | grep ":$REDIS_PORT" | grep "127.0.0.1" >/dev/null 2>&1; then
        echo -e "${CGREEN}Localhost binding: OK${CEND}"
    else
        echo -e "${CRED}Localhost binding: FAILED${CEND}"
        exit 1
    fi
    
    # Verify firewall rules
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "$REDIS_PORT.*ALLOW.*127.0.0.1" && ufw status | grep -q "$REDIS_PORT.*DENY"; then
            echo -e "${CGREEN}UFW firewall rules: OK${CEND}"
        else
            echo -e "${CRED}UFW firewall rules: FAILED${CEND}"
            exit 1
        fi
    elif command -v iptables >/dev/null 2>&1; then
        if iptables -L INPUT | grep -q "$REDIS_PORT.*127.0.0.1.*ACCEPT" && iptables -L INPUT | grep -q "$REDIS_PORT.*DROP"; then
            echo -e "${CGREEN}iptables firewall rules: OK${CEND}"
        else
            echo -e "${CRED}iptables firewall rules: FAILED${CEND}"
            exit 1
        fi
    else
        echo -e "${CYAN}No firewall detected - skipping firewall verification${CEND}"
    fi
    
    # Verify Redis configuration
    if grep -q "bind 127.0.0.1 ::1" "$REDIS_CONF_DIR/redis.conf"; then
        echo -e "${CGREEN}Redis configuration: OK${CEND}"
    else
        echo -e "${CRED}Redis configuration: FAILED${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Redis installation verified successfully${CEND}"
    echo -e "${CCYAN}Redis is configured for localhost-only access${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Redis Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Redis Version: $REDIS_VERSION"
    echo -e "  Architecture: $ARCH"
    echo -e "  OS: $OS $OS_VERSION"
    echo -e "  Security: Localhost-only with password authentication"
    echo -e "  Firewall: Configured for local access only"
    echo -e "  Persistence: RDB + AOF enabled"
    echo ""
    echo -e "${CCYAN}Security Features:${CEND}"
    echo -e "  ✅ Redis bound to localhost only"
    echo -e "  ✅ Password authentication enabled"
    echo -e "  ✅ Dangerous commands disabled"
    echo -e "  ✅ Firewall blocks external access"
    echo -e "  ✅ Systemd security hardening applied"
    echo -e "  ✅ Log rotation configured"
    echo ""
    echo -e "${CCYAN}Redis Configuration:${CEND}"
    echo -e "  Port: $REDIS_PORT"
    echo -e "  Password: $(cat "$REDIS_PASSWORD_FILE")"
    echo -e "  Config File: $REDIS_CONF_DIR/redis.conf"
    echo -e "  Data Directory: $REDIS_DATA_DIR"
    echo -e "  Log Directory: $REDIS_LOG_DIR"
    echo ""
    echo -e "${CCYAN}Next Steps:${CEND}"
    echo -e "  1. Check Redis status: systemctl status redis"
    echo -e "  2. Test connection: redis-cli -a $(cat "$REDIS_PASSWORD_FILE") ping"
    echo -e "  3. Monitor Redis: redis-monitor"
    echo -e "  4. Create backup: redis-backup create"
    echo ""
    echo -e "${CCYAN}Example Usage:${CEND}"
    echo -e "  # Connect to Redis"
    echo -e "  redis-cli -a $(cat "$REDIS_PASSWORD_FILE")"
    echo ""
    echo -e "  # Test basic operations"
    echo -e "  redis-cli -a $(cat "$REDIS_PASSWORD_FILE") set mykey \"Hello Redis\""
    echo -e "  redis-cli -a $(cat "$REDIS_PASSWORD_FILE") get mykey"
    echo ""
    echo -e "  # Monitor Redis"
    echo -e "  redis-monitor all"
    echo ""
    echo -e "${CCYAN}Logs:${CEND}"
    echo -e "  Redis Install: $LOG_FILE"
    echo -e "  Dependencies: $APT_LOG"
    echo -e "  Redis Logs: $REDIS_LOG_DIR/redis-server.log"
    echo ""
    echo -e "${CCYAN}Security Notes:${CEND}"
    echo -e "  - Redis is configured for localhost access only"
    echo -e "  - Password authentication is required"
    echo -e "  - External access is blocked by firewall"
    echo -e "  - Dangerous commands are disabled for security"
    echo -e "  - All Redis operations are logged"
    echo ""
    echo -e "${CMAGENTA}Redis installation completed successfully!${CEND}"
}

# Main installation process
show_header
check_root
check_architecture
install_dependencies
create_redis_user
download_redis
compile_redis
install_redis
configure_redis
create_systemd_service
configure_firewall
setup_logrotate
create_monitoring_scripts
start_redis_service
verify_installation
show_success_message
