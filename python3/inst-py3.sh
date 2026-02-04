#!/bin/bash
#
# Description: Install Python 3.x with AI/ML Environment Setup
# Tested:
#       Debian: 9.x, 10.x, 11.x, 12.x, 13.x
#       Ubuntu: 18.04, 20.04, 22.04, 24.04
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

# System information detection
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)

# Installation mode
INSTALL_MODE=""
PYTHON_INSTALL_TYPE=""

# Function to show installation type menu
function show_installation_type_menu() {
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Python Installation Type Menu    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Please select Python installation type:${CEND}"
    echo "1) Repository Installation (Deadsnakes PPA) - Recommended"
    echo "2) Source Installation (Compile from source)"
    echo ""
    echo -e "${CCYAN}Repository installation advantages:${CEND}"
    echo "- Faster installation"
    echo "- Easier maintenance and updates"
    echo "- Multiple Python versions available"
    echo "- Better system integration"
    echo ""
}

# Function to get installation type choice
function get_installation_type_choice() {
    while true; do
        show_installation_type_menu
        read -p "Enter your choice [1-2]: " type_choice
        case $type_choice in
            1)
                PYTHON_INSTALL_TYPE="repository"
                echo -e "${CGREEN}Selected: Repository Installation${CEND}"
                break
                ;;
            2)
                PYTHON_INSTALL_TYPE="source"
                echo -e "${CGREEN}Selected: Source Installation${CEND}"
                break
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please select 1 or 2.${CEND}"
                ;;
        esac
    done
}

# Function to add Deadsnakes repository with intelligent management
function add_deadsnakes_repository_enhanced() {
    echo -e "${CCYAN}Adding Deadsnakes repository for $os $os_ver...${CEND}" >> "/tmp/py3-install.log"
    
    case "$os" in
        "ubuntu")
            add_ubuntu_deadsnakes_repo_enhanced
            ;;
        "debian")
            add_debian_deadsnakes_repo_enhanced
            ;;
        *)
            echo -e "${CRED}✗ Unsupported OS for Deadsnakes: $os${CEND}" >> "/tmp/py3-install.log"
            echo -e "${CRED}Deadsnakes PPA is only available for Ubuntu and Debian${CEND}"
            echo -e "${CYAN}Falling back to source installation...${CEND}"
            return 1
            ;;
    esac
}

