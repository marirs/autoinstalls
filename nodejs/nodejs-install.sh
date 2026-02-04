#!/bin/bash

# Node.js Installation Script
# Secure Node.js 20.x LTS installation with development tools and security hardening

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

# Node.js Configuration
NODE_VERSION="20.x"
NVM_VERSION="0.39.7"
NODE_USER="nodejs"
INSTALL_METHOD="nodesource"  # Default to NodeSource

# System Information
ARCH=$(uname -m)
OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")

# Logging
LOG_FILE="/tmp/nodejs-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Node.js Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}Version: ${NODE_VERSION} LTS${CEND}"
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

function choose_installation_method() {
    echo -e "${CGREEN}Choose Node.js installation method:${CEND}"
    echo "1) NodeSource 20.x LTS (System-wide) - [DEFAULT]"
    echo "2) NVM (User-level with version switching)"
    read -p "Enter choice [1-2]: " -n 1 -r
    echo
    
    case $REPLY in
        1|"")
            INSTALL_METHOD="nodesource"
            echo -e "${CCYAN}Selected: NodeSource 20.x LTS (System-wide)${CEND}"
            ;;
        2)
            INSTALL_METHOD="nvm"
            echo -e "${CCYAN}Selected: NVM (User-level with version switching)${CEND}"
            ;;
        *)
            echo -e "${CRED}Invalid choice. Using default: NodeSource 20.x LTS${CEND}"
            INSTALL_METHOD="nodesource"
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
    
    # Check if Node.js is already installed
    if command -v node >/dev/null 2>&1; then
        echo -e "${CYAN}Node.js is already installed${CEND}"
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
        build-essential \
        python3 \
        python3-pip \
        git \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Dependencies installed successfully${CEND}"
}

function install_nodesource() {
    echo -e "${CGREEN}Installing Node.js via NodeSource...${CEND}"
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to add NodeSource repository${CEND}"
        exit 1
    fi
    
    # Install Node.js
    apt install -y nodejs >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Node.js${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Node.js installed successfully${CEND}"
}

function install_nvm() {
    echo -e "${CGREEN}Installing NVM...${CEND}"
    
    # Get the current user for NVM installation
    local current_user=${SUDO_USER:-$USER}
    local nvm_dir="/home/$current_user/.nvm"
    
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash - >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install NVM${CEND}"
        exit 1
    fi
    
    # Load NVM
    export NVM_DIR="$nvm_dir"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install Node.js LTS via NVM
    su - "$current_user" -c "source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default lts/*" >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Node.js via NVM${CEND}"
        exit 1
    fi
    
    # Create system-wide symlinks for convenience
    ln -sf "$nvm_dir/versions/node/$(ls $nvm_dir/versions/node | sort -V | tail -1)/bin/node" /usr/local/bin/node
    ln -sf "$nvm_dir/versions/node/$(ls $nvm_dir/versions/node | sort -V | tail -1)/bin/npm" /usr/local/bin/npm
    ln -sf "$nvm_dir/versions/node/$(ls $nvm_dir/versions/node | sort -V | tail -1)/bin/npx" /usr/local/bin/npx
    
    echo -e "${CGREEN}NVM and Node.js installed successfully${CEND}"
}

function configure_security() {
    echo -e "${CGREEN}Configuring security settings...${CEND}"
    
    # Configure npm security settings
    npm config set audit true >> "$LOG_FILE" 2>&1
    npm config set fund false >> "$LOG_FILE" 2>&1
    
    # Set secure npm registry (can be changed to private registry)
    npm config set registry https://registry.npmjs.org/ >> "$LOG_FILE" 2>&1
    
    # Create secure global modules directory
    mkdir -p /usr/local/lib/node_modules
    chmod 755 /usr/local/lib/node_modules
    
    # Set proper permissions for npm global directory
    if [ "$INSTALL_METHOD" = "nodesource" ]; then
        chown -R root:root /usr/local/lib/node_modules
    else
        local current_user=${SUDO_USER:-$USER}
        chown -R "$current_user:$current_user" /usr/local/lib/node_modules
    fi
    
    echo -e "${CGREEN}Security configuration completed${CEND}"
}

function install_dev_tools() {
    echo -e "${CGREEN}Installing development tools...${CEND}"
    
    # Install essential global packages
    npm install -g \
        nodemon \
        pm2 \
        yarn \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install development tools${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Development tools installed successfully${CEND}"
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create Node.js monitoring script
    cat > /usr/local/bin/nodejs-monitor << 'EOF'
#!/bin/bash

# Node.js Monitoring Script

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
    echo -e "${CBLUE}    Node.js Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function show_version() {
    echo -e "${CGREEN}Node.js and npm Versions:${CEND}"
    
    if command -v node >/dev/null 2>&1; then
        echo -e "  Node.js: $(node --version)"
    else
        echo -e "  ${CRED}Node.js: Not installed${CEND}"
    fi
    
    if command -v npm >/dev/null 2>&1; then
        echo -e "  npm: $(npm --version)"
    else
        echo -e "  ${CRED}npm: Not installed${CEND}"
    fi
    
    if command -v yarn >/dev/null 2>&1; then
        echo -e "  Yarn: $(yarn --version)"
    else
        echo -e "  ${CYAN}Yarn: Not installed${CEND}"
    fi
    
    echo ""
}

function show_modules() {
    echo -e "${CGREEN}Global npm Modules:${CEND}"
    
    if command -v npm >/dev/null 2>&1; then
        npm list -g --depth=0 2>/dev/null | grep -E "├|└" | sed 's/^[├└─\s]*//' | head -20
    else
        echo -e "  ${CRED}npm not available${CEND}"
    fi
    
    echo ""
}

function show_security() {
    echo -e "${CGREEN}Security Information:${CEND}"
    
    if command -v npm >/dev/null 2>&1; then
        echo -e "  npm audit status:"
        npm audit --audit-level=moderate 2>/dev/null | grep -E "found|vulnerabilities" || echo -e "  ${CGREEN}No vulnerabilities found${CEND}"
        
        echo -e "  npm registry: $(npm config get registry)"
    else
        echo -e "  ${CRED}npm not available${CEND}"
    fi
    
    echo ""
}

function show_processes() {
    echo -e "${CGREEN}Running Node.js Processes:${CEND}"
    
    local processes=$(ps aux | grep -E "node|npm" | grep -v grep | wc -l)
    echo -e "  Total Node.js processes: $processes"
    
    if [ "$processes" -gt 0 ]; then
        echo -e "  Process details:"
        ps aux | grep -E "node|npm" | grep -v grep | awk '{print "  PID: " $2 ", CPU: " $3 "%, MEM: " $4 "%, CMD: " $11}' | head -10
    fi
    
    echo ""
}

function main() {
    case "${1:-all}" in
        "version")
            show_header
            show_version
            ;;
        "modules")
            show_header
            show_modules
            ;;
        "security")
            show_header
            show_security
            ;;
        "processes")
            show_header
            show_processes
            ;;
        "all")
            show_header
            show_version
            show_modules
            show_security
            show_processes
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [version|modules|security|processes|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Create Node.js management script
    cat > /usr/local/bin/nodejs-manager << 'EOF'
#!/bin/bash

# Node.js Management Script

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
    echo -e "${CBLUE}    Node.js Manager${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function list_globals() {
    echo -e "${CGREEN}Global npm Modules:${CEND}"
    
    if command -v npm >/dev/null 2>&1; then
        npm list -g --depth=0 2>/dev/null | grep -E "├|└" | sed 's/^[├└─\s]*//'
    else
        echo -e "  ${CRED}npm not available${CEND}"
    fi
    
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up npm cache...${CEND}"
    
    # Clear npm cache
    npm cache clean --force
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    case "${1:-help}" in
        "globals")
            show_header
            list_globals
            ;;
        "cleanup")
            show_header
            cleanup
            ;;
        "help"|*)
            show_header
            echo -e "${CCYAN}Available commands:${CEND}"
            echo -e "  globals    - List global npm modules"
            echo -e "  cleanup    - Clean npm cache"
            echo ""
            ;;
    esac
}

