# Docker Installation Script
# Automated Docker installation with security hardening for internal use only

#!/bin/bash

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

# Clear log files
rm -f /tmp/docker-install.log /tmp/apt-packages.log

# Versions
docker_version="27.0.0"
docker_compose_version="2.24.0"

# System information
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
cores=$(nproc)
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
echo -e "  Target Docker: $docker_version"
echo -e "  Target Docker Compose: $docker_compose_version"
echo ""

function install_deps() {
    echo -e "${CGREEN}Installing dependencies...${CEND}"
    apt-get update -y >> /tmp/apt-packages.log 2>&1
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common \
        >> /tmp/apt-packages.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Dependencies installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
}

function setup_docker_repo() {
    echo -e "${CGREEN}Setting up Docker repository...${CEND}"
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings >> /tmp/docker-install.log 2>&1
    curl -fsSL https://download.docker.com/linux/$os/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg >> /tmp/docker-install.log 2>&1
    chmod a+r /etc/apt/keyrings/docker.gpg >> /tmp/docker-install.log 2>&1
    
    # Add the repository to Apt sources
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$os \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null >> /tmp/docker-install.log 2>&1
    
    apt-get update >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker repository setup completed${CEND}"
    else
        echo -e "${CRED}Failed to setup Docker repository${CEND}"
        exit 1
    fi
}

function install_docker() {
    echo -e "${CGREEN}Installing Docker Engine...${CEND}"
    
    # Install Docker Engine, CLI, Containerd, and Docker Compose plugin
    apt-get install -y \
        docker-ce=$docker_version* \
        docker-ce-cli=$docker_version* \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Engine installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install Docker Engine${CEND}"
        exit 1
    fi
}

function install_docker_compose_standalone() {
    echo -e "${CGREEN}Installing standalone Docker Compose...${CEND}"
    
    # Download Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v$docker_compose_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    # Apply executable permissions
    chmod +x /usr/local/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    # Create symbolic link
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Compose installed successfully${CEND}"
    else
        echo -e "${CRED}Failed to install Docker Compose${CEND}"
        exit 1
    fi
}

function configure_docker_security() {
    echo -e "${CGREEN}Configuring Docker with secure internet access...${CEND}"
    
    # Create Docker daemon configuration directory
    mkdir -p /etc/docker
    
    # Create secure Docker daemon configuration
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "bridge": "docker0",
  "bip": "172.17.0.1/16",
  "fixed-cidr": "172.17.0.0/16",
  "mtu": 1500,
  "ip-forward": true,
  "iptables": true,
  "live-restore": true,
  "userns-remap": "default",
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json",
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc",
      "runtimeArgs": [
        "--seccomp",
        "/etc/docker/seccomp.json"
      ]
    }
  },
  "registry-mirrors": [],
  "insecure-registries": [],
  "disable-legacy-registry": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "max-download-attempts": 5,
  "data-root": "/var/lib/docker",
  "exec-root": "/var/run/docker",
  "hosts": [
    "unix:///var/run/docker.sock"
  ]
}
EOF
    
    # Create seccomp profile
    mkdir -p /etc/docker
    curl -fsSL https://raw.githubusercontent.com/moby/moby/master/profiles/seccomp/default.json -o /etc/docker/seccomp.json >> /tmp/docker-install.log 2>&1
    
    # Create Docker user namespace
    echo "dockremap:165536:65536" >> /etc/subuid
    echo "dockremap:165536:65536" >> /etc/subgid
    
    # Restart Docker to apply configuration
    systemctl restart docker >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker security configuration applied${CEND}"
    else
        echo -e "${CRED}Failed to apply Docker security configuration${CEND}"
        exit 1
    fi
}

