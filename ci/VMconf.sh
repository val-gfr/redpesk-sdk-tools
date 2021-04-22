#!/bin/bash


declare -A listevagrant
listevagrant=(["./debian/10/Vagrantfile"]="generic/debian10"
["./fedora/32/Vagrantfile"]="generic/fedora32"
["./fedora/33/Vagrantfile"]="generic/fedora33"
["./opensuse/15.2/Vagrantfile"]="generic/opensuse15"
["./ubuntu/20.04/Vagrantfile"]="generic/ubuntu2004"
["./ubuntu/18.04/Vagrantfile"]="generic/ubuntu1804"
["./ubuntu/18.10/Vagrantfile"]="generic/ubuntu1810"
["./ubuntu/20.10/Vagrantfile"]="generic/ubuntu2010"
)

for path in "${!listevagrant[@]}"
do
    directory="$(dirname "$path")"
    rm "$path"
    echo -e "\n$directory\n"
    cd "$directory" || return && vagrant init "${listevagrant[$path]}"
    echo "require '../../VagrantCommonConf.rb'" >> Vagrantfile
    cd ../..
    grep "config.vm.box =" "$path" | cut -d'"' -f2
done