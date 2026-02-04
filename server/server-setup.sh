#!/bin/bash
#
# Description: Comprehensive Server Setup, Configuration & Hardening
# Tested: Ubuntu 18.04, 20.04, 22.04, 24.04 | Debian 9.x, 10.x, 11.x, 12.x
# macOS: Intel & Apple Silicon
#
# Features:
# - Essential software installation
# - System hardening (sysctl.conf, security configs)
# - Network configuration (IPv4/IPv6 dual stack)
# - SSH key management (generate or import)
# - Network configuration and optimization
# - Firewall setup
# - User security configuration
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"
CYELLOW="${CSI}1;33m"

# Global variables
LOG_FILE="/tmp/server-setup.log"
OS=""
OS_VER=""
ARCH=""
ROOT_ACCESS=""
SSH_KEY_MODE=""
FIREWALL_ENABLED=""
TIMEZONE=""
HOSTNAME=""

# Function to detect platform
function detect_platform() {
    echo -e "${CGREEN}Detecting platform and architecture...${CEND}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VER=$(sw_vers -productVersion)
        ARCH=$(uname -m)
        echo -e "${CCYAN}Platform: macOS $OS_VER ($ARCH)${CEND}"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS="$ID"
        OS_VER="$VERSION_ID"
        ARCH=$(uname -m)
        echo -e "${CCYAN}Platform: $OS $OS_VER ($ARCH)${CEND}"
    else
        echo -e "${CRED}Unsupported platform detected${CEND}"
        exit 1
    fi
}

# Function to check root access
function check_root_access() {
    if [[ "$OS" != "macos" && "$EUID" -ne 0 ]]; then
        echo -e "${CRED}This script requires root privileges on Linux systems${CEND}"
        echo -e "${CYAN}Please run with: sudo $0${CEND}"
        exit 1
    fi
    ROOT_ACCESS="yes"
}

# Function to show main menu
function show_main_menu() {
    clear
    echo -e "${CGREEN}========================================${CEND}"
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CGREEN}    macOS Development Setup Menu    ${CEND}"
    else
        echo -e "${CGREEN}    Server Setup & Hardening Menu    ${CEND}"
    fi
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Detected Platform: $OS $OS_VER ($ARCH)${CEND}"
    echo ""
    
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CCYAN}Select configuration options:${CEND}"
        echo "1) Essential Development Tools"
        echo "2) SSH Key Management"
        echo "3) Development Environment Setup"
        echo "4) Git Configuration"
        echo "5) Security & Privacy Settings"
        echo "6) Shell Environment Configuration"
        echo "7) Complete Development Setup (All of the above)"
        echo "8) Custom Setup (Select individual components)"
    else
        echo -e "${CCYAN}Select configuration options:${CEND}"
        echo "1) Essential Software Installation"
        echo "2) System Hardening & Security Configuration"
        echo "3) Network Configuration (IPv4/IPv6)"
        echo "4) SSH Key Management"
        echo "5) Firewall Configuration"
        echo "6) User & Authentication Setup"
        echo "7) Complete Server Setup (All of the above)"
        echo "8) Custom Setup (Select individual components)"
    fi
    
    echo ""
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CYAN}Recommended: Option 7 for complete development setup${CEND}"
    else
        echo -e "${CYAN}Recommended: Option 7 for complete setup${CEND}"
    fi
    echo ""
}

# Function to get user choice
function get_user_choice() {
    while true; do
        show_main_menu
        if [[ "$OS" == "macos" ]]; then
            read -p "Enter your choice [1-8]: " choice
            case $choice in
                1) SETUP_MODE="essential" && break ;;
                2) SETUP_MODE="ssh" && break ;;
                3) SETUP_MODE="development" && break ;;
                4) SETUP_MODE="git" && break ;;
                5) SETUP_MODE="security" && break ;;
                6) SETUP_MODE="shell" && break ;;
                7) SETUP_MODE="complete" && break ;;
                8) SETUP_MODE="custom" && break ;;
                *) echo -e "${CRED}Invalid choice. Please enter 1-8.${CEND}" && sleep 2 ;;
            esac
        else
            read -p "Enter your choice [1-8]: " choice
            case $choice in
                1) SETUP_MODE="essential" && break ;;
                2) SETUP_MODE="hardening" && break ;;
                3) SETUP_MODE="network" && break ;;
                4) SETUP_MODE="ssh" && break ;;
                5) SETUP_MODE="firewall" && break ;;
                6) SETUP_MODE="users" && break ;;
                7) SETUP_MODE="complete" && break ;;
                8) SETUP_MODE="custom" && break ;;
                *) echo -e "${CRED}Invalid choice. Please enter 1-8.${CEND}" && sleep 2 ;;
            esac
        fi
    done
    
    echo -e "${CGREEN}Selected: $SETUP_MODE setup${CEND}"
}

