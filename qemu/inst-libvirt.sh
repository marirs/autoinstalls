#!/bin/bash
#
# Description: Install Libvirt & VirtManager
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
[ -f "/tmp/libvirt-install.log" ] && rm -f /tmp/libvirt-install.log

# Versions
libvirt_version=10.0.0
virtmanager_version=5.0.0
python_version=3.8

# gather system info
vendor_id=$(cat /proc/cpuinfo | grep 'vendor_id' | head -1 | cut -d":" -f2 | xargs)
cpuid=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | xargs)
cpuspeed=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | cut -d "@" -f 2 | xargs)
is_numa=$(lscpu | grep -i numa | head -1 | cut -d":" -f2 | xargs)
cores=$(nproc)
os=$(cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release 2>/dev/null | grep "_ID=" | cut -d"=" -f2 | xargs)
architecture=$(arch)
py3=$(which python3 2>/dev/null)
curr_py3_version=$($py3 -V 2>/dev/null | cut -d" " -f2)
required_py3_version="3.8"

function ver { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3,$4); }'; }

# Architecture support
if [[ "$architecture" != "x86_64" && "$architecture" != "aarch64" && "$architecture" != "arm64" ]]; then
    echo "${CRED}$architecture not supported, cannot be installed. You need x86_64 or ARM64 system.${CEND}"
    exit 1
fi

# Python version check
[[ -z $py3 ]] && echo "${CRED}python3 not found, cannot be installed${CEND}" && exit 1
[ $(ver $curr_py3_version) -lt $(ver $required_py3_version) ] && echo -e "${CRED}Required $required_py3_version+: detected python $curr_py3_version not supported, cannot continue${CEND}" && exit 1

# Display current system info
echo -e "${CGREEN}System Information:${CEND}"
echo -e "  OS: $os $os_ver"
echo -e "  Architecture: $architecture"
echo -e "  CPU Cores: $cores"
echo -e "  CPU: $cpuid"
echo -e "  Python Version: $curr_py3_version"
echo -e "  Target Libvirt: $libvirt_version"
echo -e "  Target Virt-Manager: $virtmanager_version"
echo ""

libvirt_opts="--system --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-yajl=yes --with-openssl --with-storage-rbd --with-qemu=yes --with-esx --with-xen --with-openvz=no  --with-dtrace --disable-nls --without-apparmor --without-secdriver-apparmor --without-apparmor-mount --without-apparmor-profiles "
if [[ "$is_numa" -ge "1" ]]; then
    libvirt_opts=$(echo $libvirt_opts; echo --with-numad)
fi

