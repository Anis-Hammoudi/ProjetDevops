# Projet DevOps - Infrastructure GLPI avec Docker Swarm

## Participants

| Nom | Prénom |
|-----|--------|
| HAMMOUDI | Anis |
| CHEDAD | Mehdi |
| ZOUINE | Sanaa |

**Date de rendu :** 16/02/2026  
**Contact :** dlamy4@myges.fr

---

## Objectif du projet

Deployer automatiquement une infrastructure Docker Swarm avec :
- **3 Nginx** en reverse proxy (replication Swarm)
- **Let's Encrypt** pour les certificats SSL (avec certificat de bootstrap en local)
- **GLPI** comme serveur web de gestion IT
- **MariaDB** comme base de donnees GLPI

**Outils utilises :**
- **Terraform** : Orchestration du provisionnement via Vagrant
- **Vagrant/VirtualBox** : Creation des VMs (3 noeuds)
- **Ansible** : Configuration des serveurs via SSH depuis WSL

---

## Architecture

- **Manager** : `192.168.56.10`
- **Worker 1** : `192.168.56.11`
- **Worker 2** : `192.168.56.12`
- **Reseau overlay** : `glpi_net`

### Services deployes

| Service | Image | Replicas | Placement | Persistance |
|---------|-------|----------|-----------|-------------|
| nginx | quay.io/nginx/nginx-unprivileged:alpine | 3 | manager | Bind-mount `/opt/glpi` |
| certbot | certbot/certbot:v2.11.0 | 1 | manager | Bind-mount `/opt/glpi` |
| glpi | ghcr.io/glpi-project/glpi:latest | 1 | manager | - |
| mariadb | ghcr.io/linuxserver/mariadb:10.6.12 | 1 | manager | **Volume: mariadb_data** |

---

## Prerequis

| Logiciel | Version | Telechargement |
|----------|---------|----------------|
| VirtualBox | >= 7.0 | https://www.virtualbox.org/wiki/Downloads |
| Vagrant | >= 2.4 | https://www.vagrantup.com/downloads |
| Terraform | >= 1.0 | https://www.terraform.io/downloads |
| WSL (Ubuntu) | 2 | `wsl --install -d Ubuntu` |

### Installation Windows (PowerShell)

```powershell
# Installer WSL avec Ubuntu
wsl --install -d Ubuntu

# Installer Ansible dans WSL
wsl -d Ubuntu -e bash -c "sudo apt update && sudo apt install -y ansible"

# Installer Vagrant et VirtualBox (avec Chocolatey)
choco install vagrant virtualbox terraform -y
```

---

## Structure du projet

```
ProjetDevops/
|-- terraform/                  # Infrastructure as Code
|   |-- main.tf                 # Orchestration Terraform
|   `-- Vagrantfile             # Definition des 3 VMs
|-- ansible/                    # Configuration Management
|   |-- ansible.cfg             # Configuration Ansible
|   |-- deploy.sh               # Script d'execution WSL
|   |-- inventory/
|   |   `-- hosts.ini           # Inventaire SSH
|   |-- playbooks/
|   |   `-- site.yml            # Playbook principal
|   |-- group_vars/
|   |   `-- all.yml             # Variables globales
|   |-- templates/              # Templates Ansible
|   |   |-- docker-compose.yml.j2
|   |   `-- nginx.conf.j2
|   `-- roles/                  # Roles Ansible
|       |-- common/             # Paquets de base
|       |-- docker/             # Installation Docker
|       |-- swarm-manager/      # Initialisation Swarm
|       |-- swarm-worker/       # Jonction au Swarm
|       `-- deploy-stack/       # Deploiement GLPI
`-- README.md                   # Documentation
```

---

## Configuration Let's Encrypt

Modifiez `ansible/group_vars/all.yml` :
- `domain_name` : votre nom de domaine public
- `letsencrypt_email` : email de contact
- `letsencrypt_staging` : `true` pour tester, `false` pour un vrai certificat

Let's Encrypt necessite :
- Un nom de domaine public resolvable vers votre IP
- Les ports **80/443** exposes depuis Internet

En local (VirtualBox), un **certificat auto-signe de bootstrap** est genere pour demarrer Nginx.
Apres delivrance du certificat, rechargez Nginx :

```powershell
vagrant ssh manager -c "docker service update --force glpi_nginx"
```

---

## Deploiement automatique

### Commande unique (recommande)

```powershell
cd terraform
terraform init
terraform apply -auto-approve
```

