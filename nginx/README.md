# Nginx AutoInstall

- Compile and install Nginx from source with optionnal modules. Modified from [here](https://github.com/Angristan/nginx-autoinstall)

```bash

Welcome to the nginx-autoinstall script.

What do you want to do?
   1) Install or update Nginx
   2) Uninstall Nginx
   3) Update the script
   4) Exit

Select an option [1-4]: 1

This script will install Nginx with some optional modules.

Do you want to install Nginx stable or mainline?
   1) Stable 1.14.2
   2) Mainline 1.15.8

Select an option [1-2]: 2

Please tell me which modules you want to install.
If you select none, Nginx will be installed with its default modules.

Modules to install :
       PageSpeed 1.13.35.2 [y/n]: y
       ngx_cache_purge [y/n]: y
       Brotli [y/n]: y
       Http Redis 2 [y/n]: y
       LDAP Auth  [y/n]: y
       NAXSI WAF (Does not play well with HTTP2)  [y/n]: y
       Headers More 0.33 [y/n]: y
       Fancy index [y/n]: y
       Nginx virtual host traffic status [y/n]: y
       GeoIP 2 [y/n]: y
       Cloudflare's TLS Dynamic Record Resizing patch [y/n]: y
       Http LUA module [y/n]: y

Choose your OpenSSL implementation :
   1) System's OpenSSL (1.1.0j)
   2) OpenSSL 1.1.0h from source
   3) LibreSSL 2.7.4 from source 

Select an option [1-3]: 1

Nginx is ready to be installed, press any key to continue...

       Installing dependencies        [OK]
       Downloading ngx_pagespeed      [OK]
       Downloading libbrotli          [OK]
       Configuring libbrotli          [OK]
       Compiling libbrotli            [OK]
       Installing libbrotli           [OK]
       Downloading ngx_brotli         [OK]
       Downloading LDAP Auth          [OK]
       Downloading Nginx VTS          [OK]
       Downloading HTTP Redis 2       [OK]
       Downloading NAXSI              [OK]
       Downloading ngx_headers_more   [OK]
       Downloading GeoIP 2 databases  [OK]
       Downloading ngx_cache_purge    [OK]
       Downloading OpenResty's LuaJIT [OK]
       Configuring OpenResty's LuaJIT [OK]
       Installing OpenResty's LuaJIT  [OK]
       Downloading ngx_devel_kit      [OK]
       Downloading lua-nginx-module   [OK]
       Downloading Nginx              [OK]
       TLS Dynamic Records support    [OK]
       Configuring Nginx              [OK]
       Compiling Nginx                [OK]
       Installing Nginx               [OK]
       Restarting Nginx               [OK]
       Blocking nginx from APT        [OK]
       Removing Nginx files           [OK]

       Installation successful !

       Installation log: /tmp/nginx-install.log
             
```

## Compatibility

* x86, x64, arm*
* Debian 8 and later
* Ubuntu 16.04 and later

## Features

- Latest mainline or stable version, from source
- Optional modules (see below)
- Removed useless modules
- [Custom nginx.conf](https://github.com/marirs/autoinstalls/blob/master/conf/nginx.conf) (default does not work)
- [Init script for systemd](https://github.com/marirs/autoinstalls/blob/master/conf/nginx.service) (not provided by default)
- [Logrotate conf](https://github.com/marirs/autoinstalls/blob/master/conf/nginx-logrotate) (not provided by default)

### Optional modules/features

- [LDAP Authentication](https://github.com/kvspb/nginx-auth-ldap) Allow Nginx to authenticate via LDAP
- [NAXSI WAF](https://github.com/nbs-system/naxsi) Web Application Firewall for Nginx
- [Nginx Virtual Host Traffic Status](https://github.com/vozlt/nginx-module-vts)
- [LibreSSL from source](http://www.libressl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [OpenSSL from source](https://www.openssl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [ngx_pagespeed](https://github.com/pagespeed/ngx_pagespeed) (Google performance module)
- [ngx_brotli](https://github.com/google/ngx_brotli) (Brotli compression algorithm)
- [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module) (Custom HTTP headers)
- [GeoIP 2](https://www.nginx.com/products/nginx/modules/geoip2/) (GeoIP module and databases)
- [GeoIP](http://dev.maxmind.com/geoip/geoip2/geolite2/) (GeoIP module and databases)
- Cloudflare's TLS Dynamic Records Resizing patch
- [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge) (Purge content from FastCGI, proxy, SCGI and uWSGI caches)
- Fancy Index
- [Http Redis 2](https://www.nginx.com/resources/wiki/modules/redis/)
- [Http Lua](https://www.nginx.com/resources/wiki/modules/lua/)

## Install Nginx

Just download and execute the script :
```
wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx-install.sh
chmod +x nginx-autoinstall.sh
./nginx-autoinstall.sh
```

You can check [configuration examples](https://github.com/marirs/autoinstalls/tree/master/conf) for the custom modules.

## Uninstall Nginx

Just select the option when running the script :

![update](https://lut.im/Hj7wJKWwke/WZqeHT1QwwGfKXFf.png)

You have te choice to delete the logs and the conf.

## Update Nginx

To update Nginx, run the script and install Nginx again. It will overwrite current Nginx files and/or modules.

## Update the script

The update feature downloads the script from this repository, and overwrite the current `nginx-autoinstall.sh` file in the working directory. This allows you to get the latest features, bug fixes, and module versions automatically.

![update](https://lut.im/uQSSVxAz09/zhZRuvJjZp2paLHm.png)

## Log file

A log file is created when running the script. It is located at `/tmp/nginx-install.log`.


## LICENSE

GPL v3.0

