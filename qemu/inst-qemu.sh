#!/bin/bash
#
# Description: Install Qemu
# Tested:
#       Debian: 9.x, 10.x, 11.x, 12.x
#       Ubuntu: 18.04, 20.04, 22.04, 24.04
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# clear log files
[ -f "/tmp/apt-packages.log" ] && rm -f /tmp/apt-packages.log
[ -f "/tmp/qemu-install.log" ] && rm -f /tmp/qemu-install.log

# Versions
qemu_version=8.2.0

# gather system info
vendor_id=$(cat /proc/cpuinfo | grep 'vendor_id' | head -1 | cut -d":" -f2 | xargs)
cpuid=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | xargs)
cpuspeed=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | cut -d "@" -f 2 | xargs)
is_numa=$(lscpu | grep -i numa | head -1 | cut -d":" -f2 | xargs)
cores=$(nproc)
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
architecture=$(arch)

# Architecture support
if [[ "$architecture" != "x86_64" && "$architecture" != "aarch64" && "$architecture" != "arm64" ]]; then
    echo "${CRED}$architecture not supported, cannot be installed. You need x86_64 or ARM64 system.${CEND}"
    exit 1
fi

# Display current system info
echo -e "${CGREEN}System Information:${CEND}"
echo -e "  OS: $os $os_ver"
echo -e "  Architecture: $architecture"
echo -e "  CPU Cores: $cores"
echo -e "  CPU: $cpuid"
echo -e "  Target QEMU: $qemu_version"
echo ""

# qemu patch replacement strings
src_misc_bios_table="07\/02\/18"
src_bios_table_date2="04\/01\/2014"
src_fw_smbios_date="11\/03\/2018"
qemu_hd_replacement="SAMSUNG MZ76E120"
qemu_dvd_replacement="HL-PQ-SV WB8"
bochs_cpu_replacement="IntelCPU"
if [[ "$vendor_id" == *"Amd"* ]]; then
    $bochs_cpu_replacement="AmdCPU"
fi
qemu_bochs_cpu='INTEL\/INTEL'
if [[ "$vendor_id" == *"Amd"* ]]; then
    $bochs_cpu_replacement="AMD\/AMD"
fi
qemu_space_replacement="intel "
if [[ "$vendor_id" == *"Amd"* ]]; then
    $bochs_cpu_replacement="amd "
fi
bochs_str="intel"
if [[ "$vendor_id" == *"Amd"* ]]; then
    $bochs_str="amd  "
fi

# qemu options
qemu_opts="--prefix=/usr --libexecdir=/usr/lib/qemu --localstatedir=/var --bindir=/usr/bin/ --enable-gnutls --enable-docs --enable-gtk --enable-vnc --enable-vnc-sasl --enable-vnc-png --enable-vnc-jpeg --enable-curl --enable-kvm  --enable-linux-aio --enable-cap-ng --enable-vhost-net --enable-vhost-crypto --enable-spice --enable-usb-redir --enable-lzo --enable-snappy --enable-bzip2 --enable-coroutine-pool --enable-libxml2 --enable-tcmalloc --enable-replication --enable-tools --enable-capstone"
if [[ "$is_numa" -ge "1" ]]; then
    qemu_opts=$(echo $qemu_opts; echo --enable-numa)
fi
qemu_targets="--target-list=i386-softmmu,x86_64-softmmu,i386-linux-user,x86_64-linux-user"

function install_deps() {
    pkgs="python3-libxml2 autotools-dev libnfs-dev libusbredirhost-dev libnl-route-3-dev python3-sphinx spice-client-gtk libssh2-1-dev libbz2-dev \
    libvde-dev xfslibs-dev libfdt-dev python3-libvirt libsasl2-dev zlib1g-dev libbrlapi-dev libaio-dev git libguestfs-tools glusterfs-client \
    spice-client-glib-usb-acl-helper libpixman-1-dev python3-requests spice-vdagent libgtk-3-dev libxml2-dev libnl-route-3-200 gir1.2-gtk-vnc-2.0 \
    libspice-server-dev libspice-protocol-dev libxml2-utils liblzo2-dev librdmacm-dev libgnutls28-dev libosinfo-1.0-dev libseccomp-dev automake libiscsi-dev \
    valgrind xmlto libvdeplug-dev gir1.2-spiceclientglib-2.0 libosinfo-1.0-0 libcap-dev gettext libnuma-dev libdevmapper-dev librbd-dev libyajl2 libsdl1.2-dev \
    python3-dev texinfo gir1.2-spiceclientgtk-3.0 libgoogle-perftools-dev libcurl4-gnutls-dev libcap-ng-dev python3-requests-cache meson libspice-server1 \
    python3-requests-unixsocket libsnappy-dev libspice-client-gtk-3.0-5 libspice-client-glib-2.0-8 libibverbs-dev libvte-2.91-0 libxen-dev libglib2.0-dev \
    libbluetooth-dev libspice-client-gtk-3.0-dev gobject-introspection libncurses5-dev autoconf genisoimage "
    if [[ "$os" == *"ubuntu"* ]]; then
        pkgs=$(echo $pkgs; echo "libjpeg62-dev acpica-tools")
        cd /tmp/ || return
    elif [[ "$os" == *"debian"* ]]; then
        pkgs=$(echo $pkgs; echo "libjpeg62-turbo-dev")
    fi
    total_packages=$(echo $pkgs | wc -w)
    echo -e "${CGREEN}Installing $total_packages dependancies...${CEND}"
    for pkg in $pkgs; do
		echo -ne "    - ${CBLUE}installing $pkg ...                                                     ${CEND}\r"
        apt install -y $pkg >> /tmp/apt-packages.log 2>&1
        if [ $? -ne 0 ]; then
			echo -ne "\n"
            echo -e "    - ${CRED}$pkg failed installation${CEND}"
            exit 1
        fi
    done
	echo -ne "                                                              \r"
}