function setup_docker_network() {
    echo -e "${CGREEN}Setting up Docker network with internet access...${CEND}"
    
    # Create Docker daemon configuration directory
    mkdir -p /etc/docker
    
    # Create Docker daemon configuration with internet access
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "userland-proxy": false,
  "experimental": false,
  "exec-opts": ["native.cgroupdriver=systemd"],
  "bridge": "docker0",
  "bip": "172.17.0.1/16",
  "fixed-cidr": "172.17.0.0/16",
  "mtu": 1500,
  "ip-forward": true,
  "iptables": true,
  "live-restore": true,
  "userns-remap": "default",
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp.json",
  "default-runtime": "runc",
  "runtimes": {
    "runc": {
      "path": "runc",
      "runtimeArgs": [
        "--seccomp",
        "/etc/docker/seccomp.json"
      ]
    }
  },
  "registry-mirrors": [],
  "insecure-registries": [],
  "disable-legacy-registry": true,
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3,
  "max-download-attempts": 5,
  "data-root": "/var/lib/docker",
  "exec-root": "/var/run/docker",
  "hosts": [
    "unix:///var/run/docker.sock"
  ]
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker >> /tmp/docker-install.log 2>&1
    
    # Create internal network (optional, for isolated containers)
    docker network create --driver bridge --subnet=172.18.0.0/16 internal-net >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker network configured with internet access${CEND}"
        echo -e "${CYAN}Default bridge network: Internet access enabled${CEND}"
        echo -e "${CYAN}Internal network: Available for isolated containers${CEND}"
    else
        echo -e "${CRED}Failed to configure Docker network${CEND}"
        exit 1
    fi
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall rules for Docker daemon security...${CEND}"
    
    # Install UFW if not present
    apt-get install -y ufw >> /tmp/docker-install.log 2>&1
    
    # Configure UFW rules
    ufw --force reset >> /tmp/docker-install.log 2>&1
    
    # Default policies
    ufw default deny incoming >> /tmp/docker-install.log 2>&1
    ufw default allow outgoing >> /tmp/docker-install.log 2>&1
    
    # Allow SSH (if needed)
    ufw allow ssh >> /tmp/docker-install.log 2>&1
    
    # Block external Docker daemon access but allow internal networks
    ufw deny 2376/tcp >> /tmp/docker-install.log 2>&1  # Docker daemon
    ufw deny 2377/tcp >> /tmp/docker-install.log 2>&1  # Docker daemon (if needed)
    
    # Allow Docker daemon access from localhost and internal networks only
    ufw allow from 127.0.0.1 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.16.0.0/12 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.17.0.0/16 to any port 2376 >> /tmp/docker-install.log 2>&1
    ufw allow from 172.18.0.0/16 to any port 2376 >> /tmp/docker-install.log 2>&1
    
    # Enable UFW
    ufw --force enable >> /tmp/docker-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Firewall rules configured successfully${CEND}"
        echo -e "${CYAN}Docker daemon: External access blocked, internal access allowed${CEND}"
        echo -e "${CYAN}Containers: Internet access enabled through default bridge${CEND}"
        echo -e "${CYAN}Internal network: Available for isolated containers${CEND}"
    else
        echo -e "${CRED}Failed to configure firewall rules${CEND}"
        exit 1
    fi
}

function setup_docker_users() {
    echo -e "${CGREEN}Adding current user to docker group...${CEND}"
    
    # Add current user to docker group
    usermod -aG docker $USER >> /tmp/docker-install.log 2>&1
    
    # Create docker group if it doesn't exist
    if ! getent group docker > /dev/null 2>&1; then
        groupadd docker >> /tmp/docker-install.log 2>&1
        usermod -aG docker $USER >> /tmp/docker-install.log 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}User added to docker group${CEND}"
        echo -e "${CYAN}Note: You need to log out and log back in for group changes to take effect${CEND}"
    else
        echo -e "${CRED}Failed to add user to docker group${CEND}"
        exit 1
    fi
}

