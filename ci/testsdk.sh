#!/bin/bash

source /etc/os-release

declare -A listepath
listepath=(["/fedora/33/"]="http://repo.lorient.iot/redpesk/sdk/master/Fedora_33/latest/"
["/debian/10/"]="http://repo.lorient.iot/redpesk/sdk/master/Debian_10/latest/"
["/ubuntu/20.04/"]="http://repo.lorient.iot/redpesk/sdk/master/Ubuntu_20.04/latest/"
["/opensuse/15.2/"]="http://repo.lorient.iot/redpesk/sdk/master/openSUSE_Leap_15.2/latest/"
)

test() {
    #write the tests result in the xunit.xml file
    echo "<testcase classname='VMsdk.$ID.$VERSION_ID' file='VMsdk.sh' line='$3' name='$2_$ID.$VERSION_ID.$1'>" >> ./xml/xunit.xml
    if [ "$1" = "success" ]; then
        echo "</testcase>" >> ./xml/xunit.xml
    elif [ "$1" = "error" ]; then
        echo -e "<error>$4</error>\n</testcase>" >> ./xml/xunit.xml
        exitval=1
    elif [ "$1" = "skipped" ]; then
        echo -e "<skipped> $skip </skipped>\n</testcase>" >> ./xml/xunit.xml
    elif [ "$1" = "failure" ]; then
        echo -e "<failure/>\n</testcase>" >> ./xml/xunit.xml
        exitval=1
    fi
}

sdktest () {
    #install and test the SDK
    (( line=LINENO + 1 ))
    if ./install-redpesk-native.sh -r "${listepath[$1]}" ; then
        test "success" "test_native_install" "$line"
    else 
        test "error" "test_native_install" "$line"
    fi
    #install helloword-binding and helloword-binding-test
    case $ID in
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
            exit 1
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
                exitval=0
            fi
            if [ "$testskip" -ne "0" ]; then
                skip=$(grep "skipped" "test.log" | cut -d"," -f4)
                test "skipped" "test_afm-test-result" "$line"
            fi
        fi
    else 
        test "error" "test_afm-test" "$line"
    fi
    exit $exitval
}


echo "distribution: $PRETTY_NAME"
#detect the OS and launch the sdktest function
case $ID in
    ubuntu)
        case $VERSION_ID in
            20.04)
                sudo sed -i '17inameserver 10.16.2.10\ ' /etc/resolv.conf
                sdktest "/ubuntu/$VERSION_ID/"
                ;;
            *)
                error_message
                ;;
        esac
        ;;
    opensuse-leap)
        case $VERSION_ID in
            15.2)
                sdktest "/opensuse/$VERSION_ID/"
                ;;
            *)
                error_message
                ;;
        esac
        ;;
    fedora)
        case $VERSION_ID in
            33)
                sdktest "/fedora/$VERSION_ID/"
                ;;
            *)
                error_message
                ;;
        esac
        ;;
    debian)
        case $VERSION_ID in 
            10)
                sudo sed -i '3inameserver 10.16.2.10\ ' /etc/resolv.conf
                sdktest "/debian/$VERSION_ID/"
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