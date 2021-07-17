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

SUPPORTED_DISTROS="Ubuntu 20.04, OpenSUSE Leap 15.2/15.3, Fedora 33/32/31"
REDPESK_REPO="https://download.redpesk.bzh/redpesk-devel/releases/33/sdk/"
source /etc/os-release
echo "Detected distribution: $PRETTY_NAME"

error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

case $ID in
	ubuntu)
		case $VERSION_ID in
			20.04)
				#Add redpesk repos
				sudo apt install -y wget add-apt-key gnupg
				wget -O - ${REDPESK_REPO}xUbuntu_20.04/Release.key | sudo apt-key add -
				sudo sh -c 'echo "deb '${REDPESK_REPO}'xUbuntu_20.04/ ./" > /etc/apt/sources.list.d/redpesk-sdk.list'
				sudo apt-get update
				#Install base redpesk packages
				sudo apt install -y afb-binder afb-binding-dev afb-libhelpers-dev afb-cmake-modules afb-libcontroller-dev afb-ui-devtools
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
				sudo zypper ar -f -r ${REDPESK_REPO}redpesk-sdk_suse.repo redpesk-sdk
				sudo zypper --gpg-auto-import-keys ref
				sudo zypper dup --from redpesk-sdk
				#Install base redpesk packages
				sudo zypper install -y afb-binder afb-binding-devel afb-libhelpers-devel afb-cmake-modules afb-libcontroller-devel afb-ui-devtools
				;;
			*)
				error_message
				;;
		esac
		;;
	fedora)
		case $VERSION_ID in
			31 | 32 | 33)
                        	#Add redpesk repos
				sudo dnf install -y dnf-plugins-core
				sudo dnf config-manager --add-repo ${REDPESK_REPO}redpesk-sdk_fedora.repo
				#Install base redpesk packages
				sudo dnf install -y afb-binder afb-binding-devel afb-libhelpers-devel afb-cmake-modules afb-libcontroller-devel afb-ui-devtools
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

