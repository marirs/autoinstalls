#!/bin/bash

# Kubernetes Installation Script
# Secure Kubernetes 1.29 installation with comprehensive security hardening

set -e

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34b"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

# Kubernetes Configuration
KUBERNETES_VERSION="1.29.0"
KUBELET_VERSION="1.29.0-1.1"
KUBEADM_VERSION="1.29.0-1.1"
KUBECTL_VERSION="1.29.0-1.1"
CRI_DOCKERD_VERSION="0.3.10"
CONTAINERD_VERSION="1.7.11"

# System Information
ARCH=$(uname -m)
OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
HOSTNAME=$(hostname)

# Logging
LOG_FILE="/tmp/kubernetes-install.log"
APT_LOG="/tmp/apt-packages.log"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}   Kubernetes Auto-Installation${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CCYAN}Kubernetes Version: ${KUBERNETES_VERSION}${CEND}"
    echo -e "${CCYAN}Container Runtime: containerd${CEND}"
    echo -e "${CCYAN}Architecture: ${ARCH}${CEND}"
    echo -e "${CCYAN}OS: ${OS} ${OS_VERSION}${CEND}"
    echo -e "${CCYAN}Hostname: ${HOSTNAME}${CEND}"
    echo ""
}

function check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${CRED}Please run as root or with sudo${CEND}"
        exit 1
    fi
}

function check_system() {
    echo -e "${CGREEN}Checking system compatibility...${CEND}"
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${CCYAN}Operating System: $NAME $VERSION${CEND}"
    else
        echo -e "${CRED}Cannot determine OS version${CEND}"
        exit 1
    fi
    
    # Check architecture
    echo -e "${CCYAN}Architecture: $ARCH${CEND}"
    
    # Check memory requirements (Kubernetes needs at least 2GB)
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    echo -e "${CCYAN}Total Memory: ${total_mem}GB${CEND}"
    
    if [ "$total_mem" -lt 2 ]; then
        echo -e "${CRED}Warning: Kubernetes requires at least 2GB RAM for optimal performance${CEND}"
        read -p "Continue with less memory? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    echo -e "${CCYAN}CPU Cores: $cpu_cores${CEND}"
    
    if [ "$cpu_cores" -lt 2 ]; then
        echo -e "${CRED}Warning: Kubernetes requires at least 2 CPU cores for optimal performance${CEND}"
        read -p "Continue with less CPU cores? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    fi
    
    # Check if Kubernetes is already installed
    if command -v kubectl >/dev/null 2>&1; then
        echo -e "${CYAN}Kubernetes is already installed${CEND}"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Installation cancelled${CEND}"
            exit 0
        fi
    fi
    
    echo -e "${CGREEN}System compatibility check completed${CEND}"
}

