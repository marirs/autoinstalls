# Redis Auto-Installation Script
# Localhost-only Redis deployment with comprehensive security hardening

## Overview

This script installs Redis 7.2.4 with comprehensive security hardening for localhost-only deployments. It includes:

- **Security Hardening**: Localhost-only binding, password authentication, dangerous command disabling
- **Systemd Service**: Security-hardened service with resource limits and restrictions
- **Firewall Configuration**: UFW rules to block external access while allowing localhost
- **Monitoring Scripts**: Built-in monitoring and backup utilities
- **Log Rotation**: Automatic log management
- **Verification**: Comprehensive installation verification

## Installation Steps

1. **System Compatibility Check**
   - Verifies OS compatibility
   - Checks for existing Redis installation
   - Confirms architecture support

2. **Dependency Installation**
   - Build tools and libraries
   - SSL development headers
   - System utilities (UFW, systemd, logrotate)

3. **User and Directory Setup**
   - Creates `redis` user and group
   - Sets up secure directories with proper permissions
   - Configures data, config, and log directories

4. **Redis Installation**
   - Downloads Redis 7.2.4 source code
   - Compiles with optimizations
   - Installs to `/usr/local`

5. **Security Configuration**
   - Generates secure random password
   - Configures localhost-only binding
   - Disables dangerous commands (FLUSHDB, FLUSHALL, KEYS, etc.)
   - Sets up memory limits and persistence

6. **Systemd Service**
   - Creates security-hardened service
   - Configures resource limits
   - Sets up network restrictions
   - Enables automatic startup

7. **Firewall Configuration**
   - Allows Redis access from localhost only
   - Blocks external access attempts
   - Configures UFW rules

8. **Monitoring and Backup**
   - Creates monitoring script (`redis-monitor`)
   - Creates backup script (`redis-backup`)
   - Sets up log rotation

9. **Verification**
   - Tests Redis connection
   - Verifies localhost binding
   - Confirms security configuration
   - Validates operations

## Security Features

### Network Security
- **Localhost Binding**: Redis only listens on 127.0.0.1 and ::1
- **Firewall Rules**: UFW blocks external access to port 6379
- **Protected Mode**: Additional Redis security layer

### Authentication Security
- **Password Protection**: Secure randomly generated password
- **Command Renaming**: Dangerous commands renamed or disabled
- **Access Control**: Password required for all operations

### System Security
- **Dedicated User**: Redis runs as non-privileged `redis` user
- **File Permissions**: Secure directory and file permissions
- **Systemd Hardening**: NoNewPrivileges, PrivateTmp, ProtectSystem
- **Network Restrictions**: IP address restrictions in systemd

### Command Security
Disabled commands:
- `FLUSHDB`, `FLUSHALL` - Data deletion prevention
- `KEYS` - Performance protection
- `CONFIG` - Configuration protection (renamed)
- `SHUTDOWN` - Shutdown protection (renamed)
- `DEBUG` - Debug access prevention
- `EVAL` - Script execution prevention

## Configuration Details

### Memory Management
- **Max Memory**: 256MB limit
- **Eviction Policy**: allkeys-lru
- **Memory Samples**: 5 for LRU algorithm

### Persistence
- **RDB Snapshots**: Regular snapshots (900s/1, 300s/10, 60s/10000)
- **AOF Logging**: Append-only file with everysec fsync
- **Compression**: RDB compression enabled
- **Checksums**: Data integrity verification

### Performance
- **TCP Keepalive**: 300 seconds
- **Client Limits**: 10000 max clients
- **Slow Log**: 10ms threshold, 128 entries
- **Latency Monitoring**: 100ms threshold

## Management Scripts

### redis-monitor
```bash
# Show all information
redis-monitor

# Show specific information
redis-monitor status    # Service status
redis-monitor info      # Redis information
redis-monitor test      # Connection test
```

### redis-backup
```bash
# Create backup
redis-backup create

# List backups
redis-backup list

# Clean old backups
redis-backup cleanup
```

## Usage Examples

### Basic Redis Operations
```bash
# Connect to Redis
redis-cli -a <password>

# Test connection
redis-cli -a <password> ping

# Set/get values
redis-cli -a <password> set mykey "Hello Redis"
redis-cli -a <password> get mykey

# Check Redis info
redis-cli -a <password> info
```

### Application Integration
```python
# Python example
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='<password>',
    decode_responses=True
)

r.ping()
r.set('key', 'value')
value = r.get('key')
```

```javascript
// Node.js example
const Redis = require('ioredis');

const redis = new Redis({
    host: 'localhost',
    port: 6379,
    password: '<password>'
});

redis.ping().then(console.log);
```

## File Structure

```
/etc/redis/
├── redis.conf          # Main configuration
└── redis.passwd        # Password file (600 permissions)

/var/lib/redis/
├── dump.rdb           # RDB snapshot
└── appendonly.aof     # AOF log

/var/log/redis/
└── redis-server.log   # Redis logs

/var/backups/redis/
├── dump_*.rdb.gz      # RDB backups
└── appendonly_*.aof.gz # AOF backups

/usr/local/bin/
├── redis-monitor      # Monitoring script
└── redis-backup       # Backup script
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Firewall installed (UFW)
- [ ] Root access available

### Post-Installation
- [ ] Redis service running and enabled
- [ ] Password authentication working
- [ ] Localhost-only access verified
- [ ] Firewall rules configured
- [ ] Monitoring scripts functional
- [ ] Backup procedures tested

### Ongoing Security
- [ ] Regular security updates
- [ ] Log monitoring
- [ ] Backup verification
- [ ] Performance monitoring

## Troubleshooting

### Connection Issues
```bash
# Check service status
systemctl status redis

# Check logs
journalctl -u redis -f

# Test connection
redis-cli -a <password> ping

# Check network binding
netstat -tlnp | grep 6379
```

### Performance Issues
```bash
# Check memory usage
redis-cli -a <password> info memory

# Check slow queries
redis-cli -a <password> slowlog get 10

# Monitor connections
redis-cli -a <password> info clients
```

### Security Issues
```bash
# Check firewall rules
ufw status verbose

# Verify localhost binding
grep "bind" /etc/redis/redis.conf

# Check password file permissions
ls -la /etc/redis/redis.passwd
```

## Compliance and Standards

This installation follows:
- **CIS Redis Benchmark**: Security configuration guidelines
- **NIST Cybersecurity Framework**: Access control and monitoring
- **Industry Best Practices**: Secure deployment patterns

## Performance Considerations

- **Memory Limit**: 256MB with LRU eviction
- **Connection Limit**: 10000 concurrent clients
- **Persistence**: RDB + AOF for durability
- **Monitoring**: Built-in performance metrics
- **Backup**: Automated backup with compression

## Support and Maintenance

### Regular Maintenance
- Monitor Redis logs for errors
- Check memory usage and fragmentation
- Verify backup integrity
- Update Redis as needed
- Review security configurations

### Monitoring Metrics
- Memory usage and fragmentation ratio
- Connection count and client types
- Command execution rates
- Hit/miss ratios
- Slow query frequency

This Redis installation provides a secure, performant, and maintainable Redis deployment suitable for production use with localhost-only access requirements.
