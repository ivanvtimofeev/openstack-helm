#!/bin/bash

export OPENSTACK_RELEASE=train
export CONTAINER_DISTRO_NAME=ubuntu
export CONTAINER_DISTRO_VERSION=bionic

sudo apt update -y
sudo apt install -y python3-pip resolvconf

cd ~/openstack-helm

./tools/deployment/common/install-packages.sh
./tools/deployment/common/deploy-k8s.sh