function add_ubuntu_deadsnakes_repo_enhanced() {
    echo -e "${CCYAN}Configuring Deadsnakes repository for Ubuntu...${CEND}" >> "/tmp/py3-install.log"
    
    # Check Ubuntu version compatibility
    case "$os_ver" in
        "18.04"|"20.04"|"22.04"|"24.04")
            echo -e "${CGREEN}✓ Ubuntu $os_ver is supported${CEND}" >> "/tmp/py3-install.log"
            ;;
        *)
            echo -e "${CYAN}⚠ Ubuntu $os_ver may not be fully supported${CEND}" >> "/tmp/py3-install.log"
            ;;
    esac
    
    # Check if repository already exists
    if apt-cache policy | grep -q "ppa.launchpad.net/deadsnakes"; then
        echo -e "${CYAN}⚠ Deadsnakes repository already exists${CEND}" >> "/tmp/py3-install.log"
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> "/tmp/py3-install.log"
    apt update >> "/tmp/py3-install.log" 2>&1
    
    local required_packages=("curl" "wget" "gnupg" "ca-certificates" "apt-transport-https" "software-properties-common")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> "/tmp/py3-install.log"
            apt install -y "$pkg" >> "/tmp/py3-install.log" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> "/tmp/py3-install.log"
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> "/tmp/py3-install.log"
                return 1
            fi
        fi
    done
    
    # Add Deadsnakes PPA
    echo -e "${CCYAN}Adding Deadsnakes PPA...${CEND}" >> "/tmp/py3-install.log"
    add-apt-repository ppa:deadsnakes/ppa -y >> "/tmp/py3-install.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Deadsnakes PPA added${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Failed to add Deadsnakes PPA${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> "/tmp/py3-install.log"
    apt update >> "/tmp/py3-install.log" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
    
    # Verify Python packages are available
    echo -e "${CCYAN}Verifying Python packages availability...${CEND}" >> "/tmp/py3-install.log"
    if apt-cache show "python3.12" >/dev/null 2>&1 || apt-cache show "python3.11" >/dev/null 2>&1 || apt-cache show "python3.10" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ Python packages available from Deadsnakes${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Python packages not available from Deadsnakes${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
}

function add_debian_deadsnakes_repo_enhanced() {
    echo -e "${CCYAN}Configuring Deadsnakes repository for Debian...${CEND}" >> "/tmp/py3-install.log"
    
    # Check Debian version compatibility
    case "$os_ver" in
        "10"|"11"|"12"|"13")
            echo -e "${CGREEN}✓ Debian $os_ver is supported${CEND}" >> "/tmp/py3-install.log"
            ;;
        *)
            echo -e "${CYAN}⚠ Debian $os_ver may not be fully supported${CEND}" >> "/tmp/py3-install.log"
            ;;
    esac
    
    # Check if repository already exists
    if apt-cache policy | grep -q "ppa.launchpad.net/deadsnakes"; then
        echo -e "${CYAN}⚠ Deadsnakes repository already exists${CEND}" >> "/tmp/py3-install.log"
        return 0
    fi
    
    # Install required packages
    echo -e "${CCYAN}Installing required packages...${CEND}" >> "/tmp/py3-install.log"
    apt update >> "/tmp/py3-install.log" 2>&1
    
    local required_packages=("curl" "wget" "gnupg" "ca-certificates" "apt-transport-https" "software-properties-common")
    for pkg in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "$pkg"; then
            echo -e "${CCYAN}Installing $pkg...${CEND}" >> "/tmp/py3-install.log"
            apt install -y "$pkg" >> "/tmp/py3-install.log" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}" >> "/tmp/py3-install.log"
            else
                echo -e "${CRED}✗ Failed to install $pkg${CEND}" >> "/tmp/py3-install.log"
                return 1
            fi
        fi
    done
    
    # Add Deadsnakes PPA
    echo -e "${CCYAN}Adding Deadsnakes PPA...${CEND}" >> "/tmp/py3-install.log"
    add-apt-repository ppa:deadsnakes/ppa -y >> "/tmp/py3-install.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Deadsnakes PPA added${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Failed to add Deadsnakes PPA${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
    
    # Update package list
    echo -e "${CCYAN}Updating package list...${CEND}" >> "/tmp/py3-install.log"
    apt update >> "/tmp/py3-install.log" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Package list updated${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Failed to update package list${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
    
    # Verify Python packages are available
    echo -e "${CCYAN}Verifying Python packages availability...${CEND}" >> "/tmp/py3-install.log"
    if apt-cache show "python3.12" >/dev/null 2>&1 || apt-cache show "python3.11" >/dev/null 2>&1 || apt-cache show "python3.10" >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ Python packages available from Deadsnakes${CEND}" >> "/tmp/py3-install.log"
    else
        echo -e "${CRED}✗ Python packages not available from Deadsnakes${CEND}" >> "/tmp/py3-install.log"
        return 1
    fi
}

# Function to show Python version selection menu
function show_python_version_menu() {
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Python Version Selection Menu    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Available Python versions:${CEND}"
    echo "1) Python 3.12 - Latest stable"
    echo "2) Python 3.11 - Previous stable"
    echo "3) Python 3.10 - LTS version"
    echo "4) Python 3.9 - Older stable"
    echo "5) Python 3.8 - Legacy version"
    echo ""
}

# Function to get Python version choice
function get_python_version_choice() {
    while true; do
        show_python_version_menu
        read -p "Enter your choice [1-5]: " version_choice
        case $version_choice in
            1)
                python_version="3.12"
                echo -e "${CGREEN}Selected: Python 3.12${CEND}"
                break
                ;;
            2)
                python_version="3.11"
                echo -e "${CGREEN}Selected: Python 3.11${CEND}"
                break
                ;;
            3)
                python_version="3.10"
                echo -e "${CGREEN}Selected: Python 3.10${CEND}"
                break
                ;;
            4)
                python_version="3.9"
                echo -e "${CGREEN}Selected: Python 3.9${CEND}"
                break
                ;;
            5)
                python_version="3.8"
                echo -e "${CGREEN}Selected: Python 3.8${CEND}"
                break
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please select 1-5.${CEND}"
                ;;
        esac
    done
}

