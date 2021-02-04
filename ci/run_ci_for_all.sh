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

GREEN="\e[92m"
RED="\e[31m"
BOLD="\e[1m"
NORMAL="\e[0m"

function test_tool_bin {
    BIN2TEST="$1"
    SCREEN="$(which "${BIN2TEST}")"
    if [ -z "${SCREEN}" ]; then
        printf "${RED}${BOLD}ERROR${NORMAL}: The tool ${GREEN}%s${NORMAL} is missing" "${BIN2TEST}"
        printf "\tPlease install ${GREEN}%s${NORMAL} to run this test" "${BIN2TEST}"
        exit 1
    fi
}

test_tool_bin screen

LIST_DISTRO="debian fedora opensuse ubuntu"
LOG_DIR="./ci_log/$(date +%Y-%m-%d_%H-%M)"

LOG_FILES=()

for DIST in ${LIST_DISTRO}; do
    for DIST_VER in "${DIST}"/* ;do
        LOG_FILE="${LOG_DIR}/run_log/${DIST_VER}.log"
        LOG_FILES+=("${LOG_FILE}")
        mkdir -p "$(dirname "${LOG_FILE}")"
        screen -Logfile "${LOG_FILE}" -L -m ./run_ci.sh "${DIST_VER}"
    done
done

./generate_ci_report.py "${LOG_FILES[@]}" --report-path "./report_$(date +%Y-%m-%d_%H-%M).log"
