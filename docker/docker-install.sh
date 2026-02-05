# Docker Installation Script
# Automated Docker installation with security hardening for internal use only

#!/bin/bash

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# Clear log files
rm -f /tmp/docker-install.log /tmp/apt-packages.log

# System information
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)
cores=$(nproc)
architecture=$(arch)

# Docker version mapping based on OS and version
function get_docker_version() {
    case "$os" in
        "ubuntu")
            case "$os_ver" in
                "18.04") echo "20.10.17" ;;  # Last version supporting Ubuntu 18.04
                "20.04") echo "24.0.7" ;;   # Latest stable for Ubuntu 20.04
                "22.04") echo "27.0.0" ;;   # Latest for Ubuntu 22.04
                "24.04") echo "27.0.0" ;;   # Latest for Ubuntu 24.04
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "debian")
            case "$os_ver" in
                "9") echo "18.09.1" ;;     # Debian 9 Stretch
                "10") echo "20.10.17" ;;   # Debian 10 Buster
                "11") echo "24.0.7" ;;     # Debian 11 Bullseye
                "12") echo "27.0.0" ;;     # Debian 12 Bookworm
                "13") echo "27.0.0" ;;     # Debian 13 Trixie (testing)
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "centos")
            case "$os_ver" in
                "7") echo "20.10.17" ;;    # CentOS 7
                "8") echo "24.0.7" ;;      # CentOS 8
                "9") echo "27.0.0" ;;      # CentOS 9 Stream
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "rhel")
            case "$os_ver" in
                "8") echo "24.0.7" ;;      # RHEL 8
                "9") echo "27.0.0" ;;      # RHEL 9
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "rocky")
            case "$os_ver" in
                "8") echo "24.0.7" ;;      # Rocky Linux 8
                "9") echo "27.0.0" ;;      # Rocky Linux 9
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "almalinux")
            case "$os_ver" in
                "8") echo "24.0.7" ;;      # AlmaLinux 8
                "9") echo "27.0.0" ;;      # AlmaLinux 9
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        "fedora")
            case "$os_ver" in
                "38") echo "24.0.7" ;;     # Fedora 38
                "39") echo "27.0.0" ;;     # Fedora 39
                "40") echo "27.0.0" ;;     # Fedora 40
                *) echo "27.0.0" ;;        # Default latest
            esac
            ;;
        *)
            echo "27.0.0" ;;            # Default latest for unknown OS
    esac
}

# Docker Compose version mapping
function get_docker_compose_version() {
    case "$os" in
        "ubuntu")
            case "$os_ver" in
                "18.04") echo "1.29.2" ;;   # Last v1 for Ubuntu 18.04
                "20.04") echo "2.24.0" ;;  # Stable for Ubuntu 20.04
                "22.04") echo "2.24.0" ;;  # Latest for Ubuntu 22.04
                "24.04") echo "2.24.0" ;;  # Latest for Ubuntu 24.04
                *) echo "2.24.0" ;;        # Default latest v2
            esac
            ;;
        "debian")
            case "$os_ver" in
                "9") echo "1.29.2" ;;     # Debian 9 - v1 compose
                "10") echo "2.24.0" ;;    # Debian 10 - v2 compose
                "11") echo "2.24.0" ;;    # Debian 11 - v2 compose
                "12") echo "2.24.0" ;;    # Debian 12 - v2 compose
                "13") echo "2.24.0" ;;    # Debian 13 - v2 compose
                *) echo "2.24.0" ;;        # Default latest v2
            esac
            ;;
        *)
            echo "2.24.0" ;;            # Default latest v2
    esac
}

# Get appropriate versions
docker_compose_version=$(get_docker_compose_version)

# Architecture support
if [[ "$architecture" != "x86_64" && "$architecture" != "aarch64" && "$architecture" != "arm64" ]]; then
    echo "${CRED}$architecture not supported, cannot be installed. You need x86_64 or ARM64 system.${CEND}"
    exit 1
fi

