MongoDB installation
====================

### 🗄️ MongoDB Database
**NoSQL database with comprehensive security and management tools**

**Features:**
- ✅ Latest MongoDB with authentication and SSL
- ✅ Multiple installation types (Standalone, Replica Set, Sharded Cluster)
- ✅ Advanced security configuration
- ✅ Automated backup and restore tools
- ✅ User management with role-based access
- ✅ Performance monitoring and alerting
- ✅ Localhost-only binding for security

**Installation:**
```bash
cd mongodb/
sudo ./mongodb-install.sh
```

**What's Included:**
- MongoDB server with security optimizations
- MongoDB Compass GUI (optional)
- Backup and restore automation
- User management utilities
- Performance monitoring tools
- Security hardening configurations

**Management Tools:**
```bash
# Create admin user
./scripts/mongodb-users create-admin admin password123

# Create backup
./scripts/mongodb-backup backup

# List users
./scripts/mongodb-users list
```