#!/bin/bash
###########################################################################
# Copyright (C) 2021 IoT.bzh
#
# Authors:   Ronan Le Martret <ronan.lemartret@iot.bzh>
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

function usage {
    printf "Usage: \n\
        %s DIR_PATH\t: vagrant directory\n\
        \n\
        -n|--no-clean\t: do not clean your vagrant VM before and after the test\n\
        -d|--debug\t: do not clean your vagrant VM before and after the test\n\
        \n\
        %s -h|--help\t\t\tdisplays this text\n" "$0" "$0"
    exit
}

GREEN="\e[92m"
RED="\e[31m"
BOLD="\e[1m"
NORMAL="\e[0m"

VAGRANT_OPT_LV1=("--no-color" "--no-tty")
VAGRANT_OPT_LV2=("${VAGRANT_OPT_LV1[@]}")
VAGRANT_OPT_LV2+=("--force")

VAG_CLEAN="YES"
DEBUG="NO"

while [[ $# -gt 0 ]];do
    key="$1"
    case $key in
    -n|--no-clean)
        VAG_CLEAN="NO";
        shift 1;
    ;;
    -d|--debug)
        DEBUG="YES";
        shift 1;
    ;;
    -h|--help)
        usage;
    ;;
    *)
        DIR_DIST="${1}"
        shift 1;
    ;;
    esac
done

function test_tool_bin {
    BIN2TEST="$1"
    BIN_PATH="$(which "${BIN2TEST}")"
    if [ -z "${BIN_PATH}" ]; then
        printf "${RED}${BOLD}ERROR${NORMAL}: The tool ${GREEN}%s${NORMAL} is missing\n" "${BIN2TEST}"
        printf "\tPlease install ${GREEN}%s${NORMAL} to run this test\n" "${BIN2TEST}"
        exit 1
    fi
}

function test_dir {
    DIR2TEST="$1"
    if [ -z "${DIR2TEST}" ]; then
        echo -e "${RED}${BOLD}ERROR${NORMAL}: directory parameter is missing\n"
        exit 1
    fi
    if [ ! -d "${DIR2TEST}" ]; then
        printf "${RED}${BOLD}ERROR${NORMAL}: parameter value ${GREEN}%s${NORMAL} is not a directory\n" "${DIR2TEST}"
        exit 1
    fi
}

if [ "${DEBUG}" == "YES" ]; then
    set -x
fi

test_dir "${DIR_DIST}"
test_tool_bin vagrant

cd "${DIR_DIST}" || exit 1

if [ "${VAG_CLEAN}" == "YES" ]; then
    # Clean old thinks
    vagrant halt      "${VAGRANT_OPT_LV2[@]}"
    vagrant destroy   "${VAGRANT_OPT_LV2[@]}"
fi

# Start and exec test
vagrant up        "${VAGRANT_OPT_LV1[@]}" --no-provision 
vagrant provision "${VAGRANT_OPT_LV1[@]}"

if [ "${VAG_CLEAN}" == "YES" ]; then
    # Clean before exit
    vagrant halt      "${VAGRANT_OPT_LV2[@]}"
    vagrant destroy   "${VAGRANT_OPT_LV2[@]}"
fi
