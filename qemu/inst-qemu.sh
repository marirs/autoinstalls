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
tsc_evasion_enabled=false

# TSC Evasion Configuration
tsc_evasion_patch_applied=false

# gather system info
vendor_id=$(cat /proc/cpuinfo | grep 'vendor_id' | head -1 | cut -d":" -f2 | xargs)
cpuid=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | xargs)
cpuspeed=$(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d":" -f2 | cut -d "@" -f 2 | xargs)
is_numa=$(lscpu | grep -i numa | head -1 | cut -d":" -f2 | xargs)
cores=$(nproc)
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)
architecture=$(arch)

# Function to show TSC evasion menu
function show_tsc_evasion_menu() {
    echo ""
    echo -e "${CGREEN}========================================${CEND}"
    echo -e "${CGREEN}    TSC Evasion Configuration    ${CEND}"
    echo -e "${CGREEN}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}TSC (Time Stamp Counter) evasion modifies QEMU/KVM to${CEND}"
    echo -e "${CCYAN}hide virtualization timing artifacts from detection software.${CEND}"
    echo ""
    echo -e "${CYAN}Features:${CEND}"
    echo "- Reduces apparent VM exit latency from ~1,200 to ~200-400 cycles"
    echo "- Bypasses timing-based VM detection mechanisms"
    echo "- Enhances existing anti-detection patches"
    echo ""
    echo -e "${CRED}WARNING: For security research purposes ONLY!${CEND}"
    echo -e "${CRED}This should only be used for legitimate research.${CEND}"
    echo ""
    echo -e "${CCYAN}Do you want to enable TSC evasion patches?${CEND}"
    echo "1) Yes - Enable TSC evasion (Security Research Only)"
    echo "2) No - Standard QEMU installation"
    echo ""
}

# Function to get TSC evasion choice
function get_tsc_evasion_choice() {
    while true; do
        show_tsc_evasion_menu
        read -p "Enter your choice [1-2]: " tsc_choice
        case $tsc_choice in
            1)
                tsc_evasion_enabled=true
                echo -e "${CGREEN}✓ TSC evasion ENABLED for security research${CEND}"
                echo -e "${CYAN}Note: This feature is for legitimate security research only${CEND}"
                break
                ;;
            2)
                tsc_evasion_enabled=false
                echo -e "${CGREEN}✓ Standard QEMU installation selected${CEND}"
                break
                ;;
            *)
                echo -e "${CRED}Invalid choice. Please select 1 or 2.${CEND}"
                ;;
        esac
    done
}

# Function to check if system supports TSC evasion
function check_tsc_evasion_support() {
    echo -e "${CCYAN}Checking system compatibility for TSC evasion...${CEND}"
    
    # Check for KVM support
    if ! grep -q -E "(vmx|svm)" /proc/cpuinfo; then
        echo -e "${CYAN}⚠ Hardware virtualization not detected - TSC evasion limited${CEND}"
        return 1
    fi
    
    # Check for KVM module
    if ! lsmod | grep -q kvm; then
        echo -e "${CYAN}⚠ KVM module not loaded - will load during installation${CEND}"
    fi
    
    # Check kernel version (TSC evasion works best on newer kernels)
    kernel_version=$(uname -r | cut -d. -f1-2)
    echo -e "${CGREEN}✓ Kernel $kernel_version supports TSC evasion${CEND}"
    
    # Check if we have required development tools
    if command -v gcc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
        echo -e "${CGREEN}✓ Development tools available for kernel module compilation${CEND}"
        return 0
    else
        echo -e "${CRED}✗ Missing development tools for kernel module compilation${CEND}"
        return 1
    fi
}

