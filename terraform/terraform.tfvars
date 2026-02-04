# Terraform variables configuration

manager_ip  = "192.168.56.10"
worker1_ip  = "192.168.56.11"
worker2_ip  = "192.168.56.12"

vm_memory = 2048
vm_cpus   = 2

box_image = "ubuntu/jammy64"

ansible_user = "vagrant"

# Let's Encrypt configuration
domain_name         = "glpi.local"
letsencrypt_email   = "admin@example.com"
letsencrypt_staging = true