function install_deps() {
    pkgs="libjbig0 python3-cffi libaa1 libxkbcommon0 python3-libvirt radvd libgtksourceview-4-common ayatana-indicator-application libsndfile1 zfs-fuse \
	python3-cffi-backend libbrlapi-dev libvorbis0a libvorbisenc2 libnetcf1 libopus0 libgtk-3-common libatk1.0-0 dconf-cli x11-common \
	libguestfs-gobject-1.0-0 libxslt-dev libxinerama1 libphodav-2.0-common libpciaccess0 libtiff5 libogg0 liblcms2-2 libatk1.0-data libxtst6 \
	libsoup2.4-1 libiscsi7 gir1.2-gtk-vnc-2.0 python3-guestfs msr-tools gir1.2-gtk-3.0 gir1.2-vte-2.91 libgstreamer-plugins-base1.0-0 \
	systemtap-sdt-dev libspice-client-glib-2.0-8 libguestfs-gobject-dev libpangoxft-1.0-0 python3 libgbm1 libsoup-gnome2.4-1 pkg-config \
	python3-libxml2 libvte-common libnspr4 librest-0.7-0 cpu-checker gir1.2-libvirt-glib-1.0 python3-pkgconfig libpython3-stdlib \
	libtag1v5-vanilla ibverbs-providers python3-gi-cairo libguestfs-hfsplus libsamplerate0 libphodav-2.0-0 python3-ntlm-auth librados2 \
	libwayland-server0 gnome-keyring libgovirt-common sharutils-doc libxcb-render0 libatspi2.0-0 gtk-doc-tools \
	libgtk-3-0 libavahi-common-data libspeex1 libcdparanoia0 wodim gir1.2-libosinfo-1.0 adwaita-icon-theme libxenstore3.0 libyajl2 libxcb-shm0 \
	libgudev-1.0-0 libharfbuzz0b libxfixes3 gobject-introspection libyajl-dev libibverbs1 libaio1 gir1.2-gdkpixbuf-2.0 genisoimage libosinfo-1.0-dev \
	libproxy1v5 libavc1394-0 python3-pkg-resources libappindicator3-1 libpciaccess-dev libvte-dev libthai-data debootstrap spice-client-glib-usb-acl-helper \
	libxml2-utils libmpg123-0 python3-argcomplete glib-networking-services at-spi2-core libwavpack1 libguestfs-zfs augeas-tools mesa-utils libgl1-mesa-glx \
	libxdamage1 libspice-server1 libdbusmenu-glib4 gtk-update-icon-cache libbluetooth3 gir1.2-spiceclientgtk-3.0 libcroco3 libgdk-pixbuf2.0-common \
	libgtk-vnc-2.0-dev libavahi-client3 libvte-2.91-0 libglapi-mesa libwayland-cursor0 intltool librdmacm1 libv4l-0 libcolord2 libpulse0 hicolor-icon-theme \
	fontconfig-config libusbredirparser1 libglvnd0 libasound2-data librsvg2-common libtag1v5 libflac8 libgstreamer1.0-0 gir1.2-rest-0.7 \
	libpixman-1-0 libepoxy0 libgtk-3-dev libxrender1 libxml2-dev libxcb-sync1 libx11-xcb1 libgraphite2-3 systemtap libcups2 dnsmasq-utils dnsmasq \
	dconf-service libwayland-egl1-mesa gir1.2-atk-1.0 librbd1 sharutils osinfo-db-tools libosinfo-1.0-0 glib-networking librsvg2-2 libdconf1 libdatrie1 \
	cdrkit-doc gir1.2-appindicator3-0.1 auditd libiec61883-0 libspice-client-gtk-3.0-5 libxcb-dri3-0 libpangocairo-1.0-0 libdv4 libasound2 \
	libavahi-common3 gstreamer1.0-x python3-pip libspice-client-gtk-3.0-dev libpulse-mainloop-glib0 libgdk-pixbuf2.0-0 libgovirt-dev libthai0 \
	libcaca0 gstreamer1.0-plugins-base python3-dev libpango-1.0-0 libgtk-3-bin libgirepository1.0-dev gir1.2-spiceclientglib-2.0 libgdk-pixbuf2.0-bin \
	dconf-gsettings-backend pm-utils fontconfig guestfsd libasyncns0 libxcb-dri2-0 libindicator3-7 libatk-bridge2.0-0 liborc-0.4-0 gstreamer1.0-plugins-good \
	libxcursor1 libgovirt2 libjson-glib-1.0-0 libpangoft2-1.0-0 libguestfs-dev libegl1 libmp3lame0 libnss3 libgtk-vnc-2.0-0 \
	glib-networking-common libwayland-client0 libgtksourceview-4-0 libjson-glib-1.0-common osinfo-db libxcomposite1 libdbusmenu-gtk3-4 libfdt1 \
	python3-future python3-gi libxshmfence1 python3-requests libjack-jackd2-0 libsdl1.2debian libcairo2 libaugeas0 libxft2 libxrandr2 \
	libcacard0 gir1.2-secret-1 gir1.2-guestfs-1.0 libgtksourceview-4-dev libegl-mesa0 libfontconfig1 augeas-doc libvte-2.91-common libxi6 ifupdown \
	gsettings-desktop-schemas libxcb-present0 gir1.2-pango-1.0 libvisual-0.4-0 unzip libguestfs-xfs libtheora0 libgvnc-1.0-0 ssh-askpass nfs-common \
	gir1.2-freedesktop libguestfs-tools libraw1394-11 augeas-lenses libdconf-dev libnl-route-3-200 fonts-dejavu-core libvirt-dev libxv1 python3-cairo \
	libcairo-gobject2 libshout3 libusbredirhost1 libxcb-xfixes0 libtwolame0 gir1.2-govirt-1.0 libv4lconvert0 build-essential cmake libfuse-dev doxygen \
	bison bison++ bisonc++ flex flexc++ flexml libjsoncpp-dev libjsoncpp1 valgrind libfastjson4 libfastjson-dev libjson-c-dev libjson-c4 check "
    if [[ "$os" == *"ubuntu"* ]]; then
        pkgs=$(echo $pkgs; echo "libjpeg62-dev humanity-icon-theme ubuntu-mono libgtk-3-devpkg-config libgstreamer-plugins-good1.0-0 libjpeg8 zfsutils ")
        cd /tmp/ || return
    elif [[ "$os" == *"debian"* ]]; then
        pkgs=$(echo $pkgs; echo "libjpeg62-turbo-dev human-icon-theme fonts-ubuntu-font-family-console fonts-ubuntu gstreamer1.0-plugins-good libturbojpeg0 libzfslinux-dev zfsutils-linux ")
    fi
	if [[ "$is_numa" -ge "1" ]]; then
		pkgs=$(echo $pkgs; echo "numactl libnuma-dev")	
	fi
	total_packages=$(echo $pkgs | wc -w)
    echo -e "${CGREEN}Installing $total_packages dependancies...${CEND}"
    for pkg in $pkgs; do
		echo -ne "    - ${CBLUE}installing $pkg ...                                                     ${CEND}\r"
        apt-get install -y $pkg >> /tmp/apt-packages.log 2>&1
        if [ $? -ne 0 ]; then
			echo -ne "\n"
            echo -e "    - ${CRED}$pkg failed installation; see /tmp/apt-packages.log for more info.${CEND}"
            exit 1
        fi
    done
	echo -ne "                                                              \r"
    echo -e "${CGREEN}Downloading additional dependancies...${CEND}"
	cd /tmp || return
	[ -f libvirt-glib-3.0.0.tar.gz ] && rm -rf libvirt-glib-3.0.0.tar.gz >> /tmp/apt-packages.log 2>&1
	[ -d libvirt-glib-3.0.0 ] && rm -rf libvirt-glib-3.0.0 >> /tmp/apt-packages.log 2>&1
	wget https://libvirt.org/sources/glib/libvirt-glib-3.0.0.tar.gz >> /tmp/apt-packages.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$pkg failed downloading libvirt-glib-3.0.0.tar.gz; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
    tar xf libvirt-glib-3.0.0.tar.gz >> /tmp/apt-packages.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$pkg failed untaring libvirt-glib-3.0.0.tar.gz; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
    cd libvirt-glib-3.0.0 || return
    aclocal && libtoolize --force >> /tmp/apt-packages.log 2>&1
    automake --add-missing >> /tmp/apt-packages.log 2>&1
    echo -e "${CGREEN}Configuring additional dependancies...${CEND}"
    ./configure >> /tmp/apt-packages.log 2>&1
     if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$pkg failed configuring libvirt-glib-3.0.0; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
    echo -e "${CGREEN}Make additional dependancies...${CEND}"
   	make -j$cores >> /tmp/apt-packages.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$pkg failed to 'make -j$cores'; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
    echo -e "${CGREEN}Installing additional dependancies...${CEND}"
	make install  >> /tmp/apt-packages.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$pkg failed to 'make install'; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
	/sbin/ldconfig >> /tmp/apt-packages.log 2>&1

	# pip3 requirements	
	requirements="requests six urllib3 ipaddr ipaddress idna dbus-python certifi lxml cryptography pyOpenSSL chardet asn1crypto pycairo PySocks PyGObject"
	total_requirements=$(echo $requirements | wc -w)
    echo -e "${CGREEN}Installing $total_requirements required pip3 modules...${CEND}"
    for requirement in $requirements; do
		echo -ne "    - ${CBLUE}installing $requirement ...                                                     ${CEND}\r"
        pip3 install -U $requirement >> /tmp/apt-packages.log 2>&1
        if [ $? -ne 0 ]; then
			echo -ne "\n"
            echo -e "    - ${CRED}$requirement module failed installation; see /tmp/apt-packages.log for more info.${CEND}"
            exit 1
        fi
    done
	echo -ne "                                                              \r"
	[[ "$is_numa" -ge "1" ]] && install_numa
}

