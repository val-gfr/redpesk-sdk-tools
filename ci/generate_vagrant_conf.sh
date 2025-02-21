#!/bin/bash


declare -A listevagrant
listevagrant=(["./debian/11/Vagrantfile"]="generic/debian11"
["./fedora/36/Vagrantfile"]="generic/fedora36"
["./fedora/37/Vagrantfile"]="generic/fedora37"
["./opensuse-leap/15.3/Vagrantfile"]="opensuse/Leap-15.3.x86_64"
["./opensuse-leap/15.4/Vagrantfile"]="opensuse/Leap-15.4.x86_64"
["./ubuntu/20.04/Vagrantfile"]="generic/ubuntu2004"
["./ubuntu/22.04/Vagrantfile"]="generic/ubuntu2204"
)

rm -fr ubuntu opensuse-leap fedora debian

for path in "${!listevagrant[@]}"; do
    directory="$(dirname "$path")"
    rm -fr "$path"
    echo -e "\n$directory\n"
    mkdir -p "$directory"
    cd "$directory" || return 
    vagrant init "${listevagrant[$path]}"
    echo "require '../../VagrantCommonConf.rb'" >> Vagrantfile
    cd ../..
done