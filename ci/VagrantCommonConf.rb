# -*- mode: ruby -*-
# vi: set ft=ruby :
#
Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
    vb.memory = "2048"
  end

  config.vm.synced_folder "../../xml/", "/home/vagrant/xml"
  config.vm.provision "file", source: "../../../install-redpesk-native.sh", destination: "/home/vagrant/"
  config.vm.provision "shell", path: "../../testsdk.sh", upload_path: "/home/vagrant/testsdk.sh", privileged: false
  
end
