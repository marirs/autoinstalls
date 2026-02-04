# Nginx AutoInstall & Virtual Host Management

- Compile and install Nginx from source with optional modules. Modified from [here](https://github.com/Angristan/nginx-autoinstall)
- Interactive virtual host generator with advanced security and SSL/TLS support

---

## 🌐 Nginx Virtual Host Generator

**Interactive tool for generating and managing Nginx virtual hosts with comprehensive security features**

![https://img.shields.io/badge/nginx-virtual%20host%20generator-blue](https://img.shields.io/badge/nginx-virtual%20host%20generator-blue)
![https://img.shields.io/badge/ssl%2Ftls-enabled-green](https://img.shields.io/badge/ssl%2Ftls-enabled-green)
![https://img.shields.io/badge/security-hardened-red](https://img.shields.io/badge/security-hardened-red)
![https://img.shields.io/badge/ipv4%2Fipv6-ready-purple](https://img.shields.io/badge/ipv4%2Fipv6-ready-purple)

### ✨ Key Features

#### **🔧 Virtual Host Management**
- ✅ **Interactive Menu System** - User-friendly CLI interface
- ✅ **Generate New Virtual Hosts** - Complete configuration generation
- ✅ **Enable/Disable Virtual Hosts** - Simple symbolic link management
- ✅ **List All Virtual Hosts** - Status overview (Enabled/Disabled)
- ✅ **Configuration Testing** - Validates Nginx config before applying
- ✅ **Automatic Nginx Reload** - Safe service restart on success

#### **🌐 Network Configuration**
- ✅ **IP Address Detection** - Automatically detects all IPv4 and IPv6 addresses
- ✅ **Dual Stack Support** - Full IPv4/IPv6 configuration
- ✅ **Selective Binding** - Listen on specific IPs or all interfaces
- ✅ **Domain Aliases** - Multiple server names support

#### **🔒 Security & SSL/TLS**
- ✅ **Modern SSL/TLS** - TLSv1.2, TLSv1.3 with strong ciphers
- ✅ **HTTP to HTTPS Redirect** - Optional secure redirect
- ✅ **HSTS Support** - HTTP Strict Transport Security
- ✅ **Security Headers** - X-Frame-Options, CSP, XSS Protection
- ✅ **Rate Limiting** - Configurable request rate limiting
- ✅ **Common Exploit Protection** - Block malicious request patterns

#### **📁 Document Root Management**
- ✅ **Automatic Directory Creation** - Creates web root with proper permissions
- ✅ **Default Index Page** - Professional welcome page with SSL status
- ✅ **Permission Setup** - www-data ownership, 755 permissions
- ✅ **PHP Support** - FastCGI PHP processing (optional)

### 🚀 Quick Start

```bash
# Navigate to nginx directory
cd nginx/

# Run the virtual host generator
sudo ./nginx-vhost-generator.sh

# Follow the interactive menu:
# 1. Generate new virtual host
# 2. Enable available virtual host
# 3. List all virtual hosts
# 4. Test Nginx configuration
# 5. Exit
```

### 📋 Virtual Host Generation Process

#### **Step 1: IP Address Selection**
```
Available IPv4 addresses:
  1. 192.168.1.100
  2. 10.0.0.15

Available IPv6 addresses:
  1. 2001:db8::1
  2. fe80::1

Select IP address for the virtual host:
  0. Listen on all addresses (default)
  1. 192.168.1.100 (IPv4)
  2. 10.0.0.15 (IPv4)
  3. 2001:db8::1 (IPv6)
  4. fe80::1 (IPv6)
```

#### **Step 2: Configuration Details**
```
Virtual Host Configuration:
Enter server name (domain): example.com
Enter alternative server names: www.example.com api.example.com
Enter document root path: /var/www/example.com/html

SSL Configuration:
Enable SSL/TLS? (y/n): y
SSL certificate path: /etc/ssl/certs/example.com.crt
SSL private key path: /etc/ssl/private/example.com.key
Enable HTTPS only (redirect HTTP to HTTPS)? (y/n): y

Additional Features:
Enable PHP support? (y/n): y
Enable security headers? (y/n): y
Enable rate limiting? (y/n): y
Rate limit requests per second: 10
Rate limit burst: 20
```

#### **Step 3: Automatic Setup**
```
Generating virtual host configuration...
Creating document root directory...
Testing Nginx configuration...
✓ Nginx configuration test passed
Reloading Nginx...
✓ Nginx reloaded successfully

✓ Virtual host generated successfully!
Configuration file: /etc/nginx/sites-available/example.com
Document root: /var/www/example.com/html
SSL Certificate: /etc/ssl/certs/example.com.crt
SSL Private Key: /etc/ssl/private/example.com.key
```

### 🔧 Generated Configuration Examples

#### **HTTP + HTTPS Virtual Host**
```nginx
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server block
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL configuration
    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Rate limiting
    limit_req zone=$server_name burst=20 nodelay;
    
    # Document root
    root /var/www/example.com/html;
    index index.html index.htm index.php;
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
    
    # Security
    server_tokens off;
}
```

### 📊 Virtual Host Management

#### **Enable Available Virtual Hosts**
```bash
sudo ./nginx-vhost-generator.sh
# Choose option 2

Disabled virtual hosts (available but not enabled):
  1. example.com
  2. test.domain.com
  3. api.example.org

Enter the number of the virtual host to enable (0 to cancel): 1
Enabling virtual host: example.com
✓ Virtual host enabled: example.com
✓ Nginx configuration test passed
✓ Nginx reloaded successfully
✓ Virtual host is now active
```

#### **List All Virtual Hosts**
```bash
sudo ./nginx-vhost-generator.sh
# Choose option 3

Available virtual hosts:
  1. example.com - Enabled
  2. test.domain.com - Disabled
  3. api.example.org - Disabled
  4. default - Enabled
```

### 🛡️ Security Features

#### **SSL/TLS Configuration**
- **Modern Protocols**: TLSv1.2 and TLSv1.3 only
- **Strong Ciphers**: ECDHE with AES-256-GCM
- **Perfect Forward Secrecy**: Ephemeral key exchange
- **HSTS**: HTTP Strict Transport Security
- **SSL Session Optimization**: 1-day timeout, shared cache

#### **Security Headers**
- **X-Frame-Options**: Prevent clickjacking
- **X-XSS-Protection**: XSS attack prevention
- **X-Content-Type-Options**: MIME-type sniffing protection
- **Content Security Policy**: XSS and data injection protection
- **Referrer Policy**: Control referrer information

#### **Rate Limiting**
- **Configurable RPS**: Requests per second limit
- **Burst Handling**: Temporary traffic spikes
- **Per-Vhost Zones**: Isolated rate limiting per domain

### 📁 File Structure

```
/etc/nginx/
├── sites-available/
│   ├── example.com          # Generated virtual host
│   ├── test.domain.com      # Available but disabled
│   └── default              # Default configuration
├── sites-enabled/
│   ├── example.com -> ../sites-available/example.com
│   └── default -> ../sites-available/default
├── ssl/
│   ├── certs/
│   │   └── example.com.crt
│   └── private/
│       └── example.com.key
└── logs/
    ├── example.com_access.log
    └── example.com_error.log
```

### 🔍 Error Handling & Validation

#### **Pre-flight Checks**
- ✅ Nginx installation verification
- ✅ Directory existence validation
- ✅ Root privilege checking
- ✅ SSL certificate file validation

#### **Safety Features**
- ✅ Configuration test before enabling virtual hosts
- ✅ Automatic rollback on test failure
- ✅ Detailed logging to `/tmp/nginx-vhost-generator.log`
- ✅ Clear error messages and user guidance

### 📝 Usage Examples

#### **E-commerce Site with SSL**
```bash
# Generate virtual host for online store
sudo ./nginx-vhost-generator.sh
# Domain: store.example.com
# SSL: Enabled
# HTTPS Only: Yes
# PHP: Enabled
# Security Headers: Enabled
# Rate Limiting: 5 RPS, 10 burst
```

#### **API Server**
```bash
# Generate virtual host for REST API
sudo ./nginx-vhost-generator.sh
# Domain: api.example.com
# SSL: Enabled
# HTTPS Only: Yes
# PHP: Disabled
# Security Headers: Enabled
# Rate Limiting: 20 RPS, 50 burst
```

#### **Development Environment**
```bash
# Generate virtual host for development
sudo ./nginx-vhost-generator.sh
# Domain: dev.example.local
# SSL: Disabled
# PHP: Enabled
# Security Headers: Disabled
# Rate Limiting: Disabled
```

### 📋 Requirements

- **Nginx**: Must be installed first
- **Root Privileges**: Required for file operations
- **OpenSSL**: For SSL certificate handling
- **PHP-FPM**: Optional, for PHP support

### 📚 Additional Resources

- [Nginx Official Documentation](https://nginx.org/en/docs/)
- [SSL/TLS Configuration Guide](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Security Best Practices](https://nginx.org/en/docs/http/security.html)

---

## 🔧 Nginx AutoInstall (Original)

```

Welcome to the nginx-autoinstall script.

What do you want to do?
   1) Install or update Nginx
   2) Install Bad Bot Blocker for Nginx
   3) Uninstall Nginx
   4) Update the script
   5) Exit

Select an option [1-5]: 1

This script will install Nginx with some optional modules.

Do you want to install Nginx stable or mainline?
   1) Stable 1.16.1
   2) Mainline 1.17.9

Select an option [1-2]: 2

Please tell me which modules you want to install.
If you select none, Nginx will be installed with its default modules.

Modules to install :
       PageSpeed 1.13.35.2 [y/n]: y
       ngx_cache_purge [y/n]: y
       Brotli [y/n]: y
       Http Redis 2 [y/n]: n
       SRCache (provides transparent caching layer) [y/n]: y
       MEMC (Extended ver of standard Memcached) [y/n]: y
       Nginx virtual host traffic status [y/n]: n
       GeoIP 2 [y/n]: y
       LDAP Auth  [y/n]: n
       Headers More 0.33 [y/n]: y
       Fancy index [y/n]: y
       SET_MISC Content filtering [y/n]: y
       PCRE [y/n]: y
       ZLIB [y/n]: y
       Cloudflare's TLS Dynamic Record Resizing patch [y/n]: y

Choose your Web Application Firewall (WAF):
   1) ModSecurity (Preferred)
   2) NAXSI (Does not play well with HTTP2)
   3) None

Select an option [1-3]: 1
      > Enable nginx ModSecurity? [y/n]: y

Choose your OpenSSL implementation :
   1) System's OpenSSL (1.1.1d)
   2) OpenSSL 1.1.1f from source
   3) LibreSSL 3.0.2 from source 

Select an option [1-3]: 2

Nginx is ready to be installed, press any key to continue...

       Installing dependencies        [OK]
       Geoip/Modsec dependencies      [OK]
       Geoip/Modsec deps Install      [OK]
       Downloading ngx_pagespeed      [OK]
       Downloading libbrotli          [OK]
       Configuring libbrotli          [OK]
       Compiling libbrotli            [OK]
       Installing libbrotli           [OK]
       Downloading ngx_brotli         [OK]
       Downloading ModSecurity        [OK]
       Configuring ModSecurity        [OK]
       Compiling ModSecurity          [OK]
       Installing ModSecurity         [OK]
       Enabling ModSecurity           [OK]
       ModSecurity Nginx Module       [OK]
       Downloading ngx_headers_more   [OK]
       Downloading SET MISC           [OK]
       Downloading PCRE Module        [OK]
       Downloading ZLIB Module        [OK]
       Downloading SRCache            [OK]
       Downloading MEMC               [OK]
       Downloading GeoIP 2            [OK]
       Downloading GeoIP 2 databases  [FAIL - You need to download manually & place in /etc/nginx/geoip2/]
       Downloading ngx_cache_purge    [OK]
       Downloading OpenSSL            [OK]
       Configuring OpenSSL            [OK]
       Downloading Nginx              [OK]
       Downloading Nginx Devel Kit    [OK]
       TLS Dynamic Records support    [OK]
       Configuring Nginx              [OK]
       Compiling Nginx                [OK]
       Installing Nginx               [OK]
       Restarting Nginx               [OK]
       Blocking nginx from APT        [OK]
       Removing Nginx files           [OK]

       Installation successful !

       Installation log: /tmp/nginx-install.log         
```

## Compatibility

* x86, x64, arm*
* Debian 8 and later
* Ubuntu 16.04 and later

## Features

- Latest mainline or stable version, from source
- Optional modules (see below)
- Removed useless modules
- [Custom nginx.conf](https://github.com/marirs/autoinstalls/blob/master/conf/nginx.conf) (default does not work)
- [Init script for systemd](https://github.com/marirs/autoinstalls/blob/master/conf/nginx.service) (not provided by default)
- [Logrotate conf](https://github.com/marirs/autoinstalls/blob/master/conf/nginx-logrotate) (not provided by default)

### Optional modules/features

- [LDAP Authentication](https://github.com/kvspb/nginx-auth-ldap) Allow Nginx to authenticate via LDAP
- [MODSecurity](https://github.com/SpiderLabs/ModSecurity-nginx) ModSecurity WAF
- [NAXSI WAF](https://github.com/nbs-system/naxsi) Web Application Firewall for Nginx
- [Nginx Virtual Host Traffic Status](https://github.com/vozlt/nginx-module-vts)
- [LibreSSL from source](http://www.libressl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [OpenSSL from source](https://www.openssl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [ngx_pagespeed](https://github.com/pagespeed/ngx_pagespeed) (Google performance module)
- [ngx_brotli](https://github.com/google/ngx_brotli) (Brotli compression algorithm)
- [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module) (Custom HTTP headers)
- [GeoIP 2](https://www.nginx.com/products/nginx/modules/geoip2/) (GeoIP module and databases)
- [GeoIP](http://dev.maxmind.com/geoip/geoip2/geolite2/) (GeoIP module and databases)
- Cloudflare's TLS Dynamic Records Resizing patch
- [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge) (Purge content from FastCGI, proxy, SCGI and uWSGI caches)
- Fancy Index
- [Http Redis 2](https://www.nginx.com/resources/wiki/modules/redis/)
- PCRE
- ZLIB
- SRCache
- MEMC

## Install Nginx

Just download and execute the script :
```
wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx-install.sh
chmod +x nginx-autoinstall.sh
./nginx-autoinstall.sh
```

You can check [configuration examples](https://github.com/marirs/autoinstalls/tree/master/conf) for the custom modules.

## Uninstall Nginx

Just select the option when running the script :

![update](https://lut.im/Hj7wJKWwke/WZqeHT1QwwGfKXFf.png)

You have te choice to delete the logs and the conf.

## Update Nginx

To update Nginx, run the script and install Nginx again. It will overwrite current Nginx files and/or modules.

## Update the script

The update feature downloads the script from this repository, and overwrite the current `nginx-autoinstall.sh` file in the working directory. This allows you to get the latest features, bug fixes, and module versions automatically.

![update](https://lut.im/uQSSVxAz09/zhZRuvJjZp2paLHm.png)

## Log file

A log file is created when running the script. It is located at `/tmp/nginx-install.log`.


## LICENSE

GPL v3.0