function install_numa() {
	echo -e "${CGREEN}Cloning numad requirements...${CEND}"
	cd /tmp
	[ -d numad ] && rm -rf numad  >> /tmp/libvirt-install.log 2>&1
	git clone --quiet https://github.com/K1773R/numad.git >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}$numad:  failed to clone from repo; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
	cd numad || return
	echo -e "${CGREEN}Make numad...${CEND}"
	make -j$cores >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}numad: failed 'make -j$cores'; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
	echo -e "${CGREEN}Installing numad...${CEND}"
	make install >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}numad:  failed to 'make install'; see /tmp/apt-packages.log for more info.${CEND}"
		exit 1
	fi
}

function _replace() {
    pattern=$1
    repl=$2
    filename=$3
    if sed -i "s/$pattern/$repl/g" $filename >> /tmp/libvirt-install.log 2>&1; then
        echo -e "    - ${CGREEN}$filename configuration modified!${CEND}"
    else
        echo -e "    - ${CRED}$filename configuration not modified!${CEND}"
    fi
}

function clean_up() {
	cd /tmp || return
    echo -ne "${CBLUE}Cleaning up    [...]${CEND}\r"
	[ -f libvirt-glib-3.0.0.tar.gz ] && rm -rf libvirt-glib-3.0.0.tar.gz >> /tmp/apt-packages.log 2>&1
	[ -d libvirt-glib-3.0.0 ] && rm -rf libvirt-glib-3.0.0 >> /tmp/apt-packages.log 2>&1
	[ -f libvirt-$libvirt_version.tar.xz ] && rm -rf libvirt-$libvirt_version.tar.xz >> /tmp/apt-packages.log 2>&1
	[ -d libvirt-$libvirt_version ] && rm -rf libvirt-$libvirt_version >> /tmp/apt-packages.log 2>&1
	[ -f v$libvirt_version.zip ] && rm -f v$libvirt_version.zip  >> /tmp/libvirt-install.log 2>&1
	[ -d libvirt-python-$libvirt_version ] && rm -rf libvirt-python-$libvirt_version  >> /tmp/libvirt-install.log 2>&1
	[ -d numad ] && rm -rf numad  >> /tmp/libvirt-install.log 2>&1
	[ -d libvirt ] && rm -rf /tmp/libvirt  >> /tmp/libvirt-install.log 2>&1
	[ -d virt-manager ] && rm -rf /tmp/virt-manager  >> /tmp/libvirt-install.log 2>&1
    echo -ne "${CBLUE}Cleaning up    [DONE]${CEND}\r"
    echo -ne "\n"
    echo -e "Dependancy installation logs: ${CCYAN}/tmp/apt-packages.log${CEND}"
    echo -e "QEMU System installation logs: ${CCYAN}/tmp/libvirt-install.log${CEND}"
}

