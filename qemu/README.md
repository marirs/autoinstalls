QEMU System Installation
===========================
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange)

Installs QEMU with seabios, Libvirt & Virt-Manager

---

#### Tested on:
- Debian 9.x, 10.x
- Ubuntu 18.04, 20.04

#### Requirements
- Python 3.x is required for Virt-Manager

#### Installation steps

```bash
git clone git@github.com:marirs/autoinstalls.git
cd qemu/
./inst-qemu.sh
/inst-libvirt.sh
```

#### Screen captures

- ./inst-qemu.sh

![qemu](docs/inst-qemu.gif)

- ./inst-libvirt.sh

![libvirt](docs/inst-libvirt.gif)

---
