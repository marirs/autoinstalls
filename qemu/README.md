QEMU System Installation
===========================
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/qemu-8.2.0-blue](https://img.shields.io/badge/qemu-8.2.0-blue)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)

Installs QEMU 8.2.0 with KVM acceleration, SeaBIOS, SPICE support, and compatibility with Libvirt & Virt-Manager

---

#### Features
- ✅ Latest QEMU 8.2.0 with KVM acceleration
- ✅ SeaBIOS with custom patches for virtualization
- ✅ SPICE protocol for remote display and USB redirection
- ✅ KVM hardware virtualization support
- ✅ ARM64 and x86_64 architecture support
- ✅ Comprehensive dependency management
- ✅ User group management for KVM access
- ✅ System optimization and kernel tuning

#### Tested on:
- Debian 9.x, 10.x, 11.x, 12.x
- Ubuntu 18.04, 20.04, 22.04, 24.04

#### Requirements
- Python 3.x is required for Virt-Manager
- KVM support in CPU and BIOS
- Root access (sudo)
- Internet connection for downloads

#### Installation steps

```bash
git clone https://github.com/marirs/autoinstalls.git
cd qemu/
sudo ./inst-qemu.sh
sudo ./inst-libvirt.sh
```

#### What gets installed

**QEMU Components:**
- QEMU 8.2.0 hypervisor with KVM support
- SeaBIOS with custom patches
- SPICE protocol support
- KVM kernel module access

**System Integration:**
- User added to kvm group
- Kernel sysrq enabled
- Symbolic links for libvirt compatibility
- System-wide QEMU installation

**Development Tools:**
- Complete build environment
- Virtualization libraries
- Network and storage support
- Graphics and display protocols

#### Post-Installation

After installation completes:

```bash
# Verify QEMU installation
qemu-system-x86_64 --version

# Check KVM access
ls -la /dev/kvm

# Add additional users to KVM group (optional)
sudo usermod -a -G kvm <username>

# Install virt-manager for GUI management
sudo apt install virt-manager

# Start libvirt service
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
```

#### Installation locations

- **QEMU**: `/usr/bin/qemu-system-*`
- **SeaBIOS**: `/usr/share/qemu/bios.bin`
- **Logs**: `/tmp/apt-packages.log`, `/tmp/qemu-install.log`
- **Configuration**: System-wide installation

#### Usage Examples

**Create a virtual machine:**
```bash
# Create disk image
qemu-img create -f qcow2 vm-disk.qcow2 20G

# Start VM with KVM
qemu-system-x86_64 -m 2048 -hda vm-disk.qcow2 -enable-kvm -cpu host

# Start with SPICE for remote display
qemu-system-x86_64 -m 2048 -hda vm-disk.qcow2 -enable-kvm -spice port=5900,disable-ticketing
```

**Network configuration:**
```bash
# Create bridge network (requires additional setup)
sudo brctl addbr br0
sudo ip link set br0 up

# Use bridge in QEMU
qemu-system-x86_64 -m 2048 -hda vm-disk.qcow2 -enable-kvm -netdev bridge,id=br0 -device virtio-net-pci,netdev=br0
```

---

#### Troubleshooting

**Common Issues:**

1. **Permission denied**: Run with `sudo`
2. **KVM not available**: Check BIOS virtualization settings
3. **Architecture not supported**: Only x86_64 and ARM64 are supported
4. **Build failed**: Check logs in `/tmp/qemu-install.log`
5. **Network issues**: Configure bridge networking properly

**Getting Help:**

Check installation logs:
```bash
# Dependencies log
cat /tmp/apt-packages.log

# QEMU build log
cat /tmp/qemu-install.log
```

**Verification Commands:**
```bash
# Check QEMU version
qemu-system-x86_64 --version

# Check KVM support
lsmod | grep kvm

# Check user groups
groups $USER
```

---

#### Security Notes

- QEMU is installed system-wide with proper permissions
- KVM access is controlled through kvm group membership
- SeaBIOS patches are for virtualization compatibility
- Network isolation recommended for production VMs

---

#### Advanced Configuration

**Performance Tuning:**
- Enable huge pages for memory optimization
- Configure CPU pinning for dedicated VMs
- Use virtio drivers for optimal performance
- Enable nested virtualization if needed

**Network Setup:**
- Configure bridge networks for VM connectivity
- Set up NAT for internet access
- Configure VLANs for network segmentation
- Use SR-IOV for high-performance networking

**Storage Options:**
- Use qcow2 format for snapshot support
- Configure LVM for dynamic storage
- Set up iSCSI for shared storage
- Use virtio for optimal disk performance

---

**Note**: This installation is optimized for development and testing environments. For production use, additional security hardening may be required.