function add_to_libvirt() {
	# check to see what group is available (libvirt/libvirtd)
	if grep -q -E '^libvirtd:' /etc/group; then
		groupname="libvirtd"
	elif grep -q -E '^libvirt:' /etc/group; then
		groupname="libvirt"
	else
		# create group if missed
		groupname="libvirt"
		groupadd libvirt
	fi
    echo -e "${CGREEN}Adding current user:${USER} into $groupname group${CEND}"
    grp=$(getent group $groupname)
    echo -e "    - ${CMAGENTA}Libvirt: $grp ...${CEND}"
    getent group $groupname 2>&1 > /dev/null && usermod -a -G $groupname ${USER} >> /tmp/libvirt-install.log 2>&1
    grp=$(getent group $groupname)
    echo -e "    - ${CMAGENTA}Libvirt: $grp${CEND}${CGREEN}    OK${CEND}"
    echo -e "    - You can add more users into $groupname group using the command: ${CBLUE}usermod -a -G $groupname <username>${CEND}"
}

function install_libvirt() {
	echo -ne "${CGREEN}Checking and removing old versions of libvirt....${CEND}\r"
	apt-get purge libvirt0 libvirt-bin libvirt-$libvirt_version >> /tmp/libvirt-install.log 2>&1
    dpkg -l|grep "libvirt-[0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}"|cut -d " " -f 3|sudo xargs dpkg --purge --force-all >> /tmp/libvirt-install.log 2>&1
	[ -f  /lib/x86_64-linux-gnu/libvirt.so.0 ] && rm -f  /lib/x86_64-linux-gnu/libvirt.so.0
	[ -f /lib/x86_64-linux-gnu/libvirt-qemu.so.0 ] && rm -f /lib/x86_64-linux-gnu/libvirt-qemu.so.0
	[ -f /lib/x86_64-linux-gnu/libvirt-lxc.so.0 ] && rm -f /lib/x86_64-linux-gnu/libvirt-lxc.so.0
	[ -f /lib/x86_64-linux-gnu/libvirt-admin.so.0 ] && rm -f /lib/x86_64-linux-gnu/libvirt-admin.so.0
	echo -ne "${CGREEN}Checking and removing old versions of libvirt    OK${CEND}\r"
	echo -ne "\n"

	echo -e "${CGREEN}Downloading libvirt...${CEND}"
	cd /tmp || return
	# clean up previous downloads if any
	[ -d libvirt-$libvirt_version ] && rm -rf libvirt-$libvirt_version  >> /tmp/libvirt-install.log 2>&1
	[ -f  libvirt-$libvirt_version.tar.xz ] && rm -f libvirt-$libvirt_version.tar.xz  >> /tmp/libvirt-install.log 2>&1

	wget https://libvirt.org/sources/libvirt-$libvirt_version.tar.xz  >> /tmp/libvirt-install.log 2>&1
	if [ ! -f libvirt-$libvirt_version.tar.xz ]; then
		echo -e "    - ${CRED}failed downloading libvirt-$libvirt_version.tar.xz!${CEND}"
		exit 1
	fi
	tar xf libvirt-$libvirt_version.tar.xz  >> /tmp/libvirt-install.log 2>&1
	cd libvirt-$libvirt_version || return
	git init >> /tmp/libvirt-install.log 2>&1
	git remote add libvtmp https://github.com/libvirt/libvirt  >> /tmp/libvirt-install.log 2>&1
	echo -e "${CGREEN}Configuring libvirt...${CEND}"
	mkdir -p build >> /tmp/libvirt-install.log 2>&1
	cd build || return
	../autogen.sh $libvirt_opts >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to configure (autogen.sh); see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	echo -e "${CGREEN}Make libvirt...${CEND}"
	make -j$cores  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed 'make -j$cores'; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	echo -e "${CGREEN}Installing libvirt...${CEND}"
	make install  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed 'make install'; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi

	# check if linked correctly
	echo -ne "${CGREEN}Checking libvirt linkages    [...]${CEND}\r"
	if [ -f /usr/lib/libvirt-qemu.so ]; then
		libvirt_so_path=/usr/lib/
		export PKG_CONFIG_PATH=/usr/lib/pkgconfig/
	elif [ -f /usr/lib64/libvirt-qemu.so ]; then
		libvirt_so_path=/usr/lib64/
		export PKG_CONFIG_PATH=/usr/lib64/pkgconfig/
	fi
	if [[ -n "$libvirt_so_path" ]]; then
		for so_path in $(ls ${libvirt_so_path}libvirt*.so.0); do ln -s $so_path /lib/$(uname -m)-linux-gnu/$(basename $so_path) >> /tmp/libvirt-install.log 2>&1; done
	fi
	echo -ne "${CGREEN}Checking libvirt linkages    [Done]${CEND}\r"
	echo -ne "\n"
}