function _replace() {
    pattern=$1
    repl=$2
    filename=$3
    if sed -i "s/$pattern/$repl/g" $filename >> /tmp/qemu-install.log 2>&1; then
        echo -e "    - ${CGREEN}$filename Patched!${CEND}"
    else
        echo -e "    - ${CRED}$filename Not Patched!${CEND}"
    fi
}

function patch_qemu() {
    echo -e "${CGREEN}Patching qemu...${CEND}"
    _replace "QEMU HARDDISK" "$qemu_hd_replacement" hw/ide/core.c
    _replace "QEMU HARDDISK" "$qemu_hd_replacement" hw/scsi/scsi-disk.c
    _replace "QEMU DVD-ROM" "$qemu_dvd_replacement" hw/ide/core.c
    _replace "QEMU DVD-ROM" "$qemu_dvd_replacement" hw/ide/atapi.c
    _replace "QEMU CD-ROM" "$qemu_dvd_replacement" hw/scsi/scsi-disk.c
    _replace "KVMKVMKVM\\0\\0\\0" "$vendor_id" target/i386/kvm.c
    _replace "QEMU PenPartner tablet" "ASUS PenPartner tablet" hw/usb/dev-wacom.c
    _replace 's->vendor = g_strdup("QEMU");' 's->vendor = g_strdup("ASUS");' hw/scsi/scsi-disk.c
    _replace 'padstr8(buf + 8, 8, "QEMU")' 'padstr8(buf + 8, 8, "ASUS")' hw/ide/atapi.c
    _replace "QEMU MICRODRIVE" "ASUS MICRODRIVE" hw/ide/core.c
    _replace "bochs" "$bochs_str" block/bochs.c
    _replace "BOCHS" "$bochs_str" include/hw/acpi/aml-build.h
    _replace "Bochs Pseudo" "Intel RealTime" roms/ipxe/src/drivers/net/pnic.c
}

function patch_seabios() {
    echo -e "${CGREEN}Patching seabios...${CEND}"
    _replace 'Bochs' 'DELL' src/config.h
    _replace 'BOCHSCPU' "$bochs_cpu_replacement" src/config.h 
    _replace '"BOCHS "' '"HPPC"' src/config.h
    _replace 'BXPC' 'HPPC' src/config.h
    _replace "QEMU\/Bochs" "$qemu_bochs_cpu" vgasrc/Kconfig
    _replace "qemu " "$qemu_space_replacement" vgasrc/Kconfig
    _replace "06\/23\/99" "$src_misc_bios_table" src/misc.c 
    _replace "04\/01\/2014" "$src_bios_table_date2" src/fw/biostables.c
    _replace "01\/01\/2011" "$src_fw_smbios_date" src/fw/smbios.c
    _replace '"SeaBios"' '"AMIBios"' src/fw/biostables.c

    FILES=(
        src/hw/blockcmd.c
        src/fw/paravirt.c
    )
    for file in "${FILES[@]}"; do
        _replace '"QEMU"' '"ASUS"' "$file"
    done

    _replace '"QEMU"' '"ASUS"' src/hw/blockcmd.c

    FILES=(
        "src/fw/acpi-dsdt.dsl"
        "src/fw/q35-acpi-dsdt.dsl"
    )
    for file in "${FILES[@]}"; do
        _replace '"BXPC"' '"HPPC"' "$file"
    done
    _replace '"BXPC"' '"HPPC"' src/fw/ssdt-pcihp.dsl
    _replace '"BXDSDT"' '"HPDSDT"' src/fw/ssdt-pcihp.dsl
    _replace '"BXPC"' '"HPPC"' src/fw/ssdt-proc.dsl
    _replace '"BXSSDT"' '"HPSSDT"' src/fw/ssdt-proc.dsl
    _replace '"BXPC"' '"HPPC"' src/fw/ssdt-misc.dsl
    _replace '"BXSSDTSU"' '"HPSSDTSU"' src/fw/ssdt-misc.dsl
    _replace '"BXSSDTSUSP"' '"HPSSDTSUSP"' src/fw/ssdt-misc.dsl 
    _replace '"BXSSDT"' '"HPSSDT"' src/fw/ssdt-proc.dsl
    _replace '"BXSSDTPCIHP"' '"HPSSDTPCIHP"' src/fw/ssdt-pcihp.dsl

    FILES=(
        src/fw/q35-acpi-dsdt.dsl
        src/fw/acpi-dsdt.dsl
        src/fw/ssdt-misc.dsl
        src/fw/ssdt-proc.dsl
        src/fw/ssdt-pcihp.dsl
        src/config.h
    )
    for file in "${FILES[@]}"; do
        _replace '"BXPC"' '"HPPC"' "$file"
    done
}

