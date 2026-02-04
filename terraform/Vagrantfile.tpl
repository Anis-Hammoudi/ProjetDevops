# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vm.box = "${box_image}"
  config.vm.box_check_update = false
  config.ssh.insert_key = false
  config.vm.boot_timeout = 600

  nodes = [
    { name: "manager", ip: "${manager_ip}" },
    { name: "worker1", ip: "${worker1_ip}" },
    { name: "worker2", ip: "${worker2_ip}" }
  ]

  nodes.each do |node|
    config.vm.define node[:name] do |n|
      n.vm.hostname = "swarm-#{node[:name]}"
      n.vm.network "private_network", ip: node[:ip]
      
      n.vm.provider "virtualbox" do |vb|
        vb.name = "swarm-#{node[:name]}"
        vb.memory = 1024
        vb.cpus = 1
        vb.linked_clone = true
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
      end

      n.vm.provision "shell", inline: "echo '#{node[:name]} ready'"
    end
  end

end