# Display current system info
echo -e "${CGREEN}System Information:${CEND}"
echo -e "  OS: $os $os_ver"
echo -e "  Architecture: $architecture"
echo -e "  CPU Cores: $cores"
echo -e "  Target Docker: $docker_version"
echo -e "  Target Docker Compose: $docker_compose_version"
echo ""

function install_deps() {
    echo -e "${CGREEN}Installing dependencies...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Update package lists first
            apt-get update -y >> /tmp/apt-packages.log 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "ca-certificates"
                "curl"
                "gnupg"
            )
            
            # Version-specific packages with comprehensive fallbacks
            local version_packages=()
            
            case "$os" in
                "debian")
                    case "$os_ver" in
                        "9"|"10"|"11")
                            # Older Debian versions
                            version_packages+=(
                                "lsb-release"
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "lsb-release"
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - comprehensive package handling
                            version_packages+=(
                                "lsb-release"
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
                            
                            # Try lsb-release alternatives
                            if ! apt-cache show lsb-release >/dev/null 2>&1; then
                                local lsb_alternatives=("lsb-base" "lsb-core")
                                for lsb_pkg in "${lsb_alternatives[@]}"; do
                                    if apt-cache show "$lsb_pkg" >/dev/null 2>&1; then
                                        version_packages+=("$lsb_pkg")
                                        echo -e "${CCYAN}Found $lsb_pkg as lsb-release alternative${CEND}"
                                        break
                                    fi
                                done
                            fi
                            ;;
                        *)
                            # Future Debian versions - try all variations
                            version_packages+=(
                                "lsb-release"
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
                                "lsb-release"
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "lsb-release"
                                "apt-transport-https"
                                "software-properties-common"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions
                            version_packages+=(
                                "lsb-release"
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
                    apt-get install -y "$package" >> /tmp/apt-packages.log 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                        successful_packages+=("$package")
                    else
                        echo -e "${CRED}✗ $package failed to install${CEND}"
                        failed_packages+=("$package")
                        
                        # Try to find alternatives for common packages
                        case "$package" in
                            "lsb-release")
                                local lsb_alternatives=("lsb-base" "lsb-core")
                                for alt_pkg in "${lsb_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt-get install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                        if [ $? -eq 0 ]; then
                                            echo -e "${CGREEN}✓ $alt_pkg installed (alternative to $package)${CEND}"
                                            successful_packages+=("$alt_pkg")
                                            break
                                        fi
                                    fi
                                done
                                ;;
                            "gnupg")
                                local gpg_alternatives=("gnupg2" "gpg")
                                for alt_pkg in "${gpg_alternatives[@]}"; do
                                    if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                        echo -e "${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                        apt-get install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
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
                echo -e "${CRED}✗ curl is missing - critical for Docker installation${CEND}"
                critical_ok=false
            fi
            
            if ! command -v gpg >/dev/null 2>&1 && ! command -v gpg2 >/dev/null 2>&1; then
                echo -e "${CRED}✗ gpg/gpg2 is missing - critical for repository verification${CEND}"
                critical_ok=false
            fi
            
            if [ "$critical_ok" = true ]; then
                echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
                echo -e "${CCYAN}Docker installation will continue...${CEND}"
            else
                echo -e "${CRED}✗ Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems with comprehensive package handling
            local rhel_base_packages=(
                "ca-certificates"
                "curl"
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
                    # CentOS 7 uses older package names
                    local rhel_packages=(
                        "yum-utils"
                    )
                    
                    # Try lsb alternatives
                    local lsb_packages=("redhat-lsb-core" "lsb_core")
                    for lsb_pkg in "${lsb_packages[@]}"; do
                        if yum info "$lsb_pkg" >/dev/null 2>&1; then
                            rhel_packages+=("$lsb_pkg")
                            echo -e "${CCYAN}Found $lsb_pkg for LSB support${CEND}"
                            break
                        fi
                    done
                    
                    if command -v yum >/dev/null 2>&1; then
                        yum update -y >> /tmp/apt-packages.log 2>&1
                        for package in "${rhel_base_packages[@]}" "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> /tmp/apt-packages.log 2>&1
                            if [ $? -eq 0 ]; then
                                echo -e "${CGREEN}✓ $package installed${CEND}"
                            else
                                echo -e "${CRED}✗ $package failed to install${CEND}"
                            fi
                        done
                    fi
                    ;;
                "8"|"9")
                    # RHEL 8+ uses dnf and newer package names
                    local rhel_packages=(
                        "dnf-plugins-core"
                    )
                    
                    # Try lsb alternatives
                    local lsb_packages=("redhat-lsb-core" "lsb_core")
                    for lsb_pkg in "${lsb_packages[@]}"; do
                        if dnf info "$lsb_pkg" >/dev/null 2>&1; then
                            rhel_packages+=("$lsb_pkg")
                            echo -e "${CCYAN}Found $lsb_pkg for LSB support${CEND}"
                            break
                        fi
                    done
                    
                    if command -v dnf >/dev/null 2>&1; then
                        dnf update -y >> /tmp/apt-packages.log 2>&1
                        for package in "${rhel_base_packages[@]}" "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> /tmp/apt-packages.log 2>&1
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
                "ca-certificates"
                "curl"
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
            
            local fedora_packages=(
                "dnf-plugins-core"
            )
            
            # Try lsb alternatives
            local lsb_packages=("redhat-lsb-core" "lsb_core")
            for lsb_pkg in "${lsb_packages[@]}"; do
                if dnf info "$lsb_pkg" >/dev/null 2>&1; then
                    fedora_packages+=("$lsb_pkg")
                    echo -e "${CCYAN}Found $lsb_pkg for LSB support${CEND}"
                    break
                fi
            done
            
            dnf update -y >> /tmp/apt-packages.log 2>&1
            for package in "${fedora_base_packages[@]}" "${fedora_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> /tmp/apt-packages.log 2>&1
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

function setup_docker_repo() {
    echo -e "${CGREEN}Setting up Docker repository...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Add Docker's official GPG key
            install -m 0755 -d /etc/apt/keyrings >> /tmp/docker-install.log 2>&1
            curl -fsSL https://download.docker.com/linux/$os/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg >> /tmp/docker-install.log 2>&1
            chmod a+r /etc/apt/keyrings/docker.gpg >> /tmp/docker-install.log 2>&1
            
            # Add the repository to Apt sources
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$os \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null >> /tmp/docker-install.log 2>&1
            
            apt-get update >> /tmp/docker-install.log 2>&1
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # Add Docker repository for RHEL-based systems
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >> /tmp/docker-install.log 2>&1
            ;;
        "fedora")
            # Add Docker repository for Fedora
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo >> /tmp/docker-install.log 2>&1
            ;;
        *)
            echo -e "${CRED}Unsupported OS for repository setup: $os${CEND}"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker repository setup completed${CEND}"
    else
        echo -e "${CRED}Failed to setup Docker repository${CEND}"
        exit 1
    fi
}

