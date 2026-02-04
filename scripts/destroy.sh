#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "GLPI Stack Destruction Script"
echo "=========================================="
echo ""
echo "This will destroy all infrastructure and data."
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "[Step 1/2] Removing Docker stack..."
echo "------------------------------------------"
cd "$PROJECT_DIR/terraform"

if vagrant status manager 2>/dev/null | grep -q "running"; then
    vagrant ssh manager -c "docker stack rm glpi_stack" 2>/dev/null || true
    echo "Waiting for stack removal..."
    sleep 15
fi

echo ""
echo "[Step 2/2] Destroying infrastructure with Terraform..."
echo "------------------------------------------"
terraform destroy -auto-approve

echo ""
echo "=========================================="
echo "Infrastructure destroyed successfully"
echo "=========================================="