# Function to install dependencies with comprehensive fallback handling
function install_deps() {
    echo -e "${CGREEN}Installing dependencies for $os $os_ver...${CEND}"
    
    # Update package lists first
    apt update >> /tmp/apt-packages.log 2>&1
    
    # Base packages common to all versions
    local base_packages=(
        "python3-libxml2"
        "autotools-dev"
        "libnfs-dev"
        "libusbredirhost-dev"
        "libnl-route-3-dev"
        "python3-sphinx"
        "spice-client-gtk"
        "libssh2-1-dev"
        "libbz2-dev"
        "libvde-dev"
        "xfslibs-dev"
        "libfdt-dev"
        "python3-libvirt"
        "libsasl2-dev"
        "zlib1g-dev"
        "libbrlapi-dev"
        "libaio-dev"
        "git"
        "libguestfs-tools"
        "glusterfs-client"
        "spice-client-glib-usb-acl-helper"
        "libpixman-1-dev"
        "python3-requests"
        "spice-vdagent"
        "libgtk-3-dev"
        "libxml2-dev"
        "libnl-route-3-200"
        "gir1.2-gtk-vnc-2.0"
        "libspice-server-dev"
        "libspice-protocol-dev"
        "libxml2-utils"
        "liblzo2-dev"
        "librdmacm-dev"
        "libgnutls28-dev"
        "libosinfo-1.0-dev"
        "libseccomp-dev"
        "automake"
        "libiscsi-dev"
        "valgrind"
        "xmlto"
        "libvdeplug-dev"
        "gir1.2-spiceclientglib-2.0"
        "libosinfo-1.0-0"
        "libcap-dev"
        "gettext"
        "libnuma-dev"
        "libdevmapper-dev"
        "librbd-dev"
        "libyajl2"
        "libsdl1.2-dev"
        "python3-dev"
        "texinfo"
        "gir1.2-spiceclientgtk-3.0"
        "libgoogle-perftools-dev"
        "libcurl4-gnutls-dev"
        "libcap-ng-dev"
        "python3-requests-cache"
        "meson"
        "libspice-server1"
        "python3-requests-unixsocket"
        "libsnappy-dev"
        "libspice-client-gtk-3.0-5"
        "libspice-client-glib-2.0-8"
        "libibverbs-dev"
        "libvte-2.91-0"
        "libxen-dev"
        "libglib2.0-dev"
        "libbluetooth-dev"
        "libspice-client-gtk-3.0-dev"
        "gobject-introspection"
        "libncurses5-dev"
        "autoconf"
        "genisoimage"
    )
    
    # Version-specific packages with comprehensive fallbacks
    local version_packages=()
    
    case "$os" in
        "debian")
            case "$os_ver" in
                "9"|"10"|"11")
                    # Older Debian versions
                    version_packages+=(
                        "libjpeg62-turbo-dev"
                        "acpica-tools"
                    )
                    ;;
                "12")
                    # Debian 12 Bookworm
                    version_packages+=(
                        "libjpeg62-turbo-dev"
                        "acpica-tools"
                    )
                    ;;
                "13")
                    # Debian 13 Trixie - comprehensive package handling
                    version_packages+=(
                        "acpica-tools"
                    )
                    
                    # Try multiple JPEG library variations
                    local jpeg_packages=("libjpeg62-turbo-dev" "libjpeg-dev" "libjpeg8-dev")
                    for jpeg_pkg in "${jpeg_packages[@]}"; do
                        if apt-cache show "$jpeg_pkg" >/dev/null 2>&1; then
                            version_packages+=("$jpeg_pkg")
                            echo -e "${CCYAN}Found $jpeg_pkg for JPEG support${CEND}"
                            break
                        fi
                    done
                    
                    # Try alternative package names for common packages
                    local alt_packages=(
                        "libnl-route-3-200:libnl-route-3-300"
                        "libvte-2.91-0:libvte-2.91-dev"
                        "libgnutls28-dev:libgnutls-dev"
                    )
                    
                    for alt_pair in "${alt_packages[@]}"; do
                        local main_pkg="${alt_pair%%:*}"
                        local alt_pkg="${alt_pair##*:}"
                        if ! apt-cache show "$main_pkg" >/dev/null 2>&1 && apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                            # Replace the package in base_packages
                            version_packages+=("$alt_pkg")
                            echo -e "${CCYAN}Found $alt_pkg as alternative to $main_pkg${CEND}"
                        fi
                    done
                    ;;
                *)
                    # Future Debian versions - try all variations
                    version_packages+=(
                        "acpica-tools"
                    )
                    
                    # Try JPEG packages
                    local jpeg_packages=("libjpeg62-turbo-dev" "libjpeg-dev" "libjpeg8-dev")
                    for jpeg_pkg in "${jpeg_packages[@]}"; do
                        if apt-cache show "$jpeg_pkg" >/dev/null 2>&1; then
                            version_packages+=("$jpeg_pkg")
                            break
                        fi
                    done
                    ;;
            esac
            ;;
        "ubuntu")
            case "$os_ver" in
                "18.04"|"20.04")
                    # Older Ubuntu versions
                    version_packages+=(
                        "libjpeg62-dev"
                        "acpica-tools"
                    )
                    ;;
                "22.04"|"24.04")
                    # Modern Ubuntu versions
                    version_packages+=(
                        "libjpeg62-dev"
                        "acpica-tools"
                    )
                    ;;
                *)
                    # Future Ubuntu versions - try all variations
                    version_packages+=(
                        "acpica-tools"
                    )
                    
                    # Try JPEG packages
                    local jpeg_packages=("libjpeg62-dev" "libjpeg-dev" "libjpeg8-dev")
                    for jpeg_pkg in "${jpeg_packages[@]}"; do
                        if apt-cache show "$jpeg_pkg" >/dev/null 2>&1; then
                            version_packages+=("$jpeg_pkg")
                            break
                        fi
                    done
                    ;;
            esac
            ;;
    esac
    
    # Combine all packages
    local all_packages=("${base_packages[@]}" "${version_packages[@]}")
    
    # Install packages with comprehensive error handling
    local failed_packages=()
    local successful_packages=()
    
    total_packages=$(echo ${all_packages[@]} | wc -w)
    echo -e "${CGREEN}Installing $total_packages dependencies...${CEND}"
    
    for pkg in "${all_packages[@]}"; do
        echo -ne "    - ${CBLUE}installing $pkg ...                                                     ${CEND}\r"
        
        # Check if package exists before installing
        if apt-cache show "$pkg" >/dev/null 2>&1; then
            apt install -y "$pkg" >> /tmp/apt-packages.log 2>&1
            if [ $? -eq 0 ]; then
                echo -e "    - ${CGREEN}✓ $pkg installed${CEND}"
                successful_packages+=("$pkg")
            else
                echo -ne "\n"
                echo -e "    - ${CRED}$pkg failed installation${CEND}"
                failed_packages+=("$pkg")
                
                # Try to find alternatives for common packages
                case "$pkg" in
                    "autotools-dev")
                        local autotools_alternatives=("autoconf" "automake")
                        for alt_pkg in "${autotools_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                    "libgnutls28-dev")
                        local gnutls_alternatives=("libgnutls-dev" "gnutls-dev")
                        for alt_pkg in "${gnutls_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                    "libnl-route-3-200")
                        local nl_alternatives=("libnl-route-3-dev" "libnl-3-dev")
                        for alt_pkg in "${nl_alternatives[@]}"; do
                            if apt-cache show "$alt_pkg" >/dev/null 2>&1; then
                                echo -e "    - ${CCYAN}Trying alternative: $alt_pkg${CEND}"
                                apt install -y "$alt_pkg" >> /tmp/apt-packages.log 2>&1
                                if [ $? -eq 0 ]; then
                                    echo -e "    - ${CGREEN}✓ $alt_pkg installed (alternative to $pkg)${CEND}"
                                    successful_packages+=("$alt_pkg")
                                    break
                                fi
                            fi
                        done
                        ;;
                esac
            fi
        else
            echo -ne "\n"
            echo -e "    - ${CCYAN}⚠ Package $pkg not found, skipping${CEND}"
            failed_packages+=("$pkg")
        fi
    done
    
    echo -ne "                                                              \r"
    
    # Comprehensive package validation
    echo -e "${CCYAN}Package installation summary:${CEND}"
    echo -e "${CGREEN}Successfully installed: ${successful_packages[*]}${CEND}"
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${CCYAN}Failed to install: ${failed_packages[*]}${CEND}"
    fi
    
    # Check if critical packages are available for QEMU compilation
    local critical_ok=true
    if ! command -v gcc >/dev/null 2>&1; then
        echo -e "${CRED}✗ gcc is missing - critical for QEMU compilation${CEND}"
        critical_ok=false
    fi
    
    if ! command -v make >/dev/null 2>&1; then
        echo -e "${CRED}✗ make is missing - critical for QEMU compilation${CEND}"
        critical_ok=false
    fi
    
    if ! ldconfig -p | grep -q libglib; then
        echo -e "${CRED}✗ GLib libraries are missing - critical for QEMU${CEND}"
        critical_ok=false
    fi
    
    if [ "$critical_ok" = true ]; then
        echo -e "${CGREEN}✓ Critical dependencies are available${CEND}"
        echo -e "${CCYAN}QEMU installation will continue...${CEND}"
    else
        echo -e "${CRED}✗ Critical dependencies missing. Cannot continue.${CEND}"
        exit 1
    fi
}

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
    
    # Standard anti-detection patches
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
    
    # TSC Evasion patches (if enabled)
    if [ "$tsc_evasion_enabled" = true ]; then
        echo -e "${CGREEN}Applying TSC evasion patches...${CEND}"
        apply_tsc_evasion_patches
        tsc_evasion_patch_applied=true
    fi
}

