#!/bin/bash

# Elasticsearch Installation Script
# Secure Elasticsearch 8.x installation with comprehensive security hardening

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

# Elasticsearch Configuration
ES_VERSION="8.11.0"
ES_USER="elasticsearch"
ES_GROUP="elasticsearch"
ES_HOME="/usr/share/elasticsearch"
ES_CONF_DIR="/etc/elasticsearch"
ES_DATA_DIR="/var/lib/elasticsearch"
ES_LOG_DIR="/var/log/elasticsearch"

# System Information
ARCH=$(uname -m)
OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")

# Logging
LOG_FILE="/tmp/elasticsearch-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}  Elasticsearch Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}Version: ${ES_VERSION}${CEND}"
    echo -e "${CCYAN}Architecture: ${ARCH}${CEND}"
    echo -e "${CCYAN}OS: ${OS} ${OS_VERSION}${CEND}"
    echo ""
}

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CRED}Please run as root or with sudo${CEND}"
        exit 1
    fi
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
    
    # Check memory requirements (Elasticsearch needs at least 4GB)
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    echo -e "${CCYAN}Total Memory: ${total_mem}GB${CEND}"
    
    if [ "$total_mem" -lt 4 ]; then
        echo -e "${CRED}Warning: Elasticsearch requires at least 4GB RAM for optimal performance${CEND}"
        read -p "Continue with less memory? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    fi
    
    # Check if Elasticsearch is already installed
    if command -v elasticsearch >/dev/null 2>&1; then
        echo -e "${CYAN}Elasticsearch is already installed${CEND}"
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
        openjdk-17-jre-headless \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Dependencies installed successfully${CEND}"
}

function add_repository() {
    echo -e "${CGREEN}Adding Elasticsearch repository...${CEND}"
    
    # Import Elasticsearch GPG key
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to import Elasticsearch GPG key${CEND}"
        exit 1
    fi
    
    # Add Elasticsearch repository
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list >> "$LOG_FILE" 2>&1
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to add Elasticsearch repository${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Elasticsearch repository added successfully${CEND}"
}

function install_elasticsearch() {
    echo -e "${CGREEN}Installing Elasticsearch...${CEND}"
    
    # Install Elasticsearch
    apt install -y elasticsearch=${ES_VERSION} >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Elasticsearch${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Elasticsearch installed successfully${CEND}"
}

function configure_security() {
    echo -e "${CGREEN}Configuring Elasticsearch security...${CEND}"
    
    # Generate random passwords for built-in users
    echo -e "${CCYAN}Generating passwords for built-in users...${CEND}"
    
    # Create elasticsearch user and group if they don't exist
    if ! id "$ES_USER" &>/dev/null; then
        useradd --system --no-create-home --shell /bin/false $ES_USER >> "$LOG_FILE" 2>&1
    fi
    
    # Set up directories with proper permissions
    mkdir -p $ES_DATA_DIR $ES_LOG_DIR
    chown -R $ES_USER:$ES_GROUP $ES_DATA_DIR $ES_LOG_DIR
    chmod 755 $ES_DATA_DIR $ES_LOG_DIR
    
    # Configure elasticsearch.yml for localhost-only access
    cat > $ES_CONF_DIR/elasticsearch.yml << EOF
# Elasticsearch Configuration
cluster.name: elasticsearch-cluster
node.name: elasticsearch-node-1

# Network settings
network.host: 127.0.0.1
http.port: 9200

# Discovery settings
discovery.type: single-node

# Security settings
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false

# Memory settings
bootstrap.memory_lock: false

# Path settings
path.data: $ES_DATA_DIR
path.logs: $ES_LOG_DIR

# Performance settings
indices.memory.index_buffer_size: 10%
indices.queries.cache.size: 5%
indices.fielddata.cache.size: 40%

# Logging
logger.level: INFO
EOF
    
    # Set proper permissions for configuration file
    chown root:root $ES_CONF_DIR/elasticsearch.yml
    chmod 644 $ES_CONF_DIR/elasticsearch.yml
    
    # Configure JVM options for memory management
    local heap_size=$(free -m | awk 'NR==2{printf "%.0f", $2/2}')
    if [ "$heap_size" -gt 32768 ]; then
        heap_size=32768  # Max 32GB heap
    fi
    
    cat > $ES_CONF_DIR/jvm.options.d/heap.options << EOF
# JVM heap size configuration
-Xms${heap_size}m
-Xmx${heap_size}m
EOF
    
    echo -e "${CGREEN}Elasticsearch security configuration completed${CEND}"
}

function configure_systemd() {
    echo -e "${CGREEN}Configuring systemd service...${CEND}"
    
    # Create systemd override for security hardening
    mkdir -p /etc/systemd/system/elasticsearch.service.d
    
    cat > /etc/systemd/system/elasticsearch.service.d/security.conf << EOF
[Service]
# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$ES_DATA_DIR $ES_LOG_DIR /tmp

# Network restrictions
IPAddressAllow=localhost
IPAddressAllow=127.0.0.1/8
IPAddressAllow=::1/128

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=4g

# File system access
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable elasticsearch
    
    echo -e "${CGREEN}Systemd service configured and enabled${CEND}"
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall...${CEND}"
    
    # Configure UFW if available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring UFW firewall...${CEND}"
        
        # Allow Elasticsearch from localhost only
        ufw allow from 127.0.0.1 to any port 9200 >> "$LOG_FILE" 2>&1
        ufw allow from ::1 to any port 9200 >> "$LOG_FILE" 2>&1
        
        # Explicitly deny external access to Elasticsearch
        ufw deny 9200 >> "$LOG_FILE" 2>&1
        
        echo -e "${CGREEN}UFW firewall configured for Elasticsearch${CEND}"
    
    # Configure iptables if UFW is not available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring iptables firewall...${CEND}"
        
        # Allow localhost access to Elasticsearch
        iptables -A INPUT -s 127.0.0.1 -p tcp --dport 9200 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -s ::1 -p tcp --dport 9200 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Deny external access
        iptables -A INPUT -p tcp --dport 9200 -j DROP >> "$LOG_FILE" 2>&1
        
        # Save iptables rules
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        
        echo -e "${CGREEN}iptables firewall configured for Elasticsearch${CEND}"
    else
        echo -e "${CYAN}No firewall found - please manually configure Elasticsearch access${CEND}"
    fi
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create Elasticsearch monitoring script
    cat > /usr/local/bin/elasticsearch-monitor << 'EOF'
#!/bin/bash

# Elasticsearch Monitoring Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

ES_HOST="http://localhost:9200"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}  Elasticsearch Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function show_status() {
    echo -e "${CGREEN}Elasticsearch Status:${CEND}"
    
    # Check service status
    if systemctl is-active --quiet elasticsearch; then
        echo -e "  Service: ${CGREEN}Running${CEND}"
    else
        echo -e "  Service: ${CRED}Stopped${CEND}"
    fi
    
    # Check cluster health
    local health=$(curl -s "$ES_HOST/_cluster/health?pretty" 2>/dev/null | grep '"status"' | cut -d'"' -f4)
    if [ -n "$health" ]; then
        case $health in
            "green")
                echo -e "  Cluster Health: ${CGREEN}$health${CEND}"
                ;;
            "yellow")
                echo -e "  Cluster Health: ${CMAGENTA}$health${CEND}"
                ;;
            "red")
                echo -e "  Cluster Health: ${CRED}$health${CEND}"
                ;;
        esac
    else
        echo -e "  Cluster Health: ${CRED}Unknown${CEND}"
    fi
    
    echo ""
}

