# LIbboost Auto Installation

Installs Libboost with python2 & python3 libraries

If Python is already found in the system:
```bash

Welcome to the libboost-install script.
Installs Libboost 1.69.0 with Python3 & Python2 libraries

       Installing dependencies             [OK]
       Downloading Python2                 Python 2 is already installed, skipping python2 installation
       Downloading Python2 dev             Python2-dev is already installed, skipping python2-dev installation
       Downloading Python3                 Python 3.5.3 is already installed, skipping python3 installation
       Downloading Python3 dev             Python3-dev is already installed, skipping python3-dev installation
       Downloading libboost 1.69.0         [OK]
       Configure libboost: Python3         [OK]
       Installing libboost: Python3        [OK]
       Configure libboost: Python2         [OK]
       Cleaning libboost install: Python3  [OK]
       Installing libboost: Python2        [OK]

       Installation successful !

       Installation log: /tmp/libboost-install.log
```
---
If either of Python versions is not found in the system:
```bash

Welcome to the libboost-install script.
Installs Libboost 1.69.0 with Python3 & Python2 libraries

       Installing dependencies             [OK]
       Downloading Python2                 Python 2 is already installed, skipping python2 installation
       Downloading Python2 dev             [OK]
       Downloading Python 3.7.2            [OK]
       Configuring Python 3.7.2            [OK]
       Installing  Python 3.7.2            [OK]
       Downloading libboost 1.69.0         [OK]
       Configure libboost: Python3         [OK]
       Installing libboost: Python3        [OK]
       Configure libboost: Python2         [OK]
       Cleaning libboost install: Python3  [OK]
       Installing libboost: Python2        [OK]

       Installation successful !

       Installation log: /tmp/libboost-install.log

```

---
