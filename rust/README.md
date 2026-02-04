# Rust Universal Auto-Installation Script
![https://img.shields.io/badge/rust-stable-orange](https://img.shields.io/badge/rust-stable-orange)
![https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue](https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green)
![https://img.shields.io/badge/cross%20compilation-universal-purple](https://img.shields.io/badge/cross%20compilation-universal-purple)
![https://img.shields.io/badge/ai%20ml-ready-blue](https://img.shields.io/badge/ai%20ml-ready-blue)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

## Overview

This universal Rust installation script supports multiple operating systems (macOS, Linux, Windows) and architectures (x64, ARM64, ARM) with comprehensive cross-compilation capabilities. It automatically detects the platform, installs appropriate dependencies, and sets up a complete Rust development environment with cross-compilation targets.

## Quick Start

```bash
# Navigate to the Rust directory
cd rust/

# Run the universal installation script
./rust-install.sh

# Choose linking type when prompted:
# 1) GNU linking - Standard Linux compatibility, dynamic linking [DEFAULT]
# 2) MUSL linking - Static binaries, better for containers, smaller size

# Source Rust environment (for new shells)
source ~/.cargo/env
```

## 🌍 Platform Support

### ✅ Operating Systems
- **macOS** (Intel and Apple Silicon)
- **Linux** (Debian, Ubuntu, Red Hat, Fedora, Arch, and generic)
- **Windows** (MSYS2/MinGW environment)

### ✅ Architectures
- **x64** (Intel/AMD 64-bit)
- **ARM64** (Apple Silicon, ARM64 servers)
- **ARM** (ARMv7, Raspberry Pi)

### ✅ Cross-Compilation Targets
- **Windows**: `x86_64-pc-windows-gnu`, `x86_64-pc-windows-msvc`
- **Linux**: `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu`, `armv7-unknown-linux-gnueabihf`
- **Linux MUSL** (optional): `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`
- **macOS**: `x86_64-apple-darwin`, `aarch64-apple-darwin`
- **WebAssembly**: `wasm32-unknown-unknown`, `wasm32-wasi`

## � Comprehensive Library Support

### ✅ Essential Development Libraries
- **OpenSSL**: Cryptographic library for secure communications
- **libmagic**: File type detection and analysis
- **PCRE/PCRE2**: Perl-compatible regular expressions
- **SQLite**: Embedded SQL database engine
- **libxml2**: XML parsing and manipulation
- **zlib/bzip2/xz/lz4**: Compression libraries

### ✅ Network and Communication
- **curl**: HTTP client and file transfer
- **libssh**: SSH client library
- **OpenSSL**: TLS/SSL support

### ✅ Multimedia and Graphics
- **FFmpeg**: Audio/video processing
- **GTK3**: Cross-platform GUI toolkit
- **freetype**: Font rendering
- **fontconfig**: Font configuration
- **X11**: X Window System support

### ✅ Build Systems
- **CMake**: Cross-platform build system
- **Ninja**: Fast build system
- **gcc-multilib**: Multilib support for 32/64-bit

### ✅ Security and Analysis
- **YARA**: Malware pattern matching
- **Regex engines**: PCRE and PCRE2 support

### ✅ Cross-Compilation Libraries
- **Multi-architecture**: Libraries available for x64, ARM64, ARM
- **Platform-specific**: Optimized for each target platform
- **Conditional installation**: Only installs what's needed for chosen targets

### ✅ AI/ML Libraries
- **LightGBM**: Gradient boosting framework (cross-compilation ready)
- **ONNX**: Open Neural Network Exchange format (cross-compilation ready)
- **OpenBLAS/LAPACK**: Linear algebra libraries (cross-compilation ready)
- **Protocol Buffers**: Data serialization (cross-compilation ready)
- **HDF5**: Hierarchical data format (cross-compilation ready)
- **Rust ML Crates**: tch (PyTorch bindings), candle-core, smartcore

## � Linking Types

### GNU Linking (Default)
- **Compatibility**: Standard Linux distributions
- **Linking**: Dynamic linking with system libraries
- **Binary Size**: Larger, but shares system libraries
- **Use Case**: Development, standard Linux applications
- **Dependencies**: Requires system libraries at runtime

### MUSL Linking (Optional)
- **Compatibility**: Static binaries, container-friendly
- **Linking**: Static linking, no runtime dependencies
- **Binary Size**: Smaller, self-contained
- **Use Case**: Containers, embedded systems, minimal environments
- **Dependencies**: No external dependencies required

## 🛡️ Security Features

### ✅ Installation Security
- **Official rustup installer**: Uses official Rust installation method
- **Checksum verification**: Secure download and verification
- **User-level installation**: No system-wide modifications required
- **Sandboxed environment**: Isolated Rust toolchain

### ✅ Development Security
- **Cargo audit**: Security vulnerability scanning
- **Trusted sources**: Official package registry and sources
- **Dependency checking**: Automated security analysis
- **Code analysis**: Built-in linting and security checks

## Installation Steps

### 🚀 Quick Start
```bash
# Download and run the installer
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# OR use our comprehensive installer:
./rust-install.sh

# The installer will present a menu:
# 1) Install Rust (basic installation)
# 2) Configure Rust with cross-compilation targets  
# 3) Configure Rust with cross-compilation + AI/ML libraries
# 4) Configure Cargo publishing settings
```

### 📋 Installation Process

#### **1. Menu Selection**
Choose your installation mode based on needs:
- **Basic**: Rust + essential libraries only
- **Cross-compilation**: Rust + cross-compilation targets
- **Cross-compilation + AI/ML**: Full ML development environment
- **Cargo Publishing**: Configure publishing settings (standalone option)

#### **2. Platform Detection**
Automatically detects OS and architecture:
- macOS (Intel/Apple Silicon)
- Linux (Debian/Ubuntu/Fedora/Arch)
- Windows (MSYS2)

#### **3. Dependency Installation**
Installs platform-specific build tools and libraries based on selected mode.

#### **4. Configuration Setup**
Automatically creates `~/.cargo/config.toml` with:
- Cross-compilation linkers
- Environment variables
- Library paths for all targets
- AI/ML library configurations (if selected)

#### **5. Verification**
Tests installation and cross-compilation capabilities.

### 🎯 Installation Modes

#### **Mode 1: Basic Installation**
```bash
# What you get:
✓ Rust toolchain (rustc, cargo, rustup)
✓ Essential development libraries (OpenSSL, libmagic, etc.)
✓ Basic cross-compilation support
✓ Cargo configuration for basic targets

# Configuration files used:
base.toml + basic.toml + macos-universal.toml (if on macOS)
```

#### **Mode 2: Cross-Compilation**
```bash
# What you get:
✓ Everything from Basic mode
✓ Full cross-compilation toolchain
✓ Multi-architecture support (x64, ARM64, ARM)
✓ Advanced Cargo configuration
✓ Universal binary support (macOS)

# Configuration files used:
base.toml + cross-compile.toml [+ musl.toml] + macos-universal.toml (if on macOS)
```

#### **Mode 3: Cross-Compilation + AI/ML**
```bash
# What you get:
✓ Everything from Cross-Compilation mode
✓ AI/ML libraries for cross-compilation
✓ Rust ML crates (tch, candle-core, smartcore)
✓ Scientific computing support
✓ ML model deployment capabilities

# Configuration files used:
base.toml + cross-compile.toml + ai-ml.toml [+ musl.toml] + macos-universal.toml (if on macOS)
```

#### **Mode 4: Cargo Publishing Configuration**
```bash
# What you get:
✓ Cargo registry login configuration
✓ crates.io API token setup
✓ Publishing settings optimization
✓ Secure credential management
✓ Next steps guidance

# Configuration files used:
cargo-publish.toml (added to existing ~/.cargo/config.toml)

# Prerequisites:
✓ Rust must already be installed (options 1, 2, or 3)
✓ crates.io account and API token
```

## Platform-Specific Details

### macOS Installation
```bash
# Automatic Homebrew setup with dual architecture support
- Native Homebrew (ARM64 on Silicon, x86_64 on Intel)
- Intel Homebrew for cross-compilation (on Silicon Macs)
- Universal binary build environment
- OpenSSL, readline, sqlite3, xz, zlib
- Essential development libraries: cmake, ninja, libmagic, pcre/pcre2
- Compression libraries: bzip2, xz, lz4
- Network libraries: curl, libssh
- Multimedia libraries: ffmpeg
- GUI libraries: gtk+3, glib, freetype, fontconfig
- AI/ML libraries: openblas, lapack, hdf5, protobuf (AI mode only)
- Cross-compilation: mingw-w64, GNU cross-compilers
- Universal binary script: ~/.cargo/build-universal.sh

# Dual Homebrew Architecture:
Apple Silicon Mac:
- Native: /opt/homebrew (ARM64 packages)
- Cross-compilation: /usr/local/homebrew (x86_64 packages)

Intel Mac:
- Native: /usr/local (x86_64 packages)
```

## 📁 Configuration System

### Modular TOML Configuration
The script uses modular configuration files located in `rust/config/`:

```
rust/config/
├── base.toml              # Base Cargo settings
├── basic.toml             # Basic installation config
├── cross-compile.toml     # Cross-compilation settings
├── musl.toml              # MUSL static linking
├── ai-ml.toml             # AI/ML library configuration
├── macos-universal.toml   # macOS universal binary support
├── cargo-publish.toml     # Cargo publishing settings
└── README.md              # Configuration documentation
```

### Automatic Configuration Assembly
```bash
# Final configuration created at: ~/.cargo/config.toml

# Mode 1 (Basic):
base.toml + basic.toml [+ macos-universal.toml]

# Mode 2 (Cross-compilation):
base.toml + cross-compile.toml [+ musl.toml] [+ macos-universal.toml]

# Mode 3 (Cross-compilation + AI/ML):
base.toml + cross-compile.toml + ai-ml.toml [+ musl.toml] [+ macos-universal.toml]

# Mode 4 (Cargo Publishing - standalone):
cargo-publish.toml (added to existing ~/.cargo/config.toml)
```

### � Complete Cross-Compilation Matrix

The installer provides **true universal cross-compilation** - you can develop on ANY platform and build for ANY other platform:

| **From Platform** | **To Windows** | **To macOS** | **To Linux** | **To Other Architectures** |
|-------------------|-----------------|--------------|--------------|----------------------------|
| **Linux** | ✅ MinGW | ✅ OSXCross | ✅ GCC Cross | ✅ ARM64/ARM |
| **Windows** | ✅ Native | ✅ OSXCross | ✅ MSYS2 GCC | ✅ ARM64/ARM |
| **macOS** | ✅ Homebrew | ✅ Native/Dual | ✅ Homebrew GCC | ✅ ARM64/ARM |

#### **Platform Detection & Automatic Setup**
```bash
# Automatic OS detection:
✓ Linux (Debian/Ubuntu/Fedora/Arch)
✓ macOS (Intel/Apple Silicon) 
✓ Windows (MSYS2/MinGW)

# Automatic dependency installation:
✓ Linux: apt/yum/pacman → cross-compilers
✓ macOS: Homebrew → dual architecture support
✓ Windows: MSYS2 → MinGW + OSXCross
```

#### **Cross-Compilation Environments**
```bash
# Linux cross-compilation:
✓ x86_64-linux-gnu-gcc, aarch64-linux-gnu-gcc
✓ arm-linux-gnueabihf-gcc
✓ MUSL toolchains for static linking

# macOS cross-compilation (OSXCross):
✓ Apple clang (o64-clang, oa64-clang)
✓ macOS SDK (10.15+)
✓ Frameworks and system libraries

# Windows cross-compilation:
✓ MinGW-w64 toolchain
✓ Windows headers and libraries
✓ DLL linking support
```

### 🏠 Automatic Dependency Management

#### **Smart Package Manager Detection**
```bash
# The script automatically detects and installs package managers:

# Linux Distribution Detection:
✓ Debian/Ubuntu → apt package manager
✓ Red Hat/Fedora → yum/dnf package manager  
✓ Arch Linux → pacman package manager

# macOS Architecture Detection:
✓ Intel Mac → /usr/local/bin/brew
✓ Apple Silicon → /opt/homebrew/bin/brew

# Windows Environment:
✓ MSYS2/MinGW → pacman package manager
```

#### **Automatic Package Installation**
```bash
# If package manager is missing, the script:
✓ Downloads and installs Homebrew on macOS
✓ Verifies MSYS2 installation on Windows
✓ Uses system package managers on Linux
✓ Installs all required build tools automatically
✓ Sets up cross-compilation toolchains
```

### 🍎 macOS Silicon Dual Homebrew Architecture

#### **Automatic Dual Homebrew Setup**
```bash
# On Apple Silicon Macs, the script automatically sets up:

# Native ARM64 Homebrew:
/opt/homebrew/bin/brew
→ ARM64-native packages (faster performance)
→ Silicon-optimized libraries

# Intel Homebrew for Cross-Compilation:
/usr/local/homebrew/bin/brew  
→ Intel x64 packages for cross-compilation
→ Compatibility libraries

# Environment Configuration:
export PATH="/opt/homebrew/bin:/usr/local/homebrew/bin:$PATH"
```

#### **Library Path Configuration**
```bash
# Automatic library path setup for both architectures:

# Native ARM64 development:
OPENSSL_ROOT = "/opt/homebrew"
HDF5_DIR = "/opt/homebrew"
OPENBLAS_LIB = "/opt/homebrew/lib/libopenblas.dylib"

# Intel cross-compilation:
OPENSSL_ROOT_x86_64-apple-darwin = "/usr/local"
HDF5_DIR_x86_64-apple-darwin = "/usr/local"
OPENBLAS_LIB = "/usr/local/lib/libopenblas.dylib"
```

#### **Cross-Compilation Examples**
```bash
# From Apple Silicon Mac, build for Intel Mac:
cargo build --target x86_64-apple-darwin --release
# → Uses Intel Homebrew libraries automatically

# Native Apple Silicon development:
cargo build --target aarch64-apple-darwin --release  
# → Uses native ARM64 Homebrew libraries

# Universal binary creation:
~/.cargo/build-universal.sh my_app
# → Combines both architectures automatically
```

#### Universal Binary Building
```bash
# After installation on macOS, you get:
~/.cargo/build-universal.sh

# Build universal binary for your project:
cd your_rust_project
~/.cargo/build-universal.sh your_binary_name

# Result:
target/universal/your_binary_name-universal
# → Single binary that works on both Intel and Apple Silicon Macs!
```

### 🧠 Complete AI/ML Cross-Compilation Coverage

#### **AI/ML Libraries Available on ALL Platforms**
```bash
# Core ML libraries (cross-compilation ready):
✓ OpenBLAS      # Linear algebra (BLAS/LAPACK)
✓ HDF5          # Hierarchical data format
✓ LightGBM      # Gradient boosting framework
✓ Protocol Buffers # Data serialization
✓ Rust ML crates (tch, candle-core, smartcore)

# Platform-specific library configurations:
✓ Linux: .so shared libraries
✓ macOS: .dylib dynamic libraries  
✓ Windows: .dll.a import libraries
```

#### **Cross-Platform AI/ML Development**
```bash
# From ANY platform, build AI/ML applications for ALL platforms:

# Linux development:
cargo build --target x86_64-unknown-linux-gnu --features openblas --release
cargo build --target aarch64-unknown-linux-gnu --features openblas --release

# macOS development (from Linux/Windows):
cargo build --target x86_64-apple-darwin --features openblas --release
cargo build --target aarch64-apple-darwin --features openblas --release

# Windows development:
cargo build --target x86_64-pc-windows-gnu --features openblas --release

# → AI/ML libraries automatically linked on ALL targets!
```

#### **AI/ML Environment Variables**
```bash
# Automatic configuration for ALL targets:
OPENBLAS_ROOT_x86_64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_aarch64-unknown-linux-gnu = "/usr"
OPENBLAS_ROOT_x86_64-apple-darwin = "/usr/local"
OPENBLAS_ROOT_aarch64-apple-darwin = "/opt/homebrew"
OPENBLAS_ROOT_x86_64-pc-windows-gnu = "/usr/x86_64-w64-mingw32"

# Same for HDF5_DIR, LIGHTGBM_DIR, PROTOBUF_ROOT
# → Complete coverage across all platforms!
```

### 🚀 Real-World Usage Examples

#### **CI/CD Pipeline (Linux-based)**
```yaml
# Build ML application for ALL platforms from Linux runner:
- name: Build AI/ML binaries
  run: |
    cargo build --target x86_64-unknown-linux-gnu --features openblas --release
    cargo build --target aarch64-unknown-linux-gnu --features openblas --release
    cargo build --target x86_64-apple-darwin --features openblas --release
    cargo build --target aarch64-apple-darwin --features openblas --release
    cargo build --target x86_64-pc-windows-gnu --features openblas --release
```

#### **Development Team Workflow**
```bash
# Windows developer builds for macOS:
cargo build --target aarch64-apple-darwin --features openblas --release
# → macOS Silicon binary with full AI/ML support!

# Linux developer builds for Windows:
cargo build --target x86_64-pc-windows-gnu --features openblas --release
# → Windows binary with full AI/ML support!

# macOS developer builds universal binary:
~/.cargo/build-universal.sh ml_application
# → Single binary with AI/ML support for both Mac architectures!
```

### 📋 Installation Commands Summary

#### **Quick Start Examples**
```bash
# Basic installation (any platform):
./rust-install.sh
# Choose option 1

# Cross-compilation setup:
./rust-install.sh  
# Choose option 2 → Gets ALL cross-compilation environments

# Full AI/ML development:
./rust-install.sh
# Choose option 3 → Gets cross-compilation + AI/ML libraries

# Configure publishing (after Rust installed):
./rust-install.sh
# Choose option 4 → Cargo publishing setup
```

#### **Platform-Specific Examples**
```bash
# On Linux (Debian/Ubuntu):
./rust-install.sh
# → Installs: Rust + MinGW + OSXCross + GCC cross-compilers + AI/ML

# On macOS Silicon:
./rust-install.sh  
# → Installs: Rust + Dual Homebrew + Cross-compilation + AI/ML

# On Windows (MSYS2):
./rust-install.sh
# → Installs: Rust + MinGW + OSXCross + Cross-compilation + AI/ML
```

#### Cross-Compilation on Apple Silicon
```bash
# Build for Intel Mac (from Apple Silicon):
cargo build --target x86_64-apple-darwin --release

# Build for Apple Silicon (native):
cargo build --target aarch64-apple-darwin --release

# Build for Linux:
cargo build --target x86_64-unknown-linux-gnu --release
cargo build --target aarch64-unknown-linux-gnu --release

# Build for Windows:
cargo build --target x86_64-pc-windows-gnu --release
```

#### AI/ML Cross-Compilation
```bash
# Build ML project with AI/ML libraries for all targets:
cargo build --target aarch64-apple-darwin --features openblas --release
cargo build --target x86_64-apple-darwin --features openblas --release
cargo build --target aarch64-unknown-linux-gnu --features openblas --release

# Universal ML binary:
~/.cargo/build-universal.sh ml_application
# → ML libraries automatically linked for both architectures!
```

### 📦 Cargo Publishing Configuration

#### Publishing Setup
```bash
# Configure Cargo publishing (standalone option):
./rust-install.sh
# Choose option 4: Configure Cargo publishing settings

# What the setup does:
✓ Validates Rust installation
✓ Securely collects crates.io API token
✓ Configures cargo login automatically
✓ Sets up publishing configuration
✓ Tests the configuration
✓ Provides next steps guidance
```

#### Publishing Process
```bash
# After configuration, you can publish crates:
cd your_rust_project
cargo check          # Verify your code
cargo test           # Run tests
cargo publish        # Publish to crates.io

# Useful publishing commands:
cargo publish --dry-run        # Test without publishing
cargo publish --allow-dirty    # Publish with uncommitted changes
cargo login --help             # Show login help
cargo logout                   # Logout from registry
cargo owner                    # Manage crate owners
```

#### Configuration Files
```bash
# Files created/updated:
~/.cargo/config.toml          # Main configuration (updated)
~/.cargo/credentials.toml     # Credentials (managed by cargo)
~/.cargo/config.toml.backup.* # Backup of existing config

# Publishing settings added:
[registry]
default = "crates-io"

[publish]
registry = "crates-io"
allow-dirty = false
verify = true

[http]
timeout = 30
check-revoke = false

[net]
retry = 3
git-fetch-with-cli = true
```

#### Security Features
```bash
# Secure token handling:
✓ Silent input (token hidden during entry)
✓ Token validation (minimum length check)
✓ Retry mechanism for invalid tokens
✓ Backup existing configuration before changes
✓ Uses official 'cargo login' command
✓ No token storage in plain text files
```

#### Prerequisites
```bash
# Required before configuring publishing:
✓ Rust must be installed (options 1, 2, or 3)
✓ crates.io account (https://crates.io/)
✓ API token from crates.io (https://crates.io/me)

# Getting API token:
1. Login to https://crates.io/
2. Go to Account Settings
3. Click "New API Token"
4. Copy the token
5. Use it in the configuration script
```

### Linux Installation
```bash
# Debian/Ubuntu
sudo apt update
sudo apt install build-essential pkg-config libssl-dev
sudo apt install gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu mingw-w64
sudo apt install cmake ninja-build libmagic-dev libpcre3-dev libxml2-dev
sudo apt install sqlite3 zlib1g-dev libbz2-dev liblzma-dev liblz4-dev
sudo apt install libcurl4-openssl-dev libssh-dev ffmpeg-devel
sudo apt install gtk3-devel glib2-devel freetype-devel fontconfig-devel
sudo apt install yara libyara-dev libpcre2-dev gcc-multilib g++-multilib

# AI/ML libraries
sudo apt install libopenblas-dev liblapack-dev libatlas-base-dev
sudo apt install libhdf5-dev libprotobuf-dev protobuf-compiler
sudo apt install libgrpc-dev python3-dev python3-pip python3-venv
sudo apt install git wget curl

# Add MUSL tools if selected (optional)
sudo apt install musl-tools musl-dev

# Red Hat/Fedora
sudo dnf install gcc gcc-c++ make openssl-devel pkgconfig
sudo dnf install cmake ninja-build file-devel pcre-devel libxml2-devel
sudo dnf install sqlite-devel zlib-devel bzip2-devel xz-devel lz4-devel
sudo dnf install libcurl-devel libssh-devel ffmpeg-devel
sudo dnf install gtk3-devel glib2-devel freetype-devel fontconfig-devel
sudo dnf install yara yara-devel pcre2-devel

# AI/ML libraries
sudo dnf install openblas-devel lapack-devel atlas-devel
sudo dnf install hdf5-devel protobuf-devel protobuf-compiler
sudo dnf install grpc-devel python3-devel python3-pip
sudo dnf install git wget curl

# Arch Linux
sudo pacman -S base-devel openssl pkgconf cmake ninja
sudo pacman -S file pcre libxml2 sqlite zlib bzip2 xz lz4
sudo pacman -S curl libssh ffmpeg gtk3 glib2 freetype2 fontconfig
sudo pacman -S xorg-server mingw-w64-gcc multilib-devel
sudo pacman -S yara pcre2

# AI/ML libraries
sudo pacman -S openblas lapack atlas hdf5 protobuf python
sudo pacman -S git wget
```

### Windows Installation
```bash
# MSYS2/MinGW environment
pacman -S mingw-w64-x86_64-toolchain
pacman -S mingw-w64-ucrt-x86_64-toolchain
```

## Management Tools

### rust-monitor
```bash
# Show comprehensive Rust status
rust-monitor

# Show specific information
rust-monitor version      # Rust, cargo, rustup versions
rust-monitor targets      # Installed compilation targets
rust-monitor tools        # Installed cargo extensions
rust-monitor environment  # Environment variables
```

### rust-manager
```bash
# Update Rust toolchain
rust-manager update

# Manage targets
rust-manager list-targets
rust-manager install-target x86_64-pc-windows-gnu

# Install tools
rust-manager install-tool cargo-watch
rust-manager install-tool cargo-audit

# Check project
rust-manager check
```

## Usage Examples

### Basic Rust Operations
```bash
# Check Rust installation
rustc --version
cargo --version

# Create new project
cargo new myproject
cd myproject

# Build project
cargo build

# Run project
cargo run

# Test project
cargo test

# Build for release
cargo build --release
```

### Cross-Compilation Examples
```bash
# Build for Windows x64
cargo build --target x86_64-pc-windows-gnu

# Build for Linux x64 (GNU)
cargo build --target x86_64-unknown-linux-gnu

# Build for Linux ARM64 (GNU)
cargo build --target aarch64-unknown-linux-gnu

# Build for macOS x64
cargo build --target x86_64-apple-darwin

# Build for macOS ARM64
cargo build --target aarch64-apple-darwin

# Build for WebAssembly
cargo build --target wasm32-unknown-unknown

# Build static Linux binary (MUSL - if selected during installation)
cargo build --target x86_64-unknown-linux-musl --release

# Build static Linux ARM64 (MUSL - if selected during installation)
cargo build --target aarch64-unknown-linux-musl --release
```

### Advanced Cross-Compilation
```bash
# Build static Linux binary (GNU)
cargo build --target x86_64-unknown-linux-gnu --release

# Build with specific features
cargo build --target x86_64-pc-windows-gnu --features "serde"

# Build with custom target directory
cargo build --target aarch64-unknown-linux-gnu --target-dir ./build

# Install cross-compilation tool
cargo install cargo-xbuild
```

## Configuration Examples

### Cargo.toml for Cross-Platform
```toml
[package]
name = "cross-platform-app"
version = "0.1.0"
edition = "2021"

[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.0", features = ["full"] }

[target.'cfg(windows)'.dependencies]
winapi = { version = "0.3", features = ["winuser"] }

[target.'cfg(unix)'.dependencies]
libc = "0.2"

[[bin]]
name = "main"
path = "src/main.rs"
```

### Cross-Platform Code
```rust
// src/main.rs
use std::env;

fn main() {
    println!("Hello, cross-platform world!");
    
    // Platform-specific code
    #[cfg(windows)]
    {
        println!("Running on Windows");
        // Windows-specific code
    }
    
    #[cfg(unix)]
    {
        println!("Running on Unix-like system");
        // Unix-specific code
    }
    
    #[cfg(target_os = "macos")]
    {
        println!("Running on macOS");
        // macOS-specific code
    }
    
    // Architecture-specific code
    match env::consts::ARCH {
        "x86_64" => println!("64-bit Intel/AMD"),
        "aarch64" => println!("ARM64"),
        "arm" => println!("32-bit ARM"),
        _ => println!("Other architecture: {}", env::consts::ARCH),
    }
}
```

## File Structure

```
~/.cargo/
├── bin/                     # Installed cargo binaries
├── registry/                # Package registry cache
├── git/                     # Git dependencies cache
├── config.toml             # Cargo configuration
└── env                     # Environment setup script

~/.rustup/
├── toolchains/             # Installed toolchains
├── updates/                # Update information
└── downloads/              # Downloaded files

/usr/local/bin/
├── rust-monitor            # Monitoring script
└── rust-manager            # Management script

/tmp/
└── rust-install.log        # Installation log
```

## WebAssembly Development

### Basic WASM Project
```bash
# Create WASM project
cargo new wasm-project --lib
cd wasm-project

# Add WASM dependencies
cargo add wasm-bindgen --target wasm32-unknown-unknown

# Build for WebAssembly
cargo build --target wasm32-unknown-unknown

# Install wasm-bindgen-cli
cargo install wasm-bindgen-cli

# Generate JavaScript bindings
wasm-bindgen target/wasm32-unknown-unknown/debug/wasm_project.wasm --out-dir ./pkg
```

### WASM Example Code
```rust
// src/lib.rs
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

#[wasm_bindgen]
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[wasm_bindgen]
pub fn fibonacci(n: u32) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}
```

## Security Checklist

### Pre-Installation
- [ ] Sufficient disk space (2GB+ recommended)
- [ ] Internet connection for downloads
- [ ] Appropriate permissions (sudo on Linux)
- [ ] Build tools available or installable
- [ ] Cross-compilation tools available

### Post-Installation
- [ ] Rust toolchain working correctly
- [ ] Cross-compilation targets installed
- [ ] Cargo environment configured
- [ ] Security tools installed (cargo-audit)
- [ ] Monitoring scripts working

### Ongoing Security
- [ ] Regular updates: `rustup update`
- [ ] Security audits: `cargo audit`
- [ ] Dependency monitoring: `cargo outdated`
- [ ] Code quality checks: `cargo clippy`
- [ ] Format checking: `cargo fmt --check`

## Troubleshooting

### Installation Issues
```bash
# Check Rust installation
rustc --version
cargo --version

# Check environment
rust-monitor environment

# Reinstall if needed
rustup self uninstall
./rust-install.sh
```

### Cross-Compilation Issues
```bash
# Check installed targets
rustup target list --installed

# Install missing target
rustup target add x86_64-pc-windows-gnu

# Check cargo configuration
cat ~/.cargo/config.toml

# Test cross-compilation
cargo build --target x86_64-pc-windows-gnu --verbose
```

### Platform-Specific Issues
```bash
# macOS: Check Homebrew
brew doctor

# Linux: Check dependencies
dpkg -l | grep build-essential  # Debian/Ubuntu
rpm -qa | grep gcc               # Red Hat/Fedora

# Windows: Check MSYS2
pacman -Q mingw-w64-x86_64-toolchain
```

## Performance Considerations

### Build Performance
- **Parallel compilation**: Use `cargo build -j$(nproc)`
- **Incremental builds**: Enabled by default
- **Target caching**: Use `sccache` for distributed caching
- **Link time optimization**: Use `cargo build --release -Z build-std`

### Cross-Compilation Performance
- **Target-specific optimization**: Use appropriate linker flags
- **GNU linking**: Standard Linux binaries, dynamic linking
- **MUSL linking**: Static binaries, no runtime dependencies
- **Binary size**: Use `cargo bloat` to analyze binary size
- **Compilation speed**: Use `cargo check` for fast validation

## Advanced Configuration

### Custom Cargo Config
```toml
# ~/.cargo/config.toml
[build]
jobs = 8                     # Parallel jobs
rustflags = ["-C", "target-cpu=native"]  # Native optimizations

[target.x86_64-pc-windows-gnu]
linker = "x86_64-w64-mingw32-gcc"

[target.aarch64-unknown-linux-gnu]
linker = "aarch64-linux-gnu-gcc"

[registry]
default = "crates-io"
sparse-registry = true

[net]
git-fetch-with-cli = true
```

### Workspace Configuration
```toml
# Cargo.toml (workspace)
[workspace]
members = [
    "core",
    "cli",
    "web",
    "wasm",
]

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
```

## Integration Examples

### CI/CD Pipeline
```yaml
# .github/workflows/rust.yml
name: Rust CI
on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        rust: [stable, beta, nightly]
    
    runs-on: ${{ matrix.os }}
    
    steps:
    - uses: actions/checkout@v2
    - uses: actions-rs/toolchain@v1
      with:
        toolchain: ${{ matrix.rust }}
        override: true
    
    - name: Build
      run: cargo build --verbose
    
    - name: Test
      run: cargo test --verbose
    
    - name: Check formatting
      run: cargo fmt -- --check
    
    - name: Run clippy
      run: cargo clippy -- -D warnings
```

### Docker Integration
```dockerfile
# Dockerfile (GNU linking)
FROM rust:1.75 as builder

WORKDIR /app
COPY . .

# Build for specific target
RUN cargo build --target x86_64-unknown-linux-gnu --release

FROM ubuntu:latest
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder /app/target/x86_64-unknown-linux-gnu/release/myapp /usr/local/bin/myapp
CMD ["myapp"]
```

```dockerfile
# Dockerfile (MUSL linking - static binary)
FROM rust:1.75 as builder

WORKDIR /app
COPY . .

# Build static binary
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /usr/local/bin/myapp
CMD ["myapp"]
```

## Compliance and Standards

This installation follows:
- **Rust Security Guidelines**: Official security best practices
- **Cross-Platform Standards**: Platform-specific conventions
- **Industry Standards**: Modern development practices
- **Open Source Compliance**: License and attribution requirements

## Support and Maintenance

### Regular Maintenance
- Update Rust toolchain regularly
- Monitor security advisories
- Update cross-compilation targets
- Clean cargo cache periodically
- Review and update dependencies

### Performance Optimization
- Monitor build times
- Optimize cargo configuration
- Use appropriate compilation flags
- Implement caching strategies
- Profile and optimize code

This Rust universal installation provides a complete, secure, and performant development environment for cross-platform Rust development across all major operating systems and architectures.
