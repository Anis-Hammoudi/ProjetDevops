# Projet DevOps - Infrastructure GLPI avec Docker Swarm

## Participants

| Nom | Prénom |
|-----|--------|
| HAMMOUDI | Anis |

---

## Objectif du projet

Déployer automatiquement une infrastructure Docker Swarm avec :
- **3 Nginx** en reverse proxy (Docker Swarm avec réplication)
- **Let's Encrypt** pour les certificats SSL (auto-signé en local)
- **GLPI** comme serveur web de gestion IT
- **MariaDB** comme base de données

**Outils utilisés :**
- **Terraform/Vagrant** : Provisionnement de l'infrastructure (3 VMs)
- **Ansible** : Configuration des serveurs (rôles Docker, Swarm, Stack)

---

## Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │            Docker Swarm Cluster             │
                    └─────────────────────────────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        │                                │                                │
        ▼                                ▼                                ▼
┌───────────────┐              ┌───────────────┐              ┌───────────────┐
│    MANAGER    │              │   WORKER 1    │              │   WORKER 2    │
│ 192.168.56.10 │              │ 192.168.56.11 │              │ 192.168.56.12 │
├───────────────┤              ├───────────────┤              ├───────────────┤
│  • MariaDB    │              │  • Nginx 1/3  │              │  • Nginx 1/3  │
│  • GLPI       │              │               │              │               │
│  • Nginx 1/3  │              │               │              │               │
└───────────────┘              └───────────────┘              └───────────────┘
```

### Services déployés

| Service | Image | Replicas | Port | Description |
|---------|-------|----------|------|-------------|
| nginx | nginx:alpine | 3 | 80, 443 | Reverse proxy avec SSL/TLS |
| glpi | diouxx/glpi:latest | 1 | - | Application GLPI |
| mariadb | mariadb:10.6 | 1 | - | Base de données |

---

## Prérequis

| Logiciel | Version | Téléchargement |
|----------|---------|----------------|
| VirtualBox | >= 6.1 | https://www.virtualbox.org/wiki/Downloads |
| Vagrant | >= 2.3 | https://www.vagrantup.com/downloads |

### Installation Windows (PowerShell)

```powershell
# Avec Scoop
scoop install vagrant

# Ou avec Chocolatey
choco install vagrant virtualbox -y
```

---

## Déploiement automatique

### Méthode 1 : Script batch (recommandé)

```cmd
deploy.bat
```

Ce script :
1. Détruit les anciennes VMs
2. Crée 3 VMs avec Vagrant/VirtualBox
3. Installe Docker sur chaque nœud
4. Initialise le cluster Docker Swarm
5. Déploie la stack GLPI

### Méthode 2 : Commandes manuelles

```powershell
# Étape 1 : Provisionnement infrastructure (Terraform/Vagrant)
cd terraform
vagrant up

# Étape 2 : Déploiement stack (Ansible équivalent)
vagrant ssh manager -c "sudo mkdir -p /opt/glpi && sudo cp /vagrant/stack/* /opt/glpi/ && sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/glpi/privkey.pem -out /opt/glpi/fullchain.pem -subj '/CN=glpi.local' 2>/dev/null && sudo docker stack deploy -c /opt/glpi/docker-compose.yml glpi"
```

---

## Vérification

```powershell
# Voir les nœuds du cluster Swarm
vagrant ssh manager -c "docker node ls"

# Voir les services déployés
vagrant ssh manager -c "docker service ls"

# Résultat attendu :
# NAME           REPLICAS   IMAGE
# glpi_nginx     3/3        nginx:alpine
# glpi_glpi      1/1        diouxx/glpi:latest
# glpi_mariadb   1/1        mariadb:10.6
```

---

## Accès à l'application

| Paramètre | Valeur |
|-----------|--------|
| URL | https://192.168.56.10 |
| Login GLPI | glpi |
| Password GLPI | glpi |

### Configuration base de données (premier lancement)

| Paramètre | Valeur |
|-----------|--------|
| SQL Server | mariadb |
| SQL User | glpi |
| SQL Password | glpipass123 |
| Database | glpi |

---

## Structure du projet

```
ProjetDevops/
├── README.md                      # Documentation (ce fichier)
├── deploy.bat                     # Script déploiement Windows
├── .gitignore                     # Fichiers ignorés par Git
│
├── terraform/                     # INFRASTRUCTURE (Terraform/Vagrant)
│   ├── Vagrantfile                # Définition des 3 VMs
│   └── stack/
│       ├── docker-compose.yml     # Stack Docker Swarm
│       └── nginx.conf             # Configuration Nginx reverse proxy
│
└── ansible/                       # CONFIGURATION (Ansible)
    ├── ansible.cfg                # Configuration Ansible
    ├── inventory/
    │   └── hosts.ini              # Inventaire des serveurs
    ├── group_vars/
    │   └── all.yml                # Variables globales
    ├── playbooks/
    │   └── site.yml               # Playbook principal
    └── roles/
        ├── common/                # Configuration de base
        ├── docker/                # Installation Docker
        ├── swarm-manager/         # Init Swarm Manager
        ├── swarm-worker/          # Join Swarm Workers
        └── deploy-stack/          # Déploiement stack GLPI
```

---

## Description des fichiers

### terraform/Vagrantfile
Crée 3 machines virtuelles Ubuntu avec VirtualBox :
- Installe Docker sur chaque nœud
- Configure le cluster Swarm (1 manager + 2 workers)

### terraform/stack/docker-compose.yml
Définit la stack Docker Swarm :
- Service MariaDB avec volume persistant
- Service GLPI connecté à MariaDB
- Service Nginx avec 3 replicas et SSL

### terraform/stack/nginx.conf
Configuration Nginx :
- Reverse proxy vers GLPI
- Terminaison SSL/TLS

### ansible/roles/
Rôles Ansible équivalents aux scripts shell :
- `docker/` : Installation et configuration Docker
- `swarm-manager/` : Initialisation du Swarm
- `swarm-worker/` : Jonction des workers au Swarm
- `deploy-stack/` : Déploiement de la stack GLPI

---

## Destruction de l'infrastructure

```powershell
cd terraform
vagrant destroy -f
```

---

## Let's Encrypt (Production)

En environnement de production avec un vrai nom de domaine :

1. Remplacer les certificats auto-signés par Let's Encrypt
2. Utiliser l'environnement **staging** pour les tests :
   ```
   https://acme-staging-v02.api.letsencrypt.org/directory
   ```
3. ⚠️ **Limite** : 5 échecs = blocage 48h

---

## Notes techniques

1. **Persistence MariaDB** : Volume Docker sur le manager uniquement
2. **Réseau overlay** : Communication inter-conteneurs via réseau Docker overlay
3. **Load balancing** : Mesh routing Docker Swarm distribue le trafic entre les 3 Nginx
4. **SSL/TLS** : Certificats auto-signés pour environnement local

---

## Commandes utiles

```bash
# Logs d'un service
docker service logs glpi_nginx

# Mise à l'échelle Nginx
docker service scale glpi_nginx=5

# Mise à jour d'un service
docker service update --image nginx:latest glpi_nginx

# Inspection d'un service
docker service inspect glpi_glpi
```