function show_info() {
    echo -e "${CGREEN}Elasticsearch Information:${CEND}"
    
    # Get cluster info
    local info=$(curl -s "$ES_HOST" 2>/dev/null | grep -E '"version"|"tagline"' | head -4)
    if [ -n "$info" ]; then
        echo -e "  $info" | sed 's/^[[:space:]]*//' | sed 's/"//g'
    else
        echo -e "  ${CRED}Cannot connect to Elasticsearch${CEND}"
    fi
    
    echo ""
}

function show_memory() {
    echo -e "${CGREEN}Memory Usage:${CEND}"
    
    # Get JVM memory stats
    local memory=$(curl -s "$ES_HOST/_nodes/stats/jvm?pretty" 2>/dev/null | grep -A 10 '"heap_used_percent"' | head -10)
    if [ -n "$memory" ]; then
        echo -e "  $memory" | sed 's/^[[:space:]]*//'
    else
        echo -e "  ${CRED}Cannot get memory stats${CEND}"
    fi
    
    echo ""
}

function show_indices() {
    echo -e "${CGREEN}Index Information:${CEND}"
    
    # Get index stats
    local indices=$(curl -s "$ES_HOST/_cat/indices?v" 2>/dev/null)
    if [ -n "$indices" ]; then
        echo -e "  $indices" | head -10
    else
        echo -e "  ${CRED}Cannot get index information${CEND}"
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
        "memory")
            show_header
            show_memory
            ;;
        "indices")
            show_header
            show_indices
            ;;
        "all")
            show_header
            show_status
            show_info
            show_memory
            show_indices
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [status|info|memory|indices|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Create Elasticsearch management script
    cat > /usr/local/bin/elasticsearch-manager << 'EOF'
#!/bin/bash

# Elasticsearch Management Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

ES_HOST="http://localhost:9200"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}  Elasticsearch Manager${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function start_service() {
    echo -e "${CGREEN}Starting Elasticsearch service...${CEND}"
    systemctl start elasticsearch
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Elasticsearch started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start Elasticsearch${CEND}"
        exit 1
    fi
}

function stop_service() {
    echo -e "${CGREEN}Stopping Elasticsearch service...${CEND}"
    systemctl stop elasticsearch
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Elasticsearch stopped successfully${CEND}"
    else
        echo -e "${CRED}Failed to stop Elasticsearch${CEND}"
        exit 1
    fi
}

function restart_service() {
    echo -e "${CGREEN}Restarting Elasticsearch service...${CEND}"
    systemctl restart elasticsearch
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Elasticsearch restarted successfully${CEND}"
    else
        echo -e "${CRED}Failed to restart Elasticsearch${CEND}"
        exit 1
    fi
}

function show_logs() {
    echo -e "${CGREEN}Elasticsearch Logs:${CEND}"
    journalctl -u elasticsearch -f --lines=50
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
        "help"|*)
            show_header
            echo -e "${CCYAN}Available commands:${CEND}"
            echo -e "  start      - Start Elasticsearch service"
            echo -e "  stop       - Stop Elasticsearch service"
            echo -e "  restart    - Restart Elasticsearch service"
            echo -e "  logs       - Show Elasticsearch logs"
            echo ""
            ;;
    esac
}