function clean_up() {
    echo -ne "${CBLUE}Cleaning up    [...]${CEND}\r"
    [ -f "/tmp/qemu-$qemu_version.tar.xz" ] && rm -f /tmp/qemu-$qemu_version.tar.xz >> /tmp/qemu-install.log 2>&1
    [ -d "/tmp/qemu-$qemu_version" ] && rm -rf /tmp/qemu-$qemu_version >> /tmp/qemu-install.log 2>&1
    [ -d "/tmp/seabios" ] && rm -rf /tmp/seabios >> /tmp/qemu-install.log 2>&1
    [ -d spice-protocol-0.14.2 ] && rm -rf spice-protocol-0.14.2 >> /tmp/qemu-install.log 2>&1 
    [ -f spice-protocol-0.14.2.tar.xz ] && rm -f spice-protocol-0.14.2.tar.xz >> /tmp/qemu-install.log 2>&1 
    echo -ne "${CBLUE}Cleaning up    [DONE]${CEND}\r"
    echo -ne "\n"
    echo -e "Dependancy installation logs: ${CCYAN}/tmp/apt-packages.log${CEND}"
    echo -e "QEMU System installation logs: ${CCYAN}/tmp/qemu-install.log${CEND}"
}

function add_to_kvm() {
    echo -e "${CGREEN}Adding current user:${USER} into kvm group${CEND}"
    grp=$(getent group kvm)
    echo -e "    - ${CMAGENTA}KVM: $grp ...${CEND}"
    getent group kvm 2>&1 > /dev/null && usermod -a -G kvm ${USER} >> /tmp/qemu-install.log 2>&1 || (groupadd kvm && usermod -a -G kvm ${USER}) >> /tmp/qemu-install.log 2>&1
    grp=$(getent group kvm)
    echo -e "    - ${CMAGENTA}KVM: $grp${CEND}${CGREEN}    OK${CEND}"
    echo -e "    - You can add more users into kvm group using the command: ${CBLUE}usermod -a -G kvm <username>${CEND}"
}

function install_spice_support() {
    echo -e "${CGREEN}Downloading spice-protocol requirements...${CEND}"
    cd /tmp
    [ -d spice-protocol-0.14.2 ] && rm -rf spice-protocol-0.14.2 >> /tmp/qemu-install.log 2>&1 
    [ -f spice-protocol-0.14.2.tar.xz ] && rm -f spice-protocol-0.14.2.tar.xz >> /tmp/qemu-install.log 2>&1 
    wget https://spice-space.org/download/releases/spice-protocol-0.14.2.tar.xz >> /tmp/qemu-install.log 2>&1 
    tar -xf spice-protocol-0.14.2.tar.xz >> /tmp/qemu-install.log 2>&1 
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to untar the spice protocol; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    cd spice-protocol-0.14.2 || return
    echo -e "${CGREEN}Building spice-protocol...${CEND}"
    meson build >> /tmp/qemu-install.log 2>&1 
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed 'meson build'; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    cd build || return
    echo -e "${CGREEN}Installing spice-protocol...${CEND}"
    meson install >> /tmp/qemu-install.log 2>&1 
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed 'meson install' spice-protocol; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
}