function install_dependencies() {
    echo -e "${CGREEN}Installing dependencies...${CEND}"
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    # Install dependencies
    apt install -y \
        curl \
        wget \
        gnupg \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        conntrack \
        socat \
        ebtables \
        ipset \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install dependencies${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Dependencies installed successfully${CEND}"
}

function configure_system() {
    echo -e "${CGREEN}Configuring system for Kubernetes...${CEND}"
    
    # Disable swap
    echo -e "${CCYAN}Disabling swap...${CEND}"
    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    
    # Load required kernel modules
    echo -e "${CCYAN}Loading kernel modules...${CEND}"
    cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF
    
    modprobe overlay
    modprobe br_netfilter
    
    # Set sysctl parameters for Kubernetes networking
    echo -e "${CCYAN}Configuring sysctl parameters...${CEND}"
    cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    sysctl --system >> "$LOG_FILE" 2>&1
    
    # Configure hostname resolution
    echo "127.0.0.1   localhost" > /etc/hosts
    echo "127.0.1.1   $HOSTNAME" >> /etc/hosts
    
    echo -e "${CGREEN}System configuration completed${CEND}"
}

function install_containerd() {
    echo -e "${CGREEN}Installing containerd...${CEND}"
    
    # Remove old Docker/containerd installations
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >> "$LOG_FILE" 2>&1
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    # Install containerd
    apt install -y containerd.io=${CONTAINERD_VERSION} >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install containerd${CEND}"
        exit 1
    fi
    
    # Configure containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml >> "$LOG_FILE" 2>&1
    
    # Configure containerd to use systemd cgroup
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    
    # Restart and enable containerd
    systemctl restart containerd
    systemctl enable containerd
    
    echo -e "${CGREEN}containerd installed and configured successfully${CEND}"
}

function add_kubernetes_repository() {
    echo -e "${CGREEN}Adding Kubernetes repository...${CEND}"
    
    # Add Kubernetes GPG key
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg >> "$LOG_FILE" 2>&1
    
    # Add Kubernetes repository
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list >> "$LOG_FILE" 2>&1
    
    # Update package lists
    apt update >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to add Kubernetes repository${CEND}"
        exit 1
    fi
    
    echo -e "${CGREEN}Kubernetes repository added successfully${CEND}"
}

function install_kubernetes() {
    echo -e "${CGREEN}Installing Kubernetes components...${CEND}"
    
    # Install Kubernetes components
    apt install -y \
        kubelet=${KUBELET_VERSION} \
        kubeadm=${KUBEADM_VERSION} \
        kubectl=${KUBECTL_VERSION} \
        >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        echo -e "${CRED}Failed to install Kubernetes components${CEND}"
        exit 1
    fi
    
    # Hold Kubernetes packages to prevent automatic updates
    apt-mark hold kubelet kubeadm kubectl >> "$LOG_FILE" 2>&1
    
    echo -e "${CGREEN}Kubernetes components installed successfully${CEND}"
}

function configure_security() {
    echo -e "${CGREEN}Configuring Kubernetes security...${CEND}"
    
    # Create Kubernetes directories
    mkdir -p /etc/kubernetes/manifests
    mkdir -p /var/lib/kubelet
    mkdir -p /var/lib/kubernetes
    
    # Set proper permissions
    chmod 755 /etc/kubernetes
    chmod 755 /var/lib/kubelet
    chmod 755 /var/lib/kubernetes
    
    # Configure kubelet systemd service
    mkdir -p /etc/systemd/system/kubelet.service.d
    
    cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf << EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
Environment="KUBELET_SYSTEM_PODS_ARGS=--pod-manifest-path=/etc/kubernetes/manifests"
Environment="KUBELET_NETWORK_ARGS=--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"
Environment="KUBELET_DNS_ARGS=--cluster-dns=10.96.0.10 --cluster-domain=cluster.local"
Environment="KUBELET_AUTHZ_ARGS=--authorization-mode=Webhook --client-ca-file=/etc/kubernetes/pki/ca.crt"
Environment="KUBELET_CADVISOR_ARGS=--cadvisor-port=0"
Environment="KUBELET_CGROUP_ARGS=--cgroup-driver=systemd"
Environment="KUBELET_CERTIFICATE_ARGS=--rotate-certificates=true --cert-dir=/var/lib/kubelet/pki"
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock"
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_SYSTEM_PODS_ARGS \$KUBELET_NETWORK_ARGS \$KUBELET_DNS_ARGS \$KUBELET_AUTHZ_ARGS \$KUBELET_CADVISOR_ARGS \$KUBELET_CGROUP_ARGS \$KUBELET_CERTIFICATE_ARGS \$KUBELET_EXTRA_ARGS
EOF
    
    # Configure kubelet security
    cat > /etc/systemd/system/kubelet.service.d/security.conf << EOF
[Service]
# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/kubelet /var/lib/kubernetes /etc/kubernetes /tmp

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=4g

# File system access
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
EOF
    
    # Reload systemd and restart kubelet
    systemctl daemon-reload
    systemctl enable kubelet
    
    echo -e "${CGREEN}Kubernetes security configuration completed${CEND}"
}

function configure_firewall() {
    echo -e "${CGREEN}Configuring firewall for Kubernetes...${CEND}"
    
    # Configure UFW if available
    if command -v ufw >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring UFW firewall...${CEND}"
        
        # Allow required Kubernetes ports
        ufw allow 6443/tcp comment "Kubernetes API Server" >> "$LOG_FILE" 2>&1
        ufw allow 2379:2380/tcp comment "etcd server client API" >> "$LOG_FILE" 2>&1
        ufw allow 10250/tcp comment "Kubelet API" >> "$LOG_FILE" 2>&1
        ufw allow 10251/tcp comment "kube-scheduler" >> "$LOG_FILE" 2>&1
        ufw allow 10252/tcp comment "kube-controller-manager" >> "$LOG_FILE" 2>&1
        
        # Allow pod network communication
        ufw allow from 10.244.0.0/16 comment "Pod network" >> "$LOG_FILE" 2>&1
        
        echo -e "${CGREEN}UFW firewall configured for Kubernetes${CEND}"
    
    # Configure iptables if UFW is not available
    elif command -v iptables >/dev/null 2>&1; then
        echo -e "${CCYAN}Configuring iptables firewall...${CEND}"
        
        # Allow required Kubernetes ports
        iptables -A INPUT -p tcp --dport 6443 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport 2379:2380 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport 10250 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport 10251 -j ACCEPT >> "$LOG_FILE" 2>&1
        iptables -A INPUT -p tcp --dport 10252 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Allow pod network communication
        iptables -A INPUT -s 10.244.0.0/16 -j ACCEPT >> "$LOG_FILE" 2>&1
        
        # Save iptables rules
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        
        echo -e "${CGREEN}iptables firewall configured for Kubernetes${CEND}"
    else
        echo -e "${CYAN}No firewall found - please manually configure Kubernetes firewall rules${CEND}"
    fi
}

function create_monitoring_scripts() {
    echo -e "${CGREEN}Creating monitoring scripts...${CEND}"
    
    # Create Kubernetes monitoring script
    cat > /usr/local/bin/kubernetes-monitor << 'EOF'
#!/bin/bash

# Kubernetes Monitoring Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Kubernetes Monitoring${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function show_status() {
    echo -e "${CGREEN}Kubernetes Status:${CEND}"
    
    # Check kubelet service status
    if systemctl is-active --quiet kubelet; then
        echo -e "  Kubelet: ${CGREEN}Running${CEND}"
    else
        echo -e "  Kubelet: ${CRED}Stopped${CEND}"
    fi
    
    # Check containerd service status
    if systemctl is-active --quiet containerd; then
        echo -e "  Containerd: ${CGREEN}Running${CEND}"
    else
        echo -e "  Containerd: ${CRED}Stopped${CEND}"
    fi
    
    # Check cluster status if kubectl is available
    if command -v kubectl >/dev/null 2>&1; then
        local cluster_info=$(kubectl cluster-info 2>/dev/null)
        if [ -n "$cluster_info" ]; then
            echo -e "  Cluster: ${CGREEN}Available${CEND}"
        else
            echo -e "  Cluster: ${CRED}Not available${CEND}"
        fi
    else
        echo -e "  kubectl: ${CRED}Not available${CEND}"
    fi
    
    echo ""
}

function show_nodes() {
    echo -e "${CGREEN}Kubernetes Nodes:${CEND}"
    
    if command -v kubectl >/dev/null 2>&1; then
        local nodes=$(kubectl get nodes 2>/dev/null)
        if [ -n "$nodes" ]; then
            echo -e "  $nodes"
        else
            echo -e "  ${CRED}Cannot get node information${CEND}"
        fi
    else
        echo -e "  ${CRED}kubectl not available${CEND}"
    fi
    
    echo ""
}

function show_pods() {
    echo -e "${CGREEN}Kubernetes Pods:${CEND}"
    
    if command -v kubectl >/dev/null 2>&1; then
        local pods=$(kubectl get pods --all-namespaces 2>/dev/null | head -10)
        if [ -n "$pods" ]; then
            echo -e "  $pods"
        else
            echo -e "  ${CRED}Cannot get pod information${CEND}"
        fi
    else
        echo -e "  ${CRED}kubectl not available${CEND}"
    fi
    
    echo ""
}

function show_services() {
    echo -e "${CGREEN}Kubernetes Services:${CEND}"
    
    if command -v kubectl >/dev/null 2>&1; then
        local services=$(kubectl get services --all-namespaces 2>/dev/null | head -10)
        if [ -n "$services" ]; then
            echo -e "  $services"
        else
            echo -e "  ${CRED}Cannot get service information${CEND}"
        fi
    else
        echo -e "  ${CRED}kubectl not available${CEND}"
    fi
    
    echo ""
}

function main() {
    case "${1:-all}" in
        "status")
            show_header
            show_status
            ;;
        "nodes")
            show_header
            show_nodes
            ;;
        "pods")
            show_header
            show_pods
            ;;
        "services")
            show_header
            show_services
            ;;
        "all")
            show_header
            show_status
            show_nodes
            show_pods
            show_services
            ;;
        *)
            echo -e "${CRED}Unknown option: $1${CEND}"
            echo "Usage: $0 [status|nodes|pods|services|all]"
            exit 1
            ;;
    esac
}

