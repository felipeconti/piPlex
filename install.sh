#!/usr/bin/env bash
set -e

# install script for piPlex

export HOSTNAME=`hostname`
export TZ="America/Sao_Paulo"
export ADVERTISE_IP="http://`hostname`:8080/"
export PLEX_CLAIM=""
export PGID=0
export PUID=0
export MEDIA="/media/hd"

export DNS_UPDATER=false

export DNS_API_KEY="xxxxxxxxxx"
export DNS_DOMAIN_NAME="example.com"
export DNS_RECORD_TYPE="A"
export DNS_RECORD_NAME=`hostname`
export DNS_INTERVAL=60
#Use network mode with eth0 to get local ip address
export DNS_NETWORK_MODE=
export DNS_LOCAL_INTERFACE=

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
$sh_c "curl -SsL https://raw.githubusercontent.com/felipeconti/ctop/master/install.sh | bash"

if [ ! -f $HOME_USER/docker-compose.yml ]
then
  output "Set variables to use on docker-compose template"

  read -p "Hostname (Default: $HOSTNAME): " AUX
  HOSTNAME=${AUX:-$HOSTNAME}
  read -p "TZ (Default: $TZ): " AUX
  TZ=${AUX:-$TZ}
  read -p "ADVERTISE_IP (Default: $ADVERTISE_IP): " AUX
  ADVERTISE_IP=${AUX:-$ADVERTISE_IP}
  read -p "PLEX_CLAIM (Default: $PLEX_CLAIM): " AUX
  PLEX_CLAIM=${AUX:-$PLEX_CLAIM}
  read -p "PGID (Default: $PGID): " AUX
  PGID=${AUX:-$PGID}
  read -p "PUID (Default: $PUID): " AUX
  PUID=${AUX:-$PUID}
  read -p "MEDIA (Default: $MEDIA): " AUX
  MEDIA=${AUX:-$MEDIA}

  read -p "DNS_UPDATER (Default: $DNS_UPDATER): " AUX
  DNS_UPDATER=${AUX:-$DNS_UPDATER}

  if [ $DNS_UPDATER == true ]
  then
    read -p "DNS_API_KEY (Default: $DNS_API_KEY): " AUX
    DNS_API_KEY=${AUX:-$DNS_API_KEY}
    read -p "DNS_DOMAIN_NAME (Default: $DNS_DOMAIN_NAME): " AUX
    DNS_DOMAIN_NAME=${AUX:-$DNS_DOMAIN_NAME}
    read -p "DNS_RECORD_TYPE (Default: $DNS_RECORD_TYPE): " AUX
    DNS_RECORD_TYPE=${AUX:-$DNS_RECORD_TYPE}
    read -p "DNS_RECORD_NAME (Default: $DNS_RECORD_NAME): " AUX
    DNS_RECORD_NAME=${AUX:-$DNS_RECORD_NAME}
    read -p "DNS_INTERVAL (Default: $DNS_INTERVAL): " AUX
    DNS_INTERVAL=${AUX:-$DNS_INTERVAL}
    #Use network mode with eth0 to get local ip address
    read -p "DNS_NETWORK_MODE (Default: $DNS_NETWORK_MODE): " AUX
    DNS_NETWORK_MODE=${AUX:-$DNS_NETWORK_MODE}
    read -p "DNS_LOCAL_INTERFACE (Default: $DNS_LOCAL_INTERFACE): " AUX
    DNS_LOCAL_INTERFACE=${AUX:-$DNS_LOCAL_INTERFACE}
  fi

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
output "Execute pull of images"
$sh_c "docker-compose pull"

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