Cette commande effectue automatiquement :
1. **Terraform** -> Cree les 3 VMs via Vagrant
2. **Terraform** -> Attend 30 secondes que les VMs soient pretes
3. **Ansible (via WSL)** -> Configure Docker et Docker Swarm
4. **Ansible** -> Deploie la stack GLPI

### Deploiement manuel (si besoin)

```powershell
# Etape 1 : Provisionnement de l'infrastructure
cd terraform
terraform init
vagrant up

# Etape 2 : Configuration avec Ansible (via WSL)
wsl -d Ubuntu -e bash ../ansible/deploy.sh
```

---

## Acces aux services

| Service | URL | Credentials |
|---------|-----|-------------|
| GLPI | https://192.168.56.10 | glpi / glpi |
| GLPI (domain) | https://<domain_name> | glpi / glpi |
| Nginx (status) | http://192.168.56.10 | - |

> Attention : en local, le certificat est auto-signe tant que Let's Encrypt n'a pas delivre le certificat.

---

## Commandes utiles

```powershell
# Verifier l'etat des VMs
cd terraform
vagrant status

# Se connecter au manager
vagrant ssh manager

# Voir les services Docker Swarm
vagrant ssh manager -c "docker service ls"

# Voir les noeuds du cluster
vagrant ssh manager -c "docker node ls"

# Logs d'un service
vagrant ssh manager -c "docker service logs glpi_nginx"

# Detruire l'infrastructure
cd terraform
terraform destroy -auto-approve
```

---

## Roles Ansible

### common
- Mise a jour des paquets apt
- Installation des outils de base
- Configuration du DNS pour eviter les timeouts

### docker
- Installation de Docker et Docker Compose
- Demarrage et activation du service Docker
- Ajout de l'utilisateur vagrant au groupe docker

### swarm-manager
- Initialisation du cluster Docker Swarm
- Generation du token de jonction worker

### swarm-worker
- Recuperation du token depuis le manager
- Jonction au cluster Swarm

### deploy-stack
- Rendu des templates de configuration
- Certificat SSL de bootstrap
- Deploiement de la stack Docker

---

## Fichiers de configuration

### docker-compose.yml.j2

Definit les services :
- **nginx** : Reverse proxy avec 3 replicas
- **certbot** : Let's Encrypt (renouvellement automatique)
- **glpi** : Application GLPI
- **mariadb** : Base de donnees

### nginx.conf.j2

Configuration du reverse proxy :
- Ecoute sur les ports 80 et 443
- Redirection HTTP -> HTTPS
- Endpoint ACME pour Let's Encrypt
- Proxy vers GLPI sur le port 80

---

## Depannage

### Les VMs ne demarrent pas

```powershell
# Verifier VirtualBox
VBoxManage list vms

# Nettoyer et recreer
cd terraform
vagrant destroy -f
terraform apply -auto-approve
```

### Apt est tres lent ou echoue

- Verifiez que le DNS fonctionne dans les VMs
- Le Vagrantfile active le DNS proxy de VirtualBox
- Si besoin : `vagrant reload --provision`

### Ansible ne se connecte pas

```powershell
# Tester la connexion SSH depuis WSL
wsl -d Ubuntu -e bash -c "
  ssh -i ~/.vagrant.d/insecure_private_key vagrant@192.168.56.10 hostname
"
```

### Les services ne demarrent pas

```powershell
# Verifier les logs
vagrant ssh manager -c "docker service ps glpi_nginx --no-trunc"
vagrant ssh manager -c "docker service logs glpi_glpi"
```

---

## Note sur les scripts

Les scripts utilises sont fournis dans ce depot et restent visibles et tracables.

---

## Technologies utilisees

| Categorie | Technologie | Version |
|-----------|-------------|---------|
| IaC | Terraform | 1.14+ |
| Provisioning | Vagrant | 2.4+ |
| Virtualisation | VirtualBox | 7.2+ |
| Config Management | Ansible | 2.20+ |
| Container Runtime | Docker | 28.2+ |
| Orchestration | Docker Swarm | native |
| Reverse Proxy | Nginx | alpine |
| Application | GLPI | latest |
| Database | MariaDB | 10.6 |

---

## Auteurs

| Nom | Prénom | Rôle |
|-----|--------|------|
| HAMMOUDI | Anis | Infrastructure Terraform/Vagrant |
| CHEDAD | Mehdi | Configuration Ansible |
| ZOUINE | Sanaa | Stack Docker/GLPI |

**Rendu à :** dlamy4@myges.fr