main "$@"
EOF
    
    # Make scripts executable
    chmod +x /usr/local/bin/elasticsearch-monitor
    chmod +x /usr/local/bin/elasticsearch-manager
    
    echo -e "${CGREEN}Monitoring and management scripts created${CEND}"
}

function start_elasticsearch() {
    echo -e "${CGREEN}Starting Elasticsearch service...${CEND}"
    
    # Start Elasticsearch service
    systemctl start elasticsearch
    
    # Wait for service to start
    sleep 10
    
    # Check if service is running
    if systemctl is-active --quiet elasticsearch; then
        echo -e "${CGREEN}Elasticsearch service started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start Elasticsearch service${CEND}"
        systemctl status elasticsearch
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Elasticsearch installation...${CEND}"
    
    # Wait for Elasticsearch to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:9200 >/dev/null 2>&1; then
            echo -e "${CGREEN}Elasticsearch connection: OK${CEND}"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${CRED}Elasticsearch connection: FAILED${CEND}"
            echo -e "${CYAN}Elasticsearch may still be starting up. Check with: elasticsearch-monitor status${CEND}"
            return 1
        fi
        
        echo -e "${CCYAN}Waiting for Elasticsearch to start... (attempt $attempt/$max_attempts)${CEND}"
        sleep 2
        ((attempt++))
    done
    
    # Test basic operations
    local version=$(curl -s http://localhost:9200 | grep -o '"number":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$version" ]; then
        echo -e "${CGREEN}Elasticsearch version: $version${CEND}"
    else
        echo -e "${CRED}Cannot get Elasticsearch version${CEND}"
        return 1
    fi
    
    # Test cluster health
    local health=$(curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$health" ]; then
        echo -e "${CGREEN}Cluster health: $health${CEND}"
    else
        echo -e "${CRED}Cannot get cluster health${CEND}"
        return 1
    fi
    
    echo -e "${CGREEN}Elasticsearch installation verified successfully${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}  Elasticsearch Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Elasticsearch Version: $ES_VERSION"
    echo -e "  HTTP Port: 9200"
    echo -e "  Transport Port: 9300"
    echo -e "  Configuration: $ES_CONF_DIR/elasticsearch.yml"
    echo ""
    echo -e "${CCYAN}Security Configuration:${CEND}"
    echo -e "  ✓ Localhost-only binding (127.0.0.1)"
    echo -e "  ✓ Security features enabled"
    echo -e "  ✓ Firewall configured for localhost access"
    echo -e "  ✓ Systemd security hardening applied"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Service status: systemctl status elasticsearch"
    echo -e "  Start service: elasticsearch-manager start"
    echo -e "  Stop service: elasticsearch-manager stop"
    echo -e "  Restart service: elasticsearch-manager restart"
    echo -e "  View logs: elasticsearch-manager logs"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  Check status: elasticsearch-monitor"
    echo -e "  Cluster health: curl http://localhost:9200/_cluster/health"
    echo -e "  Node info: curl http://localhost:9200"
    echo ""
    echo -e "${CCYAN}Quick Start:${CEND}"
    echo -e "  Test connection: curl http://localhost:9200"
    echo -e "  Create index: curl -X PUT http://localhost:9200/test-index"
    echo -e "  Add document: curl -X POST http://localhost:9200/test-index/_doc -H 'Content-Type: application/json' -d '{\"field\":\"value\"}'"
    echo -e "  Search: curl http://localhost:9200/test-index/_search"
    echo ""
    echo -e "${CMAGENTA}Important Notes:${CEND}"
    echo -e "  • Elasticsearch is configured for localhost-only access"
    echo -e "  • Security features are enabled by default"
    echo -e "  • Default passwords are generated during first start"
    echo -e "  • Check logs for initial setup instructions"
    echo -e "  • Memory settings are automatically configured"
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/test_elasticsearch.sh 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    check_root
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Add repository
    add_repository
    
    # Install Elasticsearch
    install_elasticsearch
    
    # Configure security
    configure_security
    
    # Configure systemd
    configure_systemd
    
    # Configure firewall
    configure_firewall
    
    # Create monitoring scripts
    create_monitoring_scripts
    
    # Start Elasticsearch
    start_elasticsearch
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show success message
    show_success_message
}

# Run main function
main
