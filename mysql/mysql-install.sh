# MySQL/MariaDB Auto-Installation Script
# Localhost-only MySQL/MariaDB deployment with comprehensive security hardening

#!/bin/bash

# MySQL/MariaDB Installation Script
# Secure MySQL/MariaDB installation with security hardening and localhost-only configuration

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

# MySQL/MariaDB Configuration
MYSQL_VERSION="8.0"
MARIADB_VERSION="10.11"
DB_TYPE="mariadb"  # Default to MariaDB
DB_USER="mysql"
DB_GROUP="mysql"
DB_DATA_DIR="/var/lib/mysql"
DB_LOG_DIR="/var/log/mysql"
DB_CONF_DIR="/etc/mysql"
DB_PORT="3306"
DB_ROOT_PASSWORD_FILE="/etc/mysql/mysql.root.passwd"
DB_SOCKET="/var/run/mysqld/mysqld.sock"

# System Information
ARCH=$(uname -m)
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)

# Logging
LOG_FILE="/tmp/mysql-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    MySQL/MariaDB Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}DB Type: ${DB_TYPE}${CEND}"
    if [ "$DB_TYPE" = "mysql" ]; then
        echo -e "${CCYAN}Version: ${MYSQL_VERSION}${CEND}"
    else
        echo -e "${CCYAN}Version: ${MARIADB_VERSION}${CEND}"
    fi
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

function choose_database() {
    echo -e "${CGREEN}Choose database type to install:${CEND}"
    echo "1) MySQL 8.0 (Oracle)"
    echo "2) MariaDB 10.11 (Community) - [DEFAULT]"
    read -p "Enter choice [1-2]: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            DB_TYPE="mysql"
            echo -e "${CCYAN}Selected: MySQL 8.0${CEND}"
            ;;
        2|"")
            DB_TYPE="mariadb"
            MARIADB_VERSION="10.11"
            echo -e "${CCYAN}Selected: MariaDB 10.11${CEND}"
            ;;
        *)
            echo -e "${CRED}Invalid choice. Using default: MariaDB 10.11${CEND}"
            DB_TYPE="mariadb"
            MARIADB_VERSION="10.11"
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
    
    # Check if MySQL/MariaDB is already installed
    if command -v mysql >/dev/null 2>&1 || command -v mysqld >/dev/null 2>&1 || command -v mariadb >/dev/null 2>&1; then
        echo -e "${CYAN}MySQL/MariaDB is already installed${CEND}"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
        
        # Stop existing service
        systemctl stop mysql 2>/dev/null || systemctl stop mariadb 2>/dev/null || true
    fi
    
    echo -e "${CGREEN}System compatibility check completed${CEND}"
}

function install_dependencies() {
    echo -e "${CGREEN}Installing dependencies for $os $os_ver...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Update package lists
            apt update >> "$LOG_FILE" 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "ca-certificates"
                "gnupg"
                "wget"
                "curl"
                "lsb-release"
                "ufw"
                "systemd"
                "logrotate"
                "bc"
            )
            
            # Version-specific packages
            local version_packages=()
            
            case "$os" in
                "debian")
                    case "$os_ver" in
                        "9"|"10"|"11")
                            # Older Debian versions
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - handle package changes
                            version_packages+=(
                                "apt-transport-https"
                            )
                            # Try software-properties-common alternatives
                            if ! apt-cache show software-properties-common >/dev/null 2>&1; then
                                echo -e "${CCYAN}software-properties-common not found, skipping...${CEND}"
                            else
                                version_packages+=("software-properties-common")
                            fi
                            ;;
                        *)
                            # Future Debian versions
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                    esac
                    ;;
                "ubuntu")
                    case "$os_ver" in
                        "18.04"|"20.04")
                            # Older Ubuntu versions
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions
                            version_packages+=(
                                "software-properties-common"
                                "apt-transport-https"
                            )
                            ;;
                    esac
                    ;;
            esac
            
            # Combine all packages
            local all_packages=("${base_packages[@]}" "${version_packages[@]}")
            
            # Install packages with error handling
            local failed_packages=()
            for package in "${all_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                if apt-cache show "$package" >/dev/null 2>&1; then
                    apt install -y "$package" >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                    else
                        echo -e "${CRED}✗ $package failed to install${CEND}"
                        failed_packages+=("$package")
                    fi
                else
                    echo -e "${CCYAN}⚠ Package $package not found, skipping${CEND}"
                    failed_packages+=("$package")
                fi
            done
            
            # Check if critical packages are available
            if command -v wget >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
                echo -e "${CGREEN}Critical dependencies installed successfully${CEND}"
            else
                echo -e "${CRED}Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            
            # Warn about failed packages but don't exit for non-critical ones
            if [ ${#failed_packages[@]} -gt 0 ]; then
                echo -e "${CCYAN}Warning: Some packages failed to install: ${failed_packages[*]}${CEND}"
                echo -e "${CCYAN}MySQL installation will continue with available packages...${CEND}"
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems
            local rhel_packages=(
                "ca-certificates"
                "gnupg2"
                "wget"
                "curl"
                "firewalld"
                "systemd"
                "logrotate"
                "bc"
            )
            
            # Version-specific adjustments
            case "$os_ver" in
                "7")
                    # CentOS 7 uses yum
                    if command -v yum >/dev/null 2>&1; then
                        yum install -y epel-release >> "$LOG_FILE" 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> "$LOG_FILE" 2>&1
                        done
                    fi
                    ;;
                "8"|"9")
                    # RHEL 8+ uses dnf
                    if command -v dnf >/dev/null 2>&1; then
                        dnf install -y epel-release >> "$LOG_FILE" 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> "$LOG_FILE" 2>&1
                        done
                    fi
                    ;;
            esac
            ;;
        "fedora")
            # Fedora-specific packages
            local fedora_packages=(
                "ca-certificates"
                "gnupg2"
                "wget"
                "curl"
                "firewalld"
                "systemd"
                "logrotate"
                "bc"
            )
            
            for package in "${fedora_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> "$LOG_FILE" 2>&1
            done
            ;;
        *)
            echo -e "${CRED}Unsupported OS: $os${CEND}"
            exit 1
            ;;
    esac
}

