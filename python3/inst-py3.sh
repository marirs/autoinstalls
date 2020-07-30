#!/bin/bash
#
# Description: Install Python 3.x
# Tested:
#       Debian: 9.x, 10.x
#       Ubuntu: 18.04, 20.04
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
[ -f "/tmp/py3-install.log" ] && rm -f /tmp/py3-install.log

# Versions
python_version=3.8.5

# system information
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
cores=$(nproc)
architecture=$(arch)

# get current py3 version if exists
curr_py3=$(which python3 2>/dev/null | tail -1 |  cut -d" " -f3 | xargs) >> /dev/null 2>&1
curr_py3_version=$($curr_py3 -V 2>/dev/null | cut -d" " -f2 | sed 's/\(.*\)\..*/\1/' | xargs) >> /dev/null 2>&1

[[ "$architecture" != "x86_64"  ]] && echo "${CRED}$architecture not supported, cannot be installed. You need x86_64 system.${CEND}" && exit 1

function install_deps() {
    echo -e "${CGREEN}Updating system...${CEND}"
    apt-get update -y >> /tmp/apt-packages.log 2>&1
    apt-get -y upgrade >> /tmp/apt-packages.log 2>&1
    pkgs="git sudo pcregrep net-tools inxi software-properties-common libpq-dev devscripts build-essential zip unzip p7zip-full p7zip-rar \
    libuv1 libre2-5 sysstat schedtool ca-certificates poppler-utils libffi-dev libssl-dev screen numactl libgdbm-compat-dev build-essential \
    libssl-dev libffi-dev zlib1g zlib1g-dev screen libuv1 libuv1-dev libre2-5 libre2-dev build-essential zlib1g-dev libbz2-dev liblzma-dev \
    libncurses5-dev libreadline-dev xclip xsel libsqlite3-dev libssl-dev libgdbm-dev liblzma-dev tk-dev lzma lzma-dev libgdbm-dev build-essential \
    liblzma-dev libgdbm-dev libsqlite3-dev libbz2-dev tk-dev "
    if [[ "$os" == *"ubuntu"* ]]; then
        pkgs=$(echo $pkgs; echo "libncurses-dev libncurses5-dev libncursesw5-dev")
        cd /tmp/ || return
    elif [[ "$os" == *"debian"* ]]; then
        pkgs=$(echo $pkgs; echo "libncurses*-dev ")
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

function clean_up() {
    cd /tmp
    echo -ne "${CBLUE}Cleaning up    [...]${CEND}\r"
    [ -d Python-$python_version ] && rm -rf Python-* >> /tmp/py3-install.log 2>&1 
    echo -ne "${CBLUE}Cleaning up    [DONE]${CEND}\r"
    echo -ne "\n"
    echo -e "Dependancy installation logs: ${CCYAN}/tmp/apt-packages.log${CEND}"
    echo -e "Python $python_version installation logs: ${CCYAN}/tmp/py3-install.log${CEND}"
}


function install_py3() {
    cd /tmp
    [ -d Python-$python_version ] && rm -rf Python-* >> /tmp/py3-install.log 2>&1 
    echo -e "${CGREEN}Downloading Python-$python_version...${CEND}"
    wget wget https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz >> /tmp/py3-install.log 2>&1
    echo -e "${CGREEN}Expanding Python-$python_version...${CEND}"
    tar xvf Python-$python_version.tgz >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to untar the Python-$python_version arhive; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    cd Python-$python_version >> /tmp/py3-install.log 2>&1
    echo -e "${CGREEN}Configuring Python-$python_version...${CEND}"
    ./configure --prefix=/usr --enable-shared --with-system-expat --with-system-ffi --enable-optimizations --with-ensurepip=install >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to 'configure' Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Make Python-$python_version...${CEND}"
    make -j$cores >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to 'make' Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Installing Python-$python_version...${CEND}"
    make altinstall >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to install Python-$python_version; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
    echo -e "${CGREEN}Upgrading pip3...${CEND}"
    python3.8 -m pip install --upgrade pip >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to upgrade pip3; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi
}

function install_venv () {
    echo -e "${CGREEN}Installing virtualenvwtapper pip3...${CEND}"
    pip3 install virtualenvwrapper >> /tmp/py3-install.log 2>&1
    if [ $? -ne 0 ]; then
        echo -e "    - ${CRED}failed to install virtualenvwrapper; see /tmp/py3-install.log for more info.${CEND}"
        exit 1
    fi

    if ! grep "export WORKON_HOME=$HOME/.virtualenvs" "$HOME/.bashrc" >> /tmp/py3-install.log 2>&1; then
        echo "" >> "$HOME/.bashrc"
        echo "# Virtualenv" >> "$HOME/.bashrc"
        echo "export WORKON_HOME=$HOME/.virtualenvs" >> "$HOME/.bashrc"
        echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> "$HOME/.bashrc"
        echo "source /usr/local/bin/virtualenvwrapper.sh" >> "$HOME/.bashrc"
    fi
}


# begin installations step-by-step
install_deps
install_py3
install_venv

# clean-up the downloads, although not necessary
clean_up

echo " "
echo -e "${CGREEN}>> Done.${CEND} ${CMAGENTA}If you reached here, seriously done!${CEND}"
# End of script
