# MongoDB Installation Script
# Automated MongoDB installation and configuration

#!/bin/bash

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"
CCYAN="${CSI}1;36m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# System information detection
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)
architecture=$(arch)

# Function to install dependencies based on OS version
function install_dependencies() {
    echo -e "${CCYAN}Installing dependencies for $os $os_ver...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Update package lists
            apt-get update >> /tmp/mongodb-install.log 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "curl"
                "wget"
                "ca-certificates"
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
                    apt-get install -y "$package" >> /tmp/mongodb-install.log 2>&1
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
                                        apt-get install -y "$alt_pkg" >> /tmp/mongodb-install.log 2>&1
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
                echo -e "${CRED}✗ curl is missing - critical for MongoDB installation${CEND}"
                critical_ok=false
            fi
            
            if ! command -v gpg >/dev/null 2>&1 && ! command -v gpg2 >/dev/null 2>&1; then
                echo -e "${CRED}✗ gpg/gpg2 is missing - critical for repository verification${CEND}"
                critical_ok=false
            fi
            
            if [ "$critical_ok" = true ]; then
                echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
                echo -e "${CCYAN}MongoDB installation will continue...${CEND}"
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
                        yum update -y >> /tmp/mongodb-install.log 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> /tmp/mongodb-install.log 2>&1
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
                        dnf update -y >> /tmp/mongodb-install.log 2>&1
                        for package in "${rhel_base_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> /tmp/mongodb-install.log 2>&1
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
            
            dnf update -y >> /tmp/mongodb-install.log 2>&1
            for package in "${fedora_base_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> /tmp/mongodb-install.log 2>&1
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

# Function to add MongoDB repository with intelligent management
function add_mongodb_repository_enhanced() {
    echo -e "${CCYAN}Adding MongoDB repository for $os $os_ver...${CEND}" >> /tmp/mongodb-install.log
    
    case "$os" in
        "ubuntu")
            add_ubuntu_mongodb_repo_enhanced
            ;;
        "debian")
            add_debian_mongodb_repo_enhanced
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            add_rhel_mongodb_repo_enhanced
            ;;
        "fedora")
            add_fedora_mongodb_repo_enhanced
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for MongoDB: $os${CEND}" >> /tmp/mongodb-install.log
            return 1
            ;;
    esac
}