main "$@"
EOF
    
    # Create Kubernetes management script
    cat > /usr/local/bin/kubernetes-manager << 'EOF'
#!/bin/bash

# Kubernetes Management Script

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CBLUE="${CSI}1;34m"
CMAGENTA="${CSI}1;35m"
CCYAN="${CSI}1;36c"

function show_header() {
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}    Kubernetes Manager${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
}

function start_services() {
    echo -e "${CGREEN}Starting Kubernetes services...${CEND}"
    
    systemctl start kubelet
    systemctl start containerd
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Kubernetes services started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start Kubernetes services${CEND}"
        exit 1
    fi
}

function stop_services() {
    echo -e "${CGREEN}Stopping Kubernetes services...${CEND}"
    
    systemctl stop kubelet
    systemctl stop containerd
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Kubernetes services stopped successfully${CEND}"
    else
        echo -e "${CRED}Failed to stop Kubernetes services${CEND}"
        exit 1
    fi
}

function restart_services() {
    echo -e "${CGREEN}Restarting Kubernetes services...${CEND}"
    
    systemctl restart kubelet
    systemctl restart containerd
    
    if [ $? -eq 0 ]; then
        echo -e "${CGREEN}Kubernetes services restarted successfully${CEND}"
    else
        echo -e "${CRED}Failed to restart Kubernetes services${CEND}"
        exit 1
    fi
}