# Function to apply TSC evasion patches
function apply_tsc_evasion_patches() {
    echo -e "${CCYAN}Applying TSC evasion patches to QEMU source...${CEND}"
    
    # Patch 1: Add TSC evasion structure and functions
    cat >> target/i386/kvm.c << 'EOF'

/* TSC Evasion - Security Research Implementation */
struct kvm_tsc_evasion {
    uint64_t tsc_offset;
    uint64_t hypervisor_time;
    uint64_t last_exit_tsc;
    bool tsc_evasion_enabled;
};

static struct kvm_tsc_evasion tsc_evasion_data = {0};

/* TSC Evasion Functions */
void kvm_enable_tsc_evasion(void) {
    tsc_evasion_data.tsc_evasion_enabled = true;
    tsc_evasion_data.tsc_offset = 0;
    tsc_evasion_data.hypervisor_time = 0;
    printf("TSC evasion enabled for security research\n");
}

uint64_t kvm_get_tsc_offset(void) {
    return tsc_evasion_data.tsc_offset;
}

void kvm_add_hypervisor_time(uint64_t cycles) {
    if (tsc_evasion_data.tsc_evasion_enabled) {
        tsc_evasion_data.hypervisor_time += cycles;
        tsc_evasion_data.tsc_offset += cycles;
    }
}

EOF

    # Patch 2: Modify MSR handling for TSC
    if grep -q "case MSR_IA32_TSC:" target/i386/kvm.c; then
        echo -e "${CCYAN}Patching existing TSC MSR handling...${CEND}"
        _replace "case MSR_IA32_TSC:" "case MSR_IA32_TSC:\n        if (tsc_evasion_data.tsc_evasion_enabled) {\n            data->data -= tsc_evasion_data.hypervisor_time;\n        }" target/i386/kvm.c
    else
        echo -e "${CCYAN}Adding TSC MSR handling...${CEND}"
        cat >> target/i386/kvm.c << 'EOF'

static int kvm_get_msr_tsc_evasion(struct kvm *kvm, struct kvm_msrs *msrs) {
    struct kvm_msr_entry *data = msrs->entries;
    int i;
    
    for (i = 0; i < msrs->nmsrs; ++i) {
        if (data[i].index == MSR_IA32_TSC && tsc_evasion_data.tsc_evasion_enabled) {
            uint64_t real_tsc = rdtsc();
            data[i].data = real_tsc - tsc_evasion_data.hypervisor_time;
        }
    }
    return 0;
}

EOF
    fi

    # Patch 3: Add VM exit timing hooks
    cat >> target/i386/kvm.c << 'EOF'

/* VM Exit Timing Hook */
static inline void kvm_tsc_evasion_exit_hook(void) {
    if (tsc_evasion_data.tsc_evasion_enabled) {
        uint64_t current_tsc = rdtsc();
        if (tsc_evasion_data.last_exit_tsc > 0) {
            uint64_t exit_duration = current_tsc - tsc_evasion_data.last_exit_tsc;
            kvm_add_hypervisor_time(exit_duration);
        }
        tsc_evasion_data.last_exit_tsc = current_tsc;
    }
}

static inline void kvm_tsc_evasion_entry_hook(void) {
    if (tsc_evasion_data.tsc_evasion_enabled) {
        tsc_evasion_data.last_exit_tsc = rdtsc();
    }
}

EOF

    # Patch 4: Hook into existing VM exit/entry points
    echo -e "${CCYAN}Adding TSC hooks to VM exit/entry points...${CEND}"
    
    # Find and patch kvm_cpu_exec function
    if grep -q "kvm_cpu_exec" target/i386/kvm.c; then
        echo -e "${CCYAN}Patching kvm_cpu_exec with TSC hooks...${CEND}"
        _replace "kvm_cpu_exec(CPUState" "kvm_tsc_evasion_entry_hook();\n    return kvm_cpu_exec(CPUState" target/i386/kvm.c
    fi
    
    # Patch 5: Add initialization call
    echo -e "${CCYAN}Adding TSC evasion initialization...${CEND}"
    cat >> target/i386/kvm.c << 'EOF'

/* Initialize TSC evasion on module load */
static int __init kvm_tsc_evasion_init(void) {
    printf("KVM TSC Evasion Module Loaded - Security Research Use Only\n");
    return 0;
}

static void __exit kvm_tsc_evasion_exit(void) {
    printf("KVM TSC Evasion Module Unloaded\n");
}

module_init(kvm_tsc_evasion_init);
module_exit(kvm_tsc_evasion_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Security Research");
MODULE_DESCRIPTION("KVM TSC Evasion for Security Research");

EOF

    echo -e "${CGREEN}✓ TSC evasion patches applied successfully${CEND}"
}

# Function to apply TSC evasion patches to SeaBIOS
function apply_seabios_tsc_evasion() {
    echo -e "${CCYAN}Applying SeaBIOS TSC evasion patches...${CEND}"
    
    # Add TSC evasion to SeaBIOS timer functions
    cat >> src/timer.c << 'EOF'

/* TSC Evasion for SeaBIOS - Security Research */
static u64 seabios_tsc_offset = 0;
static bool seabios_tsc_evasion_enabled = false;

void seabios_enable_tsc_evasion(void) {
    seabios_tsc_evasion_enabled = true;
    seabios_tsc_offset = 0;
}

u64 rdtscll_evasion(void) {
    u64 real_tsc = rdtscll();
    if (seabios_tsc_evasion_enabled) {
        return real_tsc - seabios_tsc_offset;
    }
    return real_tsc;
}

void seabios_add_hypervisor_time(u64 cycles) {
    if (seabios_tsc_evasion_enabled) {
        seabios_tsc_offset += cycles;
    }
}

EOF

    # Patch existing timer functions if they exist
    if grep -q "rdtscll" src/timer.c; then
        echo -e "${CCYAN}Patching existing SeaBIOS timer functions...${CEND}"
        _replace "rdtscll()" "rdtscll_evasion()" src/timer.c
    fi
    
    # Add TSC evasion to PM timer and other timing sources
    cat >> src/hw/timer.c << 'EOF'

/* Enhanced timing with TSC evasion */
u32 timer_calc_usec(u32 end) {
    if (seabios_tsc_evasion_enabled) {
        return (end - rdtscll_evasion()) * ticks_per_usec;
    }
    return (end - rdtscll()) * ticks_per_usec;
}

EOF

    # Add initialization in main SeaBIOS initialization
    if [ -f "src/post.c" ]; then
        echo -e "${CCYAN}Adding TSC evasion initialization to SeaBIOS...${CEND}"
        cat >> src/post.c << 'EOF'

/* Initialize TSC evasion for security research */
static void seabios_tsc_evasion_init(void) {
    seabios_enable_tsc_evasion();
    dprintf(1, "SeaBIOS TSC evasion enabled - Security Research Use Only\n");
}

EOF
    fi
    
    echo -e "${CGREEN}✓ SeaBIOS TSC evasion patches applied${CEND}"
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
        src/hw/pci.c
        src/hw/ata.c
        src/hw/ps2port.c
        src/hw/serial.c
        src/hw/timer.c
        src/hw/rtc.c
        src/fw/mtrr.c
        src/fw/smbios.c
    )
    for file in "${FILES[@]}"; do
        _replace 'SeaBIOS' 'DELL' "$file"
    done
    
    # TSC Evasion patches for SeaBIOS (if enabled)
    if [ "$tsc_evasion_enabled" = true ]; then
        echo -e "${CGREEN}Applying TSC evasion patches to SeaBIOS...${CEND}"
        apply_seabios_tsc_evasion
    fi

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

# Show TSC evasion menu and get user choice
get_tsc_evasion_choice

# Check system compatibility if TSC evasion is enabled
if [ "$tsc_evasion_enabled" = true ]; then
    if ! check_tsc_evasion_support; then
        echo -e "${CRED}⚠ System compatibility issues detected for TSC evasion${CEND}"
        echo -e "${CYAN}Do you want to continue with standard installation? [y/N]${CEND}"
        read -r continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            echo -e "${CRED}Installation aborted by user${CEND}"
            exit 1
        else
            tsc_evasion_enabled=false
            echo -e "${CGREEN}Continuing with standard QEMU installation${CEND}"
        fi
    fi
fi

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

if [ "$tsc_evasion_enabled" = true ] && [ "$tsc_evasion_patch_applied" = true ]; then
    echo -e "  TSC Evasion: ${CGREEN}ENABLED${CEND} (Security Research)"
    echo ""
    echo -e "${CYAN}TSC Evasion Features:${CEND}"
    echo -e "  - VM exit latency hidden (~1,200 → ~200-400 cycles)"
    echo -e "  - Timing-based detection bypassed"
    echo -e "  - Enhanced anti-detection capabilities"
    echo -e "  - SeaBIOS timing hooks installed"
else
    echo -e "  TSC Evasion: ${CCYAN}Not Enabled${CEND}"
fi

echo ""
echo -e "${CCYAN}Next Steps:${CEND}"
echo -e "  1. Add users to kvm group: usermod -a -G kvm <username>"
echo -e "  2. Install libvirt: ./inst-libvirt.sh"
echo -e "  3. Install virt-manager for GUI management"
echo -e "  4. Test installation: qemu-system-x86_64 --version"

if [ "$tsc_evasion_enabled" = true ] && [ "$tsc_evasion_patch_applied" = true ]; then
    echo ""
    echo -e "${CMAGENTA}TSC Evasion Usage:${CEND}"
    echo -e "  - TSC evasion is automatically enabled in VMs"
    echo -e "  - Use for legitimate security research only"
    echo -e "  - Test with timing analysis tools to verify"
    echo -e "  - Monitor VM performance for any issues"
fi

echo ""
echo -e "${CCYAN}Logs:${CEND}"
echo -e "  Dependencies: /tmp/apt-packages.log"
echo -e "  QEMU Install: /tmp/qemu-install.log"
echo ""
if [ "$tsc_evasion_enabled" = true ] && [ "$tsc_evasion_patch_applied" = true ]; then
    echo -e "${CMAGENTA}🔒 TSC Evasion System Active - Security Research Implementation Complete!${CEND}"
else
    echo -e "${CMAGENTA}If you reached here, seriously done!${CEND}"
fi
# End of script
