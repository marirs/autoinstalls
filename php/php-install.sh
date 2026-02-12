#!/bin/bash

# PHP Installation & Configuration Script
# Supports multiple PHP versions with FPM, TCP/Socket configuration, and webserver integration

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

# Available PHP versions
PHP_VERSIONS=("8.3" "8.2" "8.1" "8.0" "7.4")
DEFAULT_PHP_VERSION="8.2"

# Configuration paths
PHP_FPM_CONF_DIR="/etc/php"
NGINX_CONF_DIR="/etc/nginx"
APACHE_CONF_DIR="/etc/apache2"
LOG_FILE="/tmp/php-install.log"

# Global variables
SELECTED_PHP_VERSION=""
FPM_TYPE=""
CONFIGURE_WEBSERVER=""
WEBSERVER_TYPE=""

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    PHP Installation & Configuration${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        OS_VERSION="$VERSION_ID"
        echo -e "${CCYAN}Detected OS: $OS $OS_VERSION${CEND}"
    else
        echo -e "${CRED}Cannot detect OS version${CEND}"
        exit 1
    fi
}

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CRED}This script requires root privileges${CEND}"
        echo -e "${CYAN}Please run with sudo: sudo $0${CEND}"
        exit 1
    fi
}

function install_dependencies() {
    echo -e "${CCYAN}Installing dependencies for $OS $OS_VERSION...${CEND}"
    
    case "$OS" in
        "ubuntu"|"debian")
            apt update >> "$LOG_FILE" 2>&1
            
            # Base packages
            local base_packages=(
                "curl"
                "wget"
                "ca-certificates"
                "apt-transport-https"
                "lsb-release"
                "gnupg"
            )
            
            # Try different software-properties packages
            local sw_props_packages=("software-properties-common" "python3-software-properties" "software-properties")
            for pkg in "${sw_props_packages[@]}"; do
                if apt-cache show "$pkg" >/dev/null 2>&1; then
                    base_packages+=("$pkg")
                    break
                fi
            done
            
            # Install packages
            for package in "${base_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                apt install -y "$package" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${CGREEN}✓ $package installed${CEND}"
                else
                    echo -e "${CRED}✗ $package failed to install${CEND}"
                fi
            done
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            if command -v dnf >/dev/null 2>&1; then
                dnf update -y >> "$LOG_FILE" 2>&1
                dnf install -y curl wget ca-certificates gnupg >> "$LOG_FILE" 2>&1
            else
                yum update -y >> "$LOG_FILE" 2>&1
                yum install -y curl wget ca-certificates gnupg >> "$LOG_FILE" 2>&1
            fi
            ;;
        "fedora")
            dnf update -y >> "$LOG_FILE" 2>&1
            dnf install -y curl wget ca-certificates gnupg >> "$LOG_FILE" 2>&1
            ;;
    esac
    
    echo -e "${CGREEN}✓ Dependencies installed${CEND}"
}

function select_php_version() {
    echo -e "${CCYAN}Available PHP versions:${CEND}"
    echo ""
    
    for i in "${!PHP_VERSIONS[@]}"; do
        local version="${PHP_VERSIONS[i]}"
        if [ "$version" = "$DEFAULT_PHP_VERSION" ]; then
            echo "  $((i+1)). $version (default)"
        else
            echo "  $((i+1)). $version"
        fi
    done
    
    echo ""
    while true; do
        read -p "Select PHP version (1-${#PHP_VERSIONS[@]}) [${#PHP_VERSIONS[@]} for default]: " choice
        
        if [ -z "$choice" ]; then
            choice=${#PHP_VERSIONS[@]}
        fi
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#PHP_VERSIONS[@]} ]; then
            SELECTED_PHP_VERSION="${PHP_VERSIONS[$((choice-1))]}"
            echo -e "${CGREEN}Selected PHP version: $SELECTED_PHP_VERSION${CEND}"
            break
        else
            echo -e "${CRED}Invalid choice. Please enter a number between 1 and ${#PHP_VERSIONS[@]}${CEND}"
        fi
    done
}

function add_php_repository() {
    echo -e "${CCYAN}Adding PHP repository for $OS $OS_VERSION...${CEND}"
    
    case "$OS" in
        "ubuntu")
            add_ubuntu_php_repository
            ;;
        "debian")
            add_debian_php_repository
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            add_rhel_php_repository
            ;;
        "fedora")
            add_fedora_php_repository
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for PHP repository: $OS${CEND}"
            return 1
            ;;
    esac
}

function add_ubuntu_php_repository() {
    echo -e "${CCYAN}Configuring Ubuntu PHP repository...${CEND}"
    
    # Check Ubuntu version compatibility
    case "$OS_VERSION" in
        "18.04"|"20.04"|"22.04"|"24.04")
            echo -e "${CGREEN}✓ Ubuntu $OS_VERSION is supported${CEND}"
            ;;
        *)
            echo -e "${CYAN}⚠ Ubuntu $OS_VERSION may not be fully supported${CEND}"
            ;;
    esac
    
    # Check if add-apt-repository is available
    if ! command -v add-apt-repository >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing software-properties-common...${CEND}"
        apt update >> "$LOG_FILE" 2>&1
        
        # Try different package names for software-properties
        local sw_props_packages=("software-properties-common" "python3-software-properties" "software-properties")
        for pkg in "${sw_props_packages[@]}"; do
            if apt-cache show "$pkg" >/dev/null 2>&1; then
                apt install -y "$pkg" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${CGREEN}✓ $pkg installed${CEND}"
                    break
                fi
            fi
        done
        
        # Check again
        if ! command -v add-apt-repository >/dev/null 2>&1; then
            echo -e "${CRED}✗ Cannot install add-apt-repository${CEND}"
            return 1
        fi
    fi
    
    # Check if PPA is already added
    if apt-cache policy | grep -q "ondrej/php"; then
        echo -e "${CYAN}⚠ Ondrej's PHP PPA already exists${CEND}"
    else
        echo -e "${CCYAN}Adding Ondrej's PHP PPA...${CEND}"
        add-apt-repository -y ppa:ondrej/php >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ Ondrej's PHP PPA added${CEND}"
        else
            echo -e "${CRED}✗ Failed to add Ondrej's PHP PPA${CEND}"
            return 1
        fi
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}"
    apt update >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}"
        return 1
    fi
    
    # Verify PHP packages are available
    echo -e "${CCYAN}Verifying PHP package availability...${CEND}"
    for version in "${PHP_VERSIONS[@]}"; do
        if apt-cache show "php$version-fpm" >/dev/null 2>&1; then
            echo -e "${CGREEN}✓ PHP $version packages available${CEND}"
        else
            echo -e "${CYAN}⚠ PHP $version packages not available${CEND}"
        fi
    done
}

