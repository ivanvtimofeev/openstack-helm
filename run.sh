#!/bin/bash

export OPENSTACK_RELEASE=train
export CONTAINER_DISTRO_NAME=ubuntu
export CONTAINER_DISTRO_VERSION=bionic

sudo apt update -y
sudo apt install -y python3-pip resolvconf

cd ~/openstack-helm

./tools/deployment/common/install-packages.sh
./tools/deployment/common/deploy-k8s.sh

dns_cluster_ip=`kubectl get svc kube-dns -n kube-system --no-headers -o custom-columns=":spec.clusterIP"`

echo "nameserver ${dns_cluster_ip}" | sudo tee -a /etc/resolvconf/resolv.conf.d/head > /dev/null
sudo dpkg-reconfigure --force resolvconf
sudo systemctl restart resolvconf

./tools/deployment/common/setup-client.sh
./tools/deployment/component/common/ingress.sh
./tools/deployment/component/common/mariadb.sh
./tools/deployment/component/common/memcached.sh
./tools/deployment/component/common/rabbitmq.sh
./tools/deployment/component/nfs-provisioner/nfs-provisioner.sh
./tools/deployment/component/keystone/keystone.sh
./tools/deployment/component/heat/heat.sh
./tools/deployment/component/glance/glance.sh
./tools/deployment/component/compute-kit/libvirt.sh
sed -i 's/^\.\/tools\/deployment\/common\/wait-for-pods.sh openstack/#\.\/tools\/deployment\/common\/wait-for-pods.sh openstack/' ./tools/deployment/component/compute-kit/compute-kit.sh
sed -i 's/^openstack compute service list/#openstack compute service list/' ./tools/deployment/component/compute-kit/compute-kit.sh
sed -i 's/^openstack hypervisor list/#openstack hypervisor list/' ./tools/deployment/component/compute-kit/compute-kit.sh
sed -i 's/^openstack network agent list/#openstack network_agent list/' ./tools/deployment/component/compute-kit/compute-kit.sh
sed -i 's/^helm test nova --timeout $timeout/#helm test nova --timeout $timeout/' ./tools/deployment/component/compute-kit/compute-kit.sh
sed -i 's/^helm test neutron --timeout $timeout/#helm test neutron --timeout $timeout/' ./tools/deployment/component/compute-kit/compute-kit.sh
./tools/deployment/component/compute-kit/compute-kit.sh


PHYS_INT=`ip route get 1 | grep -o 'dev.*' | awk '{print($2)}'`
NODE_IP=`ip addr show dev $PHYS_INT | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d '/' -f 1`
export CONTROLLER_NODES="${CONTROLLER_NODES:-$NODE_IP}"
export AGENT_NODE="${AGENT_NODES:-$NODE_IP}"

cd
sudo docker create --name tf-helm-deployer-src --entrypoint /bin/true tungstenfabric/tf-helm-deployer-src:latest
sudo docker cp tf-helm-deployer-src:/src ~/tf-helm-deployer
sudo docker rm -fv tf-helm-deployer-src

cd ~/tf-helm-deployer
helm repo add local http://localhost:8879/charts
sudo make all

cat <<EOF > ~/tf-devstack-values.yaml 
global:
  contrail_env:
    CONTAINER_REGISTRY: tungstenfabric
    CONTRAIL_CONTAINER_TAG: latest
    CONTROLLER_NODES: ${CONTROLLER_NODES}
    JVM_EXTRA_OPTS: "-Xms1g -Xmx2g"
    BGP_PORT: "1179"
    CONFIG_DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
    DATABASE_NODEMGR__DEFAULTS__minimum_diskGB: "2"
    LOG_LEVEL: SYS_DEBUG
    VROUTER_ENCRYPTION: FALSE
    ANALYTICS_ALARM_ENABLE: TRUE
    ANALYTICS_SNMP_ENABLE: TRUE
    ANALYTICSDB_ENABLE: TRUE
    CLOUD_ORCHESTRATOR: openstack
  node:
    host_os: ubuntu
EOF

sudo mkdir -p /var/log/contrail
kubectl create ns tungsten-fabric
helm upgrade --install --namespace tungsten-fabric tungsten-fabric ~/tf-helm-deployer/contrail -f ~/tf-devstack-values.yaml
kubectl label nodes --all opencontrail.org/vrouter-kernel=enabled
sleep 30
kubectl label nodes --all openstack-control-plane=enabled