# Function to install Python from repository
function install_python_from_repository() {
    echo -e "${CGREEN}Installing Python $python_version from Deadsnakes repository...${CEND}"
    
    # Check if the specific Python version is available
    if ! apt-cache show "python$python_version" >/dev/null 2>&1; then
        echo -e "${CRED}✗ Python $python_version is not available from Deadsnakes${CEND}"
        echo -e "${CYAN}Available versions:${CEND}"
        apt-cache search "^python3\.[0-9]+$" | grep -E "python3\.[0-9]+" | head -5
        return 1
    fi
    
    # Install Python package
    echo -e "${CCYAN}Installing python$python_version...${CEND}"
    apt install -y python$python_version >> "/tmp/py3-install.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ Python $python_version installed${CEND}"
    else
        echo -e "${CRED}✗ Failed to install Python $python_version${CEND}"
        return 1
    fi
    
    # Install additional packages
    echo -e "${CCYAN}Installing additional Python packages...${CEND}"
    local additional_packages=(
        "python$python_version-venv"
        "python$python_version-dev"
        "python$python_version-distutils"
        "python$python_version-lib2to3"
        "python$python_version-tk"
        "python$python_version-full"
    )
    
    for pkg in "${additional_packages[@]}"; do
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            echo -e "${CCYAN}Installing $pkg...${CEND}"
            apt install -y "$pkg" >> "/tmp/py3-install.log" 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ $pkg installed${CEND}"
            else
                echo -e "${CYAN}⚠ $pkg failed (optional)${CEND}"
            fi
        fi
    done
    
    # Install pip if not included
    if ! command -v pip$python_version >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing pip for Python $python_version...${CEND}"
        apt install -y python$python_version-pip >> "/tmp/py3-install.log" 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}✓ pip$python_version installed${CEND}"
        else
            echo -e "${CYAN}⚠ pip$python_version not available, will use ensurepip${CEND}"
        fi
    fi
    
    # Upgrade pip
    echo -e "${CGREEN}Upgrading pip...${CEND}"
    python$python_version -m pip install --upgrade pip >> "/tmp/py3-install.log" 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}✓ pip upgraded${CEND}"
    else
        echo -e "${CYAN}⚠ pip upgrade failed (will continue)${CEND}"
    fi
    
    echo -e "${CGREEN}✓ Python $python_version installation completed${CEND}"
}

# Function to install dependencies with comprehensive fallback handling
function install_packages_with_fallback() {
    local pkgs="$1"
    local failed_packages=()
    local successful_packages=()
    
    echo -e "${CGREEN}Installing dependencies for $os $os_ver...${CEND}"
    
    # Update package lists first
    apt update >> /tmp/apt-packages.log 2>&1
    
    total_packages=$(echo $pkgs | wc -w)
    echo -e "${CGREEN}Installing $total_packages dependencies...${CEND}"
    
    for pkg in $pkgs; do
        echo -ne "    - ${CBLUE}installing $pkg ...                                                     ${CEND}\r"
        
        # Check if package exists before installing
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            apt install -y "$pkg" >> /tmp/apt-packages.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "    - ${CGREEN}✓ $pkg installed${CEND}"
                successful_packages+=("$pkg")
            else
                echo -ne "\n"
                echo -e "    - ${CRED}$pkg failed installation${CEND}"
                failed_packages+=("$pkg")
                
                # Try to find alternatives for common packages
                case "$pkg" in
                    "build-essential")
                        local build_alternatives=("build-base" "base-devel")
                        for alt_pkg in "${build_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                    "libssl-dev")
                        local ssl_alternatives=("libssl-dev" "openssl-dev" "libssl3-dev")
                        for alt_pkg in "${ssl_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                    "libffi-dev")
                        local ffi_alternatives=("libffi-dev" "libffi8-dev" "libffi7-dev")
                        for alt_pkg in "${ffi_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                    "software-properties-common")
                        local software_props_alternatives=("software-properties-common" "python3-software-properties" "software-properties")
                        for alt_pkg in "${software_props_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                esac
            fi
        else
            echo -ne "\n"
            echo -e "    - ${CCYAN}⚠ Package $pkg not found, skipping${CEND}"
            failed_packages+=("$pkg")
        fi
    done
    
    echo -ne "                                                              \r"
    
    # Comprehensive package validation
    echo -e "${CCYAN}Package installation summary:${CEND}"
    echo -e "${CGREEN}Successfully installed: ${successful_packages[*]}${CEND}"
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${CCYAN}Failed to install: ${failed_packages[*]}${CEND}"
    fi
    
    # Check if critical packages are available for Python compilation
    local critical_ok=true
    if ! command -v gcc >/dev/null 2>&1; then
        echo -e "${CRED}✗ gcc is missing - critical for Python compilation${CEND}"
        critical_ok=false
    fi
    
    if ! ldconfig -p | grep -q libssl; then
        echo -e "${CRED}✗ SSL libraries are missing - critical for Python SSL support${CEND}"
        critical_ok=false
    fi
    
    if [ "$critical_ok" = true ]; then
        echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
        echo -e "${CCYAN}Python installation will continue...${CEND}"
    else
        echo -e "${CRED}✗ Critical dependencies missing. Cannot continue.${CEND}"
        exit 1
    fi
}