function add_debian_php_repository() {
    echo -e "${CCYAN}Configuring Debian PHP repository...${CEND}"
    
    # Check Debian version compatibility
    case "$OS_VERSION" in
        "9"|"10"|"11"|"12"|"13")
            echo -e "${CGREEN}✓ Debian $OS_VERSION is supported${CEND}"
            ;;
        *)
            echo -e "${CYAN}⚠ Debian $OS_VERSION may not be fully supported${CEND}"
            ;;
    esac
    
    # Get Debian codename
    local debian_codename=""
    case "$OS_VERSION" in
        "9") debian_codename="stretch" ;;
        "10") debian_codename="buster" ;;
        "11") debian_codename="bullseye" ;;
        "12") debian_codename="bookworm" ;;
        "13") debian_codename="trixie" ;;
        *) debian_codename="bookworm" ;;
    esac
    
    # For Debian 13, use bookworm repository as trixie may not be supported yet
    if [[ "$OS_VERSION" == "13" ]]; then
        debian_codename="bookworm"
        echo -e "${CYAN}Using Debian 12 (bookworm) repository for Debian 13 (trixie) compatibility${CEND}"
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}"
    apt update >> "$LOG_FILE" 2>&1
    local required_packages=("curl" "gnupg" "lsb-release" "ca-certificates" "apt-transport-https")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}"
            apt install -y "$pkg" >> "$LOG_FILE" 2>&1
        fi
    done
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/ondrej-php.list" ] || apt-cache policy | grep -q "packages.sury.org"; then
        echo -e "${CYAN}⚠ Ondrej's PHP repository already exists${CEND}"
    else
        echo -e "${CCYAN}Adding Ondrej's PHP repository...${CEND}"
        
        # Import GPG key
        curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ GPG key imported${CEND}"
        else
            echo -e "${CRED}✗ Failed to import GPG key${CEND}"
            return 1
        fi
        
        # Add repository
        echo "deb [signed-by=/etc/apt/trusted.gpg.d/php.gpg] https://packages.sury.org/php/ $debian_codename main" | tee /etc/apt/sources.list.d/ondrej-php.list >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ Ondrej's PHP repository added${CEND}"
        else
            echo -e "${CRED}✗ Failed to add Ondrej's PHP repository${CEND}"
            return 1
        fi
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}"
    apt update >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}"
        return 1
    fi
}

function add_rhel_php_repository() {
    echo -e "${CCYAN}Configuring RHEL-based PHP repository...${CEND}"
    
    # Check OS version compatibility
    case "$OS_VERSION" in
        "7")
            echo -e "${CGREEN}✓ RHEL/CentOS 7 is supported${CEND}"
            configure_rhel7_php_repo
            ;;
        "8"|"9")
            echo -e "${CGREEN}✓ RHEL/CentOS/Rocky/AlmaLinux $OS_VERSION is supported${CEND}"
            configure_rhel8_php_repo
            ;;
        *)
            echo -e "${CRED}✗ RHEL/CentOS version $OS_VERSION not supported${CEND}"
            return 1
            ;;
    esac
}

function configure_rhel7_php_repo() {
    echo -e "${CCYAN}Configuring PHP repository for RHEL/CentOS 7...${CEND}"
    
    # Install EPEL if not already installed
    if ! rpm -q epel-release >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing EPEL repository...${CEND}"
        yum install -y epel-release >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ EPEL repository installed${CEND}"
        else
            echo -e "${CRED}✗ Failed to install EPEL repository${CEND}"
            return 1
        fi
    else
        echo -e "${CYAN}⚠ EPEL repository already installed${CEND}"
    fi
    
    # Install Remi repository if not already installed
    if ! rpm -q remi-release >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing Remi repository...${CEND}"
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ Remi repository installed${CEND}"
        else
            echo -e "${CRED}✗ Failed to install Remi repository${CEND}"
            return 1
        fi
    else
        echo -e "${CYAN}⚠ Remi repository already installed${CEND}"
    fi
    
    # Verify repository is working
    echo -e "${CCYAN}Verifying repository configuration...${CEND}"
    if yum repolist enabled | grep -q "remi"; then
        echo -e "${CGREEN}✓ Remi repository is active${CEND}"
    else
        echo -e "${CRED}✗ Remi repository not found in repolist${CEND}"
        return 1
    fi
}

function configure_rhel8_php_repo() {
    echo -e "${CCYAN}Configuring PHP repository for RHEL/CentOS/Rocky/AlmaLinux $OS_VERSION...${CEND}"
    
    # Determine package manager
    local pkg_manager="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        pkg_manager="yum"
    fi
    
    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}"
    
    # Install EPEL if not already installed
    if ! rpm -q epel-release >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing EPEL repository...${CEND}"
        $pkg_manager install -y epel-release >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ EPEL repository installed${CEND}"
        else
            echo -e "${CRED}✗ Failed to install EPEL repository${CEND}"
            return 1
        fi
    else
        echo -e "${CYAN}⚠ EPEL repository already installed${CEND}"
    fi
    
    # Install Remi repository if not already installed
    if ! rpm -q remi-release >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing Remi repository...${CEND}"
        $pkg_manager install -y https://rpms.remirepo.net/enterprise/remi-release-$OS_VERSION.rpm >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ Remi repository installed${CEND}"
        else
            echo -e "${CRED}✗ Failed to install Remi repository${CEND}"
            return 1
        fi
    else
        echo -e "${CYAN}⚠ Remi repository already installed${CEND}"
    fi
    
    # Reset PHP module and enable default
    echo -e "${CCYAN}Configuring PHP module...${CEND}"
    $pkg_manager module reset php >> "$LOG_FILE" 2>&1
    
    # Verify repository is working
    echo -e "${CCYAN}Verifying repository configuration...${CEND}"
    if $pkg_manager repolist enabled | grep -q "remi"; then
        echo -e "${CGREEN}✓ Remi repository is active${CEND}"
    else
        echo -e "${CRED}✗ Remi repository not found in repolist${CEND}"
        return 1
    fi
    
    # Check available PHP streams
    echo -e "${CCYAN}Available PHP streams:${CEND}"
    $pkg_manager module list php | grep -E "php\s+\[d\]" | head -5
}

function add_fedora_php_repository() {
    echo -e "${CCYAN}Configuring Fedora PHP repository...${CEND}"
    
    # Check Fedora version
    local fedora_major=$(echo "$OS_VERSION" | cut -d. -f1)
    echo -e "${CGREEN}✓ Fedora $OS_VERSION detected${CEND}"
    
    # Fedora usually has PHP in the main repositories
    echo -e "${CCYAN}Fedora includes PHP in main repositories${CEND}"
    
    # Check if we need additional repositories
    local pkg_manager="dnf"
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}"
    $pkg_manager makecache >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package cache updated${CEND}"
    else
        echo -e "${CRED}✗ Failed to update package cache${CEND}"
        return 1
    fi
    
    # Check available PHP versions
    echo -e "${CCYAN}Checking available PHP versions...${CEND}"
    for version in "${PHP_VERSIONS[@]}"; do
        if $pkg_manager info "php" >/dev/null 2>&1; then
            echo -e "${CGREEN}✓ PHP packages available in Fedora repositories${CEND}"
            break
        fi
    done
    
    # Check for Remi repository as optional enhancement
    echo -e "${CCYAN}Checking for optional Remi repository...${CEND}"
    if $pkg_manager repolist | grep -q "remi"; then
        echo -e "${CGREEN}✓ Remi repository is available${CEND}"
    else
        echo -e "${CYAN}⚠ Remi repository not available (using default Fedora PHP)${CEND}"
    fi
}

