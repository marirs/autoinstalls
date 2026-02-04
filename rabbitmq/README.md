# RabbitMQ Message Broker Auto-Installation Script
![https://img.shields.io/badge/rabbitmq-3.12-orange](https://img.shields.io/badge/rabbitmq-3.12-orange)
![https://img.shields.io/badge/erlang-25-blue](https://img.shields.io/badge/erlang-25-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-hardened-brightgreen](https://img.shields.io/badge/security-hardened-brightgreen)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

## Overview

This script installs RabbitMQ 3.12 with Erlang/OTP 25 and comprehensive security hardening. The installation includes the management plugin, secure configuration for localhost-only access, and provides a reliable message broker for microservices and distributed systems.

## Quick Start

```bash
# Navigate to the RabbitMQ directory
cd rabbitmq/

# Run the installation script
sudo ./rabbitmq-install.sh
```

## 🛡️ Security Features

### ✅ Network Security
- **Localhost-only binding**: RabbitMQ binds to 127.0.0.1 only
- **Firewall configuration**: UFW/iptables rules for localhost access
- **Port security**: AMQP port 5672 and Management port 15672 secured
- **SSL/TLS ready**: Configuration prepared for SSL (disabled for localhost)

### ✅ Authentication & Authorization
- **Default user management**: Secure admin user with generated password
- **Guest user disabled**: Removes anonymous access
- **Built-in authentication**: PLAIN, AMQPLAIN, and ANONYMOUS mechanisms
- **Role-based access**: Administrator, monitoring, and management roles

### ✅ System Security
- **Systemd hardening**: Resource limits and process isolation
- **File permissions**: Secure directory and file permissions
- **Memory management**: Optimized memory settings
- **Process isolation**: Restricted system access

## Installation Steps

1. **System Compatibility Check**: Verifies OS and existing installations
2. **Dependency Installation**: Required system packages
3. **Erlang Repository Setup**: Add official Erlang repository
4. **Erlang Installation**: Install Erlang/OTP 25 with required modules
5. **RabbitMQ Repository Setup**: Add official RabbitMQ repository
6. **RabbitMQ Installation**: Install RabbitMQ 3.12 server
7. **Security Configuration**: Localhost-only binding and user management
8. **Systemd Configuration**: Service hardening and resource limits
9. **Firewall Setup**: Configure firewall for localhost access
10. **Management Plugin**: Enable web management interface
11. **Service Start**: Start and verify RabbitMQ service
12. **Verification**: Test installation and management interface

## Configuration Details

### RabbitMQ Configuration
- **Version**: RabbitMQ 3.12
- **Erlang Version**: Erlang/OTP 25
- **Node Name**: rabbit@localhost
- **AMQP Port**: 5672 (localhost only)
- **Management Port**: 15672 (localhost only)
- **Data Directory**: /var/lib/rabbitmq
- **Log Directory**: /var/log/rabbitmq

### Security Configuration
- **Default User**: admin with auto-generated password
- **Guest User**: Disabled for security
- **Authentication**: PLAIN, AMQPLAIN, ANONYMOUS mechanisms
- **Virtual Host**: Default "/" vhost configured
- **Permissions**: Full permissions for admin user

### Performance Configuration
- **Memory Limit**: 60% of available RAM
- **Disk Limit**: 1GB minimum free space
- **Heartbeat**: 60 seconds
- **Frame Max**: 131072 bytes

## Management Tools

### rabbitmq-monitor
```bash
# Show comprehensive RabbitMQ status
rabbitmq-monitor

# Show specific information
rabbitmq-monitor status      # Service and cluster status
rabbitmq-monitor info        # Version and system information
rabbitmq-monitor queues      # Queue information and statistics
rabbitmq-monitor connections # Connection information
```

### rabbitmq-manager
```bash
# Manage RabbitMQ service
rabbitmq-manager start       # Start RabbitMQ service
rabbitmq-manager stop        # Stop RabbitMQ service
rabbitmq-manager restart     # Restart RabbitMQ service
rabbitmq-manager logs        # Show RabbitMQ logs

# User management
rabbitmq-manager users       # List all users
rabbitmq-manager add-user <username> <password>  # Add new user
```

## Usage Examples

### Basic RabbitMQ Operations
```bash
# Check RabbitMQ status
rabbitmqctl status

# List users
rabbitmqctl list_users

# List virtual hosts
rabbitmqctl list_vhosts

# List queues
rabbitmqctl list_queues

# List connections
rabbitmqctl list_connections

# List exchanges
rabbitmqctl list_exchanges
```

### User Management
```bash
# Add a new user
rabbitmqctl add_user testuser testpass

# Set user tags (roles)
rabbitmqctl set_user_tags testuser administrator

# Add virtual host
rabbitmqctl add_vhost testhost

# Set permissions for user on vhost
rabbitmqctl set_permissions -p testhost testuser ".*" ".*" ".*"

# Delete user
rabbitmqctl delete_user testuser

# Delete virtual host
rabbitmqctl delete_vhost testhost
```

### Queue and Exchange Management
```bash
# Declare a queue (via management interface)
curl -u admin:password -X PUT http://localhost:15672/api/queues/%2F/test-queue

# Publish a message
curl -u admin:password -X POST http://localhost:15672/api/exchanges/%2F/amqp.default/publish \
  -H 'Content-Type: application/json' \
  -d '{"routing_key":"test-queue","payload":"Hello RabbitMQ!","payload_encoding":"string"}'

# Get messages from queue
curl -u admin:password -X POST http://localhost:15672/api/queues/%2F/test-queue/get \
  -H 'Content-Type: application/json' \
  -d '{"count":1,"requeue":false,"encoding":"auto"}'
```

## File Structure

```
/etc/rabbitmq/
├── rabbitmq.conf            # Main configuration file
├── advanced.config          # Advanced configuration
└── enabled_plugins          # Enabled plugins list

/var/lib/rabbitmq/
├── mnesia/                  # RabbitMQ database
└── log/                     # RabbitMQ logs

/var/log/rabbitmq/
└── rabbitmq/                # Additional log files

/usr/local/bin/
├── rabbitmq-monitor         # Monitoring script
└── rabbitmq-manager         # Management script

/tmp/
└── rabbitmq-install.log     # Installation log
```

## Programming Examples

### Python with Pika
```python
import pika

# Connect to RabbitMQ
connection = pika.BlockingConnection(
    pika.ConnectionParameters('localhost')
)
channel = connection.channel()

# Declare a queue
channel.queue_declare(queue='hello')

# Publish a message
channel.basic_publish(
    exchange='',
    routing_key='hello',
    body='Hello World!'
)
print(" [x] Sent 'Hello World!'")

# Consume messages
def callback(ch, method, properties, body):
    print(f" [x] Received {body}")

channel.basic_consume(
    queue='hello',
    auto_ack=True,
    on_message_callback=callback
)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
```

### Node.js with amqplib
```javascript
const amqp = require('amqplib');

async function main() {
  // Connect to RabbitMQ
  const connection = await amqp.connect('amqp://localhost');
  const channel = await connection.createChannel();

  // Declare a queue
  const queue = 'hello';
  await channel.assertQueue(queue, { durable: false });

  // Send a message
  const msg = 'Hello World!';
  channel.sendToQueue(queue, Buffer.from(msg));
  console.log(" [x] Sent '%s'", msg);

  // Consume messages
  await channel.consume(queue, (msg) => {
    console.log(" [x] Received '%s'", msg.content.toString());
  }, { noAck: true });

  setTimeout(() => {
    connection.close();
    process.exit(0);
  }, 500);
}

main().catch(console.error);
```

### Java with Spring AMQP
```java
@Configuration
@EnableRabbit
public class RabbitConfig {
    
    @Bean
    public ConnectionFactory connectionFactory() {
        CachingConnectionFactory factory = new CachingConnectionFactory();
        factory.setHost("localhost");
        factory.setPort(5672);
        return factory;
    }
    
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        return new RabbitTemplate(connectionFactory);
    }
    
    @Bean
    public Queue helloQueue() {
        return new Queue("hello");
    }
}

@Component
public class MessageProducer {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void sendMessage(String message) {
        rabbitTemplate.convertAndSend("hello", message);
    }
}

@RabbitListener(queues = "hello")
public class MessageReceiver {
    
    @RabbitHandler
    public void receive(String message) {
        System.out.println(" [x] Received '" + message + "'");
    }
}
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Sufficient disk space for RabbitMQ data
- [ ] Network access to package repositories
- [ ] Root access available

### Post-Installation
- [ ] RabbitMQ service running correctly
- [ ] Localhost-only binding confirmed
- [ ] Management plugin enabled
- [ ] Admin user configured
- [ ] Firewall rules configured
- [ ] Monitoring scripts working

### Ongoing Security
- [ ] Regular security updates applied
- [ ] Monitor user access and permissions
- [ ] Review connection logs regularly
- [ ] Backup configuration and data
- [ ] Monitor queue sizes and memory usage
- [ ] Rotate admin passwords regularly

## Troubleshooting

### Service Issues
```bash
# Check service status
systemctl status rabbitmq-server

# Check service logs
journalctl -u rabbitmq-server -f

# Check RabbitMQ logs
tail -f /var/log/rabbitmq/rabbitmq.log

# Restart service
rabbitmq-manager restart
```

### Connection Issues
```bash
# Test RabbitMQ connection
rabbitmqctl status

# Check cluster status
rabbitmqctl cluster_status

# Check network connectivity
netstat -tlnp | grep 5672
netstat -tlnp | grep 15672

# Check firewall rules
ufw status verbose
```

### Performance Issues
```bash
# Monitor RabbitMQ status
rabbitmq-monitor

# Check memory usage
rabbitmqctl status | grep memory

# Monitor queue sizes
rabbitmqctl list_queues name messages

# Check connection count
rabbitmqctl list_connections
```

## Performance Considerations

### Memory Management
- **Memory Limit**: Set to 60% of available RAM
- **Message Persistence**: Balance between performance and durability
- **Queue Types**: Choose appropriate queue types for use case

### Disk I/O
- **SSD Storage**: Use SSD for better performance
- **Disk Space**: Monitor disk usage regularly
- **Message Cleanup**: Implement message TTL and cleanup policies

### Network Performance
- **Connection Pooling**: Reuse connections when possible
- **Batch Operations**: Use batch publishing for better throughput
- **Prefetch Count**: Optimize prefetch count for consumers

## Advanced Configuration

### Production Settings
```ini
# /etc/rabbitmq/rabbitmq.conf
# Performance settings
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 2GB

# Connection settings
heartbeat = 60
frame_max = 131072

# Logging settings
log.file.level = info
log.console = true
log.console.level = info
```

### SSL/TLS Configuration (for external access)
```ini
# /etc/rabbitmq/rabbitmq.conf
# SSL settings
listeners.ssl.default = 5671
ssl_options.cacertfile = /etc/rabbitmq/ca_certificate.pem
ssl_options.certfile   = /etc/rabbitmq/server_certificate.pem
ssl_options.keyfile    = /etc/rabbitmq/server_key.pem
ssl_options.verify     = verify_none
ssl_options.fail_if_no_peer_cert = false
```

## Integration Examples

### Microservices Architecture
```
API Gateway -> RabbitMQ -> Service A
                    -> Service B
                    -> Service C
```

### Event-Driven Architecture
```
Producer -> RabbitMQ Exchange -> Queue A -> Consumer A
                           -> Queue B -> Consumer B
                           -> Queue C -> Consumer C
```

### Log Aggregation
```
Application Logs -> RabbitMQ -> Log Processor -> Elasticsearch
```

## Compliance and Standards

This installation follows:
- **RabbitMQ Security Best Practices**: Official security guidelines
- **AMQP Protocol Standards**: Message queue protocol compliance
- **Industry Standards**: Enterprise messaging standards
- **Data Protection**: Secure message handling practices

## Support and Maintenance

### Regular Maintenance
- Update RabbitMQ to latest stable version
- Monitor queue sizes and memory usage
- Review and optimize configuration
- Clean up old queues and exchanges
- Monitor connection and channel usage

### Backup and Recovery
```bash
# Export definitions
rabbitmqctl export_definitions /backup/definitions.json

# Import definitions
rabbitmqctl import_definitions /backup/definitions.json

# Backup data directory
tar -czf /backup/rabbitmq-data.tar.gz /var/lib/rabbitmq/
```

This RabbitMQ installation provides a secure, performant, and maintainable message broker suitable for microservices, event-driven architectures, and distributed systems.
