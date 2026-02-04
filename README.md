# Projet DevOps - Infrastructure GLPI avec Docker Swarm

## Participants

| Nom | Prénom |
|-----|--------|
| HAMMOUDI | Anis |

---

## Objectif du projet

Déployer automatiquement une infrastructure Docker Swarm avec :
- **3 Nginx** en reverse proxy (Docker Swarm avec réplication)
- **Certificats SSL** auto-signés (environnement local)
- **GLPI** comme serveur web de gestion IT
- **MariaDB** comme base de données

**Outils utilisés :**
- **Terraform** : Orchestration du provisionnement via Vagrant
- **Vagrant/VirtualBox** : Création des VMs (3 nœuds)
- **Ansible** : Configuration des serveurs via SSH depuis WSL

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
│  • MariaDB    │◄─Volume──────│               │              │               │
│    (persist)  │  mariadb_data│  Docker       │              │  Docker       │
│  • GLPI       │              │  Engine       │              │  Engine       │
│  • Nginx x3   │              │               │              │               │
└───────────────┘              └───────────────┘              └───────────────┘
        │                                │                                │
        └────────────────────────────────┴────────────────────────────────┘
                          Réseau overlay : glpi_glpi_net
```

### Services déployés

| Service | Image | Replicas | Placement | Persistance |
|---------|-------|----------|-----------|-------------|
| nginx | quay.io/nginx/nginx-unprivileged:alpine | 3 | manager | Configs bind-mount |
| glpi | ghcr.io/glpi-project/glpi:latest | 1 | manager | - |
| mariadb | ghcr.io/linuxserver/mariadb:10.6.12 | 1 | manager | **Volume: mariadb_data** |

---

## Prérequis

| Logiciel | Version | Téléchargement |
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
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Orchestration Terraform
│   └── Vagrantfile             # Définition des 3 VMs
│
├── ansible/                    # Configuration Management
│   ├── ansible.cfg             # Configuration Ansible
│   ├── deploy.sh               # Script d'exécution WSL
│   ├── inventory/
│   │   └── hosts.ini           # Inventaire SSH
│   ├── playbooks/
│   │   └── site.yml            # Playbook principal
│   ├── group_vars/
│   │   └── all.yml             # Variables globales
│   ├── files/                  # Fichiers à copier
│   │   ├── docker-compose.yml
│   │   └── nginx.conf
│   └── roles/                  # Rôles Ansible
│       ├── common/             # Paquets de base
│       ├── docker/             # Installation Docker
│       ├── swarm-manager/      # Initialisation Swarm
│       ├── swarm-worker/       # Jonction au Swarm
│       └── deploy-stack/       # Déploiement GLPI
│
└── README.md                   # Documentation
```

---

## Choix Architecturaux

### Terraform + Vagrant (Justification)

**Pourquoi Terraform orchestre Vagrant ?**

| Approche | Avantages | Inconvénients |
|----------|-----------|---------------|
| Terraform direct (VirtualBox provider) | Natif | Provider non officiel, peu maintenu |
| Vagrant seul | Simple | Pas d'état, pas de dépendances |
| **Terraform + Vagrant** | État Terraform, Vagrantfile standard | Couche supplémentaire |

**Notre choix** : Terraform orchestre l'infrastructure (variables, état, dépendances) et délègue la création des VMs à Vagrant (mature, bien documenté). Terraform gère ensuite l'exécution d'Ansible automatiquement via `null_resource`.

```
┌─────────────────────────────────────────────────────────────────┐
│                    terraform apply                               │
├─────────────────────────────────────────────────────────────────┤
│  1. null_resource.vagrant_up    →  vagrant up (3 VMs)           │
│  2. null_resource.ansible_config →  ansible-playbook (via WSL)  │
└─────────────────────────────────────────────────────────────────┘
```

### Persistance MariaDB

La base de données utilise :
- **Volume nommé Docker** : `mariadb_data:/var/lib/mysql` (persistant)
- **Contrainte de placement** : `node.role == manager` (reste sur le même nœud)

