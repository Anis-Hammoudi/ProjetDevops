@echo off
cd /d "%~dp0terraform"
echo ==========================================
echo    GLPI Stack Automated Deployment
echo ==========================================
echo.

echo [1/4] Destroying existing VMs...
vagrant destroy -f 2>nul

echo.
echo [2/4] Creating VMs and configuring Docker Swarm...
vagrant up

echo.
echo [3/4] Waiting for swarm cluster to stabilize...
timeout /t 10 /nobreak > nul
vagrant ssh manager -c "docker node ls"

echo.
echo [4/4] Deploying GLPI Stack on manager...
vagrant ssh manager -c "sudo mkdir -p /opt/glpi && sudo cp /vagrant/stack/nginx.conf /opt/glpi/ && sudo cp /vagrant/stack/docker-compose.yml /opt/glpi/ && sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/glpi/privkey.pem -out /opt/glpi/fullchain.pem -subj '/CN=glpi.local' 2>/dev/null && sudo docker stack deploy -c /opt/glpi/docker-compose.yml glpi"

echo.
echo Waiting for services to start...
timeout /t 20 /nobreak > nul

echo.
echo ==========================================
echo    DEPLOYMENT COMPLETE
echo ==========================================
echo.
echo Services:
vagrant ssh manager -c "docker service ls"
echo.
echo Access GLPI at: https://192.168.56.10
echo Default credentials: glpi / glpi
echo.
pause