main "$@"
EOF
    
    # Make scripts executable
    chmod +x /usr/local/bin/nodejs-monitor
    chmod +x /usr/local/bin/nodejs-manager
    
    echo -e "${CGREEN}Monitoring and management scripts created${CEND}"
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Node.js installation...${CEND}"
    
    # Test Node.js installation
    if command -v node >/dev/null 2>&1; then
        local node_version=$(node --version)
        echo -e "${CGREEN}Node.js installation: OK ($node_version)${CEND}"
    else
        echo -e "${CRED}Node.js installation: FAILED${CEND}"
        exit 1
    fi
    
    # Test npm installation
    if command -v npm >/dev/null 2>&1; then
        local npm_version=$(npm --version)
        echo -e "${CGREEN}npm installation: OK ($npm_version)${CEND}"
    else
        echo -e "${CRED}npm installation: FAILED${CEND}"
        exit 1
    fi
    
    # Test basic Node.js functionality
    echo 'console.log("Node.js is working!");' > /tmp/test_node.js
    if node /tmp/test_node.js >/dev/null 2>&1; then
        echo -e "${CGREEN}Node.js functionality: OK${CEND}"
    else
        echo -e "${CRED}Node.js functionality: FAILED${CEND}"
        exit 1
    fi
    rm -f /tmp/test_node.js
    
    echo -e "${CGREEN}Node.js installation verified successfully${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Node.js Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Installation Method: $INSTALL_METHOD"
    echo -e "  Node.js Version: $(node --version)"
    echo -e "  npm Version: $(npm --version)"
    echo ""
    echo -e "${CCYAN}Development Tools:${CEND}"
    echo -e "  ✓ nodemon - Auto-restart for development"
    echo -e "  ✓ pm2 - Process manager for production"
    echo -e "  ✓ yarn - Alternative package manager"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Check versions: node --version && npm --version"
    echo -e "  Install package: npm install <package>"
    echo -e "  Install global: npm install -g <package>"
    echo -e "  Security audit: npm audit"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  Node.js status: nodejs-monitor"
    echo -e "  Manage modules: nodejs-manager"
    echo ""
}

function main() {
    show_header
    check_root
    
    # Choose installation method
    choose_installation_method
    
    # Check system compatibility
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Install Node.js based on method
    if [ "$INSTALL_METHOD" = "nodesource" ]; then
        install_nodesource
    else
        install_nvm
    fi
    
    # Configure security
    configure_security
    
    # Install development tools
    install_dev_tools
    
    # Create monitoring scripts
    create_monitoring_scripts
    
    # Verify installation
    verify_installation
    
    # Show success message
    show_success_message
}

# Run main function
main
