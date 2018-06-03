#!/usr/bin/env bash
set -e

# install script for piPlex

HOSTNAME=`hostname`
TZ="America/Sao_Paulo"
ADVERTISE_IP="http://`hostname`:8080/"
PLEX_CLAIM=""
PGID=0
PUID=0
MEDIA="/media/hd"

DNS_UPDATER=false

DNS_API_KEY="xxxxxxxxxx"
DNS_DOMAIN_NAME="example.com"
DNS_RECORD_TYPE="A"
DNS_RECORD_NAME=`hostname`
DNS_INTERVAL=60
#Use network mode with eth0 to get local ip address
DNS_NETWORK_MODE=
DNS_LOCAL_INTERFACE=

KERNEL=$(uname -s)
CURRENT_USER=$(whoami)
HOME_USER=$HOME

output() { echo -e "\033[32mpiPlex:\033[0m $@"; }

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

case $KERNEL in
  Linux) output "Let's start" ;;
  *)
    output "platform not supported by this install script"
    exit 1
    ;;
esac

sh_c='sh -c'
if [ "$CURRENT_USER" != 'root' ]; then
  if command_exists sudo; then
    sh_c='sudo -E sh -c'
  elif command_exists su; then
    sh_c='su -c'
  else
    output "Error: this installer needs the ability to run commands as root. We are unable to find either "sudo" or "su" available to make this happen."
    exit 1
  fi
fi

output "Upgrade Linux"
set -x
$sh_c "apt-get update -qq >/dev/null"
$sh_c "apt-get -y upgrade -qq >/dev/null"
$sh_c "apt-get -y dist-upgrade -qq >/dev/null"
$sh_c "apt-get -y autoremove -qq >/dev/null"
$sh_c "apt-get -y clean -qq >/dev/null"
$sh_c "apt-get -y --no-install-recommends install apt-transport-https ca-certificates curl wget -qq >/dev/null"
set +x

output "Install/Upgrade docker"
curl -SsL get.docker.com | sh

if [ "$CURRENT_USER" != 'root' ]; then
  output "Add current user to docker group"
  set -x
  $sh_c "usermod -aG docker "$CURRENT_USER
  set +x
fi

output "Install/Upgrade docker-compose"
if ! command_exists pip; then
  set -x
  $sh_c "apt-get -y install python-pip -qq >/dev/null"
  set +x
fi
# if ! command_exists docker-compose; then
  set -x
  $sh_c "pip install docker-compose >/dev/null"
  set +x
# fi

output "Install/Upgrade ctop"
$sh_c "curl -SsL https://raw.githubusercontent.com/bcicen/ctop/master/install.sh | bash"

if [ ! -f $HOME_USER/docker-compose.yml ]
then
  output "Set variables to use on docker-compose template"
  # echo "Name: "$name
  echo -n "Hostname (Default: $HOSTNAME):"
  read HOSTNAME
  echo -n "TZ (Default: $TZ):"
  read TZ
  echo -n "ADVERTISE_IP (Default: $ADVERTISE_IP):"
  read ADVERTISE_IP
  echo -n "PLEX_CLAIM (Default: $PLEX_CLAIM):"
  read PLEX_CLAIM
  echo -n "PGID (Default: $PGID):"
  read PGID
  echo -n "PUID (Default: $PUID):"
  read PUID
  echo -n "MEDIA (Default: $MEDIA):"
  read MEDIA

  echo -n "DNS_UPDATER (Default: $DNS_UPDATER):"
  read DNS_UPDATER

  echo -n "DNS_API_KEY (Default: $DNS_API_KEY):"
  read DNS_API_KEY
  echo -n "DNS_DOMAIN_NAME (Default: $DNS_DOMAIN_NAME):"
  read DNS_DOMAIN_NAME
  echo -n "DNS_RECORD_TYPE (Default: $DNS_RECORD_TYPE):"
  read DNS_RECORD_TYPE
  echo -n "DNS_RECORD_NAME (Default: $DNS_RECORD_NAME):"
  read DNS_RECORD_NAME
  echo -n "DNS_INTERVAL (Default: $DNS_INTERVAL):"
  read DNS_INTERVAL
  #Use network mode with eth0 to get local ip address
  echo -n "DNS_NETWORK_MODE (Default: $DNS_NETWORK_MODE):"
  read DNS_NETWORK_MODE
  echo -n "DNS_LOCAL_INTERFACE (Default: $DNS_LOCAL_INTERFACE):"
  read DNS_LOCAL_INTERFACE

  output "Download docker-compose template"
  tlp_url="https://raw.githubusercontent.com/felipeconti/piPlex/master/docker-compose.yml.tlp"
  # $sh_c "curl -fsSL $tlp_url -o $HOME_USER/docker-compose.yml.tlp"
  $sh_c "wget -q --show-progress $tlp_url -O $HOME_USER/docker-compose.yml.tlp"

  output "Execute docker-compose template"
  set -x
  $sh_c "chmod +x $HOME_USER/docker-compose.yml.tlp"
  $sh_c "$HOME_USER/docker-compose.yml.tlp > $HOME_USER/docker-compose.yml"
  $sh_c "rm $HOME_USER/docker-compose.yml.tlp"
  $sh_c "chown $CURRENT_USER:$CURRENT_USER $HOME_USER/docker-compose.yml"
  set +x

  output ""
  output ""
  output "Advertise addres: $ADVERTISE_IP"
  output ""
  output "Don't forget to mount the media at $MEDIA"
fi

output ""
output "Ports for running services"
output "Plex: 8080"
output "Transmission: 9191 (web) and 51413 (peer)"
output ""
output "To execute the compose, run:"
output "docker-compose up -d $HOME_USER/docker-compose.yml"
output ""
output ""
output "Enjoy!"