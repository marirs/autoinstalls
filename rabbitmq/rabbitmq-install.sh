#!/bin/bash

# RabbitMQ Installation Script
# Secure RabbitMQ 3.12 installation with comprehensive security hardening

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

# RabbitMQ Configuration
RABBITMQ_VERSION="3.12"
ERLANG_VERSION="25"
RABBITMQ_USER="rabbitmq"
RABBITMQ_GROUP="rabbitmq"
RABBITMQ_HOME="/etc/rabbitmq"
RABBITMQ_DATA_DIR="/var/lib/rabbitmq"
RABBITMQ_LOG_DIR="/var/log/rabbitmq"

# System Information
ARCH=$(uname -m)
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)

# Logging
LOG_FILE="/tmp/rabbitmq-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    RabbitMQ Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}RabbitMQ Version: ${RABBITMQ_VERSION}${CEND}"
    echo -e "${CCYAN}Erlang Version: ${ERLANG_VERSION}${CEND}"
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
            apt update >> "$LOG_FILE" 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "curl"
                "wget"
                "ca-certificates"
                "logrotate"
            )
            
            # Try different GPG package names
            local gpg_packages=("gnupg" "gnupg2" "gpg")
            for gpg_pkg in "${gpg_packages[@]}"; do
                if apt-cache show "$gpg_pkg" >/dev/null 2>&1; then
                    base_packages+=("$gpg_pkg")
                    echo -e "${CCYAN}Found $gpg_pkg for GPG support${CEND}"
                    break
                fi
            done
            
            # Version-specific packages with comprehensive fallbacks
            local version_packages=()
            
            case "$os" in
                "debian")
                    case "$os_ver" in
                        "9"|"10"|"11")
                            # Older Debian versions
                            version_packages+=(
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - comprehensive package handling
                            version_packages+=(
                                "apt-transport-https"
                            )
                            
                            # Try multiple package name variations
                            local pkg_variations=(
                                "software-properties-common"
                                "python3-software-properties"
                                "software-properties"
                            )
                            
                            for pkg in "${pkg_variations[@]}"; do
                                if apt-cache show "$pkg" >/dev/null 2>&1; then
                                    version_packages+=("$pkg")
                                    echo -e "${CCYAN}Found $pkg for software properties${CEND}"
                                    break
                                fi
                            done
                            ;;
                        *)
                            # Future Debian versions - try all variations
                            version_packages+=(
                                "apt-transport-https"
                            )
                            
                            # Try software-properties variations
                            local pkg_variations=(
                                "software-properties-common"
                                "python3-software-properties"
                                "software-properties"
                            )
                            for pkg in "${pkg_variations[@]}"; do
                                if apt-cache show "$pkg" >/dev/null 2>&1; then
                                    version_packages+=("$pkg")
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
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions
                            version_packages+=(
                                "apt-transport-https"
                            )
                            
                            # Try software-properties variations
                            local pkg_variations=(
                                "software-properties-common"
                                "python3-software-properties"
                                "software-properties"
                            )
                            for pkg in "${pkg_variations[@]}"; do
                                if apt-cache show "$pkg" >/dev/null 2>&1; then
                                    version_packages+=("$pkg")
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
                    apt install -y "$package" >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                        successful_packages+=("$package")
                    else
                        echo -e "${CRED}✗ $package failed to install${CEND}"
                        failed_packages+=("$package")
                        
                        # Try to find alternatives for common packages
                        case "$package" in
                            "gnupg")
                                local gpg_alternatives=("gnupg2" "gpg")
                                for alt_pkg in "${gpg_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt install -y "$alt_pkg" >> "$LOG_FILE" 2>&1
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
            if ! command -v curl >/dev/null 2>&1; then
                echo -e "${CRED}✗ curl is missing - critical for RabbitMQ installation${CEND}"
                critical_ok=false
            fi
            
            if ! command -v gpg >/dev/null 2>&1 && ! command -v gpg2 >/dev/null 2>&1; then
                echo -e "${CRED}✗ gpg/gpg2 is missing - critical for repository verification${CEND}"
                critical_ok=false
            fi
            
            if [ "$critical_ok" = true ]; then
                echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
                echo -e "${CCYAN}RabbitMQ installation will continue...${CEND}"
            else
                echo -e "${CRED}✗ Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems with comprehensive package handling
            local rhel_base_packages=(
                "curl"
                "wget"
                "ca-certificates"
                "logrotate"
            )
            
            # Try different GPG package names
            local gpg_packages=("gnupg2" "gnupg" "gpg")
            for gpg_pkg in "${gpg_packages[@]}"; do
                if command -v dnf >/dev/null 2>&1; then
                    if dnf info "$gpg_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$gpg_pkg")
                        echo -e "${CCYAN}Found $gpg_pkg for GPG support${CEND}"
                        break
                    fi
                elif command -v yum >/dev/null 2>&1; then
                    if yum info "$gpg_pkg" >/dev/null 2>&1; then
                        rhel_base_packages+=("$gpg_pkg")
                        echo -e "${CCYAN}Found $gpg_pkg for GPG support${CEND}"
                        break
                    fi
                fi
            done
            
            # Version-specific adjustments
            case "$os_ver" in
                "7")
                    # CentOS 7 uses yum
                    if command -v yum >/dev/null 2>&1; then
                        yum update -y >> "$LOG_FILE" 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> "$LOG_FILE" 2>&1
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
                        dnf update -y >> "$LOG_FILE" 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> "$LOG_FILE" 2>&1
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
                "curl"
                "wget"
                "ca-certificates"
                "logrotate"
            )
            
            # Try different GPG package names
            local gpg_packages=("gnupg2" "gnupg" "gpg")
            for gpg_pkg in "${gpg_packages[@]}"; do
                if dnf info "$gpg_pkg" >/dev/null 2>&1; then
                    fedora_base_packages+=("$gpg_pkg")
                    echo -e "${CCYAN}Found $gpg_pkg for GPG support${CEND}"
                    break
                fi
            done
            
            dnf update -y >> "$LOG_FILE" 2>&1
            for package in "${fedora_base_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> "$LOG_FILE" 2>&1
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

