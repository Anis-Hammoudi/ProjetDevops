@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo GLPI Stack Destruction Script (Windows)
echo ==========================================
echo.
echo This will destroy all infrastructure and data.
set /p CONFIRM="Are you sure you want to continue? (y/N) "

if /i not "%CONFIRM%"=="y" (
    echo Aborted.
    exit /b 1
)

set SCRIPT_DIR=%~dp0
set PROJECT_DIR=%SCRIPT_DIR%..

echo.
echo [Step 1/2] Removing Docker stack...
echo ------------------------------------------
cd /d "%PROJECT_DIR%\terraform"

vagrant ssh manager -c "docker stack rm glpi_stack" 2>nul
echo Waiting for stack removal...
timeout /t 15 /nobreak > nul

echo.
echo [Step 2/2] Destroying infrastructure with Terraform...
echo ------------------------------------------
terraform destroy -auto-approve

echo.
echo ==========================================
echo Infrastructure destroyed successfully
echo ==========================================

endlocal
