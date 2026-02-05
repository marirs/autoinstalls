# Network Configuration Tool

A comprehensive IPv6/IPv4 network configuration script for Debian-based systems that intelligently manages network interfaces and IP addresses.

## Features

### 🌐 Multi-Protocol Support
- **IPv6 Configuration**: Add single, bulk, or custom IPv6 addresses
- **IPv4 Configuration**: Add static IPv4 addresses
- **Mixed Networks**: Handle both IPv4 and IPv6 on the same interface

### 🧠 Intelligent Configuration Analysis
- **Auto-detection**: Reads existing `/etc/network/interfaces` configuration
- **Capacity Analysis**: Calculates maximum available IPs based on CIDR
- **Smart Suggestions**: Provides appropriate defaults based on subnet size
- **Conflict Prevention**: Avoids duplicate configurations

### 📊 Bulk IPv6 Management
- **Range Addition**: Add hundreds/thousands of IPv6 addresses at once
- **Custom Lists**: Add specific IPv6 addresses of your choice
- **Capacity Display**: Shows available IPs in human-readable format
- **Performance Warnings**: Alerts for large address additions

### 🛡️ Safety Features
- **Automatic Backups**: Creates timestamped backups before changes
- **Configuration Validation**: Verifies syntax and format
- **Rollback Capability**: Easy restoration from backups
- **Connectivity Testing**: Verifies configuration works

### 🔧 Multi-Distro Support
- **Debian/Ubuntu**: `/etc/network/interfaces` method
- **Netplan**: Ubuntu 18.04+ configuration
- **NetworkManager**: Modern Linux desktops
- **RHEL/CentOS**: `ifcfg` files support

## Installation

```bash
# Make the script executable
chmod +x network-config.sh

# Run with sudo (required for network configuration)
sudo ./network-config.sh
```

## Usage Examples

### Example 1: Adding Bulk IPv6 Addresses

```bash
=== Network Configuration Tool ===

Current network interfaces:
  1. enp7s0 - 65.108.195.245/24 (UP)
  2. lo - 127.0.0.1/8 (UP)

Select interface to configure (1-2): 1

Current configuration for enp7s0:
Interface: enp7s0
  IPv4: iface enp7s0 inet static
    address 65.108.195.245
    netmask 255.255.255.192
    gateway 65.108.195.193
  IPv6: iface enp7s0 inet6 static
    address 2a01:4f9:1a:97cb::2
    netmask 64
    gateway fe80::1

Configuration Analysis:
  IPv4 Configuration: Yes (static)
  IPv6 Configuration: Yes (static)

What would you like to configure?
  1. Add IPv6 addresses
  2. Add IPv4 addresses

Enter your choice (1-2): 1

How would you like to add IPv6 addresses?
  1. Add single IPv6 address
  2. Add range of IPv6 addresses (bulk)
  3. Add specific IPv6 addresses (custom list)

Enter your choice (1-3): 2

IPv6 Range Configuration:

Current IPv6 subnet detected: 2a01:4f9:1a:97cb::/64
Maximum addresses available in this subnet: 18 quintillion

Enter IPv6 subnet/CIDR (current: 2a01:4f9:1a:97cb::/64): [Press Enter]

Selected subnet: 2a01:4f9:1a:97cb::/64
Maximum addresses available in this subnet: 18 quintillion

Address Range Selection:
Suggested range: 1 to 1000
Maximum reasonable range: 1 to 10000

Enter starting address number (default: 1): 1
Enter ending address number (default: 1000): 100

Generated 100 IPv6 addresses
Range: 2a01:4f9:1a:97cb::1/64 to 2a01:4f9:1a:97cb::100/64

IPv6 Addresses to be Added:
  Showing first 5 and last 5 of 100 addresses:

  1. 2a01:4f9:1a:97cb::1/64
  2. 2a01:4f9:1a:97cb::2/64
  3. 2a01:4f9:1a:97cb::3/64
  4. 2a01:4f9:1a:97cb::4/64
  5. 2a01:4f9:1a:97cb::5/64
  ...
  96. 2a01:4f9:1a:97cb::96/64
  97. 2a01:4f9:1a:97cb::97/64
  98. 2a01:4f9:1a:97cb::98/64
  99. 2a01:4f9:1a:97cb::99/64
  100. 2a01:4f9:1a:97cb::100/64

Add these 100 IPv6 addresses? [y/N]: y

Adding 100 IPv6 addresses to /etc/network/interfaces...
✓ Added 100 IPv6 addresses to configuration

Verifying IPv6 addresses were assigned...
✓ Successfully assigned: 100/100 addresses

Testing IPv6 connectivity...
✓ IPv6 address assigned: 2a01:4f9:1a:97cb::1/64
✓ Ping to gateway (fe80::1): OK
✓ Ping to external (Google DNS): OK
✓ DNS resolution: OK

🎉 Network configuration completed successfully!
Backup saved to: /tmp/network-config-backup-20250205-105500
```

### Example 2: Custom IPv6 List