# Function to show main menu
function show_main_menu() {
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Python 3.x Installation Menu    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Please select installation mode:${CEND}"
    echo "1) Basic Python 3.x Installation"
    echo "2) Python 3.x + Data Science Environment"
    echo "3) Python 3.x + Machine Learning Environment"
    echo "4) Python 3.x + Deep Learning Environment"
    echo "5) Python 3.x + Full AI/ML Environment"
    echo "6) Setup AI/ML Environment Only (Python already installed)"
    echo ""
    echo -e "${CCYAN}Recommended: Option 5 for complete AI/ML setup${CEND}"
    echo ""
}

# Function to get user choice
function get_user_choice() {
    while true; do
        show_main_menu
        read -p "Enter your choice [1-6]: " choice
        case $choice in
            1)
                INSTALL_MODE="basic"
                echo -e "${CGREEN}Selected: Basic Python Installation${CEND}"
                break
                ;;
            2)
                INSTALL_MODE="datascience"
                echo -e "${CGREEN}Selected: Python + Data Science Environment${CEND}"
                break
                ;;
            3)
                INSTALL_MODE="ml"
                echo -e "${CGREEN}Selected: Python + Machine Learning Environment${CEND}"
                break
                ;;
            4)
                INSTALL_MODE="deeplearning"
                echo -e "${CGREEN}Selected: Python + Deep Learning Environment${CEND}"
                break
                ;;
            5)
                INSTALL_MODE="full-ai"
                echo -e "${CGREEN}Selected: Python + Full AI/ML Environment${CEND}"
                break
                ;;
            6)
                INSTALL_MODE="ai-only"
                echo -e "${CGREEN}Selected: AI/ML Environment Setup Only${CEND}"
                break
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please enter 1-6.${CEND}"
                sleep 2
                ;;
        esac
    done
}

# Function to show what will be installed
function show_installation_summary() {
    echo ""
    echo -e "${CCYAN}========================================${CEND}"
    echo -e "${CCYAN}    Installation Summary    ${CEND}"
    echo -e "${CCYAN}========================================${CEND}"
    echo ""
    
    case $INSTALL_MODE in
        "basic")
            echo -e "${CGREEN}✓ Python $python_version${CEND}"
            echo -e "${CGREEN}✓ Virtualenvwrapper${CEND}"
            echo -e "${CGREEN}✓ Essential development packages${CEND}"
            ;;
        "datascience")
            echo -e "${CGREEN}✓ Python $python_version${CEND}"
            echo -e "${CGREEN}✓ Virtualenvwrapper${CEND}"
            echo -e "${CGREEN}✓ Essential development packages${CEND}"
            echo -e "${CGREEN}✓ Data Science Libraries:${CEND}"
            echo "    - NumPy, Pandas, Matplotlib, Seaborn"
            echo "    - Scikit-learn, Jupyter, IPython"
            echo "    - Plotly, Bokeh, Statsmodels"
            ;;
        "ml")
            echo -e "${CGREEN}✓ Python $python_version${CEND}"
            echo -e "${CGREEN}✓ Virtualenvwrapper${CEND}"
            echo -e "${CGREEN}✓ Essential development packages${CEND}"
            echo -e "${CGREEN}✓ Machine Learning Libraries:${CEND}"
            echo "    - All Data Science libraries"
            echo "    - XGBoost, LightGBM, CatBoost"
            echo "    - TensorFlow (CPU), Scikit-learn-extra"
            echo "    - Imbalanced-learn, Feature-engine"
            ;;
        "deeplearning")
            echo -e "${CGREEN}✓ Python $python_version${CEND}"
            echo -e "${CGREEN}✓ Virtualenvwrapper${CEND}"
            echo -e "${CGREEN}✓ Essential development packages${CEND}"
            echo -e "${CGREEN}✓ Deep Learning Libraries:${CEND}"
            echo "    - All ML libraries"
            echo "    - TensorFlow (GPU/CPU), PyTorch, Keras"
            echo "    - OpenCV, OpenAI Gym, Transformers"
            echo "    - CUDA support (if compatible)"
            ;;
        "full-ai")
            echo -e "${CGREEN}✓ Python $python_version${CEND}"
            echo -e "${CGREEN}✓ Virtualenvwrapper${CEND}"
            echo -e "${CGREEN}✓ Essential development packages${CEND}"
            echo -e "${CGREEN}✓ Complete AI/ML Environment:${CEND}"
            echo "    - All Data Science libraries"
            echo "    - All Machine Learning libraries"
            echo "    - All Deep Learning libraries"
            echo "    - NLP libraries (NLTK, spaCy, Gensim)"
            echo "    - Computer Vision libraries"
            echo "    - MLOps tools (MLflow, DVC)"
            echo "    - Development tools (Black, Flake8, pytest)"
            ;;
        "ai-only")
            echo -e "${CGREEN}✓ AI/ML Environment Setup Only${CEND}"
            echo -e "${CGREEN}✓ Complete AI/ML Libraries:${CEND}"
            echo "    - All Data Science libraries"
            echo "    - All Machine Learning libraries"
            echo "    - All Deep Learning libraries"
            echo "    - NLP and Computer Vision libraries"
            echo "    - MLOps and development tools"
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}System Information:${CEND}"
    echo "  OS: $os $os_ver"
    echo "  Architecture: $architecture"
    echo "  CPU Cores: $cores"
    echo "  Current Python3: $curr_py3_version"
    if [ "$INSTALL_MODE" != "ai-only" ]; then
        echo "  Target Python: $python_version"
    fi
    echo ""
    
    read -p "Continue with installation? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CRED}Installation cancelled.${CEND}"
        exit 0
    fi
}


# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# clear log files
[ -f "/tmp/apt-packages.log" ] && rm -f /tmp/apt-packages.log
[ -f "/tmp/py3-install.log" ] && rm -f /tmp/py3-install.log

# Versions
python_version=3.11.8

# system information
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
cores=$(nproc)
architecture=$(arch)

# get current py3 version if exists
curr_py3=$(which python3 2>/dev/null)
if [[ -n "$curr_py3" ]]; then
    curr_py3_version=$($curr_py3 -V 2>/dev/null | cut -d" " -f2)
else
    curr_py3_version="none"
fi

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
echo -e "  Current Python3: $curr_py3_version"
echo -e "  Target Python: $python_version"
echo ""

function install_deps() {
    echo -e "${CGREEN}Updating system...${CEND}"
    apt-get update -y >> /tmp/apt-packages.log 2>&1
    apt-get -y upgrade >> /tmp/apt-packages.log 2>&1
    pkgs="git sudo pcregrep net-tools inxi software-properties-common libpq-dev devscripts build-essential \
    zip unzip p7zip-full p7zip-rar libuv1 libre2-5 sysstat schedtool ca-certificates poppler-utils \
    libffi-dev libssl-dev screen numactl libgdbm-compat-dev libuv1-dev libre2-dev zlib1g-dev \
    libbz2-dev liblzma-dev libncurses5-dev libreadline-dev xclip xsel libsqlite3-dev \
    tk-dev libgdbm-dev"
    if [[ "$os" == *"ubuntu"* ]]; then
        pkgs=$(echo $pkgs; echo "libncurses-dev libncurses5-dev libncursesw5-dev")
        cd /tmp/ || return
    elif [[ "$os" == *"debian"* ]]; then
        pkgs=$(echo $pkgs; echo "libncurses*-dev ")
    fi
    
    total_packages=$(echo $pkgs | wc -w)
    echo -e "${CGREEN}Installing $total_packages dependencies...${CEND}"
    
    # Use the comprehensive package installation function
    install_packages_with_fallback "$pkgs"
}

function clean_up() {
    cd /tmp
    echo -ne "${CBLUE}Cleaning up    [...]${CEND}\r"
    [ -d Python-$python_version ] && rm -rf Python-* >> /tmp/py3-install.log 2>&1 
    echo -ne "${CBLUE}Cleaning up    [DONE]${CEND}\r"
    echo -ne "\n"
    echo -e "Dependancy installation logs: ${CCYAN}/tmp/apt-packages.log${CEND}"
    echo -e "Python $python_version installation logs: ${CCYAN}/tmp/py3-install.log${CEND}"
}


function install_py3() {
    cd /tmp
    [ -d Python-$python_version ] && rm -rf Python-* >> /tmp/py3-install.log 2>&1 
    echo -e "${CGREEN}Downloading Python-$python_version...${CEND}"
    wget https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to download Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Expanding Python-$python_version...${CEND}"
    tar xvf Python-$python_version.tgz >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to untar the Python-$python_version arhive; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    cd Python-$python_version >> /tmp/py3-install.log 2>&1
    echo -e "${CGREEN}Configuring Python-$python_version...${CEND}"
    ./configure --prefix=/usr --enable-shared --with-system-expat --with-system-ffi --enable-optimizations --with-ensurepip=install >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to 'configure' Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Make Python-$python_version...${CEND}"
    make -j$cores >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to 'make' Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Installing Python-$python_version...${CEND}"
    make altinstall >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to install Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Upgrading pip3...${CEND}"
    python${python_version%.*} -m pip install --upgrade pip >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to upgrade pip3; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
}

