# PostgreSQL Installation Script
# Automated PostgreSQL installation and configuration

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
            apt-get update >> /tmp/postgresql-install.log 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "curl"
                "wget"
                "gnupg"
                "build-essential"
                "libreadline-dev"
                "zlib1g-dev"
                "libssl-dev"
                "libxml2-dev"
                "libxslt1-dev"
                "libjson-c-dev"
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
                                "libsystemd-dev"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "software-properties-common"
                                "libsystemd-dev"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - handle package changes
                            version_packages+=(
                                "libsystemd-dev"
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
                                "libsystemd-dev"
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
                                "libsystemd-dev"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "software-properties-common"
                                "libsystemd-dev"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions
                            version_packages+=(
                                "software-properties-common"
                                "libsystemd-dev"
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
                    apt-get install -y "$package" >> /tmp/postgresql-install.log 2>&1
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
            if command -v gcc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
                echo -e "${CGREEN}Critical dependencies installed successfully${CEND}"
            else
                echo -e "${CRED}Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            
            # Warn about failed packages but don't exit for non-critical ones
            if [ ${#failed_packages[@]} -gt 0 ]; then
                echo -e "${CCYAN}Warning: Some packages failed to install: ${failed_packages[*]}${CEND}"
                echo -e "${CCYAN}PostgreSQL installation will continue with available packages...${CEND}"
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems
            local rhel_packages=(
                "curl"
                "wget"
                "gnupg2"
                "gcc"
                "gcc-c++"
                "make"
                "readline-devel"
                "zlib-devel"
                "openssl-devel"
                "libxml2-devel"
                "libxslt-devel"
                "json-c-devel"
                "systemd-devel"
            )
            
            # Version-specific adjustments
            case "$os_ver" in
                "7")
                    # CentOS 7 uses yum
                    if command -v yum >/dev/null 2>&1; then
                        yum install -y epel-release >> /tmp/postgresql-install.log 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> /tmp/postgresql-install.log 2>&1
                        done
                    fi
                    ;;
                "8"|"9")
                    # RHEL 8+ uses dnf
                    if command -v dnf >/dev/null 2>&1; then
                        dnf install -y epel-release >> /tmp/postgresql-install.log 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> /tmp/postgresql-install.log 2>&1
                        done
                    fi
                    ;;
            esac
            ;;
        "fedora")
            # Fedora-specific packages
            local fedora_packages=(
                "curl"
                "wget"
                "gnupg2"
                "gcc"
                "gcc-c++"
                "make"
                "readline-devel"
                "zlib-devel"
                "openssl-devel"
                "libxml2-devel"
                "libxslt-devel"
                "json-c-devel"
                "systemd-devel"
            )
            
            for package in "${fedora_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> /tmp/postgresql-install.log 2>&1
            done
            ;;
        *)
            echo -e "${CRED}Unsupported OS: $os${CEND}"
            exit 1
            ;;
    esac
}

# Function to add PostgreSQL repository with intelligent management
function add_postgresql_repository() {
    echo -e "${CCYAN}Adding PostgreSQL repository for $os $os_ver...${CEND}" >> /tmp/postgresql-install.log
    
    case "$os" in
        "ubuntu")
            add_ubuntu_postgresql_repo
            ;;
        "debian")
            add_debian_postgresql_repo
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            add_rhel_postgresql_repo
            ;;
        "fedora")
            add_fedora_postgresql_repo
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for PostgreSQL: $os${CEND}"
            return 1
            ;;
    esac
}

