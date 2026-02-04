#!/bin/bash

# Rust Universal Auto-Installation Script
# Supports macOS, Linux, Windows with x64 and ARM architectures
# Includes cross-compilation dependencies and targets

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

# Rust Configuration
RUST_VERSION="stable"
RUSTUP_VERSION="latest"
INSTALL_ALL_TARGETS=true
INSTALL_CROSS_DEPS=true

# Installation mode (set by menu)
INSTALL_MODE="basic"  # Options: basic, cross-compile, cross-compile-ai

# Cross-compilation choice
LINKING_TYPE="gnu"  # Default to GNU, will be set by user choice

# System Detection
OS=""
ARCH=""
PLATFORM=""

# Logging
LOG_FILE="/tmp/rust-install.log"
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Rust Universal Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}Rust Version: ${RUST_VERSION}${CEND}"
    echo -e "${CCYAN}Platform: ${PLATFORM}${CEND}"
    echo -e "${CCYAN}Architecture: ${ARCH}${CEND}"
    echo ""
}

function detect_platform() {
    echo -e "${CGREEN}Detecting platform and architecture...${CEND}"
    
    # Detect Operating System
    case "$(uname -s)" in
        Darwin*)
            OS="macos"
            echo -e "${CCYAN}Operating System: macOS${CEND}"
            ;;
        Linux*)
            OS="linux"
            echo -e "${CCYAN}Operating System: Linux${CEND}"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            OS="windows"
            echo -e "${CCYAN}Operating System: Windows${CEND}"
            ;;
        *)
            echo -e "${CRED}Unsupported operating system: $(uname -s)${CEND}"
            exit 1
            ;;
    esac
    
    # Detect Architecture
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="x64"
            echo -e "${CCYAN}Architecture: x64${CEND}"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            echo -e "${CCYAN}Architecture: ARM64${CEND}"
            ;;
        armv7l|armv6l)
            ARCH="arm"
            echo -e "${CCYAN}Architecture: ARM${CEND}"
            ;;
        *)
            echo -e "${CRED}Unsupported architecture: $(uname -m)${CEND}"
            exit 1
            ;;
    esac
    
    PLATFORM="${OS}-${ARCH}"
    echo -e "${CGREEN}Platform detected: ${PLATFORM}${CEND}"
}

function show_main_menu() {
    clear
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Rust Universal Installation Menu    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Please choose an option:${CEND}"
    echo "1) Install Rust (basic installation)"
    echo "2) Configure Rust with cross-compilation targets"
    echo "3) Configure Rust with cross-compilation + AI/ML libraries"
    echo "4) Configure Cargo publishing settings"
    echo "5) Exit"
    echo ""
    read -p "Enter your choice [1-5]: " -n 1 -r
    echo
    
    case $REPLY in
        1)
            INSTALL_MODE="basic"
            echo -e "${CCYAN}Selected: Basic Rust installation${CEND}"
            ;;
        2)
            INSTALL_MODE="cross-compile"
            echo -e "${CCYAN}Selected: Cross-compilation configuration${CEND}"
            ;;
        3)
            INSTALL_MODE="cross-compile-ai"
            echo -e "${CCYAN}Selected: Cross-compilation + AI/ML libraries${CEND}"
            ;;
        4)
            INSTALL_MODE="cargo-publish"
            echo -e "${CCYAN}Selected: Cargo publishing configuration${CEND}"
            ;;
        5)
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
            ;;
        *)
            echo -e "${CRED}Invalid choice. Please try again.${CEND}"
            show_main_menu
            ;;
    esac
}

function choose_linking_type() {
    if [ "$INSTALL_MODE" != "basic" ]; then
        echo -e "${CGREEN}Choose cross-compilation linking type:${CEND}"
        echo "1) GNU linking - Standard Linux compatibility, dynamic linking [DEFAULT]"
        echo "2) MUSL linking - Static binaries, better for containers, smaller size"
        read -p "Enter choice [1-2]: " -n 1 -r
        echo
        
        case $REPLY in
            1|"")
                LINKING_TYPE="gnu"
                echo -e "${CCYAN}Selected: GNU linking (standard Linux compatibility)${CEND}"
                ;;
            2)
                LINKING_TYPE="musl"
                echo -e "${CCYAN}Selected: MUSL linking (static binaries)${CEND}"
                ;;
            *)
                echo -e "${CRED}Invalid choice. Using default: GNU linking${CEND}"
                LINKING_TYPE="gnu"
                ;;
        esac
    else
        LINKING_TYPE="gnu"
    fi
}

function check_existing_rust() {
    echo -e "${CGREEN}Checking for existing Rust installation...${CEND}"
    
    if command -v rustc >/dev/null 2>&1; then
        local current_version=$(rustc --version | cut -d' ' -f2)
        echo -e "${CYAN}Rust is already installed: $current_version${CEND}"
        read -p "Do you want to reinstall/update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    else
        echo -e "${CCYAN}Rust is not installed${CEND}"
    fi
}

function create_config_files() {
    echo -e "${CCYAN}Creating configuration files...${CEND}"
    
    # Get the directory where this script is located
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_DIR="$SCRIPT_DIR/config"
    
    # Create Cargo config directory
    mkdir -p "$CARGO_HOME"
    
    # Copy base configuration
    if [ -f "$CONFIG_DIR/base.toml" ]; then
        cat "$CONFIG_DIR/base.toml" > "$CARGO_HOME/config.toml"
        echo -e "${CGREEN}Base configuration copied${CEND}"
    else
        echo -e "${CRED}Base configuration file not found: $CONFIG_DIR/base.toml${CEND}"
        create_base_cargo_config
    fi
    
    # Create mode-specific configurations
    case "$INSTALL_MODE" in
        "basic")
            if [ -f "$CONFIG_DIR/basic.toml" ]; then
                cat "$CONFIG_DIR/basic.toml" >> "$CARGO_HOME/config.toml"
                echo -e "${CGREEN}Basic configuration added${CEND}"
            else
                echo -e "${CRED}Basic configuration file not found: $CONFIG_DIR/basic.toml${CEND}"
                create_basic_config
            fi
            
            # Add macOS universal configuration if on macOS
            if [ "$OS" = "macos" ]; then
                add_macos_config
            fi
            ;;
        "cross-compile")
            if [ -f "$CONFIG_DIR/cross-compile.toml" ]; then
                cat "$CONFIG_DIR/cross-compile.toml" >> "$CARGO_HOME/config.toml"
                echo -e "${CGREEN}Cross-compilation configuration added${CEND}"
            else
                echo -e "${CRED}Cross-compilation configuration file not found: $CONFIG_DIR/cross-compile.toml${CEND}"
                create_cross_compile_config
            fi
            
            # Add MUSL configuration if selected
            if [ "$LINKING_TYPE" = "musl" ]; then
                if [ -f "$CONFIG_DIR/musl.toml" ]; then
                    cat "$CONFIG_DIR/musl.toml" >> "$CARGO_HOME/config.toml"
                    echo -e "${CGREEN}MUSL configuration added${CEND}"
                else
                    echo -e "${CRED}MUSL configuration file not found: $CONFIG_DIR/musl.toml${CEND}"
                    create_musl_config
                fi
            fi
            
            # Add macOS universal configuration if on macOS
            if [ "$OS" = "macos" ]; then
                add_macos_config
            fi
            ;;
        "cross-compile-ai")
            if [ -f "$CONFIG_DIR/cross-compile.toml" ]; then
                cat "$CONFIG_DIR/cross-compile.toml" >> "$CARGO_HOME/config.toml"
                echo -e "${CGREEN}Cross-compilation configuration added${CEND}"
            else
                echo -e "${CRED}Cross-compilation configuration file not found: $CONFIG_DIR/cross-compile.toml${CEND}"
                create_cross_compile_config
            fi
            
            # Add MUSL configuration if selected
            if [ "$LINKING_TYPE" = "musl" ]; then
                if [ -f "$CONFIG_DIR/musl.toml" ]; then
                    cat "$CONFIG_DIR/musl.toml" >> "$CARGO_HOME/config.toml"
                    echo -e "${CGREEN}MUSL configuration added${CEND}"
                else
                    echo -e "${CRED}MUSL configuration file not found: $CONFIG_DIR/musl.toml${CEND}"
                    create_musl_config
                fi
            fi
            
            # Add AI/ML configuration
            if [ -f "$CONFIG_DIR/ai-ml.toml" ]; then
                cat "$CONFIG_DIR/ai-ml.toml" >> "$CARGO_HOME/config.toml"
                echo -e "${CGREEN}AI/ML configuration added${CEND}"
            else
                echo -e "${CRED}AI/ML configuration file not found: $CONFIG_DIR/ai-ml.toml${CEND}"
                create_ai_ml_config
            fi
            
            # Add macOS universal configuration if on macOS
            if [ "$OS" = "macos" ]; then
                add_macos_config
            fi
            ;;
    esac
    
    echo -e "${CGREEN}Configuration files created successfully${CEND}"
    echo -e "${CCYAN}Configuration file location: $CARGO_HOME/config.toml${CEND}"
}

function add_macos_config() {
    echo -e "${CCYAN}Adding macOS universal binary configuration...${CEND}"
    
    # Get the directory where this script is located
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_DIR="$SCRIPT_DIR/config"
    
    # Add macOS universal configuration
    if [ -f "$CONFIG_DIR/macos-universal.toml" ]; then
        cat "$CONFIG_DIR/macos-universal.toml" >> "$CARGO_HOME/config.toml"
        echo -e "${CGREEN}macOS universal configuration added${CEND}"
    else
        echo -e "${CRED}macOS universal configuration file not found: $CONFIG_DIR/macos-universal.toml${CEND}"
        create_macos_universal_config
    fi
}

function create_macos_universal_config() {
    cat >> "$CARGO_HOME/config.toml" << 'EOF'

# macOS Universal Binary Configuration
[target.x86_64-apple-darwin]
# Linker for Intel macOS
linker = "gcc"
ar = "ar"

[target.aarch64-apple-darwin]
# Linker for Apple Silicon macOS
linker = "gcc"
ar = "ar"

[env]
# macOS SDK paths for cross-compilation
SDKROOT_x86_64-apple-darwin = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
SDKROOT_aarch64-apple-darwin = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

# macOS deployment targets
MACOSX_DEPLOYMENT_TARGET_x86_64-apple-darwin = "10.15"
MACOSX_DEPLOYMENT_TARGET_aarch64-apple-darwin = "11.0"

# Homebrew paths for different architectures
HOMEBREW_PREFIX_x86_64-apple-darwin = "/usr/local"
HOMEBREW_PREFIX_aarch64-apple-darwin = "/opt/homebrew"

# Library paths for Intel Homebrew (for cross-compilation on Silicon)
PKG_CONFIG_PATH_x86_64-apple-darwin = "/usr/local/lib/pkgconfig:/usr/local/Homebrew/lib/pkgconfig"
OPENSSL_ROOT_DIR_x86_64-apple-darwin = "/usr/local/opt/openssl"
OPENSSL_DIR_x86_64-apple-darwin = "/usr/local/opt/openssl"

# Library paths for ARM Homebrew (native on Silicon)
PKG_CONFIG_PATH_aarch64-apple-darwin = "/opt/homebrew/lib/pkgconfig"
OPENSSL_ROOT_DIR_aarch64-apple-darwin = "/opt/homebrew/opt/openssl"
OPENSSL_DIR_aarch64-apple-darwin = "/opt/homebrew/opt/openssl"

EOF
}

