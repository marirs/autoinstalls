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
    
    # Check for Homebrew
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${CCYAN}Installing Homebrew...${CEND}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >> "$LOG_FILE" 2>&1
    fi
    
    # Install dependencies
    echo -e "${CCYAN}Installing build tools...${CEND}"
    brew install --quiet openssl readline sqlite3 xz zlib >> "$LOG_FILE" 2>&1
    
    # Install cross-compilation tools
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        echo -e "${CCYAN}Installing cross-compilation tools...${CEND}"
        
        # For Linux target compilation
        brew install --quiet filosottile/musl-cross/musl-cross >> "$LOG_FILE" 2>&1 || true
        
        # For Windows target compilation
        brew install --quiet mingw-w64 >> "$LOG_FILE" 2>&1 || true
    fi
    
    echo -e "${CGREEN}macOS dependencies installed successfully${CEND}"
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
        echo -e "${CYAN}Generic Linux installation...${CEND}"
        install_generic_linux_dependencies
    fi
}

function install_debian_dependencies() {
    echo -e "${CCYAN}Installing Debian/Ubuntu dependencies...${CEND}"
    
    # Update package list
    if command -v apt >/dev/null 2>&1; then
        sudo apt update >> "$LOG_FILE" 2>&1
    fi
    
    # Install basic dependencies
    local packages="build-essential pkg-config libssl-dev"
    
    # Add cross-compilation packages
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        packages="$packages gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf"
        packages="$packages mingw-w64"
        
        # Add musl tools for static linking
        packages="$packages musl-tools musl-dev"
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt install -y $packages >> "$LOG_FILE" 2>&1
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y $packages >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${CGREEN}Debian/Ubuntu dependencies installed successfully${CEND}"
}

function install_redhat_dependencies() {
    echo -e "${CCYAN}Installing Red Hat/Fedora dependencies...${CEND}"
    
    # Install basic dependencies
    local packages="gcc gcc-c++ make openssl-devel pkg-config"
    
    # Add cross-compilation packages
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        packages="$packages mingw64-gcc mingw64-gcc-c++"
        packages="$packages gcc-x86_64-linux-gnu gcc-aarch64-linux-gnu"
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y $packages >> "$LOG_FILE" 2>&1
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y $packages >> "$LOG_FILE" 2>&1
    fi
    
    echo -e "${CGREEN}Red Hat/Fedora dependencies installed successfully${CEND}"
}

function install_arch_dependencies() {
    echo -e "${CCYAN}Installing Arch Linux dependencies...${CEND}"
    
    # Install basic dependencies
    local packages="base-devel openssl pkgconf"
    
    # Add cross-compilation packages
    if [ "$INSTALL_CROSS_DEPS" = true ]; then
        packages="$packages mingw-w64-gcc"
        packages="$packages arm-linux-gnueabihf-gcc aarch64-linux-gnu-gcc"
    fi
    
    echo -e "${CCYAN}Installing packages: $packages${CEND}"
    sudo pacman -S --noconfirm $packages >> "$LOG_FILE" 2>&1
    
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
    fi
    
    echo -e "${CGREEN}Windows dependencies installed${CEND}"
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
            "aarch64-unknown-linux-gnu"  # Linux ARM64
            "armv7-unknown-linux-gnueabihf"  # Linux ARM
            "x86_64-unknown-linux-musl"  # Linux MUSL
            "aarch64-unknown-linux-musl" # Linux ARM64 MUSL
            "wasm32-unknown-unknown"     # WebAssembly
            "wasm32-wasi"                # WebAssembly System Interface
        )
        
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

[target.x86_64-unknown-linux-musl]
# Linker for MUSL Linux target
linker = "x86_64-linux-musl-gcc"
ar = "x86_64-linux-musl-ar"

[env]
# Set environment variables for cross-compilation
CC_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-gcc"
CXX_x86_64-pc-windows-gnu = "x86_64-w64-mingw32-g++"

CC_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-gcc"
CXX_aarch64-unknown-linux-gnu = "aarch64-linux-gnu-g++"

CC_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-gcc"
CXX_armv7-unknown-linux-gnueabihf = "arm-linux-gnueabihf-g++"

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
    echo ""
    echo -e "${CCYAN}Cross-Compilation Targets:${CEND}"
    if [ "$INSTALL_ALL_TARGETS" = true ]; then
        echo -e "  ✓ Native target ($PLATFORM)"
        echo -e "  ✓ Windows x64 (x86_64-pc-windows-gnu)"
        echo -e "  ✓ Linux x64 (x86_64-unknown-linux-gnu)"
        echo -e "  ✓ Linux ARM64 (aarch64-unknown-linux-gnu)"
        echo -e "  ✓ macOS x64 (x86_64-apple-darwin)"
        echo -e "  ✓ macOS ARM64 (aarch64-apple-darwin)"
        echo -e "  ✓ WebAssembly (wasm32-unknown-unknown)"
    else
        echo -e "  ✓ Native target ($PLATFORM)"
    fi
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
    echo -e "  Build for macOS: cargo build --target x86_64-apple-darwin"
    echo -e "  Build for WebAssembly: cargo build --target wasm32-unknown-unknown"
    echo ""
    echo -e "${CMAGENTA}Important Notes:${CEND}"
    echo -e "  • Rust is installed for current user only"
    echo -e "  • Source ~/.cargo/env to use Rust in new shells"
    echo -e "  • Cross-compilation requires additional toolchains"
    echo -e "  • Use 'rust-manager check' to validate projects"
    echo -e "  • Regular updates recommended: rustup update"
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/test_rust.rs /tmp/test_rust 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    detect_platform
    check_existing_rust
    
    # Install dependencies
    install_dependencies
    
    # Install Rustup and Rust
    install_rustup
    
    # Install targets
    install_rust_targets
    
    # Configure Cargo
    configure_cargo
    
    # Install useful tools
    install_useful_tools
    
    # Create monitoring scripts
    create_monitoring_scripts
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show success message
    show_success_message
}

# Check if running with appropriate permissions
if [ "$OS" = "linux" ] && [ "$EUID" -ne 0 ]; then
    echo -e "${CYAN}Note: Some dependencies may require sudo access${CEND}"
fi

# Run main function
main