function install_php() {
    echo -e "${CCYAN}Installing PHP $SELECTED_PHP_VERSION...${CEND}"
    
    case "$OS" in
        "ubuntu"|"debian")
            # Install PHP core and common extensions
            local php_packages=(
                "php$SELECTED_PHP_VERSION"
                "php$SELECTED_PHP_VERSION-fpm"
                "php$SELECTED_PHP_VERSION-cli"
                "php$SELECTED_PHP_VERSION-common"
                "php$SELECTED_PHP_VERSION-curl"
                "php$SELECTED_PHP_VERSION-mbstring"
                "php$SELECTED_PHP_VERSION-xml"
                "php$SELECTED_PHP_VERSION-mysql"
                "php$SELECTED_PHP_VERSION-pgsql"
                "php$SELECTED_PHP_VERSION-sqlite3"
                "php$SELECTED_PHP_VERSION-zip"
                "php$SELECTED_PHP_VERSION-bcmath"
                "php$SELECTED_PHP_VERSION-gd"
                "php$SELECTED_PHP_VERSION-intl"
                "php$SELECTED_PHP_VERSION-opcache"
                # Database extensions
                "php$SELECTED_PHP_VERSION-redis"
                "php$SELECTED_PHP_VERSION-mongodb"
                # System extensions
                "php$SELECTED_PHP_VERSION-zlib"
                "php$SELECTED_PHP_VERSION-pcre"
                # Additional important extensions
                "php$SELECTED_PHP_VERSION-json"
                "php$SELECTED_PHP_VERSION-tokenizer"
                "php$SELECTED_PHP_VERSION-ctype"
                "php$SELECTED_PHP_VERSION-dom"
                "php$SELECTED_PHP_VERSION-simplexml"
                "php$SELECTED_PHP_VERSION-xmlwriter"
                "php$SELECTED_PHP_VERSION-xmlreader"
                "php$SELECTED_PHP_VERSION-hash"
                "php$SELECTED_PHP_VERSION-filter"
                "php$SELECTED_PHP_VERSION-iconv"
                # Security and encryption
                "php$SELECTED_PHP_VERSION-sodium"
                "php$SELECTED_PHP_VERSION-gmp"
                # Image and media
                "php$SELECTED_PHP_VERSION-exif"
                "php$SELECTED_PHP_VERSION-imagick"
                # Calendar and date
                "php$SELECTED_PHP_VERSION-calendar"
                # File handling
                "php$SELECTED_PHP_VERSION-fileinfo"
                # Network extensions
                "php$SELECTED_PHP_VERSION-soap"
                "php$SELECTED_PHP_VERSION-xmlrpc"
                # Process control
                "php$SELECTED_PHP_VERSION-pcntl"
                "php$SELECTED_PHP_VERSION-posix"
                "php$SELECTED_PHP_VERSION-shmop"
                "php$SELECTED_PHP_VERSION-sysvmsg"
                "php$SELECTED_PHP_VERSION-sysvsem"
                "php$SELECTED_PHP_VERSION-sysvshm"
            )
            
            for package in "${php_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                if apt-cache show "$package" >/dev/null 2>&1; then
                    apt install -y "$package" >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                    else
                        echo -e "${CYAN}⚠ $package failed to install${CEND}"
                    fi
                else
                    echo -e "${CYAN}⚠ $package not available, skipping${CEND}"
                fi
            done
            
            # Try alternative extension package names
            echo -e "${CCYAN}Installing alternative extension packages...${CEND}"
            
            # MongoDB alternatives
            if ! dpkg -l | grep -q "php$SELECTED_PHP_VERSION-mongodb"; then
                local mongo_packages=("php-mongodb" "php$SELECTED_PHP_VERSION-mongo")
                for mongo_pkg in "${mongo_packages[@]}"; do
                    if apt-cache show "$mongo_pkg" >/dev/null 2>&1; then
                        echo -e "${CCYAN}Installing $mongo_pkg...${CEND}"
                        apt install -y "$mongo_pkg" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $mongo_pkg installed (MongoDB extension)${CEND}"
                            break
                        fi
                    fi
                done
            fi
            
            # Redis alternatives
            if ! dpkg -l | grep -q "php$SELECTED_PHP_VERSION-redis"; then
                local redis_packages=("php-redis")
                for redis_pkg in "${redis_packages[@]}"; do
                    if apt-cache show "$redis_pkg" >/dev/null 2>&1; then
                        echo -e "${CCYAN}Installing $redis_pkg...${CEND}"
                        apt install -y "$redis_pkg" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $redis_pkg installed (Redis extension)${CEND}"
                            break
                        fi
                    fi
                done
            fi
            
            # ImageMagick alternatives
            if ! dpkg -l | grep -q "php$SELECTED_PHP_VERSION-imagick"; then
                local imagick_packages=("php-imagick")
                for imagick_pkg in "${imagick_packages[@]}"; do
                    if apt-cache show "$imagick_pkg" >/dev/null 2>&1; then
                        echo -e "${CCYAN}Installing $imagick_pkg...${CEND}"
                        apt install -y "$imagick_pkg" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $imagick_pkg installed (ImageMagick extension)${CEND}"
                            break
                        fi
                    fi
                done
            fi
            
            # Sodium alternatives
            if ! dpkg -l | grep -q "php$SELECTED_PHP_VERSION-sodium"; then
                local sodium_packages=("php-sodium")
                for sodium_pkg in "${sodium_packages[@]}"; do
                    if apt-cache show "$sodium_pkg" >/dev/null 2>&1; then
                        echo -e "${CCYAN}Installing $sodium_pkg...${CEND}"
                        apt install -y "$sodium_pkg" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $sodium_pkg installed (Sodium extension)${CEND}"
                            break
                        fi
                    fi
                done
            fi
            
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # Enable Remi PHP module
            case "$OS_VERSION" in
                "7")
                    echo -e "${CCYAN}Enabling PHP $SELECTED_PHP_VERSION module on RHEL/CentOS 7...${CEND}"
                    # For CentOS 7, we need to enable the specific Remi repo
                    yum-config-manager --enable remi-php$SELECTED_PHP_VERSION >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ PHP $SELECTED_PHP_VERSION repository enabled${CEND}"
                    else
                        echo -e "${CRED}✗ Failed to enable PHP $SELECTED_PHP_VERSION repository${CEND}"
                        echo -e "${CYAN}Trying to install packages from default repositories...${CEND}"
                    fi
                    
                    local php_packages=(
                        "php"
                        "php-fpm"
                        "php-cli"
                        "php-common"
                        "php-curl"
                        "php-mbstring"
                        "php-xml"
                        "php-mysqlnd"
                        "php-pgsql"
                        "php-sqlite"
                        "php-zip"
                        "php-bcmath"
                        "php-gd"
                        "php-intl"
                        "php-opcache"
                        # Database extensions
                        "php-redis"
                        "php-mongodb"
                        # System extensions
                        "php-zlib"
                        "php-pcre"
                        # Additional important extensions
                        "php-json"
                        "php-tokenizer"
                        "php-ctype"
                        "php-dom"
                        "php-simplexml"
                        "php-xmlwriter"
                        "php-xmlreader"
                        "php-hash"
                        "php-filter"
                        "php-iconv"
                        # Security and encryption
                        "php-sodium"
                        "php-gmp"
                        # Image and media
                        "php-exif"
                        # Calendar and date
                        "php-calendar"
                        # File handling
                        "php-fileinfo"
                        # Network extensions
                        "php-soap"
                        "php-xmlrpc"
                        # Process control
                        "php-pcntl"
                        "php-posix"
                        "php-shmop"
                        "php-sysvmsg"
                        "php-sysvsem"
                        "php-sysvshm"
                    )
                    for package in "${php_packages[@]}"; do
                        echo -e "${CCYAN}Installing $package...${CEND}"
                        yum install -y "$package" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $package installed${CEND}"
                        else
                            echo -e "${CYAN}⚠ $package not available, skipping${CEND}"
                        fi
                    done
                    ;;
                "8"|"9")
                    echo -e "${CCYAN}Enabling PHP $SELECTED_PHP_VERSION module on RHEL/CentOS/Rocky/AlmaLinux $OS_VERSION...${CEND}"
                    
                    # Determine package manager
                    local pkg_manager="dnf"
                    if ! command -v dnf >/dev/null 2>&1; then
                        pkg_manager="yum"
                    fi
                    
                    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}"
                    
                    # Reset PHP module first
                    $pkg_manager module reset php >> "$LOG_FILE" 2>&1
                    
                    # Enable the specific PHP version module
                    $pkg_manager module enable php:remi-$SELECTED_PHP_VERSION >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ PHP $SELECTED_PHP_VERSION module enabled${CEND}"
                    else
                        echo -e "${CRED}✗ Failed to enable PHP $SELECTED_PHP_VERSION module${CEND}"
                        echo -e "${CYAN}Available PHP modules:${CEND}"
                        $pkg_manager module list php | grep -E "php\s+\[d\]"
                        return 1
                    fi
                    
                    local php_packages=(
                        "php"
                        "php-fpm"
                        "php-cli"
                        "php-common"
                        "php-curl"
                        "php-mbstring"
                        "php-xml"
                        "php-mysqlnd"
                        "php-pgsql"
                        "php-sqlite"
                        "php-zip"
                        "php-bcmath"
                        "php-gd"
                        "php-intl"
                        "php-opcache"
                        # Database extensions
                        "php-redis"
                        "php-mongodb"
                        # System extensions
                        "php-zlib"
                        "php-pcre"
                        # Additional important extensions
                        "php-json"
                        "php-tokenizer"
                        "php-ctype"
                        "php-dom"
                        "php-simplexml"
                        "php-xmlwriter"
                        "php-xmlreader"
                        "php-hash"
                        "php-filter"
                        "php-iconv"
                        # Security and encryption
                        "php-sodium"
                        "php-gmp"
                        # Image and media
                        "php-exif"
                        # Calendar and date
                        "php-calendar"
                        # File handling
                        "php-fileinfo"
                        # Network extensions
                        "php-soap"
                        "php-xmlrpc"
                        # Process control
                        "php-pcntl"
                        "php-posix"
                        "php-shmop"
                        "php-sysvmsg"
                        "php-sysvsem"
                        "php-sysvshm"
                    )
                    for package in "${php_packages[@]}"; do
                        echo -e "${CCYAN}Installing $package...${CEND}"
                        $pkg_manager install -y "$package" >> "$LOG_FILE" 2>&1
                        if [ $? -eq 0 ]; then
                            echo -e "${CGREEN}✓ $package installed${CEND}"
                        else
                            echo -e "${CYAN}⚠ $package not available, skipping${CEND}"
                        fi
                    done
                    ;;
            esac
            
            # Try PECL installation for missing extensions
            echo -e "${CCYAN}Installing missing extensions via PECL...${CEND}"
            
            # MongoDB
            if ! php -m | grep -q mongodb; then
                if command -v pecl >/dev/null 2>&1; then
                    echo -e "${CCYAN}Installing MongoDB via PECL...${CEND}"
                    pecl install mongodb >> "$LOG_FILE" 2>&1
                    echo "extension=mongodb.so" >> "/etc/php/$SELECTED_PHP_VERSION/mods-available/mongodb.ini"
                    phpenmod mongodb >> "$LOG_FILE" 2>&1
                    if php -m | grep -q mongodb; then
                        echo -e "${CGREEN}✓ MongoDB extension installed via PECL${CEND}"
                    fi
                fi
            fi
            
            # Redis
            if ! php -m | grep -q redis; then
                if command -v pecl >/dev/null 2>&1; then
                    echo -e "${CCYAN}Installing Redis via PECL...${CEND}"
                    pecl install redis >> "$LOG_FILE" 2>&1
                    echo "extension=redis.so" >> "/etc/php/$SELECTED_PHP_VERSION/mods-available/redis.ini"
                    phpenmod redis >> "$LOG_FILE" 2>&1
                    if php -m | grep -q redis; then
                        echo -e "${CGREEN}✓ Redis extension installed via PECL${CEND}"
                    fi
                fi
            fi
            
            # ImageMagick
            if ! php -m | grep -q imagick; then
                if command -v pecl >/dev/null 2>&1; then
                    echo -e "${CCYAN}Installing ImageMagick via PECL...${CEND}"
                    pecl install imagick >> "$LOG_FILE" 2>&1
                    echo "extension=imagick.so" >> "/etc/php/$SELECTED_PHP_VERSION/mods-available/imagick.ini"
                    phpenmod imagick >> "$LOG_FILE" 2>&1
                    if php -m | grep -q imagick; then
                        echo -e "${CGREEN}✓ ImageMagick extension installed via PECL${CEND}"
                    fi
                fi
            fi
            
            # Sodium
            if ! php -m | grep -q sodium; then
                if command -v pecl >/dev/null 2>&1; then
                    echo -e "${CCYAN}Installing Sodium via PECL...${CEND}"
                    pecl install sodium >> "$LOG_FILE" 2>&1
                    echo "extension=sodium.so" >> "/etc/php/$SELECTED_PHP_VERSION/mods-available/sodium.ini"
                    phpenmod sodium >> "$LOG_FILE" 2>&1
                    if php -m | grep -q sodium; then
                        echo -e "${CGREEN}✓ Sodium extension installed via PECL${CEND}"
                    fi
                fi
            fi
            
            ;;
        "fedora")
            local php_packages=(
                "php"
                "php-fpm"
                "php-cli"
                "php-common"
                "php-curl"
                "php-mbstring"
                "php-xml"
                "php-mysqlnd"
                "php-pgsql"
                "php-sqlite"
                "php-zip"
                "php-bcmath"
                "php-gd"
                "php-intl"
                "php-opcache"
                # Database extensions
                "php-redis"
                "php-mongodb"
                # System extensions
                "php-zlib"
                "php-pcre"
                # Additional important extensions
                "php-json"
                "php-tokenizer"
                "php-ctype"
                "php-dom"
                "php-simplexml"
                "php-xmlwriter"
                "php-xmlreader"
                "php-hash"
                "php-filter"
                "php-iconv"
                # Security and encryption
                "php-sodium"
                "php-gmp"
                # Image and media
                "php-exif"
                # Calendar and date
                "php-calendar"
                # File handling
                "php-fileinfo"
                # Network extensions
                "php-soap"
                "php-xmlrpc"
                # Process control
                "php-pcntl"
                "php-posix"
                "php-shmop"
                "php-sysvmsg"
                "php-sysvsem"
                "php-sysvshm"
            )
            for package in "${php_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then
                    echo -e "${CGREEN}✓ $package installed${CEND}"
                else
                    echo -e "${CYAN}⚠ $package not available, skipping${CEND}"
                fi
            done
            
            # Try PECL installation for missing extensions
            if ! php -m | grep -q mongodb; then
                if command -v pecl >/dev/null 2>&1; then
                    echo -e "${CCYAN}Installing MongoDB via PECL...${CEND}"
                    pecl install mongodb >> "$LOG_FILE" 2>&1
                    echo "extension=mongodb.so" >> "/etc/php.d/mongodb.ini"
                    if php -m | grep -q mongodb; then
                        echo -e "${CGREEN}✓ MongoDB extension installed via PECL${CEND}"
                    fi
                fi
            fi
            ;;
    esac
    
    echo -e "${CGREEN}✓ PHP $SELECTED_PHP_VERSION installed${CEND}"
}

