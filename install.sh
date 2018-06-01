#!/usr/bin/env bash
# install script for piPlex

KERNEL=$(uname -s)

function output() { echo -e "\033[32mpiPlex:\033[0m $@"; }

case $KERNEL in
  Linux) output "Let's start" ;;
  *)
    output "platform not supported by this install script"
    exit 1
    ;;
esac

output "Going to home folder"
cd ${HOME}

output "Upgrading Linux"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y clean
sudo apt-get -y install curl wget

output "Installing docker"
curl -SsL get.docker.com | sh

output "Add current user to docker group"
sudo usermod -aG docker $USER

output "Installing docker-compose"
sudo apt-get install python-pip
sudo pip install docker-compose

output "Installing ctop"
curl -SsL https://raw.githubusercontent.com/bcicen/ctop/master/install.sh | bash

output "Set variables to use on .tlp"


output "Downloading docker-compose template"
tlp_url="https://raw.githubusercontent.com/felipeconti/piPlex/master/docker-compose.yml.tlp"
wget -q --show-progress $tlp_url -O docker-compose.yml.tlp

output "Executing docker-compose template"
./docker-compose.yml.tlp > docker-compose.yml
rm docker-compose.yml.tlp

output "Running docker-compose"
docker-compose up -d docker-compose.yml