function add_ubuntu_postgresql_repo() {
    echo -e "${CCYAN}Configuring PostgreSQL repository for Ubuntu...${CEND}" >> /tmp/postgresql-install.log
    
    # Check Ubuntu version compatibility
    case "$os_ver" in
        "18.04"|"20.04"|"22.04"|"24.04")
            echo -e "${CGREEN}✓ Ubuntu $os_ver is supported${CEND}" >> /tmp/postgresql-install.log
            ;;
        *)
            echo -e "${CYAN}⚠ Ubuntu $os_ver may not be fully supported${CEND}" >> /tmp/postgresql-install.log
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/pgdg.list" ] || apt-cache policy | grep -q "apt.postgresql.org"; then
        echo -e "${CYAN}⚠ PostgreSQL repository already exists${CEND}" >> /tmp/postgresql-install.log
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> /tmp/postgresql-install.log
    apt-get update >> /tmp/postgresql-install.log 2>&1
    
    local required_packages=("curl" "gnupg" "software-properties-common")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> /tmp/postgresql-install.log
            apt-get install -y "$pkg" >> /tmp/postgresql-install.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> /tmp/postgresql-install.log
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> /tmp/postgresql-install.log
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
    
    echo -e "${CCYAN}Using Ubuntu codename: $ubuntu_codename${CEND}" >> /tmp/postgresql-install.log
    
    # Import PostgreSQL GPG key
    echo -e "${CCYAN}Importing PostgreSQL GPG key...${CEND}" >> /tmp/postgresql-install.log
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/postgresql.gpg >/dev/null >> /tmp/postgresql-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL GPG key imported${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to import PostgreSQL GPG key${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Add PostgreSQL repository
    echo -e "${CCYAN}Adding PostgreSQL repository...${CEND}" >> /tmp/postgresql-install.log
    echo "deb http://apt.postgresql.org/pub/repos/apt $ubuntu_codename-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL repository added${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to add PostgreSQL repository${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> /tmp/postgresql-install.log
    apt-get update >> /tmp/postgresql-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Verify PostgreSQL packages are available
    echo -e "${CCYAN}Verifying PostgreSQL package availability...${CEND}" >> /tmp/postgresql-install.log
    if apt-cache show "postgresql" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ PostgreSQL packages available${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ PostgreSQL packages not available${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
}

function add_debian_postgresql_repo() {
    echo -e "${CCYAN}Configuring PostgreSQL repository for Debian...${CEND}" >> /tmp/postgresql-install.log
    
    # Check Debian version compatibility
    case "$os_ver" in
        "9"|"10"|"11"|"12"|"13")
            echo -e "${CGREEN}✓ Debian $os_ver is supported${CEND}" >> /tmp/postgresql-install.log
            ;;
        *)
            echo -e "${CYAN}⚠ Debian $os_ver may not be fully supported${CEND}" >> /tmp/postgresql-install.log
            ;;
    esac
    
    # Check if repository already exists
    if [ -f "/etc/apt/sources.list.d/pgdg.list" ] || apt-cache policy | grep -q "apt.postgresql.org"; then
        echo -e "${CYAN}⚠ PostgreSQL repository already exists${CEND}" >> /tmp/postgresql-install.log
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> /tmp/postgresql-install.log
    apt-get update >> /tmp/postgresql-install.log 2>&1
    
    local required_packages=("curl" "gnupg" "software-properties-common" "lsb-release")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> /tmp/postgresql-install.log
            apt-get install -y "$pkg" >> /tmp/postgresql-install.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> /tmp/postgresql-install.log
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> /tmp/postgresql-install.log
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
    
    echo -e "${CCYAN}Using Debian codename: $debian_codename${CEND}" >> /tmp/postgresql-install.log
    
    # Import PostgreSQL GPG key
    echo -e "${CCYAN}Importing PostgreSQL GPG key...${CEND}" >> /tmp/postgresql-install.log
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/postgresql.gpg >/dev/null >> /tmp/postgresql-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL GPG key imported${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to import PostgreSQL GPG key${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Add PostgreSQL repository
    echo -e "${CCYAN}Adding PostgreSQL repository...${CEND}" >> /tmp/postgresql-install.log
    echo "deb http://apt.postgresql.org/pub/repos/apt $debian_codename-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL repository added${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to add PostgreSQL repository${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> /tmp/postgresql-install.log
    apt-get update >> /tmp/postgresql-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Verify PostgreSQL packages are available
    echo -e "${CCYAN}Verifying PostgreSQL package availability...${CEND}" >> /tmp/postgresql-install.log
    if apt-cache show "postgresql" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ PostgreSQL packages available${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ PostgreSQL packages not available${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
}

function add_rhel_postgresql_repo() {
    echo -e "${CCYAN}Configuring PostgreSQL repository for RHEL-based systems...${CEND}" >> /tmp/postgresql-install.log
    
    # Check OS version compatibility
    case "$os_ver" in
        "7"|"8"|"9")
            echo -e "${CGREEN}✓ RHEL/CentOS/Rocky/AlmaLinux $os_ver is supported${CEND}" >> /tmp/postgresql-install.log
            ;;
        *)
            echo -e "${CRED}✗ RHEL/CentOS version $os_ver not supported${CEND}" >> /tmp/postgresql-install.log
            return 1
            ;;
    esac
    
    # Determine package manager
    local pkg_manager="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        pkg_manager="yum"
    fi
    
    echo -e "${CCYAN}Using package manager: $pkg_manager${CEND}" >> /tmp/postgresql-install.log
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/pgdg-redhat-all.repo" ]; then
        echo -e "${CYAN}⚠ PostgreSQL repository already exists${CEND}" >> /tmp/postgresql-install.log
        return 0
    fi
    
    # Install PostgreSQL RPM repository
    echo -e "${CCYAN}Installing PostgreSQL RPM repository...${CEND}" >> /tmp/postgresql-install.log
    
    local postgresql_rpm_url=""
    case "$os_ver" in
        "7")
            postgresql_rpm_url="https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
            ;;
        "8")
            postgresql_rpm_url="https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
            ;;
        "9")
            postgresql_rpm_url="https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
            ;;
    esac
    
    $pkg_manager install -y "$postgresql_rpm_url" >> /tmp/postgresql-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL RPM repository installed${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to install PostgreSQL RPM repository${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Update package cache
    echo -e "${CCYAN}Updating package cache...${CEND}" >> /tmp/postgresql-install.log
    $pkg_manager makecache >> /tmp/postgresql-install.log 2>&1
    
    # Verify PostgreSQL packages are available
    echo -e "${CCYAN}Verifying PostgreSQL package availability...${CEND}" >> /tmp/postgresql-install.log
    if $pkg_manager info postgresql-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ PostgreSQL packages available${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ PostgreSQL packages not available${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
}

function add_fedora_postgresql_repo() {
    echo -e "${CCYAN}Configuring PostgreSQL repository for Fedora...${CEND}" >> /tmp/postgresql-install.log
    
    # Check Fedora version
    local fedora_major=$(echo "$os_ver" | cut -d. -f1)
    echo -e "${CGREEN}✓ Fedora $os_ver detected${CEND}" >> /tmp/postgresql-install.log
    
    # Determine package manager
    local pkg_manager="dnf"
    
    # Check if repository already exists
    if [ -f "/etc/yum.repos.d/pgdg-fedora-all.repo" ]; then
        echo -e "${CYAN}⚠ PostgreSQL repository already exists${CEND}" >> /tmp/postgresql-install.log
        return 0
    fi
    
    # Install PostgreSQL RPM repository
    echo -e "${CCYAN}Installing PostgreSQL RPM repository...${CEND}" >> /tmp/postgresql-install.log
    local postgresql_rpm_url="https://download.postgresql.org/pub/repos/yum/reporpms/F-$fedora_major-x86_64/pgdg-fedora-repo-latest.noarch.rpm"
    
    $pkg_manager install -y "$postgresql_rpm_url" >> /tmp/postgresql-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ PostgreSQL RPM repository installed${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ Failed to install PostgreSQL RPM repository${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
    
    # Update package cache
    echo -e "${CCYAN}Updating package cache...${CEND}" >> /tmp/postgresql-install.log
    $pkg_manager makecache >> /tmp/postgresql-install.log 2>&1
    
    # Verify PostgreSQL packages are available
    echo -e "${CCYAN}Verifying PostgreSQL package availability...${CEND}" >> /tmp/postgresql-install.log
    if $pkg_manager info postgresql-server >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ PostgreSQL packages available${CEND}" >> /tmp/postgresql-install.log
    else
        echo -e "${CRED}✗ PostgreSQL packages not available${CEND}" >> /tmp/postgresql-install.log
        return 1
    fi
}

# Get PostgreSQL latest version
POSTGRESQL_VERSIONS=$(curl -s https://www.postgresql.org/source/ | grep -oP 'postgresql-\d+\.\d+\.\d+' | sort -V | uniq | tail -n2)
POSTGRESQL_LATEST_VER=$(echo $POSTGRESQL_VERSIONS | cut -d' ' -f2 | cut -d'-' -f2)
POSTGRESQL_STABLE_VER=$(echo $POSTGRESQL_VERSIONS | cut -d' ' -f1 | cut -d'-' -f2)

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/postgresql-install.log

clear
echo ""
echo "Welcome to the PostgreSQL auto-install script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update PostgreSQL"
echo "   2) Configure PostgreSQL"
echo "   3) Uninstall PostgreSQL"
echo "   4) Create PostgreSQL user"
echo "   5) Create PostgreSQL database"
echo "   6) Backup PostgreSQL"
echo "   7) Restore PostgreSQL"
echo "   8) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" && $OPTION != "6" && $OPTION != "7" && $OPTION != "8" ]]; do
	read -p "Select an option [1-8]: " OPTION
done

case $OPTION in
	1)
		echo ""
		echo "This script will install PostgreSQL with optional configurations."
		echo ""
		echo "Choose PostgreSQL version:"
		echo "   1) Stable $POSTGRESQL_STABLE_VER"
		echo "   2) Latest $POSTGRESQL_LATEST_VER"
		echo "   3) Repository version (Recommended)"
		echo ""
		while [[ $POSTGRES_VER != "1" && $POSTGRES_VER != "2" && $POSTGRES_VER != "3" ]]; do
			read -p "Select an option [1-3]: " POSTGRES_VER
		done
		case $POSTGRES_VER in
			1)
			POSTGRES_VER=$POSTGRESQL_STABLE_VER
			INSTALL_TYPE="source"
			;;
			2)
			POSTGRES_VER=$POSTGRESQL_LATEST_VER
			INSTALL_TYPE="source"
			;;
			3)
			POSTGRES_VER="repository"
			INSTALL_TYPE="repository"
			;;
		esac
		
		echo ""
		echo "Choose installation type:"
		echo "   1) Standalone (Single instance)"
		echo "   2) Primary-Replica (Streaming replication)"
		echo "   3) Cluster (Multiple nodes)"
		echo ""
		while [[ $CLUSTER_TYPE != "1" && $CLUSTER_TYPE != "2" && $CLUSTER_TYPE != "3" ]]; do
			read -p "Select an option [1-3]: " CLUSTER_TYPE
		done
		
		echo ""
		echo "Additional configurations:"
		while [[ $POSTGRES_AUTH != "y" && $POSTGRES_AUTH != "n" ]]; do
			read -p "       Enable Authentication (Required) [y/n]: " -e POSTGRES_AUTH
		done
		while [[ $POSTGRES_EXT != "y" && $POSTGRES_EXT != "n" ]]; do
			read -p "       Install useful extensions [y/n]: " -e POSTGRES_EXT
		done
		while [[ $POSTGRES_PGA != "y" && $POSTGRES_PGA != "n" ]]; do
			read -p "       Install pgAdmin4 (Web UI) [y/n]: " -e POSTGRES_PGA
		done
		while [[ $POSTGRES_TOOLS != "y" && $POSTGRES_TOOLS != "n" ]]; do
			read -p "       Install PostgreSQL tools [y/n]: " -e POSTGRES_TOOLS
		done
		while [[ $POSTGRES_BACKUP != "y" && $POSTGRES_BACKUP != "n" ]]; do
			read -p "       Setup backup script [y/n]: " -e POSTGRES_BACKUP
		done
		while [[ $POSTGRES_PERF != "y" && $POSTGRES_PERF != "n" ]]; do
			read -p "       Enable performance tuning [y/n]: " -e POSTGRES_PERF
		done
		
		echo ""
		read -n1 -r -p "PostgreSQL is ready to be installed, press any key to continue..."
		echo ""
		
		# Dependencies
		install_dependencies
		
		if [[ "$INSTALL_TYPE" = "repository" ]]; then
			# Install from PostgreSQL repository with intelligent management
			echo -ne "       Adding PostgreSQL repository      [..]\r"
			
			# Enhanced repository management
			if add_postgresql_repository; then
				echo -ne "       Adding PostgreSQL repository      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Adding PostgreSQL repository      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
		 fi
			
			# Install PostgreSQL packages
			echo -ne "       Installing PostgreSQL packages   [..]\r"
			apt-get install -y postgresql postgresql-contrib >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing PostgreSQL packages   [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing PostgreSQL packages   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
		else
			# Install from source
			echo -ne "       Downloading PostgreSQL source     [..]\r"
			cd /usr/local/src
			wget https://ftp.postgresql.org/pub/source/v$POSTGRES_VER/postgresql-$POSTGRES_VER.tar.gz >> /tmp/postgresql-install.log 2>&1
			tar xzf postgresql-$POSTGRES_VER.tar.gz >> /tmp/postgresql-install.log 2>&1
			cd postgresql-$POSTGRES_VER
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading PostgreSQL source     [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading PostgreSQL source     [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
			
			# Configure PostgreSQL
			echo -ne "       Configuring PostgreSQL            [..]\r"
			./configure --prefix=/usr/local/pgsql --with-libxml --with-libxslt --with-openssl --with-systemd --with-jsonc --with-pgport=5432 >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Configuring PostgreSQL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring PostgreSQL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
			
			# Compile PostgreSQL
			echo -ne "       Compiling PostgreSQL              [..]\r"
			make -j$cores >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Compiling PostgreSQL              [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Compiling PostgreSQL              [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
			
			# Install PostgreSQL
			echo -ne "       Installing PostgreSQL             [..]\r"
			make install >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing PostgreSQL             [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing PostgreSQL             [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
			
			# Create postgres user
			useradd -r -m -d /var/lib/pgsql postgres >> /tmp/postgresql-install.log 2>&1
			chown -R postgres:postgres /usr/local/pgsql >> /tmp/postgresql-install.log 2>&1
		fi
		
		# Install PostgreSQL tools
		if [[ "$POSTGRES_TOOLS" = 'y' ]]; then
			echo -ne "       Installing PostgreSQL tools        [..]\r"
			apt-get install -y postgresql-client pgadmin4 pgtop pgbouncer >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing PostgreSQL tools        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing PostgreSQL tools        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Install pgAdmin4
		if [[ "$POSTGRES_PGA" = 'y' ]]; then
			echo -ne "       Installing pgAdmin4              [..]\r"
			apt-get install -y pgadmin4-web >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing pgAdmin4              [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing pgAdmin4              [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Start and enable PostgreSQL
		echo -ne "       Starting PostgreSQL service        [..]\r"
		systemctl start postgresql >> /tmp/postgresql-install.log 2>&1
		systemctl enable postgresql >> /tmp/postgresql-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Starting PostgreSQL service        [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Starting PostgreSQL service        [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/postgresql-install.log"
			echo ""
			exit 1
		fi
		
		# Configure PostgreSQL
		echo -ne "       Configuring PostgreSQL             [..]\r"
		mkdir -p /etc/postgresql/conf.d
		wget -O /etc/postgresql/postgresql.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/postgresql/conf/postgresql.conf >> /tmp/postgresql-install.log 2>&1
		wget -O /etc/postgresql/pg_hba.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/postgresql/conf/pg_hba.conf >> /tmp/postgresql-install.log 2>&1
		
		# Apply configuration based on cluster type
		case $CLUSTER_TYPE in
			1)
				# Standalone configuration
				sed -i 's/#wal_level = replica/wal_level = replica/' /etc/postgresql/postgresql.conf
				sed -i 's/#max_wal_senders = 0/max_wal_senders = 3/' /etc/postgresql/postgresql.conf
				;;
			2)
				# Primary-Replica configuration
				sed -i 's/#wal_level = replica/wal_level = replica/' /etc/postgresql/postgresql.conf
				sed -i 's/#max_wal_senders = 0/max_wal_senders = 10/' /etc/postgresql/postgresql.conf
				sed -i 's/#archive_mode = off/archive_mode = on/' /etc/postgresql/postgresql.conf
				sed -i 's/#archive_command = .*/archive_command = '\''cp %p \/var\/lib\/postgresql\/archive\/%f'\''/' /etc/postgresql/postgresql.conf
				;;
			3)
				# Cluster configuration
				sed -i 's/#wal_level = replica/wal_level = replica/' /etc/postgresql/postgresql.conf
				sed -i 's/#max_wal_senders = 0/max_wal_senders = 20/' /etc/postgresql/postgresql.conf
				sed -i 's/#max_replication_slots = 0/max_replication_slots = 10/' /etc/postgresql/postgresql.conf
				;;
		esac
		
		# Enable performance tuning if requested
		if [[ "$POSTGRES_PERF" = 'y' ]]; then
			sed -i 's/#shared_buffers = 128MB/shared_buffers = 256MB/' /etc/postgresql/postgresql.conf
			sed -i 's/#effective_cache_size = 4GB/effective_cache_size = 1GB/' /etc/postgresql/postgresql.conf
			sed -i 's/#maintenance_work_mem = 64MB/maintenance_work_mem = 128MB/' /etc/postgresql/postgresql.conf
			sed -i 's/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.7/' /etc/postgresql/postgresql.conf
			sed -i 's/#wal_buffers = -1/wal_buffers = 16MB/' /etc/postgresql/postgresql.conf
			sed -i 's/#default_statistics_target = 100/default_statistics_target = 200/' /etc/postgresql/postgresql.conf
		fi
		
		# Restart PostgreSQL to apply configuration
		systemctl restart postgresql >> /tmp/postgresql-install.log 2>&1
		
		# Setup backup script if requested
		if [[ "$POSTGRES_BACKUP" = 'y' ]]; then
			echo -ne "       Setting up backup script           [..]\r"
			wget -O /usr/local/bin/postgresql-backup https://raw.githubusercontent.com/marirs/autoinstalls/master/postgresql/scripts/postgresql-backup >> /tmp/postgresql-install.log 2>&1
			chmod +x /usr/local/bin/postgresql-backup >> /tmp/postgresql-install.log 2>&1
			echo -ne "       Setting up backup script           [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		
		# Install extensions if requested
		if [[ "$POSTGRES_EXT" = 'y' ]]; then
			echo -ne "       Installing PostgreSQL extensions    [..]\r"
			sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;" >> /tmp/postgresql-install.log 2>&1
			sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" >> /tmp/postgresql-install.log 2>&1
			sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS unaccent;" >> /tmp/postgresql-install.log 2>&1
			sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;" >> /tmp/postgresql-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing PostgreSQL extensions    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing PostgreSQL extensions    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/postgresql-install.log"
				echo ""
				exit 1
			fi
		fi
		
		echo ""
		echo -e "${CGREEN}PostgreSQL installation successful!${CEND}"
		echo ""
		echo "PostgreSQL version: $([[ "$INSTALL_TYPE" = "repository" ]] && echo "Repository latest" || echo $POSTGRES_VER)"
		echo "Installation type: $CLUSTER_TYPE"
		echo "Authentication: $([[ "$POSTGRES_AUTH" = 'y' ]] && echo "Enabled" || echo "Disabled")"
		echo "pgAdmin4: $([[ "$POSTGRES_PGA" = 'y' ]] && echo "Installed" || echo "Not installed")"
		echo "Extensions: $([[ "$POSTGRES_EXT" = 'y' ]] && echo "Installed" || echo "Not installed")"
		echo ""
		echo "PostgreSQL configuration: /etc/postgresql/postgresql.conf"
		echo "Log file: /var/log/postgresql/postgresql.log"
		echo "Data directory: /var/lib/postgresql/data"
		echo ""
		echo "Installation log: /tmp/postgresql-install.log"
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
		# Database creation option would go here
		echo "Database creation option - not implemented yet"
		;;
	6)
		# Backup option would go here
		echo "Backup option - not implemented yet"
		;;
	7)
		# Restore option would go here
		echo "Restore option - not implemented yet"
		;;
	8)
		exit
		;;
esac
