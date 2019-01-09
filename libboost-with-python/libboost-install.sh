#!/bin/bash

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# Variables
LIBBOOST_VER=1.69.0
PYTHON_VER=3.7.2

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/libboost-install.log
clear
echo ""
echo "Welcome to the libboost-install script."
echo -e "${CGREEN}Installs Libboost ${LIBBOOST_VER} with Python3 & Python2 libraries${CEND}"
echo ""


# Dependencies
echo -ne "       Installing dependencies             [..]\r"
apt-get update >> /tmp/nginx-install.log 2>&1
INSTALL_PKGS="software-properties-common dirmngr build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev"
for i in $INSTALL_PKGS; do
    apt-get install -y $i  >> /tmp/libboost-install.log 2>&1
    if [ $? -ne 0 ]; then
    echo -e "       Installing dependencies             [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/libboost-install.log"
        echo ""
        exit 1
    fi
done

if [ $? -eq 0 ]; then
    echo -ne "       Installing dependencies             [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
fi


# Python 2
if command -v python2 &>/dev/null; then
    echo -ne "       Downloading Python2                 ${CGREEN}Python 2 is already installed, skipping python2 installation${CEND}\r"
    echo -ne "\n"
    if command -v python2-config >/dev/null; then
        echo -ne "       Downloading Python2 dev             ${CGREEN}Python2-dev is already installed, skipping python2-dev installation${CEND}\r"
        echo -ne "\n"
    else
        echo -ne "       Downloading Python2 dev             [..]\r"
        apt-get install -y python-dev >> /tmp/libboost-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -ne "       Downloading Python2 dev             [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Downloading Python2 dev             [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look at /tmp/libboost-install.log"
            echo ""
            exit 1
        fi
    fi
else
    echo -ne "       Installing Python 2 & Python2-dev   [..]\r"
    apt-get install -y python python-dev >> /tmp/libboost-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing Python 2 & Python2-dev   [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Installing Python 2 & Python2-dev   [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/libboost-install.log"
        echo ""
        exit 1
    fi
fi


# Python 3
if command -v python3 &>/dev/null; then
    echo -ne "       Downloading Python3                 ${CGREEN}Python $(python3 -V | cut -c8-14) is already installed, skipping python3 installation${CEND}\r"
    echo -ne "\n"
    if command -v python3-config >/dev/null; then
        echo -ne "       Downloading Python3 dev             ${CGREEN}Python3-dev is already installed, skipping python3-dev installation${CEND}\r"
        echo -ne "\n"
    else
        echo -ne "       Downloading Python3 dev             [..]\r"
        apt-get install -y python3-dev >> /tmp/libboost-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -ne "       Downloading Python3 dev             [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Downloading Python3 dev             [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look at /tmp/libboost-install.log"
            echo ""
            exit 1
        fi
    fi
else
    echo -ne "       Downloading Python ${PYTHON_VER}            [..]\r"
    curl -fLs https://www.python.org/ftp/python/${PYTHON_VER}/Python-${PYTHON_VER}.tgz | tar xz -C /tmp/  >> /tmp/libboost-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading Python ${PYTHON_VER}            [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Downloading Python ${PYTHON_VER}            [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/libboost-install.log"
        echo ""
        exit 1
    fi
    cd /tmp/Python-${PYTHON_VER}
    echo -ne "       Configuring Python ${PYTHON_VER}            [..]\r"
    CXX="/usr/bin/g++" \
    ./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes \
            --enable-optimizations >> /tmp/nginx-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Configuring Python ${PYTHON_VER}            [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Configuring Python ${PYTHON_VER}            [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/libboost-install.log"
        echo ""
        exit 1
    fi

    echo -ne "       Installing Python ${PYTHON_VER}             [..]\r"
    make -j $cores >> /tmp/libboost-install.log 2>&1
    make install >> /tmp/libboost-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing Python ${PYTHON_VER}             [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Installing Python ${PYTHON_VER}             [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/libboost-install.log"
        echo ""
        exit 1
    fi
    chmod -v 755 /usr/lib/libpython3.7m.so >> /tmp/libboost-install.log 2>&1
    chmod -v 755 /usr/lib/libpython3.so >> /tmp/libboost-install.log 2>&1
fi

# install LibBoost
echo -ne "       Downloading libboost ${LIBBOOST_VER}         [..]\r"
curl -fLs https://dl.bintray.com/boostorg/release/${LIBBOOST_VER}/source/boost_$(echo ${LIBBOOST_VER//./_}).tar.gz | tar xz -C /tmp/ >> /tmp/libboost-install.log 2>&1
cd /tmp/boost_$(echo ${LIBBOOST_VER//./_})
if [ $? -eq 0 ]; then
    echo -ne "       Downloading libboost ${LIBBOOST_VER}         [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Downloading libboost ${LIBBOOST_VER}         [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

# configure
echo -ne "       Configure libboost: Python3         [..]\r"
./bootstrap.sh --with-python=python3 --with-libraries=atomic,system,random,regex,iostreams,chrono,thread,python >> /tmp/libboost-install.log 2>&1
if [ $? -eq 0 ]; then
    echo -ne "       Configure libboost: Python3         [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Configure libboost: Python3         [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

echo -ne "       Installing libboost: Python3        [..]\r"
./b2 -j $cores cxxflags="-fPIC" install >> /tmp/libboost-install.log 2>&1
if [ $? -eq 0 ]; then
    echo -ne "       Installing libboost: Python3        [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Installing libboost: Python3        [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

echo -ne "       Configure libboost: Python2         [..]\r"
./bootstrap.sh --with-python=python2 --with-libraries=atomic,system,random,regex,iostreams,chrono,thread,python >> /tmp/libboost-install.log 2>&1
if [ $? -eq 0 ]; then
    echo -ne "       Configure libboost: Python2         [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Configure libboost: Python2         [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

echo -ne "       Cleaning libboost install: Python3  [..]\r"
./b2 -j $cores cxxflags="-fPIC" >> /tmp/libboost-install.log 2>&1
./b2 -j $cores cxxflags="-fPIC" --with-python --clean >> /tmp/libboost-install.log 2>&1
if [ $? -eq 0 ]; then
    echo -ne "       Cleaning libboost install: Python3  [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Cleaning libboost install: Python3  [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

echo -ne "       Installing libboost: Python2        [..]\r"
./b2 -j $cores cxxflags="-fPIC" install >> /tmp/libboost-install.log 2>&1
if [ $? -eq 0 ]; then
    echo -ne "       Installing libboost: Python2        [${CGREEN}OK${CEND}]\r"
    echo -ne "\n"
else
    echo -e "       Installing libboost: Python2        [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/libboost-install.log"
    echo ""
    exit 1
fi

# We're done !
echo ""
echo -e "       ${CGREEN}Installation successful !${CEND}"
echo ""
echo "       Installation log: /tmp/libboost-install.log"
echo ""
