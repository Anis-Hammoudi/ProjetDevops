# Outputs from Terraform provisioning

output "manager_ip" {
  description = "IP address of the Swarm Manager"
  value       = var.manager_ip
}

output "worker1_ip" {
  description = "IP address of Worker 1"
  value       = var.worker1_ip
}

output "worker2_ip" {
  description = "IP address of Worker 2"
  value       = var.worker2_ip
}

output "swarm_nodes" {
  description = "All Swarm node IPs"
  value = {
    manager = var.manager_ip
    worker1 = var.worker1_ip
    worker2 = var.worker2_ip
  }
}

output "glpi_url" {
  description = "URL to access GLPI"
  value       = "https://${var.manager_ip}"
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = "${path.module}/../ansible/inventory/hosts.ini"
}

output "ssh_connection_manager" {
  description = "SSH command to connect to manager"
  value       = "vagrant ssh manager"
}

output "next_steps" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
    Infrastructure provisioned successfully.
    
    Next steps:
    1. cd ../ansible
    2. ansible-playbook -i inventory/hosts.ini playbooks/site.yml
    
    Or run the deploy script:
    ../scripts/deploy.sh
  EOT
}
