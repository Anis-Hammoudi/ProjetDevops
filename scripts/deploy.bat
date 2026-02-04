@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo GLPI Stack Deployment Script (Windows)
echo ==========================================

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

echo.
echo [Step 1/4] Provisioning infrastructure with Terraform...
echo ------------------------------------------
cd /d "%PROJECT_DIR%\terraform"

if not exist ".terraform.lock.hcl" (
    terraform init
)

terraform apply -auto-approve

echo.
echo [Step 2/4] Waiting for VMs to be ready...
echo ------------------------------------------
timeout /t 30 /nobreak > nul

echo.
echo [Step 3/4] Configuring servers with Ansible...
echo ------------------------------------------
cd /d "%PROJECT_DIR%\ansible"

set ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory/hosts.ini playbooks/site.yml

echo.
echo [Step 4/4] Deployment complete
echo ==========================================
echo.
echo Access GLPI at:
echo   - HTTP:  http://192.168.56.10
echo   - HTTPS: https://192.168.56.10
echo.
echo Default GLPI credentials:
echo   - Username: glpi
echo   - Password: glpi
echo.
echo To check the stack status, run:
echo   vagrant ssh manager -c "docker service ls"
echo.

endlocal
