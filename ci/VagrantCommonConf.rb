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

  config.vm.synced_folder "../../", "/home/vagrant/ci"
  
  #localbuilder CI
  config.vm.provision  "install-redpesk-localbuilder", type: "file", source: "../../../install-redpesk-localbuilder.sh", destination: "/home/vagrant/"
  config.vm.provision  "test-localbuilder-script", type: "shell", path: "../../test_localbuilder.sh", upload_path: "/home/vagrant/test_localbuilder.sh", privileged: false
  
  #SDK CI
  config.vm.provision  "install-redpesk-sdk"      , type: "file", source: "../../../install-redpesk-sdk.sh" , destination: "/home/vagrant/"
  config.vm.provision  "test-sdk-script"          , type: "file", source: "../../test_SDK.sh"               , destination: "/home/vagrant/"
  config.vm.provision  "test-sdk-master-script"   , type: "shell", path: "../../test_SDK_master.sh"         , upload_path: "/home/vagrant/test_SDK_master.sh"   , privileged: false
  config.vm.provision  "test-sdk-next-script"     , type: "shell", path: "../../test_SDK_next.sh"           , upload_path: "/home/vagrant/test_SDK_next.sh"     , privileged: false
  config.vm.provision  "test-sdk-upstream-script" , type: "shell", path: "../../test_SDK_upstream.sh"       , upload_path: "/home/vagrant/test_SDK_upstream.sh" , privileged: false
  
end
