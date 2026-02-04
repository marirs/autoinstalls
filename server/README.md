# Server Setup & Hardening Automation
========================================
![GitHub](https://img.shields.io/github/license/marirs/autoinstalls?label=Apache-2.0)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20macOS-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-hardened-red](https://img.shields.io/badge/security-hardened-red)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

Comprehensive server initialization, configuration, and hardening automation script with support for Ubuntu, Debian, and macOS. Features essential software installation, system hardening, network configuration, SSH key management, Nginx virtual host setup, firewall configuration, and user authentication hardening.

---

## 🚀 Menu-Driven Server Setup

### Installation Options:
1. **Essential Software Installation** - Core utilities and development tools
2. **System Hardening & Security Configuration** - sysctl.conf, file permissions, service hardening
3. **Network Configuration (IPv4/IPv6)** - Dual stack setup, virtual host preparation
4. **SSH Key Management** - Generate or import SSH keys, hardening
5. **Nginx Virtual Host Setup** - Web server configuration, SSL preparation
6. **Firewall Configuration** - UFW/firewalld setup, security rules
7. **User & Authentication Setup** - Secure user management, password policies
8. **Complete Server Setup** - All of the above (Recommended)
9. **Custom Setup** - Select individual components

---

## 🛡️ Security Features

### System Hardening
- ✅ **Kernel Hardening** - sysctl.conf security configurations
- ✅ **Network Security** - IP forwarding disabled, SYN cookies enabled
- ✅ **File System Security** - Protected hardlinks, symlinks, SUID restrictions
- ✅ **Memory Protection** - Swappiness optimization, dirty ratio tuning
- ✅ **Service Hardening** - Unnecessary services disabled
- ✅ **File Permissions** - Critical files secured with proper permissions

### Network Security
- ✅ **IPv4/IPv6 Dual Stack** - Full support for both protocols
- ✅ **Virtual Host Support** - Multiple IP addresses for virtual hosts
- ✅ **Connection Tracking** - Optimized for high traffic
- ✅ **Network Performance** - TCP tuning, buffer optimization

### SSH Security
- ✅ **Key-Based Authentication** - Generate or import SSH keys
- ✅ **SSH Daemon Hardening** - Secure configuration
- ✅ **Key Management** - Proper permissions and storage
- ✅ **macOS Support** - Native SSH key handling for Apple Silicon

### Firewall Protection
- ✅ **UFW Support** - Ubuntu/Debian firewall configuration
- ✅ **firewalld Support** - RHEL/CentOS firewall configuration
- ✅ **Default Deny Policy** - Secure inbound traffic control
- ✅ **Rate Limiting** - SSH brute force protection
- ✅ **Service Rules** - HTTP/HTTPS/SSH access control

---

## 🌐 Platform Support

### Supported Operating Systems
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **Debian**: 9.x, 10.x, 11.x, 12.x, 13.x
- **macOS**: Intel & Apple Silicon (Big Sur+)

### Architecture Support
- **x86_64** (Intel/AMD 64-bit)
- **ARM64** (Apple Silicon, ARM64 servers)

### Package Manager Support
- **apt** (Ubuntu/Debian)
- **yum** (CentOS/RHEL)
- **dnf** (Fedora)
- **brew** (macOS)

---

## 📦 Essential Software Installation

### Linux Packages
```bash
# System Essentials
- software-properties-common
- apt-transport-https
- ca-certificates
- curl, wget, git
- openssl, build-essential
- unzip, zip, vim, nano

# Monitoring & Tools
- htop, tree, jq, lsof
- net-tools, sysstat
- iotop, ncdu, fail2ban
- logrotate
```

### macOS Packages
```bash
# Development Essentials
- git, curl, wget, openssl
- bash, coreutils, findutils
- grep, sed, awk, vim, nano

# System Tools
- htop, tree, jq, yq
```

---

## 🔧 Installation Steps

### Quick Start
```bash
# Clone the repository
git clone https://github.com/marirs/autoinstalls.git
cd autoinstalls/server/

# Run the server setup script
sudo ./server-setup.sh

# Choose your setup mode:
# 1-7: Individual components
# 8: Complete setup (Recommended)
# 9: Custom selection
```

### Platform-Specific Instructions

#### Ubuntu/Debian
```bash
# Requires root privileges
sudo ./server-setup.sh

# Follow the menu prompts
# Confirm setup configuration
# Wait for completion
```

#### macOS
```bash
# Can run with user privileges (for most features)
./server-setup.sh

# Some features may require sudo for system-wide changes
```

---

## 🛠️ Configuration Details

### System Hardening (sysctl.conf)
```bash
# Network Security
net.ipv4.ip_forward = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0

# IPv6 Security
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.all.accept_source_route = 0

# Kernel Hardening
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1

# File System Security
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
```

### Network Configuration
```bash
# IPv4/IPv6 Dual Stack
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0

# Virtual Host Support
net.ipv4.ip_nonlocal_bind = 1
net.ipv6.ip_nonlocal_bind = 1

# Connection Tracking
net.netfilter.nf_conntrack_max = 1048576
```

### Firewall Rules
```bash
# UFW Configuration (Ubuntu/Debian)
- Default deny incoming
- Default allow outgoing
- Allow SSH (rate limited)
- Allow HTTP/HTTPS
- Enable firewall

# firewalld Configuration (RHEL/CentOS)
- Public zone default
- SSH, HTTP, HTTPS services
- Permanent rules
```

---

## 🔑 SSH Key Management

### Generate New Keys
```bash
# Interactive key generation
- Email address for key identification
- Custom key name support
- 4096-bit RSA keys
- Automatic authorized_keys setup
```

### Import Existing Keys
```bash
# Import public key
- Paste public key content
- Add to authorized_keys
- Proper permissions set

# Import private key (optional)
- Paste private key content
- Secure file permissions
- Ready for SSH usage
```

### macOS SSH Support
```bash
# Apple Silicon compatible
- Proper SSH directory handling
- Keychain integration support
- Native macOS SSH tools
```

---

## 🌐 Nginx Virtual Host Setup

### Nginx Installation & Configuration
```bash
# Automatic installation
- Package manager detection
- Service configuration
- Performance optimizations

# Virtual Host Template
- IPv4/IPv6 dual stack listening
- Security headers
- Gzip compression
- Server tokens disabled
- Common exploit blocking
```

### Virtual Host Template
```nginx
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    
    root /var/www/example.com/html;
    index index.html index.htm index.php;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Performance optimizations
    gzip on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json;
}
```

---

## 👥 User & Authentication Setup

### Sudo Configuration
```bash
# Secure sudo defaults
- Environment reset
- Timestamp timeout: 15 minutes
- Lecture always enabled
- Input/output logging
- Security restrictions
```

### Password Policy
```bash
# Password quality requirements
- Minimum length: 12 characters
- Minimum character classes: 3
- Maximum repetitions: 3
- Required different characters: 3
- Dictionary check enabled

# Password aging
- Maximum age: 90 days
- Minimum age: 1 day
- Warning period: 7 days
```

---

## 📊 Usage Examples

### Complete Server Setup
```bash
# Recommended for new servers
sudo ./server-setup.sh
# Choose option 8: Complete Server Setup

# This will:
- Install essential software
- Harden system configuration
- Configure network settings
- Set up SSH keys
- Prepare Nginx virtual hosts
- Configure firewall
- Set up user authentication
```

### Custom Setup
```bash
# For specific needs
sudo ./server-setup.sh
# Choose option 9: Custom Setup

# Select components:
# 1 2 4 6  # Essential, Hardening, SSH, Firewall
```

### SSH Key Setup Only
```bash
# For existing servers needing SSH hardening
sudo ./server-setup.sh
# Choose option 4: SSH Key Management

# Then choose:
# 1: Generate new keys
# 2: Import existing keys
```

---

## 🔍 Post-Setup Verification

### System Status Checks
```bash
# Check system hardening
sysctl -a | grep -E "(ipv4|ipv6|kernel|fs)"

# Verify firewall status
ufw status verbose        # Ubuntu/Debian
firewall-cmd --list-all    # RHEL/CentOS

# Check SSH configuration
sshd -T | grep -E "(permitrootlogin|passwordauthentication)"

# Verify Nginx configuration
nginx -t
systemctl status nginx
```

### Security Verification
```bash
# Check file permissions
ls -la /etc/passwd /etc/shadow /etc/group /etc/gshadow

# Verify SSH keys
ls -la ~/.ssh/ or /root/.ssh/
cat ~/.ssh/authorized_keys

# Check running services
systemctl list-units --type=service --state=running
```

---

## 📋 Important Files & Locations

### Configuration Files
```bash
# System hardening
/etc/sysctl.d/99-server-hardening.conf
/etc/sysctl.d/99-virtual-hosts.conf

# SSH configuration
~/.ssh/authorized_keys
/etc/ssh/sshd_config

# Nginx configuration
/etc/nginx/nginx.conf
/etc/nginx/sites-available/virtual-host-template

# Firewall configuration
/etc/ufw/user.rules
/etc/firewalld/zones/public.xml

# User authentication
/etc/sudoers.d/secure-config
/etc/security/pwquality.conf
```

### Log Files
```bash
# Setup log
/tmp/server-setup.log

# System logs
/var/log/syslog
/var/log/auth.log
/var/log/nginx/
/var/log/ufw.log
```

---

## 🚨 Security Recommendations

### Immediate Actions
1. **Regular Updates** - Keep system packages updated
2. **Monitor Logs** - Check system and security logs regularly
3. **SSH Keys Only** - Disable password authentication
4. **Backup Configuration** - Save copies of important config files
5. **Security Audits** - Regular security assessments

### Ongoing Maintenance
1. **Log Monitoring** - Set up log monitoring and alerts
2. **Security Scanning** - Regular vulnerability scans
3. **Access Review** - Periodic user access reviews
4. **Backup Testing** - Regular backup verification
5. **Performance Monitoring** - System performance tracking

---

## 🆘 Troubleshooting

### Common Issues
```bash
# Permission denied
- Ensure script is executable: chmod +x server-setup.sh
- Use sudo for system-wide changes

# Package installation failures
- Check internet connectivity
- Update package lists: apt update
- Check package manager status

# SSH key issues
- Verify file permissions: chmod 600 ~/.ssh/id_rsa
- Check authorized_keys format
- Test SSH connection: ssh -v user@host

# Firewall problems
- Check firewall status
- Verify port accessibility
- Review firewall logs
```

### Log Analysis
```bash
# Check setup log
tail -f /tmp/server-setup.log

# System logs
journalctl -f
tail -f /var/log/syslog

# Authentication logs
tail -f /var/log/auth.log

# Nginx logs
tail -f /var/log/nginx/error.log
```

---

## 📞 Support & Contributing

### Getting Help
- Check the setup log: `/tmp/server-setup.log`
- Review system logs in `/var/log/`
- Verify system requirements and permissions

### Contributing
- Report issues on GitHub
- Submit pull requests for improvements
- Suggest additional security features
- Share configuration templates

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../LICENSE) file for details.

---

**🎉 Your server is now secured, configured, and ready for production use!**