function configure_libvirt_socks() {
	if [ -f /etc/libvirt/libvirtd.conf ]; then
        libvirt_path="/etc/libvirt/libvirtd.conf"
    elif [ -f /usr/local/etc/libvirt/libvirtd.conf ]; then
        libvirt_path="/usr/local/etc/libvirt/libvirtd.conf"
    fi

	echo -e "${CGREEN}Configuring libvirt with secure authentication...${CEND}"
    _replace '#unix_sock_group' 'unix_sock_group' "$libvirt_path"
    _replace '#unix_sock_ro_perms = "0777"' 'unix_sock_ro_perms = "0750"' "$libvirt_path"
    _replace '#unix_sock_rw_perms = "0770"' 'unix_sock_rw_perms = "0750"' "$libvirt_path"
    _replace '#auth_unix_ro = "none"' 'auth_unix_ro = "polkit"' "$libvirt_path"
    _replace '#auth_unix_rw = "none"' 'auth_unix_rw = "polkit"' "$libvirt_path"
}

function start_libvirt_services() {
    systemctl daemon-reload >> /tmp/libvirt-install.log 2>&1
    systemctl enable libvirtd  >> /tmp/libvirt-install.log 2>&1
	systemctl enable libvirt-guests >> /tmp/libvirt-install.log 2>&1
	systemctl enable virtlogd >> /tmp/libvirt-install.log 2>&1
	systemctl enable virtlockd >> /tmp/libvirt-install.log 2>&1
	echo -e "${CGREEN}Starting virtlockd service...${CEND}\e"
    service virtlockd start  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to start virtlockd service; see /tmp/libvirt-install.log for more info. Skipping...${CEND}"
    fi
	echo -e "${CGREEN}Starting virtlogd service...${CEND}\e"
    service virtlogd start  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to start virtlogd service; see /tmp/libvirt-install.log for more info. Skipping...${CEND}"
    fi
	echo -e "${CGREEN}Starting libvirtd service...${CEND}\e"
    service libvirtd start  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to start libvirtd service; see /tmp/libvirt-install.log for more info. Skipping...${CEND}"
    fi
	echo -e "${CGREEN}Starting libvirt-guests service...${CEND}\e"
	service libvirt-guests start  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to start libvirt-guests service; see /tmp/libvirt-install.log for more info. Skipping...${CEND}"
    fi
}

