# Elasticsearch Search Engine Auto-Installation Script
![https://img.shields.io/badge/elasticsearch-8.11.0-blue](https://img.shields.io/badge/elasticsearch-8.11.0-blue)
![https://img.shields.io/badge/java-17-orange](https://img.shields.io/badge/java-17-orange)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-localhost%20only-red](https://img.shields.io/badge/security-localhost%20only-red)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

## Overview

This script installs Elasticsearch 8.11.0 with comprehensive security hardening and optimization. The installation is configured for localhost-only access with built-in security features enabled, providing a powerful search and analytics engine for development and production use.

## Quick Start

```bash
# Navigate to the Elasticsearch directory
cd elasticsearch/

# Run the installation script
sudo ./elasticsearch-install.sh
```

## 🛡️ Security Features

### ✅ Network Security
- **Localhost-only binding**: Elasticsearch binds to 127.0.0.1 only
- **Firewall configuration**: UFW/iptables rules for localhost access
- **Port security**: HTTP port 9200 restricted to localhost
- **Transport security**: Transport port 9300 secured

### ✅ Application Security
- **Built-in security features**: X-Pack security enabled by default
- **User authentication**: Secure user management system
- **Role-based access**: Fine-grained permissions control
- **Password protection**: Auto-generated secure passwords

### ✅ System Security
- **Systemd hardening**: Resource limits and restrictions
- **File permissions**: Secure directory and file permissions
- **Memory management**: JVM heap size optimization
- **Process isolation**: Restricted system access

## Installation Steps

1. **System Compatibility Check**: Verifies OS, memory, and architecture
2. **Dependency Installation**: Java 17 JRE and required packages
3. **Repository Setup**: Add official Elasticsearch repository
4. **Elasticsearch Installation**: Install Elasticsearch 8.11.0
5. **Security Configuration**: Localhost-only binding and security settings
6. **Systemd Configuration**: Service hardening and resource limits
7. **Firewall Setup**: Configure firewall for localhost access
8. **Service Start**: Start and verify Elasticsearch service
9. **Verification**: Test installation and cluster health

## Configuration Details

### Elasticsearch Configuration
- **Version**: Elasticsearch 8.11.0
- **Cluster Name**: elasticsearch-cluster
- **Node Name**: elasticsearch-node-1
- **Network Host**: 127.0.0.1 (localhost only)
- **HTTP Port**: 9200
- **Transport Port**: 9300
- **Discovery Type**: single-node

### Security Configuration
- **X-Pack Security**: Enabled
- **SSL/TLS**: Disabled for localhost setup
- **Authentication**: Built-in user management
- **Authorization**: Role-based access control

### JVM Configuration
- **Heap Size**: Automatically configured (50% of available RAM, max 32GB)
- **Memory Settings**: Optimized for performance
- **Garbage Collection**: Default GC settings

## Management Tools

### elasticsearch-monitor
```bash
# Show comprehensive Elasticsearch status
elasticsearch-monitor

# Show specific information
elasticsearch-monitor status      # Service and cluster health
elasticsearch-monitor info        # Version and cluster information
elasticsearch-monitor memory      # JVM memory usage
elasticsearch-monitor indices     # Index information
```

### elasticsearch-manager
```bash
# Manage Elasticsearch service
elasticsearch-manager start       # Start Elasticsearch service
elasticsearch-manager stop        # Stop Elasticsearch service
elasticsearch-manager restart     # Restart Elasticsearch service
elasticsearch-manager logs        # Show Elasticsearch logs
```

## Usage Examples

### Basic Elasticsearch Operations
```bash
# Test Elasticsearch connection
curl http://localhost:9200

# Check cluster health
curl http://localhost:9200/_cluster/health

# Get cluster information
curl http://localhost:9200

# List all indices
curl http://localhost:9200/_cat/indices?v

# Create an index
curl -X PUT http://localhost:9200/test-index

# Add a document
curl -X POST http://localhost:9200/test-index/_doc -H 'Content-Type: application/json' -d '{
  "field": "value",
  "timestamp": "2024-01-01T00:00:00Z"
}'

# Search documents
curl http://localhost:9200/test-index/_search

# Delete an index
curl -X DELETE http://localhost:9200/test-index
```

### Advanced Search Examples
```bash
# Simple text search
curl -X GET http://localhost:9200/test-index/_search -H 'Content-Type: application/json' -d '{
  "query": {
    "match": {
      "field": "value"
    }
  }
}'

# Range query
curl -X GET http://localhost:9200/test-index/_search -H 'Content-Type: application/json' -d '{
  "query": {
    "range": {
      "timestamp": {
        "gte": "2024-01-01",
        "lte": "2024-12-31"
      }
    }
  }
}'

# Aggregation query
curl -X GET http://localhost:9200/test-index/_search -H 'Content-Type: application/json' -d '{
  "size": 0,
  "aggs": {
    "field_count": {
      "terms": {
        "field": "field.keyword"
      }
    }
  }
}'
```

## File Structure

```
/usr/share/elasticsearch/
├── bin/                      # Elasticsearch binaries
├── lib/                      # Elasticsearch libraries
├── modules/                  # Elasticsearch modules
└── plugins/                  # Elasticsearch plugins

/etc/elasticsearch/
├── elasticsearch.yml         # Main configuration file
├── jvm.options.d/            # JVM configuration
│   └── heap.options          # Heap size settings
└── log4j2.properties         # Logging configuration

/var/lib/elasticsearch/
└── data/                     # Elasticsearch data directory

/var/log/elasticsearch/
└── elasticsearch.log         # Elasticsearch logs

/usr/local/bin/
├── elasticsearch-monitor     # Monitoring script
└── elasticsearch-manager     # Management script

/tmp/
└── elasticsearch-install.log # Installation log
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Minimum 4GB RAM available (recommended)
- [ ] Sufficient disk space for data and logs
- [ ] Java 17 JRE installed or available
- [ ] Root access available

### Post-Installation
- [ ] Elasticsearch service running correctly
- [ ] Localhost-only binding confirmed
- [ ] Firewall rules configured
- [ ] Security features enabled
- [ ] Cluster health is green
- [ ] Monitoring scripts working

### Ongoing Security
- [ ] Regular security updates applied
- [ ] Monitor cluster health and performance
- [ ] Review access logs regularly
- [ ] Backup data regularly
- [ ] Monitor disk space usage
- [ ] Keep Java updated

## Troubleshooting

### Service Issues
```bash
# Check service status
systemctl status elasticsearch

# Check service logs
journalctl -u elasticsearch -f

# Check Elasticsearch logs
tail -f /var/log/elasticsearch/elasticsearch.log

# Restart service
elasticsearch-manager restart
```

### Connection Issues
```bash
# Test Elasticsearch connection
curl http://localhost:9200

# Check cluster health
curl http://localhost:9200/_cluster/health

# Check network connectivity
netstat -tlnp | grep 9200

# Check firewall rules
ufw status verbose
```

### Performance Issues
```bash
# Monitor JVM memory usage
elasticsearch-monitor memory

# Check cluster statistics
curl http://localhost:9200/_cluster/stats

# Monitor index performance
curl http://localhost:9200/_cat/indices?v

# Check thread pool stats
curl http://localhost:9200/_cat/thread_pool?v
```

## Performance Considerations

### Memory Management
- **Heap Size**: Set to 50% of available RAM, max 32GB
- **File System Cache**: Leave 50% RAM for OS cache
- **Memory Pressure**: Monitor for memory-related issues

### Disk I/O
- **SSD Storage**: Use SSD for better performance
- **RAID Configuration**: Consider RAID 0 for performance, RAID 10 for redundancy
- **Disk Space**: Monitor disk usage regularly

### Network Performance
- **Localhost Access**: Optimized for local connections
- **Bulk Operations**: Use bulk API for better throughput
- **Connection Pooling**: Use connection pooling in applications

## Advanced Configuration

### Production Settings
```yaml
# /etc/elasticsearch/elasticsearch.yml
cluster.name: production-cluster
node.name: production-node-1

# Performance settings
indices.memory.index_buffer_size: 10%
indices.queries.cache.size: 5%
indices.fielddata.cache.size: 40%

# Thread pool settings
thread_pool.write.queue_size: 1000
thread_pool.search.queue_size: 1000
```

### JVM Tuning
```bash
# /etc/elasticsearch/jvm.options.d/performance.options
# GC settings
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200

# Memory settings
-XX:+UnlockExperimentalVMOptions
-XX:+UseCGroupMemoryLimitForHeap
```

## Integration Examples

### Web Application Integration
```javascript
// Node.js with Elasticsearch client
const { Client } = require('@elastic/elasticsearch');

const client = new Client({
  node: 'http://localhost:9200'
});

// Search documents
async function searchDocuments() {
  const result = await client.search({
    index: 'my-index',
    body: {
      query: {
        match: { title: 'search term' }
      }
    }
  });
  return result.body.hits.hits;
}
```

### Log Analytics Setup
```bash
# Create log index pattern
curl -X PUT http://localhost:9200/logs-*/_template/logs_template -H 'Content-Type: application/json' -d '{
  "index_patterns": ["logs-*"],
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "level": { "type": "keyword" },
      "message": { "type": "text" }
    }
  }
}'
```

## Compliance and Standards

This installation follows:
- **Elasticsearch Security Best Practices**: Official security guidelines
- **OWASP Guidelines**: Search engine security recommendations
- **Industry Standards**: Enterprise search and analytics standards
- **Data Protection**: Secure data handling practices

## Support and Maintenance

### Regular Maintenance
- Update Elasticsearch to latest stable version
- Monitor cluster health and performance
- Review and optimize index mappings
- Clean up old indices and data
- Monitor disk space and memory usage

### Backup and Recovery
```bash
# Create snapshot repository
curl -X PUT http://localhost:9200/_snapshot/backup_repo -H 'Content-Type: application/json' -d '{
  "type": "fs",
  "settings": {
    "location": "/backup/elasticsearch"
  }
}'

# Create snapshot
curl -X PUT http://localhost:9200/_snapshot/backup_repo/snapshot_1

# Restore snapshot
curl -X POST http://localhost:9200/_snapshot/backup_repo/snapshot_1/_restore
```

This Elasticsearch installation provides a secure, performant, and maintainable search and analytics engine suitable for development, testing, and production environments.