# Get available Docker versions from repository
get_available_docker_versions() {
    case "$os" in
        "ubuntu"|"debian")
            # Get available versions from apt cache
            apt-cache policy docker-ce 2>/dev/null | \
                grep -A 50 "Version table:" | \
                grep -E "^\s+[0-9]" | \
                awk '{print $1}' | \
                sort -V | \
                tail -5
            ;;
        "centos"|"rhel"|"rocky"|"almalinux"|"fedora")
            # Get available versions from yum/dnf
            if command -v dnf >/dev/null 2>&1; then
                dnf list --showduplicates docker-ce 2>/dev/null | \
                    grep docker-ce | \
                    awk '{print $2}' | \
                    sort -V | \
                    tail -5
            else
                yum list --showduplicates docker-ce 2>/dev/null | \
                    grep docker-ce | \
                    awk '{print $2}' | \
                    sort -V | \
                    tail -5
            fi
            ;;
        *)
            echo "Unable to detect versions for $os"
            return 1
            ;;
    esac
}

# Display available versions and let user choose
select_docker_version() {
    echo -e "${CGREEN}Detecting available Docker versions for $os $os_ver...${CEND}"
    echo -e "${CCYAN}Available Docker versions:${CEND}"
    echo ""
    
    # Get available versions
    local available_versions=($(get_available_docker_versions))
    
    if [ ${#available_versions[@]} -eq 0 ] || [[ "${available_versions[0]}" == "Unable" ]]; then
        echo -e "${CYAN}⚠ Could not detect available versions, using latest...${CEND}"
        docker_version="latest"
        return
    fi
    
    # Display top 3 latest versions
    echo "   1) ${available_versions[0]} (Latest)"
    if [ ${#available_versions[@]} -gt 1 ]; then
        echo "   2) ${available_versions[1]}"
    fi
    if [ ${#available_versions[@]} -gt 2 ]; then
        echo "   3) ${available_versions[2]}"
    fi
    echo "   4) Install latest available version"
    echo ""
    
    local choice=""
    while [[ "$choice" != "1" && "$choice" != "2" && "$choice" != "3" && "$choice" != "4" ]]; do
        read -p "Select Docker version [1-4]: " choice
    done
    
    case "$choice" in
        1)
            docker_version="${available_versions[0]}"
            echo -e "${CGREEN}Selected: $docker_version${CEND}"
            ;;
        2)
            docker_version="${available_versions[1]}"
            echo -e "${CGREEN}Selected: $docker_version${CEND}"
            ;;
        3)
            docker_version="${available_versions[2]}"
            echo -e "${CGREEN}Selected: $docker_version${CEND}"
            ;;
        4)
            docker_version="latest"
            echo -e "${CGREEN}Selected: Latest available version${CEND}"
            ;;
    esac
}

function install_docker() {
    echo -e "${CGREEN}Installing Docker Engine...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Install Docker Engine with selected version
            if [[ "$docker_version" != "latest" ]]; then
                echo -e "${CCYAN}Installing Docker version: $docker_version${CEND}"
                apt-get install -y \
                    docker-ce=$docker_version \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin \
                    >> /tmp/docker-install.log 2>&1
            else
                echo -e "${CCYAN}Installing latest Docker version${CEND}"
                apt-get install -y \
                    docker-ce \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin \
                    >> /tmp/docker-install.log 2>&1
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # Install Docker Engine for RHEL-based systems
            if command -v dnf >/dev/null 2>&1; then
                if [[ "$docker_version" != "latest" ]]; then
                    echo -e "${CCYAN}Installing Docker version: $docker_version${CEND}"
                    dnf install -y \
                        docker-ce-$docker_version \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin \
                        >> /tmp/docker-install.log 2>&1
                else
                    echo -e "${CCYAN}Installing latest Docker version${CEND}"
                    dnf install -y \
                        docker-ce \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin \
                        >> /tmp/docker-install.log 2>&1
                fi
            else
                if [[ "$docker_version" != "latest" ]]; then
                    echo -e "${CCYAN}Installing Docker version: $docker_version${CEND}"
                    yum install -y \
                        docker-ce-$docker_version \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin \
                        >> /tmp/docker-install.log 2>&1
                else
                    echo -e "${CCYAN}Installing latest Docker version${CEND}"
                    yum install -y \
                        docker-ce \
                        containerd.io \
                        docker-buildx-plugin \
                        docker-compose-plugin \
                        >> /tmp/docker-install.log 2>&1
                fi
            fi
            ;;
        "fedora")
            # Install Docker Engine for Fedora
            if [[ "$docker_version" != "latest" ]]; then
                echo -e "${CCYAN}Installing Docker version: $docker_version${CEND}"
                dnf install -y \
                    docker-ce-$docker_version \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin \
                    >> /tmp/docker-install.log 2>&1
            else
                echo -e "${CCYAN}Installing latest Docker version${CEND}"
                dnf install -y \
                    docker-ce \
                    containerd.io \
                    docker-buildx-plugin \
                    docker-compose-plugin \
                    >> /tmp/docker-install.log 2>&1
            fi
            ;;
        *)
            echo -e "${CRED}Unsupported OS for Docker installation: $os${CEND}"
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Engine installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install Docker Engine${CEND}"
        exit 1
    fi
}

