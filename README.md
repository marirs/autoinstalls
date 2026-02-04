# AutoInstalls
![GitHub](https://img.shields.io/github/license/marirs/autoinstalls?label=Apache-2.0)
![https://img.shields.io/badge/shell-bash-blue](https://img.shields.io/badge/shell-bash-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS%20%7C%20Windows-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS%20%7C%20Windows-orange)
![https://img.shields.io/badge/components-14-green](https://img.shields.io/badge/components-14-green)
![https://img.shields.io/badge/cross%20compilation-enabled-purple](https://img.shields.io/badge/cross%20compilation-enabled-purple)
![https://img.shields.io/badge/ai%20ml-ready-blue](https://img.shields.io/badge/ai%20ml-ready-blue)
![https://img.shields.io/badge/security-hardened-red](https://img.shields.io/badge/security-hardened-red)

A comprehensive collection of automated installation scripts for popular software and development tools. These scripts are designed to simplify the setup process on Ubuntu and Debian systems with proper security configurations and optimizations.

---

## 🚀 Available Installations

### 🖥️ Server Setup & Hardening
**Comprehensive server initialization, configuration, and security hardening automation**
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-hardened-red](https://img.shields.io/badge/security-hardened-red)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)
![https://img.shields.io/badge/package%20fallback-enabled-brightgreen](https://img.shields.io/badge/package%20fallback-enabled-brightgreen)

**Features:**
- ✅ **Intelligent Package Detection** - Automatically detects OS version and adapts package installation
- ✅ **Comprehensive Fallback System** - Tries multiple package names for maximum compatibility
- ✅ **Cross-Distribution Support** - Works on Ubuntu, Debian (9-13), CentOS/RHEL, Fedora, and macOS
- ✅ **Menu-Driven Setup** - Choose individual components or complete server setup
- ✅ **System Hardening** - Kernel security, network protection, file system security
- ✅ **SSH Key Management** - Generate or import SSH keys with proper hardening
- ✅ **Network Configuration** - IPv4/IPv6 dual stack, virtual host support
- ✅ **Firewall Setup** - UFW/firewalld configuration with security rules
- ✅ **User Authentication** - Secure user management and password policies
- ✅ **Nginx Virtual Hosts** - Web server preparation with SSL support

**Advanced Package Handling:**
- 🔄 **Version-Aware Installation** - Detects Debian 9-13, Ubuntu 18.04-24.04, RHEL/CentOS 7-9, Fedora
- 🔄 **Package Name Variations** - Handles `software-properties-common` → `python3-software-properties`
- 🔄 **Build Tool Fallbacks** - `build-essential` → `build-base` → `base-devel`
- 🔄 **Library Alternatives** - `libssl-dev` → `openssl-dev` → `libssl3-dev`
- 🔄 **GPG Package Detection** - `gnupg` → `gnupg2` → `gpg`
- 🔄 **Critical Dependency Validation** - Ensures essential tools are available

**Installation:**
```bash
cd server/
sudo ./server-setup.sh

# Choose your setup mode:
# 1-7: Individual components (Essential, Hardening, Network, SSH, Nginx, Firewall, Users)
# 8: Complete Server Setup (Recommended)
# 9: Custom Setup (Select specific components)
```

**What's Included:**
- Essential software installation with intelligent package detection
- System security hardening with kernel and network protection
- SSH key generation and management with secure configurations
- Network configuration for IPv4/IPv6 dual stack
- Firewall setup with UFW/firewalld support
- User authentication hardening with password policies
- Nginx virtual host templates with SSL preparation
- Comprehensive logging and verification tools

**Package Fallback Examples:**
```bash
# Debian 13 - Automatic Package Resolution
Installing dependencies for debian 13...
Found python3-software-properties for software properties
Found gnupg2 for GPG support
Found build-base for build tools
Found libssl3-dev for SSL support
✓ Critical dependencies are available

# RHEL Systems - Package Manager Detection
Installing dependencies for centos 7...
Using yum package manager
Found cmake3 for build system
✓ Critical dependencies are available
```

---

### 🌐 Nginx Web Server
**High-performance web server with advanced modules, security hardening, and virtual host management**
![https://img.shields.io/badge/version-latest-brightgreen](https://img.shields.io/badge/version-latest-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)
![https://img.shields.io/badge/virtual%20host%20generator-enabled-blue](https://img.shields.io/badge/virtual%20host%20generator-enabled-blue)

**Features:**
- ✅ Latest stable Nginx with optimized configuration
- ✅ Advanced modules (Brotli, GeoIP2, Rate Limiting, Security headers)
- ✅ SSL/TLS optimization with modern protocols
- ✅ DDoS protection and connection limiting
- ✅ Comprehensive security hardening
- ✅ Performance monitoring and status endpoints
- ✅ Automated configuration management
- ✅ **Interactive Virtual Host Generator** - Generate and manage virtual hosts with SSL/TLS
- ✅ **Dual Stack Support** - IPv4/IPv6 configuration with automatic IP detection
- ✅ **Security-First Templates** - Modern SSL, HSTS, security headers, rate limiting

**Virtual Host Generator Features:**
- 🔄 **Interactive Menu System** - User-friendly CLI for vhost management
- 🔄 **Automatic IP Detection** - Detects all IPv4/IPv6 addresses for binding
- 🔄 **SSL/TLS Configuration** - Modern SSL with HTTP to HTTPS redirect
- 🔄 **Security Headers** - CSP, HSTS, XSS protection, clickjacking prevention
- 🔄 **Rate Limiting** - Configurable request rate limiting per vhost
- 🔄 **PHP Support** - FastCGI PHP processing with optional integration
- 🔄 **Document Root Management** - Automatic directory creation with permissions
- 🔄 **Configuration Testing** - Validates Nginx config before applying changes

**Installation:**
```bash
cd nginx/
sudo ./nginx-install.sh

# After installation, use the virtual host generator:
sudo ./nginx-vhost-generator.sh
```

**Virtual Host Management:**
```bash
# Generate new virtual host with SSL/TLS
sudo ./nginx-vhost-generator.sh
# Choose option 1, follow interactive prompts:
# - Select IP address (IPv4/IPv6 or all)
# - Enter domain name and aliases
# - Configure SSL certificates
# - Enable security headers and rate limiting
# - Set up PHP support (optional)

# Enable available virtual hosts
sudo ./nginx-vhost-generator.sh
# Choose option 2 to enable disabled virtual hosts

# List all virtual hosts
sudo ./nginx-vhost-generator.sh
# Choose option 3 to see status (Enabled/Disabled)
```

**What's Included:**
- Nginx with performance optimizations
- Security headers and hardening
- Rate limiting and DDoS protection
- SSL/TLS configuration
- Monitoring and status endpoints
- Log rotation and backup scripts
- Interactive virtual host generator
- Professional vhost templates with security best practices

---

### � PHP Programming Language
**Multi-version PHP installation with FPM, 40+ extensions, and webserver integration**
![https://img.shields.io/badge/php-8.3%20%7C%208.2%20%7C%208.1%20%7C%208.0%20%7C%207.4-blue](https://img.shields.io/badge/php-8.3%20%7C%208.2%20%7C%208.1%20%7C%208.0%20%7C%207.4-blue)
![https://img.shields.io/badge/php--fpm-enabled-green](https://img.shields.io/badge/php--fpm-enabled-green)
![https://img.shields.io/badge/extensions-40%2B-brightgreen](https://img.shields.io/badge/extensions-40%2B-brightgreen)
![https://img.shields.io/badge/nginx%20%7C%20apache-integrated-purple](https://img.shields.io/badge/nginx%20%7C%20apache-integrated-purple)

**Features:**
- ✅ **Multi-Version Support** - PHP 8.3, 8.2, 8.1, 8.0, 7.4
- ✅ **PHP-FPM Configuration** - Unix Socket or TCP Port options
- ✅ **40+ Extensions** - Database, security, image, system extensions
- ✅ **Webserver Integration** - Automatic Nginx and Apache configuration
- ✅ **Security Hardening** - Production-ready security settings
- ✅ **Performance Optimization** - OPcache and FPM tuning
- ✅ **Smart Installation** - Package fallbacks and PECL support
- ✅ **Comprehensive Testing** - Built-in test site and validation

**Extension Categories:**
- 🔄 **Database Extensions** - Redis, MongoDB, MySQL, PostgreSQL, SQLite
- 🔄 **Security Extensions** - Sodium, GMP for modern cryptography
- 🔄 **Image Processing** - GD, ImageMagick, EXIF support
- 🔄 **Web Services** - SOAP, XML-RPC, DOM, SimpleXML
- 🔄 **System Extensions** - Process control, shared memory, IPC
- 🔄 **Text Processing** - JSON, mbstring, tokenizer, iconv

**Installation:**
```bash
cd php/
sudo ./php-install.sh

# Interactive installation:
# - Select PHP version (8.3, 8.2, 8.1, 8.0, 7.4)
# - Choose FPM type (Unix Socket/TCP Port)
# - Configure webserver integration (Nginx/Apache)
# - Install 40+ extensions automatically
```

**Webserver Integration:**
```bash
# Automatic configuration for detected webservers
# Nginx: Upstream and location blocks
# Apache: Proxy modules and virtual hosts
# Test site: http://php-test.local
# Extension testing: http://php-test.local/test-extensions.php
```

**What's Included:**
- Multi-version PHP with FPM
- 40+ essential extensions
- Nginx and Apache integration
- Security hardening and optimization
- Comprehensive test site
- Performance monitoring tools
- Production-ready configuration

---

### �🗄️ MySQL/MariaDB Database
**Unified installer for MySQL 8.0 and MariaDB 10.11 with comprehensive security**
![https://img.shields.io/badge/mysql-8.0-blue](https://img.shields.io/badge/mysql-8.0-blue)
![https://img.shields.io/badge/mariadb-10.11-orange](https://img.shields.io/badge/mariadb-10.11-orange)
![https://img.shields.io/badge/security-localhost%20only-red](https://img.shields.io/badge/security-localhost%20only-red)

**Features:**
- ✅ Interactive database selection (MySQL 8.0 or MariaDB 10.11)
- ✅ Localhost-only binding for maximum security
- ✅ Secure password generation and authentication
- ✅ Anonymous user removal and test database cleanup
- ✅ Firewall configuration (UFW/iptables)
- ✅ Systemd security hardening
- ✅ Automated backup and monitoring tools
- ✅ Comprehensive verification and testing

**Installation:**
```bash
cd mysql/
sudo ./mysql-install.sh
# Choose between MySQL 8.0 and MariaDB 10.11 when prompted
```

**Management Tools:**
```bash
# Monitor database status and performance
mysql-monitor

# Create automated backups
mysql-backup create

# List available backups
mysql-backup list
```

---

### 🐳 Docker Container Platform
**Container platform with security-focused configuration and management**
![https://img.shields.io/badge/docker-27.0.0-blue](https://img.shields.io/badge/docker-27.0.0-blue)
![https://img.shields.io/badge/docker%20compose-2.24.0-blue](https://img.shields.io/badge/docker%20compose-2.24.0-blue)
![https://img.shields.io/badge/security-internal%20only-orange](https://img.shields.io/badge/security-internal%20only-orange)

**Features:**
- ✅ Docker 27.0.0 and Docker Compose 2.24.0
- ✅ Internet access for containers with secure daemon
- ✅ User namespace remapping and seccomp profiles
- ✅ Internal Docker bridge networks
- ✅ Firewall rules for daemon security
- ✅ Automated backup and monitoring tools
- ✅ Example configurations for isolated and internet-enabled containers

**Installation:**
```bash
cd docker/
sudo ./docker-install.sh
```

**Management Tools:**
```bash
# Monitor Docker status and containers
docker-monitor

# Create Docker backups
docker-backup create

# Run example containers
cd examples/
docker-compose up -d
```

---

### 💾 Redis In-Memory Database
**High-performance Redis with security hardening and management tools**
![https://img.shields.io/badge/redis-7.2.4-red](https://img.shields.io/badge/redis-7.2.4-red)
![https://img.shields.io/badge/security-hardened-brightgreen](https://img.shields.io/badge/security-hardened-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ Redis 7.2.4 compiled from source
- ✅ Localhost-only binding with password authentication
- ✅ Dangerous commands disabled for security
- ✅ AOF and RDB persistence configuration
- ✅ Memory management and performance tuning
- ✅ Firewall configuration and systemd hardening
- ✅ Automated backup and monitoring scripts
- ✅ Comprehensive installation verification

**Installation:**
```bash
cd redis/
sudo ./redis-install.sh
```

**Management Tools:**
```bash
# Monitor Redis status and performance
redis-monitor

# Create automated backups
redis-backup create

# Test Redis connection
redis-cli -a <password> ping
```

---

### 🐍 Python 3 Development Environment
**Latest Python 3.11 with development tools and virtual environment management**
![https://img.shields.io/badge/python-3.11.8-blue](https://img.shields.io/badge/python-3.11.8-blue)
![https://img.shields.io/badge/status-development%20ready-green](https://img.shields.io/badge/status-development%20ready-green)

**Features:**
- ✅ Python 3.11.8 (latest stable)
- ✅ Optimized build with performance enhancements
- ✅ Virtualenvwrapper for environment management
- ✅ Comprehensive development dependencies
- ✅ ARM64 and x86_64 architecture support
- ✅ Security-hardened installation

**Installation:**
```bash
cd python3/
sudo ./inst-py3.sh
```

**What's Included:**
- Python 3.11.8 compiled from source
- Latest pip and package management
- Virtualenvwrapper for environment isolation
- Development libraries and headers
- Build tools and utilities

**Post-Installation:**
```bash
source ~/.bashrc
mkvirtualenv myenv
python3.11 --version
```

---

### 🗄️ MongoDB Database
**NoSQL database with comprehensive security and management tools**
![https://img.shields.io/badge/mongodb-latest-green](https://img.shields.io/badge/mongodb-latest-green)
![https://img.shields.io/badge/security-enterprise%20ready-orange](https://img.shields.io/badge/security-enterprise%20ready-orange)

**Features:**
- ✅ Latest MongoDB with authentication and SSL
- ✅ Multiple installation types (Standalone, Replica Set, Sharded Cluster)
- ✅ Advanced security configuration
- ✅ Automated backup and restore tools
- ✅ User management with role-based access
- ✅ Performance monitoring and alerting
- ✅ Localhost-only binding for security

**Installation:**
```bash
cd mongodb/
sudo ./mongodb-install.sh
```

**What's Included:**
- MongoDB server with security optimizations
- MongoDB Compass GUI (optional)
- Backup and restore automation
- User management utilities
- Performance monitoring tools
- Security hardening configurations

**Management Tools:**
```bash
# Create admin user
./scripts/mongodb-users create-admin admin password123

# Create backup
./scripts/mongodb-backup backup

# List users
./scripts/mongodb-users list
```

---

### 🐘 PostgreSQL Database
**Advanced relational database with enterprise-grade features**
![https://img.shields.io/badge/postgresql-latest-blue](https://img.shields.io/badge/postgresql-latest-blue)
![https://img.shields.io/badge/features-enterprise%20grade-purple](https://img.shields.io/badge/features-enterprise%20grade-purple)

**Features:**
- ✅ Latest PostgreSQL with performance tuning
- ✅ Multiple installation modes (Standalone, Primary-Replica, Cluster)
- ✅ Comprehensive security with Row Level Security
- ✅ Advanced monitoring and performance tuning
- ✅ Automated backup and point-in-time recovery
- ✅ User management with fine-grained permissions
- ✅ SSL/TLS encryption and audit logging
- ✅ Localhost-only binding for maximum security

**Installation:**
```bash
cd postgresql/
sudo ./postgresql-install.sh
```

**What's Included:**
- PostgreSQL server with optimizations
- pgAdmin4 web interface (optional)
- Extension support (pg_stat_statements, pg_trgm, etc.)
- Backup and restore automation
- User and role management
- Performance monitoring tools
- Security hardening configurations

**Management Tools:**
```bash
# Create application user
./scripts/postgresql-users create-app webapp password123 myapp

# Create backup
./scripts/postgresql-backup backup

# List users
./scripts/postgresql-users list
```

---

### 💻 QEMU Virtualization
**Full virtualization solution with KVM support**
![https://img.shields.io/badge/qemu-kvm-ready-green](https://img.shields.io/badge/qemu-kvm-ready-green)
![https://img.shields.io/badge/status-stable-blue](https://img.shields.io/badge/status-stable-blue)

**Features:**
- ✅ QEMU with KVM acceleration
- ✅ Virt-Manager for GUI management
- ✅ Libvirt for virtualization management
- ✅ Network configuration for VMs
- ✅ Storage pool management
- ✅ Bridge networking setup

**Installation:**
```bash
cd qemu/
sudo ./inst-qemu.sh
sudo ./inst-libvirt.sh
```

**What's Included:**
- QEMU hypervisor with KVM
- Virt-Manager GUI application
- Libvirt daemon and tools
- Network bridge configuration
- Storage pool setup
- User permissions for virtualization

---

### 🟢 Node.js JavaScript Runtime
**Modern JavaScript runtime with development tools and package management**
![https://img.shields.io/badge/node.js-20.x-lts-green](https://img.shields.io/badge/node.js-20.x-lts-green)
![https://img.shields.io/badge/npm-10.x-blue](https://img.shields.io/badge/npm-10.x-blue)
![https://img.shields.io/badge/security-hardened-orange](https://img.shields.io/badge/security-hardened-orange)
![https://img.shields.io/badge/status-development%20ready-green](https://img.shields.io/badge/status-development%20ready-green)

**Features:**
- ✅ Node.js 20.x LTS with npm package manager
- ✅ NodeSource or NVM installation options
- ✅ Development tools (nodemon, pm2, yarn)
- ✅ Security-hardened npm configuration
- ✅ Process management and monitoring
- ✅ Automated security auditing
- ✅ Global package management
- ✅ Performance optimization

**Installation:**
```bash
cd nodejs/
sudo ./nodejs-install.sh
# Choose between NodeSource LTS or NVM when prompted
```

**Management Tools:**
```bash
# Monitor Node.js status and performance
nodejs-monitor

# Manage global packages
nodejs-manager globals

# Security audit
npm audit
```

---

### 🔍 Elasticsearch Search Engine
**Powerful search and analytics engine with comprehensive security**
![https://img.shields.io/badge/elasticsearch-8.11.0-blue](https://img.shields.io/badge/elasticsearch-8.11.0-blue)
![https://img.shields.io/badge/security-localhost%20only-red](https://img.shields.io/badge/security-localhost%20only-red)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ Elasticsearch 8.11.0 with security features
- ✅ Localhost-only binding for maximum security
- ✅ Built-in security features enabled
- ✅ JVM memory optimization
- ✅ Cluster health monitoring
- ✅ Index and search capabilities
- ✅ Management interface (localhost:15672)
- ✅ Performance tuning

**Installation:**
```bash
cd elasticsearch/
sudo ./elasticsearch-install.sh
```

**Management Tools:**
```bash
# Monitor Elasticsearch status and performance
elasticsearch-monitor

# Manage Elasticsearch service
elasticsearch-manager start|stop|restart

# Test connection
curl http://localhost:9200
```

---

### 🐰 RabbitMQ Message Broker
**Reliable message broker with enterprise-grade features**
![https://img.shields.io/badge/rabbitmq-3.12-orange](https://img.shields.io/badge/rabbitmq-3.12-orange)
![https://img.shields.io/badge/security-hardened-brightgreen](https://img.shields.io/badge/security-hardened-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ RabbitMQ 3.12 with Erlang/OTP
- ✅ Localhost-only binding for security
- ✅ Management plugin enabled
- ✅ User and permission management
- ✅ Queue and connection monitoring
- ✅ Web management interface
- ✅ Message persistence and reliability
- ✅ Performance optimization

**Installation:**
```bash
cd rabbitmq/
sudo ./rabbitmq-install.sh
```

**Management Tools:**
```bash
# Monitor RabbitMQ status and queues
rabbitmq-monitor

# Manage RabbitMQ service and users
rabbitmq-manager start|stop|restart
rabbitmq-manager users
rabbitmq-manager add-user <username> <password>
```

---

### ☸️ Kubernetes Container Orchestration
**Production-grade container orchestration platform**
![https://img.shields.io/badge/kubernetes-1.29.0-blue](https://img.shields.io/badge/kubernetes-1.29.0-blue)
![https://img.shields.io/badge/containerd-1.7.11-green](https://img.shields.io/badge/containerd-1.7.11-green)
![https://img.shields.io/badge/security-enterprise%20ready-purple](https://img.shields.io/badge/kubernetes-1.29.0-blue)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ Kubernetes 1.29.0 with containerd runtime
- ✅ Single-node cluster setup
- ✅ Security-hardened configuration
- ✅ Systemd service management
- ✅ Firewall configuration
- ✅ Cluster initialization tools
- ✅ Monitoring and management scripts
- ✅ Production-ready setup

**Installation:**
```bash
cd kubernetes/
sudo ./kubernetes-install.sh
```

**Management Tools:**
```bash
# Monitor Kubernetes status and resources
kubernetes-monitor

# Manage Kubernetes services
kubernetes-manager start|stop|restart
kubernetes-manager init|reset

# Cluster management
kubectl cluster-info
kubectl get nodes
```

---

### 🦀 Rust Programming Language
**Universal Rust installation with cross-compilation support for all platforms**
![https://img.shields.io/badge/rust-stable-orange](https://img.shields.io/badge/rust-stable-orange)
![https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue](https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-blue)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64%20%7C%20ARM-green)
![https://img.shields.io/badge/cross%20compilation-universal-purple](https://img.shields.io/badge/cross%20compilation-universal-purple)
![https://img.shields.io/badge/ai%20ml-ready-blue](https://img.shields.io/badge/ai%20ml-ready-blue)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ Rust stable with rustup toolchain manager
- ✅ Multi-platform support (macOS, Linux, Windows)
- ✅ Multi-architecture support (x64, ARM64, ARM)
- ✅ Cross-compilation targets for all platforms
- ✅ Platform-specific dependency installation
- ✅ WebAssembly (WASM) support
- ✅ Development tools and cargo extensions
- ✅ Security audit and code analysis tools

**Installation:**
```bash
cd rust/
./rust-install.sh

# Source environment for new shells
source ~/.cargo/env
```

**Cross-Compilation Examples:**
```bash
# Build for Windows from Linux/macOS
cargo build --target x86_64-pc-windows-gnu

# Build for Linux ARM64
cargo build --target aarch64-unknown-linux-gnu

# Build for macOS from Linux
cargo build --target x86_64-apple-darwin

# Build for WebAssembly
cargo build --target wasm32-unknown-unknown
```

**Management Tools:**
```bash
# Monitor Rust installation and targets
rust-monitor

# Manage Rust toolchain and targets
rust-manager update
rust-manager install-target x86_64-pc-windows-gnu
rust-manager check
```

---

## 🔧 Common Features Across All Scripts

### 🛡️ Security Best Practices
- **Localhost-only binding** for databases (MySQL/MariaDB, Redis, MongoDB, PostgreSQL, Elasticsearch, RabbitMQ)
- **SSL/TLS encryption** where applicable
- **Authentication** and authorization
- **Firewall-friendly** configurations (UFW/iptables support)
- **Audit logging** and monitoring
- **Hardened** default settings
- **Systemd security** with resource limits and restrictions
- **Password generation** and secure storage

### 📊 Monitoring and Management
- **Automated backup** solutions with scheduling
- **User management** utilities
- **Performance monitoring** tools
- **Log rotation** and management
- **Status endpoints** for health checks
- **Alerting** capabilities
- **Backup verification** and restore tools

### 🚀 Performance Optimizations
- **Tuned configurations** for production use
- **Resource optimization** settings
- **Connection pooling** and limits
- **Caching** configurations
- **Compression** support
- **Parallel processing** where applicable
- **Memory management** and tuning

### 📝 Comprehensive Logging
- **Detailed installation logs**
- **Error handling** and reporting
- **Progress indicators**
- **Troubleshooting** information
- **Configuration** documentation
- **Verification** and testing results

---

## 🎯 System Requirements

### Minimum Requirements:
- **OS**: Ubuntu 18.04+ / Debian 9.x+
- **Architecture**: x86_64 or ARM64
- **Memory**: 2GB RAM minimum (4GB+ recommended)
- **Storage**: 10GB free space
- **Network**: Internet connection for downloads
- **Permissions**: Root/sudo access

### Recommended Requirements:
- **OS**: Ubuntu 20.04+ / Debian 10.x+
- **Memory**: 4GB+ RAM
- **Storage**: 20GB+ free space
- **CPU**: Multi-core processor
- **Network**: Stable internet connection

---

## 📚 Usage Instructions

### General Installation Pattern:
```bash
# Clone the repository
git clone https://github.com/marirs/autoinstalls.git
cd autoinstalls/

# Navigate to desired component
cd <component-name>/

# Run installation script
sudo ./<install-script>.sh

# Follow on-screen instructions
```

### Post-Installation Steps:
1. **Reload shell configuration** (if required)
2. **Verify installation** with provided test commands
3. **Configure** according to your needs
4. **Start services** and enable auto-start
5. **Test functionality** with provided examples

---

## 🔍 Troubleshooting

### Common Issues:
1. **Permission denied**: Run with `sudo`
2. **Architecture not supported**: Check system compatibility
3. **Download failed**: Verify internet connection
4. **Build failed**: Check logs in `/tmp/`
5. **Service won't start**: Check configuration and logs

### Getting Help:
- **Check logs**: Each script creates detailed log files
- **Review documentation**: Component-specific README files
- **Verify requirements**: Ensure system meets minimum requirements
- **Check permissions**: Ensure proper user permissions

### Log Locations:
- **Nginx**: `/tmp/nginx-install.log`
- **MySQL/MariaDB**: `/tmp/mysql-install.log`
- **Redis**: `/tmp/redis-install.log`
- **Docker**: `/tmp/docker-install.log`
- **Python**: `/tmp/py3-install.log`
- **MongoDB**: `/tmp/mongodb-install.log`
- **PostgreSQL**: `/tmp/postgresql-install.log`
- **QEMU**: `/tmp/qemu-install.log`
- **Node.js**: `/tmp/nodejs-install.log`
- **Elasticsearch**: `/tmp/elasticsearch-install.log`
- **RabbitMQ**: `/tmp/rabbitmq-install.log`
- **Kubernetes**: `/tmp/kubernetes-install.log`
- **Rust**: `/tmp/rust-install.log`

---

## 🛠️ Advanced Configuration

### Customization Options:
- **Configuration files**: Located in each component's `conf/` directory
- **Environment variables**: Can be set before running scripts
- **Module selection**: Choose specific modules during installation
- **Performance tuning**: Adjust settings in configuration files
- **Security settings**: Modify according to your security requirements

### Integration Examples:
- **Web applications**: Nginx + MySQL/MariaDB/PostgreSQL + Python
- **API servers**: Nginx + Python + Redis + MySQL/MariaDB
- **Microservices**: Nginx + MongoDB + Redis + Docker
- **Development environments**: Python + PostgreSQL + QEMU + Docker
- **Caching layers**: Redis + MySQL/MariaDB + Nginx
- **Containerized apps**: Docker + Redis + MySQL/MariaDB + Nginx

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contribution Guidelines:
1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

---

## 📞 Support

For support and questions:
- **Issues**: Open an issue on GitHub
- **Documentation**: Check component-specific README files
- **Logs**: Review installation logs for errors
- **Community**: Join discussions in GitHub Issues

---

## 🔄 Updates and Maintenance

### Regular Updates:
- **Security patches**: Applied regularly
- **Version updates**: Keep components current
- **Dependency updates**: Maintain latest stable versions
- **Configuration updates**: Optimize for performance and security

### Maintenance Tasks:
- **Log rotation**: Automated log management
- **Backup verification**: Ensure backup integrity
- **Performance monitoring**: Track system performance
- **Security audits**: Regular security reviews

---

**Thank you for using AutoInstalls! 🎉**

These scripts are designed to make your life easier by automating complex installations while maintaining security best practices and performance optimizations.
