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
QEMU_VER=3.1.0
LIBVIRT_VER=4.10.0
VIRTMANAGER_VER=1.5.0
PY2_VER=$(dpkg-query -f '${Package}-${Version}\n' -W | grep -iw ^python2 | head -1 | cut -d'-' -f 2 | cut -c1-3)
PY3_VER=$(dpkg-query -f '${Package}-${Version}\n' -W | grep -iw ^python3 | head -1 | cut -d'-' -f 2 | cut -c1-3)
is_numa=$(lscpu | grep -i numa | head -1 |cut -c14-26 | xargs)


# Clear log file
[ -f "//tmp/qemu-install.log" ] && rm -f /tmp/qemu-install.log

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

clear
echo ""
echo "Welcome to the qemu-install script."
echo -e "${CGREEN}Installs QEMU ${QEMU_VER}, Libvirt ${LIBVIRT_VER} & Virt-Manager 1.x/2.x${CEND}"
echo ""


# Dependencies
function install_deps() {
    echo -ne "       Installing dependencies             [..]\r"
    apt-get update >> /tmp/qemu-install.log 2>&1
    INSTALL_PKGS="\
    libcurl4-gnutls-dev libnl-route-3-dev libsasl2-dev libattr1-dev libyajl2 libpciaccess-dev \
    software-properties-common libdevmapper-dev gir1.2-spice-client-glib-2.0 gobject-introspection \
    dconf-tools libsnappy-dev libcap-dev libasound2-dev unzip glusterfs-common libssh2-1-dev liblzo2-dev \
    libspice-server1 libibverbs-dev genisoimage libgoogle-perftools-dev libnl-route-3-200 xfslibs-dev \
    libjpeg8-dev python-requests autopoint libosinfo-1.0 pkg-config libarchive-tools libpulse-dev xsltproc \
    ibglib2.0-dev libvirt-glib-1.0 uuid-dev python-ipaddr iasl intltool libiscsi-dev automake g++ \
    systemtap-sdt-dev gir1.2-spice-client-gtk-3.0 librbd-dev binfmt-support libicu-dev wget libvdeplug-dev \
    libpixman-1-dev valgrind libyajl-dev autotools-dev libusbredirhost-dev zlib1g-dev build-essential libaio-dev \
    python3-libxml2 libfdt-dev python-lxml libguestfs-tools libbluetooth-dev git libpciaccess0 glib-2.0 \
    libspice-protocol-dev libbz2-dev libsdl2-dev xmlto libnuma-dev dirmngr gir1.2-gtk-vnc-2.0 python-libxml2 \
    libncurses5-dev libseccomp-dev dconf-cli libxen-dev libxml2-dev libvde-dev python3-libvirt libgnutls28-dev \
    libbrlapi-dev devscripts libnl-3-dev autoconf libgtk-3-dev gir1.2-vte-2.91 curl python-dev gcc libosinfo-1.0-0 \
    libnfs-dev libsdl1.2-dev make libxml2-utils gettext dbus-x11 libspice-server-dev libusb-1.0-0-dev librbd1 \
    libxslt-dev libvirt-glib-1.0-0 glusterfs-client librdmacm-dev libvte-dev python-gnutls checkinstall \
    libjpeg62-turbo-dev libvte-2.91-dev libcap-ng-dev"
    for i in $INSTALL_PKGS; do
        apt-get install -y $i  >> /tmp/qemu-install.log 2>&1
        if [ $? -ne 0 ]; then
            echo -e "       Installing dependencies             [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look at /tmp/qemu-install.log"
            echo ""
            exit 1
        fi
    done
    if [ $? -eq 0 ]; then
        echo -ne "       Installing dependencies             [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    fi
}