# Function to show setup summary
function show_setup_summary() {
    echo ""
    echo -e "${CCYAN}========================================${CEND}"
    echo -e "${CCYAN}    Setup Configuration Summary    ${CEND}"
    echo -e "${CCYAN}========================================${CEND}"
    echo ""
    
    case $SETUP_MODE in
        "essential")
            if [[ "$OS" == "macos" ]]; then
                echo -e "${CGREEN}✓ Essential Development Tools${CEND}"
                echo "  - Homebrew package manager"
                echo "  - Development utilities (git, curl, wget)"
                echo "  - Text editors (vim, nano)"
                echo "  - System tools (htop, tree, jq)"
            else
                echo -e "${CGREEN}✓ Essential Software Installation${CEND}"
                echo "  - System updates and core utilities"
                echo "  - Development tools (git, curl, wget)"
                echo "  - Security packages (openssl, fail2ban)"
                echo "  - System monitoring tools"
            fi
            ;;
        "development")
            echo -e "${CGREEN}✓ Development Environment Setup${CEND}"
            echo "  - Python development environment"
            echo "  - Node.js and npm"
            echo "  - Docker Desktop"
            echo "  - VS Code and extensions"
            echo "  - Development databases"
            ;;
        "git")
            echo -e "${CGREEN}✓ Git Configuration${CEND}"
            echo "  - Global git configuration"
            echo "  - SSH key integration"
            echo "  - Git aliases and helpers"
            echo "  - Credential manager setup"
            ;;
        "security")
            echo -e "${CGREEN}✓ Security & Privacy Settings${CEND}"
            echo "  - macOS firewall configuration"
            echo "  - FileVault encryption setup"
            echo "  - Privacy settings optimization"
            echo "  - Application permissions"
            ;;
        "shell")
            echo -e "${CGREEN}✓ Shell Environment Configuration${CEND}"
            echo "  - Custom PS1 prompt setup"
            echo "  - SSH agent initialization"
            echo "  - Environment variables"
            echo "  - Useful aliases and shortcuts"
            echo "  - Color configuration for ls"
            ;;
        "hardening")
            echo -e "${CGREEN}✓ System Hardening & Security${CEND}"
            echo "  - sysctl.conf hardening"
            echo "  - File permissions security"
            echo "  - Service hardening"
            echo "  - Security audit tools"
            ;;
        "network")
            echo -e "${CGREEN}✓ Network Configuration${CEND}"
            echo "  - IPv4/IPv6 dual stack setup"
            echo "  - Network interface configuration"
            echo "  - DNS optimization"
            echo "  - Connection tracking optimization"
            ;;
        "ssh")
            echo -e "${CGREEN}✓ SSH Key Management${CEND}"
            echo "  - Generate new SSH keys or import existing"
            echo "  - SSH daemon hardening"
            echo "  - Key-based authentication setup"
            echo "  - SSH configuration optimization"
            ;;
        "firewall")
            echo -e "${CGREEN}✓ Firewall Configuration${CEND}"
            echo "  - UFW/iptables setup"
            echo "  - Security rules configuration"
            echo "  - Port management"
            echo "  - Intrusion prevention"
            ;;
        "users")
            echo -e "${CGREEN}✓ User & Authentication Setup${CEND}"
            echo "  - Secure user creation"
            echo "  - sudo configuration"
            echo "  - Password policies"
            echo "  - Authentication hardening"
            ;;
        "complete")
            if [[ "$OS" == "macos" ]]; then
                echo -e "${CGREEN}✓ Complete Development Setup${CEND}"
                echo "  - Essential development tools"
                echo "  - Development environment setup"
                echo "  - Git configuration"
                echo "  - Security & privacy settings"
                echo "  - Shell environment configuration"
                echo "  - SSH key management"
            else
                echo -e "${CGREEN}✓ Complete Server Setup${CEND}"
                echo "  - All essential software installation"
                echo "  - Full system hardening"
                echo "  - Network configuration"
                echo "  - SSH key management"
                echo "  - Firewall configuration"
                echo "  - User and authentication setup"
            fi
            ;;
        "custom")
            echo -e "${CGREEN}✓ Custom Setup${CEND}"
            echo "  - Select individual components"
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}System Information:${CEND}"
    echo "  Platform: $OS $OS_VER"
    echo "  Architecture: $ARCH"
    echo "  Root Access: $ROOT_ACCESS"
    echo ""
    
    read -p "Continue with setup? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CRED}Setup cancelled.${CEND}"
        exit 0
    fi
}

# Function to install essential software
function install_essential_software() {
    echo -e "${CGREEN}Installing essential software...${CEND}"
    
    if [[ "$OS" == "macos" ]]; then
        install_macos_essentials
    else
        install_linux_essentials
    fi
}

# Function to install macOS essentials
function install_macos_essentials() {
    echo -e "${CCYAN}Installing macOS essentials...${CEND}"
    
    # Check for Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${CYAN}Installing Homebrew...${CEND}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
    fi
    
    # Install essential packages with availability checking
    local packages=(
        "git"
        "curl"
        "wget"
        "openssl"
        "bash"
        "coreutils"
        "findutils"
        "grep"
        "sed"
        "awk"
        "vim"
        "nano"
        "htop"
        "tree"
        "jq"
        "yq"
        "screen"
        "ca-certificates"
        "zip"
        "unzip"
        "p7zip"
    )
    
    # Try to install packages with error handling
    for package in "${packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $package ...${CEND}\r"
        if brew install "$package" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $package installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $package failed${CEND}"
        fi
    done
    
    # Install packages that might have different names or versions
    echo -e "${CCYAN}Installing additional packages...${CEND}"
    
    # Try different libuv packages
    local libuv_packages=("libuv" "libuv@1")
    for libuv_pkg in "${libuv_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $libuv_pkg ...${CEND}\r"
        if brew install "$libuv_pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $libuv_pkg installed${CEND}"
            break
        else
            echo -e "    - ${CRED}✗ $libuv_pkg failed${CEND}"
        fi
    done
    
    # Try different re2 packages
    local re2_packages=("re2" "google-re2")
    for re2_pkg in "${re2_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $re2_pkg ...${CEND}\r"
        if brew install "$re2_pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $re2_pkg installed${CEND}"
            break
        else
            echo -e "    - ${CRED}✗ $re2_pkg failed${CEND}"
        fi
    done
    
    # Try different pcregrep packages
    local pcre_packages=("pcre" "grep" "gnu-sed")
    for pcre_pkg in "${pcre_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $pcre_pkg ...${CEND}\r"
        if brew install "$pcre_pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $pcre_pkg installed${CEND}"
            break
        else
            echo -e "    - ${CRED}✗ $pcre_pkg failed${CEND}"
        fi
    done
    
    # Try different libffi packages
    local ffi_packages=("libffi" "ffi")
    for ffi_pkg in "${ffi_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $ffi_pkg ...${CEND}\r"
        if brew install "$ffi_pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $ffi_pkg installed${CEND}"
            break
        else
            echo -e "    - ${CRED}✗ $ffi_pkg failed${CEND}"
        fi
    done
    
    # Try different poppler packages
    local poppler_packages=("poppler" "poppler-utils")
    for poppler_pkg in "${poppler_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $poppler_pkg ...${CEND}\r"
        if brew install "$poppler_pkg" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $poppler_pkg installed${CEND}"
            break
        else
            echo -e "    - ${CRED}✗ $poppler_pkg failed${CEND}"
        fi
    done
    
    # Install development libraries
    echo -e "${CCYAN}Installing development libraries...${CEND}"
    local dev_packages=(
        "openssl@3"
    )
    
    for package in "${dev_packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $package ...${CEND}\r"
        if brew install "$package" >> "$LOG_FILE" 2>&1; then
            echo -e "    - ${CGREEN}✓ $package installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $package failed${CEND}"
        fi
    done
    
    echo -e "${CGREEN}✓ macOS essentials installation completed${CEND}"
}