function show_logs() {
    local service=$1
    
    case $service in
        "kubelet")
            echo -e "${CGREEN}Kubelet Logs:${CEND}"
            journalctl -u kubelet -f --lines=50
            ;;
        "containerd")
            echo -e "${CGREEN}Containerd Logs:${CEND}"
            journalctl -u containerd -f --lines=50
            ;;
        *)
            echo -e "${CCYAN}Available services: kubelet, containerd${CEND}"
            echo -e "Usage: $0 logs <service>"
            ;;
    esac
}

function initialize_cluster() {
    echo -e "${CGREEN}Initializing Kubernetes cluster...${CEND}"
    
    if command -v kubeadm >/dev/null 2>&1; then
        kubeadm init --pod-network-cidr=10.244.0.0/16
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}Kubernetes cluster initialized successfully${CEND}"
            echo -e "${CCYAN}To configure kubectl, run:${CEND}"
            echo -e "  mkdir -p \$HOME/.kube"
            echo -e "  sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
            echo -e "  sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
        else
            echo -e "${CRED}Failed to initialize Kubernetes cluster${CEND}"
            exit 1
        fi
    else
        echo -e "${CRED}kubeadm not available${CEND}"
        exit 1
    fi
}

function reset_cluster() {
    echo -e "${CGREEN}Resetting Kubernetes cluster...${CEND}"
    
    if command -v kubeadm >/dev/null 2>&1; then
        kubeadm reset --force
        
        if [ $? -eq 0 ]; then
            echo -e "${CGREEN}Kubernetes cluster reset successfully${CEND}"
        else
            echo -e "${CRED}Failed to reset Kubernetes cluster${CEND}"
            exit 1
        fi
    else
        echo -e "${CRED}kubeadm not available${CEND}"
        exit 1
    fi
}

