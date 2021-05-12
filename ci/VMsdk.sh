#!/bin/bash

SUPPORTED_DISTROS="Ubuntu 20.04, OpenSUSE Leap 15.2, Fedora 33, Debian 10"

function help {
    echo -e "Starts $SUPPORTED_DISTROS virtual machines, runs their configured provisionners and shuts them down\n
            <VMpath>:\t Start the VM contained in the VMpath, run its configured provisionners and shut it down\n
            -d | --destroy:\t Destroy the VM after being shut down\n
            -h | --help:\t Display help\n"
    exit
}

script_dir="$(dirname "$(readlink -f "$0")")"

exitval=0

listepath=("fedora/33/" "debian/10/" "ubuntu/20.04/" "opensuse/15.2/")



error_message () {
	echo "Your distribution, $PRETTY_NAME, is not supported. Supported distribution are $SUPPORTED_DISTROS. For more information, please check https://docs.redpesk.bzh/"
}

#function that runs all VMs from listepath
run_all(){
    for path in "${listepath[@]}";
    do
        cd "$script_dir/$path" || exit 1
        if ! vagrant up --provision; then
             exitval=1
        fi
        vagrant halt
        if [ "$OPTION" = "-d" ] || [ "$OPTION" = "--destroy" ]; then
            vagrant destroy -f
        fi
        cd ../..
    done
    echo -e '</testsuite>\n</testsuites>' >> ./xml/xunit.xml
    exit $exitval
}

#write at the beginning of the xunit.xml file
touch "$script_dir"/xml/xunit.xml
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites>\n<testsuite>' > "$script_dir"/xml/xunit.xml

#tests the presence of an argument
#runs all VM if no argument is detected
if [ $# -gt 0 ]; then

    #test arguments
    while [[ $# -gt 0 ]]; do
        OPTION="$1"
        case $OPTION in
        -h | --help)
            help;
        ;;
        -d | --destroy)
            if [[ -n $2 ]]; then
                vmpath="$2"
                shift 2;
            else
                run_all
            fi
        ;;
        *)
            vmpath="$1"
            shift 1;
        ;;
        esac
    done

    #running a single VM
    if [ ! -d "$vmpath" ]; then
        printf "%s$vmpath no such file or directory\n"
        exit 1
    fi

    cd "$vmpath" || exit 1
    if ! vagrant up --provision; then
        exitval=1
    fi
    vagrant halt
    if [ "$OPTION" = "-d" ] || [ "$OPTION" = "--destroy" ]; then
        vagrant destroy -f
    fi
    echo -e '</testsuite>\n</testsuites>' >> ../../xml/xunit.xml
    exit $exitval
else
    run_all
fi

    