function add_ubuntu_mongodb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MongoDB repository for Ubuntu...${CEND}" >> /tmp/mongodb-install.log
    
    # Check Ubuntu version compatibility
    case "$os_ver" in
        "18.04"|"20.04"|"22.04"|"24.04")
            echo -e "${CGREEN}✓ Ubuntu $os_ver is supported${CEND}" >> /tmp/mongodb-install.log
            ;;
        *)
            echo -e "${CYAN}⚠ Ubuntu $os_ver may not be fully supported${CEND}" >> /tmp/mongodb-install.log
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/mongodb-org-${MONGO_VER}.list" ] || apt-cache policy | grep -q "repo.mongodb.org"; then
        echo -e "${CYAN}⚠ MongoDB repository already exists${CEND}" >> /tmp/mongodb-install.log
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> /tmp/mongodb-install.log
    apt-get update >> /tmp/mongodb-install.log 2>&1
    
    local required_packages=("curl" "gnupg")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> /tmp/mongodb-install.log
            apt-get install -y "$pkg" >> /tmp/mongodb-install.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> /tmp/mongodb-install.log
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> /tmp/mongodb-install.log
                return 1
            fi
        fi
    done
    
    # Get Ubuntu codename dynamically
    local ubuntu_codename=""
    if command -v lsb_release >/dev/null 2>&1; then
        ubuntu_codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
    else
        # Fallback to version-based codename
        case "$os_ver" in
            "18.04") ubuntu_codename="bionic" ;;
            "20.04") ubuntu_codename="focal" ;;
            "22.04") ubuntu_codename="jammy" ;;
            "24.04") ubuntu_codename="noble" ;;
            *) ubuntu_codename="jammy" ;;
        esac
    fi
    
    echo -e "${CCYAN}Using Ubuntu codename: $ubuntu_codename${CEND}" >> /tmp/mongodb-install.log
    
    # Import MongoDB GPG key
    echo -e "${CCYAN}Importing MongoDB GPG key...${CEND}" >> /tmp/mongodb-install.log
    curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc" | gpg -o /usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg >> /tmp/mongodb-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB GPG key imported${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to import MongoDB GPG key${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Add MongoDB repository
    echo -e "${CCYAN}Adding MongoDB repository...${CEND}" >> /tmp/mongodb-install.log
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg ] https://repo.mongodb.org/apt/ubuntu $ubuntu_codename/mongodb-org/${MONGO_VER} multiverse" | tee "/etc/apt/sources.list.d/mongodb-org-${MONGO_VER}.list" >> /tmp/mongodb-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB repository added${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to add MongoDB repository${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> /tmp/mongodb-install.log
    apt-get update >> /tmp/mongodb-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Verify MongoDB packages are available
    echo -e "${CCYAN}Verifying MongoDB package availability...${CEND}" >> /tmp/mongodb-install.log
    if apt-cache show "mongodb-org" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MongoDB packages available${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ MongoDB packages not available${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
}

function add_debian_mongodb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MongoDB repository for Debian...${CEND}" >> /tmp/mongodb-install.log
    
    # Check Debian version compatibility
    case "$os_ver" in
        "9"|"10"|"11"|"12"|"13")
            echo -e "${CGREEN}✓ Debian $os_ver is supported${CEND}" >> /tmp/mongodb-install.log
            ;;
        *)
            echo -e "${CYAN}⚠ Debian $os_ver may not be fully supported${CEND}" >> /tmp/mongodb-install.log
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/mongodb-org-${MONGO_VER}.list" ] || apt-cache policy | grep -q "repo.mongodb.org"; then
        echo -e "${CYAN}⚠ MongoDB repository already exists${CEND}" >> /tmp/mongodb-install.log
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> /tmp/mongodb-install.log
    apt-get update >> /tmp/mongodb-install.log 2>&1
    
    local required_packages=("curl" "gnupg" "lsb-release")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> /tmp/mongodb-install.log
            apt-get install -y "$pkg" >> /tmp/mongodb-install.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> /tmp/mongodb-install.log
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> /tmp/mongodb-install.log
                return 1
            fi
        fi
    done
    
    # Get Debian codename dynamically
    local debian_codename=""
    if command -v lsb_release >/dev/null 2>&1; then
        debian_codename=$(lsb_release -cs 2>/dev/null || echo "bookworm")
    else
        # Fallback to version-based codename
        case "$os_ver" in
            "9") debian_codename="stretch" ;;
            "10") debian_codename="buster" ;;
            "11") debian_codename="bullseye" ;;
            "12") debian_codename="bookworm" ;;
            "13") debian_codename="trixie" ;;
            *) debian_codename="bookworm" ;;
        esac
    fi
    
    echo -e "${CCYAN}Using Debian codename: $debian_codename${CEND}" >> /tmp/mongodb-install.log
    
    # Import MongoDB GPG key
    echo -e "${CCYAN}Importing MongoDB GPG key...${CEND}" >> /tmp/mongodb-install.log
    
    # Use a more reliable method for GPG key import
    curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc" | gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg >> /tmp/mongodb-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB GPG key imported${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to import MongoDB GPG key${CEND}" >> /tmp/mongodb-install.log
        # Try alternative method
        echo -e "${CYAN}Trying alternative GPG key import method...${CEND}" >> /tmp/mongodb-install.log
        curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc" > /tmp/mongodb-key.asc
        gpg --dearmor < /tmp/mongodb-key.asc > /usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg 2>> /tmp/mongodb-install.log
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ MongoDB GPG key imported (alternative method)${CEND}" >> /tmp/mongodb-install.log
            rm -f /tmp/mongodb-key.asc
        else
            echo -e "${CRED}✗ Failed to import MongoDB GPG key (all methods)${CEND}" >> /tmp/mongodb-install.log
            rm -f /tmp/mongodb-key.asc
            return 1
        fi
    fi
    
    # Add MongoDB repository
    echo -e "${CCYAN}Adding MongoDB repository...${CEND}" >> /tmp/mongodb-install.log
    
    # For Debian 13 (trixie), use Debian 12 (bookworm) repository since MongoDB doesn't support trixie yet
    local repo_codename="$debian_codename"
    if [[ "$debian_codename" == "trixie" ]]; then
        repo_codename="bookworm"
        echo -e "${CYAN}Using Debian 12 (bookworm) repository for Debian 13 (trixie) compatibility${CEND}" >> /tmp/mongodb-install.log
    fi
    
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg ] https://repo.mongodb.org/apt/debian $repo_codename/mongodb-org/${MONGO_VER} main" | tee "/etc/apt/sources.list.d/mongodb-org-${MONGO_VER}.list" >> /tmp/mongodb-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB repository added${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to add MongoDB repository${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> /tmp/mongodb-install.log
    apt-get update >> /tmp/mongodb-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Verify MongoDB packages are available
    echo -e "${CCYAN}Verifying MongoDB package availability...${CEND}" >> /tmp/mongodb-install.log
    if apt-cache show "mongodb-org" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MongoDB packages available${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ MongoDB packages not available${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
}

function add_rhel_mongodb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MongoDB repository for RHEL-based systems...${CEND}" >> /tmp/mongodb-install.log
    
    # Check OS version compatibility
    case "$os_ver" in
        "7"|"8"|"9")
            echo -e "${CGREEN}✓ RHEL/CentOS/Rocky/AlmaLinux $os_ver is supported${CEND}" >> /tmp/mongodb-install.log
            ;;
        *)
            echo -e "${CRED}✗ RHEL/CentOS version $os_ver not supported${CEND}" >> /tmp/mongodb-install.log
            return 1
            ;;
    esac
    
    # Determine package manager
    local pkg_manager="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        pkg_manager="yum"
    fi
    
    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}" >> /tmp/mongodb-install.log
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mongodb-org-${MONGO_VER}.repo" ]; then
        echo -e "${CYAN}⚠ MongoDB repository already exists${CEND}" >> /tmp/mongodb-install.log
        return 0
    fi
    
    # Create MongoDB repository file
    echo -e "${CCYAN}Creating MongoDB repository file...${CEND}" >> /tmp/mongodb-install.log
    cat > "/etc/yum.repos.d/mongodb-org-${MONGO_VER}.repo" << EOF
