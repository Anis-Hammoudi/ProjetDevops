# Variables for local VM provisioning

variable "manager_ip" {
  description = "IP address for the Swarm Manager node"
  type        = string
  default     = "192.168.56.10"
}

variable "worker1_ip" {
  description = "IP address for the first Swarm Worker node"
  type        = string
  default     = "192.168.56.11"
}

variable "worker2_ip" {
  description = "IP address for the second Swarm Worker node"
  type        = string
  default     = "192.168.56.12"
}

variable "vm_memory" {
  description = "Memory allocation for each VM in MB"
  type        = number
  default     = 2048
}

variable "vm_cpus" {
  description = "Number of CPUs for each VM"
  type        = number
  default     = 2
}

variable "box_image" {
  description = "Vagrant box image to use"
  type        = string
  default     = "ubuntu/jammy64"
}

variable "ansible_user" {
  description = "SSH user for Ansible connections"
  type        = string
  default     = "vagrant"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for Let's Encrypt certificates"
  type        = string
  default     = "glpi.local"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt registration"
  type        = string
  default     = "admin@example.com"
}

variable "letsencrypt_staging" {
  description = "Use Let's Encrypt staging environment"
  type        = bool
  default     = true
}