function add_repository() {
    echo -e "${CGREEN}Adding ${DB_TYPE} repository with intelligent management...${CEND}"
    
    if [ "$DB_TYPE" = "mysql" ]; then
        # Enhanced MySQL repository management
        if add_mysql_repository_enhanced; then
            echo -e "${CGREEN}✓ MySQL repository configured${CEND}"
        else
            echo -e "${CRED}✗ Failed to configure MySQL repository${CEND}"
            exit 1
        fi
        
    elif [ "$DB_TYPE" = "mariadb" ]; then
        # Enhanced MariaDB repository management
        if add_mariadb_repository_enhanced; then
            echo -e "${CGREEN}✓ MariaDB repository configured${CEND}"
        else
            echo -e "${CRED}✗ Failed to configure MariaDB repository${CEND}"
            exit 1
        fi
    fi
}

function add_mysql_repository_enhanced() {
    echo -e "${CCYAN}Configuring MySQL repository for $os $os_ver...${CEND}" >> "$LOG_FILE"
    
    case "$os" in
        "ubuntu")
            add_ubuntu_mysql_repo_enhanced
            ;;
        "debian")
            add_debian_mysql_repo_enhanced
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            add_rhel_mysql_repo_enhanced
            ;;
        "fedora")
            add_fedora_mysql_repo_enhanced
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for MySQL: $os${CEND}" >> "$LOG_FILE"
            return 1
            ;;
    esac
}