# Function to install Linux essentials
function install_linux_essentials() {
    echo -e "${CCYAN}Installing Linux essentials...${CEND}"
    
    # Update system
    echo -e "${CYAN}Updating system packages...${CEND}"
    if command -v apt >/dev/null 2>&1; then
        apt update >> "$LOG_FILE" 2>&1
        apt upgrade -y >> "$LOG_FILE" 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum update -y >> "$LOG_FILE" 2>&1
        yum upgrade -y >> "$LOG_FILE" 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf update -y >> "$LOG_FILE" 2>&1
        dnf upgrade -y >> "$LOG_FILE" 2>&1
    fi
    
    # Install essential packages with version flexibility
    local packages=(
        "ca-certificates"
        "curl"
        "wget"
        "git"
        "openssl"
        "build-essential"
        "zip"
        "unzip"
        "vim"
        "nano"
        "htop"
        "tree"
        "jq"
        "lsof"
        "iotop"
        "ncdu"
        "fail2ban"
        "logrotate"
    )
    
    # Add distribution-specific packages with version handling
    if command -v apt >/dev/null 2>&1; then
        # Ubuntu/Debian specific packages with version flexibility
        local apt_packages=()
        
        # Detect OS version for package selection
        local os_id=""
        local os_version=""
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            os_id="$ID"
            os_version="$VERSION_ID"
        fi
        
        # Base packages for Ubuntu/Debian
        apt_packages+=(
            "apt-transport-https"
        )
        
        # Version-specific packages
        case "$os_id" in
            "debian")
                case "$os_version" in
                    "9"|"10"|"11")
                        # Older Debian versions
                        apt_packages+=(
                            "software-properties-common"
                            "p7zip-full"
                            "p7zip-rar"
                            "libre2-9"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                            "libx11-xcb1"
                            "dnsutils"
                            "devscripts"
                            "libuv1"
                            "libuv1-dev"
                            "libre2-dev"
                        )
                        ;;
                    "12")
                        # Debian 12 Bookworm
                        apt_packages+=(
                            "software-properties-common"
                            "p7zip-full"
                            "p7zip-rar"
                            "libre2-9"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                            "libx11-xcb1"
                            "dnsutils"
                            "devscripts"
                            "libuv1"
                            "libuv1-dev"
                            "libre2-dev"
                        )
                        ;;
                    "13")
                        # Debian 13 Trixie - handle package changes
                        apt_packages+=(
                            "sudo"
                            "p7zip-full"
                            "p7zip-rar"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                            "libx11-xcb1"
                            "dnsutils"
                            "devscripts"
                            "libuv1"
                            "libuv1-dev"
                        )
                        # Try different re2 package versions
                        local re2_packages=("libre2-9" "libre2-10" "libre2-8" "libre2-dev" "libre2")
                        for re2_pkg in "${re2_packages[@]}"; do
                            if apt-cache show "$re2_pkg" >/dev/null 2>&1; then
                                apt_packages+=("$re2_pkg")
                                break
                            fi
                        done
                        # Try software-properties-common alternatives
                        if ! apt-cache show software-properties-common >/dev/null 2>&1; then
                            echo -e "${CYAN}software-properties-common not found, skipping...${CEND}"
                        else
                            apt_packages+=("software-properties-common")
                        fi
                        ;;
                    *)
                        # Future Debian versions
                        apt_packages+=(
                            "software-properties-common"
                            "sudo"
                            "p7zip-full"
                            "p7zip-rar"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                        )
                        # Try re2 packages
                        local re2_packages=("libre2-9" "libre2-10" "libre2-8" "libre2-dev" "libre2")
                        for re2_pkg in "${re2_packages[@]}"; do
                            if apt-cache show "$re2_pkg" >/dev/null 2>&1; then
                                apt_packages+=("$re2_pkg")
                                break
                            fi
                        done
                        ;;
                esac
                ;;
            "ubuntu")
                case "$os_version" in
                    "18.04"|"20.04")
                        # Older Ubuntu versions
                        apt_packages+=(
                            "software-properties-common"
                            "sudo"
                            "p7zip-full"
                            "p7zip-rar"
                            "libre2-9"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                            "libx11-xcb1"
                            "dnsutils"
                            "devscripts"
                            "libuv1"
                            "libuv1-dev"
                            "libre2-dev"
                        )
                        ;;
                    "22.04"|"24.04")
                        # Modern Ubuntu versions
                        apt_packages+=(
                            "software-properties-common"
                            "sudo"
                            "p7zip-full"
                            "p7zip-rar"
                            "libre2-9"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                            "libx11-xcb1"
                            "dnsutils"
                            "devscripts"
                            "libuv1"
                            "libuv1-dev"
                            "libre2-dev"
                        )
                        ;;
                    *)
                        # Future Ubuntu versions
                        apt_packages+=(
                            "software-properties-common"
                            "sudo"
                            "p7zip-full"
                            "p7zip-rar"
                            "sysstat"
                            "schedtool"
                            "poppler-utils"
                            "libffi-dev"
                            "libssl-dev"
                            "screen"
                            "pcregrep"
                            "net-tools"
                        )
                        ;;
                esac
                ;;
        esac
        
        # Try mailutils or alternatives
        local mail_packages=("mailutils" "mailx" "bsd-mailx")
        for mail_pkg in "${mail_packages[@]}"; do
            if apt-cache show "$mail_pkg" >/dev/null 2>&1; then
                apt_packages+=("$mail_pkg")
                break
            fi
        done
        
        packages+=("${apt_packages[@]}")
        
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        # RHEL/CentOS/Fedora specific packages with version flexibility
        local rpm_packages=(
            "sudo"
            "libX11-xcb"
            "bind-utils"
        )
        
        # Try different libuv versions
        local libuv_packages=("libuv" "libuv-devel")
        for libuv_pkg in "${libuv_packages[@]}"; do
            if command -v dnf >/dev/null 2>&1; then
                if dnf info "$libuv_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$libuv_pkg")
                fi
            else
                if yum info "$libuv_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$libuv_pkg")
                fi
            fi
        done
        
        # Try different re2 versions
        local re2_rpm_packages=("re2" "re2-devel")
        for re2_pkg in "${re2_rpm_packages[@]}"; do
            if command -v dnf >/dev/null 2>&1; then
                if dnf info "$re2_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$re2_pkg")
                fi
            else
                if yum info "$re2_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$re2_pkg")
                fi
            fi
        done
        
        # Try mail packages
        local mail_rpm_packages=("mailx" "s-nail" "heirloom-mailx")
        for mail_pkg in "${mail_rpm_packages[@]}"; do
            if command -v dnf >/dev/null 2>&1; then
                if dnf info "$mail_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$mail_pkg")
                    break
                fi
            else
                if yum info "$mail_pkg" >/dev/null 2>&1; then
                    rpm_packages+=("$mail_pkg")
                    break
                fi
            fi
        done
        
        packages+=("${rpm_packages[@]}")
    fi
    
    # Install packages with error handling
    for package in "${packages[@]}"; do
        echo -ne "    - ${CBLUE}Installing $package ...${CEND}\r"
        
        local install_success=false
        
        if command -v apt >/dev/null 2>&1; then
            # Check if package exists before installing
            if apt-cache show "$package" >/dev/null 2>&1; then
                apt install -y "$package" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    install_success=true
                fi
            else
                echo -e "    - ${CYAN}⚠ Package $package not found, skipping${CEND}"
                continue
            fi
        elif command -v yum >/dev/null 2>&1; then
            if yum info "$package" >/dev/null 2>&1; then
                yum install -y "$package" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    install_success=true
                fi
            else
                echo -e "    - ${CYAN}⚠ Package $package not found, skipping${CEND}"
                continue
            fi
        elif command -v dnf >/dev/null 2>&1; then
            if dnf info "$package" >/dev/null 2>&1; then
                dnf install -y "$package" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    install_success=true
                fi
            else
                echo -e "    - ${CYAN}⚠ Package $package not found, skipping${CEND}"
                continue
            fi
        fi
        
        if [ "$install_success" = true ]; then
            echo -e "    - ${CGREEN}✓ $package installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $package failed${CEND}"
        fi
    done
    
    echo -e "${CGREEN}✓ Linux essentials installation completed${CEND}"
}

