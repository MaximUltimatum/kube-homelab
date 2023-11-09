#!/bin/bash
################# LFD259:2023-02-28 s_02/k8scp-cilium.sh ################
# The code herein is: Copyright the Linux Foundation, 2023
#
# This Copyright is retained for the purpose of protecting free
# redistribution of source.
#
#     URL:    https://training.linuxfoundation.org
#     email:  info@linuxfoundation.org
#
# This code is distributed under Version 2 of the GNU General Public
# License, which you should have received with the source.
#Version 1.25.1
#
# This script is intended to be run on an Ubuntu 20.04, 
# 2cpu, 8G.
# By Tim Serewicz, 05/2022 GPL

# Note there is a lot of software downloaded, which may require
# some troubleshooting if any of the sites updates their code,
# which should be expected

# This version uses Cilium instead of Calico. Be aware exam still
# uses Calico, and not as much testing has happened with Cilium in class

# Check to see if the script has been run before. Exit out if so.
FILE=/k8scp_run
if [ -f "$FILE" ]; then
    echo "WARNING!"
    echo "$FILE exists. Script has already been run on control plane."
    echo 
    exit 1
else 
    echo "$FILE does not exist. Running  script"
fi


# Create a file when this script is started to keep it from running 
# twice on same node
sudo touch /k8scp_run

# Update the system
sudo apt update ; sudo apt upgrade -y

# Install necessary software
sudo apt install curl apt-transport-https vim git wget gnupg2 software-properties-common apt-transport-https ca-certificates -y

# Add repo for Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install the Kubernetes software, and lock the version 
sudo apt update
sudo apt -y install kubelet=1.25.1-00 kubeadm=1.25.1-00 kubectl=1.25.1-00
sudo apt-mark hold kubelet kubeadm kubectl

# Ensure Kubelet is running
sudo systemctl enable --now kubelet

# Disable swap just in case 
sudo swapoff -a

# Ensure Kernel has modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Update networking to allow traffic
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Configure containerd settings
￼
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf 
overlay
br_netfilter
EOF

sudo sysctl --system

# Install the containerd software
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install containerd.io -y

# Configure containerd and restart
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Configure the cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 

# Configure the non-root user to use kubectl
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Use Cilium as the network plugin
# Install the CLI first
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
export CLI_ARCH=amd64

# Ensure correct architecture
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Make sure download worked
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

# Move binary to correct location and remove tarball
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Now that binary is in place, install network plugin
echo '********************************************************'
echo '********************************************************'
echo
echo Installing Cilium, this may take a bit...
echo
echo '********************************************************'
echo '********************************************************'
echo

cilium install

echo
sleep 3
echo Cilium install finished. Continuing with script.
echo 


# Add Helm to make our life easier
wget https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz
tar -xf helm-v3.9.0-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin/


# Output the state of the cluster
kubectl get node

# Ready to continue
sleep 3
echo
echo
echo '***************************'
echo
echo "Continue to the next step"
echo
echo '***************************'
echo