function select_fpm_type() {
    echo ""
    echo -e "${CCYAN}PHP-FPM Configuration Type:${CEND}"
    echo "  1. Unix Socket (recommended for same server)"
    echo "  2. TCP Port (recommended for remote connections)"
    echo ""
    
    while true; do
        read -p "Select FPM type (1-2) [1]: " choice
        
        if [ -z "$choice" ]; then
            choice=1
        fi
        
        case $choice in
            1)
                FPM_TYPE="socket"
                echo -e "${CGREEN}Selected: Unix Socket${CEND}"
                break
                ;;
            2)
                FPM_TYPE="tcp"
                echo -e "${CGREEN}Selected: TCP Port${CEND}"
                break
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please enter 1 or 2${CEND}"
                ;;
        esac
    done
}

function configure_php_fpm() {
    echo -e "${CCYAN}Configuring PHP-FPM...${CEND}"
    
    local php_fpm_conf="/etc/php/$SELECTED_PHP_VERSION/fpm/php-fpm.conf"
    local www_conf="/etc/php/$SELECTED_PHP_VERSION/fpm/pool.d/www.conf"
    
    # Configure main php-fpm.conf
    if [ -f "$php_fpm_conf" ]; then
        # Backup original
        cp "$php_fpm_conf" "$php_fpm_conf.backup"
        
        # Basic configuration
        sed -i "s/^;pid =.*/pid = \/run\/php-fpm-$SELECTED_PHP_VERSION.pid/" "$php_fpm_conf"
        sed -i "s/^;error_log =.*/error_log = \/var\/log\/php$SELECTED_PHP_VERSION-fpm.log/" "$php_fpm_conf"
    fi
    
    # Configure www pool
    if [ -f "$www_conf" ]; then
        # Backup original
        cp "$www_conf" "$www_conf.backup"
        
        if [ "$FPM_TYPE" = "socket" ]; then
            # Unix socket configuration
            sed -i "s/^listen =.*/listen = \/run\/php\/php$SELECTED_PHP_VERSION-fpm.sock/" "$www_conf"
            sed -i "s/^;listen.owner =.*/listen.owner = www-data/" "$www_conf"
            sed -i "s/^;listen.group =.*/listen.group = www-data/" "$www_conf"
            sed -i "s/^;listen.mode =.*/listen.mode = 0660/" "$www_conf"
        else
            # TCP configuration
            sed -i "s/^listen =.*/listen = 127.0.0.1:9000/" "$www_conf"
            sed -i "s/^;listen.owner =.*/;listen.owner = www-data/" "$www_conf"
            sed -i "s/^;listen.group =.*/;listen.group = www-data/" "$www_conf"
            sed -i "s/^;listen.mode =.*/;listen.mode = 0660/" "$www_conf"
        fi
        
        # Performance tuning
        sed -i "s/^pm = dynamic/pm = dynamic/" "$www_conf"
        sed -i "s/^pm.max_children =.*/pm.max_children = 50/" "$www_conf"
        sed -i "s/^pm.start_servers =.*/pm.start_servers = 5/" "$www_conf"
        sed -i "s/^pm.min_spare_servers =.*/pm.min_spare_servers = 5/" "$www_conf"
        sed -i "s/^pm.max_spare_servers =.*/pm.max_spare_servers = 35/" "$www_conf"
        sed -i "s/^;pm.max_requests =.*/pm.max_requests = 500/" "$www_conf"
        
        # Security settings
        sed -i "s/^;security.limit_extensions =.*/security.limit_extensions = .php .php3 .php4 .php5 .php7/" "$www_conf"
    fi
    
    # Configure PHP.ini
    local php_ini="/etc/php/$SELECTED_PHP_VERSION/fpm/php.ini"
    if [ -f "$php_ini" ]; then
        cp "$php_ini" "$php_ini.backup"
        
        # Performance optimizations
        sed -i "s/^memory_limit =.*/memory_limit = 256M/" "$php_ini"
        sed -i "s/^max_execution_time =.*/max_execution_time = 300/" "$php_ini"
        sed -i "s/^max_input_time =.*/max_input_time = 300/" "$php_ini"
        sed -i "s/^post_max_size =.*/post_max_size = 64M/" "$php_ini"
        sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 64M/" "$php_ini"
        
        # Error reporting
        sed -i "s/^display_errors =.*/display_errors = Off/" "$php_ini"
        sed -i "s/^display_startup_errors =.*/display_startup_errors = Off/" "$php_ini"
        sed -i "s/^error_reporting =.*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/" "$php_ini"
        
        # OPcache settings
        sed -i "s/^;opcache.enable=1/opcache.enable=1/" "$php_ini"
        sed -i "s/^;opcache.memory_consumption=128/opcache.memory_consumption=256/" "$php_ini"
        sed -i "s/^;opcache.max_accelerated_files=4000/opcache.max_accelerated_files=10000/" "$php_ini"
        sed -i "s/^;opcache.revalidate_freq=2/opcache.revalidate_freq=60/" "$php_ini"
    fi
    
    # Create socket directory if using socket
    if [ "$FPM_TYPE" = "socket" ]; then
        mkdir -p /run/php
        chown www-data:www-data /run/php
    fi
    
    echo -e "${CGREEN}✓ PHP-FPM configured${CEND}"
}

