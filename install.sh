#!/bin/bash

# Author: Thierry Bultel (thierry.bultel@iot.bzh)
# License: Apache 2

set -e
set -o pipefail

IMAGE_STORE=download.redpesk.bzh
GREP=$(which grep)

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

	if [ $(lxc list -cn --format csv | $GREP -w "^"$1"$") ]; then
		read -p "Container $container exists and will be destroyed, are you sure ? (y/N)" choice
		if [ "x$choice" != "xy" ]; then exit
		fi

		echo "Stopping $container"
		lxc stop $1 --force > /dev/null 2>&1
		echo "Deleting $container"
		lxc delete $container --force > /dev/null 2>&1

	fi

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
		jq --version &> /dev/null || (echo "Installing jq" && sudo apt install jq)
	else
		lxc --version &> /dev/null || (echo "Installing lxd" && sudo apt install lxd)
		jq --version &> /dev/null || (echo "Installing jq" && sudo apt install jq)
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
		jq --version &> /dev/null || (echo "Installing jq" && sudo dnf install jq)
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
		jq --version &> /dev/null || (echo "Installing jq" && sudo zypper install jq)
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

function lxd_init {
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

}


if lxc network show lxdbr0 | grep -wq ipv4.address; then
	echo "LXD brigdge already setup, you are likely already owning another container. LXD will not be restarted."
else
	echo "1st configuration of lxd ..."
	lxd_init
fi

echo "Allow user ID remapping"

sudo echo "$USER:$(id -u):1" | sudo tee -a /etc/subuid /etc/subgid
sudo echo "root:100000:65536" | sudo tee -a /etc/subuid /etc/subgid
sudo echo "root:1000:1" | sudo tee -a /etc/subuid /etc/subgid

[[ `snap list | grep lxd` ]] && sudo snap restart lxd || sudo systemctl restart lxd

echo "Adding the LXD image store: '$IMAGE_STORE'"
lxc remote add iotbzh $IMAGE_STORE

profile_name=redpesk
reuse=0

while true;
do
	echo "Checking existing profiles ..."
	if lxc profile list | grep -qw $profile_name; then
		read -p "A '$profile_name' profile already exists, (R)euse or (C)reate another one ?" choice
		case $choice in
		R)
			reuse=1
			break
		;;
		C)
			read -p "Enter the profile name:" profile_name
			continue
		;;
		*) echo "bad choice";;
		esac
	else
		break
	fi
done

if [ $reuse -eq 1 ]; then
	echo "Reuse '$profile_name' LXD Profile"
else
	echo "Create a '$profile_name' LXD Profile"
	lxc profile create $profile_name
fi

lxc profile set $profile_name security.privileged true
lxc profile set $profile_name security.nesting true
lxc profile set $profile_name security.syscalls.blacklist "keyctl errno 38\nkeyctl_chown errno 38"

# Setup the LXC container

lxc launch iotbzh:redpesk-builder/33 $container -p default -p $profile_name

# Wait for ipv4 address to be available
while true;
do

	MY_IP_ADD_RES_TYPE=$(lxc ls $container --format json |jq -r '.
	[0].state.network.eth0.addresses[0].family')

	if [ $MY_IP_ADD_RES_TYPE != "inet" ] ; then
		echo 'waiting for IPv4 address'
		sleep 1
		continue
	fi

	MY_IP_ADD_RESS=$(lxc ls $container --format json |jq -r '.
	[0].state.network.eth0.addresses[0].address')

	echo "Got $MY_IP_ADD_RESS"

	break;
done

echo "Container $container operational. Remaining few last steps ..."

echo "Fixes the annoying missing suid bit on ping"

lxc exec ${container} chmod +s /usr/bin/ping

echo "Switches DNSSEC off"

lxc exec ${container} -- bash -c 'sed -i -e '\''/^DNSSEC/d'\''  /etc/systemd/resolved.conf'
lxc exec ${container} -- bash -c 'sed -i -e '\''$aDNSSEC=no'\'' /etc/systemd/resolved.conf'

echo "Mapping .ssh directory"
lxc config device add $container my_ssh disk source=~/.ssh path=/home/devel/.ssh

GREEN="\e[92m"
BOLD="\e[1m"
NORMAL="\e[0m"

echo -e "\nYou will have three repositories in your container (gitsources, gitpkgs, and build)
If you already have directories in your host, they will be mapped, just have to precise the path.
And if you don't have directories to map, they will be created by default under$BOLD$HOME/my_rp_builder_dir$NORMAL\n"

directory=$HOME/my_rp_builder_dir

gitsources_msg="applications sources you want to build"
gitpkgs_msg='gitpkgs (where is the specfile) to map'
build_msg='build (files generated by rpmbuild) to map'

for variable in "gitsources First ${gitsources_msg}" "gitpkgs Second ${gitpkgs_msg}" "build Third ${build_msg}"
do
	set -- $variable
	echo -e "$GREEN$2 directory: $1$NORMAL
Host directory with ${*:3}? It will be mapped under $BOLD$HOME/$1$NORMAL
in container ($BOLD$HOME/my_rp_builder_dir/$1$NORMAL by default):"
	read $1
done

gitsources=${gitsources:-${directory}/gitsources}
gitpkgs=${gitpkgs:-${directory}/gitpkgs}
build=${build:-${directory}/build}

for variable in gitsources gitpkgs build
do
    mkdir -p ${!variable}
	lxc config device add $container my_$variable disk source=${!variable} path=$HOME/${variable}
done
echo -e "Mapping of host directories to retrieve your files in the container"

lxc config set ${container} raw.idmap "$(echo -e "uid $(id -u) 1000\ngid $(id -g) 1000")"

lxc restart ${container}

echo "$MY_IP_ADD_RESS $container" | sudo tee -a /etc/hosts
echo "$MY_IP_ADD_RESS ${container}-$USER" | sudo tee -a /etc/hosts

ssh-keygen -f "$HOME/.ssh/known_hosts" -R ""$container""


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

