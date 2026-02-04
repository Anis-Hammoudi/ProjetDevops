#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "GLPI Stack Deployment Script"
echo "=========================================="

echo ""
echo "[Step 1/4] Provisioning infrastructure with Terraform..."
echo "------------------------------------------"
cd "$PROJECT_DIR/terraform"

if [ ! -f ".terraform.lock.hcl" ]; then
    terraform init
fi

terraform apply -auto-approve

echo ""
echo "[Step 2/4] Waiting for VMs to be ready..."
echo "------------------------------------------"
sleep 30

echo ""
echo "[Step 3/4] Configuring servers with Ansible..."
echo "------------------------------------------"
cd "$PROJECT_DIR/ansible"

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory/hosts.ini playbooks/site.yml

echo ""
echo "[Step 4/4] Deployment complete"
echo "=========================================="
echo ""
echo "Access GLPI at:"
echo "  - HTTP:  http://192.168.56.10"
echo "  - HTTPS: https://192.168.56.10"
echo ""
echo "Default GLPI credentials:"
echo "  - Username: glpi"
echo "  - Password: glpi"
echo ""
echo "To check the stack status, run:"
echo "  vagrant ssh manager -c 'docker service ls'"
echo ""