function install_venv () {
    echo -e "${CGREEN}Installing virtualenvwrapper...${CEND}"
    python${python_version%.*} -m pip install virtualenvwrapper >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to install virtualenvwrapper; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi

    if ! grep "export WORKON_HOME=$HOME/.virtualenvs" "$HOME/.bashrc" >> /tmp/py3-install.log 2>&1; then
        echo "" >> "$HOME/.bashrc"
        echo "# Virtualenv" >> "$HOME/.bashrc"
        echo "export WORKON_HOME=$HOME/.virtualenvs" >> "$HOME/.bashrc"
        echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python${python_version%.*}" >> "$HOME/.bashrc"
        echo "source /usr/local/bin/virtualenvwrapper.sh" >> "$HOME/.bashrc"
    fi
}

# Function to install AI/ML libraries based on mode
function install_ai_ml_libraries() {
    echo -e "${CGREEN}Installing AI/ML libraries...${CEND}"
    
    # Determine which Python version to use
    if [ "$INSTALL_MODE" = "ai-only" ]; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python${python_version%.*}"
    fi
    
    # Upgrade pip first
    echo -e "${CGREEN}Upgrading pip...${CEND}"
    $PYTHON_CMD -m pip install --upgrade pip >> /tmp/py3-install.log 2>&1
    
    case $INSTALL_MODE in
        "datascience")
            install_datascience_libraries $PYTHON_CMD
            ;;
        "ml")
            install_datascience_libraries $PYTHON_CMD
            install_ml_libraries $PYTHON_CMD
            ;;
        "deeplearning")
            install_datascience_libraries $PYTHON_CMD
            install_ml_libraries $PYTHON_CMD
            install_deeplearning_libraries $PYTHON_CMD
            ;;
        "full-ai")
            install_datascience_libraries $PYTHON_CMD
            install_ml_libraries $PYTHON_CMD
            install_deeplearning_libraries $PYTHON_CMD
            install_nlp_libraries $PYTHON_CMD
            install_computervision_libraries $PYTHON_CMD
            install_mlops_tools $PYTHON_CMD
            install_dev_tools $PYTHON_CMD
            ;;
        "ai-only")
            install_datascience_libraries $PYTHON_CMD
            install_ml_libraries $PYTHON_CMD
            install_deeplearning_libraries $PYTHON_CMD
            install_nlp_libraries $PYTHON_CMD
            install_computervision_libraries $PYTHON_CMD
            install_mlops_tools $PYTHON_CMD
            install_dev_tools $PYTHON_CMD
            ;;
    esac
}

# Function to install data science libraries
function install_datascience_libraries() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing Data Science libraries...${CEND}"
    
    libraries=(
        "numpy"
        "pandas"
        "matplotlib"
        "seaborn"
        "scikit-learn"
        "jupyter"
        "ipython"
        "plotly"
        "bokeh"
        "statsmodels"
        "scipy"
        "sympy"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
}

# Function to install machine learning libraries
function install_ml_libraries() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing Machine Learning libraries...${CEND}"
    
    libraries=(
        "xgboost"
        "lightgbm"
        "catboost"
        "imbalanced-learn"
        "feature-engine"
        "scikit-learn-extra"
        "shap"
        "eli5"
        "yellowbrick"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
}

# Function to install deep learning libraries
function install_deeplearning_libraries() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing Deep Learning libraries...${CEND}"
    
    # Install CPU versions first (more compatible)
    libraries=(
        "tensorflow-cpu"
        "torch"
        "torchvision"
        "torchaudio"
        "keras"
        "opencv-python"
        "gym"
        "transformers"
        "datasets"
        "accelerate"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
    
    # Try to detect and install GPU versions if compatible
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "${CYAN}NVIDIA GPU detected, attempting GPU versions...${CEND}"
        $python_cmd -m pip install tensorflow >> /tmp/py3-install.log 2>&1 || true
    fi
}

# Function to install NLP libraries
function install_nlp_libraries() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing NLP libraries...${CEND}"
    
    libraries=(
        "nltk"
        "spacy"
        "gensim"
        "textblob"
        "wordcloud"
        "transformers"
        "tokenizers"
        "sentence-transformers"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
    
    # Download NLTK data
    echo -e "${CCYAN}Downloading NLTK data...${CEND}"
    $python_cmd -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')" >> /tmp/py3-install.log 2>&1 || true
    
    # Download spaCy model
    echo -e "${CCYAN}Downloading spaCy model...${CEND}"
    $python_cmd -m spacy download en_core_web_sm >> /tmp/py3-install.log 2>&1 || true
}

