### 🌐 Apache HTTP Server
**Powerful, flexible, and widely-used web server with comprehensive module ecosystem**
![https://img.shields.io/badge/apache-latest%20stable-blue](https://img.shields.io/badge/apache-latest%20stable-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20CentOS%207.x%20%7C%20RHEL%207.x%20%7C%20Fedora-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x%2C%2013.x%20%7C%20CentOS%207.x%20%7C%20RHEL%207.x%20%7C%20Fedora-orange)
![https://img.shields.io/badge/security-hardened-brightgreen](https://img.shields.io/badge/security-hardened-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Apache HTTP Server** is the most widely used web server software in the world. Known for its power, flexibility, and extensive module ecosystem, Apache has been the backbone of the internet for decades and continues to be a trusted choice for everything from small personal sites to large enterprise applications.

---

## 🎯 **Why Choose Apache?**

### **🔥 Proven Reliability:**
- **Battle-Tested** - Decades of production use across millions of websites
- **Extensive Documentation** - Comprehensive guides and community support
- **Flexible Configuration** - Powerful .htaccess support and per-directory configuration
- **Module Ecosystem** - Hundreds of modules for every conceivable use case
- **Enterprise-Ready** - Trusted by Fortune 500 companies and governments

### **🛠️ Technical Excellence:**
- **Multiple MPMs** - Event, Worker, and Prefork for different workloads
- **Advanced Security** - Built-in security features and extensive hardening options
- **Performance Optimization** - Caching, compression, and connection handling
- **Protocol Support** - HTTP/2, WebSocket, proxy, and load balancing
- **Integration Ready** - Seamless integration with PHP, Python, Ruby, and more

---

## 🚀 **Installation**

### **📥 Quick Install:**
```bash
cd apache/
sudo ./apache-install.sh
```

### **🔄 Dynamic Version Detection:**
The script automatically fetches the latest stable Apache version from the official download page:
- Fetches from: `https://httpd.apache.org/download.cgi`
- Fallback to known stable version if web fetch fails
- Ensures you always get the latest security updates and features

### **📋 Installation Process:**
1. **System Detection** - Automatically detects OS and version
2. **Dependency Installation** - Installs required build tools and libraries
3. **Source Compilation** - Compiles Apache with latest optimizations
4. **Module Selection** - Interactive module configuration menu
5. **Security Hardening** - Applies production-ready security settings
6. **Service Setup** - Configures systemd service and management tools

---

## 🎛️ **Available Modules**

### **🔥 Core Modules:**
| Module | Function | Use Case |
|--------|----------|----------|
| **mod_core** | Core server functionality | Basic web serving |
| **mod_so** | Dynamic shared object support | Module loading |
| **mod_log_config** | Logging configuration | Custom log formats |
| **mod_mime** | MIME type handling | Content type mapping |
| **mod_dir** | Directory index handling | Default file serving |
| **mod_alias** | URL aliasing | Path mapping |

### **⚡ Performance Modules:**
| Module | Function | Benefit |
|--------|----------|---------|
| **mod_cache** | Content caching | Reduce server load |
| **mod_deflate** | Response compression | Save bandwidth |
| **mod_expires** | Cache expiration control | Browser caching |
| **mod_headers** | HTTP header manipulation | Security and optimization |
| **mod_rewrite** | URL rewriting | Clean URLs and routing |
| **mod_proxy** | Reverse proxy capabilities | Load balancing |

### **🔒 Security Modules:**
| Module | Function | Security Feature |
|--------|----------|------------------|
| **mod_ssl** | SSL/TLS encryption | HTTPS support |
| **mod_security** | Web application firewall | Attack protection |
| **mod_auth** | Authentication | User access control |
| **mod_authz** | Authorization | Permission management |
| **mod_reqtimeout** | Request timeout control | DoS protection |
| **mod_unique_id** | Unique request IDs | Tracking and debugging |

### **🌟 Advanced Modules:**
| Module | Function | Advanced Feature |
|--------|----------|-----------------|
| **mod_status** | Server status monitoring | Real-time metrics |
| **mod_info** | Server information display | Configuration overview |
| **mod_suexec** | CGI script execution | User-specific execution |
| **mod_cgi** | CGI script support | Legacy applications |
| **mod_dav** | WebDAV support | File sharing |
| **mod_lua** | Lua scripting | Dynamic configuration |

### **⚙️ MPM (Multi-Processing Modules):**
| MPM | Architecture | Best For |
|-----|--------------|----------|
| **event** | Event-driven | High concurrent connections |
| **worker** | Hybrid thread/process | Balanced performance |
| **prefork** | Process-based | Compatibility and stability |

---

## 🔧 **Configuration Structure**

### **📁 Directory Layout:**
```bash
/etc/apache2/
├── apache2.conf              # Main configuration file
├── sites-available/          # Available virtual hosts
│   ├── 000-default.conf
│   ├── example.com.conf
│   └── api.example.com.conf
├── sites-enabled/            # Enabled virtual hosts
│   ├── 000-default.conf -> ../sites-available/000-default.conf
│   └── example.com.conf -> ../sites-available/example.com.conf
├── mods-available/           # Available module configurations
│   ├── ssl.conf
│   ├── rewrite.conf
│   ├── cache.conf
│   └── security.conf
├── mods-enabled/             # Enabled module configurations
│   ├── rewrite.conf -> ../mods-available/rewrite.conf
│   └── ssl.conf -> ../mods-available/ssl.conf
├── conf-available/           # Available configurations
│   └── security.conf
└── conf-enabled/             # Enabled configurations
    └── security.conf -> ../conf-available/security.conf
```

### **🎛️ Configuration Examples:**

#### **🌐 Basic Virtual Host:**
```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAdmin admin@example.com
    DocumentRoot "/var/www/example.com"
    
    ErrorLog "/var/log/apache2/example.com-error.log"
    CustomLog "/var/log/apache2/example.com-access.log" combined
    
    <Directory "/var/www/example.com">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

#### **🔒 SSL Configuration:**
```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot "/var/www/example.com"
    
    SSLEngine on
    SSLCertificateFile "/etc/letsencrypt/live/example.com/fullchain.pem"
    SSLCertificateKeyFile "/etc/letsencrypt/live/example.com/privkey.pem"
    
    # SSL Security Configuration
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    SSLHonorCipherOrder on
    SSLCompression off
    
    # Security Headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
</VirtualHost>
```

#### **⚡ Performance Optimization:**
```apache
# Enable compression
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
</Location>

# Enable caching
<IfModule mod_cache.c>
    CacheEnable disk /
    CacheRoot "/var/cache/apache2/mod_cache_disk"
    CacheDefaultExpire 3600
</IfModule>

# URL rewriting
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php [QSA,L]
</IfModule>
```

---

## 🛠️ **Management Tools**

### **🔧 Built-in Commands:**
```bash
# Monitor server status
apache-monitor

# Graceful reload configuration
apache-reload

# Backup configurations
apache-backup

# Service management
systemctl status apache2
systemctl start apache2
systemctl stop apache2
systemctl restart apache2
```

### **📊 Monitoring Features:**
- **Real-time Status** - Server uptime, connections, memory usage
- **Performance Metrics** - Request rates, response times, throughput
- **Error Monitoring** - Automatic error log analysis and alerts
- **Connection Tracking** - Active connections and client information
- **Resource Usage** - CPU, memory, and disk I/O statistics

### **🌐 Web-based Monitoring:**
- **Server Status** - `/server-status` (localhost only)
- **Server Info** - `/server-info` (localhost only)
- **ModSecurity Logs** - WAF activity and blocked requests
- **Performance Graphs** - Customizable monitoring dashboards

---

## 🔒 **Security Features**

### **🛡️ Built-in Security:**
```bash
Security Configurations Applied:
├── ✅ Secure file permissions (755/644)
├── ✅ Security headers (HSTS, XSS Protection, etc.)
├── ✅ Server version hiding
├── ✅ Request size limits (10MB default)
├── ✅ Access restrictions for sensitive files
├── ✅ Hidden file protection
├── ✅ Clickjacking prevention
├── ✅ MIME type sniffing prevention
├── ✅ TRACE method disabled
├── ✅ OPTIONS method restricted
└── ✅ .htaccess/.htpasswd protection
```

### **🔒 SSL/TLS Security:**
```bash
SSL Configuration Features:
├── ✅ TLS 1.2/1.3 only
├── ✅ Modern cipher suites
├── ✅ Perfect Forward Secrecy
├── ✅ HSTS with preload
├── ✅ OCSP Stapling support
├── ✅ Certificate pinning ready
├── ✅ Automatic HTTP→HTTPS redirect
└── ✅ SSL session caching
```

### **🛡️ Web Application Firewall:**
```bash
ModSecurity Protection:
├── 🛡️ SQL Injection detection
├── 🛡️ XSS attack prevention
├── 🛡️ File upload security
├── 🛡️ Bot and scanner blocking
├── 🛡️ Request size validation
├── 🛡️ HTTP method enforcement
├── 🛡️ IP-based blocking
└── 🛡️ Real-time threat detection
```

---

## 🚀 **Performance Optimization**

### **⚡ Caching Strategies:**
```bash
Caching Configuration:
├── 🗄️ File-based caching (mod_cache)
├── 🗜️ Response compression (mod_deflate)
├── ⏰ Cache expiration control (mod_expires)
├── 📊 Static file optimization
├── 🔧 Browser caching headers
├── 🚀 Memory-based caching
└── 📈 Cache hit ratio monitoring
```

### **📈 Performance Tuning:**
```bash
Optimization Settings:
├── 🔧 MPM Event for high concurrency
├── 📊 Connection pooling and keep-alive
├── ⚡ Gzip compression for text content
├── 🗄️ Disk caching for static files
├── 🔧 Thread/process optimization
├── 📊 Memory usage tuning
└── 🚀 HTTP/2 support
```

---

## 🔗 **Integration Examples**

### **🌐 Web Application Stack:**
```bash
Apache + PHP + MySQL:
├── 🌐 Apache (Web Server)
├── 🔧 PHP-FPM (Application Server)
├── 🗄️ MySQL/MariaDB (Database)
├── 🔒 Let's Encrypt (SSL Certificates)
└── 📊 Monitoring Tools
```

### **🔄 Reverse Proxy Setup:**
```bash
Apache as Reverse Proxy:
├── 🌐 Apache (Frontend)
├── 🐳 Docker Containers (Backend)
├── 📊 Node.js Applications
├── 🐍 Python Services
├── ☕ Java Applications
└── ⚖️ Load Balancing
```

### **📱 High-Traffic Site:**
```bash
Production Configuration:
├── ⚡ Apache (Static Files + Proxy)
├── 🗄️ Redis Cache (Session Storage)
├── 🗜️ CDN Integration (Content Delivery)
├── 📊 Load Balancing
├── 🔒 DDoS Protection
└── 📈 Real-time Monitoring
```

---

## 📊 **System Requirements**

### **🔧 Minimum Requirements:**
- **OS:** Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora
- **RAM:** 1GB (2GB recommended)
- **CPU:** 1 core (2+ cores recommended)
- **Disk:** 2GB free space (5GB recommended)
- **Network:** Port 80/443 access

### **📦 Dependencies:**
```bash
Build Dependencies:
├── 🔧 GCC/G++ (Compiler)
├── 📚 OpenSSL (SSL/TLS)
├── 🔤 PCRE (Regular Expressions)
├── 🗜️ Zlib (Compression)
├── 🌐 libxml2 (XML Support)
├── 🔄 APR/APR-Util (Apache Runtime)
├── 🐍 Lua (Scripting)
└── 🗄️ Database Libraries (Optional)
```

---

## 🛠️ **Troubleshooting**

### **🔧 Common Issues:**

#### **🚫 Server Won't Start:**
```bash
# Check configuration syntax
/opt/apache/bin/apachectl configtest

# Check error logs
tail -f /var/log/apache2/error.log

# Check service status
systemctl status apache2

# Check port usage
netstat -tlnp | grep :80
```

#### **🔒 SSL Certificate Issues:**
```bash
# Test SSL configuration
openssl s_client -connect your-domain.com:443

# Check certificate paths
ls -la /etc/letsencrypt/live/your-domain.com/

# Reload after certificate update
apache-reload
```

#### **⚡ Performance Issues:**
```bash
# Check server status
apache-monitor

# Analyze connections
ss -tn state established '( dport = :http or dport = :https )'

# Check memory usage
ps aux | grep apache2

# Monitor MPM status
curl http://localhost/server-status
```

#### **🔧 Module Issues:**
```bash
# List loaded modules
/opt/apache/bin/apachectl -M

# Check module configuration
apache2ctl -t -D DUMP_MODULES

# Enable/disable modules
a2enmod module_name
a2dismod module_name
```

---

## 🎯 **Best Practices**

### **✅ Production Configuration:**
1. **Security First** - Enable all security modules and headers
2. **Performance Tuning** - Configure appropriate MPM and caching
3. **Monitoring** - Set up log analysis and alerting
4. **Backup Strategy** - Regular configuration backups
5. **SSL/TLS** - Always use HTTPS in production
6. **Resource Limits** - Set appropriate connection and memory limits

### **🔒 Security Checklist:**
- [ ] Hide server version and signature
- [ ] Enable security headers
- [ ] Configure SSL/TLS properly
- [ ] Set file permissions correctly
- [ ] Enable access logging
- [ ] Configure firewall rules
- [ ] Regular security updates
- [ ] Monitor for suspicious activity
- [ ] Enable ModSecurity WAF
- [ ] Use .htaccess restrictions

### **⚡ Performance Checklist:**
- [ ] Enable appropriate MPM (Event for high traffic)
- [ ] Configure caching modules
- [ ] Enable compression
- [ ] Set proper expires headers
- [ ] Optimize KeepAlive settings
- [ ] Monitor resource usage
- [ ] Tune thread/process limits
- [ ] Enable HTTP/2 if possible

---

## 📞 **Support & Resources**

### **📚 Documentation:**
- **Official Apache Documentation:** https://httpd.apache.org/docs/
- **Configuration Reference:** https://httpd.apache.org/docs/current/mod/
- **Module Documentation:** https://httpd.apache.org/docs/current/mod/
- **Performance Tuning Guide:** https://httpd.apache.org/docs/2.4/misc/perf-tuning.html

### **🔧 Community Support:**
- **Apache HTTP Server Project:** https://httpd.apache.org/
- **User Mailing Lists:** Active community discussions
- **Stack Overflow:** Technical questions and answers
- **Server Fault:** System administration discussions
- **Apache Forums:** Community support and help

### **📊 Monitoring Tools:**
- **Built-in Status Module:** `/server-status`
- **Built-in Info Module:** `/server-info`
- **ModSecurity Console:** WAF monitoring
- **Apache JMeter** - Load testing
- **New Relic/DataDog** - APM integration
- **Prometheus + Grafana** - Metrics collection

---

## 🔄 **Updates & Maintenance**

### **📦 Regular Updates:**
```bash
# Check for updates
cd /tmp
wget https://httpd.apache.org/download.cgi

# Backup before update
apache-backup

# Update process (manual)
./apache-install.sh
```

### **🔧 Maintenance Tasks:**
```bash
# Log rotation (automatic via logrotate)
# Configuration backup (weekly recommended)
# SSL certificate renewal (via Let's Encrypt)
# Performance monitoring (daily)
# Security audits (monthly)
# Module updates (as needed)
```

---

## 🎊 **Conclusion**

**Apache HTTP Server provides unparalleled flexibility, power, and reliability for web hosting needs.** With its extensive module ecosystem and proven track record, it's suitable for:

- **Enterprise websites** requiring robust security and performance
- **Development environments** with flexible configuration options
- **Legacy applications** needing compatibility and stability
- **High-traffic sites** with advanced caching and proxy capabilities
- **Secure applications** requiring comprehensive security features

**This installation script provides a production-ready Apache setup with:**
✅ **Optimized performance** - Caching, compression, and MPM tuning
✅ **Enterprise security** - SSL/TLS, ModSecurity, and hardening
✅ **Management tools** - Monitoring, backup, and maintenance
✅ **Module ecosystem** - Extensive functionality
✅ **Integration ready** - Works with existing autoinstalls

**🚀 Your powerful and flexible web server is ready for production!**
