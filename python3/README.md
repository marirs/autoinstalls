Python 3.x Installation
========================
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%20%7C%20Debian%209.x%2C%2010.x-orange)
![https://img.shields.io/badge/python-3.11.8-blue](https://img.shields.io/badge/python-3.11.8-blue)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)

Installs Python 3.11.8 with virtualenvwrapper and essential development packages

---

#### Features
- ✅ Latest stable Python 3.11.8
- ✅ Optimized build with `--enable-optimizations`
- ✅ Virtualenvwrapper for environment management
- ✅ Comprehensive development dependencies
- ✅ ARM64 and x86_64 support
- ✅ Detailed logging and error handling
- ✅ System information display

#### Tested on:
- Debian 9.x, 10.x, 11.x, 12.x, 13.x
- Ubuntu 18.04, 20.04, 22.04, 24.04

#### Requirements
- Root access (sudo)
- x86_64 or ARM64 architecture
- Internet connection

#### Installation steps

```bash
git clone https://github.com/marirs/autoinstalls.git
cd python3/
sudo ./inst-py3.sh
```

#### Post-Installation

After installation completes:

```bash
# Reload bash configuration
source ~/.bashrc

# Create virtual environment
mkvirtualenv myenv

# Test Python installation
python3.11 --version

# Test pip
python3.11 -m pip --version
```

#### What gets installed

**Python Components:**
- Python 3.11.8 (compiled from source)
- pip (latest version)
- virtualenvwrapper

**Development Packages:**
- Build tools (gcc, make, etc.)
- SSL/TLS libraries
- Database development headers
- Compression libraries
- Terminal utilities

#### Installation locations

- **Python**: `/usr/bin/python3.11`
- **Pip**: `/usr/bin/python3.11 -m pip`
- **Virtualenvwrapper**: `/usr/local/bin/virtualenvwrapper.sh`
- **Logs**: `/tmp/apt-packages.log`, `/tmp/py3-install.log`

#### Screen captures

- ./inst-py3.sh
![docs/py3.gif](docs/py3.gif)

---

#### Troubleshooting

**Common Issues:**

1. **Permission denied**: Run with `sudo`
2. **Architecture not supported**: Only x86_64 and ARM64 are supported
3. **Download failed**: Check internet connection and try again
4. **Build failed**: Check logs in `/tmp/py3-install.log`

**Getting Help:**

Check installation logs:
```bash
# Dependencies log
cat /tmp/apt-packages.log

# Python build log
cat /tmp/py3-install.log
```

---

#### Security Notes

- Downloads from official Python HTTPS sources
- Verifies download integrity
- Uses system SSL libraries
- No third-party repositories
