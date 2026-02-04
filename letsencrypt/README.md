### 🔐 Let's Encrypt SSL Certificate Manager
**Automated SSL certificate management with multi-webserver support**
![https://img.shields.io/badge/certbot-latest-blue](https://img.shields.io/badge/certbot-latest-blue)
![https://img.shields.io/badge/webservers-nginx%20%7C%20apache%20%7C%20lighttpd-green](https://img.shields.io/badge/webservers-nginx%20%7C%20apache%20%7C%20lighttpd-green)
![https://img.shields.io/badge/security-hardened-brightgreen](https://img.shields.io/badge/security-hardened-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

**Features:**
- ✅ Automatic web server detection (Nginx, Apache, Lighttpd)
- ✅ Domain discovery from existing vhost configurations
- ✅ One-click SSL certificate generation and configuration
- ✅ Automatic HTTP to HTTPS redirects
- ✅ Security headers and cipher suite hardening
- ✅ Clean cron management (single renewal script)
- ✅ Certificate backup and restoration
- ✅ Multi-domain support with automatic renewal
- ✅ Production-ready SSL configurations
- ✅ Comprehensive logging and monitoring

**Installation:**
```bash
cd letsencrypt/
sudo ./letsencrypt-install.sh
```

**Quick Start:**
1. Install and Configure Let's Encrypt (Option 1)
2. Configure SSL Certificate for Domain (Option 2)
3. Configure Auto-Renewal (Option 6)

---

## 🎛️ **Menu Options:**

### **1) Install and Configure Let's Encrypt**
- Auto-detects OS and installs Certbot
- Supports Debian/Ubuntu (Snap) and RHEL/CentOS (YUM/DNF)
- Configures default settings and directories

### **2) Configure SSL Certificate for Domain**
- Scans all vhost directories for domains without SSL
- Supports multiple vhost locations:
  - `/etc/nginx/sites-available/`
  - `/etc/nginx/conf.d/`
  - `/etc/apache2/sites-available/`
  - `/etc/httpd/conf.d/`
  - `/etc/lighttpd/conf-enabled/`
  - Custom user directories
- Automatically generates certificates and configures SSL
- Adds HTTP to HTTPS redirects
- Implements security headers and hardening

### **3) List Available Domains (without SSL)**
- Shows all detected domains without SSL configuration
- Displays vhost file paths for verification
- Real-time scanning of web server configurations

### **4) List Configured SSL Domains**
- Shows all domains with active SSL certificates
- Displays certificate expiry dates
- Certificate health monitoring

### **5) Manual Certificate Renewal**
- Renew all certificates or specific domains
- Immediate renewal option for testing
- Web server reload after renewal

### **6) Configure Auto-Renewal**
- Single cron job for clean management
- Multiple scheduling options:
  - Daily at 2:00 AM, 3:00 AM, or 4:00 AM
  - Weekly (Sunday at 3:00 AM)
  - Monthly (1st at 3:00 AM)
- Automatic email notifications
- 30-day expiry threshold

### **7) Backup Certificates**
- Complete certificate archive creation
- Timestamped backup files
- Pre-uninstall automatic backup

### **8) Uninstall Let's Encrypt**
- Complete removal with backup
- Cleans up cron jobs and certificates
- Preserves configurations in backup

---

## 🔧 **Web Server Integration:**

### **🚀 Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Security Hardening
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
}
```

### **🅰️ Apache Configuration:**
```apache
<VirtualHost *:80>
    ServerName example.com
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName example.com
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
    
    # Security Headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options DENY
</VirtualHost>
```

### **💡 Lighttpd Configuration:**
```lighttpd
$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/letsencrypt/live/example.com/privkey.pem"
    ssl.ca-file = "/etc/letsencrypt/live/example.com/fullchain.pem"
    
    # Security Headers
    setenv.add-response-header = (
        "Strict-Transport-Security" => "max-age=31536000; includeSubDomains",
        "X-Frame-Options" => "DENY"
    )
}

# HTTP to HTTPS redirect
$HTTP["host"] =~ "example.com" {
    $SERVER["socket"] == ":80" {
        url.redirect = ( "^/(.*)" => "https://example.com/$1" )
    }
}
```

---

## 📁 **Directory Structure:**

```bash
/opt/letsencrypt/
├── letsencrypt-renew-all.sh    # Main renewal script
├── conf/
│   ├── domains.list            # Configured domains
│   ├── email.conf              # Email configuration
│   └── renewal-config.sh       # Renewal settings
├── logs/
│   └── renewal.log             # Renewal logs
├── backups/
│   └── letsencrypt_backup_*.tar.gz
└── /etc/letsencrypt/           # Certbot certificates
    ├── live/
    ├── archive/
    └── renewal/
```

---

## 🔄 **Automatic Renewal System:**

### **📅 Cron Job Management:**
```bash
# Single clean cron entry
0 3 * * * /opt/letsencrypt/letsencrypt-renew-all.sh > /var/log/letsencrypt-renewal.log 2>&1
```

### **🧪 Renewal Process:**
1. **Check expiry** (30-day threshold)
2. **Renew certificates** if needed
3. **Reload web server** automatically
4. **Log all activities**
5. **Send email summary** (if configured)

### **📊 Monitoring Features:**
- Certificate expiry tracking
- Renewal success/failure logging
- Email notifications for renewals
- Web server reload verification

---

## 🛡️ **Security Features:**

### **🔒 SSL Hardening:**
- **TLS Protocols:** TLSv1.2 and TLSv1.3 only
- **Cipher Suites:** Strong modern ciphers
- **HSTS:** Strict Transport Security headers
- **Security Headers:** X-Frame-Options, X-Content-Type-Options, XSS Protection

### **🔐 File Permissions:**
- **Certificates:** root:ssl-cert 644
- **Private Keys:** root:ssl-cert 600
- **Configuration:** root:root 644
- **Scripts:** root:root 755

### **🛡️ Web Server Security:**
- Configuration testing before reload
- Graceful web server reloads
- Backup of original configurations
- Rollback capability

---

## 📋 **Management Commands:**

### **🔍 Certificate Monitoring:**
```bash
# Check all certificates
/opt/letsencrypt/letsencrypt-renew-all.sh

# Check renewal log
tail -f /var/log/letsencrypt-renewal.log

# List certificates
ls -la /etc/letsencrypt/live/
```

### **🧪 Manual Operations:**
```bash
# Test certificate renewal
certbot renew --dry-run

# Check specific certificate
openssl x509 -in /etc/letsencrypt/live/domain.com/fullchain.pem -noout -dates

# Verify SSL configuration
nginx -t  # or apache2ctl configtest
```

### **📁 Backup Operations:**
```bash
# List backups
ls -la /opt/letsencrypt/backups/

# Restore from backup
tar -xzf letsencrypt_backup_YYYYMMDD_HHMMSS.tar.gz -C /
```

---

## 🚨 **Troubleshooting:**

### **🔍 Common Issues:**

#### **Certificate Generation Failed:**
```bash
# Check log file
tail -f /tmp/letsencrypt-install.log

# Verify domain DNS resolution
nslookup domain.com

# Check web root accessibility
curl -I http://domain.com/.well-known/acme-challenge/
```

#### **Web Server Configuration Error:**
```bash
# Test configuration
nginx -t
apache2ctl configtest

# Check syntax errors
nginx -T | grep -i ssl
```

#### **Auto-Renewal Not Working:**
```bash
# Check cron job
crontab -l | grep letsencrypt

# Test renewal script manually
/opt/letsencrypt/letsencrypt-renew-all.sh

# Check renewal log
tail -f /var/log/letsencrypt-renewal.log
```

---

## 📊 **System Requirements:**

### **🔧 Minimum Requirements:**
- **OS:** Debian 9+, Ubuntu 18+, RHEL 7+, CentOS 7+
- **Web Server:** Nginx, Apache2, or Lighttpd
- **Root Access:** Required for installation
- **Domain:** Valid domain name with DNS A record
- **Port 80:** Must be accessible for validation
- **Port 443:** Must be open for SSL traffic

### **📦 Dependencies:**
- **Certbot:** Auto-installed
- **OpenSSL:** For certificate operations
- **Systemd:** For service management
- **Cron:** For automatic renewal

---

## 🎯 **Best Practices:**

### **✅ Recommended Configuration:**
1. **Use option 1** to install Let's Encrypt first
2. **Configure email** for renewal notifications
3. **Set up auto-renewal** (daily at 3:00 AM recommended)
4. **Test certificates** after configuration
5. **Monitor renewal logs** regularly
6. **Backup certificates** before major changes

### **🛡️ Security Recommendations:**
1. **Keep system updated** for latest security patches
2. **Use strong passwords** for web server management
3. **Monitor certificate expiry** dates
4. **Test SSL configuration** with online tools
5. **Implement firewall rules** for ports 80/443
6. **Regular backups** of certificates and configurations

---

## 📞 **Support:**

### **📚 Documentation:**
- **Installation Log:** `/tmp/letsencrypt-install.log`
- **Renewal Log:** `/var/log/letsencrypt-renewal.log`
- **Certificate Location:** `/etc/letsencrypt/live/`

### **🔗 Useful Links:**
- **Let's Encrypt:** https://letsencrypt.org/
- **Certbot Documentation:** https://certbot.eff.org/docs/
- **SSL Labs Test:** https://www.ssllabs.com/ssltest/

---

**This Let's Encrypt manager provides enterprise-grade SSL certificate management with automatic detection, configuration, and renewal for all major web servers!** 🚀🔒✨
