# Rust Universal Auto-Installation Script
![https://img.shields.io/badge/rust-stable-orange](https://img.shields.io/badge/rust-stable-orange)
![https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue](https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green)
![https://img.shields.io/badge/cross%20compilation-enabled-purple](https://img.shields.io/badge/cross%20compilation-enabled-purple)
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

## 🔗 Linking Types

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

1. **Platform Detection**: Automatically detects OS and architecture
2. **Dependency Installation**: Installs platform-specific build tools
3. **Cross-Compilation Setup**: Installs MinGW, GCC cross-compilers
4. **Rustup Installation**: Installs official Rust toolchain manager
5. **Target Installation**: Adds cross-compilation targets
6. **Cargo Configuration**: Configures cross-compilation settings
7. **Tool Installation**: Installs useful cargo extensions
8. **Verification**: Tests installation and cross-compilation

## Platform-Specific Details

### macOS Installation
```bash
# Automatically installs via Homebrew
- OpenSSL, readline, sqlite3, xz, zlib
- Cross-compilation: mingw-w64, GNU cross-compilers
- Native target: x86_64-apple-darwin or aarch64-apple-darwin
```

### Linux Installation
```bash
# Debian/Ubuntu
sudo apt update
sudo apt install build-essential pkg-config libssl-dev
sudo apt install gcc-x86-64-linux-gnu gcc-aarch64-linux-gnu mingw-w64

# Add MUSL tools if selected (optional)
sudo apt install musl-tools musl-dev

# Red Hat/Fedora
sudo dnf install gcc gcc-c++ make openssl-devel pkg-config
sudo dnf install mingw64-gcc gcc-x86_64-linux-gnu

# Arch Linux
sudo pacman -S base-devel openssl pkgconf
sudo pacman -S mingw-w64-gcc arm-linux-gnueabihf-gcc
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