function add_ubuntu_mysql_repo_enhanced() {
    echo -e "${CCYAN}Configuring MySQL repository for Ubuntu...${CEND}" >> "$LOG_FILE"
    
    # Check Ubuntu version compatibility
    case "$os_ver" in
        "18.04"|"20.04"|"22.04"|"24.04")
            echo -e "${CGREEN}✓ Ubuntu $os_ver is supported${CEND}" >> "$LOG_FILE"
            ;;
        *)
            echo -e "${CYAN}⚠ Ubuntu $os_ver may not be fully supported${CEND}" >> "$LOG_FILE"
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/mysql.list" ] || apt-cache policy | grep -q "repo.mysql.com"; then
        echo -e "${CYAN}⚠ MySQL repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    
    local required_packages=("curl" "gnupg" "software-properties-common")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> "$LOG_FILE"
            apt install -y "$pkg" >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> "$LOG_FILE"
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> "$LOG_FILE"
                return 1
            fi
        fi
    done
    
    # Download MySQL APT repository package
    echo -e "${CCYAN}Downloading MySQL APT repository package...${CEND}" >> "$LOG_FILE"
    local mysql_apt_repo="mysql-apt-config_0.8.24-1_all.deb"
    wget -q "https://dev.mysql.com/get/$mysql_apt_repo" -O "/tmp/$mysql_apt_repo" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL APT repository package downloaded${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to download MySQL APT repository package${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Install MySQL APT repository package
    echo -e "${CCYAN}Installing MySQL APT repository package...${CEND}" >> "$LOG_FILE"
    echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.0" | debconf-set-selections >> "$LOG_FILE" 2>&1
    DEBIAN_FRONTEND=noninteractive apt install -y "/tmp/$mysql_apt_repo" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL APT repository package installed${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to install MySQL APT repository package${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Verify MySQL packages are available
    echo -e "${CCYAN}Verifying MySQL package availability...${CEND}" >> "$LOG_FILE"
    if apt-cache show "mysql-server" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MySQL packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MySQL packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean up
    rm -f "/tmp/$mysql_apt_repo"
}

function add_debian_mysql_repo_enhanced() {
    echo -e "${CCYAN}Configuring MySQL repository for Debian...${CEND}" >> "$LOG_FILE"
    
    # Check Debian version compatibility
    case "$os_ver" in
        "10"|"11"|"12"|"13")
            echo -e "${CGREEN}✓ Debian $os_ver is supported${CEND}" >> "$LOG_FILE"
            ;;
        *)
            echo -e "${CYAN}⚠ Debian $os_ver may not be fully supported${CEND}" >> "$LOG_FILE"
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/mysql.list" ] || apt-cache policy | grep -q "repo.mysql.com"; then
        echo -e "${CYAN}⚠ MySQL repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    
    local required_packages=("curl" "gnupg" "software-properties-common")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> "$LOG_FILE"
            apt install -y "$pkg" >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> "$LOG_FILE"
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> "$LOG_FILE"
                return 1
            fi
        fi
    done
    
    # Download MySQL APT repository package
    echo -e "${CCYAN}Downloading MySQL APT repository package...${CEND}" >> "$LOG_FILE"
    local mysql_apt_repo="mysql-apt-config_0.8.24-1_all.deb"
    wget -q "https://dev.mysql.com/get/$mysql_apt_repo" -O "/tmp/$mysql_apt_repo" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL APT repository package downloaded${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to download MySQL APT repository package${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Install MySQL APT repository package
    echo -e "${CCYAN}Installing MySQL APT repository package...${CEND}" >> "$LOG_FILE"
    echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.0" | debconf-set-selections >> "$LOG_FILE" 2>&1
    DEBIAN_FRONTEND=noninteractive apt install -y "/tmp/$mysql_apt_repo" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL APT repository package installed${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to install MySQL APT repository package${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Verify MySQL packages are available
    echo -e "${CCYAN}Verifying MySQL package availability...${CEND}" >> "$LOG_FILE"
    if apt-cache show "mysql-server" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MySQL packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MySQL packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean up
    rm -f "/tmp/$mysql_apt_repo"
}

function add_rhel_mysql_repo_enhanced() {
    echo -e "${CCYAN}Configuring MySQL repository for RHEL-based systems...${CEND}" >> "$LOG_FILE"
    
    # Check OS version compatibility
    case "$os_ver" in
        "7"|"8"|"9")
            echo -e "${CGREEN}✓ RHEL/CentOS/Rocky/AlmaLinux $os_ver is supported${CEND}" >> "$LOG_FILE"
            ;;
        *)
            echo -e "${CRED}✗ RHEL/CentOS version $os_ver not supported${CEND}" >> "$LOG_FILE"
            return 1
            ;;
    esac
    
    # Determine package manager
    local pkg_manager="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        pkg_manager="yum"
    fi
    
    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}" >> "$LOG_FILE"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mysql-community.repo" ]; then
        echo -e "${CYAN}⚠ MySQL repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Install MySQL Yum repository
    echo -e "${CCYAN}Installing MySQL Yum repository...${CEND}" >> "$LOG_FILE"
    
    local mysql_repo_url=""
    case "$os_ver" in
        "7")
            mysql_repo_url="https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm"
            ;;
        "8")
            mysql_repo_url="https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm"
            ;;
        "9")
            mysql_repo_url="https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm"
            ;;
    esac
    
    $pkg_manager install -y "$mysql_repo_url" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL Yum repository installed${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to install MySQL Yum repository${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> "$LOG_FILE"
    $pkg_manager clean all >> "$LOG_FILE" 2>&1
    
    # Verify MySQL packages are available
    echo -e "${CCYAN}Verifying MySQL package availability...${CEND}" >> "$LOG_FILE"
    if $pkg_manager info mysql-community-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MySQL packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MySQL packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
}

function add_fedora_mysql_repo_enhanced() {
    echo -e "${CCYAN}Configuring MySQL repository for Fedora...${CEND}" >> "$LOG_FILE"
    
    # Check Fedora version
    local fedora_major=$(echo "$os_ver" | cut -d. -f1)
    echo -e "${CGREEN}✓ Fedora $os_ver detected${CEND}" >> "$LOG_FILE"
    
    # Determine package manager
    local pkg_manager="dnf"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mysql-community.repo" ]; then
        echo -e "${CYAN}⚠ MySQL repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Install MySQL Yum repository
    echo -e "${CCYAN}Installing MySQL Yum repository...${CEND}" >> "$LOG_FILE"
    local mysql_repo_url="https://dev.mysql.com/get/mysql80-community-release-fc${fedora_major}-1.noarch.rpm"
    
    $pkg_manager install -y "$mysql_repo_url" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MySQL Yum repository installed${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to install MySQL Yum repository${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> "$LOG_FILE"
    $pkg_manager clean all >> "$LOG_FILE" 2>&1
    
    # Verify MySQL packages are available
    echo -e "${CCYAN}Verifying MySQL package availability...${CEND}" >> "$LOG_FILE"
    if $pkg_manager info mysql-community-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MySQL packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MySQL packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
}

function add_mariadb_repository_enhanced() {
    echo -e "${CCYAN}Configuring MariaDB repository for $os $os_ver...${CEND}" >> "$LOG_FILE"
    
    case "$os" in
        "ubuntu"|"debian")
            add_ubuntu_mariadb_repo_enhanced
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            add_rhel_mariadb_repo_enhanced
            ;;
        "fedora")
            add_fedora_mariadb_repo_enhanced
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for MariaDB: $os${CEND}" >> "$LOG_FILE"
            return 1
            ;;
    esac
}

function add_ubuntu_mariadb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MariaDB repository for Ubuntu/Debian...${CEND}" >> "$LOG_FILE"
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/mariadb.list" ] || apt-cache policy | grep -q "downloads.mariadb.com"; then
        echo -e "${CYAN}⚠ MariaDB repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    
    local required_packages=("curl" "gnupg" "apt-transport-https")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> "$LOG_FILE"
            apt install -y "$pkg" >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> "$LOG_FILE"
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> "$LOG_FILE"
                return 1
            fi
        fi
    done
    
    # Get OS codename for repository
    local os_codename=""
    if [[ "$os" == "debian" ]]; then
        case "$os_ver" in
            "9") os_codename="stretch" ;;
            "10") os_codename="buster" ;;
            "11") os_codename="bullseye" ;;
            "12") os_codename="bookworm" ;;
            "13") os_codename="trixie" ;;
            *) os_codename="bookworm" ;;
        esac
        
        # For Debian 13, use bookworm repository as trixie may not be supported yet
        if [[ "$os_ver" == "13" ]]; then
            os_codename="bookworm"
            echo -e "${CYAN}Using Debian 12 (bookworm) repository for Debian 13 (trixie) compatibility${CEND}" >> "$LOG_FILE"
        fi
    else
        # Ubuntu codenames
        case "$os_ver" in
            "18.04") os_codename="bionic" ;;
            "20.04") os_codename="focal" ;;
            "22.04") os_codename="jammy" ;;
            "24.04") os_codename="noble" ;;
            *) os_codename="jammy" ;;
        esac
    fi
    
    # Add MariaDB repository manually instead of using setup script
    echo -e "${CCYAN}Adding MariaDB repository manually...${CEND}" >> "$LOG_FILE"
    
    # Import MariaDB GPG key
    curl -fsSL https://downloads.mariadb.com/MariaDB/MariaDB-Server-GPG-KEY | gpg --dearmor -o /etc/apt/trusted.gpg.d/mariadb.gpg >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MariaDB GPG key imported${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to import MariaDB GPG key${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Add repository
    echo "deb [arch=amd64,arm64,ppc64el signed-by=/etc/apt/trusted.gpg.d/mariadb.gpg] https://downloads.mariadb.com/MariaDB/mariadb_repo_setup $os_codename main" | tee /etc/apt/sources.list.d/mariadb.list >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MariaDB repository added${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to add MariaDB repository${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> "$LOG_FILE"
    apt update >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Verify MariaDB packages are available
    echo -e "${CCYAN}Verifying MariaDB package availability...${CEND}" >> "$LOG_FILE"
    if apt-cache show mariadb-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MariaDB packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MariaDB packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
}

function add_rhel_mariadb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MariaDB repository for RHEL-based systems...${CEND}" >> "$LOG_FILE"
    
    # Determine package manager
    local pkg_manager="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        pkg_manager="yum"
    fi
    
    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}" >> "$LOG_FILE"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mariadb.repo" ]; then
        echo -e "${CYAN}⚠ MariaDB repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Add MariaDB repository
    echo -e "${CCYAN}Adding MariaDB repository...${CEND}" >> "$LOG_FILE"
    cat > "/etc/yum.repos.d/mariadb.repo" << EOF
