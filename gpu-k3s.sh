#!/bin/bash
if lspci | grep -q NVIDIA; then
echo "Install NVIDIA"
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | tee /etc/apt/sources.list.d/libnvidia-container.list
apt-get update
ubuntu-drivers install --gpgpu
DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-cuda-toolkit nvidia-container-toolkit nvidia-container-runtime ubuntu-drivers-commons
DEBIAN_FRONTEND=noninteractive apt-get install -y cuda-drivers-fabricmanager-525
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
fi
