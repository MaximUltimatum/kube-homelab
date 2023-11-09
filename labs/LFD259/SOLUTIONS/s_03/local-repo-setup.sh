#!/bin/bash
################# LFD259:2023-02-28 s_03/local-repo-setup.sh ################
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
# FRK - Local Repo Setup - v1.0.0

# podman installation
echo "Configuring local repo, Please standby"
sleep 2
curl -fsSL -o podman-linux-amd64.tar.gz https://github.com/mgoltzsche/podman-static/releases/latest/download/podman-linux-amd64.tar.gz
tar -xf podman-linux-amd64.tar.gz
sudo cp -r podman-linux-amd64/usr podman-linux-amd64/etc /

# configure the local repo
sudo mkdir -p /etc/containers/registries.conf.d
sudo cat << EOF | sudo tee /etc/containers/registries.conf.d/registry.conf
[[registry]]
location = "10.97.40.62:5000"
insecure = true
EOF

sudo cat << EOF | sudo tee -a /etc/containerd/config.toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."*"]
endpoint = ["http://10.97.40.62:5000"]
EOF

# restart containerd
sudo systemctl daemon-reload
sudo systemctl restart containerd

export repo=10.97.40.62:5000
export repo=10.97.40.62:5000 >> $HOME/.bashrc

sleep 4
echo ""

echo "Local Repo configured, follow the next steps"