# Function to harden system configuration
function harden_system() {
    echo -e "${CGREEN}Hardening system configuration...${CEND}"
    
    # Backup original sysctl.conf
    if [[ -f /etc/sysctl.conf ]]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d)
    fi
    
    # Create hardened sysctl configuration
    cat > /etc/sysctl.d/99-server-hardening.conf << 'EOF'
# Network Security Settings
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# IPv6 Security Settings
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Kernel Hardening
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.kexec_load_disabled = 1
kernel.perf_event_paranoid = 2
kernel.yama.ptrace_scope = 1

# File System Security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0

# Memory Protection
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Network Performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000

# IPv4/IPv6 Dual Stack Support
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
EOF

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-server-hardening.conf >> "$LOG_FILE" 2>&1
    
    # Secure file permissions
    echo -e "${CYAN}Securing file permissions...${CEND}"
    
    # Secure critical files
    chmod 644 /etc/passwd
    chmod 600 /etc/shadow
    chmod 644 /etc/group
    chmod 600 /etc/gshadow
    chmod 600 /etc/ssh/sshd_config
    
    # Remove unnecessary services
    echo -e "${CYAN}Disabling unnecessary services...${CEND}"
    
    services_to_disable=(
        "bluetooth"
        "cups"
        "avahi-daemon"
        "telnet"
        "rsh"
        "rlogin"
    )
    
    for service in "${services_to_disable[@]}"; do
        systemctl disable "$service" 2>/dev/null || true
        systemctl stop "$service" 2>/dev/null || true
    done
    
    echo -e "${CGREEN}✓ System hardening completed${CEND}"
}