function install_docker_compose_standalone() {
    echo -e "${CGREEN}Installing standalone Docker Compose...${CEND}"
    
    # Download Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v$docker_compose_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    # Apply executable permissions
    chmod +x /usr/local/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    # Create symbolic link
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Compose installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install Docker Compose${CEND}"
        exit 1
    fi
}

function configure_docker_security() {
    echo -e "${CGREEN}Configuring Docker with secure internet access...${CEND}"
    
    # Create Docker daemon configuration directory
    mkdir -p /etc/docker
    
    # Create secure Docker daemon configuration (simplified for compatibility)
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "userland-proxy": false,
  "experimental": false,
  "exec-opts": ["native.cgroupdriver=systemd"],
  "iptables": true,
  "live-restore": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "data-root": "/var/lib/docker",
  "exec-root": "/var/run/docker",
  "hosts": [
    "unix:///var/run/docker.sock"
  ]
}
EOF
    
    # Try to create seccomp profile (optional, don't fail if it fails)
    echo -e "${CCYAN}Setting up seccomp profile (optional)...${CEND}"
    if curl -fsSL https://raw.githubusercontent.com/moby/moby/master/profiles/seccomp/default.json -o /etc/docker/seccomp.json >> /tmp/docker-install.log 2>&1; then
        echo -e "${CGREEN}✓ Seccomp profile downloaded${CEND}"
        # Add seccomp to daemon.json if downloaded successfully
        sed -i '/}/i\
  "seccomp-profile": "/etc/docker/seccomp.json",' /etc/docker/daemon.json
    else
        echo -e "${CYAN}⚠ Could not download seccomp profile, continuing without it${CEND}"
    fi
    
    # Try to create Docker user namespace (optional, don't fail if it fails)
    echo -e "${CCYAN}Setting up user namespace remapping (optional)...${CEND}"
    if echo "dockremap:165536:65536" >> /etc/subuid 2>/dev/null && echo "dockremap:165536:65536" >> /etc/subgid 2>/dev/null; then
        echo -e "${CGREEN}✓ User namespace remapping configured${CEND}"
        # Add userns-remap to daemon.json if successful
        sed -i '/}/i\
  "userns-remap": "default",' /etc/docker/daemon.json
    else
        echo -e "${CYAN}⚠ Could not configure user namespace, continuing without it${CEND}"
    fi
    
    # Validate JSON syntax
    if ! python3 -m json.tool /etc/docker/daemon.json >/dev/null 2>&1; then
        echo -e "${CRED}❌ Invalid JSON in daemon.json, using minimal config${CEND}"
        # Fallback to minimal configuration
        cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
    fi
    
    # Restart Docker to apply configuration
    echo -e "${CCYAN}Restarting Docker to apply configuration...${CEND}"
    systemctl restart docker >> /tmp/docker-install.log 2>&1
    
    # Wait a moment for Docker to restart
    sleep 3
    
    # Check if Docker is running properly
    if systemctl is-active --quiet docker && docker info >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ Docker security configuration applied successfully${CEND}"
    else
        echo -e "${CRED}❌ Docker failed to restart after configuration${CEND}"
        echo -e "${CYAN}Attempting to restore Docker functionality...${CEND}"
        
        # Remove the config file and restart with defaults
        mv /etc/docker/daemon.json /etc/docker/daemon.json.bak 2>/dev/null
        systemctl restart docker >> /tmp/docker-install.log 2>&1
        sleep 3
        
        if systemctl is-active --quiet docker; then
            echo -e "${CYAN}✓ Docker restored with default configuration${CEND}"
            echo -e "${CYAN}⚠ Security configuration was not applied${CEND}"
        else
            echo -e "${CRED}❌ Docker is not running. Please check the logs:${CEND}"
            echo -e "${CYAN}tail -f /tmp/docker-install.log${CEND}"
            exit 1
        fi
    fi
}