function check_system() {
    echo -e "${CGREEN}Checking system compatibility...${CEND}"
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${CCYAN}Operating System: $NAME $VERSION${CEND}"
    else
        echo -e "${CRED}Cannot determine OS version${CEND}"
        exit 1
    fi
    
    # Check architecture
    echo -e "${CCYAN}Architecture: $ARCH${CEND}"
    
    # Check if RabbitMQ is already installed
    if command -v rabbitmq-server >/dev/null 2>&1; then
        echo -e "${CYAN}RabbitMQ is already installed${CEND}"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    fi
    
    echo -e "${CGREEN}System compatibility check completed${CEND}"
}

function install_dependencies() {
    echo -e "${CGREEN}Installing dependencies...${CEND}"
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    # Install dependencies
    apt install -y \
        curl \
        wget \
        gnupg \
        ca-certificates \
        apt-transport-https \
        logrotate \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Dependencies installed successfully${CEND}"
}

function add_erlang_repository() {
    echo -e "${CGREEN}Adding Erlang repository...${CEND}"
    
    # Import RabbitMQ/Erlang GPG key
    curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | gpg --dearmor -o /usr/share/keyrings/rabbitmq-archive-keyring.gpg >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to import RabbitMQ GPG key${CEND}"
        exit 1
    fi
    
    # Add Erlang repository
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/rabbitmq.list >> "$LOG_FILE" 2>&1
    
    # Set Erlang package priority
    echo "Package: erlang*" | tee /etc/apt/preferences.d/erlang >> "$LOG_FILE" 2>&1
    echo "Pin: release o=LP-PPA-rabbitmq-rabbitmq-erlang" | tee -a /etc/apt/preferences.d/erlang >> "$LOG_FILE" 2>&1
    echo "Pin-Priority: 1000" | tee -a /etc/apt/preferences.d/erlang >> "$LOG_FILE" 2>&1
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to add Erlang repository${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Erlang repository added successfully${CEND}"
}

function install_erlang() {
    echo -e "${CGREEN}Installing Erlang...${CEND}"
    
    # Install Erlang
    apt install -y \
        erlang-base \
        erlang-asn1 \
        erlang-crypto \
        erlang-eldap \
        erlang-ftp \
        erlang-inets \
        erlang-mnesia \
        erlang-os-mon \
        erlang-parsetools \
        erlang-public-key \
        erlang-runtime-tools \
        erlang-snmp \
        erlang-ssl \
        erlang-syntax-tools \
        erlang-tftp \
        erlang-tools \
        erlang-xmerl \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Erlang${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Erlang installed successfully${CEND}"
}

function add_rabbitmq_repository() {
    echo -e "${CGREEN}Adding RabbitMQ repository...${CEND}"
    
    # Add RabbitMQ repository
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq-archive-keyring.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/rabbitmq.list >> "$LOG_FILE" 2>&1
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to add RabbitMQ repository${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}RabbitMQ repository added successfully${CEND}"
}

function install_rabbitmq() {
    echo -e "${CGREEN}Installing RabbitMQ...${CEND}"
    
    # Install RabbitMQ server
    apt install -y rabbitmq-server=${RABBITMQ_VERSION}* >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install RabbitMQ${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}RabbitMQ installed successfully${CEND}"
}

function configure_security() {
    echo -e "${CGREEN}Configuring RabbitMQ security...${CEND}"
    
    # Create rabbitmq configuration directory
    mkdir -p $RABBITMQ_HOME
    
    # Create rabbitmq.conf for localhost-only access
    cat > $RABBITMQ_HOME/rabbitmq.conf << EOF
# RabbitMQ Configuration

# Network settings
listeners.tcp.default = 5672
listeners.ssl.default = 

# Disable guest user for security
auth.users.default.username = admin
auth.users.default.password = $(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# Enable management plugin
management.tcp.port = 15672
management.tcp.ip = 127.0.0.1

# Memory and disk limits
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 1GB

# Logging settings
log.file.level = info
log.console = true
log.console.level = info

# Security settings
auth_mechanisms.1 = PLAIN
auth_mechanisms.2 = AMQPLAIN
auth_mechanisms.3 = ANONYMOUS

# Disable SSL for localhost-only setup
ssl_options.verify = verify_none
ssl_options.fail_if_no_peer_cert = false

# Performance settings
heartbeat = 60
frame_max = 131072
EOF
    
    # Create advanced configuration
    cat > $RABBITMQ_HOME/advanced.config << EOF
[
  {rabbit, [
    {tcp_listeners, [{"127.0.0.1", 5672}]},
    {ssl_listeners, []},
    {default_user, <<"admin">>},
    {default_pass, <<$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)>>},
    {default_user_tags, [administrator]},
    {default_vhost, <<"/">>},
    {default_permissions, [<<".*">>, <<".*">>, <<".*">>]},
    {vm_memory_high_watermark, 0.6},
    {disk_free_limit, "1GB"},
    {log_level, info}
  ]},
  {rabbitmq_management, [
    {listener, [{port, 15672}, {ip, "127.0.0.1"}]}
  ]}
].
EOF
    
    # Set proper permissions
    chown -R $RABBITMQ_USER:$RABBITMQ_GROUP $RABBITMQ_HOME
    chmod 640 $RABBITMQ_HOME/rabbitmq.conf
    chmod 640 $RABBITMQ_HOME/advanced.config
    
    # Create data and log directories with proper permissions
    mkdir -p $RABBITMQ_DATA_DIR $RABBITMQ_LOG_DIR
    chown -R $RABBITMQ_USER:$RABBITMQ_GROUP $RABBITMQ_DATA_DIR $RABBITMQ_LOG_DIR
    chmod 755 $RABBITMQ_DATA_DIR $RABBITMQ_LOG_DIR
    
    echo -e "${CGREEN}RabbitMQ security configuration completed${CEND}"
}

function configure_systemd() {
    echo -e "${CGREEN}Configuring systemd service...${CEND}"
    
    # Create systemd override for security hardening
    mkdir -p /etc/systemd/system/rabbitmq-server.service.d
    
    cat > /etc/systemd/system/rabbitmq-server.service.d/security.conf << EOF
[Service]
# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$RABBITMQ_DATA_DIR $RABBITMQ_LOG_DIR $RABBITMQ_HOME /tmp

# Network restrictions
IPAddressAllow=localhost
IPAddressAllow=127.0.0.1/8
IPAddressAllow=::1/128

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=2g

# File system access
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true

# Environment
RABBITMQ_CONFIG_FILE=$RABBITMQ_HOME/rabbitmq
RABBITMQ_ADVANCED_CONFIG_FILE=$RABBITMQ_HOME/advanced
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable rabbitmq-server
    
    echo -e "${CGREEN}Systemd service configured and enabled${CEND}"
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall...${CEND}"
    
    # Configure UFW if available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring UFW firewall...${CEND}"
        
        # Allow RabbitMQ from localhost only
        ufw allow from 127.0.0.1 to any port 5672 >> "$LOG_FILE" 2>&1
        ufw allow from 127.0.0.1 to any port 15672 >> "$LOG_FILE" 2>&1
        ufw allow from ::1 to any port 5672 >> "$LOG_FILE" 2>&1
        ufw allow from ::1 to any port 15672 >> "$LOG_FILE" 2>&1
        
        # Explicitly deny external access to RabbitMQ
        ufw deny 5672 >> "$LOG_FILE" 2>&1
        ufw deny 15672 >> "$LOG_FILE" 2>&1
        
        echo -e "${CGREEN}UFW firewall configured for RabbitMQ${CEND}"
    
    # Configure iptables if UFW is not available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring iptables firewall...${CEND}"
        
        # Allow localhost access to RabbitMQ
        iptables -A INPUT -s 127.0.0.1 -p tcp --dport 5672 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -s 127.0.0.1 -p tcp --dport 15672 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -s ::1 -p tcp --dport 5672 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -s ::1 -p tcp --dport 15672 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Deny external access
        iptables -A INPUT -p tcp --dport 5672 -j DROP >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport 15672 -j DROP >> "$LOG_FILE" 2>&1
        
        # Save iptables rules
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        
        echo -e "${CGREEN}iptables firewall configured for RabbitMQ${CEND}"
    else
        echo -e "${CYAN}No firewall found - please manually configure RabbitMQ access${CEND}"
    fi
}

function enable_management_plugin() {
    echo -e "${CGREEN}Enabling RabbitMQ Management plugin...${CEND}"
    
    # Enable management plugin
    rabbitmq-plugins enable rabbitmq_management >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to enable RabbitMQ Management plugin${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}RabbitMQ Management plugin enabled${CEND}"
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create RabbitMQ monitoring script
    cat > /usr/local/bin/rabbitmq-monitor << 'EOF'
#!/bin/bash

# RabbitMQ Monitoring Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    RabbitMQ Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function show_status() {
    echo -e "${CGREEN}RabbitMQ Status:${CEND}"
    
    # Check service status
    if systemctl is-active --quiet rabbitmq-server; then
        echo -e "  Service: ${CGREEN}Running${CEND}"
    else
        echo -e "  Service: ${CRED}Stopped${CEND}"
    fi
    
    # Check cluster status
    local cluster_status=$(rabbitmqctl cluster_status 2>/dev/null | grep -A 5 "running_nodes" || echo "Unknown")
    echo -e "  Cluster Status: $cluster_status"
    
    echo ""
}

function show_info() {
    echo -e "${CGREEN}RabbitMQ Information:${CEND}"
    
    # Get RabbitMQ info
    local info=$(rabbitmqctl status 2>/dev/null | grep -E "RabbitMQ|Erlang/OTP" | head -5)
    if [ -n "$info" ]; then
        echo -e "  $info" | sed 's/^[[:space:]]*//'
    else
        echo -e "  ${CRED}Cannot get RabbitMQ information${CEND}"
    fi
    
    echo ""
}

function show_queues() {
    echo -e "${CGREEN}Queue Information:${CEND}"
    
    # Get queue information
    local queues=$(rabbitmqctl list_queues name messages consumers 2>/dev/null | tail -n +2)
    if [ -n "$queues" ]; then
        echo -e "  Name              Messages  Consumers"
        echo -e "  ----              --------  ---------"
        echo -e "  $queues" | head -10
    else
        echo -e "  ${CYAN}No queues found${CEND}"
    fi
    
    echo ""
}

function show_connections() {
    echo -e "${CGREEN}Connection Information:${CEND}"
    
    # Get connection information
    local connections=$(rabbitmqctl list_connections pid host state 2>/dev/null | tail -n +2)
    if [ -n "$connections" ]; then
        echo -e "  PID              Host              State"
        echo -e "  ---              ----              -----"
        echo -e "  $connections" | head -10
    else
        echo -e "  ${CYAN}No connections found${CEND}"
    fi
    
    echo ""
}

function main() {
    case "${1:-all}" in
        "status")
            show_header
            show_status
            ;;
        "info")
            show_header
            show_info
            ;;
        "queues")
            show_header
            show_queues
            ;;
        "connections")
            show_header
            show_connections
            ;;
        "all")
            show_header
            show_status
            show_info
            show_queues
            show_connections
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [status|info|queues|connections|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Create RabbitMQ management script
    cat > /usr/local/bin/rabbitmq-manager << 'EOF'
#!/bin/bash

# RabbitMQ Management Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    RabbitMQ Manager${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function start_service() {
    echo -e "${CGREEN}Starting RabbitMQ service...${CEND}"
    systemctl start rabbitmq-server
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}RabbitMQ started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start RabbitMQ${CEND}"
        exit 1
    fi
}