```bash
How would you like to add IPv6 addresses?
  1. Add single IPv6 address
  2. Add range of IPv6 addresses (bulk)
  3. Add specific IPv6 addresses (custom list)

Enter your choice (1-3): 3

Custom IPv6 Addresses Configuration:
Enter IPv6 addresses one per line. Enter 'done' when finished.

IPv6 address (or 'done'): 2a01:4f9:1a:97cb::10/64
Added: 2a01:4f9:1a:97cb::10/64
IPv6 address (or 'done'): 2a01:4f9:1a:97cb::20/64
Added: 2a01:4f9:1a:97cb::20/64
IPv6 address (or 'done'): 2a01:4f9:1a:97cb::30/64
Added: 2a01:4f9:1a:97cb::30/64
IPv6 address (or 'done'): done

Added 3 IPv6 addresses
```

### Example 3: Adding IPv4 Address

```bash
What would you like to configure?
  1. Add IPv6 addresses
  2. Add IPv4 addresses

Enter your choice (1-2): 2

IPv4 Configuration:
Enter IPv4 address (e.g., 65.108.195.246): 65.108.195.246
Enter netmask (e.g., 255.255.255.192): 255.255.255.192
Enter gateway (optional, press Enter to skip): 65.108.195.193

Adding IPv4 address to /etc/network/interfaces...
✓ IPv4 address added successfully
Testing IPv4 connectivity...
✓ IPv4 connectivity: OK
```

## Configuration File Changes

### Before (Original `/etc/network/interfaces`):
```bash
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback
iface lo inet6 loopback

auto enp7s0
iface enp7s0 inet static
  address 65.108.195.245
  netmask 255.255.255.192
  gateway 65.108.195.193

iface enp7s0 inet6 static
  address 2a01:4f9:1a:97cb::2
  netmask 64
  gateway fe80::1
```

### After (After adding 100 IPv6 addresses):
```bash
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback
iface lo inet6 loopback

auto enp7s0
iface enp7s0 inet static
  address 65.108.195.245
  netmask 255.255.255.192
  gateway 65.108.195.193
  address 65.108.195.246
  netmask 255.255.255.192

iface enp7s0 inet6 static
  address 2a01:4f9:1a:97cb::2
  netmask 64
  gateway fe80::1
  address 2a01:4f9:1a:97cb::1/64
  address 2a01:4f9:1a:97cb::3/64
  address 2a01:4f9:1a:97cb::4/64
  # ... continues to ::100/64
  address 2a01:4f9:1a:97cb::100/64
```

## Subnet Capacity Reference

| CIDR | Maximum IPs | Typical Use | Suggested Range |
|------|-------------|-------------|-----------------|
| /48  | 1.2 sextillion | Large data centers | 1-10000 |
| /56  | 4.7 quintillion | Enterprise networks | 1-5000 |
| /64  | 18 quintillion | Standard allocation | 1-1000 |
| /72  | 4 trillion | Medium networks | 1-500 |
| /80  | 281 billion | Small networks | 1-100 |
| /96  | 4 billion | Micro networks | 1-50 |
| /112 | 65 thousand | Minimal networks | 1-10 |

## Backup and Recovery

### Automatic Backups
Every configuration change creates a timestamped backup:
```bash
# Backup location
/tmp/network-config-backup-YYYYMMDD-HHMMSS/

# Contents
/tmp/network-config-backup-20250205-105500/interfaces
```

### Manual Recovery
```bash
# Restore from backup
sudo cp /tmp/network-config-backup-20250205-105500/interfaces /etc/network/interfaces

# Restart network interface
sudo ifdown enp7s0 && sudo ifup enp7s0
```

## Verification Commands

### Check IPv6 Addresses
```bash
# Show all IPv6 addresses on interface
ip -6 addr show enp7s0

# Show IPv6 routing table
ip -6 route show

# Test IPv6 connectivity
ping6 -c 2 2001:4860:4860::8888
```

### Check IPv4 Addresses
```bash
# Show all IPv4 addresses on interface
ip addr show enp7s0

# Test IPv4 connectivity
ping -c 2 8.8.8.8
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Always run with `sudo`
2. **Interface Not Found**: Verify interface name with `ip addr show`
3. **Invalid CIDR**: Use format like `2a01:4f9:1a:97cb::/64`
4. **Configuration Not Applied**: Check syntax with `ifdown enp7s0 && ifup enp7s0`

### Debug Mode
For detailed debugging, check the backup directory and system logs:
```bash
# Check network logs
sudo journalctl -u networking -f

# Verify configuration syntax
sudo ifup -n enp7s0
```

## Requirements

- **OS**: Debian, Ubuntu, or derivatives
- **Permissions**: Root/sudo access required
- **Tools**: Standard Linux networking utilities
- **Shell**: Bash 4.0+

## Security Considerations

- **Backups**: Automatic backups prevent configuration loss
- **Validation**: Input validation prevents malformed configurations
- **Rollback**: Easy restoration if issues occur
- **Testing**: Connectivity verification ensures working configuration

## License

This script is part of the autoinstalls project and follows the same license terms.

## Support

For issues and feature requests, please refer to the main autoinstalls project documentation.