function create_musl_config() {
    cat >> "$CARGO_HOME/config.toml" << 'EOF'

# MUSL Configuration for static linking
[target.x86_64-unknown-linux-musl]
# Linker for MUSL Linux target
linker = "x86_64-linux-musl-gcc"
ar = "x86_64-linux-musl-ar"

[target.aarch64-unknown-linux-musl]
# Linker for MUSL Linux ARM64 target
linker = "aarch64-linux-musl-gcc"
ar = "aarch64-linux-musl-ar"

[target.armv7-unknown-linux-gnueabihf]
# Linker for MUSL Linux ARM target
linker = "arm-linux-gnueabihf-musl-gcc"
ar = "arm-linux-gnueabihf-musl-ar"

EOF
}

function create_base_cargo_config() {
    cat > "$CARGO_HOME/config.toml" << 'EOF'
[build]
# Enable parallel compilation
jobs = 4

[net]
# Enable offline mode by default
git-fetch-with-cli = true

[registry]
# Use sparse registry for faster downloads
sparse-registry = true

[term]
# Enable colored output
color = 'auto'

[source.crates-io]
replace-with = 'sparse+https://index.crates.io/'

# Sparse registry configuration
[sparse+https://index.crates.io/]
EOF
}

function create_basic_config() {
    cat >> "$CARGO_HOME/config.toml" << 'EOF'

# Basic Rust Configuration
[target.x86_64-unknown-linux-gnu]
linker = "gcc"

[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"

[target.x86_64-apple-darwin]
linker = "gcc"
EOF
}

function create_cross_compile_config() {
    cat >> "$CARGO_HOME/config.toml" << 'EOF'

# Cross-Compilation Configuration
[target.x86_64-pc-windows-gnu]
# Linker for Windows x64 target
linker = "x86_64-w64-mingw32-gcc"
ar = "x86_64-w64-mingw32-ar"

[target.aarch64-unknown-linux-gnu]
# Linker for ARM64 Linux target
linker = "aarch64-linux-gnu-gcc"
ar = "aarch64-linux-gnu-ar"

[target.armv7-unknown-linux-gnueabihf]
# Linker for ARM Linux target
linker = "arm-linux-gnueabihf-gcc"
ar = "arm-linux-gnueabihf-ar"

[env]
# Set environment variables for cross-compilation
CC_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-gcc"
CXX_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-g++"

CC_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-gcc"
CXX_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-g++"

CC_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-gcc"
CXX_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-g++"

# Basic library paths for cross-compilation
PKG_CONFIG_PATH_x86_64-unknown-linux-gnu = "/usr/lib/x86_64-linux-gnu/pkgconfig"
PKG_CONFIG_PATH_aarch64-unknown-linux-gnu = "/usr/lib/aarch64-linux-gnu/pkgconfig"
PKG_CONFIG_PATH_armv7-unknown-linux-gnueabihf = "/usr/lib/arm-linux-gnueabihf/pkgconfig"

OPENSSL_ROOT_DIR_x86_64-unknown-linux-gnu = "/usr"
OPENSSL_ROOT_DIR_aarch64-unknown-linux-gnu = "/usr"
OPENSSL_ROOT_DIR_armv7-unknown-linux-gnueabihf = "/usr"

OPENSSL_DIR_x86_64-unknown-linux-gnu = "/usr"
OPENSSL_DIR_aarch64-unknown-linux-gnu = "/usr"
OPENSSL_DIR_armv7-unknown-linux-gnueabihf = "/usr"

EOF
}

function create_ai_ml_config() {
    cat >> "$CARGO_HOME/config.toml" << 'EOF'

# AI/ML Library Configuration for Cross-Compilation
[target.x86_64-unknown-linux-gnu]
# OpenBLAS configuration
OPENBLAS_ROOT = "/usr"
OPENBLAS_INCLUDE_DIR = "/usr/include/openblas"
OPENBLAS_LIB = "/usr/lib/x86_64-linux-gnu/libopenblas.so"

# HDF5 configuration
HDF5_DIR = "/usr"
HDF5_INCLUDE_DIR = "/usr/include/hdf5/serial"
HDF5_LIB = "/usr/lib/x86_64-linux-gnu/libhdf5.so"

# LightGBM configuration
LIGHTGBM_DIR = "/usr"
LIGHTGBM_INCLUDE_DIR = "/usr/include/LightGBM"
LIGHTGBM_LIB = "/usr/lib/x86_64-linux-gnu/liblightgbm.so"

# Protocol Buffers configuration
PROTOBUF_ROOT = "/usr"
PROTOBUF_INCLUDE_DIR = "/usr/include/google/protobuf"
PROTOBUF_LIB = "/usr/lib/x86_64-linux-gnu/libprotobuf.so"

[target.aarch64-unknown-linux-gnu]
# OpenBLAS configuration for ARM64
OPENBLAS_ROOT = "/usr"
OPENBLAS_INCLUDE_DIR = "/usr/include/openblas"
OPENBLAS_LIB = "/usr/lib/aarch64-linux-gnu/libopenblas.so"

# HDF5 configuration for ARM64
HDF5_DIR = "/usr"
HDF5_INCLUDE_DIR = "/usr/include/hdf5/serial"
HDF5_LIB = "/usr/lib/aarch64-linux-gnu/libhdf5.so"

# LightGBM configuration for ARM64
LIGHTGBM_DIR = "/usr"
LIGHTGBM_INCLUDE_DIR = "/usr/include/LightGBM"
LIGHTGBM_LIB = "/usr/lib/aarch64-linux-gnu/liblightgbm.so"

# Protocol Buffers configuration for ARM64
PROTOBUF_ROOT = "/usr"
PROTOBUF_INCLUDE_DIR = "/usr/include/google/protobuf"
PROTOBUF_LIB = "/usr/lib/aarch64-linux-gnu/libprotobuf.so"

[target.armv7-unknown-linux-gnueabihf]
# OpenBLAS configuration for ARM
OPENBLAS_ROOT = "/usr"
OPENBLAS_INCLUDE_DIR = "/usr/include/openblas"
OPENBLAS_LIB = "/usr/lib/arm-linux-gnueabihf/libopenblas.so"

# HDF5 configuration for ARM
HDF5_DIR = "/usr"
HDF5_INCLUDE_DIR = "/usr/include/hdf5/serial"
HDF5_LIB = "/usr/lib/arm-linux-gnueabihf/libhdf5.so"

# LightGBM configuration for ARM
LIGHTGBM_DIR = "/usr"
LIGHTGBM_INCLUDE_DIR = "/usr/include/LightGBM"
LIGHTGBM_LIB = "/usr/lib/arm-linux-gnueabihf/liblightgbm.so"

# Protocol Buffers configuration for ARM
PROTOBUF_ROOT = "/usr"
PROTOBUF_INCLUDE_DIR = "/usr/include/google/protobuf"
PROTOBUF_LIB = "/usr/lib/arm-linux-gnueabihf/libprotobuf.so"

# AI/ML Environment Variables
OPENBLAS_ROOT_x86_64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_aarch64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_armv7-unknown-linux-gnueabihf = "/usr"

HDF5_DIR_x86_64-unknown-linux-gnu = "/usr"
HDF5_DIR_aarch64-unknown-linux-gnu = "/usr"
HDF5_DIR_armv7-unknown-linux-gnueabihf = "/usr"

LIGHTGBM_DIR_x86_64-unknown-linux-gnu = "/usr"
LIGHTGBM_DIR_aarch64-unknown-linux-gnu = "/usr"
LIGHTGBM_DIR_armv7-unknown-linux-gnueabihf = "/usr"

PROTOBUF_ROOT_x86_64-unknown-linux-gnu = "/usr"
PROTOBUF_ROOT_aarch64-unknown-linux-gnu = "/usr"
PROTOBUF_ROOT_armv7-unknown-linux-gnueabihf = "/usr"

EOF
}

function install_dependencies() {
    echo -e "${CGREEN}Installing dependencies for ${OS}...${CEND}"
    
    case $OS in
        "macos")
            install_macos_dependencies
            ;;
        "linux")
            install_linux_dependencies
            ;;
        "windows")
            install_windows_dependencies
            ;;
    esac
}

function install_macos_dependencies() {
    echo -e "${CCYAN}Installing macOS dependencies...${CEND}"
    
    # Check for Homebrew and handle Silicon vs Intel
    setup_macos_homebrew
    
    # Install dependencies
    echo -e "${CCYAN}Installing build tools...${CEND}"
    "$HOMEBREW_CMD" install --quiet openssl readline sqlite3 xz zlib >> "$LOG_FILE" 2>&1
    
    # Install essential development libraries
    echo -e "${CCYAN}Installing development libraries...${CEND}"
    "$HOMEBREW_CMD" install --quiet cmake ninja >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet libmagic >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet pcre pcre2 >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet libxml2 >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet curl >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet libssh >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet ffmpeg >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet gtk+3 glib >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet freetype fontconfig >> "$LOG_FILE" 2>&1
    "$HOMEBREW_CMD" install --quiet xorg-server >> "$LOG_FILE" 2>&1
    
    # Install compression libraries
    "$HOMEBREW_CMD" install --quiet bzip2 xz lz4 >> "$LOG_FILE" 2>&1
    
    # Install cross-compilation tools for advanced modes
    if [ "$INSTALL_MODE" != "basic" ]; then
        echo -e "${CCYAN}Installing cross-compilation tools...${CEND}"
        
        # Install cross-compilation tools for both architectures
        setup_macos_cross_compilation
        
        # Install AI/ML libraries if needed
        if [ "$INSTALL_MODE" = "cross-compile-ai" ]; then
            echo -e "${CCYAN}Installing AI/ML libraries...${CEND}"
            "$HOMEBREW_CMD" install --quiet openblas lapack >> "$LOG_FILE" 2>&1 || true
            "$HOMEBREW_CMD" install --quiet hdf5 >> "$LOG_FILE" 2>&1 || true
            "$HOMEBREW_CMD" install --quiet protobuf >> "$LOG_FILE" 2>&1 || true
            "$HOMEBREW_CMD" install --quiet grpc >> "$LOG_FILE" 2>&1 || true
            "$HOMEBREW_CMD" install --quiet python >> "$LOG_FILE" 2>&1 || true
        fi
    fi
    
    # Install additional tools
    echo -e "${CCYAN}Installing additional development tools...${CEND}"
    
    # Install YARA
    "$HOMEBREW_CMD" install --quiet yara >> "$LOG_FILE" 2>&1 || true
    
    # Install AI/ML libraries and tools if needed
    if [ "$INSTALL_MODE" = "cross-compile-ai" ]; then
        install_ai_ml_libraries
    fi
    
    echo -e "${CGREEN}macOS dependencies installed successfully${CEND}"
}