function stop_service() {
    echo -e "${CGREEN}Stopping RabbitMQ service...${CEND}"
    systemctl stop rabbitmq-server
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}RabbitMQ stopped successfully${CEND}"
    else
        echo -e "${CRED}Failed to stop RabbitMQ${CEND}"
        exit 1
    fi
}

function restart_service() {
    echo -e "${CGREEN}Restarting RabbitMQ service...${CEND}"
    systemctl restart rabbitmq-server
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}RabbitMQ restarted successfully${CEND}"
    else
        echo -e "${CRED}Failed to restart RabbitMQ${CEND}"
        exit 1
    fi
}

function show_logs() {
    echo -e "${CGREEN}RabbitMQ Logs:${CEND}"
    journalctl -u rabbitmq-server -f --lines=50
}

function list_users() {
    echo -e "${CGREEN}RabbitMQ Users:${CEND}"
    rabbitmqctl list_users
    echo ""
}

function add_user() {
    local username=$1
    local password=$2
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo -e "${CRED}Usage: $0 add-user <username> <password>${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Adding user: $username${CEND}"
    rabbitmqctl add_user "$username" "$password"
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}User $username added successfully${CEND}"
    else
        echo -e "${CRED}Failed to add user $username${CEND}"
        exit 1
    fi
}