[mongodb-org-${MONGO_VER}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/${MONGO_VER}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB repository file created${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to create MongoDB repository file${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> /tmp/mongodb-install.log
    $pkg_manager clean all >> /tmp/mongodb-install.log 2>&1
    
    # Verify MongoDB packages are available
    echo -e "${CCYAN}Verifying MongoDB package availability...${CEND}" >> /tmp/mongodb-install.log
    if $pkg_manager info mongodb-org >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MongoDB packages available${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ MongoDB packages not available${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
}

function add_fedora_mongodb_repo_enhanced() {
    echo -e "${CCYAN}Configuring MongoDB repository for Fedora...${CEND}" >> /tmp/mongodb-install.log
    
    # Check Fedora version
    local fedora_major=$(echo "$os_ver" | cut -d. -f1)
    echo -e "${CGREEN}✓ Fedora $os_ver detected${CEND}" >> /tmp/mongodb-install.log
    
    # Determine package manager
    local pkg_manager="dnf"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/mongodb-org-${MONGO_VER}.repo" ]; then
        echo -e "${CYAN}⚠ MongoDB repository already exists${CEND}" >> /tmp/mongodb-install.log
        return 0
    fi
    
    # Create MongoDB repository file
    echo -e "${CCYAN}Creating MongoDB repository file...${CEND}" >> /tmp/mongodb-install.log
    cat > "/etc/yum.repos.d/mongodb-org-${MONGO_VER}.repo" << EOF
[mongodb-org-${MONGO_VER}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/fedora/\$releasever/mongodb-org/${MONGO_VER}/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ MongoDB repository file created${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ Failed to create MongoDB repository file${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
    
    # Clean package cache
    echo -e "${CCYAN}Cleaning package cache...${CEND}" >> /tmp/mongodb-install.log
    $pkg_manager clean all >> /tmp/mongodb-install.log 2>&1
    
    # Verify MongoDB packages are available
    echo -e "${CCYAN}Verifying MongoDB package availability...${CEND}" >> /tmp/mongodb-install.log
    if $pkg_manager info mongodb-org >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ MongoDB packages available${CEND}" >> /tmp/mongodb-install.log
    else
        echo -e "${CRED}✗ MongoDB packages not available${CEND}" >> /tmp/mongodb-install.log
        return 1
    fi
}

# Get MongoDB latest version
MONGODB_VERSIONS=$(curl -s https://www.mongodb.org/download-center/community | grep -oP 'mongodb-\d+\.\d+\.\d+' | sort -V | uniq | tail -n2)
MONGODB_LATEST_VER=$(echo $MONGODB_VERSIONS | cut -d' ' -f2 | cut -d'-' -f2)
MONGODB_STABLE_VER=$(echo $MONGODB_VERSIONS | cut -d' ' -f1 | cut -d'-' -f2)

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/mongodb-install.log

clear
echo ""
echo "Welcome to the MongoDB auto-install script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update MongoDB"
echo "   2) Configure MongoDB"
echo "   3) Uninstall MongoDB"
echo "   4) Create MongoDB user"
echo "   5) Backup MongoDB"
echo "   6) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" && $OPTION != "6" ]]; do
	read -p "Select an option [1-6]: " OPTION
done

case $OPTION in
	1)
		echo ""
		echo "This script will install MongoDB with optional configurations."
		echo ""
		echo "Choose MongoDB version:"
		echo "   1) Stable (v${MONGODB_STABLE_VER}) - Recommended for production"
		echo "   2) Latest (v${MONGODB_LATEST_VER}) - Newest features and updates"
		echo ""
		while [[ $MONGO_VER != "1" && $MONGO_VER != "2" ]]; do
			read -p "Select an option [1-2]: " MONGO_VER
		done
		case $MONGO_VER in
			1)
			MONGO_VER=$MONGODB_STABLE_VER
			;;
			2)
			MONGO_VER=$MONGODB_LATEST_VER
			;;
		esac
		
		echo ""
		echo "Choose installation type:"
		echo "   1) Standalone (Single instance)"
		echo "   2) Replica Set (Multiple instances)"
		echo "   3) Sharded Cluster (Advanced)"
		echo ""
		while [[ $INSTALL_TYPE != "1" && $INSTALL_TYPE != "2" && $INSTALL_TYPE != "3" ]]; do
			read -p "Select an option [1-3]: " INSTALL_TYPE
		done
		
		echo ""
		echo "Additional configurations:"
		while [[ $MONGO_AUTH != "y" && $MONGO_AUTH != "n" ]]; do
			read -p "       Enable Authentication [y/n]: " -e MONGO_AUTH
		done
		while [[ $MONGO_UI != "y" && $MONGO_UI != "n" ]]; do
			read -p "       Install MongoDB Compass UI [y/n]: " -e MONGO_UI
		done
		while [[ $MONGO_TOOLS != "y" && $MONGO_TOOLS != "n" ]]; do
			read -p "       Install MongoDB Tools [y/n]: " -e MONGO_TOOLS
		done
		while [[ $MONGO_BACKUP != "y" && $MONGO_BACKUP != "n" ]]; do
			read -p "       Setup backup script [y/n]: " -e MONGO_BACKUP
		done
		
		echo ""
		read -n1 -r -p "MongoDB is ready to be installed, press any key to continue..."
		echo ""
		
		# Dependencies
		install_dependencies
		
		# Import MongoDB public key with intelligent repository management
		echo -ne "       Adding MongoDB repository       [..]\r"
		
		# Enhanced repository management
		if add_mongodb_repository_enhanced; then
			echo -ne "       Adding MongoDB repository       [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Adding MongoDB repository       [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Install MongoDB packages
		echo -ne "       Installing MongoDB packages      [..]\r"
		apt-get install -y mongodb-org >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Installing MongoDB packages      [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Installing MongoDB packages      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Install MongoDB Tools
		if [[ "$MONGO_TOOLS" = 'y' ]]; then
			echo -ne "       Installing MongoDB tools         [..]\r"
			apt-get install -y mongodb-org-tools mongodb-org-database mongodb-org-shell >> /tmp/mongodb-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing MongoDB tools         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing MongoDB tools         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/mongodb-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Install MongoDB Compass
		if [[ "$MONGO_UI" = 'y' ]]; then
			echo -ne "       Installing MongoDB Compass      [..]\r"
			wget -qO - https://downloads.mongodb.com/compass/mongodb-compass_1.40.4_amd64.deb >> /tmp/mongodb-install.log 2>&1
			dpkg -i mongodb-compass_1.40.4_amd64.deb >> /tmp/mongodb-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing MongoDB Compass      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing MongoDB Compass      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/mongodb-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Start and enable MongoDB
		echo -ne "       Starting MongoDB service         [..]\r"
		systemctl start mongod >> /tmp/mongodb-install.log 2>&1
		systemctl enable mongod >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Starting MongoDB service         [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Starting MongoDB service         [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Configure MongoDB
		echo -ne "       Configuring MongoDB              [..]\r"
		mkdir -p /etc/mongodb/conf.d
		wget -O /etc/mongodb/mongod.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/mongodb/conf/mongod.conf >> /tmp/mongodb-install.log 2>&1
		
		# Apply configuration based on installation type
		case $INSTALL_TYPE in
			1)
				# Standalone configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				;;
			2)
				# Replica Set configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				;;
			3)
				# Sharded cluster configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				sed -i 's/#sharding:/sharding:/' /etc/mongodb/mongod.conf
				sed -i 's/#clusterRole:/clusterRole: "shardsvr"/' /etc/mongodb/mongod.conf
				;;
		esac
		
		# Enable authentication if requested
		if [[ "$MONGO_AUTH" = 'y' ]]; then
			sed -i 's/#security:/security:/' /etc/mongodb/mongod.conf
			sed -i 's/#authorization: enabled/authorization: enabled/' /etc/mongodb/mongod.conf
		fi
		
		# Restart MongoDB to apply configuration
		systemctl restart mongod >> /tmp/mongodb-install.log 2>&1
		
		# Setup backup script if requested
		if [[ "$MONGO_BACKUP" = 'y' ]]; then
			echo -ne "       Setting up backup script           [..]\r"
			wget -O /usr/local/bin/mongodb-backup https://raw.githubusercontent.com/marirs/autoinstalls/master/mongodb/scripts/mongodb-backup >> /tmp/mongodb-install.log 2>&1
			chmod +x /usr/local/bin/mongodb-backup >> /tmp/mongodb-install.log 2>&1
			echo -ne "       Setting up backup script           [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		
		echo ""
		echo -e "${CGREEN}MongoDB installation successful!${CEND}"
		echo ""
		echo "MongoDB version: $MONGO_VER"
		echo "Installation type: $INSTALL_TYPE"
		echo "Authentication: $([[ "$MONGO_AUTH" = 'y' ]] && echo "Enabled" || echo "Disabled")"
		echo "MongoDB Compass: $([[ "$MONGO_UI" = 'y' ]] && echo "Installed" || echo "Not installed")"
		echo ""
		echo "MongoDB configuration: /etc/mongodb/mongod.conf"
		echo "Log file: /var/log/mongodb/mongod.log"
		echo "Data directory: /var/lib/mongodb"
		echo ""
		echo "Installation log: /tmp/mongodb-install.log"
		echo ""
		exit
		;;
	2)
		# Configuration option would go here
		echo "Configuration option - not implemented yet"
		;;
	3)
		# Uninstall option would go here
		echo "Uninstall option - not implemented yet"
		;;
	4)
		# User creation option would go here
		echo "User creation option - not implemented yet"
		;;
	5)
		# Backup option would go here
		echo "Backup option - not implemented yet"
		;;
	6)
		exit
		;;
esac