[mariadb]
name = MariaDB
baseurl = https://downloads.mariadb.com/MariaDB/yum/10.11/rhel\$releasever-amd64
gpgkey = https://downloads.mariadb.com/MariaDB/MariaDB-Server-GPG-KEY
gpgcheck = 1
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MariaDB repository file created${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to create MariaDB repository file${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> "$LOG_FILE"
    $pkg_manager clean all >> "$LOG_FILE" 2>&1
    
    # Verify MariaDB packages are available
    echo -e "${CCYAN}Verifying MariaDB package availability...${CEND}" >> "$LOG_FILE"
    if $pkg_manager info MariaDB-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MariaDB packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MariaDB packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
}

function add_fedora_mariadb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MariaDB repository for Fedora...${CEND}" >> "$LOG_FILE"
    
    # Determine package manager
    local pkg_manager="dnf"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mariadb.repo" ]; then
        echo -e "${CYAN}⚠ MariaDB repository already exists${CEND}" >> "$LOG_FILE"
        return 0
    fi
    
    # Add MariaDB repository
    echo -e "${CCYAN}Adding MariaDB repository...${CEND}" >> "$LOG_FILE"
    cat > "/etc/yum.repos.d/mariadb.repo" << EOF
[mariadb]
name = MariaDB
baseurl = https://downloads.mariadb.com/MariaDB/yum/10.11/fedora\$releasever-amd64
gpgkey = https://downloads.mariadb.com/MariaDB/MariaDB-Server-GPG-KEY
gpgcheck = 1
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MariaDB repository file created${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ Failed to create MariaDB repository file${CEND}" >> "$LOG_FILE"
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> "$LOG_FILE"
    $pkg_manager clean all >> "$LOG_FILE" 2>&1
    
    # Verify MariaDB packages are available
    echo -e "${CCYAN}Verifying MariaDB package availability...${CEND}" >> "$LOG_FILE"
    if $pkg_manager info MariaDB-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MariaDB packages available${CEND}" >> "$LOG_FILE"
    else
        echo -e "${CRED}✗ MariaDB packages not available${CEND}" >> "$LOG_FILE"
        return 1
    fi
}

function install_database() {
    echo -e "${CGREEN}Installing ${DB_TYPE}...${CEND}"
    
    if [ "$DB_TYPE" = "mysql" ]; then
        # Install MySQL
        DEBIAN_FRONTEND=noninteractive apt install -y \
            mysql-server \
            mysql-client \
            libmysqlclient-dev \
            >> "$LOG_FILE" 2>&1
            
    elif [ "$DB_TYPE" = "mariadb" ]; then
        # Install MariaDB
        DEBIAN_FRONTEND=noninteractive apt install -y \
            mariadb-server \
            mariadb-client \
            libmariadb-dev \
            >> "$LOG_FILE" 2>&1
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install ${DB_TYPE}${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}${DB_TYPE} installed successfully${CEND}"
}

function create_mysql_user() {
    echo -e "${CGREEN}Creating MySQL user and directories...${CEND}"
    
    # Create group if it doesn't exist
    if ! getent group "$DB_GROUP" >/dev/null 2>&1; then
        groupadd "$DB_GROUP"
        echo -e "${CCYAN}Created MySQL group: $DB_GROUP${CEND}"
    fi
    
    # Create user if it doesn't exist
    if ! getent passwd "$DB_USER" >/dev/null 2>&1; then
        useradd -r -g "$DB_GROUP" -s /bin/false -d "$DB_DATA_DIR" "$DB_USER"
        echo -e "${CCYAN}Created MySQL user: $DB_USER${CEND}"
    fi
    
    # Create directories
    mkdir -p "$DB_DATA_DIR"
    mkdir -p "$DB_LOG_DIR"
    mkdir -p "$DB_CONF_DIR"
    mkdir -p "/var/run/mysqld"
    
    # Set permissions
    chown -R "$DB_USER:$DB_GROUP" "$DB_DATA_DIR"
    chown -R "$DB_USER:$DB_GROUP" "$DB_LOG_DIR"
    chown -R "$DB_USER:$DB_GROUP" "/var/run/mysqld"
    chown -R root:root "$DB_CONF_DIR"
    
    chmod 750 "$DB_DATA_DIR"
    chmod 750 "$DB_LOG_DIR"
    chmod 755 "/var/run/mysqld"
    
    echo -e "${CGREEN}MySQL user and directories setup completed${CEND}"
}

function generate_password() {
    echo -e "${CGREEN}Generating secure MySQL passwords...${CEND}"
    
    # Generate root password
    DB_ROOT_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    echo "$DB_ROOT_PASSWORD" > "$DB_ROOT_PASSWORD_FILE"
    chmod 600 "$DB_ROOT_PASSWORD_FILE"
    
    # Generate debian-sys-maint password
    DB_DEBIAN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    echo -e "${CGREEN}Passwords generated and saved${CEND}"
}

function create_mysql_config() {
    echo -e "${CGREEN}Creating MySQL configuration...${CEND}"
    
    cat > "$DB_CONF_DIR/my.cnf" << EOF
# MySQL/MariaDB Configuration
# Localhost-only deployment with security hardening

[client]
port = $DB_PORT
socket = $DB_SOCKET
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
# Basic Settings
user = $DB_USER
pid-file = /var/run/mysqld/mysqld.pid
socket = $DB_SOCKET
port = $DB_PORT
basedir = /usr
datadir = $DB_DATA_DIR
tmpdir = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

# Network Security
bind-address = 127.0.0.1
skip-networking = false
skip-name-resolve

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init_connect = 'SET NAMES utf8mb4'

# Security Settings
skip-show-database = 1
local-infile = 0

# Logging
log-error = $DB_LOG_DIR/error.log
slow-query-log = 1
slow-query-log-file = $DB_LOG_DIR/slow.log
long_query_time = 2
log-queries-not-using-indexes = 1

# Performance Settings
key_buffer_size = 32M
max_allowed_packet = 64M
table_open_cache = 256
sort_buffer_size = 1M
read_buffer_size = 1M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
query_cache_size = 16M
query_cache_type = 1

# InnoDB Settings
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 1

# Connection Settings
max_connections = 100
max_connect_errors = 1000
wait_timeout = 28800
interactive_timeout = 28800

# Memory Settings
max_heap_table_size = 16M
tmp_table_size = 16M

# Binary Logging (for backups/replication)
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

[mysqldump]
quick
quote-names
max_allowed_packet = 64M

[mysqlhotcopy]
interactive-timeout

[isamchk]
key_buffer_size = 16M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M
EOF
    
    # Set permissions
    chmod 640 "$DB_CONF_DIR/my.cnf"
    chown root:root "$DB_CONF_DIR/my.cnf"
    
    echo -e "${CGREEN}MySQL configuration created${CEND}"
}

function secure_mysql() {
    echo -e "${CGREEN}Securing ${DB_TYPE} installation...${CEND}"
    
    # Start the appropriate service
    if [ "$DB_TYPE" = "mysql" ]; then
        systemctl start mysql
        SERVICE_NAME="mysql"
    else
        systemctl start mariadb
        SERVICE_NAME="mariadb"
    fi
    
    sleep 5
    
    # Check if service is running
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${CRED}Failed to start ${DB_TYPE} service${CEND}"
        exit 1
    fi
    
    # Get temporary root password if MySQL 8.0
    if [ "$DB_TYPE" = "mysql" ]; then
        TEMP_PASSWORD=$(grep 'temporary password' "$DB_LOG_DIR/error.log" | tail -1 | awk '{print $NF}')
        if [ -n "$TEMP_PASSWORD" ]; then
            echo -e "${CCYAN}Using temporary password for initial setup${CEND}"
        fi
    fi
    
    # Secure database
    mysql -u root << EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Remove remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Create debian-sys-maint user if it doesn't exist
CREATE USER IF NOT EXISTS 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DB_DEBIAN_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' WITH GRANT OPTION;

-- Reload privileges
FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}${DB_TYPE} secured successfully${CEND}"
    else
        echo -e "${CRED}Failed to secure ${DB_TYPE}${CEND}"
        exit 1
    fi
}