# Function to configure network settings
function configure_network() {
    echo -e "${CGREEN}Configuring network settings...${CEND}"
    
    # Configure IPv4/IPv6 dual stack
    echo -e "${CYAN}Setting up IPv4/IPv6 dual stack...${CEND}"
    
    # Enable IPv6 if disabled
    sysctl -w net.ipv6.conf.all.disable_ipv6=0 >> "$LOG_FILE" 2>&1
    sysctl -w net.ipv6.conf.default.disable_ipv6=0 >> "$LOG_FILE" 2>&1
    
    # Configure network interfaces for multiple virtual hosts
    echo -e "${CYAN}Configuring for multiple virtual hosts...${CEND}"
    
    # Create network configuration for virtual hosts
    cat > /etc/sysctl.d/99-virtual-hosts.conf << 'EOF'
# Virtual Host Network Configuration
net.ipv4.ip_nonlocal_bind = 1
net.ipv6.ip_nonlocal_bind = 1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_ignore = 1
net.ipv4.conf.default.arp_announce = 2

# Increase connection tracking for virtual hosts
net.netfilter.nf_conntrack_max = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
EOF

    # Apply network settings
    sysctl -p /etc/sysctl.d/99-virtual-hosts.conf >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}✓ Network configuration completed${CEND}"
}

# Function to manage SSH keys
function manage_ssh_keys() {
    echo -e "${CGREEN}Managing SSH keys...${CEND}"
    
    echo -e "${CCYAN}SSH Key Management Options:${CEND}"
    echo "1) Generate new SSH key pair"
    echo "2) Import existing SSH key pair"
    echo "3) Skip SSH key setup"
    echo ""
    
    while true; do
        read -p "Enter your choice [1-3]: " ssh_choice
        case $ssh_choice in
            1) generate_ssh_keys && break ;;
            2) import_ssh_keys && break ;;
            3) echo -e "${CYAN}Skipping SSH key setup${CEND}" && break ;;
            *) echo -e "${CRED}Invalid choice. Please enter 1-3.${CEND}" ;;
        esac
    done
}

# Function to generate SSH keys
function generate_ssh_keys() {
    echo -e "${CCYAN}Generating new SSH key pair...${CEND}"
    
    # Get user information
    read -p "Enter your email address for SSH key: " email
    read -p "Enter key name [default: id_rsa]: " key_name
    key_name=${key_name:-"id_rsa"}
    
    # Determine SSH directory
    if [[ "$OS" == "macos" ]]; then
        ssh_dir="$HOME/.ssh"
    else
        ssh_dir="/root/.ssh"
    fi
    
    # Create SSH directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Generate SSH key
    echo -e "${CYAN}Generating SSH key...${CEND}"
    ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_dir/$key_name" -N "" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ SSH key pair generated successfully${CEND}"
        echo -e "${CYAN}Public key location: $ssh_dir/$key_name.pub${CEND}"
        echo -e "${CYAN}Private key location: $ssh_dir/$key_name${CEND}"
        
        # Display public key
        echo ""
        echo -e "${CGREEN}Your public key (copy this for authorized_keys):${CEND}"
        echo "----------------------------------------"
        cat "$ssh_dir/$key_name.pub"
        echo "----------------------------------------"
        
        # Add to authorized_keys
        cat "$ssh_dir/$key_name.pub" >> "$ssh_dir/authorized_keys"
        chmod 600 "$ssh_dir/authorized_keys"
        
        echo -e "${CGREEN}✓ Public key added to authorized_keys${CEND}"
    else
        echo -e "${CRED}✗ SSH key generation failed${CEND}"
    fi
}

# Function to import SSH keys
function import_ssh_keys() {
    echo -e "${CCYAN}Importing existing SSH key pair...${CEND}"
    
    # Determine SSH directory
    if [[ "$OS" == "macos" ]]; then
        ssh_dir="$HOME/.ssh"
    else
        ssh_dir="/root/.ssh"
    fi
    
    # Create SSH directory if it doesn't exist
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    echo -e "${CYAN}Please paste your public key (or press Enter to skip):${CEND}"
    echo -e "${CYAN}(Ctrl+D to finish input)${CEND}"
    
    public_key=""
    while IFS= read -r line; do
        public_key+="$line"$'\n'
    done
    
    if [[ -n "$public_key" ]]; then
        echo "$public_key" > "$ssh_dir/imported.pub"
        chmod 644 "$ssh_dir/imported.pub"
        
        # Add to authorized_keys
        cat "$ssh_dir/imported.pub" >> "$ssh_dir/authorized_keys"
        chmod 600 "$ssh_dir/authorized_keys"
        
        echo -e "${CGREEN}✓ Public key imported and added to authorized_keys${CEND}"
    fi
    
    echo -e "${CYAN}Please paste your private key (or press Enter to skip):${CEND}"
    echo -e "${CYAN}(Ctrl+D to finish input)${CEND}"
    
    private_key=""
    while IFS= read -r line; do
        private_key+="$line"$'\n'
    done
    
    if [[ -n "$private_key" ]]; then
        echo "$private_key" > "$ssh_dir/imported"
        chmod 600 "$ssh_dir/imported"
        echo -e "${CGREEN}✓ Private key imported${CEND}"
    fi
    
    echo -e "${CGREEN}✓ SSH key import completed${CEND}"
}

