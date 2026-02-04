# Node.js JavaScript Runtime Auto-Installation Script
![https://img.shields.io/badge/node.js-20.x-lts-green](https://img.shields.io/badge/node.js-20.x-lts-green)
![https://img.shields.io/badge/npm-10.x-blue](https://img.shields.io/badge/npm-10.x-blue)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-hardened-orange](https://img.shields.io/badge/security-hardened-orange)
![https://img.shields.io/badge/status-development%20ready-green](https://img.shields.io/badge/status-development%20ready-green)

## Overview

This script installs Node.js 20.x LTS with comprehensive security hardening and development tools. It supports both NodeSource system-wide installation and NVM user-level installation with version management capabilities.

## Quick Start

```bash
# Navigate to the Node.js directory
cd nodejs/

# Run the installation script
sudo ./nodejs-install.sh

# Choose installation method:
# 1) NodeSource 20.x LTS (System-wide) - [DEFAULT]
# 2) NVM (User-level with version switching)
```

## Installation Methods

### NodeSource 20.x LTS (System-wide) - Default
- **Node.js 20.x LTS** from official NodeSource repository
- **System-wide installation** available to all users
- **Automatic security updates** via package manager
- **Integrated with system PATH**

### NVM (User-level with version switching)
- **Node Version Manager** for flexible version management
- **User-level installation** (no sudo required for daily use)
- **Easy switching** between Node.js versions
- **Per-user .nvmrc file support**

## 🛡️ Security Features

### ✅ System Security
- **Non-root execution**: Node.js applications run as non-privileged users
- **File permissions**: Secure npm global directory permissions
- **Path security**: Protected npm and Node.js paths
- **Package security**: Configured npm security settings

### ✅ Network Security
- **Registry security**: Configured npm registry settings
- **Audit capabilities**: npm audit for security vulnerabilities
- **Scoped packages**: Support for private registries

## Installation Steps

1. **System Compatibility Check**: Verifies OS compatibility and existing installations
2. **Installation Method Selection**: Choose between NodeSource LTS or NVM
3. **Dependency Installation**: Build tools and system utilities
4. **Node.js Installation**: Installs Node.js 20.x LTS with npm
5. **Security Configuration**: Sets up proper permissions and security
6. **Development Tools**: Installs essential global packages
7. **Verification**: Tests installation and configuration

## Configuration Details

### Node.js Configuration
- **LTS Version**: Node.js 20.x Long Term Support
- **npm Version**: Latest compatible npm 10.x
- **Global Modules**: Secure global module directory
- **Environment**: Optimized NODE_ENV settings

### Development Tools
- **Essential packages**: nodemon, pm2, yarn
- **Security tools**: npm audit, helmet
- **Build tools**: TypeScript support (optional)
- **Testing frameworks**: Jest support (optional)

## Management Tools

### nodejs-monitor
```bash
# Show comprehensive Node.js status
nodejs-monitor

# Show specific information
nodejs-monitor version     # Node.js and npm versions
nodejs-monitor modules     # Global modules
nodejs-monitor security    # Security audit
nodejs-monitor processes   # Running Node.js processes
```

### nodejs-manager
```bash
# Manage global modules
nodejs-manager globals     # List global modules
nodejs-manager cleanup     # Clean npm cache
```

## Usage Examples

### Basic Node.js Operations
```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Install a global package
npm install -g nodemon

# Create a new project
npm init -y

# Install dependencies
npm install express

# Run security audit
npm audit
```

### Application Development
```javascript
// Simple Express server example
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.json({ message: 'Hello from Node.js!' });
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
```

### Process Management with PM2
```bash
# Install PM2 globally
npm install -g pm2

# Start application
pm2 start app.js

# List processes
pm2 list

# Monitor processes
pm2 monit

# Setup startup script
pm2 startup
```

## File Structure

```
/usr/local/bin/
├── node                    # Node.js executable
├── npm                     # npm executable
├── npx                     # npx executable
├── nodejs-monitor          # Monitoring script
└── nodejs-manager          # Management script

/usr/local/lib/node_modules/
└── [global-modules]/       # Global npm modules

~/.npm/
├── _cacache/               # npm cache
├── _logs/                  # npm logs
└── _npx/                   # npx cache

~/.nvm/                     # NVM directory (NVM only)
├── versions/               # Node.js versions
└── alias/                  # Version aliases

/tmp/
└── nodejs-install.log      # Installation log
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Sufficient disk space for Node.js and modules
- [ ] Network access for npm registry
- [ ] Root access available

### Post-Installation
- [ ] Node.js and npm working correctly
- [ ] Global module permissions secure
- [ ] npm audit configured
- [ ] Development tools functional
- [ ] Monitoring scripts working

### Ongoing Security
- [ ] Regular npm audits for vulnerabilities
- [ ] Keep Node.js updated to latest LTS
- [ ] Review global modules regularly
- [ ] Monitor npm security advisories
- [ ] Use npm audit fix regularly

## Troubleshooting

### Installation Issues
```bash
# Check Node.js installation
node --version
npm --version

# Check npm configuration
npm config list

# Clear npm cache
npm cache clean --force

# Check global modules
npm list -g --depth=0
```

### Permission Issues
```bash
# Fix npm permissions (NVM)
npm config set prefix ~/.npm-global

# Check npm global directory
npm config get prefix

# Fix global module permissions
sudo chown -R $(whoami) ~/.npm
```

### Performance Issues
```bash
# Monitor Node.js processes
nodejs-monitor processes

# Check npm performance
npm config get registry
npm config get cache

# Monitor memory usage
nodejs-monitor performance
```

## Performance Considerations

- **Memory Usage**: Node.js typically uses 50-100MB base memory
- **Module Loading**: Optimize require() statements
- **npm Cache**: Regular cache cleanup improves performance
- **Global Modules**: Limit global modules to essentials

## Advanced Configuration

### Production Deployment
- **Process Manager**: PM2 for production process management
- **Environment Variables**: Secure NODE_ENV configuration
- **Logging**: Winston or similar logging framework
- **Monitoring**: APM tools integration

### Development Environment
- **Hot Reloading**: Nodemon for development
- **Debugging**: Node.js inspector integration
- **Testing**: Jest or Mocha testing framework
- **Linting**: ESLint for code quality

## Integration Examples

### Web Development Stack
- **Frontend**: Node.js + React/Vue/Angular
- **Backend**: Node.js + Express/Fastify
- **Database**: MongoDB/PostgreSQL/MySQL
- **Caching**: Redis
- **Proxy**: Nginx

### Microservices Architecture
- **API Gateway**: Node.js + Express
- **Services**: Individual Node.js microservices
- **Message Queue**: RabbitMQ
- **Database**: PostgreSQL/MongoDB
- **Container**: Docker + Kubernetes

## Compliance and Standards

This installation follows:
- **Node.js Security Best Practices**: Official security guidelines
- **npm Security Guidelines**: Package security recommendations
- **Industry Standards**: Modern JavaScript development practices
- **OWASP Guidelines**: Web application security

## Support and Maintenance

### Regular Maintenance
- Update Node.js to latest LTS version
- Run npm audit regularly
- Clean npm cache periodically
- Review and update global modules
- Monitor security advisories

### Performance Optimization
- Monitor Node.js process memory
- Optimize module loading
- Use clustering for CPU-intensive apps
- Implement proper logging
- Regular performance profiling

This Node.js installation provides a secure, performant, and maintainable JavaScript runtime environment suitable for both development and production use.