function main() {
    case "${1:-help}" in
        "start")
            show_header
            start_services
            ;;
        "stop")
            show_header
            stop_services
            ;;
        "restart")
            show_header
            restart_services
            ;;
        "logs")
            show_logs "$2"
            ;;
        "init")
            show_header
            initialize_cluster
            ;;
        "reset")
            show_header
            reset_cluster
            ;;
        "help"|*)
            show_header
            echo -e "${CCYAN}Available commands:${CEND}"
            echo -e "  start          - Start Kubernetes services"
            echo -e "  stop           - Stop Kubernetes services"
            echo -e "  restart        - Restart Kubernetes services"
            echo -e "  logs           - Show service logs (kubelet|containerd)"
            echo -e "  init           - Initialize Kubernetes cluster"
            echo -e "  reset          - Reset Kubernetes cluster"
            echo ""
            ;;
    esac
}

main "$@"
EOF
    
    # Make scripts executable
    chmod +x /usr/local/bin/kubernetes-monitor
    chmod +x /usr/local/bin/kubernetes-manager
    
    echo -e "${CGREEN}Monitoring and management scripts created${CEND}"
}

function start_kubernetes() {
    echo -e "${CGREEN}Starting Kubernetes services...${CEND}"
    
    # Start kubelet service
    systemctl start kubelet
    
    # Wait for service to start
    sleep 5
    
    # Check if service is running
    if systemctl is-active --quiet kubelet; then
        echo -e "${CGREEN}Kubelet service started successfully${CEND}"
    else
        echo -e "${CRED}Failed to start Kubelet service${CEND}"
        systemctl status kubelet
        exit 1
    fi
}

function verify_installation() {
    echo -e "${CGREEN}Verifying Kubernetes installation...${CEND}"
    
    # Test kubeadm installation
    if command -v kubeadm >/dev/null 2>&1; then
        local kubeadm_version=$(kubeadm version --short 2>/dev/null)
        echo -e "${CGREEN}kubeadm installation: OK ($kubeadm_version)${CEND}"
    else
        echo -e "${CRED}kubeadm installation: FAILED${CEND}"
        return 1
    fi
    
    # Test kubelet installation
    if command -v kubelet >/dev/null 2>&1; then
        echo -e "${CGREEN}kubelet installation: OK${CEND}"
    else
        echo -e "${CRED}kubelet installation: FAILED${CEND}"
        return 1
    fi
    
    # Test kubectl installation
    if command -v kubectl >/dev/null 2>&1; then
        local kubectl_version=$(kubectl version --client --short 2>/dev/null)
        echo -e "${CGREEN}kubectl installation: OK ($kubectl_version)${CEND}"
    else
        echo -e "${CRED}kubectl installation: FAILED${CEND}"
        return 1
    fi
    
    # Test containerd installation
    if systemctl is-active --quiet containerd; then
        echo -e "${CGREEN}containerd service: OK${CEND}"
    else
        echo -e "${CRED}containerd service: FAILED${CEND}"
        return 1
    fi
    
    # Test kubelet service
    if systemctl is-active --quiet kubelet; then
        echo -e "${CGREEN}kubelet service: OK${CEND}"
    else
        echo -e "${CRED}kubelet service: FAILED${CEND}"
        return 1
    fi
    
    echo -e "${CGREEN}Kubernetes installation verified successfully${CEND}"
}