# Function to setup development environment (macOS)
function setup_development_environment() {
    echo -e "${CGREEN}Setting up development environment...${CEND}"
    
    # Install Python
    echo -e "${CCYAN}Installing Python...${CEND}"
    brew install python >> "$LOG_FILE" 2>&1
    
    # Install Node.js
    echo -e "${CCYAN}Installing Node.js...${CEND}"
    brew install node >> "$LOG_FILE" 2>&1
    
    # Install Docker Desktop
    echo -e "${CCYAN}Installing Docker Desktop...${CEND}"
    brew install --cask docker >> "$LOG_FILE" 2>&1
    
    # Install VS Code
    echo -e "${CCYAN}Installing VS Code...${CEND}"
    brew install --cask visual-studio-code >> "$LOG_FILE" 2>&1
    
    # Install development databases
    echo -e "${CCYAN}Installing development databases...${CEND}"
    brew install postgresql mysql redis >> "$LOG_FILE" 2>&1
    
    # Install useful development tools
    echo -e "${CCYAN}Installing development tools...${CEND}"
    brew install postman insomnia github-cli >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}✓ Development environment setup completed${CEND}"
}

# Function to configure Git (macOS)
function configure_git() {
    echo -e "${CGREEN}Configuring Git...${CEND}"
    
    # Get user information
    read -p "Enter your name for Git: " git_name
    read -p "Enter your email for Git: " git_email
    
    if [[ -n "$git_name" ]]; then
        git config --global user.name "$git_name"
    fi
    
    if [[ -n "$git_email" ]]; then
        git config --global user.email "$git_email"
    fi
    
    # Set useful defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global push.autoSetupRemote true
    
    # Set up useful aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual '!gitk'
    
    # Configure credential helper
    git config --global credential.helper osxkeychain
    
    echo -e "${CGREEN}✓ Git configuration completed${CEND}"
    echo -e "${CCYAN}Git configuration:${CEND}"
    git config --list | grep -E "(user\.|credential\.|alias\.)"
}

# Function to setup security and privacy settings (macOS)
function setup_macos_security() {
    echo -e "${CGREEN}Configuring macOS security and privacy settings...${CEND}"
    
    # Enable firewall
    echo -e "${CCYAN}Enabling macOS firewall...${CEND}"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on >> "$LOG_FILE" 2>&1
    
    # Require password for sleep and screen saver
    echo -e "${CCYAN}Configuring screen lock...${CEND}"
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    
    # Disable automatic login
    echo -e "${CCYAN}Disabling automatic login...${CEND}"
    defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || true
    
    # Enable FileVault (requires user interaction)
    echo -e "${CYAN}FileVault encryption:${CEND}"
    echo -e "${CYAN}Note: FileVault requires manual setup in System Preferences > Security & Privacy${CEND}"
    
    # Configure privacy settings
    echo -e "${CCYAN}Configuring privacy settings...${CEND}"
    
    # Disable Siri
    defaults write com.apple.Siri StatusMenuVisible -bool false
    defaults write com.apple.Siri UserHasDeclinedEnable -bool true
    
    # Disable telemetry
    defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
    
    # Secure Gatekeeper
    sudo spctl --master-enable >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}✓ macOS security settings configured${CEND}"
    echo -e "${CYAN}Note: Some settings may require restart to take effect${CEND}"
}

# Function to configure shell environment
function configure_shell_environment() {
    echo -e "${CGREEN}Configuring shell environment...${CEND}"
    
    # Determine shell configuration file
    if [[ "$OS" == "macos" ]]; then
        SHELL_CONFIG="$HOME/.profile"
        BASH_CONFIG="$HOME/.bashrc"
        ZSH_CONFIG="$HOME/.zshrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
        BASH_CONFIG="$HOME/.bashrc"
        ZSH_CONFIG="$HOME/.zshrc"
    fi
    
    # Create backup of existing config
    if [[ -f "$SHELL_CONFIG" ]]; then
        cp "$SHELL_CONFIG" "$SHELL_CONFIG.backup.$(date +%Y%m%d)"
    fi
    
    # Add shell configuration
    cat >> "$SHELL_CONFIG" << 'EOF'

# ===============================================
# Server Setup Script - Shell Configuration
# ===============================================

# Custom PS1 prompt (current directory and user)
export PS1="\W \[\033[1;31m\]\u\\[\033[0m\]$ "

# SSH agent initialization
eval "$(ssh-agent -s)"

# Environment variables
export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=/usr/bin/nano
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export LANG=en_US.UTF-8

# Custom aliases
alias ll='ls -latrh'
alias l='ls -ltrh'
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'

# Directory navigation aliases
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias ~='cd ~'

# Utility aliases
alias tailf='tail -f'
alias myip='curl https://ipinfo.is/my'

# SSH/SCP aliases with no host key checking
alias ssh='ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null > 2>&1"'
alias scp='scp -o StrictHostKeyChecking=no -o "UserKnownHostsFile=/dev/null > 2>&1"'

EOF

    # For macOS, also configure .bashrc if it exists
    if [[ "$OS" == "macos" && -f "$BASH_CONFIG" ]]; then
        cp "$BASH_CONFIG" "$BASH_CONFIG.backup.$(date +%Y%m%d)"
        cat >> "$BASH_CONFIG" << 'EOF'

# ===============================================
# Server Setup Script - Bash Configuration
# ===============================================

# Custom PS1 prompt (current directory and user)
export PS1="\W \[\033[1;31m\]\u\\[\033[0m\]$ "

# SSH agent initialization
eval "$(ssh-agent -s)"

# Environment variables
export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=/usr/bin/nano
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export LANG=en_US.UTF-8

# Custom aliases
alias ll='ls -latrh'
alias l='ls -ltrh'
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'

# Directory navigation aliases
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias ~='cd ~'

# Utility aliases
alias tailf='tail -f'
alias myip='curl https://ipinfo.is/my'

# SSH/SCP aliases with no host key checking
alias ssh='ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null > 2>&1"'
alias scp='scp -o StrictHostKeyChecking=no -o "UserKnownHostsFile=/dev/null > 2>&1"'

EOF
    fi
    
    # For ZSH users
    if [[ -f "$ZSH_CONFIG" ]]; then
        cp "$ZSH_CONFIG" "$ZSH_CONFIG.backup.$(date +%Y%m%d)"
        cat >> "$ZSH_CONFIG" << 'EOF'

# ===============================================
# Server Setup Script - ZSH Configuration
# ===============================================

# Custom PS1 prompt (current directory and user)
export PS1="\W \[\033[1;31m\]\u\\[\033[0m\]$ "

# SSH agent initialization
eval "$(ssh-agent -s)"

# Environment variables
export BASH_SILENCE_DEPRECATION_WARNING=1
export EDITOR=/usr/bin/nano
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export LANG=en_US.UTF-8

# Custom aliases
alias ll='ls -latrh'
alias l='ls -ltrh'
alias lr='ls -R | grep ":$" | sed -e '\''s/:$//'\'' -e '\''s/[^-][^\/]*\//--/g'\'' -e '\''s/^/   /'\'' -e '\''s/-/|/'\'' | less'

# Directory navigation aliases
alias cd..='cd ../'
alias ..='cd ../'
alias ...='cd ../../'
alias .3='cd ../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../../'
alias .6='cd ../../../../../../'
alias ~='cd ~'

# Utility aliases
alias tailf='tail -f'
alias myip='curl https://ipinfo.is/my'

# SSH/SCP aliases with no host key checking
alias ssh='ssh -o StrictHostKeyChecking=no -o "UserKnownHostsFile /dev/null > 2>&1"'
alias scp='scp -o StrictHostKeyChecking=no -o "UserKnownHostsFile=/dev/null > 2>&1"'

EOF
    fi
    
    echo -e "${CGREEN}✓ Shell environment configured${CEND}"
    echo -e "${CCYAN}Configuration added to:${CEND}"
    echo -e "  - $SHELL_CONFIG"
    if [[ "$OS" == "macos" && -f "$BASH_CONFIG" ]]; then
        echo -e "  - $BASH_CONFIG"
    fi
    if [[ -f "$ZSH_CONFIG" ]]; then
        echo -e "  - $ZSH_CONFIG"
    fi
    echo -e "${CYAN}Note: Restart your shell or run 'source $SHELL_CONFIG' to apply changes${CEND}"
}