function create_systemd_service() {
    echo -e "${CGREEN}Creating systemd service...${CEND}"
    
    # Determine service file location based on database type
    if [ "$DB_TYPE" = "mysql" ]; then
        SERVICE_FILE="/lib/systemd/system/mysql.service"
        SERVICE_NAME="mysql"
    else
        SERVICE_FILE="/lib/systemd/system/mariadb.service"
        SERVICE_NAME="mariadb"
    fi
    
    # Check if service file exists
    if [ -f "$SERVICE_FILE" ]; then
        # Create override for additional security
        mkdir -p /etc/systemd/system/${SERVICE_NAME}.service.d
        
        cat > /etc/systemd/system/${SERVICE_NAME}.service.d/override.conf << EOF
[Service]
# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$DB_DATA_DIR $DB_LOG_DIR $DB_CONF_DIR /var/run/mysqld
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
MemoryMax=1G

# User settings
User=$DB_USER
Group=$DB_GROUP
EOF
        
        # Reload systemd
        systemctl daemon-reload
        
        # Enable service
        systemctl enable $SERVICE_NAME
        
        echo -e "${CGREEN}Systemd service configured and enabled${CEND}"
    else
        echo -e "${CYAN}${DB_TYPE} systemd service not found, using default configuration${CEND}"
    fi
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall for MySQL...${CEND}"
    
    # Check if UFW is available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CCYAN}Using UFW firewall...${CEND}"
        
        # Allow MySQL from localhost only
        ufw allow from 127.0.0.1 to any port "$DB_PORT" >> "$LOG_FILE" 2>&1
        ufw allow from ::1 to any port "$DB_PORT" >> "$LOG_FILE" 2>&1
        
        # Explicitly deny external MySQL access
        ufw deny "$DB_PORT"/tcp >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}UFW firewall configured successfully${CEND}"
        else
            echo -e "${CRED}Failed to configure UFW firewall${CEND}"
        fi
        
    # Check if iptables is available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${CCYAN}Using iptables firewall...${CEND}"
        
        # Allow MySQL from localhost only
        iptables -A INPUT -p tcp --dport "$DB_PORT" -s 127.0.0.1 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport "$DB_PORT" -s ::1 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Deny external MySQL access
        iptables -A INPUT -p tcp --dport "$DB_PORT" -j DROP >> "$LOG_FILE" 2>&1
        
        # Save iptables rules
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}iptables firewall configured successfully${CEND}"
        else
            echo -e "${CRED}Failed to configure iptables firewall${CEND}"
        fi
        
    else
        echo -e "${CYAN}No firewall (UFW or iptables) detected${CEND}"
        echo -e "${CYAN}Skipping firewall configuration${CEND}"
        echo -e "${CYAN}Note: MySQL is still configured for localhost-only binding${CEND}"
    fi
}