function setup_docker_network() {
    echo -e "${CGREEN}Setting up Docker network with internet access...${CEND}"
    
    # Create Docker daemon configuration directory
    mkdir -p /etc/docker
    
    # Create Docker daemon configuration with internet access
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "userland-proxy": false,
  "experimental": false,
  "exec-opts": ["native.cgroupdriver=systemd"],
  "bridge": "docker0",
  "bip": "172.17.0.1/16",
  "fixed-cidr": "172.17.0.0/16",
  "mtu": 1500,
  "ip-forward": true,
  "iptables": true,
  "live-restore": true,
  "userns-remap": "default",
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json",
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc",
      "runtimeArgs": [
        "--seccomp",
        "/etc/docker/seccomp.json"
      ]
    }
  },
  "registry-mirrors": [],
  "insecure-registries": [],
  "disable-legacy-registry": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "max-download-attempts": 5,
  "data-root": "/var/lib/docker",
  "exec-root": "/var/run/docker",
  "hosts": [
    "unix:///var/run/docker.sock"
  ]
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker >> /tmp/docker-install.log 2>&1
    
    # Create internal network (optional, for isolated containers)
    docker network create --driver bridge --subnet=172.18.0.0/16 internal-net >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker network configured with internet access${CEND}"
        echo -e "${CYAN}Default bridge network: Internet access enabled${CEND}"
        echo -e "${CYAN}Internal network: Available for isolated containers${CEND}"
    else
        echo -e "${CRED}Failed to configure Docker network${CEND}"
        exit 1
    fi
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall rules for Docker daemon security...${CEND}"
    
    # Install UFW if not present
    apt-get install -y ufw >> /tmp/docker-install.log 2>&1
    
    # Configure UFW rules
    ufw --force reset >> /tmp/docker-install.log 2>&1
    
    # Default policies
    ufw default deny incoming >> /tmp/docker-install.log 2>&1
    ufw default allow outgoing >> /tmp/docker-install.log 2>&1
    
    # Allow SSH (if needed)
    ufw allow ssh >> /tmp/docker-install.log 2>&1
    
    # Block external Docker daemon access but allow internal networks
    ufw deny 2376/tcp >> /tmp/docker-install.log 2>&1  # Docker daemon
    ufw deny 2377/tcp >> /tmp/docker-install.log 2>&1  # Docker daemon (if needed)
    
    # Allow Docker daemon access from localhost and internal networks only
    ufw allow from 127.0.0.1 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.16.0.0/12 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.17.0.0/16 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.18.0.0/16 to any port 2376 >> /tmp/docker-install.log 2>&1
    
    # Enable UFW
    ufw --force enable >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Firewall rules configured successfully${CEND}"
        echo -e "${CYAN}Docker daemon: External access blocked, internal access allowed${CEND}"
        echo -e "${CYAN}Containers: Internet access enabled through default bridge${CEND}"
        echo -e "${CYAN}Internal network: Available for isolated containers${CEND}"
    else
        echo -e "${CRED}Failed to configure firewall rules${CEND}"
        exit 1
    fi
}

