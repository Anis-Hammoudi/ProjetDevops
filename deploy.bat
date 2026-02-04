@echo off
echo ==========================================
echo    GLPI Stack - Deploiement Automatique
echo ==========================================
echo.
echo Outils utilises:
echo   - Terraform : Orchestration infrastructure
echo   - Vagrant   : Creation des VMs VirtualBox
echo   - Ansible   : Configuration (via WSL)
echo ==========================================
echo.

cd /d "%~dp0terraform"

echo [1/4] Destruction des anciennes VMs...
vagrant destroy -f 2>nul

echo.
echo [2/4] Initialisation Terraform...
terraform init -upgrade

echo.
echo [3/4] Creation des VMs (Terraform + Vagrant)...
terraform apply -auto-approve

echo.
echo [4/4] Configuration via Ansible (WSL)...
wsl -d Ubuntu -e bash -c "cd /mnt/c/Users/%USERNAME%/OneDrive/Desktop/ProjetDevops/ansible && chmod +x deploy.sh && ./deploy.sh"

echo.
echo ==========================================
echo    DEPLOIEMENT TERMINE
echo ==========================================
echo.
echo Access GLPI: https://192.168.56.10
echo Login: glpi / glpi
echo.
echo Database setup:
echo   Host: mariadb
echo   User: glpi
echo   Pass: glpipass123
echo ==========================================
pause
