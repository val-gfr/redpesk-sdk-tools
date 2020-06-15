#!/bin/bash

set -e

set -x

if [ "$(id -u)" == "0" ]
  then echo "Some of the installation must not be run as root, please execute as normal user, you will prompted for root password when needed"; exit
fi

IMAGE_STORE=download.redpesk.bzh

echo "This will install RedPesk localbuider on your machine"

dist=$(cat /etc/os-release | grep -w NAME= | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//' )

echo "Detected distro: $dist"

case $dist in
Ubuntu)
	echo "Installing LXD ..."
	sudo apt install lxd jq
	;;
Fedora)
	if [ "$id -nG " | grep -qw lxd ]; then
		echo "LXD already installed ..."
	else
		sudo dnf remove lxc
		# Now install LXD
		sudo dnf copr enable ganto/lxc3
		sudo dnf install lxc lxd jq
		sudo systemctl enable --now lxc lxd
		sudo usermod -aG lxd ${USER}
		echo "Please close your session and open a new one, and restart the script"
		exit
	fi
	;;
"openSUSE Leap")

	if [ "$id -nG " | grep -qw lxd ]; then
		sudo systemctl start snapd
		sudo snap refresh
		sudo snap install lxd
	else
		sudo zypper addrepo --refresh https://download.opensuse.org/repositories/system:/snappy/openSUSE_Leap_15.1 snappy
		sudo zypper –gpg-auto-import-keys refresh
		sudo zypper dup –from snappy
		sudo zypper install snapd
		sudo zypper install jq
		sudo systemctl enable snapd
		sudo usermod -aG lxd ${USER}

		echo "Please close your session and open a new one, and restart the script"
		exit
	fi
	;;
*)
	echo "$dist in not supported"
	;;
esac


echo "Configuration of lxd ..."

cat << EOF | lxd init --preseed
config:
  images.auto_update_interval: "0"
networks:
- config:
    ipv4.address: auto
    ipv6.address: none
  description: ""
  managed: false
  name: lxdbr0
  type: ""
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF

echo "Allow user ID remap"

sudo echo "root:$(id -u):1" | sudo tee -a /etc/subuid /etc/subgid

echo "Add LXD image store: '$IMAGE_STORE'"
lxc remote add iotbzh $IMAGE_STORE

echo "Create a RedPesk LXD Profile"

# Created only once
lxc profile create redpesk

# Add /dev/loop-control device to support mock 2.x
lxc profile device add redpesk loop-control unix-char path=/dev/loop-control
lxc profile set redpesk security.nesting true
lxc profile set redpesk security.syscalls.blacklist "keyctl errno 38\nkeyctl_chown errno 38"

# Setup the LXC container

read -p "Please enter a name for you container (or press enter for keeping it as 'redpesk-builder')" container_name

if [ "x$container_name" = "x" ]; then
	export container_name=redpesk-builder
fi

lxc launch iotbzh:redpesk-builder/28 ${container_name} -p default -p redpesk

MY_IP_ADD_RESS=$(lxc ls --format json |jq -r '.
[0].state.network.eth0.addresses[0].address')
echo "${MY_IP_ADD_RESS} ${container_name}" | sudo tee -a /etc/hosts
echo "${MY_IP_ADD_RESS} ${container_name}-$USER" | sudo tee -a /etc/hosts

echo "Container "$container_name" successfully created ! You can log in it with 'ssh devel@$container_name'"