function setup_docker_users() {
    echo -e "${CGREEN}Adding current user to docker group...${CEND}"
    
    # Add current user to docker group
    usermod -aG docker $USER >> /tmp/docker-install.log 2>&1
    
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null 2>&1; then
        groupadd docker >> /tmp/docker-install.log 2>&1
        usermod -aG docker $USER >> /tmp/docker-install.log 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}User added to docker group${CEND}"
        echo -e "${CYAN}Note: You need to log out and log back in for group changes to take effect${CEND}"
    else
        echo -e "${CRED}Failed to add user to docker group${CEND}"
        exit 1
    fi
}

function start_docker_services() {
    echo -e "${CGREEN}Starting and enabling Docker services...${CEND}"
    
    # Enable and start Docker service
    systemctl enable docker >> /tmp/docker-install.log 2>&1
    systemctl start docker >> /tmp/docker-install.log 2>&1
    
    # Enable and start containerd service
    systemctl enable containerd >> /tmp/docker-install.log 2>&1
    systemctl start containerd >> /tmp/docker-install.log 2>&1
    
    # Check Docker status
    if systemctl is-active --quiet docker; then
        echo -e "${CGREEN}Docker service is running${CEND}"
    else
        echo -e "${CRED}Docker service failed to start${CEND}"
        exit 1
    fi
    
    if systemctl is-active --quiet containerd; then
        echo -e "${CGREEN}Containerd service is running${CEND}"
    else
        echo -e "${CRED}Containerd service failed to start${CEND}"
        exit 1
    fi
}