function libvirt_python() {
	echo -e "${CGREEN}Downloading libvirt-python-$libvirt_version...${CEND}\e"
	cd /tmp || return
	[ -f v$libvirt_version.zip ] && rm -f v$libvirt_version.zip  >> /tmp/libvirt-install.log 2>&1
	[ -d libvirt-python-$libvirt_version ] && rm -rf libvirt-python-$libvirt_version  >> /tmp/libvirt-install.log 2>&1
	wget https://github.com/libvirt/libvirt-python/archive/v$libvirt_version.zip  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to download v$libvirt_version.zip; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
    unzip v$libvirt_version.zip  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to unzip v$libvirt_version; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
    cd "libvirt-python-$libvirt_version" || return  >> /tmp/libvirt-install.log 2>&1
	echo -e "${CGREEN}Building libvirt-python-$libvirt_version...${CEND}\e"
    python3 setup.py build  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to buid libvirt-python-$libvirt_version; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	echo -e "${CGREEN}Installing libvirt-python-$libvirt_version...${CEND}\e"
    pip3 install .  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed install libvirt-python-$libvirt_version; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
}

function install_virtmanager() {
	if [ -f /usr/lib/libvirt-qemu.so ]; then
        libvirt_so_path=/usr/lib/
        export PKG_CONFIG_PATH=/usr/lib/pkgconfig/
    elif [ -f /usr/lib64/libvirt-qemu.so ]; then
        libvirt_so_path=/usr/lib64/
        export PKG_CONFIG_PATH=/usr/lib64/pkgconfig/
    fi
	cd /tmp || return
	echo -e "${CGREEN}Cloning VirtManager...${CEND}\e"
	[ -d "virt-manager" ] && rm -rf virt-manager >> /tmp/libvirt-install.log 2>&1
	git clone https://github.com/virt-manager/virt-manager.git  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to clone virt-manager; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	cd "virt-manager" || return
	echo -e "${CGREEN}Building VirtManager...${CEND}\e"
	python3 setup.py build  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to buid virt-manager; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	echo -e "${CGREEN}Installing VirtManager...${CEND}\e"
	python3 setup.py install  >> /tmp/libvirt-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to install virt-manager; see /tmp/libvirt-install.log for more info.${CEND}"
        exit 1
    fi
	echo -e "${CGREEN}Updating default_uri to qemu:///system...${CEND}\e"
	if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ] ; then
	   	if ! grep "export LIBVIRT_DEFAULT_URI=qemu:///system" "$HOME/.zsh" >> /tmp/libvirt-install.log 2>&1; then 
		   	echo " " >> "$HOME/.zsh"
		   	echo "# libvirt config" >> "$HOME/.zsh"
			echo "export LIBVIRT_DEFAULT_URI=qemu:///system" >> "$HOME/.zsh"
		fi
    else
	   	if ! grep "export LIBVIRT_DEFAULT_URI=qemu:///system" "$HOME/.bashrc" >> /tmp/libvirt-install.log 2>&1; then 
		   	echo " " >> "$HOME/.bashrc"
		   	echo "# libvirt config" >> "$HOME/.bashrc"
			echo "export LIBVIRT_DEFAULT_URI=qemu:///system" >> "$HOME/.bashrc"
		fi
    fi
}