# spice support
function install_spice_support() {
    cd /tmp
    echo -ne "       Spice protocol support              [..]\r"
    git clone --quiet git://git.freedesktop.org/git/spice/spice-protocol   >> /tmp/qemu-install.log 2>&1
    cd spice-protocol
    ./autogen.sh   >> /tmp/qemu-install.log 2>&1
    ./configure   >> /tmp/qemu-install.log 2>&1
    make -j$cores   >> /tmp/qemu-install.log 2>&1
    make install   >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Spice protocol support              [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Spice protocol support              [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi
}

# NUMA check
function numa_install() {
    echo -ne "       Checking NUMA status                [..]\r"
    if [[ "$is_numa" -ge "1" ]]; then
        echo -ne "       Checking NUMA status                [${CGREEN}PRESENT${CEND}]\r\n"
        echo -ne "       Installing NUMA requirements        [..]\r"
        apt-get -y install numactl libnuma-dev >> /tmp/qemu-install.log 2>&1
        cd /tmp
        git clone --quiet https://github.com/K1773R/numad.git >> /tmp/qemu-install.log 2>&1
        cd numad
        make -j$cores >> /tmp/qemu-install.log 2>&1
        make install >> /tmp/qemu-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -ne "       Installing NUMA requirements        [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Installing NUMA requirements        [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look at /tmp/qemu-install.log"
            echo ""
            exit 1
        fi
    else
        echo -ne "       Checking NUMA status                [${CRED}NOT PRESENT${CEND}]\r\n"
    fi
}

function install_libvirt() {
    echo ""
    echo -ne "       Downloading Libvirt                 [..]\r"
    cd /tmp  >> /tmp/qemu-install.log 2>&1
    curl -fLs https://libvirt.org/sources/libvirt-${LIBVIRT_VER}.tar.xz | tar xvJ -C /tmp/ >> /tmp/qemu-install.log 2>&1
    cd /tmp/libvirt-${LIBVIRT_VER}
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading Libvirt                 [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Downloading Libvirt                 [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi
    mount -o remount,exec /tmp  >> /tmp/qemu-install.log 2>&1
    LIBVIRT_OPTIONS="--system \
                    --prefix=/usr \
                    --localstatedir=/var \
                    --sysconfdir=/etc \
                    --with-openssl \
                    --with-storage-rbd \
                    --with-qemu=yes --with-esx --with-xen=yes \
                    --with-dtrace --disable-nls \
                    --without-apparmor --without-secdriver-apparmor --without-apparmor-mount --without-apparmor-profiles "

    if [[ "$is_numa" -ge "1" ]]; then
        LIBVIRT_OPTIONS=$(echo $LIBVIRT_OPTIONS; echo --with-numad)
    fi

    echo -ne "       Configuring Libvirt                 [..]\r"
    ./autogen.sh $LIBVIRT_OPTIONS >> /tmp/qemu-install.log 2>&1
    make -j$cores  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Configuring Libvirt                 [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Configuring Libvirt                 [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi
    echo -ne "       Installing Libvirt                  [..]\r"
    make install  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing Libvirt                  [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Installing Libvirt                  [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi
    echo -ne "       Starting Libvirt services           [..]\r"
    systemctl start libvirtd  >> /tmp/qemu-install.log 2>&1
    systemctl daemon-reload >> /tmp/qemu-install.log 2>&1
    systemctl enable libvirtd  >> /tmp/qemu-install.log 2>&1
    service virtlockd start  >> /tmp/qemu-install.log 2>&1
    service virtlogd start  >> /tmp/qemu-install.log 2>&1
    service libvirtd start  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Starting Libvirt services           [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Starting Libvirt services           [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi

    cd /tmp
}

# virt-manager
function install_virtmanager_15() {
    echo ""
    cd /tmp/  >> /tmp/qemu-install.log 2>&1
    echo -ne "       Cloning virt-manager 1.5            [..]\r"
    git clone --quiet -b v1.5-maint https://github.com/virt-manager/virt-manager.git  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Cloning virt-manager 1.5            [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Cloning virt-manager 1.5            [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
    cd "virt-manager" || return

    echo -ne "       Building virt-manager 1.5           [..]\r"
    python setup.py build   >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Building virt-manager 1.5           [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Building virt-manager 1.5           [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

    echo -ne "       Installing virt-manager 1.5         [..]\r"
    python setup.py install   >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing virt-manager 1.5         [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Installing virt-manager 1.5         [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
}

function install_virtmanager_2() {
    echo ""
    cd /tmp/  >> /tmp/qemu-install.log 2>&1
    echo -ne "       Cloning virt-manager 2.0            [..]\r"
    git clone --quiet https://github.com/virt-manager/virt-manager.git  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Cloning virt-manager 2.0            [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Cloning virt-manager 2.0            [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
    cd "virt-manager" || return

    echo -ne "       Building virt-manager 2.0           [..]\r"
    python3 setup.py build   >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Building virt-manager 2.0           [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Building virt-manager 2.0           [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

    echo -ne "       Installing virt-manager 2.0         [..]\r"
    python3 setup.py install   >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing virt-manager 2.0         [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Installing virt-manager 2.0         [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
}

# seabios
function install_seabios() {
    echo ""
    cd /tmp/ >> /tmp/qemu-install.log 2>&1
    echo -ne "       Cloning seabios                     [..]\r"
    git clone --quiet https://github.com/coreboot/seabios.git >> /tmp/qemu-install.log 2>&1
    cd /tmp/seabios
    if [ $? -eq 0 ]; then
        echo -ne "       Cloning seabios                     [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Cloning seabios                     [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

    # Patch seabios
    echo -ne "       Patching seabios clues              [..]\r"
    if [ -f "src/config.h" ]; then
        sed -i 's/Bochs/Intel/g' seabios/src/config.h >> /tmp/qemu-install.log 2>&1
        sed -i 's/BOCHSCPU/INTELCPU/g' seabios/src/config.h >> /tmp/qemu-install.log 2>&1
        sed -i 's/BOCHS/INTEL/g' seabios/src/config.h >> /tmp/qemu-install.log 2>&1
        sed -i 's/BXPC/HPPC/g' seabios/src/config.h >> /tmp/qemu-install.log 2>&1
    fi

    if [ -f "src/fw/ssdt-misc.dsl" ]; then
        sed -i 's/QEMU0001/Intel001/g' seabios/src/fw/ssdt-misc.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXPC"/"HPPC"/g' seabios/src/fw/ssdt-misc.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXSSDTSU"/"HPSSDTSU"/g' seabios/src/fw/ssdt-misc.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXSSDTSUSP"/"HPSSDTSUSP"/g' seabios/src/fw/ssdt-misc.dsl >> /tmp/qemu-install.log 2>&1
    fi

    if [ -f "src/fw/ssdt-pcihp.dsl" ]; then
        sed -i 's/"BXPC"/"HPPC"/g' seabios/src/fw/ssdt-pcihp.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXDSDT"/"HPDSDT"/g' seabios/src/fw/ssdt-pcihp.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXSSDTPCIHP"/"HPSSDTPCIHP"/g' seabios/src/fw/ssdt-pcihp.dsl >> /tmp/qemu-install.log 2>&1
    fi

    if [ -f "src/fw/ssdt-proc.dsl" ]; then
        sed -i 's/"BXPC"/"HPPC"/g' seabios/src/fw/ssdt-proc.dsl >> /tmp/qemu-install.log 2>&1
        sed -i 's/"BXSSDT"/"HPSSDT"/g' seabios/src/fw/ssdt-proc.dsl >> /tmp/qemu-install.log 2>&1
    fi

    if [ -f "vgasrc/Kconfig" ]; then
        sed -i 's/QEMU\/Bochs/ASUS\/Strix/g' seabios/vgasrc/Kconfig >> /tmp/qemu-install.log 2>&1
        sed -i 's/qemu /asus /g' seabios/vgasrc/Kconfig >> /tmp/qemu-install.log 2>&1
    fi

    FILES=(
        src/hw/blockcmd.c
        src/fw/paravirt.c
    )
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            sed -i 's/"QEMU/"ASUS/g' "$file" >> /tmp/qemu-install.log 2>&1
        fi
    done

    FILES=(
        src/fw/acpi-dsdt.dsl
        src/fw/q35-acpi-dsdt.dsl
    )
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            sed -i 's/"BXPC"/"HPPC"/g' "$file" >> /tmp/qemu-install.log 2>&1
            sed -i 's/"BXDSDT"/"HPDSDT"/g' "$file" >> /tmp/qemu-install.log 2>&1
        fi
    done

    FILES=(
        src/fw/q35-acpi-dsdt.dsl
        src/fw/acpi-dsdt.dsl
        src/fw/ssdt-misc.dsl
        src/fw/ssdt-proc.dsl
        src/fw/ssdt-pcihp.dsl
        src/config.h
    )
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
        sed -i 's/"BXPC"/"HPPC"/g' "$file" >> /tmp/qemu-install.log 2>&1
        fi
    done
    if [ $? -eq 0 ]; then
        echo -ne "       Patching seabios clues              [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Patching seabios clues              [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi


    echo -ne "       Installing seabios                  [..]\r"
    make -j$cores >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing seabios                  [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Installing seabios                  [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

    FILES=(
        /usr/share/qemu/bios.bin
        /usr/share/qemu/bios-256k.bin
    )
    echo -ne "       Copying seabios inside of qemu      [..]\r"
    for file in "${FILES[@]}"; do
        cp -vf out/bios.bin "$file" >> /tmp/qemu-install.log 2>&1
    done
    if [ $? -eq 0 ]; then
        echo -ne "       Copying seabios inside of qemu      [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Copying seabios inside of qemu      [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
}

# QEMU
function install_qemu() {
    #      "KVMKVMKVM\0\0\0"; /* KVM */
    #      "TCGTCGTCG\0\0\0"; /* TCG */
    #      "Microsoft Hv"; /* Microsoft Hyper-V or Windows Virtual PC */
    #      "VMwareVMware"; /* VMware */
    #      "XenVMMXenVMM"; /* Xen */
    #      "prl hyperv  "; /* Parallels */
    #      "VBoxVBoxVBox"; /* VirtualBox */
    echo ""
    echo -ne "       Downloading Qemu                    [..]\r"
    curl -fLs https://download.qemu.org/qemu-${QEMU_VER}.tar.xz | tar xvJ -C /tmp/  >> /tmp/qemu-install.log 2>&1
    cd /tmp/qemu-${QEMU_VER}
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading Qemu                    [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Downloading Qemu                    [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        echo ""
        exit 1
    fi

    echo -ne "       Patching Qemu clues                 [..]\r"
    if [[ -f "hw/scsi/scsi-disk.c" ]]; then
        sed -i 's/QEMU CD-ROM/SONY CD-ROM/g' hw/scsi/scsi-disk.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/s->vendor = g_strdup("QEMU");/s->vendor = g_strdup("SONY");/g' hw/scsi/scsi-disk.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/s->product = g_strdup("QEMU HARDDISK");/s->product = g_strdup("SONY HARDDISK");/g' hw/scsi/scsi-disk.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/QEMU HARDDISK/SONY SCSIDISK/g' hw/scsi/scsi-disk.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "hw/ide/atapi.c" ]]; then
        sed -i 's/padstr8(buf + 8, 8, "QEMU");/padstr8(buf + 8, 8, "SONY");/g' hw/ide/atapi.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/QEMU DVD-ROM/SONY DVD-ROM/g' hw/ide/atapi.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "hw/ide/core.c" ]]; then
        sed -i 's/QEMU HARDDISK/SONY HARDDISK/g' hw/ide/core.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/QEMU MICRODRIVE/SONY MICRODRIVE/g' hw/ide/core.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/QEMU DVD-ROM/SONY DVD-ROM/g' hw/ide/core.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "target/i386/kvm.c" ]]; then
        sed -i 's/KVMKVMKVM\\0\\0\\0/GenuineIntel/g' target/i386/kvm.c >> /tmp/qemu-install.log 2>&1
        sed -i 's/TCGTCGTCG\\0\\0\\0/GenuineIntel/g' target/i386/kvm.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "target/i386/kvm.c" ]]; then
        sed -i 's/Microsoft Hv/GenuineIntel/g' target/i386/kvm.c >> /tmp/qemu-install.log 2>&1
    fi

    if [[ -f "block/bochs.c" ]]; then
        sed -i 's/"bochs"/"intel"/g' block/bochs.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "include/hw/acpi/aml-build.h" ]]; then
        sed -i 's/"BOCHS "/"INTEL "/g' include/hw/acpi/aml-build.h >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "roms/ipxe/src/drivers/net/pnic.c" ]]; then
        sed -i 's/Bochs Pseudo/Intel RealTime/g' roms/ipxe/src/drivers/net/pnic.c >> /tmp/qemu-install.log 2>&1
    fi
    if [[ -f "roms/vgabios/vbe.c" ]]; then
        sed -i 's/Bochs\/Plex86/Intel\/Raedon/g' roms/vgabios/vbe.c >> /tmp/qemu-install.log 2>&1
    fi

    if [ $? -eq 0 ]; then
        echo -ne "       Patching Qemu clues                 [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Patching Qemu clues                 [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi
    mkdir -p build >> /tmp/qemu-install.log 2>&1
    cd build >> /tmp/qemu-install.log 2>&1
    mount -o remount,exec /tmp >> /tmp/qemu-install.log 2>&1
    QEMU_OPTIONS="--prefix=/usr \
                    --libexecdir=/usr/lib/qemu \
                    --localstatedir=/var \
                    --sysconfdir=/etc \
                    --bindir=/usr/bin/ \
                    --enable-gnutls \
                    --enable-xen \
                    --enable-kvm \
                    --enable-vnc \
                    --enable-spice \
                    --enable-vnc-sasl \
                    --enable-vnc-png \
                    --enable-vnc-jpeg \
                    --enable-curl \
                    --enable-usb-redir \
                    --enable-lzo \
                    --enable-snappy \
                    --enable-bzip2 \
                    --enable-libusb \
                    --enable-coroutine-pool  \
                    --enable-libxml2 \
                    --enable-tcmalloc \
                    --enable-replication \
                    --enable-tools \
                    --enable-capstone \
                    --enable-sdl \
                    --with-sdlabi=2.0 \
                    --target-list=i386-softmmu,x86_64-softmmu,i386-linux-user,x86_64-linux-user"

    if [[ "$is_numa" -ge "1" ]]; then
        QEMU_OPTIONS=$(echo $QEMU_OPTIONS; echo --enable-numa)
    fi

    echo -ne "       Configuring Qemu                    [..]\r"
    ../configure $QEMU_OPTIONS >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Configuring Qemu                    [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Configuring Qemu                    [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

    echo -ne "       Installing Qemu                     [..]\r"
    make -j$cores  >> /tmp/qemu-install.log 2>&1
    make install  >> /tmp/qemu-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing Qemu                     [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -ne "       Installing Qemu                     [${CRED}FAIL${CEND}]\r"
        echo ""
        echo "Please look at /tmp/qemu-install.log"
        exit 1
    fi

}

function add_user_to_group() {
    if [[ $(getent group libvirt) || $(getent group libvirt) ]]; then
        echo -ne "       Adding current user to libvirt group[..]\r"
        getent group librit 2>&1 > /dev/null && usermod -a -G libvirt ${USER} >> /tmp/qemu-install.log 2>&1 || echo "libvirt group does not exist" >> /tmp/qemu-install.log 2>&1
        getent group kvm 2>&1 > /dev/null && usermod -a -G kvm ${USER} >> /tmp/qemu-install.log 2>&1 || echo "kvm group does not exist" >> /tmp/qemu-install.log 2>&1
        if [ $? -eq 0 ]; then
            echo -ne "       Adding current user to libvirt group[${CGREEN}OK! ${USER} added${CEND}]\r"
            echo -ne "\n"
        else
            echo -e "       Adding current user to libvirt group[${CRED}FAIL! ${USER} not added${CEND}]"
            echo ""
            echo "Please look at /tmp/qemu-install.log"
            echo ""
            exit 1
        fi
    fi
}

#### Begin of Script
echo "What do you want to do?"
echo "   1) Install everything (Qemu with SeaBios, Libvirt, VirtManager)"
echo "   2) Install Qemu with SeaBios"
echo "   3) Install Libvirt"
echo "   4) Install Virt-Manager"
echo "   5) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" ]]; do
	read -p "Select an option [1-5]: " OPTION
done

if [[ "$OPTION" == "5"  ]]; then
    exit
fi

if [[ ! -z "$PY3_VER" && ! -z "$PY2_VER" ]]; then
    if [[ "$OPTION" == "1" || "$OPTION" == "4"  ]]; then
        echo ""
        echo "Which Virt-Manager version do you want to install"
        echo "    1) Virt-Manager 1.5 (Python 2 required) - detected ${PY2_VER}"
        echo "    2) Virt-Manager 2.0 (Python 3 required) - detected ${PY3_VER}"
        echo ""
        while [[ $VV != "1" && $VV != "2" ]]; do
            read -p "Select an option [1-2]: " VV
        done
        case $VV in
        1)
            VIRTMANAGER_VER=1.5
        ;;
        2)
            VIRTMANAGER_VER=2.0
        ;;
        esac
    fi
elif [[ ! -z "$PY2_VER" ]]; then
    echo "Virt-Manager 1.5 will be installed since only Python ${PY2_VER} is detected."
    VIRTMANAGER_VER=1.5
elif [[ ! -z "$PY3_VER" ]]; then
    echo "Virt-Manager 2.0 will be installed since only Python ${PY3_VER} is detected."
    VIRTMANAGER_VER=2.0
elif [[ "$OPTION" == "1" ]]; then
    echo "Virt-Manager cannot be installed as no python versions detected."
    VIRTMANAGER_VER=0
elif [[ "$OPTION" == "4" ]]; then
    echo "Virt-Manager cannot be installed as no python versions detected."
    exit
fi

echo ""
# install dependencies
install_deps
numa_install
install_spice_support

# install qemu with seabios
if [[ "$OPTION" == "1" || "$OPTION" == "2"  ]]; then
    install_qemu
    install_seabios
fi

# install libvirt
if [[ "$OPTION" == "1" || "$OPTION" == "3"  ]]; then
    install_libvirt
    add_user_to_group
fi

# install Virt-Manager
if [[ "$OPTION" == "1" || "$OPTION" == "4"  ]]; then
    if [[ "$VIRTMANAGER_VER" == *"1"* ]]; then
        install_virtmanager_15
    elif [[ "$VIRTMANAGER_VER" == *"2"* ]]; then
        install_virtmanager_2
    fi
fi

# We're done !
echo ""
echo -e "       ${CGREEN}Installation successful !${CEND}"
echo ""
echo "       Installation log: /tmp/qemu-install.log"
echo ""
