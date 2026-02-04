# MongoDB Installation Script
# Automated MongoDB installation and configuration

#!/bin/bash

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CYELLOW="${CSI}1;33m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# Get MongoDB latest version
MONGODB_VERSIONS=$(curl -s https://www.mongodb.org/download-center/community | grep -oP 'mongodb-\d+\.\d+\.\d+' | sort -V | uniq | tail -n2)
MONGODB_LATEST_VER=$(echo $MONGODB_VERSIONS | cut -d' ' -f2 | cut -d'-' -f2)
MONGODB_STABLE_VER=$(echo $MONGODB_VERSIONS | cut -d' ' -f1 | cut -d'-' -f2)

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/mongodb-install.log

clear
echo ""
echo "Welcome to the MongoDB auto-install script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update MongoDB"
echo "   2) Configure MongoDB"
echo "   3) Uninstall MongoDB"
echo "   4) Create MongoDB user"
echo "   5) Backup MongoDB"
echo "   6) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" && $OPTION != "6" ]]; do
	read -p "Select an option [1-6]: " OPTION
done

case $OPTION in
	1)
		echo ""
		echo "This script will install MongoDB with optional configurations."
		echo ""
		echo "Choose MongoDB version:"
		echo "   1) Stable $MONGODB_STABLE_VER"
		echo "   2) Latest $MONGODB_LATEST_VER"
		echo ""
		while [[ $MONGO_VER != "1" && $MONGO_VER != "2" ]]; do
			read -p "Select an option [1-2]: " MONGO_VER
		done
		case $MONGO_VER in
			1)
			MONGO_VER=$MONGODB_STABLE_VER
			;;
			2)
			MONGO_VER=$MONGODB_LATEST_VER
			;;
		esac
		
		echo ""
		echo "Choose installation type:"
		echo "   1) Standalone (Single instance)"
		echo "   2) Replica Set (Multiple instances)"
		echo "   3) Sharded Cluster (Advanced)"
		echo ""
		while [[ $INSTALL_TYPE != "1" && $INSTALL_TYPE != "2" && $INSTALL_TYPE != "3" ]]; do
			read -p "Select an option [1-3]: " INSTALL_TYPE
		done
		
		echo ""
		echo "Additional configurations:"
		while [[ $MONGO_AUTH != "y" && $MONGO_AUTH != "n" ]]; do
			read -p "       Enable Authentication [y/n]: " -e MONGO_AUTH
		done
		while [[ $MONGO_UI != "y" && $MONGO_UI != "n" ]]; do
			read -p "       Install MongoDB Compass UI [y/n]: " -e MONGO_UI
		done
		while [[ $MONGO_TOOLS != "y" && $MONGO_TOOLS != "n" ]]; do
			read -p "       Install MongoDB Tools [y/n]: " -e MONGO_TOOLS
		done
		while [[ $MONGO_BACKUP != "y" && $MONGO_BACKUP != "n" ]]; do
			read -p "       Setup backup script [y/n]: " -e MONGO_BACKUP
		done
		
		echo ""
		read -n1 -r -p "MongoDB is ready to be installed, press any key to continue..."
		echo ""
		
		# Dependencies
		echo -ne "       Installing dependencies        [..]\r"
		apt-get update >> /tmp/mongodb-install.log 2>&1
		apt-get install -y curl gnupg wget >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Installing dependencies        [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Installing dependencies        [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Import MongoDB public key
		echo -ne "       Adding MongoDB repository       [..]\r"
		curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGO_VER}.asc | gpg -o /usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg >> /tmp/mongodb-install.log 2>&1
		echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGO_VER}.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/${MONGO_VER} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VER}.list >> /tmp/mongodb-install.log 2>&1
		apt-get update >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Adding MongoDB repository       [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Adding MongoDB repository       [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Install MongoDB packages
		echo -ne "       Installing MongoDB packages      [..]\r"
		apt-get install -y mongodb-org >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Installing MongoDB packages      [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Installing MongoDB packages      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Install MongoDB Tools
		if [[ "$MONGO_TOOLS" = 'y' ]]; then
			echo -ne "       Installing MongoDB tools         [..]\r"
			apt-get install -y mongodb-org-tools mongodb-org-database mongodb-org-shell >> /tmp/mongodb-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing MongoDB tools         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing MongoDB tools         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/mongodb-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Install MongoDB Compass
		if [[ "$MONGO_UI" = 'y' ]]; then
			echo -ne "       Installing MongoDB Compass      [..]\r"
			wget -qO - https://downloads.mongodb.com/compass/mongodb-compass_1.40.4_amd64.deb >> /tmp/mongodb-install.log 2>&1
			dpkg -i mongodb-compass_1.40.4_amd64.deb >> /tmp/mongodb-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing MongoDB Compass      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing MongoDB Compass      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/mongodb-install.log"
				echo ""
				exit 1
			fi
		fi
		
		# Start and enable MongoDB
		echo -ne "       Starting MongoDB service         [..]\r"
		systemctl start mongod >> /tmp/mongodb-install.log 2>&1
		systemctl enable mongod >> /tmp/mongodb-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Starting MongoDB service         [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Starting MongoDB service         [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/mongodb-install.log"
			echo ""
			exit 1
		fi
		
		# Configure MongoDB
		echo -ne "       Configuring MongoDB              [..]\r"
		mkdir -p /etc/mongodb/conf.d
		wget -O /etc/mongodb/mongod.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/mongodb/conf/mongod.conf >> /tmp/mongodb-install.log 2>&1
		
		# Apply configuration based on installation type
		case $INSTALL_TYPE in
			1)
				# Standalone configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				;;
			2)
				# Replica Set configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				;;
			3)
				# Sharded cluster configuration
				sed -i 's/#replication:/replication:/' /etc/mongodb/mongod.conf
				sed -i 's/#replSet:/replSet: "rs0"/' /etc/mongodb/mongod.conf
				sed -i 's/#sharding:/sharding:/' /etc/mongodb/mongod.conf
				sed -i 's/#clusterRole:/clusterRole: "shardsvr"/' /etc/mongodb/mongod.conf
				;;
		esac
		
		# Enable authentication if requested
		if [[ "$MONGO_AUTH" = 'y' ]]; then
			sed -i 's/#security:/security:/' /etc/mongodb/mongod.conf
			sed -i 's/#authorization: enabled/authorization: enabled/' /etc/mongodb/mongod.conf
		fi
		
		# Restart MongoDB to apply configuration
		systemctl restart mongod >> /tmp/mongodb-install.log 2>&1
		
		# Setup backup script if requested
		if [[ "$MONGO_BACKUP" = 'y' ]]; then
			echo -ne "       Setting up backup script           [..]\r"
			wget -O /usr/local/bin/mongodb-backup https://raw.githubusercontent.com/marirs/autoinstalls/master/mongodb/scripts/mongodb-backup >> /tmp/mongodb-install.log 2>&1
			chmod +x /usr/local/bin/mongodb-backup >> /tmp/mongodb-install.log 2>&1
			echo -ne "       Setting up backup script           [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi
		
		echo ""
		echo -e "${CGREEN}MongoDB installation successful!${CEND}"
		echo ""
		echo "MongoDB version: $MONGO_VER"
		echo "Installation type: $INSTALL_TYPE"
		echo "Authentication: $([[ "$MONGO_AUTH" = 'y' ]] && echo "Enabled" || echo "Disabled")"
		echo "MongoDB Compass: $([[ "$MONGO_UI" = 'y' ]] && echo "Installed" || echo "Not installed")"
		echo ""
		echo "MongoDB configuration: /etc/mongodb/mongod.conf"
		echo "Log file: /var/log/mongodb/mongod.log"
		echo "Data directory: /var/lib/mongodb"
		echo ""
		echo "Installation log: /tmp/mongodb-install.log"
		echo ""
		exit
		;;
	2)
		# Configuration option would go here
		echo "Configuration option - not implemented yet"
		;;
	3)
		# Uninstall option would go here
		echo "Uninstall option - not implemented yet"
		;;
	4)
		# User creation option would go here
		echo "User creation option - not implemented yet"
		;;
	5)
		# Backup option would go here
		echo "Backup option - not implemented yet"
		;;
	6)
		exit
		;;
esac
