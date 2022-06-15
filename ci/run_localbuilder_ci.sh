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
        -v | --vm-path <VMpath>:\t Start the VM contained in the VMpath, run its configured provisionners and shut it down\n
        \n\
        -c|--clean\t: clean your vagrant VM before and after the test\n\
        -s | --destroy\t: destroy your vagrant VM before and after the test\n\
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

VAG_CLEAN="NO"
DESTROY_AFTER="NO"
DEBUG="NO"

script_dir="$(dirname "$(readlink -f "$0")")"
LOG_DIR="${script_dir}/ci_log/$(date +%Y-%m-%d_%H-%M)"

LISTPATH_DEFAULT="fedora/35 fedora/36 debian/10 ubuntu/20.04 ubuntu/22.04 opensuse-leap/15.3 opensuse-leap/15.4"
LISTPATH=""

while [[ $# -gt 0 ]];do
    key="$1"
    case $key in
    -c|--clean)
        VAG_CLEAN="NO";
        shift 1;
    ;;
    -s | --destroy)
        DESTROY_AFTER="YES"
        shift 1;
    ;;
    -d|--debug)
        DEBUG="YES";
        shift 1;
    ;;
    -v | --vm-path)
        LISTPATH="${LISTPATH} $2"
        shift 2;
    ;;
    -h|--help)
        usage;
    ;;
    *)
        usage;
    ;;
    esac
done

if [ -z "${LISTPATH}" ]; then
    LISTPATH="${LISTPATH_DEFAULT}"
fi

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

test_tool_bin vagrant
test_tool_bin screen

cd "${DIR_DIST}" || exit 1

run_all_test(){
    LOG_FILES=()
    for DIR_DIST in ${LISTPATH}; do
        test_dir "${DIR_DIST}"
        run_one_test "${DIR_DIST}"
    done
}

run_one_test(){
    DIST_VER="$1"
    cd "${DIST_VER}" || exit

    if [ "${VAG_CLEAN}" == "YES" ]; then
        vagrant halt      "${VAGRANT_OPT_LV2[@]}"
    fi

    if [ "$DESTROY_AFTER" = "YES" ]; then
        vagrant destroy "${VAGRANT_OPT_LV2[@]}"
    fi

    vagrant up          "${VAGRANT_OPT_LV1[@]}" --no-provision

    LOG_FILE="${LOG_DIR}/run_log/${DIST_VER}.log"
    mkdir -p "$(dirname "${LOG_FILE}")"
    LOG_FILES+=("${LOG_FILE}")
    
    screen -d -m -Logfile "${LOG_FILE}" -L -m vagrant provision "${VAGRANT_OPT_LV1[@]}" --provision-with install-redpesk-localbuilder,test-localbuilder-script

    if [ "${VAG_CLEAN}" == "YES" ]; then
        vagrant halt      "${VAGRANT_OPT_LV2[@]}"
    fi

    if [ "$DESTROY_AFTER" = "YES" ]; then
        vagrant destroy "${VAGRANT_OPT_LV2[@]}"
    fi
    cd ../..
}

run_all_test

./generate_ci_report.py "${LOG_FILES[@]}" --report-path "./report_$(date +%Y-%m-%d_%H-%M).log"