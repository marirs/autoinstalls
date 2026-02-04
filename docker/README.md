# Docker README Documentation
# Internal-only Docker deployment with security hardening

# Docker Internal Installation
=============================
![https://img.shields.io/badge/docker-27.0.0-blue](https://img.shields.io/badge/docker-27.0.0-blue)
![https://img.shields.io/badge/docker%20compose-2.24.0-blue](https://img.shields.io/badge/docker%20compose-2.24.0-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-secure%20access-blue](https://img.shields.io/badge/security-secure%20access-blue)

Secure Docker installation configured for internal Docker daemon access with internet access for containers and comprehensive security hardening.

---

## 🛡️ Security Features

### ✅ Secure Docker Daemon Access
- **No external network access** for Docker daemon
- **Firewall rules** block external Docker daemon access
- **Unix socket only** - no TCP daemon socket
- **Internal network access** only for Docker daemon

### ✅ Container Internet Access
- **Internet access** enabled for containers by default
- **Default bridge network** with NAT
- **Internal network** available for isolation
- **Configurable networking** per container

### ✅ Security Hardening
- **User namespace remapping** prevents root access
- **Seccomp profiles** restrict system calls
- **No new privileges** prevents privilege escalation
- **Capability dropping** minimizes container permissions
- **Read-only filesystems** where possible
- **Resource limits** prevent resource exhaustion

### ✅ Network Security
- **Docker daemon** isolated from external access
- **Container internet** access through NAT
- **Internal bridge network** for isolation
- **Firewall protection** for daemon ports
- **Configurable isolation** per container

---

## 🚀 Features

### Docker Engine Features
- ✅ Latest Docker 27.0.0 with security patches
- ✅ Docker Compose 2.24.0 for multi-container applications
- ✅ Overlay2 storage driver with performance optimizations
- ✅ JSON file logging with rotation
- ✅ Systemd integration for service management

### Security Features
- ✅ User namespace remapping (dockremap)
- ✅ Seccomp security profiles
- ✅ No-new-privileges enforcement
- ✅ Capability dropping
- ✅ Read-only filesystem support
- ✅ Resource limits and ulimits

### Network Features
- ✅ **Default bridge network** with internet access
- ✅ **Internal bridge network** (172.18.0.0/16) for isolation
- ✅ **NAT configuration** for container internet access
- ✅ **Firewall protection** for Docker daemon
- ✅ **Unix socket only** for daemon access
- **Configurable isolation** per container

---

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 18.04+ / Debian 9.x+
- **Architecture**: x86_64 or ARM64
- **Memory**: 2GB RAM minimum (4GB+ recommended)
- **Storage**: 20GB free space
- **Network**: Internet access for containers
- **Permissions**: Root/sudo access

### Recommended Requirements
- **OS**: Ubuntu 20.04+ / Debian 10.x+
- **Memory**: 4GB+ RAM
- **Storage**: 50GB+ free space
- **CPU**: Multi-core processor
- **Security**: Firewall enabled

---

## 📦 Installation

### Quick Install
```bash
git clone https://github.com/marirs/autoinstalls.git
cd docker/
sudo ./docker-install.sh
```

### Post-Installation Steps
```bash
# Log out and log back in for docker group access
exit
# (log back in)

# Test Docker installation
docker run --rm hello-world

# Test internet access
docker run --rm -it alpine ping -c 3 google.com

# Try the example configuration
cd /opt/docker-examples
docker-compose up -d

# Check security status
docker-monitor security
```

---

## 🔧 Configuration

### Docker Daemon Configuration
The installation creates a secure `/etc/docker/daemon.json` with:

```json
{
  "ip-forward": true,
  "iptables": true,
  "userns-remap": "default",
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json",
  "hosts": ["unix:///var/run/docker.sock"]
}
```

### Firewall Configuration
UFW rules block external Docker daemon access:
```bash
# Block external Docker daemon access
ufw deny 2376/tcp
ufw deny 2377/tcp

# Allow localhost only
ufw allow from 127.0.0.1 to any port 2376
ufw allow from 172.16.0.0/12 to any port 2376
ufw allow from 172.17.0.0/16 to any port 2376
ufw allow from 172.18.0.0/16 to any port 2376
```

### Network Configuration
```bash
# Default bridge network (internet access)
docker network ls | grep bridge

# Internal network (isolation)
docker network create --driver bridge --subnet=172.18.0.0/16 internal-net
```

---

## 📚 Usage Examples

### Basic Container Operations
```bash
# Run a container with internet access (default)
docker run --rm -it nginx:alpine

# Run a container on isolated network
docker run --rm -it --network internal-net nginx:alpine

# Run with security options
docker run --rm -it \
  --security-opt no-new-privileges:true \
  --security-opt seccomp=default.json \
  --read-only \
  --tmpfs /tmp \
  --cap-drop ALL \
  --cap-add CHOWN \
  --network internal-net \
  nginx:alpine
```

### Docker Compose Example
```bash
cd /opt/docker-examples
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Network Configuration
```bash
# Default network (internet access)
docker run --rm -it --network bridge nginx:alpine

# Internal network (isolated)
docker run --rm -it --network internal-net nginx:alpine

# Custom network
docker network create --driver bridge --subnet 192.168.100.0/24 custom-net
docker run --rm -it --network custom-net nginx:alpine
```

### Security Monitoring
```bash
# Check Docker security status
docker-monitor security

# Monitor running containers
docker-monitor containers

# View resource usage
docker-monitor resources

# Generate full report
docker-monitor report
```

### Backup and Restore
```bash
# Create full backup
docker-backup full

# List available backups
docker-backup list

# Restore from backup
docker-backup restore-containers 20240204_120000

# Verify backup integrity
docker-backup verify /var/backups/docker/docker_full_backup_20240204_120000.tar.gz
```

---

## 🛠️ Management Scripts

### Docker Monitor (`docker-monitor`)
Comprehensive monitoring tool for secure Docker deployment:

```bash
# Show all information
docker-monitor all

# Show specific information
docker-monitor status
docker-monitor containers
docker-monitor networks
docker-monitor resources
docker-monitor security

# Generate report
docker-monitor report

# Clean up unused resources
docker-monitor cleanup
```

### Docker Backup (`docker-backup`)
Complete backup and restore solution:

```bash
# Create full backup
docker-backup full

# Backup specific components
docker-backup containers
docker-backup images
docker-backup volumes
docker-backup config

# Restore operations
docker-backup restore-containers <date>
docker-backup restore-images <date>
docker-backup restore-volumes <date>

# List and verify backups
docker-backup list
docker-backup verify <backup_file>
```

---

## 🔍 Security Best Practices

### Container Security
```dockerfile
# Use minimal base images
FROM alpine:3.18

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -D -s /bin/sh -u 1001 -G appgroup appuser

USER appuser

# Use read-only filesystem
VOLUME ["/tmp"]
```

### Docker Compose Security
```yaml
services:
  app:
    image: nginx:alpine
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
    networks:
      - internal-net
```

### Runtime Security
```bash
# Run with maximum security
docker run --rm -it \
  --security-opt no-new-privileges:true \
  --security-opt seccomp=default.json \
  --read-only \
  --tmpfs /tmp \
  --cap-drop ALL \
  --cap-add CHOWN \
  --network internal-net \
  nginx:alpine
```

---

## 📊 Monitoring

### Security Monitoring
```bash
# Check security status
docker-monitor security

# Monitor container activity
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# Check network configuration
docker network ls
docker network inspect bridge
docker network inspect internal-net
```

### Resource Monitoring
```bash
# Real-time resource usage
docker stats

# System resource usage
docker system df

# Container resource limits
docker inspect <container> | jq '.[0].HostConfig.Resources'
```

### Log Monitoring
```bash
# Docker daemon logs
journalctl -u docker.service -f

# Container logs
docker logs <container>

# All container logs
docker-monitor logs
```

---

## 🔧 Troubleshooting

### Common Issues

#### Container Cannot Access Internet
```bash
# Check if container is on default bridge network
docker inspect <container> | jq '.[0].NetworkSettings.Networks'

# Test internet access
docker run --rm -it alpine ping -c 3 google.com
```

#### Docker Daemon Not Accessible
```bash
# Check if user is in docker group
groups $USER

# Check Docker service status
systemctl status docker

# Check firewall rules
ufw status verbose
```

#### Permission Denied Errors
```bash
# Log out and log back in for group changes
exit
# (log back in)

# Verify docker group access
docker run --rm hello-world
```

### Debug Commands
```bash
# Check Docker installation
docker --version
docker-compose --version

# Test Docker daemon
docker info

# Check network configuration
docker network ls
docker network inspect bridge
docker network inspect internal-net

# Verify security configuration
cat /etc/docker/daemon.json
```

---

## 📋 Security Checklist

### ✅ Pre-Installation
- [ ] System updated and patched
- [ ] Firewall installed and configured
- [ ] User accounts with minimal privileges
- [ ] Security policies reviewed

### ✅ Installation
- [ ] Docker installed from official repository
- [ ] Security configuration applied
- [ ] Default bridge network created
- [ ] Internal network created
- [ ] Firewall rules configured
- [ ] User group permissions set

### ✅ Post-Installation
- [ ] Docker services running and enabled
- [ ] Security configuration verified
- [ ] Internet access tested
- [ ] Example containers deployed
- [ ] Monitoring configured

### ✅ Ongoing Security
- [ ] Regular security updates applied
- [ ] Container images scanned for vulnerabilities
- [ ] Resource usage monitored
- [ ] Network traffic monitored
- [ ] User access reviewed regularly
- [ ] Backups tested regularly

---

## 🚨 Important Security Notes

### ⚠️ Secure Docker Daemon Access
- **No external access** to Docker daemon by design
- **Firewall rules** block external daemon ports
- **Unix socket only** - no TCP daemon socket
- **Internal networks** only for daemon access

### ⚠️ Container Internet Access
- **Internet access** enabled by default for containers
- **NAT configuration** through default bridge
- **Isolation available** through internal network
- **Configurable per container** network access

### ⚠️ Security Considerations
- **User namespace remapping** may affect some applications
- **No new privileges** may break some container functionality
- **Internal network** requires explicit configuration for external access
- **Read-only filesystems** require temporary directories for writable paths

### ⚠️ Network Isolation
- **Docker daemon** isolated from external access
- **Containers** have internet access by default
- **Host services** not accessible from containers
- **External services** accessible from containers
- **Inter-container communication** allowed on all networks

---

## 📞 Support

### Getting Help
```bash
# Check installation logs
cat /tmp/docker-install.log
cat /tmp/apt-packages.log

# Check Docker status
docker-monitor all

# Generate diagnostic report
docker-monitor report
```

### Common Solutions
1. **Permission issues**: Log out and log back in
2. **Network issues**: Verify internal network configuration
3. **Security issues**: Check firewall rules and Docker configuration
4. **Performance issues**: Monitor resource usage and limits

---

## 🔄 Updates and Maintenance

### Regular Maintenance
```bash
# Clean up unused resources
docker-monitor cleanup

# Update Docker packages
apt update && apt upgrade docker-ce docker-ce-cli containerd.io

# Restart Docker service
systemctl restart docker

# Verify configuration
docker-monitor security
```

### Backup Strategy
```bash
# Create regular backups
docker-backup full

# Schedule automatic cleanup
docker-backup cleanup

# Test restore procedures
docker-backup verify <backup_file>
```

---

**⚠️ Important**: This Docker installation is configured with **secure daemon access** while allowing **internet access for containers**. The Docker daemon is isolated from external access, but containers can access the internet through the default bridge network. For complete isolation, use the internal network.

---

**🐳 Secure Docker Deployment with Internet Access - Ready for Production Use!**
