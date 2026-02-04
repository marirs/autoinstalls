# AutoInstalls
![GitHub](https://img.shields.io/github/license/marirs/autoinstalls)
![https://img.shields.io/badge/shell-bash-blue](https://img.shields.io/badge/shell-bash-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange)

A comprehensive collection of automated installation scripts for popular software and development tools. These scripts are designed to simplify the setup process on Ubuntu and Debian systems with proper security configurations and optimizations.

---

## 🚀 Available Installations

### 🌐 Nginx Web Server
**High-performance web server with advanced modules and security hardening**

**Features:**
- ✅ Latest stable Nginx with optimized configuration
- ✅ Advanced modules (Brotli, GeoIP2, Rate Limiting, Security headers)
- ✅ SSL/TLS optimization with modern protocols
- ✅ DDoS protection and connection limiting
- ✅ Comprehensive security hardening
- ✅ Performance monitoring and status endpoints
- ✅ Automated configuration management

**Installation:**
```bash
cd nginx/
sudo ./nginx-install.sh
```

**What's Included:**
- Nginx with performance optimizations
- Security headers and hardening
- Rate limiting and DDoS protection
- SSL/TLS configuration
- Monitoring and status endpoints
- Log rotation and backup scripts

---

### 🐍 Python 3 Development Environment
**Latest Python 3.11 with development tools and virtual environment management**

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

## 🔧 Common Features Across All Scripts

### 🛡️ Security Best Practices
- **Localhost-only binding** for databases (MongoDB, PostgreSQL)
- **SSL/TLS encryption** where applicable
- **Authentication** and authorization
- **Firewall-friendly** configurations
- **Audit logging** and monitoring
- **Hardened** default settings

### 📊 Monitoring and Management
- **Automated backup** solutions
- **User management** utilities
- **Performance monitoring** tools
- **Log rotation** and management
- **Status endpoints** for health checks
- **Alerting** capabilities

### 🚀 Performance Optimizations
- **Tuned configurations** for production use
- **Resource optimization** settings
- **Connection pooling** and limits
- **Caching** configurations
- **Compression** support
- **Parallel processing** where applicable

### 📝 Comprehensive Logging
- **Detailed installation logs**
- **Error handling** and reporting
- **Progress indicators**
- **Troubleshooting** information
- **Configuration** documentation

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
- **Python**: `/tmp/py3-install.log`
- **MongoDB**: `/tmp/mongodb-install.log`
- **PostgreSQL**: `/tmp/postgresql-install.log`
- **QEMU**: `/tmp/qemu-install.log`

---

## 🛠️ Advanced Configuration

### Customization Options:
- **Configuration files**: Located in each component's `conf/` directory
- **Environment variables**: Can be set before running scripts
- **Module selection**: Choose specific modules during installation
- **Performance tuning**: Adjust settings in configuration files
- **Security settings**: Modify according to your security requirements

### Integration Examples:
- **Web applications**: Nginx + PostgreSQL/Python
- **API servers**: Nginx + Python + PostgreSQL
- **Microservices**: Nginx + MongoDB + Python
- **Development environments**: Python + PostgreSQL + QEMU

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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
