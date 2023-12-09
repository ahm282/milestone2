#!/bin/bash

set -e

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Update and set hostname
sudo apt-get update
sudo apt-get upgrade -y
sudo hostnamectl set-hostname "k8s-master"

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Update hosts file
echo "192.168.33.11 k8s-node01" | sudo tee -a /etc/hosts

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without reboot
sudo sysctl --system

# Install dependencies
sudo apt -y install docker.io

# Install containerd (the container runtime)
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Set up Kubernetes repositories
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Import Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
# Add Kubernetes repository
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull

# Initialize Kubernetes master
kubeadm init --pod-network-cidr=172.16.0.0/12 --apiserver-advertise-address=192.168.33.10

# Configure kubectl
export KUBECONFIG=/etc/kubernetes/admin.conf

# Apply Calico network plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Install Nginx Ingress Controller
cd /vagrant/kubernetes-ingress/deployments

# Create namespace and service account for the Ingress controller
kubectl apply -f common/ns-and-sa.yaml

# Create a cluster role and cluster role binding for the service account
kubectl apply -f rbac/rbac.yaml

# Create a default secret with a TLS certificate and a key for the default server in NGINX
kubectl apply -f ../examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/ingress-class.yaml

# Core custom resource definitions
kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml

# Deploy the Ingress controller
kubectl apply -f deployment/nginx-ingress.yaml

# Create a daemon set with the Ingress controller
kubectl apply -f daemon-set/nginx-ingress.yaml

# Save the join token to a file
sudo kubeadm token create --print-join-command > /vagrant/join-token.sh
sudo chmod +x /vagrant/join-token.sh

# Copy kubeconfig to vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown 1000:1000 /home/vagrant/.kube/config

# Install Helm
cd /vagrant
sudo bash ./get_helm.sh

# Setup complete
echo "Kubernetes master node setup completed."

# Add a cronjob to disable swap on boot
echo "@reboot sudo swapoff -a" >> /etc/crontab

# Add a cronjob to restart kubelet on boot
echo "@reboot sudo systemctl restart kubelet" >> /etc/crontab
