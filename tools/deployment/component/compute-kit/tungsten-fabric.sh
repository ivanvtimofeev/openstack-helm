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

stages="prepare deploy wait"

function show_usage_tf(){
  cat <<EOF
To use this script pass a stage you need as a first argument:

  tungsten_fabric.sh <stage>

Possible stages are:
  'prepare' - prepared host to deploy Tungsten fabric:
    - add an tf.yaml file to libvirt/values_override
    - comment lines in compute_kit.sh which wait nova and neutron is working and run tests
    - check and add line to /etc/hosts file
  'deploy' - deploy Tungsten fabric:
    - download tf Helm charts
    - preapare tf config
    - deploy Tungsten fabric to Kubernetes
  'wait' - wait for tf and openstack pods are up and works properly:
    - wait for tf pods
    - wait for openstack opds
    - run couple of openstack commands and nova tests
EOF
}

# 'prepare' stage implementation
function prepare_tf(){
  echo Prepare tf
}

# 'deploy' stage implementation
function deploy_tf(){
  echo deploy tf
}

# 'wait' stage implementation
function wait_tf(){
  echo wait tf
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