Cela garantit que les données survivent aux redémarrages de conteneurs.

### Certificats SSL (Let's Encrypt)

**Pourquoi certificats auto-signés ?**

Let's Encrypt nécessite :
- Un nom de domaine public (pas d'IP privée)
- Port 80/443 accessible depuis Internet
- Validation HTTP-01 ou DNS-01

En environnement VirtualBox local, ces conditions sont impossibles. Les certificats auto-signés sont l'alternative standard pour le développement.

---

## Déploiement automatique

### Commande unique (recommandé)

```powershell
cd terraform
terraform init
terraform apply -auto-approve
```

Cette commande effectue **automatiquement** :
1. **Terraform** → Crée les 3 VMs via Vagrant
2. **Terraform** → Attend 30 secondes que les VMs soient prêtes
3. **Ansible (via WSL)** → Configure Docker et Docker Swarm
4. **Ansible** → Déploie la stack GLPI

### Déploiement manuel (si besoin)

```powershell
# Étape 1 : Provisionnement de l'infrastructure
cd terraform
terraform init
vagrant up

# Étape 2 : Configuration avec Ansible (via WSL)
wsl -d Ubuntu -e bash ../ansible/deploy.sh
```

---

## Accès aux services

| Service | URL | Credentials |
|---------|-----|-------------|
| GLPI | https://192.168.56.10 | glpi / glpi |
| Nginx (status) | http://192.168.56.10 | - |

> ⚠️ Le certificat SSL est auto-signé, le navigateur affichera un avertissement.

---

## Commandes utiles

```powershell
# Vérifier l'état des VMs
cd terraform
vagrant status

# Se connecter au manager
vagrant ssh manager

# Voir les services Docker Swarm
vagrant ssh manager -c "docker service ls"

# Voir les nœuds du cluster
vagrant ssh manager -c "docker node ls"

# Logs d'un service
vagrant ssh manager -c "docker service logs glpi_nginx"

# Détruire l'infrastructure
cd terraform
terraform destroy -auto-approve
```

---

## Rôles Ansible

### common
- Mise à jour des paquets apt
- Installation des outils de base (curl, vim, net-tools)
- Configuration du timezone

### docker
- Installation de Docker et Docker Compose
- Démarrage et activation du service Docker
- Ajout de l'utilisateur vagrant au groupe docker

### swarm-manager
- Initialisation du cluster Docker Swarm
- Génération du token de jonction worker

### swarm-worker
- Récupération du token depuis le manager
- Jonction au cluster Swarm

### deploy-stack
- Copie des fichiers de configuration
- Génération du certificat SSL auto-signé
- Déploiement de la stack Docker

---

## Fichiers de configuration

### docker-compose.yml

Définit les 3 services :
- **nginx** : Reverse proxy avec 3 réplicas
- **glpi** : Application GLPI
- **mariadb** : Base de données

### nginx.conf

Configuration du reverse proxy :
- Écoute sur les ports 80 et 443
- Redirection HTTP → HTTPS
- Proxy vers GLPI sur le port 80

---

## Dépannage

### Les VMs ne démarrent pas
```powershell
# Vérifier VirtualBox
VBoxManage list vms

# Nettoyer et recréer
cd terraform
vagrant destroy -f
terraform apply -auto-approve
```

### Ansible ne se connecte pas
```powershell
# Tester la connexion SSH depuis WSL
wsl -d Ubuntu -e bash -c "
  ssh -i ~/.vagrant.d/insecure_private_key vagrant@192.168.56.10 hostname
"
```

### Les services ne démarrent pas
```powershell
# Vérifier les logs
vagrant ssh manager -c "docker service ps glpi_nginx --no-trunc"
vagrant ssh manager -c "docker service logs glpi_glpi"
```

---

## Technologies utilisées

| Catégorie | Technologie | Version |
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

## Auteur

**Anis HAMMOUDI** - Projet DevOps

Rendu à : dlamy4@myges.fr
