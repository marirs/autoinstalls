# MySQL/MariaDB Auto-Installation Script
![https://img.shields.io/badge/mysql-8.0-blue](https://img.shields.io/badge/mysql-8.0-blue)
![https://img.shields.io/badge/mariadb-10.11-orange](https://img.shields.io/badge/mariadb-10.11-orange)
![https://img.shields.io/badge/security-localhost%20only-red](https://img.shields.io/badge/security-localhost%20only-red)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

## Overview

This script provides a unified installer for both MySQL 8.0 and MariaDB 10.11 with comprehensive security hardening for localhost-only deployments. It includes:

- **Interactive Database Selection**: Choose between MySQL 8.0 or MariaDB 10.11 during installation
- **Security Hardening**: Localhost-only binding, password authentication, user cleanup
- **Systemd Service**: Security-hardened service with resource limits and restrictions
- **Firewall Configuration**: UFW or iptables rules to block external access while allowing localhost
- **Monitoring Scripts**: Built-in monitoring and backup utilities
- **Log Rotation**: Automatic log management
- **Verification**: Comprehensive installation verification

## Installation Steps

1. **Database Selection**: Interactive choice between MySQL 8.0 and MariaDB 10.11
2. **System Compatibility Check**: Verifies OS compatibility and existing installations
3. **Dependency Installation**: Build tools, SSL headers, system utilities
4. **Repository Setup**: Adds official MySQL or MariaDB repository
5. **Database Installation**: Installs selected database server and client
6. **User and Directory Setup**: Creates mysql user and secure directories
7. **Security Configuration**: Generates passwords, configures localhost binding
8. **Database Hardening**: Removes anonymous users, test database, remote root access
9. **Systemd Service**: Creates security-hardened service with restrictions
10. **Firewall Configuration**: Configures UFW or iptables for localhost-only access
11. **Monitoring and Backup**: Creates management scripts
12. **Verification**: Tests connection, security, and configuration

## Quick Start

```bash
# Navigate to the MySQL directory
cd mysql/

# Run the installation script
sudo ./mysql-install.sh

# Choose your database when prompted:
# 1) MySQL 8.0 (Oracle)
# 2) MariaDB 10.11 (Community) - [DEFAULT]
```

## Database Selection Options

### MySQL 8.0 (Oracle)
- Latest stable version from Oracle
- Advanced security features
- Performance improvements
- JSON document store
- Window functions

### MariaDB 10.11 (Community) - Default
- Community-driven fork
- Enhanced storage engines
- Additional security features
- Backward compatibility
- Open source commitment

## Security Features

### Network Security
- **Localhost Binding**: Database only listens on 127.0.0.1
- **Firewall Rules**: UFW/iptables blocks external access to port 3306
- **Skip Name Resolve**: Disables DNS lookups for security

### Authentication Security
- **Root Password**: Secure randomly generated password
- **User Cleanup**: Removes anonymous users
- **Remote Access**: Disables remote root access
- **Test Database**: Removes test database for security

### System Security
- **Dedicated User**: Database runs as non-privileged `mysql` user
- **File Permissions**: Secure directory and file permissions
- **Systemd Hardening**: NoNewPrivileges, PrivateTmp, ProtectSystem
- **Network Restrictions**: IP address restrictions in systemd

### Configuration Security
- **Skip Show Database**: Prevents users from seeing all databases
- **Local Infile Disabled**: Prevents LOAD DATA LOCAL INFILE attacks
- **Character Set**: UTF8MB4 for full Unicode support

## Configuration Details

### Memory Management
- **InnoDB Buffer Pool**: 128MB (adjustable based on system resources)
- **Key Buffer Size**: 32MB for MyISAM tables
- **Query Cache**: 16MB for improved performance
- **Connection Limits**: 100 max connections

### Performance Settings
- **Thread Cache**: 8 threads for connection handling
- **Table Open Cache**: 256 tables
- **Sort Buffer**: 1MB for query sorting
- **Read Buffer**: 1MB for sequential reads

### Persistence and Logging
- **Binary Logging**: ROW format for point-in-time recovery
- **Slow Query Log**: Queries longer than 2 seconds
- **Error Log**: Comprehensive error logging
- **Log Rotation**: 30-day retention with compression

## Management Scripts

### mysql-monitor
```bash
# Show all information
mysql-monitor

# Show specific information
mysql-monitor status      # Service status
mysql-monitor info        # Database information
mysql-monitor memory      # Memory usage
mysql-monitor performance # Performance statistics
mysql-monitor databases   # Database information
mysql-monitor processes   # Active processes
mysql-monitor security    # Security status
mysql-monitor test        # Connection test
```

### mysql-backup
```bash
# Create backup
mysql-backup create

# List backups
mysql-backup list

# Restore full backup
mysql-backup restore 20240204_120000

# Restore specific database
mysql-backup restore-db 20240204_120000 mydatabase

# Verify backup
mysql-backup verify 20240204_120000

# Clean old backups
mysql-backup cleanup

# Schedule automatic backups
mysql-backup schedule
```

## Usage Examples

### Basic Database Operations
```bash
# Connect to database
mysql -u root -p<password>

# Test connection
mysql -u root -p<password> -e "SELECT VERSION();"

# Create database
mysql -u root -p<password> -e "CREATE DATABASE myapp;"

# Create user
mysql -u root -p<password> -e "CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'app_password';"
mysql -u root -p<password> -e "GRANT ALL PRIVILEGES ON myapp.* TO 'appuser'@'localhost';"
```

### Application Integration
```python
# Python example with mysql-connector-python
import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    port=3306,
    user='root',
    password='<password>',
    database='myapp',
    charset='utf8mb4'
)

cursor = conn.cursor()
cursor.execute("SELECT VERSION()")
version = cursor.fetchone()
print(f"MySQL/MariaDB version: {version[0]}")
```

```javascript
// Node.js example with mysql2
const mysql = require('mysql2');

const connection = mysql.createConnection({
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '<password>',
    database: 'myapp',
    charset: 'utf8mb4'
});

connection.connect((err) => {
    if (err) throw err;
    console.log('Connected to MySQL/MariaDB');
});
```

## File Structure

```
/etc/mysql/
├── my.cnf                    # Main configuration
└── mysql.root.passwd         # Root password file (600 permissions)

/var/lib/mysql/
├── mysql/                    # System database
├── performance_schema/       # Performance schema
├── information_schema/       # Information schema
└── [user_databases]/         # User databases

/var/log/mysql/
├── error.log                 # Database error log
└── slow.log                  # Slow query log

/var/backups/mysql/
├── all_databases_*.sql.gz    # Full database backups
├── [database]_*.sql.gz       # Individual database backups
├── my.cnf_*                  # Configuration backups
└── mysql.root.passwd_*       # Password backups

/usr/local/bin/
├── mysql-monitor             # Monitoring script
└── mysql-backup              # Backup script
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Firewall installed (UFW or iptables)
- [ ] Root access available
- [ ] Database type selected (MySQL/MariaDB)

### Post-Installation
- [ ] Database service running and enabled
- [ ] Password authentication working
- [ ] Localhost-only access verified
- [ ] Firewall rules configured
- [ ] Anonymous users removed
- [ ] Test database removed
- [ ] Remote root access disabled
- [ ] Monitoring scripts functional
- [ ] Backup procedures tested

### Ongoing Security
- [ ] Regular security updates applied
- [ ] Password rotation schedule
- [ ] Log monitoring for security events
- [ ] Backup verification
- [ ] Performance monitoring
- [ ] User access reviews

## Troubleshooting

### Connection Issues
```bash
# Check service status
systemctl status mysql    # For MySQL
systemctl status mariadb  # For MariaDB

# Check logs
journalctl -u mysql -f    # For MySQL
journalctl -u mariadb -f  # For MariaDB
tail -f /var/log/mysql/error.log

# Test connection
mysql -u root -p<password> -e "SELECT 1;"

# Check network binding
netstat -tlnp | grep 3306
```

### Performance Issues
```bash
# Check memory usage
mysql-monitor memory

# Check slow queries
mysql-monitor performance
tail -f /var/log/mysql/slow.log

# Monitor connections
mysql-monitor processes
```

### Security Issues
```bash
# Check firewall rules
ufw status verbose

# Verify localhost binding
grep "bind-address" /etc/mysql/my.cnf

# Check password file permissions
ls -la /etc/mysql/mysql.root.passwd

# Review users
mysql -u root -p<password> -e "SELECT User, Host FROM mysql.user;"
```

## Compliance and Standards

This installation follows:
- **CIS MySQL Benchmark**: Security configuration guidelines
- **NIST Cybersecurity Framework**: Access control and monitoring
- **Industry Best Practices**: Secure deployment patterns
- **GDPR Compliance**: Data processing within controlled environment

## Performance Considerations

- **Memory Usage**: 128MB InnoDB buffer pool (adjustable)
- **Connection Limits**: 100 concurrent connections
- **Query Cache**: 16MB for improved performance
- **Binary Logging**: ROW format for replication and backups
- **Slow Query Log**: 2-second threshold for performance monitoring

## Advanced Configuration

### SSL/TLS Configuration
The script can be extended to include SSL/TLS configuration for encrypted connections.

### Replication Setup
Support for master-slave replication configuration can be added for high availability.

### Performance Tuning
Memory and performance settings can be adjusted based on system resources and workload.

## Support and Maintenance

### Regular Maintenance
- Monitor database logs for errors
- Check memory usage and performance metrics
- Verify backup integrity
- Update database software as needed
- Review security configurations

### Monitoring Metrics
- Memory usage and buffer pool hit rate
- Connection count and thread usage
- Query execution rates and slow queries
- Disk I/O and network statistics
- Database sizes and growth rates

This MySQL/MariaDB installation provides a secure, performant, and maintainable database deployment suitable for production use with localhost-only access requirements.