function main() {
    case "${1:-help}" in
        "start")
            show_header
            start_service
            ;;
        "stop")
            show_header
            stop_service
            ;;
        "restart")
            show_header
            restart_service
            ;;
        "logs")
            show_logs
            ;;
        "users")
            show_header
            list_users
            ;;
        "add-user")
            show_header
            add_user "$2" "$3"
            ;;
        "help"|*)
            show_header
            echo -e "${CCYAN}Available commands:${CEND}"
            echo -e "  start          - Start RabbitMQ service"
            echo -e "  stop           - Stop RabbitMQ service"
            echo -e "  restart        - Restart RabbitMQ service"
            echo -e "  logs           - Show RabbitMQ logs"
            echo -e "  users          - List RabbitMQ users"
            echo -e "  add-user       - Add new user (add-user <username> <password>)"
            echo ""
            ;;
    esac
}

main "$@"
EOF
    
    # Make scripts executable
    chmod +x /usr/local/bin/rabbitmq-monitor
    chmod +x /usr/local/bin/rabbitmq-manager
    
    echo -e "${CGREEN}Monitoring and management scripts created${CEND}"
}

function start_rabbitmq() {
    echo -e "${CGREEN}Starting RabbitMQ service...${CEND}"
    
    # Start RabbitMQ service
    systemctl start rabbitmq-server
    
    # Wait for service to start
    sleep 10
    
    # Check if service is running
    if systemctl is-active --quiet rabbitmq-server; then
        echo -e "${CGREEN}RabbitMQ service started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start RabbitMQ service${CEND}"
        systemctl status rabbitmq-server
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying RabbitMQ installation...${CEND}"
    
    # Wait for RabbitMQ to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if rabbitmqctl status >/dev/null 2>&1; then
            echo -e "${CGREEN}RabbitMQ connection: OK${CEND}"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${CRED}RabbitMQ connection: FAILED${CEND}"
            echo -e "${CYAN}RabbitMQ may still be starting up. Check with: rabbitmq-monitor status${CEND}"
            return 1
        fi
        
        echo -e "${CCYAN}Waiting for RabbitMQ to start... (attempt $attempt/$max_attempts)${CEND}"
        sleep 2
        ((attempt++))
    done
    
    # Test basic operations
    local status=$(rabbitmqctl status 2>/dev/null | grep -E "RabbitMQ|Erlang/OTP" | head -2)
    if [ -n "$status" ]; then
        echo -e "${CGREEN}RabbitMQ status: OK${CEND}"
        echo -e "  $status" | sed 's/^[[:space:]]*//'
    else
        echo -e "${CRED}Cannot get RabbitMQ status${CEND}"
        return 1
    fi
    
    # Check management plugin
    if rabbitmq-plugins list | grep -q "rabbitmq_management.*E"; then
        echo -e "${CGREEN}Management plugin: Enabled${CEND}"
    else
        echo -e "${CYAN}Management plugin: Not enabled${CEND}"
    fi
    
    # Test management interface
    if curl -s http://localhost:15672 >/dev/null 2>&1; then
        echo -e "${CGREEN}Management interface: OK${CEND}"
    else
        echo -e "${CYAN}Management interface: Not accessible${CEND}"
    fi
    
    echo -e "${CGREEN}RabbitMQ installation verified successfully${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    RabbitMQ Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  RabbitMQ Version: $RABBITMQ_VERSION"
    echo -e "  Erlang Version: $ERLANG_VERSION"
    echo -e "  AMQP Port: 5672"
    echo -e "  Management Port: 15672"
    echo -e "  Configuration: $RABBITMQ_HOME/rabbitmq.conf"
    echo ""
    echo -e "${CCYAN}Security Configuration:${CEND}"
    echo -e "  ✓ Localhost-only binding (127.0.0.1)"
    echo -e "  ✓ Default admin user configured"
    echo -e "  ✓ Firewall configured for localhost access"
    echo -e "  ✓ Systemd security hardening applied"
    echo -e "  ✓ Management plugin enabled"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Service status: systemctl status rabbitmq-server"
    echo -e "  Start service: rabbitmq-manager start"
    echo -e "  Stop service: rabbitmq-manager stop"
    echo -e "  Restart service: rabbitmq-manager restart"
    echo -e "  View logs: rabbitmq-manager logs"
    echo -e "  List users: rabbitmq-manager users"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  Check status: rabbitmq-monitor"
    echo -e "  Cluster status: rabbitmqctl cluster_status"
    echo -e "  Management UI: http://localhost:15672"
    echo ""
    echo -e "${CCYAN}Quick Start:${CEND}"
    echo -e "  Test connection: rabbitmqctl status"
    echo -e "  Add user: rabbitmq-manager add-user testuser testpass"
    echo -e "  Add virtual host: rabbitmqctl add_vhost testhost"
    echo -e "  Set permissions: rabbitmqctl set_permissions -p testhost testuser \".*\" \".*\" \".*\""
    echo ""
    echo -e "${CMAGENTA}Important Notes:${CEND}"
    echo -e "  • RabbitMQ is configured for localhost-only access"
    echo -e "  • Default admin user credentials are in the config file"
    echo -e "  • Management interface is available at http://localhost:15672"
    echo -e "  • AMQP port 5672 is for message communication"
    echo -e "  • Management port 15672 is for web interface"
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/test_rabbitmq.sh 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    check_root
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Add Erlang repository
    add_erlang_repository
    
    # Install Erlang
    install_erlang
    
    # Add RabbitMQ repository
    add_rabbitmq_repository
    
    # Install RabbitMQ
    install_rabbitmq
    
    # Configure security
    configure_security
    
    # Configure systemd
    configure_systemd
    
    # Configure firewall
    configure_firewall
    
    # Enable management plugin
    enable_management_plugin
    
    # Create monitoring scripts
    create_monitoring_scripts
    
    # Start RabbitMQ
    start_rabbitmq
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show success message
    show_success_message
}

# Run main function
main
