# Projet DevOps - Infrastructure GLPI avec Docker Swarm

## Participants

| Nom | Prenom |
|-----|--------|
| HAMMO | [PRENOM] |

## Contact
Email de soumission: dlamy4@myges.fr

---

## Architecture

```
+-------------------+     +-------------------+     +-------------------+
|    Manager        |     |    Worker 1       |     |    Worker 2       |
|  192.168.56.10    |     |  192.168.56.11    |     |  192.168.56.12    |
|                   |     |                   |     |                   |
|  - MariaDB        |     |  - Nginx (1/3)    |     |  - Nginx (1/3)    |
|  - GLPI           |     |                   |     |                   |
|  - Nginx (1/3)    |     |                   |     |                   |
+-------------------+     +-------------------+     +-------------------+
         |                         |                         |
         +-----------+-------------+-----------+-------------+
                     |                         |
              Docker Swarm Cluster      Overlay Network
```

### Services deployes

| Service | Replicas | Placement | Description |
|---------|----------|-----------|-------------|
| Nginx | 3 | Tous les noeuds | Reverse proxy avec SSL |
| GLPI | 1 | Manager | Application web IT Asset Management |
| MariaDB | 1 | Manager | Base de donnees (volume persistant) |

---

## Pre-requis

- VirtualBox >= 6.1
- Vagrant >= 2.3

### Installation (Windows avec Scoop)

```powershell
scoop install vagrant terraform
```

Installer VirtualBox manuellement depuis: https://www.virtualbox.org/wiki/Downloads

---

## Deploiement

### Methode simple (un seul script)

```cmd
deploy.bat
```

### Methode manuelle

```powershell
# 1. Creer les VMs et le Swarm
cd terraform
vagrant up

# 2. Deployer la stack
vagrant ssh manager -c "sudo mkdir -p /opt/glpi && sudo cp /vagrant/stack/* /opt/glpi/ && sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/glpi/privkey.pem -out /opt/glpi/fullchain.pem -subj '/CN=glpi.local' 2>/dev/null && sudo docker stack deploy -c /opt/glpi/docker-compose.yml glpi"
```

---

## Verification

```powershell
# Voir les noeuds du cluster
vagrant ssh manager -c "docker node ls"

# Voir les services
vagrant ssh manager -c "docker service ls"
```

### Acces

- URL: https://192.168.56.10
- Identifiants GLPI par defaut: glpi / glpi

---

## Structure du projet

```
ProjetDevops/
├── README.md                      # Documentation
├── deploy.bat                     # Script de deploiement automatique
├── terraform/
│   ├── Vagrantfile                # Configuration des VMs
│   └── stack/
│       ├── docker-compose.yml     # Stack Docker Swarm
│       └── nginx.conf             # Configuration Nginx
└── ansible/                       # Playbooks Ansible (optionnel)
```

---

## Fichiers principaux

### Vagrantfile (terraform/Vagrantfile)
- Cree 3 VMs Ubuntu avec VirtualBox
- Installe Docker sur chaque noeud
- Initialise le Swarm (1 manager + 2 workers)

### docker-compose.yml (terraform/stack/docker-compose.yml)
- Service MariaDB avec volume persistant
- Service GLPI connecte a MariaDB
- Service Nginx avec 3 replicas et SSL

---

## Destruction

```powershell
cd terraform
vagrant destroy -f
```

---

## Let's Encrypt

Pour la production avec un vrai domaine:

1. Remplacer le certificat auto-signe par Let's Encrypt
2. Utiliser l'environnement staging pour les tests:
   ```
   https://acme-staging-v02.api.letsencrypt.org/directory
   ```
3. Limite: 5 echecs = blocage 48h

---

## Notes techniques

1. **Persistence MariaDB**: Le volume `mariadb_data` est sur le manager pour eviter la perte de donnees
2. **Reseau overlay**: Les services communiquent via le reseau Docker overlay
3. **Load balancing**: Le mesh routing de Docker Swarm distribue le trafic entre les 3 Nginx