function setup_macos_homebrew() {
    echo -e "${CCYAN}Setting up Homebrew for macOS...${CEND}"
    
    # Detect architecture
    local arch=$(uname -m)
    echo -e "${CCYAN}Detected Mac architecture: $arch${CEND}"
    
    if [ "$arch" = "arm64" ]; then
        # Apple Silicon Mac
        HOMEBREW_PREFIX="/opt/homebrew"
        HOMEBREW_CMD="$HOMEBREW_PREFIX/bin/brew"
        
        # Check for Homebrew
        if ! command -v "$HOMEBREW_CMD" >/dev/null 2>&1; then
            echo -e "${CCYAN}Installing Homebrew for Apple Silicon...${CEND}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
        fi
        
        # Setup Intel Homebrew for cross-compilation if needed
        if [ "$INSTALL_MODE" != "basic" ]; then
            setup_intel_homebrew_cross
        fi
        
    else
        # Intel Mac
        HOMEBREW_PREFIX="/usr/local"
        HOMEBREW_CMD="$HOMEBREW_PREFIX/bin/brew"
        
        # Check for Homebrew
        if ! command -v brew >/dev/null 2>&1; then
            echo -e "${CCYAN}Installing Homebrew for Intel Mac...${CEND}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
        fi
        HOMEBREW_CMD="brew"
    fi
    
    echo -e "${CGREEN}Homebrew setup completed: $HOMEBREW_CMD${CEND}"
}

function setup_intel_homebrew_cross() {
    echo -e "${CCYAN}Setting up Intel Homebrew for cross-compilation...${CEND}"
    
    local intel_homebrew="/usr/local/homebrew"
    
    # Check if Intel Homebrew exists
    if [ ! -d "$intel_homebrew" ]; then
        echo -e "${CCYAN}Installing Intel Homebrew for cross-compilation...${CEND}"
        
        # Create directory for Intel Homebrew
        sudo mkdir -p "$intel_homebrew"
        sudo chown -R $(whoami) "$intel_homebrew"
        
        # Install Intel Homebrew
        cd "$intel_homebrew"
        curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$intel_homebrew" >> "$LOG_FILE" 2>&1
        
        # Create Intel Homebrew bin directory
        mkdir -p "$intel_homebrew/bin"
        ln -sf "$intel_homebrew/bin/brew" "$intel_homebrew/bin/brew"
    fi
    
    # Set up environment for Intel Homebrew
    export PATH="$intel_homebrew/bin:$PATH"
    
    echo -e "${CGREEN}Intel Homebrew setup completed${CEND}"
}

function setup_macos_cross_compilation() {
    echo -e "${CCYAN}Setting up macOS cross-compilation...${CEND}"
    
    local arch=$(uname -m)
    
    if [ "$arch" = "arm64" ]; then
        # Apple Silicon: Install tools for Intel cross-compilation
        echo -e "${CCYAN}Setting up Intel cross-compilation on Silicon Mac...${CEND}"
        
        # Install cross-compilation tools via native Homebrew
        "$HOMEBREW_CMD" install --quiet filosottile/musl-cross/musl-cross >> "$LOG_FILE" 2>&1 || true
        
        # Install mingw-w64 for Windows cross-compilation
        "$HOMEBREW_CMD" install --quiet mingw-w64 >> "$LOG_FILE" 2>&1 || true
        
        # Install cross-compilation toolchains for Linux targets
        "$HOMEBREW_CMD" install --quiet x86_64-linux-gnu-gcc >> "$LOG_FILE" 2>&1 || true
        "$HOMEBREW_CMD" install --quiet aarch64-linux-gnu-gcc >> "$LOG_FILE" 2>&1 || true
        
        # Setup universal binary build environment
        setup_universal_binary_env
        
    else
        # Intel Mac: Install tools for ARM cross-compilation
        echo -e "${CCYAN}Setting up ARM cross-compilation on Intel Mac...${CEND}"
        
        # Install cross-compilation tools
        "$HOMEBREW_CMD" install --quiet mingw-w64 >> "$LOG_FILE" 2>&1 || true
        "$HOMEBREW_CMD" install --quiet filosottile/musl-cross/musl-cross >> "$LOG_FILE" 2>&1 || true
        
        # Install ARM cross-compilation tools
        "$HOMEBREW_CMD" install --quiet aarch64-linux-gnu-gcc >> "$LOG_FILE" 2>&1 || true
        "$HOMEBREW_CMD" install --quiet x86_64-linux-gnu-gcc >> "$LOG_FILE" 2>&1 || true
    fi
    
    echo -e "${CGREEN}macOS cross-compilation setup completed${CEND}"
}

function setup_universal_binary_env() {
    echo -e "${CCYAN}Setting up universal binary build environment...${CEND}"
    
    # Create universal binary build script
    cat > "$CARGO_HOME/build-universal.sh" << 'EOF'
#!/bin/bash

# Universal Binary Build Script for macOS
# Usage: ./build-universal.sh <crate-name>

set -e

CRATE_NAME=${1:-"my_app"}
BUILD_DIR="target/universal"

echo "Building universal binary for $CRATE_NAME..."

# Clean previous builds
cargo clean

# Build for ARM64 (Apple Silicon)
echo "Building for ARM64 (Apple Silicon)..."
cargo build --target aarch64-apple-darwin --release

# Build for x86_64 (Intel)
echo "Building for x86_64 (Intel)..."
cargo build --target x86_64-apple-darwin --release

# Create universal binary
echo "Creating universal binary..."
mkdir -p "$BUILD_DIR"
lipo -create \
    target/aarch64-apple-darwin/release/$CRATE_NAME \
    target/x86_64-apple-darwin/release/$CRATE_NAME \
    -output "$BUILD_DIR/$CRATE_NAME-universal"

echo "Universal binary created: $BUILD_DIR/$CRATE_NAME-universal"
echo "File info:"
file "$BUILD_DIR/$CRATE_NAME-universal"
echo "Size:"
ls -lh "$BUILD_DIR/$CRATE_NAME-universal"
EOF

    chmod +x "$CARGO_HOME/build-universal.sh"
    
    echo -e "${CGREEN}Universal binary build script created${CEND}"
}

function install_linux_dependencies() {
    echo -e "${CCYAN}Installing Linux dependencies...${CEND}"
    
    # Detect Linux distribution
    if [ -f /etc/debian_version ]; then
        install_debian_dependencies
    elif [ -f /etc/redhat-release ]; then
        install_redhat_dependencies
    elif [ -f /etc/arch-release ]; then
        install_arch_dependencies
    else
        echo -e "${CRED}Unsupported Linux distribution${CEND}"
        exit 1
    fi
    
    # Install cross-compilation environments for advanced modes
    if [ "$INSTALL_MODE" != "basic" ]; then
        setup_linux_cross_compilation_environments
    fi
    
    echo -e "${CGREEN}Linux dependencies installed successfully${CEND}"
}

function setup_linux_cross_compilation_environments() {
    echo -e "${CCYAN}Setting up cross-compilation environments...${CEND}"
    
    # Setup Windows cross-compilation
    setup_windows_cross_env
    
    # Setup macOS cross-compilation  
    setup_macos_cross_env
    
    # Setup Linux cross-compilation (other architectures)
    setup_linux_cross_env
    
    echo -e "${CGREEN}Cross-compilation environments setup completed${CEND}"
}

function setup_macos_cross_env() {
    echo -e "${CCYAN}Setting up macOS cross-compilation environment...${CEND}"
    
    # Install osxcross for macOS cross-compilation
    setup_osxcross
    
    echo -e "${CGREEN}macOS cross-compilation environment setup completed${CEND}"
}

function setup_osxcross() {
    echo -e "${CCYAN}Installing OSXCross for macOS cross-compilation...${CEND}"
    
    local osxcross_dir="$HOME/osxcross"
    local tarball_name="Xcode-15.3-15E204a-extracted-OSX10.15.tar.xz"
    
    # Create osxcross directory
    mkdir -p "$osxcross_dir"
    cd "$osxcross_dir"
    
    # Check if already installed
    if [ -f "$osxcross_dir/target/bin/o64-clang" ]; then
        echo -e "${CGREEN}OSXCross already installed${CEND}"
        return 0
    fi
    
    # Clone osxcross
    if [ ! -d "$osxcross_dir/osxcross" ]; then
        echo -e "${CCYAN}Cloning OSXCross...${CEND}"
        git clone https://github.com/tpoechtrager/osxcross.git >> "$LOG_FILE" 2>&1 || {
            echo -e "${CRED}Failed to clone OSXCross${CEND}"
            return 1
        }
    fi
    
    cd "$osxcross_dir/osxcross"
    
    # Download macOS SDK (using a reliable mirror)
    echo -e "${CCYAN}Downloading macOS SDK...${CEND}"
    if [ ! -f "tarballs/$tarball_name" ]; then
        mkdir -p tarballs
        # Use GitHub releases for SDK
        curl -L "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/$tarball_name" \
             -o "tarballs/$tarball_name" >> "$LOG_FILE" 2>&1 || {
            echo -e "${CYAN}SDK download failed, trying alternative source...${CEND}"
            # Try alternative source
            curl -L "https://github.com/tpoechtrager/osxcross/releases/download/1.4/$tarball_name" \
                 -o "tarballs/$tarball_name" >> "$LOG_FILE" 2>&1 || {
                echo -e "${CRED}Failed to download macOS SDK${CEND}"
                echo -e "${CYAN}You can manually download and extract the SDK${CEND}"
                return 1
            }
        }
    fi
    
    # Build OSXCross
    echo -e "${CCYAN}Building OSXCross toolchain...${CEND}"
    ./build.sh >> "$LOG_FILE" 2>&1 || {
        echo -e "${CRED}Failed to build OSXCross${CEND}"
        echo -e "${CYAN}Check the log file: $LOG_FILE${CEND}"
        return 1
    }
    
    # Add to PATH
    echo "export PATH=\"$osxcross_dir/target/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "export PATH=\"$osxcross_dir/target/bin:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
    export PATH="$osxcross_dir/target/bin:$PATH"
    
    echo -e "${CGREEN}OSXCross installed successfully${CEND}"
    echo -e "${CCYAN}macOS cross-compilation tools are now available${CEND}"
}