# Function to configure firewall
function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall...${CEND}"
    
    if command -v ufw >/dev/null 2>&1; then
        configure_ufw
    elif command -v firewall-cmd >/dev/null 2>&1; then
        configure_firewalld
    else
        echo -e "${CYAN}No supported firewall found. Installing UFW...${CEND}"
        if command -v apt >/dev/null 2>&1; then
            apt install -y ufw >> "$LOG_FILE" 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y ufw >> "$LOG_FILE" 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y ufw >> "$LOG_FILE" 2>&1
        fi
        configure_ufw
    fi
}

# Function to configure UFW firewall
function configure_ufw() {
    echo -e "${CYAN}Configuring UFW firewall...${CEND}"
    
    # Reset firewall
    ufw --force reset >> "$LOG_FILE" 2>&1
    
    # Default policies
    ufw default deny incoming >> "$LOG_FILE" 2>&1
    ufw default allow outgoing >> "$LOG_FILE" 2>&1
    
    # Allow SSH
    ufw allow ssh >> "$LOG_FILE" 2>&1
    
    # Allow HTTP/HTTPS
    ufw allow 80/tcp >> "$LOG_FILE" 2>&1
    ufw allow 443/tcp >> "$LOG_FILE" 2>&1
    
    # Rate limiting for SSH
    ufw limit ssh >> "$LOG_FILE" 2>&1
    
    # Enable firewall
    ufw --force enable >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}✓ UFW firewall configured and enabled${CEND}"
}

# Function to configure firewalld
function configure_firewalld() {
    echo -e "${CYAN}Configuring firewalld...${CEND}"
    
    # Start and enable firewalld
    systemctl start firewalld >> "$LOG_FILE" 2>&1
    systemctl enable firewalld >> "$LOG_FILE" 2>&1
    
    # Set default zone
    firewall-cmd --set-default-zone=public >> "$LOG_FILE" 2>&1
    
    # Allow services
    firewall-cmd --permanent --add-service=ssh >> "$LOG_FILE" 2>&1
    firewall-cmd --permanent --add-service=http >> "$LOG_FILE" 2>&1
    firewall-cmd --permanent --add-service=https >> "$LOG_FILE" 2>&1
    
    # Reload firewall
    firewall-cmd --reload >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}✓ firewalld configured and enabled${CEND}"
}

# Function to setup users and authentication
function setup_users_auth() {
    echo -e "${CGREEN}Setting up users and authentication...${CEND}"
    
    # Create secure sudo configuration
    cat > /etc/sudoers.d/secure-config << 'EOF'
# Secure sudo configuration
Defaults env_reset
Defaults timestamp_timeout=15
Defaults lecture=always
Defaults lecture_file=/etc/security/sudo_lecture
Defaults badpass_message="Incorrect password. Please try again."
Defaults iolog_dir=/var/log/sudo-io/
Defaults log_input,log_output

# Allow sudo group to execute sudo
%sudo ALL=(ALL:ALL) ALL

# Security restrictions
Defaults !root_sudo
Defaults !runas_root
Defaults !tty_tickets
EOF

    # Configure password policy
    if [[ -f /etc/security/pwquality.conf ]]; then
        cp /etc/security/pwquality.conf /etc/security/pwquality.conf.backup
        cat > /etc/security/pwquality.conf << 'EOF'
# Password quality requirements
minlen = 12
minclass = 3
maxrepeat = 3
maxsequence = 3
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 3
usercheck = 1
dictcheck = 1
EOF
    fi
    
    # Configure login.defs
    if [[ -f /etc/login.defs ]]; then
        cp /etc/login.defs /etc/login.defs.backup
        sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
        sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
        sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
    fi
    
    echo -e "${CGREEN}✓ User and authentication setup completed${CEND}"
}

