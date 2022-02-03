#!/bin/bash
###########################################################################
# Copyright (C) 2020, 2021 IoT.bzh
#
# Authors:   Corentin Le Gall <corentin.legall@iot.bzh>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###########################################################################
# shellcheck disable=SC1091
source /etc/os-release

SUPPORTED_DISTROS="Ubuntu 20.04, OpenSUSE Leap 15.2/15.3, Fedora 34/35"
REDPESK_REPO="https://download.redpesk.bzh/redpesk-lts/arz-1/sdk/"

SPIKPACKINST="no";
INTERACTIVE="yes";

LIST_PACKAGE_DEB="afb-binder afb-binding-dev afb-libhelpers-dev afb-cmake-modules afb-libcontroller-dev afb-ui-devtools afb-test-bin afb-client redpesk-cli"
LIST_PACKAGE_RPM="afb-binder afb-binding-devel afb-libhelpers-devel afb-cmake-modules afb-libcontroller-devel afb-ui-devtools afb-test afb-client redpesk-cli"


function help {
    echo -e "Supported distributions : $SUPPORTED_DISTROS\n
			-c | --rp-cli:\t install rp-cli only\n
            -r | --repository:\t redpesk sdk repository path\n
			-h | --help:\t Display help\n
			-s| --skip-packages-install\n
			-a| --non-interactive\n"
    exit
}

error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

echo "Detected distribution: $PRETTY_NAME"

while [[ $# -gt 0 ]]; do
	OPTION="$1"
	case $OPTION in
	-c|--rp-cli)
		# Overwrite list to install
		LIST_PACKAGE_DEB="redpesk-cli"
		LIST_PACKAGE_RPM="redpesk-cli"
		shift;
	;;
	-r|--repository)
		if [[ -n $2 ]]; then
			REDPESK_REPO="$2";
			shift 2;
		else
			printf "command error: a repository was expected\n-r <repository>\n"
			exit;
		fi
	;;
	-h | --help)
		help;
	;;
	-s| --skip-packages-install)
        SPIKPACKINST="yes";
        shift;
	;;
    -a|--non-interactive)
        INTERACTIVE="no";
        shift;
    ;;
	*)
		printf " Unknown command\n
		try -h or --help\n "
		exit
	;;
	esac
done

REPO_CONF_FILE_NAME="redpesk-sdk"
REPO_CONF_FILE=""
case $ID in
	ubuntu)
		REPO_CONF_FILE="/etc/apt/sources.list.d/${REPO_CONF_FILE_NAME}.list"
		;;
	opensuse-leap)
		REPO_CONF_FILE="/etc/zypp/repos.d/${REPO_CONF_FILE_NAME}.repo"
		;;
	fedora)
		REPO_CONF_FILE="/etc/yum.repos.d/${REPO_CONF_FILE_NAME}.repo"
		;;
	debian)
		REPO_CONF_FILE="/etc/apt/sources.list.d/${REPO_CONF_FILE_NAME}.list"
		;;
	*)
		error_message
		;;
esac

WRITE_CONF="yes"

if [ -f "${REPO_CONF_FILE}" ]; then
	if [ "${INTERACTIVE}" == "yes" ]; then
		read -r -p "The conf file ${REPO_CONF_FILE} already exists and will be destroyed, keep it? [N/y]" choice
	fi
	if [ -z "${choice}" ]; then
		choice="n"
	fi
	if [ "x$choice" != "xn" ] && [ "x$choice" != "xN" ]; then
		WRITE_CONF="no"
	fi
fi

case $ID in
	ubuntu)
		case $VERSION_ID in
			20.04)
				#Add redpesk repos
				sudo apt install -y wget add-apt-key gnupg
				#wget -O - "${REDPESK_REPO}"Release.key | sudo apt-key add - 
				if [ "${WRITE_CONF}" == "yes" ]; then
					sudo sh -c 'echo "deb [trusted=yes] '"${REDPESK_REPO}/Ubuntu_${VERSION_ID}"' ./" > '"${REPO_CONF_FILE}"
				fi
				sudo apt-get update
				#Install base redpesk packages
				if [ "${SPIKPACKINST}" == "no" ]; then
					sudo apt install -y ${LIST_PACKAGE_DEB}
				fi
				;;
			*)
				error_message
				;;
		esac
		;;
	opensuse-leap)
		case $VERSION_ID in
			15.2 | 15.3)
				#Add redpesk repos
				sudo zypper ar -f "${REDPESK_REPO}/openSUSE_Leap_${VERSION_ID}" redpesk-sdk

				if [ "${WRITE_CONF}" == "yes" ]; then
				sudo tee "${REPO_CONF_FILE}" >/dev/null <<EOF
[redpesk-sdk]
name=redpesk-sdk
baseurl=${REDPESK_REPO}/openSUSE_Leap_${VERSION_ID}
enabled=1
gpgcheck=0
EOF
				fi
				sudo zypper --non-interactive --gpg-auto-import-keys ref
				sudo zypper --non-interactive  dup --from redpesk-sdk
				#Install base redpesk packages
				if [ "${SPIKPACKINST}" == "no" ]; then
					sudo zypper install -y ${LIST_PACKAGE_RPM}
				fi
				;;
			*)
				error_message
				;;
		esac
		;;
	fedora)
		case $VERSION_ID in
			34 | 35)
				#Add redpesk repos
				sudo dnf install -y dnf-plugins-core
				for OLD_REPO in /etc/yum.repos.d/download.redpesk.bzh_redpesk-lts_arz-1.0_sdk_Fedora_*.repo ;do
					if [ -f "${OLD_REPO}" ]; then
						if [ "${INTERACTIVE}" == "yes" ]; then
							read -r -p "An old conf file has been detected ${OLD_REPO}, remove it? [Y/n]" choice
						fi
						if [ -z "${choice}" ]; then
							choice="y"
						fi
						if [ "x$choice" != "xn" ] && [ "x$choice" != "xN" ]; then
							sudo rm -fr "${OLD_REPO}"
						fi
					fi
				done
				if [ "${WRITE_CONF}" == "yes" ]; then
					sudo tee "${REPO_CONF_FILE}" >/dev/null <<EOF
[redpesk-sdk]
name=redpesk-sdk
baseurl=${REDPESK_REPO}/Fedora_${VERSION_ID}
enabled=1
gpgcheck=0
EOF
				fi
				sudo dnf clean expire-cache
				#Install base redpesk packages
				if [ "${SPIKPACKINST}" == "no" ]; then
					sudo dnf install -y ${LIST_PACKAGE_RPM}
				fi
				;;
			*)
				error_message
				;;
		esac
		;;
	debian)
		case $VERSION_ID in
			10)
				#Add redpesk repos 
				if [ "${WRITE_CONF}" == "yes" ]; then
					sudo sh -c 'echo "deb [trusted=yes] '"${REDPESK_REPO}/Debian_${VERSION_ID}"' ./" > '"${REPO_CONF_FILE}"
				fi
				sudo apt-get update
				#Install base redpesk packages
				if [ "${SPIKPACKINST}" == "no" ]; then
					sudo apt-get install -y ${LIST_PACKAGE_DEB}
				fi
				;;
			*)
				error_message
				;;
		esac
		;;
	*)
		error_message
		;;
esac