# begin installations step-by-step
install_deps
install_libvirt

# add current user to libvirt group
add_to_libvirt

configure_libvirt_socks
start_libvirt_services
libvirt_python

# install virt-manager
install_virtmanager

# clean-up the downloads, although not necessary
clean_up

echo ""
echo -e "${CGREEN}>> Libvirt $libvirt_version and Virt-Manager installation completed successfully!${CEND}"
echo ""
echo -e "${CCYAN}Installation Summary:${CEND}"
echo -e "  Libvirt Version: $libvirt_version"
echo -e "  Virt-Manager Version: $virtmanager_version"
echo -e "  Architecture: $architecture"
echo -e "  Python Version: $curr_py3_version"
echo -e "  Authentication: Polkit (secure)"
echo -e "  Services: Enabled and started"
echo ""
echo -e "${CCYAN}Next Steps:${CEND}"
echo -e "  1. Reload shell: source ~/.bashrc (or ~/.zsh)"
echo -e "  2. Log out and log back in for group changes"
echo -e "  3. Start virt-manager: virt-manager"
echo -e "  4. Test libvirt: virsh list --all"
echo ""
echo -e "${CCYAN}Services Status:${CEND}"
echo -e "  libvirtd: $(systemctl is-active libvirtd)"
echo -e "  virtlogd: $(systemctl is-active virtlogd)"
echo -e "  virtlockd: $(systemctl is-active virtlockd)"
echo ""
echo -e "${CCYAN}Logs:${CEND}"
echo -e "  Dependencies: /tmp/apt-packages.log"
echo -e "  Libvirt Install: /tmp/libvirt-install.log"
echo ""
echo -e "${CMAGENTA}If you reached here, seriously done!${CEND}"
# End of script