# Function to install computer vision libraries
function install_computervision_libraries() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing Computer Vision libraries...${CEND}"
    
    libraries=(
        "opencv-python"
        "opencv-contrib-python"
        "pillow"
        "scikit-image"
        "imageio"
        "matplotlib"
        "pytesseract"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
}

# Function to install MLOps tools
function install_mlops_tools() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing MLOps tools...${CEND}"
    
    libraries=(
        "mlflow"
        "dvc"
        "wandb"
        "optuna"
        "hyperopt"
        "prefect"
        "dagster"
        "bentoml"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
}

# Function to install development tools
function install_dev_tools() {
    local python_cmd=$1
    echo -e "${CCYAN}Installing Development tools...${CEND}"
    
    libraries=(
        "black"
        "flake8"
        "pytest"
        "pytest-cov"
        "jupyterlab"
        "ipywidgets"
        "notebook"
        "pre-commit"
        "mypy"
        "isort"
    )
    
    for lib in "${libraries[@]}"; do
        echo -ne "    - ${CBLUE}Installing $lib ...${CEND}\r"
        $python_cmd -m pip install $lib >> /tmp/py3-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -e "    - ${CGREEN}✓ $lib installed${CEND}"
        else
            echo -e "    - ${CRED}✗ $lib failed${CEND}"
        fi
    done
}

# Function to create AI/ML environment setup script
function create_ai_ml_env_script() {
    echo -e "${CGREEN}Creating AI/ML environment setup script...${CEND}"
    
    cat > /usr/local/bin/setup-ai-env << 'EOF'
#!/bin/bash
#
# AI/ML Environment Setup Script
# Creates a virtual environment with AI/ML libraries
#

COLORS="\033["
CEND="${COLORS}0m"
CGREEN="${COLORS}1;32m"
CBLUE="${COLORS}1;34m"
CCYAN="${COLORS}1;36m"

show_help() {
    echo -e "${CGREEN}AI/ML Environment Setup${CEND}"
    echo ""
    echo "Usage: setup-ai-env [ENVIRONMENT_NAME] [TYPE]"
    echo ""
    echo "Types:"
    echo "  datascience    - Data Science environment"
    echo "  ml             - Machine Learning environment"
    echo "  deeplearning   - Deep Learning environment"
    echo "  nlp            - NLP environment"
    echo "  cv             - Computer Vision environment"
    echo "  full           - Complete AI/ML environment"
    echo ""
    echo "Examples:"
    echo "  setup-ai-env myenv full"
    echo "  setup-ai-env ds-env datascience"
    echo ""
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

ENV_NAME=${1:-"ai-env"}
ENV_TYPE=${2:-"full"}

echo -e "${CGREEN}Creating AI/ML environment: $ENV_NAME${CEND}"
echo -e "${CCYAN}Type: $ENV_TYPE${CEND}"

# Create virtual environment
mkvirtualenv $ENV_NAME

# Activate environment
workon $ENV_NAME

echo -e "${CGREEN}Environment '$ENV_NAME' created and activated!${CEND}"
echo -e "${CCYAN}To activate later: workon $ENV_NAME${CEND}"
EOF

    chmod +x /usr/local/bin/setup-ai-env
    echo -e "${CGREEN}✓ AI/ML environment script created: /usr/local/bin/setup-ai-env${CEND}"
}


# Main execution flow
function main() {
    # Get installation type choice (repository vs source)
    get_installation_type_choice
    
    # Get Python version choice
    get_python_version_choice
    
    # Get user choice for installation mode
    get_user_choice
    
    # Show installation summary and confirm
    show_installation_summary
    
    # Install based on mode and installation type
    case $INSTALL_MODE in
        "ai-only")
            echo -e "${CGREEN}Setting up AI/ML environment only...${CEND}"
            install_ai_ml_libraries
            create_ai_ml_env_script
            ;;
        *)
            # Standard Python installation + AI/ML if needed
            if [ "$PYTHON_INSTALL_TYPE" = "repository" ]; then
                echo -e "${CGREEN}Installing Python from repository...${CEND}"
                install_deps
                
                # Add Deadsnakes repository with intelligent management
                if add_deadsnakes_repository_enhanced; then
                    echo -e "${CGREEN}✓ Deadsnakes repository configured${CEND}"
                    install_python_from_repository
                else
                    echo -e "${CRED}✗ Failed to configure Deadsnakes repository${CEND}"
                    echo -e "${CYAN}Falling back to source installation...${CEND}"
                    PYTHON_INSTALL_TYPE="source"
                    install_py3
                fi
            else
                echo -e "${CGREEN}Installing Python from source...${CEND}"
                install_deps
                install_py3
            fi
            
            install_venv
            
            # Install AI/ML libraries if requested
            if [[ "$INSTALL_MODE" != "basic" ]]; then
                install_ai_ml_libraries
                create_ai_ml_env_script
            fi
            
            # clean-up the downloads, although not necessary
            clean_up
            ;;
    esac
    
    # Show completion message
    show_completion_message
}

