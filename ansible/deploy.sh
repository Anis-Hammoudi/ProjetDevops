#!/bin/bash
# =============================================================================
# SCRIPT DE DÉPLOIEMENT - Ansible depuis WSL
# =============================================================================
# Ce script configure les VMs créées par Vagrant/Terraform
# Exécuter depuis WSL : ./deploy.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR"

echo "=========================================="
echo "   ANSIBLE - Configuration des serveurs"
echo "=========================================="
echo ""

# Vérifier qu'Ansible est installé
if ! command -v ansible &> /dev/null; then
    echo "Installation d'Ansible..."
    sudo apt update && sudo apt install -y ansible sshpass
fi

# Copier la clé Vagrant si elle n'existe pas
if [ ! -f ~/.vagrant.d/insecure_private_key ]; then
    echo "Copie de la clé SSH Vagrant..."
    mkdir -p ~/.vagrant.d
    cp /mnt/c/Users/$USER/.vagrant.d/insecure_private_key ~/.vagrant.d/
    chmod 600 ~/.vagrant.d/insecure_private_key
fi

cd "$ANSIBLE_DIR"
export ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg"

echo ""
echo "[1/2] Test de connexion aux VMs..."
ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ansible all -m ping

echo ""
echo "[2/2] Exécution du playbook Ansible..."
ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ansible-playbook playbooks/site.yml -v

echo ""
echo "=========================================="
echo "   CONFIGURATION TERMINÉE"
echo "=========================================="
echo ""
echo "Vérification des services..."
ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg" ansible managers -m shell -a "docker service ls"
echo ""
echo "Accès GLPI: https://192.168.56.10"
echo "Login: glpi / glpi"
echo ""
