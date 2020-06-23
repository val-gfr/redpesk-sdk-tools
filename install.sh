#!/bin/bash

# Author: Thierry Bultel (thierry.bultel@iot.bzh)
# License: Apache 2

set -e
set -o pipefail

IMAGE_STORE=download.redpesk.bzh

function clean_subxid {
	for f in /etc/subuid /etc/subgid; do
		sudo sed -i -e "/^$USER:$(id -u):1/d" -e "/^root:100000:65536/d" -e "/^root:1000:1/d" $f
	done
}

function clean_hosts {
	container=$1
	sudo sed -i -e "/$container$/d" -e "/$container-$USER$/d" /etc/hosts
}

function clean {
	set +e

	ret=$(id -nG | grep -qw lxd > /dev/null 2>&1)
	if [ $? -ne 0 ];  then
		# Incomplete installation (or no installation at all) , do nothing
		return
	fi

	container=$1

	clean_subxid /dev/null 2>&1
	clean_hosts $container /dev/null 2>&1

	if [ $(lxc list -cn --format csv | grep $1) ]; then
		read -p "Container $container exists and will be destroyed, are you sure ? (y/N)" choice
		if [ "x$choice" != "xy" ]; then exit
		fi

		echo "Stopping $container"
		lxc stop $1 --force > /dev/null 2>&1
		echo "Deleting $container"
		lxc delete $container --force > /dev/null 2>&1

	fi

	echo "Delete redpesk profile"
	lxc profile delete redpesk > /dev/null 2>&1
	echo "Remove iotbzh image store"
	lxc remote remove iotbzh > /dev/null 2>&1
	echo "Clean done"
}


if [ "$(id -u)" == "0" ]; then
	echo "Some of the installation must not be run as root, please execute as normal user, you will prompted for root password when needed"
	exit
fi



function setup {
set -e

echo "This will install RedPesk localbuider on your machine"

container=$1

dist=$(cat /etc/os-release | grep ^ID= | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//' )

echo "Detected distro: $dist"

case $dist in
ubuntu)
	if id -nG | grep -qw lxd ; then
		echo "LXD already installed ..."
	else
		lxc --version &> /dev/null || echo "Installing lxd"; sudo apt install lxd
		jq --version &> /dev/null || echo "Installing jq"; sudo apt install jq
		sudo groupadd lxd || true
		sudo usermod -aG lxd $USER
		read -p "The session now needs to be restarted, all your processes are about to be killed, do it now (you have to restart the script after) (y/N) ?" choice
		if [ "x$choice" == "xy" ]; then
			ps aux | grep ^$USER | awk '{print $2}' | xargs kill -9
		fi
		# not reached
		exit
	fi
	;;

fedora)
	if id -nG | grep -qw lxd ; then
		echo "LXD already installed ..."
	else
		sudo dnf remove lxc
		# Now install LXD
		sudo dnf copr enable ganto/lxc3
		sudo dnf install lxc lxd jq
		sudo systemctl enable --now lxc lxd
		sudo usermod -aG lxd $USER
		sudo sed -i -e 's:systemd.unified_cgroup_hierarchy=0 ::' -e 's:rhgb:systemd.unified_cgroup_hierarchy=0 rhgb:' grub /etc/default/grub
		sudo grub2-mkconfig -o /etc/grub2.cfg
		echo "Please reboot, then restart the script"
		exit
	fi
	;;

opensuse-leap)

	read -p "Support of opensuse is currently EXPERIMENTAL and you may encounter problems, are you sure to continue (y/N)?" choice
	if [ "x$choice" != "xy" ]; then exit
	fi

	if id -nG | grep -qw lxd ; then
		echo "LXD already installed ..."
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
		sudo usermod -aG lxd $USER
		echo "Please close your session and open a new one, then restart the script"
		exit
	fi
	;;
*)
	echo "$dist is not a supported distribution!"
	exit 1
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

echo "Allow user ID remapping"

sudo echo "$USER:$(id -u):1" | sudo tee -a /etc/subuid /etc/subgid
sudo echo "root:100000:65536" | sudo tee -a /etc/subuid /etc/subgid
sudo echo "root:1000:1" | sudo tee -a /etc/subuid /etc/subgid


if [ "$(which lxd)" == "/usr/bin/lxd" ]; then
	sudo systemctl restart lxd
else
	sudo snap restart lxd
fi

echo "Adding the LXD image store: '$IMAGE_STORE'"
lxc remote add iotbzh $IMAGE_STORE

echo "Create a RedPesk LXD Profile"

# Created only once
lxc profile create redpesk

lxc profile set redpesk security.nesting true
lxc profile set redpesk security.syscalls.blacklist "keyctl errno 38\nkeyctl_chown errno 38"

# Setup the LXC container


lxc launch iotbzh:redpesk-builder/28 $container -p default -p redpesk

# Wait for ipv4 address to be available
while true;
do

	MY_IP_ADD_RES_TYPE=$(lxc ls --format json |jq -r '.
	[0].state.network.eth0.addresses[0].family')

	if [ $MY_IP_ADD_RES_TYPE != "inet" ] ; then
		echo 'waiting for IPv4 address'
		sleep 1
		continue
	fi

	MY_IP_ADD_RESS=$(lxc ls --format json |jq -r '.
	[0].state.network.eth0.addresses[0].address')

	echo "Got $MY_IP_ADD_RESS"

	break;
done

echo "Container $container operational. Remaining few last steps ..."

echo "Mapping .ssh directory"
lxc config device add $container my_ssh disk source=~/.ssh path=/home/devel/.ssh

read -p "Extra host directory to map? It will be mapped under /home/devel/<my_dir> \
in container (Just hit enter for doing nothing)" directory

if [ "x$directory" != "x" ]; then
	lxc config device add ${container} my_dir disk source=$directory path=/home/devel/$(basename $directory)
fi

lxc config set ${container} raw.idmap "$(echo -e "uid $(id -u) 1000\ngid $(id -g) 1000")"

lxc restart ${container}

echo "$MY_IP_ADD_RESS $container" | sudo tee -a /etc/hosts
echo "$MY_IP_ADD_RESS ${container}-$USER" | sudo tee -a /etc/hosts

echo "Container "$container \($MY_IP_ADD_RESS\)" successfully created ! \
You can log in it with 'ssh devel@$container'"

}


function usage {
	printf "Usage: \n\
		$1 create <container_name>\tcreates container\n\
		$1 clean <container_name>\tdeletes container and cleans things up\n\
		$1 help\t\t\tdisplays this text\n"
}

##########


case $1 in
help)
	usage $0
	;;
clean)
	if [ -z "$2" ]; then
		echo "Please specify a container name (eg: 'redpesk-builder')"
		usage $0
		exit
	fi
	clean $2
	;;
create)
	clean $2
	setup $2
	;;
*)
	usage $0
	;;
esac

