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

SUPPORTED_DISTROS="Ubuntu 20.04, OpenSUSE Leap 15.2/15.3, Fedora 34/33"
REDPESK_REPO="https://download.redpesk.bzh/redpesk-lts/arz-1/sdk/"

function help {
    echo -e "Supported distributions : $SUPPORTED_DISTROS\n
            -r | --repository:\t redpesk sdk repository path\n
			-h | --help:\t Display help\n"
    exit
}

error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

echo "Detected distribution: $PRETTY_NAME"

while [[ $# -gt 0 ]]; do
	OPTION="$1"
	case $OPTION in
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
	*)
		printf " Unknown command\n
		try -h or --help\n "
		exit
	;;
	esac
done

case $ID in
	ubuntu)
		case $VERSION_ID in
			20.04)
				#Add redpesk repos
				sudo apt install -y wget add-apt-key gnupg
				#wget -O - "${REDPESK_REPO}"Release.key | sudo apt-key add - 
				sudo sh -c 'echo "deb [trusted=yes] '"${REDPESK_REPO}/Ubuntu_${VERSION_ID}"' ./" > /etc/apt/sources.list.d/redpesk-sdk.list'
				sudo apt-get update
				#Install base redpesk packages
				sudo apt install -y afb-binder afb-binding-dev afb-libhelpers-dev afb-cmake-modules afb-libcontroller-dev afb-ui-devtools afb-test-bin
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
				sudo zypper --non-interactive --gpg-auto-import-keys ref
				sudo zypper dup --non-interactive --from redpesk-sdk
				#Install base redpesk packages
				sudo zypper --no-gpg-checks install -y afb-binder afb-binding-devel afb-libhelpers-devel afb-cmake-modules afb-libcontroller-devel afb-ui-devtools afb-test
				;;
			*)
				error_message
				;;
		esac
		;;
	fedora)
		case $VERSION_ID in
			33 | 34)
				#Add redpesk repos
				sudo dnf install -y dnf-plugins-core
				sudo dnf config-manager --add-repo "${REDPESK_REPO}/Fedora_${VERSION_ID}"
				#Install base redpesk packages
				sudo dnf install -y --nogpgcheck afb-binder afb-binding-devel afb-libhelpers-devel afb-cmake-modules afb-libcontroller-devel afb-ui-devtools afb-test
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
				sudo sh -c 'echo "deb [trusted=yes] '"${REDPESK_REPO}/Debian_${VERSION_ID}"' ./" > /etc/apt/sources.list.d/redpesk-sdk.list'
				sudo apt-get update
				#Install base redpesk packages
				sudo apt-get install -y afb-binder afb-binding-dev afb-libhelpers-dev afb-cmake-modules afb-libcontroller-dev afb-ui-devtools afb-test-bin
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