function detect_webservers() {
    echo -e "${CCYAN}Detecting installed webservers...${CEND}"
    
    local detected_servers=()
    
    if command -v nginx >/dev/null 2>&1 && [ -d "$NGINX_CONF_DIR" ]; then
        detected_servers+=("nginx")
        echo -e "${CGREEN}✓ Nginx detected${CEND}"
    fi
    
    if command -v apache2 >/dev/null 2>&1 && [ -d "$APACHE_CONF_DIR" ]; then
        detected_servers+=("apache2")
        echo -e "${CGREEN}✓ Apache2 detected${CEND}"
    fi
    
    if command -v httpd >/dev/null 2>&1 && [ -d "/etc/httpd" ]; then
        detected_servers+=("httpd")
        echo -e "${CGREEN}✓ Apache (httpd) detected${CEND}"
    fi
    
    if [ ${#detected_servers[@]} -eq 0 ]; then
        echo -e "${CYAN}No webservers detected${CEND}"
        return 1
    fi
    
    return 0
}

function configure_webserver_integration() {
    echo ""
    echo -e "${CCYAN}Webserver Configuration:${CEND}"
    
    if ! detect_webservers; then
        echo -e "${CYAN}No webservers found. Skipping webserver configuration.${CEND}"
        return 0
    fi
    
    echo ""
    read -p "Configure PHP with detected webservers? (y/n): " configure_choice
    
    if [[ ! "$configure_choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Skipping webserver configuration${CEND}"
        return 0
    fi
    
    # Configure Nginx
    if command -v nginx >/dev/null 2>&1 && [ -d "$NGINX_CONF_DIR" ]; then
        configure_nginx_php
    fi
    
    # Configure Apache
    if (command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1); then
        configure_apache_php
    fi
}

function configure_nginx_php() {
    echo -e "${CCYAN}Configuring Nginx for PHP...${CEND}"
    
    # Create PHP upstream configuration
    local upstream_conf="$NGINX_CONF_DIR/conf.d/php-upstream.conf"
    
    cat > "$upstream_conf" << EOF
# PHP $SELECTED_PHP_VERSION Upstream Configuration
upstream php$SELECTED_PHP_VERSION {
EOF
    
    if [ "$FPM_TYPE" = "socket" ]; then
        cat >> "$upstream_conf" << EOF
    server unix:/run/php/php$SELECTED_PHP_VERSION-fpm.sock;
EOF
    else
        cat >> "$upstream_conf" << EOF
    server 127.0.0.1:9000;
EOF
    fi
    
    cat >> "$upstream_conf" << EOF
}
EOF
    
    # Create PHP location snippet
    local php_snippet="$NGINX_CONF_DIR/snippets/php$SELECTED_PHP_VERSION.conf"
    mkdir -p "$NGINX_CONF_DIR/snippets"
    
    cat > "$php_snippet" << EOF
# PHP $SELECTED_PHP_VERSION Configuration Snippet
location ~ \\.php\$ {
    include snippets/fastcgi-php.conf;
    
EOF
    
    if [ "$FPM_TYPE" = "socket" ]; then
        cat >> "$php_snippet" << EOF
    fastcgi_pass unix:/run/php/php$SELECTED_PHP_VERSION-fpm.sock;
EOF
    else
        cat >> "$php_snippet" << EOF
    fastcgi_pass php$SELECTED_PHP_VERSION;
EOF
    fi
    
    cat >> "$php_snippet" << EOF
    
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    include fastcgi_params;
    
    # Security headers
    fastcgi_param HTTPS \$https if_not_empty;
}
EOF
    
    # Create example virtual host
    local example_vhost="$NGINX_CONF_DIR/sites-available/php-test"
    mkdir -p "$NGINX_CONF_DIR/sites-available"
    mkdir -p "$NGINX_CONF_DIR/sites-enabled"
    
    cat > "$example_vhost" << EOF
# PHP Test Virtual Host
server {
    listen 80;
    server_name php-test.local;
    
    root /var/www/php-test;
    index index.php index.html;
    
    access_log /var/log/nginx/php-test_access.log;
    error_log /var/log/nginx/php-test_error.log;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP processing
    include snippets/php$SELECTED_PHP_VERSION.conf;
    
    # PHP status page
    location /php-status {
        include snippets/php$SELECTED_PHP_VERSION.conf;
        fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
        allow 127.0.0.1;
        deny all;
    }
    
    # PHP info page
    location /php-info {
        include snippets/php$SELECTED_PHP_VERSION.conf;
        fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
        allow 127.0.0.1;
        deny all;
    }
}
EOF
    
    # Create test directory and files
    mkdir -p /var/www/php-test
    chown www-data:www-data /var/www/php-test
    
    cat > /var/www/php-test/index.php << 'EOF'
<?php
echo "<h1>PHP Test Page</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";
echo "<p>Server Time: " . date('Y-m-d H:i:s') . "</p>";

// Test Redis extension
if (extension_loaded('redis')) {
    echo "<p style='color: green;'>✓ Redis Extension: Loaded</p>";
    try {
        $redis = new Redis();
        // Try to connect if Redis server is available
        if ($redis->connect('127.0.0.1', 6379, 1)) {
            echo "<p style='color: green;'>✓ Redis Server: Connected</p>";
            $redis->close();
        } else {
            echo "<p style='color: orange;'>⚠ Redis Server: Not available</p>";
        }
    } catch (Exception $e) {
        echo "<p style='color: orange;'>⚠ Redis Server: Connection failed</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Redis Extension: Not loaded</p>";
}

// Test MongoDB extension
if (extension_loaded('mongodb')) {
    echo "<p style='color: green;'>✓ MongoDB Extension: Loaded</p>";
    try {
        // Test MongoDB manager
        $manager = new MongoDB\Driver\Manager("mongodb://localhost:27017");
        echo "<p style='color: green;'>✓ MongoDB Manager: Created</p>";
    } catch (Exception $e) {
        echo "<p style='color: orange;'>⚠ MongoDB Server: Not available</p>";
    }
} else {
    echo "<p style='color: red;'>✗ MongoDB Extension: Not loaded</p>";
}

// Test Zlib extension
if (extension_loaded('zlib')) {
    echo "<p style='color: green;'>✓ Zlib Extension: Loaded</p>";
    $test_string = "This is a test string for compression";
    $compressed = gzcompress($test_string);
    $decompressed = gzuncompress($compressed);
    if ($decompressed === $test_string) {
        echo "<p style='color: green;'>✓ Zlib Compression: Working</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Zlib Extension: Not loaded</p>";
}

// Test PCRE extension
if (extension_loaded('pcre')) {
    echo "<p style='color: green;'>✓ PCRE Extension: Loaded</p>";
    $pattern = '/^test.*$/';
    $subject = 'test string';
    if (preg_match($pattern, $subject)) {
        echo "<p style='color: green;'>✓ PCRE Functions: Working</p>";
    }
} else {
    echo "<p style='color: red;'>✗ PCRE Extension: Not loaded</p>";
}

echo "<h2>Additional Tests:</h2>";
echo "<p><a href='/php-info'>View PHP Info</a></p>";
echo "<p><a href='/php-status'>View PHP-FPM Status</a></p>";
echo "<p><a href='/test-extensions'>Test Extensions</a></p>";
?>
EOF
    
    # Create extensions test page
    cat > /var/www/php-test/test-extensions.php << 'EOF'
<?php
echo "<h1>PHP Extensions Test</h1>";
echo "<h2>Extension Details:</h2>";

$extensions_to_test = [
    'redis' => 'Redis - In-memory data structure store',
    'mongodb' => 'MongoDB - NoSQL database driver',
    'zlib' => 'Zlib - Data compression',
    'pcre' => 'PCRE - Regular expressions',
    'curl' => 'cURL - HTTP client library',
    'gd' => 'GD - Image processing',
    'mbstring' => 'MBString - Multi-byte string handling',
    'opcache' => 'OPcache - PHP bytecode cache'
];

foreach ($extensions_to_test as $ext => $description) {
    echo "<h3>$ext</h3>";
    echo "<p><strong>Description:</strong> $description</p>";
    
    if (extension_loaded($ext)) {
        echo "<p style='color: green;'><strong>Status:</strong> ✓ Loaded</p>";
        
        // Show extension version if available
        $ext_version = phpversion($ext);
        if ($ext_version) {
            echo "<p><strong>Version:</strong> $ext_version</p>";
        }
        
        // Show specific functions for key extensions
        switch ($ext) {
            case 'redis':
                if (class_exists('Redis')) {
                    echo "<p><strong>Available:</strong> Redis class</p>";
                    $redis_methods = ['connect', 'get', 'set', 'exists', 'del'];
                    echo "<p><strong>Key Methods:</strong> " . implode(', ', $redis_methods) . "</p>";
                }
                break;
                
            case 'mongodb':
                if (class_exists('MongoDB\Driver\Manager')) {
                    echo "<p><strong>Available:</strong> MongoDB\Driver\Manager class</p>";
                }
                if (class_exists('MongoDB\Client')) {
                    echo "<p><strong>Available:</strong> MongoDB\Client class</p>";
                }
                break;
                
            case 'zlib':
                $zlib_funcs = ['gzcompress', 'gzuncompress', 'gzencode', 'gzdecode', 'gzfile'];
                echo "<p><strong>Functions:</strong> " . implode(', ', array_filter($zlib_funcs, 'function_exists')) . "</p>";
                break;
                
            case 'pcre':
                echo "<p><strong>Functions:</strong> preg_match, preg_replace, preg_split, etc.</p>";
                break;
        }
    } else {
        echo "<p style='color: red;'><strong>Status:</strong> ✗ Not Loaded</p>";
    }
    echo "<hr>";
}

echo "<p><a href='/'>← Back to main test page</a></p>";
?>
EOF
    
    # Enable the site
    if [ -d "$NGINX_CONF_DIR/sites-enabled" ]; then
        ln -sf "$NGINX_CONF_DIR/sites-available/php-test" "$NGINX_CONF_DIR/sites-enabled/"
    fi
    
    echo -e "${CGREEN}✓ Nginx configured for PHP $SELECTED_PHP_VERSION${CEND}"
    echo -e "${CYAN}Test site: http://php-test.local${CEND}"
    echo -e "${CYAN}PHP info: http://php-test.local/php-info${CEND}"
    echo -e "${CYAN}PHP-FPM status: http://php-test.local/php-status${CEND}"
}

function configure_apache_php() {
    echo -e "${CCYAN}Configuring Apache for PHP...${CEND}"
    
    # Determine Apache configuration directory
    local apache_conf_dir=""
    if [ -d "/etc/apache2" ]; then
        apache_conf_dir="/etc/apache2"
    elif [ -d "/etc/httpd" ]; then
        apache_conf_dir="/etc/httpd"
    else
        echo -e "${CRED}Apache configuration directory not found${CEND}"
        return 1
    fi
    
    # Enable PHP module
    if command -v a2enmod >/dev/null 2>&1; then
        # Ubuntu/Debian
        a2enmod php$SELECTED_PHP_VERSION >> "$LOG_FILE" 2>&1
        a2enmod proxy_fcgi >> "$LOG_FILE" 2>&1
        a2enmod setenvif >> "$LOG_FILE" 2>&1
        
        # Create PHP-FPM configuration
        cat > "$apache_conf_dir/conf-available/php$SELECTED_PHP_VERSION-fpm.conf" << EOF
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php$SELECTED_PHP_VERSION-fpm.sock|fcgi://localhost/"
</FilesMatch>

<Proxy fcgi://localhost/>
    ProxySet connectiontimeout=5 timeout=240
</Proxy>
EOF
        
        a2enconf php$SELECTED_PHP_VERSION-fpm >> "$LOG_FILE" 2>&1
        
    else
        # RHEL/CentOS/Fedora
        cat > "$apache_conf_dir/conf.d/php.conf" << EOF
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php$SELECTED_PHP_VERSION-fpm.sock|fcgi://localhost/"
</FilesMatch>

<Proxy fcgi://localhost/>
    ProxySet connectiontimeout=5 timeout=240
</Proxy>

# Add index.php to DirectoryIndex
DirectoryIndex index.php index.html
EOF
    fi
    
    # Create test virtual host
    local test_conf="$apache_conf_dir/sites-available/php-test.conf"
    if [ ! -d "$apache_conf_dir/sites-available" ]; then
        mkdir -p "$apache_conf_dir/sites-available"
    fi
    
    cat > "$test_conf" << EOF
<VirtualHost *:80>
    ServerName php-test.local
    DocumentRoot /var/www/php-test
    
    <Directory /var/www/php-test>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/php-test_error.log
    CustomLog \${APACHE_LOG_DIR}/php-test_access.log combined
</VirtualHost>
EOF
    
    # Enable the site
    if command -v a2ensite >/dev/null 2>&1; then
        a2ensite php-test >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${CGREEN}✓ Apache configured for PHP $SELECTED_PHP_VERSION${CEND}"
    echo -e "${CYAN}Test site: http://php-test.local${CEND}"
}

function start_services() {
    echo -e "${CCYAN}Starting PHP-FPM service...${CEND}"
    
    # Start PHP-FPM
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable "php$SELECTED_PHP_VERSION-fpm" >> "$LOG_FILE" 2>&1
        systemctl start "php$SELECTED_PHP_VERSION-fpm" >> "$LOG_FILE" 2>&1
        
        if systemctl is-active --quiet "php$SELECTED_PHP_VERSION-fpm"; then
            echo -e "${CGREEN}✓ PHP-FPM service started${CEND}"
        else
            echo -e "${CRED}✗ Failed to start PHP-FPM service${CEND}"
            return 1
        fi
    else
        echo -e "${CRED}systemd not available, please start PHP-FPM manually${CEND}"
        return 1
    fi
    
    # Restart webservers if configured
    if [ "$CONFIGURE_WEBSERVER" = "true" ]; then
        if command -v nginx >/dev/null 2>&1; then
            echo -e "${CCYAN}Restarting Nginx...${CEND}"
            systemctl restart nginx >> "$LOG_FILE" 2>&1
            echo -e "${CGREEN}✓ Nginx restarted${CEND}"
        fi
        
        if command -v apache2 >/dev/null 2>&1; then
            echo -e "${CCYAN}Restarting Apache2...${CEND}"
            systemctl restart apache2 >> "$LOG_FILE" 2>&1
            echo -e "${CGREEN}✓ Apache2 restarted${CEND}"
        elif command -v httpd >/dev/null 2>&1; then
            echo -e "${CCYAN}Restarting Apache (httpd)...${CEND}"
            systemctl restart httpd >> "$LOG_FILE" 2>&1
            echo -e "${CGREEN}✓ Apache (httpd) restarted${CEND}"
        fi
    fi
}

function test_php_installation() {
    echo -e "${CCYAN}Testing PHP installation...${CEND}"
    
    # Test PHP CLI
    if php$SELECTED_PHP_VERSION -v >> "$LOG_FILE" 2>&1; then
        echo -e "${CGREEN}✓ PHP CLI working${CEND}"
        php$SELECTED_PHP_VERSION -v
    else
        echo -e "${CRED}✗ PHP CLI not working${CEND}"
    fi
    
    # Test PHP-FPM
    if [ "$FPM_TYPE" = "socket" ] && [ -S "/run/php/php$SELECTED_PHP_VERSION-fpm.sock" ]; then
        echo -e "${CGREEN}✓ PHP-FPM socket working${CEND}"
    elif [ "$FPM_TYPE" = "tcp" ] && netstat -ln | grep -q ":9000"; then
        echo -e "${CGREEN}✓ PHP-FPM TCP port working${CEND}"
    else
        echo -e "${CRED}✗ PHP-FPM not working${CEND}"
    fi
    
    # Test additional extensions
    echo ""
    echo -e "${CCYAN}Testing additional extensions...${CEND}"
    
    # Database extensions
    echo -e "${CYYAN}Database Extensions:${CEND}"
    
    if php$SELECTED_PHP_VERSION -m | grep -q redis; then
        echo -e "${CGREEN}✓ Redis extension installed${CEND}"
        if command -v redis-cli >/dev/null 2>&1 && redis-cli ping >/dev/null 2>&1; then
            echo -e "${CGREEN}✓ Redis server connectivity confirmed${CEND}"
        else
            echo -e "${CYAN}⚠ Redis extension installed but Redis server not available${CEND}"
        fi
    else
        echo -e "${CYAN}⚠ Redis extension not available${CEND}"
    fi
    
    if php$SELECTED_PHP_VERSION -m | grep -q mongodb; then
        echo -e "${CGREEN}✓ MongoDB extension installed${CEND}"
        if command -v mongosh >/dev/null 2>&1 || command -v mongo >/dev/null 2>&1; then
            echo -e "${CGREEN}✓ MongoDB server tools available${CEND}"
        else
            echo -e "${CYAN}⚠ MongoDB extension installed but MongoDB server tools not available${CEND}"
        fi
    else
        echo -e "${CYAN}⚠ MongoDB extension not available${CEND}"
    fi
    
    # System extensions
    echo ""
    echo -e "${CYAN}System Extensions:${CEND}"
    
    if php$SELECTED_PHP_VERSION -m | grep -q zlib; then
        echo -e "${CGREEN}✓ Zlib extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ Zlib extension not available${CEND}"
    fi
    
    if php$SELECTED_PHP_VERSION -m | grep -q pcre; then
        echo -e "${CGREEN}✓ PCRE extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ PCRE extension not available${CEND}"
    fi
    
    # Core extensions
    echo ""
    echo -e "${CYAN}Core Extensions:${CEND}"
    
    local core_extensions=("json" "tokenizer" "ctype" "dom" "simplexml" "xmlwriter" "xmlreader" "hash" "filter" "iconv")
    for ext in "${core_extensions[@]}"; do
        if php$SELECTED_PHP_VERSION -m | grep -q "$ext"; then
            echo -e "${CGREEN}✓ $ext extension installed${CEND}"
        else
            echo -e "${CYAN}⚠ $ext extension not available${CEND}"
        fi
    done
    
    # Security extensions
    echo ""
    echo -e "${CYAN}Security Extensions:${CEND}"
    
    if php$SELECTED_PHP_VERSION -m | grep -q sodium; then
        echo -e "${CGREEN}✓ Sodium extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ Sodium extension not available${CEND}"
    fi
    
    if php$SELECTED_PHP_VERSION -m | grep -q gmp; then
        echo -e "${CGREEN}✓ GMP extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ GMP extension not available${CEND}"
    fi
    
    # Image extensions
    echo ""
    echo -e "${CYAN}Image Extensions:${CEND}"
    
    if php$SELECTED_PHP_VERSION -m | grep -q gd; then
        echo -e "${CGREEN}✓ GD extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ GD extension not available${CEND}"
    fi
    
    if php$SELECTED_PHP_VERSION -m | grep -q exif; then
        echo -e "${CGREEN}✓ EXIF extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ EXIF extension not available${CEND}"
    fi
    
    if php$SELECTED_PHP_VERSION -m | grep -q imagick; then
        echo -e "${CGREEN}✓ ImageMagick extension installed${CEND}"
    else
        echo -e "${CYAN}⚠ ImageMagick extension not available${CEND}"
    fi
    
    # Utility extensions
    echo ""
    echo -e "${CYAN}Utility Extensions:${CEND}"
    
    local utility_extensions=("calendar" "fileinfo" "soap" "xmlrpc")
    for ext in "${utility_extensions[@]}"; do
        if php$SELECTED_PHP_VERSION -m | grep -q "$ext"; then
            echo -e "${CGREEN}✓ $ext extension installed${CEND}"
        else
            echo -e "${CYAN}⚠ $ext extension not available${CEND}"
        fi
    done
    
    # Process control extensions
    echo ""
    echo -e "${CYAN}Process Control Extensions:${CEND}"
    
    local process_extensions=("pcntl" "posix" "shmop" "sysvmsg" "sysvsem" "sysvshm")
    for ext in "${process_extensions[@]}"; do
        if php$SELECTED_PHP_VERSION -m | grep -q "$ext"; then
            echo -e "${CGREEN}✓ $ext extension installed${CEND}"
        else
            echo -e "${CYAN}⚠ $ext extension not available${CEND}"
        fi
    done
    
    # Show all loaded modules
    echo ""
    echo -e "${CCYAN}All loaded PHP modules (${#php_modules[@]} total):${CEND}"
    php$SELECTED_PHP_VERSION -m | sort | tr '\n' ' '
    echo ""
    
    # Show PHP info
    echo ""
    echo -e "${CCYAN}PHP Configuration:${CEND}"
    echo -e "${CYAN}Version: $(php$SELECTED_PHP_VERSION -v | head -n1)${CEND}"
    echo -e "${CYAN}FPM Type: $FPM_TYPE${CEND}"
    echo -e "${CYAN}Configuration: /etc/php/$SELECTED_PHP_VERSION/fpm/${CEND}"
    echo -e "${CYAN}Log file: /var/log/php$SELECTED_PHP_VERSION-fpm.log${CEND}"
}

function show_completion_info() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CGREEN}    PHP Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}PHP Version: $SELECTED_PHP_VERSION${CEND}"
    echo -e "${CCYAN}FPM Type: $FPM_TYPE${CEND}"
    echo ""
    echo -e "${CYAN}Configuration Files:${CEND}"
    echo -e "  PHP-FPM: /etc/php/$SELECTED_PHP_VERSION/fpm/php-fpm.conf"
    echo -e "  Pool: /etc/php/$SELECTED_PHP_VERSION/fpm/pool.d/www.conf"
    echo -e "  PHP.ini: /etc/php/$SELECTED_PHP_VERSION/fpm/php.ini"
    echo ""
    echo -e "${CYAN}Service Management:${CEND}"
    echo -e "  Start: systemctl start php$SELECTED_PHP_VERSION-fpm"
    echo -e "  Stop: systemctl stop php$SELECTED_PHP_VERSION-fpm"
    echo -e "  Restart: systemctl restart php$SELECTED_PHP_VERSION-fpm"
    echo -e "  Status: systemctl status php$SELECTED_PHP_VERSION-fpm"
    echo ""
    
    if [ "$CONFIGURE_WEBSERVER" = "true" ]; then
        echo -e "${CYAN}Webserver Integration:${CEND}"
        echo -e "  Test Site: http://php-test.local"
        echo -e "  PHP Info: http://php-test.local/php-info"
        echo -e "  PHP-FPM Status: http://php-test.local/php-status"
        echo ""
        echo -e "${CYAN}Don't forget to add 'php-test.local' to your /etc/hosts file!${CEND}"
        echo -e "  echo '127.0.0.1 php-test.local' >> /etc/hosts"
        echo ""
    fi
    
    echo -e "${CYAN}Log Files:${CEND}"
    echo -e "  PHP-FPM: /var/log/php$SELECTED_PHP_VERSION-fpm.log"
    echo -e "  Installation: $LOG_FILE"
    echo ""
}

function main() {
    show_header
    check_root
    detect_os
    install_dependencies
    select_php_version
    add_php_repository
    install_php
    select_fpm_type
    configure_php_fpm
    configure_webserver_integration
    start_services
    test_php_installation
    show_completion_info
}

# Create log file
touch "$LOG_FILE"

# Run main function
main "$@"
