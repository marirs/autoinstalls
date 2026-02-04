# Rust Configuration Files

This directory contains modular TOML configuration files for the Rust installation script.

## File Structure

### `base.toml`
- Base Cargo configuration
- Parallel compilation settings
- Sparse registry configuration
- Terminal colors and output settings

### `basic.toml`
- Basic Rust installation configuration
- Simple linker settings for common targets
- Used when user selects "Install Rust (basic installation)"

### `cross-compile.toml`
- Cross-compilation configuration
- Linker settings for Windows, ARM64, and ARM targets
- Environment variables for cross-compilation
- OpenSSL and pkg-config paths for all targets

### `musl.toml`
- MUSL static linking configuration
- Used when user selects MUSL linking type
- Configures static linkers for all targets

### `ai-ml.toml`
- AI/ML library configuration
- OpenBLAS, HDF5, LightGBM, Protocol Buffers settings
- Library paths and include directories for all targets
- Environment variables for AI/ML development

## Usage

The installation script automatically combines these files based on user selection:

1. **Basic Installation**: `base.toml` + `basic.toml`
2. **Cross-Compilation**: `base.toml` + `cross-compile.toml` (+ `musl.toml` if selected)
3. **Cross-Compilation + AI/ML**: `base.toml` + `cross-compile.toml` + `ai-ml.toml` (+ `musl.toml` if selected)

## Configuration Location

The final configuration is copied to: `~/.cargo/config.toml`

## Customization

You can modify these files to:
- Add new targets
- Change compiler flags
- Update library paths
- Add environment variables

The script will use these modified files during installation.