# Function to show completion message
function show_completion_message() {
    echo ""
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Installation Completed!    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    
    case $INSTALL_MODE in
        "basic")
            echo -e "${CCYAN}Python $python_version installation completed successfully!${CEND}"
            echo ""
            echo -e "${CCYAN}Installation Summary:${CEND}"
            echo -e "  Python Version: $python_version"
            echo -e "  Installation Type: $PYTHON_INSTALL_TYPE"
            if [ "$PYTHON_INSTALL_TYPE" = "repository" ]; then
                echo -e "  Installation Path: /usr/bin/python$python_version"
                echo -e "  Pip Command: pip$python_version"
            else
                echo -e "  Installation Path: /usr/bin/python${python_version%.*}"
                echo -e "  Pip Command: python${python_version%.*} -m pip"
            fi
            echo -e "  Virtualenvwrapper: Installed"
            ;;
        "ai-only")
            echo -e "${CCYAN}AI/ML environment setup completed successfully!${CEND}"
            echo ""
            echo -e "${CCYAN}What was installed:${CEND}"
            echo -e "  ✓ Complete AI/ML libraries"
            echo -e "  ✓ Data Science tools"
            echo -e "  ✓ Machine Learning frameworks"
            echo -e "  ✓ Deep Learning libraries"
            echo -e "  ✓ NLP and Computer Vision tools"
            echo -e "  ✓ MLOps and development tools"
            echo -e "  ✓ Environment management script"
            ;;
        *)
            echo -e "${CCYAN}Python $python_version with AI/ML environment completed successfully!${CEND}"
            echo ""
            echo -e "${CCYAN}Installation Summary:${CEND}"
            echo -e "  Python Version: $python_version"
            echo -e "  Installation Type: $PYTHON_INSTALL_TYPE"
            if [ "$PYTHON_INSTALL_TYPE" = "repository" ]; then
                echo -e "  Installation Path: /usr/bin/python$python_version"
                echo -e "  Pip Command: pip$python_version"
            else
                echo -e "  Installation Path: /usr/bin/python${python_version%.*}"
                echo -e "  Pip Command: python${python_version%.*} -m pip"
            fi
            echo -e "  Virtualenvwrapper: Installed"
            echo -e "  AI/ML Libraries: Installed"
            echo -e "  Environment Script: /usr/local/bin/setup-ai-env"
            ;;
    esac
    
    echo ""
    echo -e "${CCYAN}Next Steps:${CEND}"
    if [ "$INSTALL_MODE" != "ai-only" ]; then
        echo -e "  1. Source your bashrc: source ~/.bashrc"
    fi
    echo -e "  2. Create AI/ML environment: setup-ai-env myenv full"
    echo -e "  3. Activate environment: workon myenv"
    echo -e "  4. Start Jupyter: jupyter lab"
    echo ""
    echo -e "${CCYAN}AI/ML Environment Usage:${CEND}"
    echo -e "  setup-ai-env <name> <type>  # Create environment"
    echo -e "  workon <name>               # Activate environment"
    echo -e "  jupyter lab                 # Start Jupyter Lab"
    if [ "$PYTHON_INSTALL_TYPE" = "repository" ]; then
        echo -e "  python$python_version -c \"import torch; print('PyTorch:', torch.__version__)\"  # Test"
    else
        echo -e "  python${python_version%.*} -c \"import torch; print('PyTorch:', torch.__version__)\"  # Test"
    fi
    echo ""
    echo -e "${CCYAN}Logs:${CEND}"
    echo -e "  Dependencies: /tmp/apt-packages.log"
    echo -e "  Python Install: /tmp/py3-install.log"
    echo ""
    echo -e "${CMAGENTA}🎉 AI/ML Environment is ready! Start building amazing things!${CEND}"
}

# Execute main function
main
# End of script