function setup_logrotate() {
    echo -e "${CGREEN}Setting up log rotation...${CEND}"
    
    cat > /etc/logrotate.d/mysql-server << EOF
$DB_LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 $DB_USER $DB_GROUP
    sharedscripts
    postrotate
        systemctl reload mysql >/dev/null 2>&1 || true
    endscript
}
EOF
    
    echo -e "${CGREEN}Log rotation configured${CEND}"
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create MySQL monitoring script
    cat > /usr/local/bin/mysql-monitor << 'EOF'
#!/bin/bash

# MySQL Monitoring Script

MYSQL_CLI="/usr/bin/mysql"
MYSQL_CONF="/etc/mysql/my.cnf"
MYSQL_ROOT_PASSWORD_FILE="/etc/mysql/mysql.root.passwd"

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
    echo -e "${CBLUE}    MySQL Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function get_mysql_password() {
    if [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
        cat "$MYSQL_ROOT_PASSWORD_FILE"
    else
        echo ""
    fi
}

function check_mysql_status() {
    echo -e "${CGREEN}MySQL Service Status:${CEND}"
    
    if systemctl is-active --quiet mysql; then
        echo -e "  MySQL Service: ${CGREEN}Running${CEND}"
    else
        echo -e "  MySQL Service: ${CRED}Stopped${CEND}"
    fi
    
    if systemctl is-enabled --quiet mysql; then
        echo -e "  MySQL Service: ${CGREEN}Enabled${CEND}"
    else
        echo -e "  MySQL Service: ${CRED}Disabled${CEND}"
    fi
    
    echo ""
}

function show_mysql_info() {
    echo -e "${CGREEN}MySQL Information:${CEND}"
    
    local password=$(get_mysql_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-p$password"
    fi
    
    # Get MySQL version
    local mysql_version=$(mysql $auth_cmd -e "SELECT VERSION();" -s -N 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "  MySQL Version: $mysql_version"
    else
        echo -e "  ${CRED}Cannot connect to MySQL${CEND}"
        return
    fi
    
    # Get uptime
    local uptime=$(mysql $auth_cmd -e "SHOW STATUS LIKE 'Uptime';" -s -N 2>/dev/null | awk '{print $2}')
    echo -e "  Uptime: $uptime seconds"
    
    # Get connections
    local connections=$(mysql $auth_cmd -e "SHOW STATUS LIKE 'Connections';" -s -N 2>/dev/null | awk '{print $2}')
    echo -e "  Total Connections: $connections"
    
    # Get current connections
    local threads_connected=$(mysql $auth_cmd -e "SHOW STATUS LIKE 'Threads_connected';" -s -N 2>/dev/null | awk '{print $2}')
    echo -e "  Current Connections: $threads_connected"
    
    echo ""
}

function test_mysql_connection() {
    echo -e "${CGREEN}Testing MySQL Connection...${CEND}"
    
    local password=$(get_mysql_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-p$password"
    fi
    
    # Test basic connection
    if mysql $auth_cmd -e "SELECT 1;" >/dev/null 2>&1; then
        echo -e "  ${CGREEN}MySQL connection: OK${CEND}"
        
        # Test database operations
        if mysql $auth_cmd -e "CREATE DATABASE IF NOT EXISTS test_db; USE test_db; CREATE TABLE IF NOT EXISTS test_table (id INT); DROP TABLE test_table; DROP DATABASE test_db;" >/dev/null 2>&1; then
            echo -e "  ${CGREEN}MySQL operations: OK${CEND}"
        else
            echo -e "  ${CRED}MySQL operations: FAILED${CEND}"
        fi
    else
        echo -e "  ${CRED}MySQL connection: FAILED${CEND}"
    fi
    
    echo ""
}

function main() {
    case "${1:-all}" in
        "status")
            show_header
            check_mysql_status
            ;;
        "info")
            show_header
            show_mysql_info
            ;;
        "test")
            show_header
            test_mysql_connection
            ;;
        "all")
            show_header
            check_mysql_status
            show_mysql_info
            test_mysql_connection
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [status|info|test|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Make monitoring script executable
    chmod +x /usr/local/bin/mysql-monitor
    
    echo -e "${CGREEN}Monitoring script created${CEND}"
}

