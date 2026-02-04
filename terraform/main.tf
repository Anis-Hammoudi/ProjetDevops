# Terraform configuration for local VM provisioning using Vagrant
# This creates 3 VMs: 1 Swarm Manager + 2 Swarm Workers

terraform {
  required_version = ">= 1.0.0"
}

# Generate Vagrantfile from template
resource "local_file" "vagrantfile" {
  content = templatefile("${path.module}/Vagrantfile.tpl", {
    manager_ip     = var.manager_ip
    worker1_ip     = var.worker1_ip
    worker2_ip     = var.worker2_ip
    vm_memory      = var.vm_memory
    vm_cpus        = var.vm_cpus
    box_image      = var.box_image
    ssh_public_key = var.ssh_public_key
  })
  filename = "${path.module}/Vagrantfile"
}

# Provision VMs using Vagrant
resource "null_resource" "vagrant_up" {
  depends_on = [local_file.vagrantfile]

  provisioner "local-exec" {
    command     = "vagrant up"
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "vagrant destroy -f"
    working_dir = path.module
  }

  triggers = {
    vagrantfile_hash = local_file.vagrantfile.content_md5
  }
}

# Wait for VMs to be ready
resource "null_resource" "wait_for_vms" {
  depends_on = [null_resource.vagrant_up]

  provisioner "local-exec" {
    command = "ping -n 10 127.0.0.1 > nul"
  }
}

# Generate Ansible inventory file
resource "local_file" "ansible_inventory" {
  depends_on = [null_resource.wait_for_vms]

  content = templatefile("${path.module}/inventory.tpl", {
    manager_ip       = var.manager_ip
    worker1_ip       = var.worker1_ip
    worker2_ip       = var.worker2_ip
    ansible_user     = var.ansible_user
    private_key_path = "${path.module}/.vagrant/machines"
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}
