# Kubernetes Container Orchestration Auto-Installation Script
![https://img.shields.io/badge/kubernetes-1.29.0-blue](https://img.shields.io/badge/kubernetes-1.29.0-blue)
![https://img.shields.io/badge/containerd-1.7.11-green](https://img.shields.io/badge/containerd-1.7.11-green)
![https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange](https://img.shields.io/badge/platform-ubuntu%2018.04%2C%2020.04%2C%2022.04%2C%2024.04%20%7C%20Debian%209.x%2C%2010.x%2C%2011.x%2C%2012.x-orange)
![https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green](https://img.shields.io/badge/architecture-x86__64%20%7C%20ARM64-green)
![https://img.shields.io/badge/security-enterprise%20ready-purple](https://img.shields.io/badge/security-enterprise%20ready-purple)
![https://img.shields.io/badge/status-production%20ready-green](https://img.shields.io/badge/status-production%20ready-green)

## Overview

This script installs Kubernetes 1.29.0 with containerd runtime and comprehensive security hardening. The installation provides a single-node cluster setup suitable for development, testing, and production workloads with enterprise-grade security configurations.

## Quick Start

```bash
# Navigate to the Kubernetes directory
cd kubernetes/

# Run the installation script
sudo ./kubernetes-install.sh

# Initialize cluster after installation
sudo kubernetes-manager init

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 🛡️ Security Features

### ✅ System Security
- **Swap disabled**: Required for Kubernetes performance and security
- **Kernel modules**: Required modules loaded and configured
- **Sysctl parameters**: Network and security parameters optimized
- **Systemd hardening**: Resource limits and process isolation
- **Firewall configuration**: UFW/iptables rules for Kubernetes ports

### ✅ Container Security
- **containerd runtime**: Secure container runtime with systemd cgroup
- **Rootless containers**: Non-privileged container execution
- **Image security**: Secure image handling and scanning
- **Network policies**: Ready for network policy enforcement

### ✅ Cluster Security
- **API Server Security**: Secure API server configuration
- **etcd security**: Encrypted etcd storage
- **Network isolation**: Pod network segmentation ready
- **RBAC enabled**: Role-based access control configured

## Installation Steps

1. **System Compatibility Check**: Verifies OS, memory, CPU, and architecture
2. **Dependency Installation**: Required system packages and tools
3. **System Configuration**: Disable swap, load kernel modules, configure sysctl
4. **containerd Installation**: Install and configure containerd runtime
5. **Kubernetes Repository Setup**: Add official Kubernetes repository
6. **Kubernetes Installation**: Install kubeadm, kubelet, kubectl
7. **Security Configuration**: Systemd hardening and resource limits
8. **Firewall Setup**: Configure firewall for Kubernetes ports
9. **Service Start**: Start kubelet and containerd services
10. **Verification**: Test installation and service status

## Configuration Details

### Kubernetes Components
- **Kubernetes Version**: 1.29.0
- **containerd Version**: 1.7.11
- **kubeadm Version**: 1.29.0-1.1
- **kubelet Version**: 1.29.0-1.1
- **kubectl Version**: 1.29.0-1.1

### Network Configuration
- **Pod Network CIDR**: 10.244.0.0/16 (for Flannel CNI)
- **API Server Port**: 6443
- **etcd Port**: 2379-2380
- **Kubelet Port**: 10250
- **Scheduler Port**: 10251
- **Controller Manager Port**: 10252

### Security Configuration
- **Swap**: Disabled for performance
- **Kernel Modules**: overlay, br_netfilter loaded
- **Sysctl Parameters**: IP forwarding, bridge filtering enabled
- **Cgroup Driver**: systemd for better security
- **Resource Limits**: Memory and CPU limits configured

## Management Tools

### kubernetes-monitor
```bash
# Show comprehensive Kubernetes status
kubernetes-monitor

# Show specific information
kubernetes-monitor status      # Service and cluster status
kubernetes-monitor nodes      # Node information
kubernetes-monitor pods       # Pod information
kubernetes-monitor services   # Service information
```

### kubernetes-manager
```bash
# Manage Kubernetes services
kubernetes-manager start       # Start Kubernetes services
kubernetes-manager stop        # Stop Kubernetes services
kubernetes-manager restart     # Restart Kubernetes services
kubernetes-manager logs        # Show service logs

# Cluster management
kubernetes-manager init        # Initialize Kubernetes cluster
kubernetes-manager reset       # Reset Kubernetes cluster
```

## Usage Examples

### Basic Kubernetes Operations
```bash
# Check cluster status
kubectl cluster-info

# Get node information
kubectl get nodes -o wide

# Get all pods in all namespaces
kubectl get pods --all-namespaces

# Get services
kubectl get services --all-namespaces

# Get system events
kubectl get events --all-namespaces

# Check component statuses
kubectl get componentstatuses
```

### Cluster Initialization
```bash
# Initialize cluster (run as root)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI plugin (Flannel example)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Allow master node to schedule pods (for single-node setup)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Pod Management
```bash
# Create a simple nginx pod
kubectl run nginx --image=nginx --port=80

# Create pod from YAML file
kubectl create -f nginx-pod.yaml

# Get pod details
kubectl describe pod nginx

# Get pod logs
kubectl logs nginx

# Exec into pod
kubectl exec -it nginx -- /bin/bash

# Delete pod
kubectl delete pod nginx
```

### Deployment and Service Management
```bash
# Create deployment
kubectl create deployment nginx-deployment --image=nginx --replicas=3

# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Expose deployment as service
kubectl expose deployment nginx-deployment --port=80 --type=NodePort

# Get deployment status
kubectl get deployment nginx-deployment

# Update deployment image
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# Rollback deployment
kubectl rollout undo deployment/nginx-deployment
```

## YAML Examples

### Pod Configuration
```yaml
# nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

### Deployment Configuration
```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

### Service Configuration
```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```

## File Structure

```
/etc/kubernetes/
├── admin.conf               # kubectl configuration
├── kubelet.conf             # kubelet configuration
├── manifests/               # Static pod manifests
└── pki/                     # Cluster certificates

/var/lib/kubelet/
├── config.yaml              # kubelet configuration
└── plugins/                 # kubelet plugins

/var/lib/kubernetes/
├── etcd/                    # etcd data directory
└── pki/                     # Additional certificates

/etc/containerd/
├── config.toml              # containerd configuration
└── certs/                   # containerd certificates

/usr/local/bin/
├── kubernetes-monitor       # Monitoring script
└── kubernetes-manager       # Management script

/tmp/
└── kubernetes-install.log   # Installation log
```

## CNI (Container Network Interface) Setup

### Flannel CNI
```bash
# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Verify CNI pods
kubectl get pods -n kube-flannel
```

### Calico CNI
```bash
# Install Calico CNI
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml

# Install custom resources
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml

# Verify CNI pods
kubectl get pods -n calico-system
```

## Security Checklist

### Pre-Installation
- [ ] System updated and patched
- [ ] Minimum 2GB RAM available (recommended 4GB+)
- [ ] Minimum 2 CPU cores available
- [ ] Sufficient disk space for containers and images
- [ ] Swap space disabled
- [ ] Root access available

### Post-Installation
- [ ] Kubernetes services running correctly
- [ ] kubelet service active and healthy
- [ ] containerd service active and healthy
- [ ] Firewall rules configured
- [ ] Cluster initialization successful
- [ ] Monitoring scripts working

### Ongoing Security
- [ ] Regular security updates applied
- [ ] Monitor cluster health and performance
- [ ] Review pod security policies
- [ ] Monitor network traffic
- [ ] Backup etcd data regularly
- [ ] Rotate certificates regularly

## Troubleshooting

### Service Issues
```bash
# Check service status
systemctl status kubelet
systemctl status containerd

# Check service logs
journalctl -u kubelet -f
journalctl -u containerd -f

# Restart services
kubernetes-manager restart
```

### Cluster Issues
```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check events
kubectl get events --all-namespaces

# Reset cluster if needed
sudo kubernetes-manager reset
```

### Network Issues
```bash
# Check CNI pods
kubectl get pods -n kube-flannel
kubectl get pods -n calico-system

# Check network connectivity
ping 10.244.0.1  # Pod network gateway

# Check firewall rules
ufw status verbose
iptables -L
```

## Performance Considerations

### Resource Management
- **Memory**: Minimum 2GB, recommended 4GB+ for production
- **CPU**: Minimum 2 cores, recommended 4+ for production
- **Storage**: Use SSD for better etcd and container performance
- **Network**: Gigabit network recommended for cluster communication

### Optimization Tips
- **Resource Limits**: Set appropriate resource requests and limits
- **Node Affinity**: Use node affinity for better performance
- **Pod Disruption**: Configure pod disruption budgets
- **Monitoring**: Use monitoring tools for performance insights

## Advanced Configuration

### Production Setup
```yaml
# kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "192.168.1.100"
  bindPort: 6443
nodeRegistration:
  kubeletExtraArgs:
    pod-infra-container-image: "registry.k8s.io/pause:3.9"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "v1.29.0"
controlPlaneEndpoint: "192.168.1.100:6443"
networking:
  serviceSubnet: "10.96.0.0/12"
  podSubnet: "10.244.0.0/16"
  dnsDomain: "cluster.local"
etcd:
  external:
    endpoints:
    - "https://192.168.1.100:2379"
apiServer:
  extraArgs:
    enable-admission-plugins: "NodeRestriction,ResourceQuota,PodSecurityPolicy"
```

### Multi-node Cluster
```bash
# On master node
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<MASTER_IP>

# Get join command
sudo kubeadm token create --print-join-command

# On worker nodes
sudo <JOIN_COMMAND_FROM_MASTER>
```

## Integration Examples

### Microservices Deployment
```yaml
# microservices-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          value: "postgresql://postgres:5432/users"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

### Ingress Configuration
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 80
```

## Compliance and Standards

This installation follows:
- **Kubernetes Security Best Practices**: Official security guidelines
- **CIS Benchmarks**: Center for Internet Security benchmarks
- **NIST Guidelines**: National Institute of Standards and Technology
- **Industry Standards**: Container orchestration security standards

## Support and Maintenance

### Regular Maintenance
- Update Kubernetes to latest stable version
- Monitor cluster health and performance
- Review and optimize resource usage
- Backup etcd data regularly
- Rotate certificates before expiration

### Backup and Recovery
```bash
# Backup etcd data
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore etcd data
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

This Kubernetes installation provides a secure, performant, and maintainable container orchestration platform suitable for development, testing, and production workloads.