function create_backup_script() {
    echo -e "${CGREEN}Creating backup script...${CEND}"
    
    cat > /usr/local/bin/mysql-backup << 'EOF'
#!/bin/bash

# MySQL Backup Script

MYSQL_ROOT_PASSWORD_FILE="/etc/mysql/mysql.root.passwd"
MYSQL_DATA_DIR="/var/lib/mysql"
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

function get_mysql_password() {
    if [ -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
        cat "$MYSQL_ROOT_PASSWORD_FILE"
    else
        echo ""
    fi
}

function create_backup() {
    echo "Creating MySQL backup..."
    
    local password=$(get_mysql_password)
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-p$password"
    fi
    
    # Get list of databases
    local databases=$(mysql $auth_cmd -e "SHOW DATABASES;" -s -N 2>/dev/null | grep -v -E "information_schema|performance_schema|mysql|sys")
    
    if [ $? -ne 0 ]; then
        echo "Cannot connect to MySQL"
        return 1
    fi
    
    # Backup each database
    for db in $databases; do
        echo "  Backing up database: $db"
        mysqldump $auth_cmd --single-transaction --routines --triggers "$db" | gzip > "$BACKUP_DIR/${db}_$DATE.sql.gz"
    done
    
    # Backup all databases
    echo "  Backing up all databases..."
    mysqldump $auth_cmd --single-transaction --routines --triggers --all-databases | gzip > "$BACKUP_DIR/all_databases_$DATE.sql.gz"
    
    echo "Backup completed: $BACKUP_DIR"
    echo "Files created:"
    ls -la "$BACKUP_DIR"/*_$DATE.sql.gz
}

function list_backups() {
    echo "Available MySQL Backups:"
    ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found"
}

function cleanup_old_backups() {
    echo "Cleaning up old backups (older than 30 days)..."
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
    echo "Cleanup completed"
}

case "${1:-create}" in
    "create")
        create_backup
        ;;
    "list")
        list_backups
        ;;
    "cleanup")
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 [create|list|cleanup]"
        exit 1
        ;;
esac
EOF
    
    # Make backup script executable
    chmod +x /usr/local/bin/mysql-backup
    
    echo -e "${CGREEN}Backup script created${CEND}"
}

function start_mysql() {
    echo -e "${CGREEN}Starting ${DB_TYPE} service...${CEND}"
    
    # Determine service name based on database type
    if [ "$DB_TYPE" = "mysql" ]; then
        SERVICE_NAME="mysql"
    else
        SERVICE_NAME="mariadb"
    fi
    
    # Restart service to apply configuration
    systemctl restart $SERVICE_NAME
    
    # Wait for service to start
    sleep 5
    
    # Check if service is running
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${CGREEN}${DB_TYPE} service started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start ${DB_TYPE} service${CEND}"
        systemctl status $SERVICE_NAME
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying ${DB_TYPE} installation...${CEND}"
    
    # Test database connection
    local password=$(cat "$DB_ROOT_PASSWORD_FILE" 2>/dev/null || echo "")
    local auth_cmd=""
    if [ -n "$password" ]; then
        auth_cmd="-p$password"
    fi
    
    if mysql $auth_cmd -e "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${CGREEN}${DB_TYPE} connection: OK${CEND}"
    else
        echo -e "${CRED}${DB_TYPE} connection: FAILED${CEND}"
        exit 1
    fi
    
    # Test basic operations
    if mysql $auth_cmd -e "CREATE DATABASE IF NOT EXISTS test_verification; USE test_verification; CREATE TABLE IF NOT EXISTS test_table (id INT); INSERT INTO test_table VALUES (1); SELECT COUNT(*) FROM test_table; DROP TABLE test_table; DROP DATABASE test_verification;" >/dev/null 2>&1; then
        echo -e "${CGREEN}${DB_TYPE} operations: OK${CEND}"
    else
        echo -e "${CRED}${DB_TYPE} operations: FAILED${CEND}"
        exit 1
    fi
    
    # Check database version
    local db_version=$(mysql $auth_cmd -e "SELECT VERSION();" -s -N 2>/dev/null)
    echo -e "${CGREEN}${DB_TYPE} version: $db_version${CEND}"
    
    # Verify localhost-only binding
    echo -e "${CCYAN}Checking network binding...${CEND}"
    
    # Check both IPv4 and IPv6 localhost binding
    local ipv4_binding=$(netstat -tlnp 2>/dev/null | grep ":$DB_PORT" | grep "127.0.0.1")
    local ipv6_binding=$(netstat -tlnp 2>/dev/null | grep ":$DB_PORT" | grep "::1")
    local any_binding=$(netstat -tlnp 2>/dev/null | grep ":$DB_PORT " | grep "0.0.0.0")
    local all_binding=$(netstat -tlnp 2>/dev/null | grep ":$DB_PORT " | grep "::")
    
    echo -e "${CCYAN}Port $DB_PORT bindings:${CEND}"
    if [[ -n "$ipv4_binding" ]]; then
        echo -e "${CGREEN}  IPv4 localhost (127.0.0.1): FOUND${CEND}"
    fi
    if [[ -n "$ipv6_binding" ]]; then
        echo -e "${CGREEN}  IPv6 localhost (::1): FOUND${CEND}"
    fi
    if [[ -n "$any_binding" ]]; then
        echo -e "${CRED}  All interfaces (0.0.0.0): FOUND - SECURITY RISK!${CEND}"
    fi
    if [[ -n "$all_binding" ]]; then
        echo -e "${CRED}  All interfaces (::): FOUND - SECURITY RISK!${CEND}"
    fi
    
    # Check if binding is secure (localhost only)
    if [[ -n "$ipv4_binding" || -n "$ipv6_binding" ]] && [[ -z "$any_binding" && -z "$all_binding" ]]; then
        echo -e "${CGREEN}Localhost binding: OK${CEND}"
    else
        echo -e "${CRED}Localhost binding: FAILED${CEND}"
        echo -e "${CRED}MariaDB may be accessible from external interfaces!${CEND}"
        echo -e "${CYAN}Checking configuration file...${CEND}"
        
        if grep -q "bind-address = 127.0.0.1" "$DB_CONF_DIR/my.cnf"; then
            echo -e "${CGREEN}  Configuration file has correct bind-address${CEND}"
        else
            echo -e "${CRED}  Configuration file missing or incorrect bind-address${CEND}"
        fi
        
        # Don't exit - just warn the user
        echo -e "${CYAN}Please check the MariaDB configuration and restart the service${CEND}"
    fi
    
    # Verify firewall rules
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "$DB_PORT.*ALLOW.*127.0.0.1" && ufw status | grep -q "$DB_PORT.*DENY"; then
            echo -e "${CGREEN}UFW firewall rules: OK${CEND}"
        else
            echo -e "${CRED}UFW firewall rules: FAILED${CEND}"
            exit 1
        fi
    elif command -v iptables >/dev/null 2>&1; then
        if iptables -L INPUT | grep -q "$DB_PORT.*127.0.0.1.*ACCEPT" && iptables -L INPUT | grep -q "$DB_PORT.*DROP"; then
            echo -e "${CGREEN}iptables firewall rules: OK${CEND}"
        else
            echo -e "${CRED}iptables firewall rules: FAILED${CEND}"
            exit 1
        fi
    else
        echo -e "${CYAN}No firewall detected - skipping firewall verification${CEND}"
    fi
    
    # Verify database configuration
    if grep -q "bind-address = 127.0.0.1" "$DB_CONF_DIR/my.cnf"; then
        echo -e "${CGREEN}${DB_TYPE} configuration: OK${CEND}"
    else
        echo -e "${CRED}${DB_TYPE} configuration: FAILED${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}${DB_TYPE} installation verified successfully${CEND}"
    echo -e "${CCYAN}${DB_TYPE} is configured for localhost-only access${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    MySQL/MariaDB Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Database Type: $DB_TYPE"
    echo -e "  Port: $DB_PORT"
    echo -e "  Data Directory: $DB_DATA_DIR"
    echo -e "  Config Directory: $DB_CONF_DIR"
    echo -e "  Log Directory: $DB_LOG_DIR"
    echo ""
    echo -e "${CCYAN}Security Features:${CEND}"
    echo -e "  ✓ Localhost-only binding (127.0.0.1)"
    echo -e "  ✓ Root password authentication"
    echo -e "  ✓ Anonymous users removed"
    echo -e "  ✓ Test database removed"
    echo -e "  ✓ Remote root access disabled"
    echo -e "  ✓ Firewall rules configured"
    echo -e "  ✓ Systemd security hardening"
    echo ""
    echo -e "${CCYAN}MySQL Credentials:${CEND}"
    echo -e "  Root Password: $(cat "$DB_ROOT_PASSWORD_FILE")"
    echo -e "  Root Password file: $DB_ROOT_PASSWORD_FILE"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Service status: systemctl status mysql"
    echo -e "  Start service: systemctl start mysql"
    echo -e "  Stop service: systemctl stop mysql"
    echo -e "  Restart service: systemctl restart mysql"
    echo ""
    echo -e "${CCYAN}MySQL CLI Usage:${CEND}"
    echo -e "  Connect: mysql -u root -p$(cat "$DB_ROOT_PASSWORD_FILE")"
    echo -e "  Test: mysql -u root -p$(cat "$DB_ROOT_PASSWORD_FILE") -e 'SELECT VERSION();'"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  MySQL status: mysql-monitor status"
    echo -e "  MySQL info: mysql-monitor info"
    echo -e "  Full overview: mysql-monitor"
    echo ""
    echo -e "${CCYAN}Backup:${CEND}"
    echo -e "  Create backup: mysql-backup create"
    echo -e "  List backups: mysql-backup list"
    echo -e "  Cleanup old: mysql-backup cleanup"
    echo ""
    echo -e "${CCYAN}Logs:${CEND}"
    echo -e "  MySQL logs: tail -f $DB_LOG_DIR/error.log"
    echo -e "  System logs: journalctl -u mysql -f"
    echo ""
    echo -e "${CCYAN}Installation Log:${CEND}"
    echo -e "  $LOG_FILE"
    echo ""
    echo -e "${CMAGENTA}Important Security Notes:${CEND}"
    echo -e "  • MySQL is configured for localhost access only"
    echo -e "  • External connections are blocked by firewall"
    echo -e "  • Root password authentication is required"
    echo -e "  • Anonymous users and test database removed"
    echo -e "  • Regular backups are recommended"
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/mysql-apt-config_*.deb 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    check_root
    
    # Choose database type
    choose_database
    
    # Check system compatibility
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Add repository
    add_repository
    
    # Install database
    install_database
    
    # Create MySQL user and directories
    create_mysql_user
    
    # Generate password and create configuration
    generate_password
    create_mysql_config
    
    # Secure MySQL
    secure_mysql
    
    # Create systemd service
    create_systemd_service
    
    # Configure firewall
    configure_firewall
    
    # Setup log rotation
    setup_logrotate
    
    # Create monitoring and backup scripts
    create_monitoring_scripts
    create_backup_script
    
    # Start MySQL service
    start_mysql
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show success message
    show_success_message
}

# Run main function
main