function setup_windows_cross_env() {
    echo -e "${CCYAN}Setting up Windows cross-compilation environment...${CEND}"
    
    # Windows cross-compilation is handled by package managers
    # mingw-w64 is already installed in the distribution-specific functions
    echo -e "${CGREEN}Windows cross-compilation environment ready${CEND}"
}

function setup_linux_cross_env() {
    echo -e "${CCYAN}Setting up Linux cross-compilation environment...${CEND}"
    
    # Linux cross-compilation is handled by package managers
    # gcc cross-compilers are already installed in distribution-specific functions
    echo -e "${CGREEN}Linux cross-compilation environment ready${CEND}"
}

function install_debian_dependencies() {
    echo -e "${CCYAN}Installing Debian/Ubuntu dependencies...${CEND}"
    
    # Update package list
    if command -v apt >/dev/null 2>&1; then
        sudo apt update >> "$LOG_FILE" 2>&1
    fi
    
    # Basic dependencies for all installations
    local packages="build-essential pkg-config libssl-dev"
    
    # Add essential development libraries for all modes
    packages="$packages cmake ninja-build"
    packages="$packages libmagic-dev libmagic1"
    packages="$packages libpcre3-dev libpcre3"
    packages="$packages libxml2-dev libxml2-utils"
    packages="$packages libsqlite3-dev sqlite3"
    packages="$packages zlib1g-dev libbz2-dev"
    packages="$packages liblzma-dev liblz4-dev"
    packages="$packages libcurl4-openssl-dev"
    packages="$packages libssh-dev"
    packages="$packages libavcodec-dev libavformat-dev libavutil-dev"
    packages="$packages libswscale-dev libavfilter-dev"
    packages="$packages libgtk-3-dev"
    packages="$packages libglib2.0-dev"
    packages="$packages libfreetype6-dev"
    packages="$packages libfontconfig1-dev"
    packages="$packages libx11-dev libxext-dev libxrender-dev"
    
    # Add cross-compilation packages for advanced modes
    if [ "$INSTALL_MODE" != "basic" ]; then
        packages="$packages gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf"
        packages="$packages g++-x86-64-linux-gnu g++-aarch64-linux-gnu g++-arm-linux-gnueabihf"
        packages="$packages mingw-w64"
        
        # Add multilib support
        packages="$packages gcc-multilib g++-multilib"
        
        # Add cross-compilation libraries for GNU targets
        packages="$packages libssl-dev:x86_64 libssl-dev:arm64"
        packages="$packages libmagic-dev:x86_64 libmagic-dev:arm64"
        packages="$packages zlib1g-dev:x86_64 zlib1g-dev:arm64"
        packages="$packages libxml2-dev:x86_64 libxml2-dev:arm64"
        packages="$packages libsqlite3-dev:x86_64 libsqlite3-dev:arm64"
        
        # Add MUSL tools if selected
        if [ "$LINKING_TYPE" = "musl" ]; then
            packages="$packages musl-tools musl-dev"
            packages="$packages musl:x86_64 musl:arm64"
            echo -e "${CCYAN}Including MUSL tools for static linking${CEND}"
        else
            echo -e "${CCYAN}Using GNU toolchain for standard Linux compatibility${CEND}"
        fi
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y $packages >> "$LOG_FILE" 2>&1
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y $packages >> "$LOG_FILE" 2>&1
    fi
    
    # Install additional tools that might not be in main repos
    echo -e "${CCYAN}Installing additional development tools...${CEND}"
    
    # Install YARA if available
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y yara libyara-dev >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install regex2 dependencies (PCRE2)
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y libpcre2-dev >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install AI/ML libraries only for AI mode
    if [ "$INSTALL_MODE" = "cross-compile-ai" ]; then
        install_ai_ml_libraries
    fi
    
    echo -e "${CGREEN}Debian/Ubuntu dependencies installed successfully${CEND}"
}

function install_ai_ml_libraries() {
    echo -e "${CCYAN}Installing AI/ML libraries for cross-compilation...${CEND}"
    
    # Install cross-compilation libraries for Rust integration
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        echo -e "${CCYAN}Setting up cross-compilation AI/ML libraries...${CEND}"
        
        # For Debian/Ubuntu - install cross-compilation libraries
        if command -v apt >/dev/null 2>&1; then
            # Install cross-compilation versions of AI/ML libraries
            sudo apt install -y libopenblas-dev:x86_64 libopenblas-dev:arm64 >> "$LOG_FILE" 2>&1 || true
            sudo apt install -y liblapack-dev:x86_64 liblapack-dev:arm64 >> "$LOG_FILE" 2>&1 || true
            sudo apt install -y libhdf5-dev:x86_64 libhdf5-dev:arm64 >> "$LOG_FILE" 2>&1 || true
            sudo apt install -y libprotobuf-dev:x86_64 libprotobuf-dev:arm64 >> "$LOG_FILE" 2>&1 || true
            
            # Install cross-compilation pkg-config files
            sudo apt install -y pkg-config:x86_64 pkg-config:arm64 >> "$LOG_FILE" 2>&1 || true
            
            # Create cross-compilation sysroots with libraries
            setup_cross_compilation_sysroots
        fi
        
        # For Red Hat/Fedora - install cross-compilation libraries
        if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            # Install cross-compilation development packages
            sudo dnf install -y glibc-devel.i686 glibc-devel.x86_64 >> "$LOG_FILE" 2>&1 || true
            sudo dnf install -y libgcc.i686 libgcc.x86_64 >> "$LOG_FILE" 2>&1 || true
            
            # Install cross-compilation tools
            sudo dnf install -y x86_64-linux-gnu-binutils aarch64-linux-gnu-binutils >> "$LOG_FILE" 2>&1 || true
        fi
        
        # For Arch Linux - setup multilib for cross-compilation
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm lib32-gcc-libs lib32-glibc >> "$LOG_FILE" 2>&1 || true
            sudo pacman -S --noconfirm multilib-devel >> "$LOG_FILE" 2>&1 || true
        fi
    fi
    
    # Install Rust ML crates for native development
    if command -v cargo >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing Rust ML crates...${CEND}"
        cargo install --quiet tch >> "$LOG_FILE" 2>&1 || true  # PyTorch bindings
        cargo install --quiet candle-core >> "$LOG_FILE" 2>&1 || true  # Candle ML framework
        cargo install --quiet smartcore >> "$LOG_FILE" 2>&1 || true  # Machine learning library
    fi
    
    # Download and compile LightGBM for cross-compilation
    compile_lightgbm_cross_compile
    
    # Setup ONNX for cross-compilation
    setup_onnx_cross_compile
    
    echo -e "${CGREEN}AI/ML cross-compilation libraries installed successfully${CEND}"
}

