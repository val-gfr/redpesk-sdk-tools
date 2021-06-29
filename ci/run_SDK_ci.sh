#!/bin/bash

SUPPORTED_DISTROS="Ubuntu 20.04, OpenSUSE Leap 15.2, Fedora 33, Debian 10"

function usage {
    echo -e "Starts $SUPPORTED_DISTROS virtual machines, runs their configured provisionners and shuts them down\n
            -v | --vm-path <VMpath>:\t Start the VM contained in the VMpath, run its configured provisionners and shut it down\n
            -d | --destroy:\t Destroy the VM after being shut down\n
            -h | --help:\t Display help\n"
    exit
}

script_dir="$(dirname "$(readlink -f "$0")")"
RESULT_DST="${script_dir}/xml/xunit.xml"
mkdir -p "$(dirname "${RESULT_DST}")"

LISTPATH_DEFAULT="fedora/33/ debian/10/ ubuntu/20.04/ opensuse/15.2/"
LISTPATH=""
DESTROY_AFTER="n"

error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

#test arguments
while [[ $# -gt 0 ]]; do
    OPTION="$1"
    case $OPTION in
    -h | --help)
        usage;
    ;;
    -d | --destroy)
        DESTROY_AFTER="y"
        shift 1;
    ;;
    -v | --vm-path)
        LISTPATH="${LISTPATH} $2"
        shift 2;
    ;;
    *)
        usage;
    ;;
    esac
done

if [ -z "${LISTPATH}" ]; then
    LISTPATH="${LISTPATH_DEFAULT}"
fi

#function that runs all VMs from listepath
run_all_test(){
    #write at the beginning of the xunit.xml file
    touch "${RESULT_DST}"
    echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites>\n<testsuite>' > "${RESULT_DST}"
    for path in ${LISTPATH}; do
        run_one_test "${script_dir}/${path}"
    done
    echo -e '</testsuite>\n</testsuites>' >> "${RESULT_DST}"
}

run_one_test(){
    cd "$1" || exit
    vagrant up --no-provision
    vagrant provision --provision-with test-sdk-script,install-redpesk-native
    vagrant halt
    if [ "$DESTROY_AFTER" = "y" ]; then
        vagrant destroy -f
    fi
    cd ../..
}

run_all_test