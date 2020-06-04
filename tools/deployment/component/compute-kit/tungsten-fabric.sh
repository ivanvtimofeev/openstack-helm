#!/bin/bash

#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
set -xe

stages="prepare deploy"
OSH_INFRA_PATH=${OSH_INFRA_PATH:="../openstack-helm-infra"}

function show_usage_tf(){
  cat <<EOF
To use this script pass a stage you need as a first argument:

  tungsten_fabric.sh <stage>

Possible stages are:

  'prepare' - prepared host to deploy Tungsten fabric:
    - add an tf.yaml file to libvirt/values_overrides
    - comment lines in compute_kit.sh which wait nova and neutron is working and run tests
    - check and add line to /etc/hosts file
    Run 'preapare' stage after install kubernetes and before run libvirt.sh and compute_kit.sh

  'deploy' - deploy Tungsten fabric:
    - download tf Helm charts
    - preapare tf config
    - deploy Tungsten fabric to Kubernetes
    - wait for tf pods
    - wait for openstack opds
    - run couple of openstack commands and nova tests
    Run 'deploy' stage after compute_kit.sh
EOF
}

# 'prepare' stage implementation
function prepare_tf(){
  # add an tf.yaml file to libvirt/values_overrides
  cat <<EOF > OSH_INFRA_PATH/libvirt/values_overrides/tf.yaml
network:
  backend:
    - tungstenfabric
dependencies:
  dynamic:
    targeted:
      tungstenfabric:
        libvirt:
          daemonset: []
conf:
  qemu:
    cgroup_device_acl: ["/dev/null", "/dev/full", "/dev/zero", "/dev/random", "/dev/urandom", "/dev/ptmx", "/dev/kvm", "/dev/kqemu", "/dev/rtc", "/dev/hpet", "/dev/net/tun"]
EOF

  # comment lines in compute_kit.sh which wait nova and neutron is working and run tests
  sed -i 's/^\.\/tools\/deployment\/common\/wait-for-pods.sh openstack/#\.\/tools\/deployment\/common\/wait-for-pods.sh openstack/' ./tools/deployment/component/compute-kit/compute-kit.sh
  sed -i 's/^openstack compute service list/#openstack compute service list/' ./tools/deployment/component/compute-kit/compute-kit.sh
  sed -i 's/^openstack hypervisor list/#openstack hypervisor list/' ./tools/deployment/component/compute-kit/compute-kit.sh
  sed -i 's/^openstack network agent list/#openstack network_agent list/' ./tools/deployment/component/compute-kit/compute-kit.sh
  sed -i 's/^helm test nova --timeout $timeout/#helm test nova --timeout $timeout/' ./tools/deployment/component/compute-kit/compute-kit.sh
  sed -i 's/^helm test neutron --timeout $timeout/#helm test neutron --timeout $timeout/' ./tools/deployment/component/compute-kit/compute-kit.sh

  # check and add a line to /etc/hosts file
  local phys_int=`ip route get 1 | grep -o 'dev.*' | awk '{print($2)}'`
  local node_ip=`ip addr show dev $phys_int | grep 'inet ' | awk '{print $2}' | head -n 1 | cut -d '/' -f 1`

  if ! cat /etc/hosts | grep "${node_ip}" ; then
    local tf_hostname=$(hostname)
    cat <<EOF | sudo tee -a /etc/hosts
${node_ip} ${tf_hostname}.cluster.local ${tf_hostname}
EOF
  fi

}

# 'deploy' stage implementation
function deploy_tf(){
  echo deploy tf
}


if [[ $# == 0 ]] ; then
  echo "ERROR: You have to pass some stage in this script"
  show_usage_tf
  exit 1
fi

if [[ ! $stages =~ .*${1}.* ]] ; then
  echo "ERROR: Not any valid stage has been found"
  show_usage_tf
  exit 1
fi

${1}_tf