function install_seabios() {
    echo -e "${CGREEN}Downloading seabios...${CEND}"
    cd /tmp || return
    [ -d seabios ] && rm -rf seabios >> /tmp/qemu-install.log 2>&1
    git clone --quiet https://github.com/coreboot/seabios.git  >> /tmp/qemu-install.log 2>&1
    cd /tmp/seabios || return
    patch_seabios
    echo -e "${CGREEN}Make seabios...${CEND}"
    make -j$cores  >> /tmp/qemu-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed 'make -j$cores'; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi

    echo -e "${CGREEN}Copying seabios into qemu...${CEND}"
    [ -f "/usr/share/qemu/bios.bin" ] && cp -vf out/bios.bin "/usr/share/qemu/bios.bin"
    [ -f "/usr/share/qemu/bios-256k.bin" ] && cp -vf out/bios.bin "/usr/share/qemu/bios-256k.bin"
    [ -f "/usr/local/share/qemu/bios.bin" ] && cp -vf out/bios.bin "/usr/local/share/qemu/bios.bin"
    [ -f "/usr/local/share/qemu/bios-256k.bin" ] && cp -vf out/bios.bin "/usr/local/share/qemu/bios-256k.bin"
}

function install_qemu() {
    echo -e "${CGREEN}Downloading qemu...${CEND}"
    cd /tmp || return
    rm -r /usr/share/qemu  >> /tmp/qemu-install.log 2>&1
    rm -rf qemu-$qemu_version*  >> /tmp/qemu-install.log 2>&1
    wget https://download.qemu.org/qemu-$qemu_version.tar.xz  >> /tmp/qemu-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to download spice-protocol; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
    if [ -f qemu-$qemu_version.tar.xz ]; then
        tar xf qemu-$qemu_version.tar.xz >> /tmp/qemu-install.log 2>&1
        if [ $? -ne 0 ]; then
            echo -e "    - ${CRED}failed tar xf qemu downloaded file; see /tmp/qemu-install.log for more info.${CEND}"
            exit 1
        fi
    else
        echo -e "    - ${CRED}failed downloading qemu; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    mkdir -p qemu-$qemu_version/build >> /tmp/qemu-install.log 2>&1
    cd qemu-$qemu_version || return
    patch_qemu
    cd /tmp/qemu-$qemu_version/build || return
    PERL_MM_USE_DEFAULT=1 perl -MCPAN -e install "Perl/perl-podlators" >> /tmp/qemu-install.log 2>&1
    echo -e "${CGREEN}Configuring qemu...${CEND}"
    ../configure $qemu_opts $qemu_targets >> /tmp/qemu-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed qemu configuration; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Make qemu...${CEND}"
    make -j$cores >> /tmp/qemu-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed qemu 'make -j$nproc'; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Installing qemu...${CEND}"
    make install >> /tmp/qemu-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed qemu 'make install'; see /tmp/qemu-install.log for more info.${CEND}"
        exit 1
    fi
    # hack for libvirt/virt-manager
    echo -e "${CGREEN}Setting-up qemu for libvirt/virt-manager...${CEND}"
    if [ ! -f /usr/bin/qemu-system-x86_64-spice ]; then
        ln -s /usr/bin/qemu-system-x86_64 /usr/bin/qemu-system-x86_64-spice
    fi
    if [ ! -f /usr/bin/kvm-spice ]; then
        ln -s /usr/bin/qemu-system-x86_64 /usr/bin/kvm-spice
    fi
    if [ ! -f /usr/bin/kvm ]; then
        ln -s /usr/bin/qemu-system-x86_64 /usr/bin/kvm
    fi
}


# begin installations step-by-step
install_deps
install_spice_support
install_qemu
install_seabios

# add current user to kvm group
add_to_kvm

# enable kernel.sysreq
echo -e "${CGREEN}Enabling kernel.sysreq${CEND}"
if ! grep -q -E '^kernel.sysrq=1' /etc/sysctl.conf; then
    echo "kernel.sysrq=1" >> /etc/sysctl.conf
fi

# clean-up the downloads, although not necessary
clean_up

echo ""
echo -e "${CGREEN}>> QEMU $qemu_version installation completed successfully!${CEND}"
echo ""
echo -e "${CCYAN}Installation Summary:${CEND}"
echo -e "  QEMU Version: $qemu_version"
echo -e "  Architecture: $architecture"
echo -e "  CPU Cores: $cores"
echo -e "  KVM Support: Enabled"
echo -e "  SPICE Support: Installed"
echo -e "  SeaBIOS: Patched and installed"
echo ""
echo -e "${CCYAN}Next Steps:${CEND}"
echo -e "  1. Add users to kvm group: usermod -a -G kvm <username>"
echo -e "  2. Install libvirt: ./inst-libvirt.sh"
echo -e "  3. Install virt-manager for GUI management"
echo -e "  4. Test installation: qemu-system-x86_64 --version"
echo ""
echo -e "${CCYAN}Logs:${CEND}"
echo -e "  Dependencies: /tmp/apt-packages.log"
echo -e "  QEMU Install: /tmp/qemu-install.log"
echo ""
echo -e "${CMAGENTA}If you reached here, seriously done!${CEND}"
# End of script
