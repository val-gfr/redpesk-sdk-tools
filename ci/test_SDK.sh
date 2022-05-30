#!/bin/bash
# shellcheck disable=SC1091
source /etc/os-release

declare -A listepath
listepath=(
["/fedora/35/"]="http://silo.redpesk.iot/redpesk/sdk/master/Fedora_35/latest/"
["/fedora/36/"]="http://silo.redpesk.iot/redpesk/sdk/master/Fedora_36/latest/"
["/debian/10/"]="http://silo.redpesk.iot/redpesk/sdk/master/Debian_10/latest/"
["/ubuntu/20.04/"]="http://silo.redpesk.iot/redpesk/sdk/master/Ubuntu_20.04/latest/"
["/opensuse-leap/15.2/"]="http://silo.redpesk.iot/redpesk/sdk/master/openSUSE_Leap_15.2/latest/"
["/opensuse-leap/15.3/"]="http://silo.redpesk.iot/redpesk/sdk/master/openSUSE_Leap_15.3/latest/"
)

RESULT_DST="/home/vagrant/ci/${ID}_${VERSION_ID}_xunit.xml"
mkdir -p "$(dirname "${RESULT_DST}")"

exitval=0

test() {
    #write the tests result in the xunit.xml file
    echo "<testcase classname='VMsdk.${ID}.${VERSION_ID}' file='VMsdk.sh' line='$3' name='$2_${ID}.${VERSION_ID}.$1'>" >> "${RESULT_DST}"
    if [ "$1" = "success" ]; then
        echo "</testcase>" >> "${RESULT_DST}"
    elif [ "$1" = "error" ]; then
        echo -e "<error>$4</error>\n</testcase>" >> "${RESULT_DST}"
        exitval=1
    elif [ "$1" = "skipped" ]; then
        echo -e "<skipped> $skip </skipped>\n</testcase>" >> "${RESULT_DST}"
    elif [ "$1" = "failure" ]; then
        echo -e "<failure/>\n</testcase>" >> "${RESULT_DST}"
        exitval=1
    fi
}

sdktest () {
    #install and test the SDK
    (( line=LINENO + 1 ))
    REPO_URL="${listepath[$1]}"
    if [ -z "${REPO_URL}" ]; then
        echo "No repo URL fort this distribution"
        return 1
    fi
    if ./install-redpesk-sdk.sh -r "${REPO_URL}" ; then
        test "success" "test_native_install" "$line"
    else 
        test "error" "test_native_install" "$line"
    fi
    #install helloword-binding and helloword-binding-test
    case ${ID} in
        ubuntu | debian)
            (( line=LINENO + 1 ))
            if sudo apt-get install helloworld-binding-bin helloworld-binding-test ;then
                test "success" "test_helloworld_binding" "$line"
            else
                test "error" "test_helloworld_binding" "$line"
            fi
        ;;
        opensuse-leap)
            (( line=LINENO + 1 ))
            if sudo zypper --no-gpg-checks install -y helloworld-binding helloworld-binding-test; then
                test "success" "test_helloworld_binding" "$line"
            else
                test "error" "test_helloworld_binding" "$line"
            fi
        ;;
        fedora)
            (( line=LINENO + 1 ))
            if sudo dnf install -y --nogpgcheck helloworld-binding helloworld-binding-test; then
                test "success" "test_helloworld_binding" "$line"
            else
                test "error" "test_helloworld_binding" "$line"
            fi
        ;;
        *)
            echo "error: distribution not supported"
            return 1
        ;;
    esac
    #test afm-test command
    (( line=LINENO + 1 ))
    if sudo afm-test /var/local/lib/afm/applications/helloworld-binding /var/local/lib/afm/applications/helloworld-binding-test ; then
        test "success" "test_afm-test" "$line"
        #test the afm-test command results
        if grep "ERROR:" "test.log"; then
            error=$(grep "ERROR:" "test.log" | cut -d">" -f2)
            test "error" "test_afm-test-result" "$line" "$error"
        else
            nofail=$(grep -c "0 failures" "test.log")
            testskip=$(grep -c "skipped" "test.log")
            if [ "$nofail" -eq "0" ] || [ "$nofail" -eq "1" ]; then
                test "failure" "test_afm-test-result" "$line"
            else 
                test "success" "test_afm-test-result" "$line"
            fi
            if [ "$testskip" -ne "0" ]; then
                skip=$(grep "skipped" "test.log" | cut -d"," -f4)
                test "skipped" "test_afm-test-result" "$line"
            fi
        fi
    else 
        test "error" "test_afm-test" "$line"
    fi
}

echo "distribution: $PRETTY_NAME"
#detect the OS and launch the sdktest function
case ${ID} in
    ubuntu)
        sudo sed -i '17inameserver 10.16.2.10\ ' /etc/resolv.conf
        ;;
    debian)
        sudo sed -i '3inameserver 10.16.2.10\ ' /etc/resolv.conf
        ;;
esac
echo -e '<?xml version="1.0" encoding="UTF-8"?>\n<testsuites>\n<testsuite>' > "${RESULT_DST}"
sdktest "/${ID}/${VERSION_ID}/"
echo -e '</testsuite>\n</testsuites>' >> "${RESULT_DST}"
exit "$exitval"