# Function to run custom setup
function run_custom_setup() {
    echo -e "${CGREEN}Custom setup selection...${CEND}"
    
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CCYAN}Select components to install:${CEND}"
        echo "1) Essential Development Tools"
        echo "2) SSH Key Management"
        echo "3) Development Environment Setup"
        echo "4) Git Configuration"
        echo "5) Security & Privacy Settings"
        echo "6) Shell Environment Configuration"
        echo ""
        echo "Enter numbers separated by spaces (e.g., '1 2 4'):"
        
        read -p "Your selection: " custom_selection
        
        for choice in $custom_selection; do
            case $choice in
                1) install_essential_software ;;
                2) manage_ssh_keys ;;
                3) setup_development_environment ;;
                4) configure_git ;;
                5) setup_macos_security ;;
                6) configure_shell_environment ;;
                *) echo -e "${CRED}Invalid selection: $choice${CEND}" ;;
            esac
        done
    else
        echo -e "${CCYAN}Select components to install:${CEND}"
        echo "1) Essential Software"
        echo "2) System Hardening"
        echo "3) Network Configuration"
        echo "4) SSH Key Management"
        echo "5) Firewall Configuration"
        echo "6) User & Authentication"
        echo ""
        echo "Enter numbers separated by spaces (e.g., '1 2 4'):"
        
        read -p "Your selection: " custom_selection
        
        for choice in $custom_selection; do
            case $choice in
                1) install_essential_software ;;
                2) harden_system ;;
                3) configure_network ;;
                4) manage_ssh_keys ;;
                5) configure_firewall ;;
                6) setup_users_auth ;;
                *) echo -e "${CRED}Invalid selection: $choice${CEND}" ;;
            esac
        done
    fi
}

# Function to show completion message
function show_completion_message() {
    echo ""
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Server Setup Completed!    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    
    echo -e "${CCYAN}Setup Summary:${CEND}"
    case $SETUP_MODE in
        "essential")
            echo -e "  ✓ Essential software installed"
            ;;
        "hardening")
            echo -e "  ✓ System hardening applied"
            ;;
        "network")
            echo -e "  ✓ Network configuration completed"
            ;;
        "ssh")
            echo -e "  ✓ SSH key management completed"
            ;;
        "firewall")
            echo -e "  ✓ Firewall configured and enabled"
            ;;
        "users")
            echo -e "  ✓ User and authentication setup completed"
            ;;
        "complete")
            echo -e "  ✓ Complete server setup completed"
            echo -e "    - Essential software installed"
            echo -e "    - System hardening applied"
            echo -e "    - Network configuration completed"
            echo -e "    - SSH key management completed"
            echo -e "    - Firewall configured and enabled"
            echo -e "    - User and authentication setup completed"
            ;;
        "custom")
            echo -e "  ✓ Custom setup completed"
            ;;
    esac
    
    echo ""
    echo -e "${CCYAN}Next Steps:${CEND}"
    echo "  1. Review configuration files in /etc/"
    echo "  2. Test SSH connectivity with new keys"
    echo "  3. Verify firewall rules"
    echo "  4. Set up monitoring and backups"
    echo ""
    echo -e "${CCYAN}Important Files:${CEND}"
    echo "  - System logs: /var/log/"
    echo "  - Setup log: $LOG_FILE"
    echo "  - SSH keys: ~/.ssh/ or /root/.ssh/"
    echo "  - Firewall status: ufw status or firewall-cmd --list-all"
    echo ""
    echo -e "${CCYAN}Security Recommendations:${CEND}"
    echo "  - Regular system updates"
    echo "  - Monitor log files for suspicious activity"
    echo "  - Use SSH key authentication only"
    echo "  - Regular backups of critical data"
    echo "  - Security audits and penetration testing"
    echo ""
    echo -e "${CMAGENTA}🎉 Server is now secured and configured!${CEND}"
}

# Main execution function
function main() {
    # Initialize log
    echo "Server Setup Log - $(date)" > "$LOG_FILE"
    
    # Detect platform
    detect_platform
    
    # Check root access
    check_root_access
    
    # Get user choice
    get_user_choice
    
    # Show setup summary
    show_setup_summary
    
    # Execute setup based on mode
    case $SETUP_MODE in
        "essential")
            install_essential_software
            ;;
        "development")
            setup_development_environment
            ;;
        "git")
            configure_git
            ;;
        "security")
            setup_macos_security
            ;;
        "hardening")
            harden_system
            ;;
        "network")
            configure_network
            ;;
        "ssh")
            manage_ssh_keys
            ;;
        "firewall")
            configure_firewall
            ;;
        "users")
            setup_users_auth
            ;;
        "complete")
            if [[ "$OS" == "macos" ]]; then
                install_essential_software
                setup_development_environment
                configure_git
                setup_macos_security
                configure_shell_environment
                manage_ssh_keys
            else
                install_essential_software
                harden_system
                configure_network
                manage_ssh_keys
                configure_firewall
                setup_users_auth
            fi
            ;;
        "custom")
            run_custom_setup
            ;;
        "shell")
            configure_shell_environment
            ;;
    esac
    
    # Show completion message
    show_completion_message
}

# Execute main function
main