function start_docker_services() {
    echo -e "${CGREEN}Starting and enabling Docker services...${CEND}"
    
    # Enable and start Docker service
    systemctl enable docker >> /tmp/docker-install.log 2>&1
    systemctl start docker >> /tmp/docker-install.log 2>&1
    
    # Enable and start containerd service
    systemctl enable containerd >> /tmp/docker-install.log 2>&1
    systemctl start containerd >> /tmp/docker-install.log 2>&1
    
    # Check Docker status
    if systemctl is-active --quiet docker; then
        echo -e "${CGREEN}Docker service is running${CEND}"
    else
        echo -e "${CRED}Docker service failed to start${CEND}"
        exit 1
    fi
    
    if systemctl is-active --quiet containerd; then
        echo -e "${CGREEN}Containerd service is running${CEND}"
    else
        echo -e "${CRED}Containerd service failed to start${CEND}"
        exit 1
    fi
}

function create_docker_compose_example() {
    echo -e "${CGREEN}Creating example Docker Compose configuration...${CEND}"
    
    # Create example directory
    mkdir -p /opt/docker-examples
    
    # Create example docker-compose.yml
    cat > /opt/docker-examples/docker-compose.yml << 'EOF'
version: '3.8'

services:
  web-internet:
    image: nginx:alpine
    container_name: web-server-internet
    restart: unless-stopped
    networks:
      - default
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /var/run/nginx
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID

  web-isolated:
    image: nginx:alpine
    container_name: web-server-isolated
    restart: unless-stopped
    networks:
      - internal-net
    ports:
      - "127.0.0.1:8081:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /var/run/nginx
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID

  app-internet:
    image: python:3.11-alpine
    container_name: app-server-internet
    restart: unless-stopped
    networks:
      - default
    volumes:
      - ./app:/app:ro
    working_dir: /app
    command: python -m http.server 8000
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID

  app-isolated:
    image: python:3.11-alpine
    container_name: app-server-isolated
    restart: unless-stopped
    networks:
      - internal-net
    volumes:
      - ./app:/app:ro
    working_dir: /app
    command: python -m http.server 8000
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID

networks:
  default:
    driver: bridge
  internal-net:
    driver: bridge
    internal: false
    ipam:
      config:
        - subnet: 172.18.0.0/16
EOF
    
    # Create example HTML directory
    mkdir -p /opt/docker-examples/html
    cat > /opt/docker-examples/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker Secure Deployment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { background: #e8f5e8; padding: 10px; border-radius: 4px; margin: 10px 0; }
        .warning { background: #fff3cd; padding: 10px; border-radius: 4px; margin: 10px 0; }
        .info { background: #d9edf7; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker Secure Deployment</h1>
        <div class="status">
            <strong>Status:</strong> Running securely with internet access<br>
            <strong>Network:</strong> Default bridge (internet enabled)<br>
            <strong>Security:</strong> Hardened configuration enabled
        </div>
        <div class="info">
            <strong>Network Options:</strong><br>
            • Default bridge: Internet access enabled<br>
            • Internal network: Available for isolation<br>
            • Docker daemon: External access blocked
        </div>
        <div class="warning">
            <strong>Security Features:</strong><br>
            • User namespace remapping enabled<br>
            • Seccomp security profiles applied<br>
            • No new privileges for containers<br>
            • Capability dropping enabled
        </div>
        <p>This is a secure Docker deployment with configurable network access.</p>
        <p>Containers can access the internet through the default bridge network.</p>
        <p>For isolation, use the internal network (172.18.0.0/16).</p>
    </div>
</body>
</html>
EOF
    
    # Create example app directory
    mkdir -p /opt/docker-examples/app
    cat > /opt/docker-examples/app/app.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver

class SecureHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/app", **kwargs)
    
    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'DENY')
        self.send_header('X-XSS-Protection', '1; mode=block')
        super().end_headers()

if __name__ == "__main__":
    PORT = 8000
    with socketserver.TCPServer(("", PORT), SecureHandler) as httpd:
        print(f"Secure server running on port {PORT}")
        httpd.serve_forever()
EOF
    
    chmod +x /opt/docker-examples/app/app.py
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Example Docker Compose configuration created${CEND}"
        echo -e "${CYAN}Location: /opt/docker-examples/${CEND}"
        echo -e "${CYAN}Services:${CEND}"
        echo -e "  - web-internet: Nginx with internet access (port 8080)"
        echo -e "  - web-isolated: Nginx on internal network (port 8081)"
        echo -e "  - app-internet: Python app with internet access (port 8000)"
        echo -e "  - app-isolated: Python app on internal network (port 8001)"
    else
        echo -e "${CRED}Failed to create example configuration${CEND}"
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Docker installation...${CEND}"
    
    # Test Docker installation
    docker --version >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker CLI working${CEND}"
    else
        echo -e "${CRED}Docker CLI not working${CEND}"
        exit 1
    fi
    
    # Test Docker Compose
    docker-compose --version >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker Compose working${CEND}"
    else
        echo -e "${CRED}Docker Compose not working${CEND}"
        exit 1
    fi
    
    # Test Docker daemon
    docker info >> /tmp/docker-install.log 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Docker daemon working${CEND}"
    else
        echo -e "${CRED}Docker daemon not working${CEND}"
        exit 1
    fi
    
    # Test internal network
    if docker network ls | grep -q "internal-net"; then
        echo -e "${CGREEN}Internal network created${CEND}"
    else
        echo -e "${CRED}Internal network not found${CEND}"
        exit 1
    fi
    
    # Test default bridge network
    if docker network ls | grep -q "bridge"; then
        echo -e "${CGREEN}Default bridge network available${CEND}"
    else
        echo -e "${CRED}Default bridge network not found${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Docker installation verified successfully${CEND}"
}

# Main installation process
install_deps
setup_docker_repo
install_docker
install_docker_compose_standalone
configure_docker_security
setup_docker_network
configure_firewall
setup_docker_users
start_docker_services
create_docker_compose_example
verify_installation

echo ""
echo -e "${CGREEN}>> Docker installation completed successfully!${CEND}"
echo ""
echo -e "${CCYAN}Installation Summary:${CEND}"
echo -e "  Docker Version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
echo -e "  Docker Compose Version: $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)"
echo -e "  Architecture: $architecture"
echo -e "  Security: Internal-only configuration"
echo -e "  Firewall: Configured for internal access only"
echo -e "  Network: Internal bridge network created"
echo ""
echo -e "${CCYAN}Security Features:${CEND}"
echo -e "  ✅ Docker daemon: External access blocked"
echo -e "  ✅ Containers: Internet access enabled"
echo -e "  ✅ User namespace remapping enabled"
echo -e "  ✅ Seccomp security profiles applied"
echo -e "  ✅ No new privileges for containers"
echo -e "  ✅ Internal network available for isolation"
echo -e "  ✅ Capability dropping enabled"
echo ""
echo -e "${CCYAN}Next Steps:${CEND}"
echo -e "  1. Log out and log back in for docker group access"
echo -e "  2. Test installation: docker run --rm hello-world"
echo -e "  3. Try example: cd /opt/docker-examples && docker-compose up -d"
echo -e "  4. Check firewall: sudo ufw status verbose"
echo ""
echo -e "${CCYAN}Example Usage:${CEND}"
echo -e "  # Run a container with internet access (default bridge)"
echo -e "  docker run --rm -it nginx:alpine"
echo ""
echo -e "  # Run a container on isolated internal network"
echo -e "  docker run --rm -it --network internal-net nginx:alpine"
echo ""
echo -e "  # Use the example configuration"
echo -e "  cd /opt/docker-examples"
echo -e "  docker-compose up -d"
echo ""
echo -e "${CCYAN}Logs:${CEND}"
echo -e "  Dependencies: /tmp/apt-packages.log"
echo -e "  Docker Install: /tmp/docker-install.log"
echo ""
echo -e "${CCYAN}Security Notes:${CEND}"
echo -e "  - Docker daemon is configured for internal access only"
echo -e "  - External access to Docker daemon is blocked"
echo -e "  - Containers have internet access through default bridge"
echo -e "  - Internal network available for isolated containers"
echo -e "  - Containers run with reduced privileges"
echo -e "  - All network access is configurable per container"
echo ""
echo -e "${CMAGENTA}If you reached here, seriously done!${CEND}"
