# QEMU System Installation

Installs QEMU with seabios, Libvirt & Virt-Manager

Tested on:
- Debian 9
- Ubuntu 16.04 and above

```bash

Welcome to the qemu-install script.
Installs QEMU 3.1.0, Libvirt 4.10.0 & Virt-Manager 1.x/2.x

What do you want to do?
   1) Install everything (Qemu with SeaBios, Libvirt, VirtManager)
   2) Install Qemu with SeaBios
   3) Install Libvirt
   4) Install Virt-Manager
   5) Exit

Select an option [1-5]: 1

Which Virt-Manager version do you want to install
    1) Virt-Manager 1.5 (Python 2 required) - detected 2.7
    2) Virt-Manager 2.0 (Python 3 required) - detected 3.5

Select an option [1-2]: 2

       Installing dependencies             [OK]
       Checking NUMA status                [PRESENT]
       Installing NUMA requirements        [OK]
       Spice protocol support              [OK]

       Downloading Qemu                    [OK]
       Patching Qemu clues                 [OK]
       Configuring Qemu                    [OK]
       Installing Qemu                     [OK]

       Cloning seabios                     [OK]
       Patching seabios clues              [OK]
       Installing seabios                  [OK]
       Copying seabios inside of qemu      [OK]

       Downloading Libvirt                 [OK]
       Configuring Libvirt                 [OK]
       Installing Libvirt                  [OK]
       Starting Libvirt services           [OK]

       Cloning virt-manager 2.0            [OK]
       Building virt-manager 2.0           [OK]
       Installing virt-manager 2.0         [OK]

       Installation successful !

       Installation log: /tmp/qemu-install.log
```