function show_success_message() {
    echo ""
    echo -e "${CBLUE}========================================${CEND}"
    echo -e "${CBLUE}   Kubernetes Installation Complete!${CEND}"
    echo -e "${CBLUE}========================================${CEND}"
    echo ""
    echo -e "${CCYAN}Installation Summary:${CEND}"
    echo -e "  Kubernetes Version: $KUBERNETES_VERSION"
    echo -e "  Container Runtime: containerd $CONTAINERD_VERSION"
    echo -e "  CNI: Not installed (install separately)"
    echo -e "  Configuration: /etc/kubernetes/"
    echo ""
    echo -e "${CCYAN}Components Installed:${CEND}"
    echo -e "  ✓ kubeadm - Cluster initialization tool"
    echo -e "  ✓ kubelet - Node agent"
    echo -e "  ✓ kubectl - Command line tool"
    echo -e "  ✓ containerd - Container runtime"
    echo ""
    echo -e "${CCYAN}Security Configuration:${CEND}"
    echo -e "  ✓ Swap disabled"
    echo -e "  ✓ Kernel modules loaded"
    echo -e "  ✓ Sysctl parameters configured"
    echo -e "  ✓ Systemd security hardening applied"
    echo -e "  ✓ Firewall rules configured"
    echo ""
    echo -e "${CCYAN}Management Commands:${CEND}"
    echo -e "  Service status: systemctl status kubelet containerd"
    echo -e "  Start services: kubernetes-manager start"
    echo -e "  Stop services: kubernetes-manager stop"
    echo -e "  Restart services: kubernetes-manager restart"
    echo -e "  View logs: kubernetes-manager logs kubelet"
    echo ""
    echo -e "${CCYAN}Cluster Initialization:${CEND}"
    echo -e "  Initialize cluster: kubernetes-manager init"
    echo -e "  Reset cluster: kubernetes-manager reset"
    echo -e "  Configure kubectl after init:"
    echo -e "    mkdir -p \$HOME/.kube"
    echo -e "    sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
    echo -e "    sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
    echo ""
    echo -e "${CCYAN}Monitoring:${CEND}"
    echo -e "  Check status: kubernetes-monitor"
    echo -e "  Cluster info: kubectl cluster-info"
    echo -e "  Node status: kubectl get nodes"
    echo ""
    echo -e "${CCYAN}Next Steps:${CEND}"
    echo -e "  1. Initialize cluster: kubernetes-manager init"
    echo -e "  2. Install CNI plugin (e.g., Flannel, Calico)"
    echo -e "  3. Configure kubectl"
    echo -e "  4. Deploy applications"
    echo ""
    echo -e "${CMAGENTA}Important Notes:${CEND}"
    echo -e "  • This is a single-node Kubernetes setup"
    echo -e "  • You need to install a CNI plugin for pod networking"
    echo -e "  • For production, consider multi-node cluster setup"
    echo -e "  • Kubernetes packages are held to prevent automatic updates"
    echo -e "  • Check system requirements for production workloads"
    echo ""
}

function cleanup() {
    echo -e "${CGREEN}Cleaning up temporary files...${CEND}"
    
    # Remove temporary files
    rm -f /tmp/test_kubernetes.sh 2>/dev/null || true
    
    echo -e "${CGREEN}Cleanup completed${CEND}"
}

function main() {
    show_header
    check_root
    check_system
    
    # Install dependencies
    install_dependencies
    
    # Configure system
    configure_system
    
    # Install containerd
    install_containerd
    
    # Add Kubernetes repository
    add_kubernetes_repository
    
    # Install Kubernetes
    install_kubernetes
    
    # Configure security
    configure_security
    
    # Configure firewall
    configure_firewall
    
    # Create monitoring scripts
    create_monitoring_scripts
    
    # Start Kubernetes services
    start_kubernetes
    
    # Verify installation
    verify_installation
    
    # Cleanup
    cleanup
    
    # Show success message
    show_success_message
}

# Run main function
main
