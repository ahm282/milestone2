    #!/bin/bash

set -e

# Disable swap
sudo swapoff -a
# sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Update and set hostname
sudo apt-get update
sudo hostnamectl set-hostname "k8s-node01"

# Load kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Update hosts file
echo "192.168.33.10 k8s-master" | sudo tee -a /etc/hosts

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

# run script in /vagrant/worker_script.sh
source /vagrant/join-token.sh

# Apply Calico network plugin
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Script complete
echo "Kubernetes worker node setup completed."
