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
NGINX_MAINLINE_VER=1.25.2
NGINX_STABLE_VER=1.24.0
LIBRESSL_VER=3.5.3
OPENSSL_VER=1.1.1w
NPS_VER=1.14.33.1-RC1
HEADERMOD_VER=0.34
LIBMAXMINDDB_VER=1.6.0
PCRE_NGINX_VER=10.40
ZLIB_NGINX_VER=1.3

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/nginx-install.log

clear
echo ""
echo "Welcome to the nginx-autoinstall script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Install Bad Bot Blocker for Nginx"
echo "   3) Uninstall Nginx"
echo "   4) Update the script"
echo "   5) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" ]]; do
	read -p "Select an option [1-5]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "This script will install Nginx with some optional modules."
		echo ""
		echo "Do you want to install Nginx stable or mainline?"
		echo "   1) Stable $NGINX_STABLE_VER"
		echo "   2) Mainline $NGINX_MAINLINE_VER"
		echo ""
		while [[ $NGINX_VER != "1" && $NGINX_VER != "2" ]]; do
			read -p "Select an option [1-2]: " NGINX_VER
		done
		case $NGINX_VER in
			1)
			NGINX_VER=$NGINX_STABLE_VER
			;;
			2)
			NGINX_VER=$NGINX_MAINLINE_VER
			;;
		esac
		echo ""
		echo "Please tell me which modules you want to install."
		echo "If you select none, Nginx will be installed with its default modules."
		echo ""
		echo "Modules to install :"
		while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
			read -p "       PageSpeed $NPS_VER [y/n]: " -e PAGESPEED
		done
		while [[ $CACHEPURGE != "y" && $CACHEPURGE != "n" ]]; do
			read -p "       ngx_cache_purge [y/n]: " -e CACHEPURGE
		done
		while [[ $BROTLI != "y" && $BROTLI != "n" ]]; do
			read -p "       Brotli [y/n]: " -e BROTLI
		done
		while [[ $REDIS2 != "y" && $REDIS2 != "n" ]]; do
			read -p "       Http Redis 2 [y/n]: " -e REDIS2
		done
        while [[ $SRCACHE != "y" && $SRCACHE != "n" ]]; do
            read -p "       SRCache (provides transparent caching layer) [y/n]: " -e SRCACHE
        done
        while [[ $MEMC_NGINX != "y" && $MEMC_NGINX != "n" ]]; do
            read -p "       MEMC (Extended ver of standard Memcached) [y/n]: " -e MEMC_NGINX
        done
        while [[ $VTS != "y" && $VTS != "n" ]]; do
            read -p "       Nginx virtual host traffic status [y/n]: " -e VTS
        done
		while [[ $GEOIP2 != "y" && $GEOIP2 != "n" ]]; do
			read -p "       GeoIP 2 [y/n]: " -e GEOIP2
		done
		while [[ $LDAPAUTH != "y" && $LDAPAUTH != "n" ]]; do
			read -p "       LDAP Auth $LDAPAUTH [y/n]: " -e LDAPAUTH
		done
		while [[ $HEADERMOD != "y" && $HEADERMOD != "n" ]]; do
			read -p "       Headers More $HEADERMOD_VER [y/n]: " -e HEADERMOD
		done
		while [[ $FANCYINDEX != "y" && $FANCYINDEX != "n" ]]; do
			read -p "       Fancy index [y/n]: " -e FANCYINDEX
		done
        while [[ $SET_MISC != "y" && $SET_MISC != "n" ]]; do
            read -p "       SET_MISC Content filtering [y/n]: " -e SET_MISC
        done
        while [[ $PCRE_NGINX != "y" && $PCRE_NGINX != "n" ]]; do
            read -p "       PCRE [y/n]: " -e PCRE_NGINX
        done
        while [[ $ZLIB_NGINX != "y" && $ZLIB_NGINX != "n" ]]; do
            read -p "       ZLIB [y/n]: " -e ZLIB_NGINX
        done

        if [[ "$NGINX_VER" == *"1.25"* ]] ||   "$NGINX_VER" == *"1.23"* ]] ||  [[ "$NGINX_VER" == *"1.13"* ]] || [[ "$NGINX_VER" == *"1.15"* ]] || [[ "$NGINX_VER" == *"1.17"* ]] || [[ "$NGINX_VER" == *"1.18"* ]]  || [[ "$NGINX_VER" == *"1.19"* ]]; then
            while [[ $TLSPATCH != "y" && $TLSPATCH != "n" ]]; do
                read -p "       Cloudflare's TLS Dynamic Record Resizing patch [y/n]: " -e TLSPATCH
            done
        else
            TLSPATCH="n"
        fi

		echo ""
		echo "Choose your Web Application Firewall (WAF):"
		echo "   1) ModSecurity (Preferred)"
		echo "   2) NAXSI (Does not play well with HTTP2)"
		echo "   3) None"
		echo ""
		while [[ $WAF != "1" && $WAF != "2" && $WAF != "3" ]]; do
			read -p "Select an option [1-3]: " WAF
		done
		case $WAF in
			1)
                MODSEC=y            
                read -p "      > Enable nginx ModSecurity? [y/n]: " -e MODSEC_ENABLE
			;;
			2)
				NAXSI=y
			;;
			3)
				MODSEC=n
                NAXSI=n
			;;
		esac

		echo ""
		echo "Choose your OpenSSL implementation :"
		echo "   1) System's OpenSSL ($(openssl version | cut -c9-14))"
		echo "   2) OpenSSL $OPENSSL_VER from source"
		echo "   3) LibreSSL $LIBRESSL_VER from source "
		echo ""
		while [[ $SSL != "1" && $SSL != "2" && $SSL != "3" ]]; do
			read -p "Select an option [1-3]: " SSL
		done
		case $SSL in
			1)
			#we do nothing
			;;
			2)
				OPENSSL=y
			;;
			3)
				LIBRESSL=y
			;;
		esac
		echo ""
		read -n1 -r -p "Nginx is ready to be installed, press any key to continue..."
		echo ""

        # Cleanup
        # The directory should be deleted at the end of the script, but in case it fails
        rm -r /usr/local/src/nginx/ >> /tmp/nginx-install.log 2>&1
        mkdir -p /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1

        # Dependencies
        echo -ne "       Installing dependencies        [..]\r"
        apt-get update >> /tmp/nginx-install.log 2>&1
        INSTALL_PKGS="build-essential ca-certificates wget curl libpcre3 libpcre3-dev libldap2-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev uuid-dev"
        if [[ "$MODSEC" = 'y' ]]; then
            INSTALL_PKGS=$(echo $INSTALL_PKGS; echo apt-utils libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libyajl-dev pkgconf libmodsecurity3 libmodsecurity-dev)
        fi
        if [[ "$GEOIP2" = 'y' ]]; then
            INSTALL_PKGS=$(echo $INSTALL_PKGS; echo libgeoip-dev libmaxminddb0 libmaxminddb-dev mmdb-bin)
        fi
        for i in $INSTALL_PKGS; do
                apt-get install -y $i  >> /tmp/nginx-install.log 2>&1
                if [ $? -ne 0 ]; then
                    echo -e "       Installing dependencies        [${CRED}FAIL${CEND}]"
                    echo ""
                    echo "Please look at /tmp/nginx-install.log"
                    echo ""
                    exit 1
                fi
        done
        if [ $? -eq 0 ]; then
            echo -ne "       Installing dependencies        [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
        fi

        if [[ "$GEOIP2" = 'y' || "$MODSEC" = 'y' ]]; then
            echo -ne "       Geoip/Modsec dependencies      [..]\r"
            cd /usr/local/src/nginx/modules  >> /tmp/nginx-install.log 2>&1
            wget https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VER}/libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz  >> /tmp/nginx-install.log 2>&1
            tar xaf libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz  >> /tmp/nginx-install.log 2>&1
            cd libmaxminddb-${LIBMAXMINDDB_VER}/  >> /tmp/nginx-install.log 2>&1
            ./configure  >> /tmp/nginx-install.log 2>&1
            make -j $cores >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
			    echo -ne "       Geoip/Modsec dependencies      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Geoip/Modsec dependencies      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

            echo -ne "       Geoip/Modsec deps Install      [..]\r"
            make install  >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
			    echo -ne "       Geoip/Modsec deps Install      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Geoip/Modsec deps Install      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
            ldconfig  >> /tmp/nginx-install.log 2>&1
        fi

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# Download and extract of PageSpeed module
			echo -ne "       Downloading ngx_pagespeed      [..]\r"
			wget https://github.com/apache/incubator-pagespeed-ngx/archive/refs/tags/v${NPS_VER}.zip >> /tmp/nginx-install.log 2>&1
			#wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-stable.zip >> /tmp/nginx-install.log 2>&1
			unzip v${NPS_VER}.zip >> /tmp/nginx-install.log 2>&1
			cd incubator-pagespeed-ngx-${NPS_VER}
			psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VER}.tar.gz
			[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
			wget ${psol_url} >> /tmp/nginx-install.log 2>&1
			tar -xzvf $(basename ${psol_url}) >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
			echo -ne "       Downloading ngx_pagespeed      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_pagespeed      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		#Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# libbrotli install
			echo -ne "       Installing libbrotli           [..]\r"
			make install >> /tmp/nginx-install.log 2>&1
			apt -y install libbrotli1 >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing libbrotli           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing libbrotli           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			# Linking libraries to avoid errors
			ldconfig >> /tmp/nginx-install.log 2>&1
			# ngx_brotli module download
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_brotli         [..]\r"
			git clone https://github.com/google/ngx_brotli >> /tmp/nginx-install.log 2>&1
			cd ngx_brotli
			git submodule update --init >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# LDAP Auth
		if [[ "$LDAPAUTH" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading LDAP Auth          [..]\r"
			wget -O ldap-auth.zip https://github.com/kvspb/nginx-auth-ldap/archive/master.zip >> /tmp/nginx-install.log 2>&1
			unzip ldap-auth.zip >> /tmp/nginx-install.log 2>&1
			rm -f ldap-auth.zip >> /tmp/nginx-install.log 2>&1
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading LDAP Auth          [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading LDAP Auth          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # Nginx virtual host traffic status
        if [[ "$VTS" = 'y' ]]; then
            cd /usr/local/src/nginx/modules
			echo -ne "       Downloading Nginx VTS          [..]\r"
            git clone https://github.com/vozlt/nginx-module-vts.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading Nginx VTS          [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading Nginx VTS          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
        fi

        # HTTP REDIS 2
        if [[ "$REDIS2" = 'y' ]]; then
            cd /usr/local/src/nginx/modules
			echo -ne "       Downloading HTTP Redis 2       [..]\r"
            git clone https://github.com/openresty/redis2-nginx-module.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading HTTP Redis 2       [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading HTTP Redis 2       [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
        fi

		# ModSecurity
		if [[ "$MODSEC" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading ModSecurity        [..]\r"
			git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ModSecurity        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ModSecurity        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
			cd ModSecurity >> /tmp/nginx-install.log 2>&1
			git submodule init >> /tmp/nginx-install.log 2>&1
			git submodule update >> /tmp/nginx-install.log 2>&1

			echo -ne "       Configuring ModSecurity        [..]\r"
			./build.sh >> /tmp/nginx-install.log 2>&1
			./configure >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Configuring ModSecurity        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring ModSecurity        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Compiling ModSecurity          [..] (Slow on low cores)\r"
			make -j $cores >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Compiling ModSecurity          [${CGREEN}OK${CEND}]                            \r"
				echo -ne "\n"
			else
				echo -e "       Compiling ModSecurity          [${CRED}FAIL${CEND}]                            "
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Installing ModSecurity         [..]\r"
			make install >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing ModSecurity         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing ModSecurity         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
			mkdir -p /etc/nginx/modsec >> /tmp/nginx-install.log 2>&1
			wget -O /etc/nginx/modsec/modsecurity.conf https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended >> /tmp/nginx-install.log 2>&1

			# Enable ModSecurity in Nginx
			if [[ "$MODSEC_ENABLE" = 'y' ]]; then
                echo -ne "       Enabling ModSecurity           [..]\r"
				sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
                if [ $? -eq 0 ]; then
                    echo -ne "       Enabling ModSecurity           [${CGREEN}OK${CEND}]\r"
                    echo -ne "\n"
                else
                    echo -ne "       Enabling ModSecurity           [${CRED}FAIL - Enable it manually after reviewing install log file!${CEND}]"
                    echo -ne "\n"
                fi
			fi
 
			echo -ne "       ModSecurity Nginx Module       [..]\r"
            git clone --quiet https://github.com/SpiderLabs/ModSecurity-nginx.git /usr/local/src/nginx/modules/ModSecurity-nginx >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       ModSecurity Nginx Module       [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       ModSecurity Nginx Module       [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# NAXSI
		if [[ "$NAXSI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading NAXSI              [..]\r"
			wget -O naxsi.zip https://github.com/nbs-system/naxsi/archive/master.zip >> /tmp/nginx-install.log 2>&1
			unzip naxsi.zip >> /tmp/nginx-install.log 2>&1
			rm -f naxsi.zip >> /tmp/nginx-install.log 2>&1
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading NAXSI              [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading NAXSI              [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_headers_more   [..]\r"
			wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf v${HEADERMOD_VER}.tar.gz
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# SET_MISC
		if [[ "$SET_MISC" = 'y' ]]; then
			echo -ne "       Downloading SET MISC           [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/set-misc-nginx-module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading SET MISC           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading SET MISC           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# PCRE NGINX
        if [[ "$PCRE_NGINX" = 'y' ]]; then
			echo -ne "       Downloading PCRE Module        [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.40/pcre2-${PCRE_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf pcre2-${PCRE_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			cd pcre2-${PCRE_NGINX_VER} >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading PCRE Module        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading PCRE Module        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # ZLIB NGINX
		if [[ "$ZLIB_NGINX" = 'y' ]]; then
			echo -ne "       Downloading ZLIB Module        [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			wget http://zlib.net/zlib-${ZLIB_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf zlib-${ZLIB_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			cd zlib-${ZLIB_NGINX_VER} >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ZLIB Module        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ZLIB Module        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# SRCACHE
		if [[ "$SRCACHE" = 'y' ]]; then
			echo -ne "       Downloading SRCache            [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/srcache-nginx-module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading SRCache            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading SRCache            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # MEMC
		if [[ "$MEMC_NGINX" = 'y' ]]; then
			echo -ne "       Downloading MEMC               [..]\r"
            cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/memc-nginx-module.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading MEMC               [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading MEMC               [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

    	# GeoIP 2
		if [[ "$GEOIP2" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading GeoIP 2            [..]\r"
            git clone --recursive https://github.com/leev/ngx_http_geoip2_module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading GeoIP 2            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading GeoIP 2            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			mkdir -p /etc/nginx/geoip2/
			echo -ne "       Downloading GeoIP 2 databases  [..]\r"
			wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz >> /tmp/nginx-install.log 2>&1
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf GeoLite2-Country.tar.gz  --strip 1 >> /tmp/nginx-install.log 2>&1
			tar xaf GeoLite2-City.tar.gz --strip 1 >> /tmp/nginx-install.log 2>&1
			mv GeoLite2-Country.mmdb /etc/nginx/geoip2/ >> /tmp/nginx-install.log 2>&1
			mv GeoLite2-City.mmdb /etc/nginx/geoip2/ >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading GeoIP 2 databases  [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -ne "       Downloading GeoIP 2 databases  [${CRED}FAIL - You need to download manually & place in /etc/nginx/geoip2/${CEND}]"
				echo -ne "\n"
			fi
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_cache_purge    [..]\r"
			git clone https://github.com/FRiCKLE/ngx_cache_purge >> /tmp/nginx-install.log 2>&1			

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_cache_purge    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_cache_purge    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# LibreSSL
		if [[ "$LIBRESSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			mkdir libressl-${LIBRESSL_VER}
			cd libressl-${LIBRESSL_VER}
			# LibreSSL download
			echo -ne "       Downloading LibreSSL           [..]\r"
			wget -qO- http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | tar xz --strip 1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading LibreSSL           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Configuring LibreSSL           [..]\r"
			./configure \
				LDFLAGS=-lrt \
				CFLAGS=-fstack-protector-strong \
				--prefix=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/.openssl/ \
				--enable-shared=no >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Configuring LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring LibreSSL         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			# LibreSSL install
			echo -ne "       Installing LibreSSL            [..]\r"
			make install-strip -j $cores >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Installing LibreSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing LibreSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# OpenSSL download
			echo -ne "       Downloading OpenSSL            [..]\r"
			wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf openssl-${OPENSSL_VER}.tar.gz
			cd openssl-${OPENSSL_VER}	
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading OpenSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Configuring OpenSSL            [..]\r"
			./config >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Configuring OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring OpenSSL          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# Download and extract of Nginx source code
		cd /usr/local/src/nginx/
		echo -ne "       Downloading Nginx              [..]\r"
		wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
		cd nginx-${NGINX_VER}

		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# As the default nginx.conf does not work
		# We download a clean and working conf from my GitHub.
		# We do it only if it does not already exist (in case of update for instance)
		if [[ ! -e /etc/nginx/nginx.conf ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx.conf >> /tmp/nginx-install.log 2>&1
            if [[ "$TLSPATCH" == "y" ]]; then
                sed -i '/ssl_dyn_rec_enable/s/#//g' nginx.conf
            fi
            if [[ "$GEOIP" != 'y' ]]; then
                sed -i '/geoip_/d' nginx.conf
            fi
		fi
		cd /usr/local/src/nginx/nginx-${NGINX_VER}

		echo -ne "       Downloading Nginx Devel Kit    [..]\r"
        git clone --quiet https://github.com/simplresty/ngx_devel_kit.git /usr/local/src/nginx/modules/ngx_devel_kit >> /tmp/nginx-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx Devel Kit    [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading Nginx Devel Kit    [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Modules configuration
		# Common configuration 
		NGINX_OPTIONS="
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--user=nginx \
		--group=nginx \
		--with-cc-opt=-Wno-deprecated-declarations \
		--with-cc-opt=-Wno-ignored-qualifiers"

		NGINX_MODULES="--without-http_ssi_module \
		--without-http_scgi_module \
		--without-http_empty_gif_module \
		--without-http_browser_module \
		--with-threads \
		--with-pcre \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_mp4_module \
		--with-http_auth_request_module \
		--with-http_sub_module \
		--with-http_secure_link_module \
		--with-ipv6 \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-http_realip_module \
        --with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-select_module \
		--with-poll_module \
        --add-module=/usr/local/src/nginx/modules/ngx_devel_kit"

		# Optional modules
		# LibreSSL 
		if [[ "$LIBRESSL" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER})
		fi

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/incubator-pagespeed-ngx-${NPS_VER}")
		fi

		# Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
		fi

		# LDAP Auth
		if [[ "$LDAPAUTH" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/nginx-auth-ldap-master")
		fi

		# Nginx virtual host traffic status
		if [[ "$VTS" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/nginx-module-vts")
		fi

        # ModSecurity WAF
		if [[ "$MODSEC" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --add-module=/usr/local/src/nginx/modules/ModSecurity-nginx)
		fi

		# NAXSI WAF
		if [[ "$NAXSI" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/naxsi-master/naxsi_src")
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
		fi

        # GeoIP 2
        if [[ "$GEOIP2" = 'y' ]]; then			
            NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_http_geoip2_module")
        fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
		fi

		# Fancy index
		if [[ "$FANCYINDEX" = 'y' ]]; then
			git clone --quiet https://github.com/aperezdc/ngx-fancyindex.git /usr/local/src/nginx/modules/fancyindex >> /tmp/nginx-install.log 2>&1
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --add-module=/usr/local/src/nginx/modules/fancyindex)
		fi

        # Http Redis 2
        if [[ "$REDIS2" = 'y' ]]; then
            NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/redis2-nginx-module")
        fi
		
        # SET_MISC
     	if [[ "$SET_MISC" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/set-misc-nginx-module")
		fi

        # SRCache
		if [[ "$SRCACHE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/srcache-nginx-module")
		fi

        # MEMC
		if [[ "$MEMC_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/memc-nginx-module")
		fi

        # PCRE
		if [[ "$PCRE_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-pcre=/usr/local/src/nginx/modules/pcre2-${PCRE_NGINX_VER}")
		fi

        # ZLIB
		if [[ "$ZLIB_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-zlib=/usr/local/src/nginx/modules/zlib-${ZLIB_NGINX_VER}")
		fi

		# Cloudflare's TLS Dynamic Record Resizing patch
		if [[ "$TLSPATCH" = 'y' ]]; then
			echo -ne "       TLS Dynamic Records support    [..]\r"

	    wget -O nginx.patch https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/nginx-dynamic-tls-1.25.2.patch >> /tmp/nginx-install.log 2>&1
            patch -p1 < nginx.patch >> /tmp/nginx-install.log 2>&1
		        
			if [ $? -eq 0 ]; then
				echo -ne "       TLS Dynamic Records support    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       TLS Dynamic Records support    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# We configure Nginx
		echo -ne "       Configuring Nginx              [..]\r"
		CFLAGS="-Wno-stringop-truncation -Wno-stringop-overflow" ./configure $NGINX_OPTIONS --with-cc-opt='-g -O2 -fPIC -fstack-protector-strong -Wformat -Wno-error -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -fPIC -pie -Wl,-z,relro -Wl,-z,now' --with-pcre-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' --with-zlib-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' $NGINX_MODULES >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Then we compile
		echo -ne "       Compiling Nginx                [..]\r"
		make -j $cores >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Compiling Nginx                [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Then we install \o/
		echo -ne "       Installing Nginx               [..]\r"
		make install >> /tmp/nginx-install.log 2>&1
		
		# remove debugging symbols
		strip -s /usr/sbin/nginx

		if [ $? -eq 0 ]; then
			echo -ne "       Installing Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Installing Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

        mkdir -p /etc/nginx/ssl >> /tmp/nginx-install.log 2>&1
        mkdir -p /etc/nginx/conf.d >> /tmp/nginx-install.log 2>&1
        wget -O /etc/nginx/conf.d/geo_fence.conf.default https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/geo_fence.conf >> /tmp/nginx-install.log 2>&1
	if [[ "$GEOIP2" = 'y' ]]; then
	    wget -O /etc/nginx/conf.d/geoip2.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/geoip2.conf >> /tmp/nginx-install.log 2>&1
	    wget -O /etc/nginx/conf.d/logformat.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/logformat.conf >> /tmp/nginx-install.log 2>&1
fi
		# Nginx installation from source does not add an init script for systemd and logrotate
		# Using the official systemd script and logrotate conf from nginx.org
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx.service >> /tmp/nginx-install.log 2>&1
			# Enable nginx start at boot
			systemctl enable nginx >> /tmp/nginx-install.log 2>&1
		fi

		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx-logrotate -O nginx >> /tmp/nginx-install.log 2>&1
		fi

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# We add sites-* folders as some use them. /etc/nginx/conf.d/ is the vhost folder by defaultnginx 
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi
		if [[ ! -d /etc/nginx/ssl ]]; then
			mkdir -p /etc/nginx/ssl
		fi

		# Restart Nginx
		echo -ne "       Restarting Nginx               [..]\r"
		systemctl restart nginx >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Restarting Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			echo -ne "       Blocking nginx from APT        [..]\r"
			cd /etc/apt/preferences.d/
			echo -e "Package: nginx*\nPin: release *\nPin-Priority: -1" > nginx-block
			echo -ne "       Blocking nginx from APT        [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# Removing temporary Nginx and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx >> /tmp/nginx-install.log 2>&1
		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"

		# We're done !
		echo ""
		echo -e "       ${CGREEN}Installation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-install.log"
		echo ""
	exit
	;;
	2) # Install Bad Bot Blocker
		echo ""
		echo "This will install Nginx Bad Bot and User-Agent Blocker."
		echo ""
		echo "Download the install script."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
		chmod +x /usr/local/sbin/install-ngxblocker

		echo ""
		echo "Run the install-ngxblocker script in DRY-MODE,"
		echo "which will show you what changes it will make and what files it will download for you.."
		echo "This is only a DRY-RUN so no changes are being made yet."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin || exit 1
		./install-ngxblocker

		echo ""
		echo "Run the install script with the -x parameter,"
		echo "to download all the necessary files from the repository.."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./install-ngxblocker -x
		chmod +x /usr/local/sbin/setup-ngxblocker
		chmod +x /usr/local/sbin/update-ngxblocker

		echo ""
		echo "All the required files have now been downloaded to the correct folders,"
		echo " on Nginx for you directly from the repository."
		echo ""
		echo "Run the setup-ngxblocker script in DRY-MODE,"
		echo "which will show you what changes it will make and what files it will download for you."
		echo "This is only a DRY-RUN so no changes are being made yet."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./setup-ngxblocker -e conf

		echo ""
		echo "Run the setup script with the -x parameter,"
		echo "to make all the necessary changes to your nginx.conf (if required),"
		echo "and also to add the required includes into all your vhost files."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./setup-ngxblocker -x -e conf

		echo ""
		echo "Test your nginx configuration"
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		/usr/sbin/nginx -t

		echo ""
		echo "Restart Nginx,"
		echo "and the Bot Blocker will immediately be active and protecting all your web sites."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		/usr/sbin/nginx -t && systemctl restart nginx

		echo "That's it, the blocker is now active and protecting your sites from thousands of malicious bots and domains."
		echo ""
		echo "For more info, visit: https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker"
		echo ""
		exit
	;;    
	3) # Uninstall Nginx
		while [[ $CONF !=  "y" && $CONF != "n" ]]; do
			read -p "       Remove configuration files ? [y/n]: " -e CONF
		done
		while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
			read -p "       Remove logs files ? [y/n]: " -e LOGS
		done
		# Stop Nginx
		echo -ne "       Stopping Nginx                 [..]\r"
		systemctl stop nginx
		if [ $? -eq 0 ]; then
			echo -ne "       Stopping Nginx                 [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Stopping Nginx                 [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi
		# Removing Nginx files and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service >> /tmp/nginx-install.log 2>&1

		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"

		# Remove conf files
		if [[ "$CONF" = 'y' ]]; then
			echo -ne "       Removing configuration files   [..]\r"
			rm -r /etc/nginx/ >> /tmp/nginx-install.log 2>&1
			echo -ne "       Removing configuration files   [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# Remove logs
		if [[ "$LOGS" = 'y' ]]; then
			echo -ne "       Removing log files             [..]\r"
			rm -r /var/log/nginx >> /tmp/nginx-install.log 2>&1
			echo -ne "       Removing log files             [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# We're done !
		echo ""
		echo -e "       ${CGREEN}Uninstallation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-install.log"
		echo ""

	exit
	;;
	4) # Update the script
		wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/nginx-install.sh -O nginx-install.sh >> /tmp/nginx-install.log 2>&1
		chmod +x nginx-install.sh
		echo ""
		echo -e "${CGREEN}Update succcessful !${CEND}"
		sleep 2
		nginx-install.sh
		exit
	;;
	*) # Exit
		exit
	;;

esac
