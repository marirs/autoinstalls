Postgresql installation
=======================

### 🐘 PostgreSQL Database
**Advanced relational database with enterprise-grade features**

**Features:**
- ✅ Latest PostgreSQL with performance tuning
- ✅ Multiple installation modes (Standalone, Primary-Replica, Cluster)
- ✅ Comprehensive security with Row Level Security
- ✅ Advanced monitoring and performance tuning
- ✅ Automated backup and point-in-time recovery
- ✅ User management with fine-grained permissions
- ✅ SSL/TLS encryption and audit logging
- ✅ Localhost-only binding for maximum security

**Installation:**
```bash
cd postgresql/
sudo ./postgresql-install.sh
```

**What's Included:**
- PostgreSQL server with optimizations
- pgAdmin4 web interface (optional)
- Extension support (pg_stat_statements, pg_trgm, etc.)
- Backup and restore automation
- User and role management
- Performance monitoring tools
- Security hardening configurations

**Management Tools:**
```bash
# Create application user
./scripts/postgresql-users create-app webapp password123 myapp

# Create backup
./scripts/postgresql-backup backup

# List users
./scripts/postgresql-users list
```
