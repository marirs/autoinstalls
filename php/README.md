# PHP Installation & Configuration

**Comprehensive PHP installation script with multi-version support, FPM configuration, and 40+ extensions**

![https://img.shields.io/badge/php-8.3%20%7C%208.2%20%7C%208.1%20%7C%208.0%20%7C%207.4-blue](https://img.shields.io/badge/php-8.3%20%7C%208.2%20%7C%208.1%20%7C%208.0%20%7C%207.4-blue)
![https://img.shields.io/badge/php--fpm-enabled-green](https://img.shields.io/badge/php--fpm-enabled-green)
![https://img.shields.io/badge/extensions-40%2B-brightgreen](https://img.shields.io/badge/extensions-40%2B-brightgreen)
![https://img.shields.io/badge/nginx%20%7C%20apache-integrated-purple](https://img.shields.io/badge/nginx%20%7C%20apache-integrated-purple)
![https://img.shields.io/badge/redis%20%7C%20mongodb%20%7C%20mysql-ready-orange](https://img.shields.io/badge/redis%20%7C%20mongodb%20%7C%20mysql-ready-orange)

---

## ✨ Features

### 🚀 Multi-Version Support
- ✅ **PHP 8.3** - Latest stable release with performance improvements
- ✅ **PHP 8.2** - Stable version with modern features
- ✅ **PHP 8.1** - Mature version with extensive ecosystem
- ✅ **PHP 8.0** - LTS version with long-term support
- ✅ **PHP 7.4** - Legacy version for compatibility

### 🔧 Advanced Configuration
- ✅ **PHP-FPM** - FastCGI Process Manager with performance tuning
- ✅ **Unix Socket** - High-performance same-server communication
- ✅ **TCP Port** - Remote connection and load balancing support
- ✅ **Webserver Integration** - Automatic Nginx and Apache configuration
- ✅ **Security Hardening** - Production-ready security settings

### 📦 Comprehensive Extensions (40+)

#### **🗄️ Database Extensions**
- ✅ **Redis** - In-memory data structure store and caching
- ✅ **MongoDB** - NoSQL document database driver
- ✅ **MySQL/MariaDB** - Relational database support
- ✅ **PostgreSQL** - Advanced relational database
- ✅ **SQLite3** - Lightweight embedded database

#### **🔒 Security & Encryption**
- ✅ **Sodium** - Modern cryptography (encryption, signing, passwords)
- ✅ **GMP** - Arbitrary precision mathematics for cryptography

#### **🖼️ Image & Media Processing**
- ✅ **GD** - Image manipulation (resize, crop, filters, watermarks)
- ✅ **ImageMagick** - Advanced image processing and conversion
- ✅ **EXIF** - Image metadata extraction and manipulation

#### **📝 Text & Data Processing**
- ✅ **JSON** - JavaScript Object Notation processing
- ✅ **Tokenizer** - PHP source code tokenization
- ✅ **ctype** - Character type checking and validation
- ✅ **iconv** - Character set conversion (UTF-8, ISO, etc.)
- ✅ **mbstring** - Multi-byte string handling (Unicode, Asian languages)

#### **🌐 XML & Web Services**
- ✅ **DOM** - Document Object Model for XML/HTML manipulation
- ✅ **SimpleXML** - Easy XML parsing and traversal
- ✅ **XMLWriter** - XML document generation
- ✅ **XMLReader** - Efficient XML parsing
- ✅ **SOAP** - Web services protocol support
- ✅ **XML-RPC** - Remote procedure calling via XML

#### **⚙️ System & File Operations**
- ✅ **zlib** - Data compression and decompression
- ✅ **PCRE** - Perl Compatible Regular Expressions
- ✅ **hash** - Message digest framework (SHA, MD5, etc.)
- ✅ **filter** - Data validation and sanitization
- ✅ **fileinfo** - File type detection and metadata
- ✅ **calendar** - Calendar functions and conversions

#### **🔧 Process Control & IPC**
- ✅ **pcntl** - Process control (signals, forking, execution)
- ✅ **posix** - POSIX system functions
- ✅ **shmop** - Shared memory operations
- ✅ **sysvmsg** - System V message queues
- ✅ **sysvsem** - System V semaphores
- ✅ **sysvshm** - System V shared memory

### 🌐 OS Support
- ✅ **Ubuntu** - 18.04, 20.04, 22.04, 24.04
- ✅ **Debian** - 9.x, 10.x, 11.x, 12.x, 13.x
- ✅ **CentOS/RHEL** - 7, 8, 9
- ✅ **Rocky Linux/AlmaLinux** - 8, 9
- ✅ **Fedora** - Latest versions

---

## 🚀 Quick Start

### Installation
```bash
# Navigate to PHP directory
cd php/

# Run the installation script
sudo ./php-install.sh

# Follow the interactive prompts:
# 1. Select PHP version (8.3, 8.2, 8.1, 8.0, 7.4)
# 2. Choose FPM type (Unix Socket or TCP Port)
# 3. Configure webserver integration (optional)
```

### Interactive Installation Process
```
Available PHP versions:
  1. 8.3
  2. 8.2 (default)
  3. 8.1
  4. 8.0
  5. 7.4

Select PHP version (1-5) [5 for default]: 2
Selected PHP version: 8.2

PHP-FPM Configuration Type:
  1. Unix Socket (recommended for same server)
  2. TCP Port (recommended for remote connections)

Select FPM type (1-2) [1]: 1
Selected: Unix Socket

Detecting installed webservers...
✓ Nginx detected
✓ Apache2 detected

Configure PHP with detected webservers? (y/n): y
```

---

## 📋 Detailed Features

### 🔧 PHP-FPM Configuration

#### **Unix Socket Configuration**
```ini
listen = /run/php/php8.2-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
```

#### **TCP Port Configuration**
```ini
listen = 127.0.0.1:9000
```

#### **Performance Tuning**
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### 🛡️ Security Configuration

#### **PHP.ini Security Settings**
```ini
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M
display_errors = Off
display_startup_errors = Off
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
```

#### **OPcache Optimization**
```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
```

### 🌐 Webserver Integration

#### **Nginx Configuration**
```nginx
# PHP-FPM Upstream
upstream php8.2 {
    server unix:/run/php/php8.2-fpm.sock;
}

# PHP Location Block
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

#### **Apache Configuration**
```apache
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/"
</FilesMatch>

<Proxy fcgi://localhost/>
    ProxySet connectiontimeout=5 timeout=240
</Proxy>
```

---

## 🧪 Testing & Validation

### Automatic Test Site
The script creates a comprehensive test site at `http://php-test.local`:

#### **Main Test Page (`/`)**
- ✅ PHP version information
- ✅ Extension status indicators
- ✅ Database connectivity testing
- ✅ Real-time extension validation

#### **Extension Testing (`/test-extensions.php`)**
- ✅ Detailed extension information
- ✅ Version numbers and available classes
- ✅ Function lists and capabilities
- ✅ Visual status indicators

#### **PHP Info (`/php-info`)**
- ✅ Complete PHP configuration
- ✅ Loaded modules overview
- ✅ Environment variables

#### **PHP-FPM Status (`/php-status`)**
- ✅ FPM process status
- ✅ Performance metrics
- ✅ Connection statistics

### Command Line Testing
```bash
# Test PHP CLI
php8.2 -v

# Test PHP-FPM status
systemctl status php8.2-fpm

# Test specific extensions
php8.2 -m | grep redis
php8.2 -m | grep mongodb
php8.2 -m | grep sodium

# View all loaded extensions
php8.2 -m
```

---

## 📁 File Structure

### Configuration Files
```
/etc/php/8.2/
├── fpm/
│   ├── php-fpm.conf              # Main FPM configuration
│   ├── php-fpm.conf.backup       # Original backup
│   ├── pool.d/
│   │   ├── www.conf              # Pool configuration
│   │   └── www.conf.backup       # Original backup
│   └── php.ini                   # PHP configuration
├── cli/
│   └── php.ini                   # CLI PHP configuration
└── mods-available/
    ├── mongodb.ini               # MongoDB extension
    ├── redis.ini                 # Redis extension
    ├── imagick.ini               # ImageMagick extension
    └── sodium.ini                # Sodium extension
```

### Webserver Integration
```
/etc/nginx/
├── conf.d/
│   └── php-upstream.conf         # PHP upstream configuration
├── snippets/
│   └── php8.2.conf              # PHP location snippet
└── sites-available/
    └── php-test                  # Test virtual host

/var/www/php-test/
├── index.php                     # Main test page
└── test-extensions.php           # Extension testing page
```

### Log Files
```
/var/log/
└── php8.2-fpm.log                # PHP-FPM error log

/tmp/
└── php-install.log               # Installation log
```

---

## 🔄 Service Management

### PHP-FPM Service Commands
```bash
# Start PHP-FPM
sudo systemctl start php8.2-fpm

# Stop PHP-FPM
sudo systemctl stop php8.2-fpm

# Restart PHP-FPM
sudo systemctl restart php8.2-fpm

# Check status
sudo systemctl status php8.2-fpm

# Enable on boot
sudo systemctl enable php8.2-fpm

# View logs
sudo journalctl -u php8.2-fpm -f
```

### Configuration Reload
```bash
# Test configuration
sudo php8.2-fpm -t

# Reload configuration
sudo systemctl reload php8.2-fpm

# Restart webservers after PHP changes
sudo systemctl restart nginx
sudo systemctl restart apache2
```

---

## 📊 Usage Examples

### Framework Support

#### **Laravel**
```bash
# All required extensions installed
✓ PHP 8.2+ with required extensions
✓ MySQL/PostgreSQL support
✓ Redis for caching and sessions
✓ Fileinfo for file uploads
✓ mbstring for Unicode support
✓ tokenizer for performance
```

#### **WordPress**
```bash
# Complete WordPress environment
✓ MySQL/MariaDB database support
✓ GD for image processing
✅ XML-RPC for pingbacks and trackbacks
✓ curl for HTTP requests
✓ hash for security
✓ filter for data validation
```

#### **Symfony**
```bash
# Enterprise framework requirements
✓ PHP 8.1+ with modern extensions
✓ PCRE for routing
✓ JSON for API responses
✓ intl for internationalization
✓ ctype for validation
✓ dom for XML processing
```

### Application Examples

#### **E-commerce Platform**
```bash
# Online store requirements
✓ MySQL for product catalog
✓ Redis for session storage and caching
✓ GD for product image processing
✓ Sodium for payment encryption
✓ SOAP for payment gateway integration
✓ EXIF for product image metadata
```

#### **API Backend**
```bash
# RESTful API server
✓ PostgreSQL for data storage
✓ Redis for rate limiting and caching
✓ JSON for API responses
✓ MongoDB for document storage
✓ sodium for JWT token security
✓ curl for external API calls
```

#### **Image Processing Service**
```bash
# Media manipulation platform
✓ ImageMagick for advanced processing
✓ GD for basic image operations
✓ EXIF for metadata extraction
✓ fileinfo for type detection
✓ MongoDB for storing image metadata
✓ Redis for job queue management
```

---

## 🛠️ Advanced Configuration

### Custom PHP.ini Settings
```bash
# Edit PHP configuration
sudo nano /etc/php/8.2/fpm/php.ini

# Common optimizations
max_input_vars = 3000
memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600

# Reload after changes
sudo systemctl restart php8.2-fpm
```

### PHP-FPM Pool Customization
```bash
# Edit pool configuration
sudo nano /etc/php/8.2/fpm/pool.d/www.conf

# Custom pool settings
[mysite]
user = www-data
group = www-data
listen = /run/php/php8.2-mysite.sock
listen.owner = www-data
listen.group = www-data
php_admin_value[memory_limit] = 512M
php_admin_value[max_execution_time] = 300
```

### Extension-Specific Configuration

#### **Redis Configuration**
```ini
; /etc/php/8.2/mods-available/redis.ini
extension=redis.so
redis.session.locking_enabled = 1
redis.session.lock_expire = 0
redis.session.lock_wait_time = 2000
```

#### **MongoDB Configuration**
```ini
; /etc/php/8.2/mods-available/mongodb.ini
extension=mongodb.so
mongodb.debug = 0
```

#### **OPcache Configuration**
```ini
; /etc/php/8.2/fpm/php.ini
opcache.enable=1
opcache.memory_consumption=512
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

---

## 🔍 Troubleshooting

### Common Issues

#### **PHP-FPM Not Starting**
```bash
# Check configuration
sudo php8.2-fpm -t

# Check logs
sudo journalctl -u php8.2-fpm -n 50

# Check socket permissions
ls -la /run/php/php8.2-fpm.sock
```

#### **Extensions Not Loading**
```bash
# Check installed extensions
php8.2 -m | grep extension_name

# Check extension files
ls -la /etc/php/8.2/mods-available/

# Enable extension manually
sudo phpenmod extension_name
sudo systemctl restart php8.2-fpm
```

#### **Webserver Integration Issues**
```bash
# Test Nginx configuration
sudo nginx -t

# Test Apache configuration
sudo apache2ctl configtest

# Check webserver logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/apache2/error.log
```

### Performance Tuning

#### **PHP-FPM Optimization**
```ini
# High-traffic site
pm.max_children = 100
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.max_requests = 1000
```

#### **Memory Optimization**
```ini
# Memory-constrained environment
memory_limit = 128M
opcache.memory_consumption = 128
pm.max_children = 20
```

---

## 📚 Additional Resources

### Documentation
- [PHP Official Documentation](https://www.php.net/docs.php)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Extension Documentation](https://www.php.net/manual/en/extensions.alphabetical.php)

### Performance Guides
- [PHP OPcache Tuning](https://www.php.net/manual/en/opcache.configuration.php)
- [PHP-FPM Performance Tuning](https://www.php.net/manual/en/install.fpm.php)

### Security Resources
- [PHP Security Best Practices](https://www.php.net/manual/en/security.php)
- [Sodium Cryptography](https://www.php.net/manual/en/book.sodium.php)

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../LICENSE) file for details.

---

**🎉 Ready for production use! This PHP installation script provides everything you need for modern PHP development, from basic websites to enterprise applications.**
