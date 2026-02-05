# Terraform - Provisionnement Infrastructure Docker Swarm
# Projet DevOps - HAMMOUDI Anis, CHEDAD Mehdi, ZOUINE Sanaa

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Variables

variable "manager_ip" {
  description = "IP du manager Swarm"
  type        = string
  default     = "192.168.56.10"
}

variable "worker1_ip" {
  description = "IP du worker 1"
  type        = string
  default     = "192.168.56.11"
}

variable "worker2_ip" {
  description = "IP du worker 2"
  type        = string
  default     = "192.168.56.12"
}

# Provisionnement des VMs avec Vagrant

resource "null_resource" "vagrant_up" {
  
  # Démarrage des VMs
  provisioner "local-exec" {
    command     = "vagrant up"
    working_dir = path.module
  }

  # Destruction des VMs
  provisioner "local-exec" {
    when        = destroy
    command     = "vagrant destroy -f"
    working_dir = path.module
  }

  triggers = {
    # Relancer si le Vagrantfile change
    vagrantfile = filemd5("${path.module}/Vagrantfile")
  }
}

# Configuration avec Ansible (via WSL)

resource "null_resource" "ansible_config" {
  depends_on = [null_resource.vagrant_up]

  # Attendre que les VMs soient prêtes
  provisioner "local-exec" {
    command = "powershell -Command \"Start-Sleep -Seconds 30\""
  }

  # Exécuter Ansible via WSL en utilisant le script deploy.sh
  provisioner "local-exec" {
    command     = "wsl -d Ubuntu -e bash ../ansible/deploy.sh"
    working_dir = path.module
  }

  triggers = {
    vagrant = null_resource.vagrant_up.id
    playbook = filemd5("${path.module}/../ansible/playbooks/site.yml")
  }
}

# Outputs

output "manager_ip" {
  description = "IP du manager Swarm"
  value       = var.manager_ip
}

output "worker1_ip" {
  description = "IP du worker 1"
  value       = var.worker1_ip
}

output "worker2_ip" {
  description = "IP du worker 2"
  value       = var.worker2_ip
}

output "glpi_url" {
  description = "URL d'accès à GLPI"
  value       = "https://${var.manager_ip}"
}

output "instructions" {
  description = "Instructions post-déploiement"
  value       = <<-EOT
    
    ========================================
    DÉPLOIEMENT TERMINÉ
    ========================================
    
    Accès GLPI: https://${var.manager_ip}
    Login: glpi / glpi
    
    Base de données:
    - Host: mariadb
    - User: glpi
    - Password: glpipass123
    
    Commandes utiles:
    - vagrant ssh manager -c "docker service ls"
    - vagrant ssh manager -c "docker node ls"
    
  EOT
}