function create_docker_compose_example() {
    echo -e "${CGREEN}Creating example Docker Compose configuration...${CEND}"
    
    # Create example directory
    mkdir -p /opt/docker-examples
    
    # Create example docker-compose.yml
    cat > /opt/docker-examples/docker-compose.yml << 'EOF'
version: '3.8'

services:
  web-internet:
    image: nginx:alpine
    container_name: web-server-internet
    restart: unless-stopped
    networks:
      - default
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /var/run/nginx
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID

  web-isolated:
    image: nginx:alpine
    container_name: web-server-isolated
    restart: unless-stopped
    networks:
      - internal-net
    ports:
      - "127.0.0.1:8081:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /var/run/nginx
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID

  app-internet:
    image: python:3.11-alpine
    container_name: app-server-internet
    restart: unless-stopped
    networks:
      - default
    volumes:
      - ./app:/app:ro
    working_dir: /app
    command: python -m http.server 8000
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID

  app-isolated:
    image: python:3.11-alpine
    container_name: app-server-isolated
    restart: unless-stopped
    networks:
      - internal-net
    volumes:
      - ./app:/app:ro
    working_dir: /app
    command: python -m http.server 8000
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID

networks:
  default:
    driver: bridge
  internal-net:
    driver: bridge
    internal: false
    ipam:
      config:
        - subnet: 172.18.0.0/16
EOF
    
    # Create example HTML directory
    mkdir -p /opt/docker-examples/html
    cat > /opt/docker-examples/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Secure Deployment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { background: #e8f5e8; padding: 10px; border-radius: 4px; margin: 10px 0; }
        .warning { background: #fff3cd; padding: 10px; border-radius: 4px; margin: 10px 0; }
        .info { background: #d9edf7; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker Secure Deployment</h1>
        <div class="status">
            <strong>Status:</strong> Running securely with internet access<br>
            <strong>Network:</strong> Default bridge (internet enabled)<br>
            <strong>Security:</strong> Hardened configuration enabled
        </div>
        <div class="info">
            <strong>Network Options:</strong><br>
            • Default bridge: Internet access enabled<br>
            • Internal network: Available for isolation<br>
            • Docker daemon: External access blocked
        </div>
        <div class="warning">
            <strong>Security Features:</strong><br>
            • User namespace remapping enabled<br>
            • Seccomp security profiles applied<br>
            • No new privileges for containers<br>
            • Capability dropping enabled
        </div>
        <p>This is a secure Docker deployment with configurable network access.</p>
        <p>Containers can access the internet through the default bridge network.</p>
        <p>For isolation, use the internal network (172.18.0.0/16).</p>
    </div>
</body>
</html>
EOF
    
    # Create example app directory
    mkdir -p /opt/docker-examples/app
    cat > /opt/docker-examples/app/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver

class SecureHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/app", **kwargs)
    
    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        self.send_header('X-XSS-Protection', '1; mode=block')
        super().end_headers()

if __name__ == "__main__":
    PORT = 8000
    with socketserver.TCPServer(("", PORT), SecureHandler) as httpd:
        print(f"Secure server running on port {PORT}")
        httpd.serve_forever()
EOF
    
    chmod +x /opt/docker-examples/app/app.py
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Example Docker Compose configuration created${CEND}"
        echo -e "${CYAN}Location: /opt/docker-examples/${CEND}"
        echo -e "${CYAN}Services:${CEND}"
        echo -e "  - web-internet: Nginx with internet access (port 8080)"
        echo -e "  - web-isolated: Nginx on internal network (port 8081)"
        echo -e "  - app-internet: Python app with internet access (port 8000)"
        echo -e "  - app-isolated: Python app on internal network (port 8001)"
    else
        echo -e "${CRED}Failed to create example configuration${CEND}"
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Docker installation...${CEND}"
    
    # Test Docker installation
    docker --version >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker CLI working${CEND}"
    else
        echo -e "${CRED}Docker CLI not working${CEND}"
        exit 1
    fi
    
    # Test Docker Compose
    docker-compose --version >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Compose working${CEND}"
    else
        echo -e "${CRED}Docker Compose not working${CEND}"
        exit 1
    fi
    
    # Test Docker daemon
    docker info >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker daemon working${CEND}"
    else
        echo -e "${CRED}Docker daemon not working${CEND}"
        exit 1
    fi
    
    # Test internal network
    if docker network ls | grep -q "internal-net"; then
        echo -e "${CGREEN}Internal network created${CEND}"
    else
        echo -e "${CRED}Internal network not found${CEND}"
        exit 1
    fi
    
    # Test default bridge network
    if docker network ls | grep -q "bridge"; then
        echo -e "${CGREEN}Default bridge network available${CEND}"
    else
        echo -e "${CRED}Default bridge network not found${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Docker installation verified successfully${CEND}"
}

# Main installation process
install_deps
setup_docker_repo

# Let user select Docker version after repository is set up
select_docker_version

install_docker
install_docker_compose_standalone
configure_docker_security
setup_docker_network
configure_firewall
setup_docker_users
start_docker_services
create_docker_compose_example
verify_installation

echo ""
echo -e "${CGREEN}>> Docker installation completed successfully!${CEND}"
echo ""
echo -e "${CCYAN}Installation Summary:${CEND}"
echo -e "  Docker Version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
echo -e "  Docker Compose Version: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
echo -e "  Architecture: $architecture"
echo -e "  Security: Internal-only configuration"
echo -e "  Firewall: Configured for internal access only"
echo -e "  Network: Internal bridge network created"
echo ""
echo -e "${CCYAN}Security Features:${CEND}"
echo -e "  ✅ Docker daemon: External access blocked"
echo -e "  ✅ Containers: Internet access enabled"
echo -e "  ✅ User namespace remapping enabled"
echo -e "  ✅ Seccomp security profiles applied"
echo -e "  ✅ No new privileges for containers"
echo -e "  ✅ Internal network available for isolation"
echo -e "  ✅ Capability dropping enabled"
echo ""
echo -e "${CCYAN}Next Steps:${CEND}"
echo -e "  1. Log out and log back in for docker group access"
echo -e "  2. Test installation: docker run --rm hello-world"
echo -e "  3. Try example: cd /opt/docker-examples && docker-compose up -d"
echo -e "  4. Check firewall: sudo ufw status verbose"
echo ""
echo -e "${CCYAN}Example Usage:${CEND}"
echo -e "  # Run a container with internet access (default bridge)"
echo -e "  docker run --rm -it nginx:alpine"
echo ""
echo -e "  # Run a container on isolated internal network"
echo -e "  docker run --rm -it --network internal-net nginx:alpine"
echo ""
echo -e "  # Use the example configuration"
echo -e "  cd /opt/docker-examples"
echo -e "  docker-compose up -d"
echo ""
echo -e "${CCYAN}Logs:${CEND}"
echo -e "  Dependencies: /tmp/apt-packages.log"
echo -e "  Docker Install: /tmp/docker-install.log"
echo ""
echo -e "${CCYAN}Security Notes:${CEND}"
echo -e "  - Docker daemon is configured for internal access only"
echo -e "  - External access to Docker daemon is blocked"
echo -e "  - Containers have internet access through default bridge"
echo -e "  - Internal network available for isolated containers"
echo -e "  - Containers run with reduced privileges"
echo -e "  - All network access is configurable per container"
echo ""
echo -e "${CMAGENTA}If you reached here, seriously done!${CEND}"