function setup_cross_compilation_sysroots() {
    echo -e "${CCYAN}Setting up cross-compilation sysroots...${CEND}"
    
    # Create sysroot directories for cross-compilation
    local sysroot_base="/usr/x86_64-linux-gnu"
    local sysroot_arm="/usr/aarch64-linux-gnu"
    local sysroot_armhf="/usr/arm-linux-gnueabihf"
    
    # Create directories
    sudo mkdir -p "$sysroot_base/lib" "$sysroot_base/usr/lib" "$sysroot_base/usr/include"
    sudo mkdir -p "$sysroot_arm/lib" "$sysroot_arm/usr/lib" "$sysroot_arm/usr/include"
    sudo mkdir -p "$sysroot_armhf/lib" "$sysroot_armhf/usr/lib" "$sysroot_armhf/usr/include"
    
    # Copy essential libraries for cross-compilation
    if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
        sudo cp -r /usr/lib/x86_64-linux-gnu/* "$sysroot_base/lib/" 2>/dev/null || true
    fi
    
    if [ -d "/usr/lib/aarch64-linux-gnu" ]; then
        sudo cp -r /usr/lib/aarch64-linux-gnu/* "$sysroot_arm/lib/" 2>/dev/null || true
    fi
    
    if [ -d "/usr/lib/arm-linux-gnueabihf" ]; then
        sudo cp -r /usr/lib/arm-linux-gnueabihf/* "$sysroot_armhf/lib/" 2>/dev/null || true
    fi
    
    # Copy headers
    if [ -d "/usr/include/x86_64-linux-gnu" ]; then
        sudo cp -r /usr/include/x86_64-linux-gnu/* "$sysroot_base/usr/include/" 2>/dev/null || true
    fi
    
    if [ -d "/usr/include/aarch64-linux-gnu" ]; then
        sudo cp -r /usr/include/aarch64-linux-gnu/* "$sysroot_arm/usr/include/" 2>/dev/null || true
    fi
    
    if [ -d "/usr/include/arm-linux-gnueabihf" ]; then
        sudo cp -r /usr/include/arm-linux-gnueabihf/* "$sysroot_armhf/usr/include/" 2>/dev/null || true
    fi
    
    echo -e "${CGREEN}Cross-compilation sysroots setup completed${CEND}"
}

function compile_lightgbm_cross_compile() {
    echo -e "${CCYAN}Compiling LightGBM for cross-compilation targets...${CEND}"
    
    cd /tmp
    if [ ! -d "LightGBM" ]; then
        git clone --recursive https://github.com/microsoft/LightGBM >> "$LOG_FILE" 2>&1 || true
    fi
    
    if [ -d "LightGBM" ]; then
        cd LightGBM
        
        # Build for native system
        mkdir -p build-native
        cd build-native
        cmake .. >> "$LOG_FILE" 2>&1 || true
        make -j$(nproc) >> "$LOG_FILE" 2>&1 || true
        sudo make install >> "$LOG_FILE" 2>&1 || true
        cd ..
        
        # Build for cross-compilation targets if available
        if [ "$INSTALL_CROSS_DEPS" = true ]; then
            # Build for x86_64-linux-gnu target
            if command -v x86_64-linux-gnu-gcc >/dev/null 2>&1; then
                mkdir -p build-x86_64-cross
                cd build-x86_64-cross
                cmake .. -DCMAKE_C_COMPILER=x86_64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=x86_64-linux-gnu-g++ >> "$LOG_FILE" 2>&1 || true
                make -j$(nproc) >> "$LOG_FILE" 2>&1 || true
                sudo make DESTDIR=/usr/x86_64-linux-gnu install >> "$LOG_FILE" 2>&1 || true
                cd ..
            fi
            
            # Build for aarch64-linux-gnu target
            if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
                mkdir -p build-aarch64-cross
                cd build-aarch64-cross
                cmake .. -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ >> "$LOG_FILE" 2>&1 || true
                make -j$(nproc) >> "$LOG_FILE" 2>&1 || true
                sudo make DESTDIR=/usr/aarch64-linux-gnu install >> "$LOG_FILE" 2>&1 || true
                cd ..
            fi
        fi
        
        cd /tmp
    fi
}

function setup_onnx_cross_compile() {
    echo -e "${CCYAN}Setting up ONNX for cross-compilation...${CEND}"
    
    cd /tmp
    if [ ! -d "onnx" ]; then
        git clone https://github.com/onnx/onnx.git >> "$LOG_FILE" 2>&1 || true
    fi
    
    if [ -d "onnx" ]; then
        cd onnx
        
        # Install ONNX for development
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install --user -e . >> "$LOG_FILE" 2>&1 || true
        fi
        
        # Setup ONNX for cross-compilation
        if [ "$INSTALL_CROSS_DEPS" = true ]; then
            # Create ONNX cross-compilation configuration
            mkdir -p ~/.cargo/onnx-cross
            cat > ~/.cargo/onnx-cross/onnx-cross.toml << 'EOF'
# ONNX Cross-Compilation Configuration
[target.x86_64-unknown-linux-gnu]
onnx-sys = { features = ["static-linking"] }

[target.aarch64-unknown-linux-gnu]
onnx-sys = { features = ["static-linking"] }

[target.armv7-unknown-linux-gnueabihf]
onnx-sys = { features = ["static-linking"] }
EOF
        fi
        
        cd /tmp
    fi
}

function install_redhat_dependencies() {
    echo -e "${CCYAN}Installing Red Hat/Fedora dependencies...${CEND}"
    
    # Install basic dependencies
    local packages="gcc gcc-c++ make openssl-devel pkgconfig"
    
    # Add essential development libraries
    packages="$packages cmake ninja-build"
    packages="$packages file-devel file-libs"
    packages="$packages pcre-devel pcre"
    packages="$packages libxml2-devel libxml2"
    packages="$packages sqlite-devel sqlite"
    packages="$packages zlib-devel bzip2-devel"
    packages="$packages xz-devel lz4-devel"
    packages="$packages libcurl-devel"
    packages="$packages libssh-devel"
    packages="$packages ffmpeg-devel"
    packages="$packages gtk3-devel glib2-devel"
    packages="$packages freetype-devel fontconfig-devel"
    packages="$packages libX11-devel libXext-devel libXrender-devel"
    
    # Add AI/ML libraries
    packages="$packages openblas-devel lapack-devel"
    packages="$packages atlas-devel"
    packages="$packages hdf5-devel"
    packages="$packages protobuf-devel protobuf-compiler"
    packages="$packages grpc-devel"
    packages="$packages python3-devel python3-pip"
    packages="$packages git wget curl"
    
    # Add cross-compilation packages
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        packages="$packages mingw64-gcc mingw64-gcc-c++"
        packages="$packages gcc-x86_64-linux-gnu gcc-aarch64-linux-gnu"
        packages="$packages glibc-devel.i686 glibc-devel.x86_64"
        
        # Add multilib support
        packages="$packages glibc-devel.i686 libgcc.i686"
        
        # Add MUSL tools if selected
        if [ "$LINKING_TYPE" = "musl" ]; then
            packages="$packages musl-tools"
            echo -e "${CCYAN}Including MUSL tools for static linking${CEND}"
        else
            echo -e "${CCYAN}Using GNU toolchain for standard Linux compatibility${CEND}"
        fi
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y $packages >> "$LOG_FILE" 2>&1
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y $packages >> "$LOG_FILE" 2>&1
    fi
    
    # Install additional tools
    echo -e "${CCYAN}Installing additional development tools...${CEND}"
    
    # Install YARA if available
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y yara yara-devel >> "$LOG_FILE" 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y yara yara-devel >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install PCRE2
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y pcre2-devel >> "$LOG_FILE" 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y pcre2-devel >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install AI/ML libraries and tools
    install_ai_ml_libraries
    
    echo -e "${CGREEN}Red Hat/Fedora dependencies installed successfully${CEND}"
}

function install_arch_dependencies() {
    echo -e "${CCYAN}Installing Arch Linux dependencies...${CEND}"
    
    # Install basic dependencies
    local packages="base-devel openssl pkgconf"
    
    # Add essential development libraries
    packages="$packages cmake ninja"
    packages="$packages file"
    packages="$packages pcre"
    packages="$packages libxml2"
    packages="$packages sqlite"
    packages="$packages zlib bzip2"
    packages="$packages xz lz4"
    packages="$packages curl"
    packages="$packages libssh"
    packages="$packages ffmpeg"
    packages="$packages gtk3 glib2"
    packages="$packages freetype2 fontconfig"
    packages="$packages libx11 libxext libxrender"
    
    # Add AI/ML libraries
    packages="$packages openblas lapack"
    packages="$packages atlas"
    packages="$packages hdf5"
    packages="$packages protobuf"
    packages="$packages python"
    packages="$packages git wget"
    
    # Add cross-compilation packages
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        packages="$packages mingw-w64-gcc"
        packages="$packages arm-linux-gnueabihf-gcc aarch64-linux-gnu-gcc"
        packages="$packages lib32-gcc-libs lib32-glibc"
        
        # Add multilib support
        packages="$packages multilib-devel"
        
        # Add MUSL tools if selected
        if [ "$LINKING_TYPE" = "musl" ]; then
            packages="$packages musl"
            echo -e "${CCYAN}Including MUSL tools for static linking${CEND}"
        else
            echo -e "${CCYAN}Using GNU toolchain for standard Linux compatibility${CEND}"
        fi
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    sudo pacman -S --noconfirm $packages >> "$LOG_FILE" 2>&1
    
    # Install additional tools from AUR if needed
    echo -e "${CCYAN}Installing additional development tools...${CEND}"
    
    # Install YARA if available
    if command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm yara >> "$LOG_FILE" 2>&1 || true
    elif command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm yara >> "$LOG_FILE" 2>&1 || true
    fi
    
    # Install PCRE2
    sudo pacman -S --noconfirm pcre2 >> "$LOG_FILE" 2>&1 || true
    
    # Install AI/ML libraries and tools
    install_ai_ml_libraries
    
    echo -e "${CGREEN}Arch Linux dependencies installed successfully${CEND}"
}

function install_generic_linux_dependencies() {
    echo -e "${CCYAN}Installing generic Linux dependencies...${CEND}"
    
    # Try to install common packages
    if command -v apt >/dev/null 2>&1; then
        sudo apt update >> "$LOG_FILE" 2>&1
        sudo apt install -y build-essential libssl-dev pkg-config >> "$LOG_FILE" 2>&1
    elif command -v yum >/dev/null 2>&1; then
        sudo yum groupinstall -y "Development Tools" >> "$LOG_FILE" 2>&1
        sudo yum install -y openssl-devel pkgconfig >> "$LOG_FILE" 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm base-devel openssl pkgconf >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${CGREEN}Generic Linux dependencies installed${CEND}"
}

function install_windows_dependencies() {
    echo -e "${CCYAN}Installing Windows dependencies...${CEND}"
    
    # On Windows, we assume MSYS2/MinGW is already available
    # Install additional tools if needed
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing MSYS2 packages...${CEND}"
        pacman -S --noconfirm mingw-w64-x86_64-toolchain >> "$LOG_FILE" 2>&1 || true
        pacman -S --noconfirm mingw-w64-ucrt-x86_64-toolchain >> "$LOG_FILE" 2>&1 || true
        
        # Install cross-compilation tools for advanced modes
        if [ "$INSTALL_MODE" != "basic" ]; then
            echo -e "${CCYAN}Installing cross-compilation tools...${CEND}"
            
            # Install build dependencies for OSXCross
            pacman -S --noconfirm git wget make patch tar xz >> "$LOG_FILE" 2>&1 || true
            
            # Setup cross-compilation environments
            setup_windows_cross_compilation_environments
        fi
        
        # Install AI/ML libraries if needed
        if [ "$INSTALL_MODE" = "cross-compile-ai" ]; then
            echo -e "${CCYAN}Installing AI/ML libraries...${CEND}"
            pacman -S --noconfirm mingw-w64-x86_64-openblas >> "$LOG_FILE" 2>&1 || true
            pacman -S --noconfirm mingw-w64-x86_64-hdf5 >> "$LOG_FILE" 2>&1 || true
            pacman -S --noconfirm mingw-w64-x86_64-protobuf >> "$LOG_FILE" 2>&1 || true
            
            install_ai_ml_libraries
        fi
    fi
    
    echo -e "${CGREEN}Windows dependencies installed${CEND}"
}

function setup_windows_cross_compilation_environments() {
    echo -e "${CCYAN}Setting up cross-compilation environments on Windows...${CEND}"
    
    # Setup Linux cross-compilation
    setup_linux_cross_env_windows
    
    # Setup macOS cross-compilation  
    setup_macos_cross_env_windows
    
    echo -e "${CGREEN}Windows cross-compilation environments setup completed${CEND}"
}

function setup_macos_cross_env_windows() {
    echo -e "${CCYAN}Setting up macOS cross-compilation environment on Windows...${CEND}"
    
    # Install osxcross for macOS cross-compilation on Windows
    setup_osxcross_windows
    
    echo -e "${CGREEN}macOS cross-compilation environment setup completed on Windows${CEND}"
}

function setup_osxcross_windows() {
    echo -e "${CCYAN}Installing OSXCross for macOS cross-compilation on Windows...${CEND}"
    
    local osxcross_dir="$HOME/osxcross"
    local tarball_name="Xcode-15.3-15E204a-extracted-OSX10.15.tar.xz"
    
    # Create osxcross directory
    mkdir -p "$osxcross_dir"
    cd "$osxcross_dir"
    
    # Check if already installed
    if [ -f "$osxcross_dir/target/bin/o64-clang.exe" ]; then
        echo -e "${CGREEN}OSXCross already installed on Windows${CEND}"
        return 0
    fi
    
    # Clone osxcross
    if [ ! -d "$osxcross_dir/osxcross" ]; then
        echo -e "${CCYAN}Cloning OSXCross...${CEND}"
        git clone https://github.com/tpoechtrager/osxcross.git >> "$LOG_FILE" 2>&1 || {
            echo -e "${CRED}Failed to clone OSXCross${CEND}"
            return 1
        }
    fi
    
    cd "$osxcross_dir/osxcross"
    
    # Download macOS SDK (using a reliable mirror)
    echo -e "${CCYAN}Downloading macOS SDK...${CEND}"
    if [ ! -f "tarballs/$tarball_name" ]; then
        mkdir -p tarballs
        # Use GitHub releases for SDK
        wget --no-check-certificate -L "https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/$tarball_name" \
             -O "tarballs/$tarball_name" >> "$LOG_FILE" 2>&1 || {
            echo -e "${CYAN}SDK download failed, trying alternative source...${CEND}"
            # Try alternative source
            wget --no-check-certificate -L "https://github.com/tpoechtrager/osxcross/releases/download/1.4/$tarball_name" \
                 -O "tarballs/$tarball_name" >> "$LOG_FILE" 2>&1 || {
                echo -e "${CRED}Failed to download macOS SDK${CEND}"
                echo -e "${CYAN}You can manually download and extract the SDK${CEND}"
                return 1
            }
        }
    fi
    
    # Build OSXCross with Windows-specific adjustments
    echo -e "${CCYAN}Building OSXCross toolchain for Windows...${CEND}"
    
    # Set Windows-specific environment variables
    export CC=x86_64-w64-mingw32-gcc
    export CXX=x86_64-w64-mingw32-g++
    
    ./build.sh >> "$LOG_FILE" 2>&1 || {
        echo -e "${CRED}Failed to build OSXCross on Windows${CEND}"
        echo -e "${CYAN}Check the log file: $LOG_FILE${CEND}"
        return 1
    }
    
    # Add to PATH (Windows MSYS2 style)
    echo "export PATH=\"$osxcross_dir/target/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "export PATH=\"$osxcross_dir/target/bin:\$PATH\"" >> "$HOME/.zshrc" 2>/dev/null || true
    export PATH="$osxcross_dir/target/bin:$PATH"
    
    echo -e "${CGREEN}OSXCross installed successfully on Windows${CEND}"
    echo -e "${CCYAN}macOS cross-compilation tools are now available${CEND}"
}

function setup_linux_cross_env_windows() {
    echo -e "${CCYAN}Setting up Linux cross-compilation environment on Windows...${CEND}"
    
    # Linux cross-compilation on Windows is handled by MSYS2 packages
    echo -e "${CGREEN}Linux cross-compilation environment ready on Windows${CEND}"
}

function install_rustup() {
    echo -e "${CGREEN}Installing Rustup...${CEND}"
    
    # Download and run rustup installer
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUST_VERSION >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Rustup${CEND}"
        exit 1
    fi
    
    # Source cargo environment
    source "$CARGO_HOME/env"
    
    echo -e "${CGREEN}Rustup installed successfully${CEND}"
}

function install_rust_targets() {
    echo -e "${CGREEN}Installing Rust targets...${CEND}"
    
    # Source cargo environment
    source "$CARGO_HOME/env"
    
    # Install targets based on host platform
    case $OS in
        "macos")
            install_macos_targets
            ;;
        "linux")
            install_linux_targets
            ;;
        "windows")
            install_windows_targets
            ;;
    esac
    
    echo -e "${CGREEN}Rust targets installed successfully${CEND}"
}

function install_macos_targets() {
    echo -e "${CCYAN}Installing targets for macOS...${CEND}"
    
    # Native target (already installed)
    echo -e "${CCYAN}Native target already installed${CEND}"
    
    if [ "$INSTALL_ALL_TARGETS" = true ]; then
        # Install additional targets
        local targets=(
            "x86_64-pc-windows-gnu"      # Windows x64
            "x86_64-unknown-linux-gnu"   # Linux x64
            "aarch64-unknown-linux-gnu"  # Linux ARM64
            "armv7-unknown-linux-gnueabihf"  # Linux ARM
            "wasm32-unknown-unknown"     # WebAssembly
            "wasm32-wasi"                # WebAssembly System Interface
        )
        
        for target in "${targets[@]}"; do
            echo -e "${CCYAN}Installing target: $target${CEND}"
            rustup target add $target >> "$LOG_FILE" 2>&1 || true
        done
    fi
}

function install_linux_targets() {
    echo -e "${CCYAN}Installing targets for Linux...${CEND}"
    
    # Native target (already installed)
    echo -e "${CCYAN}Native target already installed${CEND}"
    
    if [ "$INSTALL_ALL_TARGETS" = true ]; then
        # Install additional targets
        local targets=(
            "x86_64-pc-windows-gnu"      # Windows x64
            "x86_64-apple-darwin"        # macOS x64
            "aarch64-apple-darwin"       # macOS ARM64
            "aarch64-unknown-linux-gnu"  # Linux ARM64 (GNU)
            "armv7-unknown-linux-gnueabihf"  # Linux ARM (GNU)
            "wasm32-unknown-unknown"     # WebAssembly
            "wasm32-wasi"                # WebAssembly System Interface
        )
        
        # Add MUSL targets if selected
        if [ "$LINKING_TYPE" = "musl" ]; then
            targets+=("x86_64-unknown-linux-musl")      # Linux x64 (MUSL)
            targets+=("aarch64-unknown-linux-musl")     # Linux ARM64 (MUSL)
            echo -e "${CCYAN}Including MUSL targets for static linking${CEND}"
        fi
        
        for target in "${targets[@]}"; do
            echo -e "${CCYAN}Installing target: $target${CEND}"
            rustup target add $target >> "$LOG_FILE" 2>&1 || true
        done
    fi
}

function install_windows_targets() {
    echo -e "${CCYAN}Installing targets for Windows...${CEND}"
    
    # Native target (already installed)
    echo -e "${CCYAN}Native target already installed${CEND}"
    
    if [ "$INSTALL_ALL_TARGETS" = true ]; then
        # Install additional targets
        local targets=(
            "x86_64-pc-windows-msvc"     # Windows MSVC (if not default)
            "x86_64-unknown-linux-gnu"   # Linux x64
            "x86_64-apple-darwin"        # macOS x64
            "aarch64-apple-darwin"       # macOS ARM64
            "aarch64-unknown-linux-gnu"  # Linux ARM64
            "wasm32-unknown-unknown"     # WebAssembly
            "wasm32-wasi"                # WebAssembly System Interface
        )
        
        for target in "${targets[@]}"; do
            echo -e "${CCYAN}Installing target: $target${CEND}"
            rustup target add $target >> "$LOG_FILE" 2>&1 || true
        done
    fi
}

function configure_cargo() {
    echo -e "${CGREEN}Configuring Cargo...${CEND}"
    
    # Create cargo config directory
    mkdir -p "$CARGO_HOME/config"
    
    # Create cargo config file
    cat > "$CARGO_HOME/config.toml" << 'EOF'
[build]
# Enable parallel compilation
jobs = 4

[target.x86_64-pc-windows-gnu]
# Linker for Windows target on Unix systems
linker = "x86_64-w64-mingw32-gcc"
ar = "x86_64-w64-mingw32-ar"

[target.aarch64-unknown-linux-gnu]
# Linker for ARM64 Linux target
linker = "aarch64-linux-gnu-gcc"
ar = "aarch64-linux-gnu-ar"

[target.armv7-unknown-linux-gnueabihf]
# Linker for ARM Linux target
linker = "arm-linux-gnueabihf-gcc"
ar = "arm-linux-gnueabihf-ar"

EOF

    # Add MUSL configuration if selected
    if [ "$LINKING_TYPE" = "musl" ]; then
        cat >> "$CARGO_HOME/config.toml" << EOF

[target.x86_64-unknown-linux-musl]
# Linker for MUSL Linux target
linker = "x86_64-linux-musl-gcc"
ar = "x86_64-linux-musl-ar"

[target.aarch64-unknown-linux-musl]
# Linker for MUSL Linux ARM64 target
linker = "aarch64-linux-musl-gcc"
ar = "aarch64-linux-musl-ar"

EOF
        echo -e "${CCYAN}Added MUSL configuration to Cargo${CEND}"
    fi
    
    # Add AI/ML library paths for cross-compilation
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        cat >> "$CARGO_HOME/config.toml" << EOF

# AI/ML Library Configuration for Cross-Compilation
[target.x86_64-unknown-linux-gnu]
# OpenBLAS configuration
openblas-static = { lib = "openblas", path = "/usr/lib/x86_64-linux-gnu" }
# HDF5 configuration
hdf5-static = { lib = "hdf5", path = "/usr/lib/x86_64-linux-gnu" }
# LightGBM configuration
lightgbm-static = { lib = "lightgbm", path = "/usr/lib/x86_64-linux-gnu" }

[target.aarch64-unknown-linux-gnu]
# OpenBLAS configuration for ARM64
openblas-static = { lib = "openblas", path = "/usr/lib/aarch64-linux-gnu" }
# HDF5 configuration for ARM64
hdf5-static = { lib = "hdf5", path = "/usr/lib/aarch64-linux-gnu" }
# LightGBM configuration for ARM64
lightgbm-static = { lib = "lightgbm", path = "/usr/lib/aarch64-linux-gnu" }

[target.armv7-unknown-linux-gnueabihf]
# OpenBLAS configuration for ARM
openblas-static = { lib = "openblas", path = "/usr/lib/arm-linux-gnueabihf" }
# HDF5 configuration for ARM
hdf5-static = { lib = "hdf5", path = "/usr/lib/arm-linux-gnueabihf" }
# LightGBM configuration for ARM
lightgbm-static = { lib = "lightgbm", path = "/usr/lib/arm-linux-gnueabihf" }

EOF
        echo -e "${CCYAN}Added AI/ML library paths to Cargo configuration${CEND}"
    fi
    
    cat >> "$CARGO_HOME/config.toml" << EOF

[env]
# Set environment variables for cross-compilation
CC_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-gcc"
CXX_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-g++"

CC_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-gcc"
CXX_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-g++"

CC_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-gcc"
CXX_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-g++"

# AI/ML Library Environment Variables
OPENBLAS_ROOT_x86_64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_aarch64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_armv7-unknown-linux-gnueabihf = "/usr"

HDF5_DIR_x86_64-unknown-linux-gnu = "/usr"
HDF5_DIR_aarch64-unknown-linux-gnu = "/usr"
HDF5_DIR_armv7-unknown-linux-gnueabihf = "/usr"

LIGHTGBM_DIR_x86_64-unknown-linux-gnu = "/usr"
LIGHTGBM_DIR_aarch64-unknown-linux-gnu = "/usr"
LIGHTGBM_DIR_armv7-unknown-linux-gnueabihf = "/usr"

PKG_CONFIG_PATH_x86_64-unknown-linux-gnu = "/usr/lib/x86_64-linux-gnu/pkgconfig"
PKG_CONFIG_PATH_aarch64-unknown-linux-gnu = "/usr/lib/aarch64-linux-gnu/pkgconfig"
PKG_CONFIG_PATH_armv7-unknown-linux-gnueabihf = "/usr/lib/arm-linux-gnueabihf/pkgconfig"

[net]
# Enable offline mode by default
git-fetch-with-cli = true

[registry]
# Use sparse registry for faster downloads
sparse-registry = true
EOF
    
    echo -e "${CGREEN}Cargo configured successfully${CEND}"
}

function install_useful_tools() {
    echo -e "${CGREEN}Installing useful Rust tools...${CEND}"
    
    # Source cargo environment
    source "$CARGO_HOME/env"
    
    # Install useful cargo extensions
    local tools=(
        "cargo-edit"      # For managing dependencies
        "cargo-watch"     # For auto-reloading during development
        "cargo-audit"     # For security auditing
        "cargo-outdated"  # For checking outdated dependencies
        "cargo-expand"    # For macro expansion
        "cargo-tree"      # For dependency tree visualization
        "rustfmt"         # For code formatting
        "clippy"          # For linting
    )
    
    for tool in "${tools[@]}"; do
        echo -e "${CCYAN}Installing $tool...${CEND}"
        cargo install $tool >> "$LOG_FILE" 2>&1 || true
    done
    
    echo -e "${CGREEN}Useful tools installed successfully${CEND}"
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create Rust monitoring script
    cat > /usr/local/bin/rust-monitor << 'EOF'
#!/bin/bash

# Rust Monitoring Script

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
    echo -e "${CBLUE}    Rust Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function show_version() {
    echo -e "${CGREEN}Rust Version Information:${CEND}"
    
    if command -v rustc >/dev/null 2>&1; then
        echo -e "  rustc: $(rustc --version)"
    else
        echo -e "  ${CRED}rustc: Not installed${CEND}"
    fi
    
    if command -v cargo >/dev/null 2>&1; then
        echo -e "  cargo: $(cargo --version)"
    else
        echo -e "  ${CRED}cargo: Not installed${CEND}"
    fi
    
    if command -v rustup >/dev/null 2>&1; then
        echo -e "  rustup: $(rustup --version)"
    else
        echo -e "  ${CRED}rustup: Not installed${CEND}"
    fi
    
    echo ""
}

function show_targets() {
    echo -e "${CGREEN}Installed Targets:${CEND}"
    
    if command -v rustup >/dev/null 2>&1; then
        rustup target list --installed
    else
        echo -e "  ${CRED}rustup not available${CEND}"
    fi
    
    echo ""
}

function show_tools() {
    echo -e "${CGREEN}Installed Tools:${CEND}"
    
    if command -v cargo >/dev/null 2>&1; then
        echo -e "  Cargo extensions:"
        cargo install --list | grep -E "^[a-z]" | head -20
    else
        echo -e "  ${CRED}cargo not available${CEND}"
    fi
    
    echo ""
}

function show_environment() {
    echo -e "${CGREEN}Environment Variables:${CEND}"
    
    echo -e "  RUSTUP_HOME: ${RUSTUP_HOME:-not set}"
    echo -e "  CARGO_HOME: ${CARGO_HOME:-not set}"
    echo -e "  PATH: ${PATH}"
    
    echo ""
}

function main() {
    case "${1:-all}" in
        "version")
            show_header
            show_version
            ;;
        "targets")
            show_header
            show_targets
            ;;
        "tools")
            show_header
            show_tools
            ;;
        "environment")
            show_header
            show_environment
            ;;
        "all")
            show_header
            show_version
            show_targets
            show_tools
            show_environment
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [version|targets|tools|environment|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Create Rust management script
    cat > /usr/local/bin/rust-manager << 'EOF'
#!/bin/bash

# Rust Management Script

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
    echo -e "${CBLUE}    Rust Manager${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function update_rust() {
    echo -e "${CGREEN}Updating Rust...${CEND}"
    
    if command -v rustup >/dev/null 2>&1; then
        rustup update
    else
        echo -e "${CRED}rustup not available${CEND}"
        exit 1
    fi
}

function install_target() {
    local target=$1
    if [ -z "$target" ]; then
        echo -e "${CRED}Please specify a target${CEND}"
        echo "Usage: $0 install-target <target>"
        exit 1
    fi
    
    echo -e "${CGREEN}Installing target: $target${CEND}"
    
    if command -v rustup >/dev/null 2>&1; then
        rustup target add $target
    else
        echo -e "${CRED}rustup not available${CEND}"
        exit 1
    fi
}

function list_targets() {
    echo -e "${CGREEN}Available Targets:${CEND}"
    
    if command -v rustup >/dev/null 2>&1; then
        rustup target list
    else
        echo -e "${CRED}rustup not available${CEND}"
    fi
}

function install_tool() {
    local tool=$1
    if [ -z "$tool" ]; then
        echo -e "${CRED}Please specify a tool${CEND}"
        echo "Usage: $0 install-tool <tool>"
        exit 1
    fi
    
    echo -e "${CGREEN}Installing tool: $tool${CEND}"
    
    if command -v cargo >/dev/null 2>&1; then
        cargo install $tool
    else
        echo -e "${CRED}cargo not available${CEND}"
        exit 1
    fi
}

function check_project() {
    echo -e "${CGREEN}Checking Rust project...${CEND}"
    
    if [ ! -f "Cargo.toml" ]; then
        echo -e "${CRED}No Cargo.toml found in current directory${CEND}"
        exit 1
    fi
    
    echo -e "${CCYAN}Running cargo check...${CEND}"
    cargo check
    
    echo -e "${CCYAN}Running cargo clippy...${CEND}"
    cargo clippy -- -D warnings
    
    echo -e "${CCYAN}Running cargo fmt --check...${CEND}"
    cargo fmt -- --check
    
    echo -e "${CCYAN}Running cargo test...${CEND}"
    cargo test
    
    echo -e "${CGREEN}Project check completed${CEND}"
}

function main() {
    case "${1:-help}" in
        "update")
            show_header
            update_rust
            ;;
        "install-target")
            show_header
            install_target "$2"
            ;;
        "list-targets")
            show_header
            list_targets
            ;;
        "install-tool")
            show_header
            install_tool "$2"
            ;;
        "check")
            show_header
            check_project
            ;;
        "help"|*)
            show_header
            echo -e "${CCYAN}Available commands:${CEND}"
            echo -e "  update          - Update Rust toolchain"
            echo -e "  install-target  - Install a specific target"
            echo -e "  list-targets    - List all available targets"
            echo -e "  install-tool    - Install a cargo tool"
            echo -e "  check           - Check current Rust project"
            echo ""
            ;;
    esac
}

main "$@"
EOF
    
    # Make scripts executable
    chmod +x /usr/local/bin/rust-monitor
    chmod +x /usr/local/bin/rust-manager
    
    echo -e "${CGREEN}Monitoring and management scripts created${CEND}"
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Rust installation...${CEND}"
    
    # Source cargo environment
    source "$CARGO_HOME/env"
    
    # Test rustc installation
    if command -v rustc >/dev/null 2>&1; then
        local rust_version=$(rustc --version)
        echo -e "${CGREEN}rustc installation: OK ($rust_version)${CEND}"
    else
        echo -e "${CRED}rustc installation: FAILED${CEND}"
        exit 1
    fi
    
    # Test cargo installation
    if command -v cargo >/dev/null 2>&1; then
        local cargo_version=$(cargo --version)
        echo -e "${CGREEN}cargo installation: OK ($cargo_version)${CEND}"
    else
        echo -e "${CRED}cargo installation: FAILED${CEND}"
        exit 1
    fi
    
    # Test rustup installation
    if command -v rustup >/dev/null 2>&1; then
        local rustup_version=$(rustup --version)
        echo -e "${CGREEN}rustup installation: OK ($rustup_version)${CEND}"
    else
        echo -e "${CRED}rustup installation: FAILED${CEND}"
        exit 1
    fi
    
    # Test basic Rust compilation
    echo 'fn main() { println!("Hello, Rust!"); }' > /tmp/test_rust.rs
    if rustc /tmp/test_rust.rs -o /tmp/test_rust 2>/dev/null; then
        if /tmp/test_rust >/dev/null 2>&1; then
            echo -e "${CGREEN}Rust compilation: OK${CEND}"
        else
            echo -e "${CRED}Rust compilation: FAILED${CEND}"
            exit 1
        fi
    else
        echo -e "${CRED}Rust compilation: FAILED${CEND}"
        exit 1
    fi
    rm -f /tmp/test_rust.rs /tmp/test_rust
    
    echo -e "${CGREEN}Rust installation verified successfully${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Rust Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Platform: $PLATFORM"
    echo -e "  Rust Version: $(rustc --version | cut -d' ' -f2)"
    echo -e "  Installation Path: $CARGO_HOME"
    echo ""
    echo -e "${CCYAN}Components Installed:${CEND}"
    echo -e "  ✓ rustc - Rust compiler"
    echo -e "  ✓ cargo - Package manager and build tool"
    echo -e "  ✓ rustup - Rust toolchain manager"
    echo -e "  ✓ rustfmt - Code formatter"
    echo -e "  ✓ clippy - Linting tool"
    echo -e "  ✓ Cross-compilation targets"
    echo -e "  ✓ Useful cargo extensions"
    echo -e "  ✓ Essential development libraries"
    echo -e "  ✓ OpenSSL, libmagic, PCRE/PCRE2"
    echo -e "  ✓ SQLite, XML, compression libraries"
    echo -e "  ✓ Multimedia libraries (FFmpeg)"
    echo -e "  ✓ GUI libraries (GTK, X11)"
    echo -e "  ✓ YARA malware analysis tools"
    echo -e "  ✓ CMake and Ninja build systems"
    echo -e "  ✓ AI/ML libraries for cross-compilation (LightGBM, ONNX)"
    echo -e "  ✓ Linear algebra libraries (OpenBLAS, LAPACK) for all targets"
    echo -e "  ✓ Data serialization (Protocol Buffers, gRPC) for all targets"
    echo -e "  ✓ Cross-compilation sysroots with library paths"
    echo -e "  ✓ Cargo configuration for automatic library detection"
    echo ""
    echo -e "${CCYAN}Cross-Compilation Targets:${CEND}"
    if [ "$INSTALL_ALL_TARGETS" = true ]; then
        echo -e "  ✓ Native target ($PLATFORM)"
        echo -e "  ✓ Windows x64 (x86_64-pc-windows-gnu)"
        echo -e "  ✓ Linux x64 (x86_64-unknown-linux-gnu)"
        echo -e "  ✓ Linux ARM64 (aarch64-unknown-linux-gnu) - GNU"
        echo -e "  ✓ Linux ARM (armv7-unknown-linux-gnueabihf) - GNU"
        echo -e "  ✓ macOS x64 (x86_64-apple-darwin)"
        echo -e "  ✓ macOS ARM64 (aarch64-apple-darwin)"
        echo -e "  ✓ WebAssembly (wasm32-unknown-unknown)"
        
        if [ "$LINKING_TYPE" = "musl" ]; then
            echo -e "  ✓ Linux x64 MUSL (x86_64-unknown-linux-musl) - Static linking"
            echo -e "  ✓ Linux ARM64 MUSL (aarch64-unknown-linux-musl) - Static linking"
        fi
    else
        echo -e "  ✓ Native target ($PLATFORM)"
    fi
    
    echo ""
    echo -e "${CCYAN}Linking Type: ${LINKING_TYPE^^}${CEND}"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Check versions: rustc --version && cargo --version"
    echo -e "  Update Rust: rustup update"
    echo -e "  List targets: rustup target list --installed"
    echo -e "  Add target: rustup target add <target>"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  Rust status: rust-monitor"
    echo -e "  Manage tools: rust-manager"
    echo ""
    echo -e "${CCYAN}Quick Start:${CEND}"
    echo -e "  Create project: cargo new myproject"
    echo -e "  Build project: cargo build"
    echo -e "  Run project: cargo run"
    echo -e "  Test project: cargo test"
    echo ""
    echo -e "${CCYAN}Cross-Compilation Examples:${CEND}"
    echo -e "  Build for Windows: cargo build --target x86_64-pc-windows-gnu"
    echo -e "  Build for Linux: cargo build --target x86_64-unknown-linux-gnu"
    echo -e "  Build for Linux ARM64: cargo build --target aarch64-unknown-linux-gnu"
    echo -e "  Build for macOS: cargo build --target x86_64-apple-darwin"
    echo -e "  Build for WebAssembly: cargo build --target wasm32-unknown-unknown"
    
    if [ "$LINKING_TYPE" = "musl" ]; then
        echo -e "  Build static Linux binary: cargo build --target x86_64-unknown-linux-musl --release"
        echo -e "  Build static Linux ARM64: cargo build --target aarch64-unknown-linux-musl --release"
    fi
    
    echo ""
    echo -e "${CCYAN}AI/ML Cross-Compilation Examples:${CEND}"
    echo -e "  Build ML project for Linux ARM64: cargo build --target aarch64-unknown-linux-gnu --release"
    echo -e "  Build with OpenBLAS for Linux: cargo build --target x86_64-unknown-linux-gnu --features openblas"
    echo -e "  Build with LightGBM for ARM: cargo build --target armv7-unknown-linux-gnueabihf --features lightgbm"
    echo -e "  Build with ONNX for all targets: cargo build --target x86_64-unknown-linux-gnu --features onnx"
    echo ""
    echo -e "${CMAGENTA}Important Notes:${CEND}"
    echo -e "  • Rust is installed for current user only"
    echo -e "  • Source ~/.cargo/env to use Rust in new shells"
    echo -e "  • Cross-compilation requires additional toolchains"
    echo -e "  • Use 'rust-manager check' to validate projects"
    echo -e "  • Regular updates recommended: rustup update"
    echo ""
}

function configure_cargo_publishing() {
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    Cargo Publishing Configuration    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    
    # Check if Cargo is installed
    if ! command -v cargo >/dev/null 2>&1; then
        echo -e "${CRED}Cargo is not installed. Please install Rust first.${CEND}"
        echo -e "${CCYAN}Run the script again and choose option 1, 2, or 3 to install Rust first.${CEND}"
        exit 1
    fi
    
    echo -e "${CCYAN}Cargo publishing configuration allows you to:${CEND}"
    echo "• Publish crates to crates.io"
    "• Login to cargo registry"
    "• Configure publishing settings"
    echo ""
    
    read -p "Do you want to configure Cargo publishing? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Cargo publishing configuration skipped${CEND}"
        exit 0
    fi
    
    echo -e "${CCYAN}Configuring Cargo publishing...${CEND}"
    echo ""
    
    # Get cargo registry token
    echo -e "${CYAN}To publish crates to crates.io, you need an API token.${CEND}"
    echo -e "${CYAN}You can get one from: https://crates.io/me${CEND}"
    echo ""
    
    while true; do
        read -p "Enter your crates.io API token (or press Enter to skip): " -s cargo_token
        echo
        
        if [ -z "$cargo_token" ]; then
            echo -e "${CYAN}No token provided. You can configure it later with 'cargo login'.${CEND}"
            break
        fi
        
        # Validate token format (basic check)
        if [[ ${#cargo_token} -ge 32 ]]; then
            echo -e "${CCYAN}Configuring cargo login...${CEND}"
            
            # Use cargo login to configure the token
            echo "$cargo_token" | cargo login >> "$LOG_FILE" 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "${CGREEN}✓ Cargo login successful${CEND}"
                cargo_token_configured=true
                break
            else
                echo -e "${CRED}✗ Failed to configure cargo login. Please check your token.${CEND}"
                read -p "Try again? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    break
                fi
            fi
        else
            echo -e "${CRED}Token appears to be too short. Please check your API token.${CEND}"
            read -p "Try again? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                break
            fi
        fi
    done
    
    echo ""
    echo -e "${CCYAN}Configuring publishing settings...${CEND}"
    
    # Create cargo config directory
    mkdir -p "$CARGO_HOME"
    
    # Create or update cargo config with publishing settings
    create_cargo_publish_config
    
    # Test the configuration
    if [ "$cargo_token_configured" = true ]; then
        echo -e "${CCYAN}Testing cargo configuration...${CEND}"
        
        # Try to verify the login
        if cargo search --limit 1 cargo >> "$LOG_FILE" 2>&1; then
            echo -e "${CGREEN}✓ Cargo configuration verified successfully${CEND}"
        else
            echo -e "${CYAN}⚠ Cargo configuration completed, but verification failed${CEND}"
            echo -e "${CYAN}  This might be due to network issues or registry problems${CEND}"
        fi
    fi
    
    # Show next steps
    show_cargo_publish_next_steps
    
    echo ""
    echo -e "${CGREEN}Cargo publishing configuration completed!${CEND}"
}

function create_cargo_publish_config() {
    echo -e "${CCYAN}Creating cargo publishing configuration...${CEND}"
    
    # Get the directory where this script is located
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local CONFIG_DIR="$SCRIPT_DIR/config"
    
    # Add publishing configuration to existing config or create new one
    local config_file="$CARGO_HOME/config.toml"
    local credentials_file="$CARGO_HOME/credentials.toml"
    
    # Backup existing config if it exists
    if [ -f "$config_file" ]; then
        cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CCYAN}Backed up existing config.toml${CEND}"
    fi
    
    # Backup existing credentials if they exist
    if [ -f "$credentials_file" ]; then
        cp "$credentials_file" "$credentials_file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${CCYAN}Backed up existing credentials.toml${CEND}"
    fi
    
    # Add publishing configuration to main config (without credentials)
    cat >> "$config_file" << 'EOF'

# Cargo Publishing Configuration
[registry]
# Default registry for publishing
default = "crates-io"

[http]
# HTTP settings for cargo registry
timeout = 30
check-revoke = false

[net]
# Network settings for publishing
retry = 3
git-fetch-with-cli = true

[registry.crates-io]
# crates.io registry configuration
protocol = "https"
registry = "https://github.com/rust-lang/crates.io-index"

[publish]
# Publishing behavior settings
registry = "crates-io"
allow-dirty = false
verify = true

EOF
    
    # Create credentials file with proper structure
    cat > "$credentials_file" << 'EOF'

# Cargo Credentials File
# This file contains authentication tokens for cargo registries
# WARNING: This file contains sensitive information - keep it secure!

[registry]
# crates.io authentication token
# This will be automatically configured when you run 'cargo login'
# or use the Rust installation script's publishing configuration

EOF
    
    # If we have a publish config template, add additional settings
    if [ -f "$CONFIG_DIR/cargo-publish.toml" ]; then
        # Extract only non-credential settings from the template
        grep -v "token" "$CONFIG_DIR/cargo-publish.toml" | grep -v "credentials" >> "$config_file"
        echo -e "${CGREEN}Added publishing configuration from template${CEND}"
    fi
    
    echo -e "${CGREEN}Publishing configuration added to $config_file${CEND}"
    echo -e "${CGREEN}Credentials file created at $credentials_file${CEND}"
    echo -e "${CYAN}Note: Token will be securely stored by 'cargo login' command${CEND}"
}

function show_cargo_publish_next_steps() {
    echo ""
    echo -e "${CCYAN}========================================${CEND}"
    echo -e "${CCYAN}    Next Steps for Publishing    ${CEND}"
    echo -e "${CCYAN}========================================${CEND}"
    echo ""
    echo -e "${CGREEN}To publish your crate:${CEND}"
    echo "1. Navigate to your crate directory: cd your_crate"
    echo "2. Check your crate: cargo check"
    echo "3. Run tests: cargo test"
    echo "4. Publish: cargo publish"
    echo ""
    echo -e "${CGREEN}Useful cargo commands:${CEND}"
    echo "• cargo login --help    # Show login help"
    echo "• cargo logout          # Logout from registry"
    echo "• cargo owner           # Manage crate owners"
    echo "• cargo publish --dry-run # Test publishing without actually publishing"
    echo "• cargo publish --allow-dirty # Publish with uncommitted changes"
    echo ""
    echo -e "${CGREEN}Configuration files:${CEND}"
    echo "• Cargo config: $CARGO_HOME/config.toml"
    echo "• Credentials: $CARGO_HOME/credentials.toml"
    echo ""
    echo -e "${CYAN}Credentials file structure:${CEND}"
    echo "The credentials.toml file should contain:"
    echo "[registry]"
    echo 'token = "your_api_token_here"'
    echo ""
    echo -e "${CYAN}Note:${CEND}"
    echo "• The 'cargo login' command automatically creates/updates credentials.toml"
    echo "• Never share your credentials.toml file"
    echo "• Add credentials.toml to your .gitignore file"
    echo "• The script backs up existing credentials before making changes"
    echo ""
    echo -e "${CYAN}For more information, visit: https://doc.rust-lang.org/cargo/reference/publishing.html${CEND}"
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/test_rust.rs /tmp/test_rust 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    show_main_menu
    
    # Handle cargo publish mode separately
    if [ "$INSTALL_MODE" = "cargo-publish" ]; then
        configure_cargo_publishing
        exit 0
    fi
    
    detect_platform
    check_existing_rust
    
    # Choose linking type
    choose_linking_type
    
    # Create configuration files first
    create_config_files
    
    # Install dependencies
    install_dependencies
    
    # Install Rustup and Rust
    install_rustup
    
    # Install targets based on mode
    if [ "$INSTALL_MODE" != "basic" ]; then
        install_rust_targets
    fi
    
    # Configure Cargo
    configure_cargo
    
    # Install useful tools
    install_useful_tools
    
    # Create management scripts
    create_management_scripts
    
    # Verify installation
    verify_installation
    
    # Show success message
    show_success_message
}

# Check if running with appropriate permissions
if [ "$OS" = "linux" ] && [ "$EUID" -ne 0 ]; then
    echo -e "${CYAN}Note: Some dependencies may require sudo access${CEND}"
fi

# Run main function
main
