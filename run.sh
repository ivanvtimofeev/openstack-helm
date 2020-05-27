#!/bin/bash

export OPENSTACK_RELEASE=train
export CONTAINER_DISTRO_NAME=ubuntu
export CONTAINER_DISTRO_VERSION=bionic

sudo apt update -y
sudo apt install -y python3-pip resolvconf
sudo dpkg-reconfigure --force-all resolvconf

cd ~/openstack-helm

./tools/deployment/common/install-packages.sh
./tools/deployment/common/deploy-k8s.sh

dns_cluster_ip=`kubectl get svc kube-dns -n kube-system --no-headers -o custom-columns=":spec.clusterIP"`

echo "nameserver ${dns_cluster_ip}" | sudo tee -a /etc/resolvconf/resolv.conf.d/head > /dev/null

sudo resolvconf -u
