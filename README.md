# 🔒 Infrastructure Réseau Sécurisée

![Linux](https://img.shields.io/badge/Linux-Fedora-blue?logo=fedora)
![Security](https://img.shields.io/badge/Security-Hardening-red)
![VPN](https://img.shields.io/badge/VPN-WireGuard-green)

## 📋 À Propos

Projet de sécurisation d'infrastructure serveur Linux réalisé en groupe pendant ma formation en cybersécurité. 

**👥 Équipe** : Les Divas  
**📅 Période** : Mai 2025
**🎯 Objectif** : Déployer et sécuriser une infrastructure réseau d'entreprise

---

## 🎯 Ce que j'ai appris

- Sécuriser un serveur Linux (Hardening)
- Configurer un pare-feu (UFW/Firewalld)
- Installer un VPN (WireGuard)
- Mettre en place un DNS local (Bind9)
- Déployer un serveur web (Apache)
- Protéger contre les attaques SSH (Fail2Ban)
- Monitorer un système (Lynis, journalctl)

---

## 🏗️ Architecture du Projet

```
Internet
    │
    ├─── Firewall UFW
    │
    ├─── VPN WireGuard (10.0.0.0/24)
    │
    └─── Serveur Fedora
            ├─── SSH sécurisé
            ├─── DNS Bind9
            ├─── Apache
            └─── Fail2Ban
```

---

## 🛠️ Technologies Utilisées

| Composant | Technologie |
|-----------|-------------|
| OS | Fedora Linux |
| SSH | OpenSSH + Clés |
| Firewall | UFW / Firewalld |
| VPN | WireGuard |
| DNS | Bind9 |
| Web | Apache |
| Sécurité | Fail2Ban |
| Monitoring | Lynis |

---

## 📁 Structure du Projet

```
├── README.md
├── docs/                    # Documentation détaillée
├── scripts/                 # Scripts d'installation
├── configs/                 # Fichiers de configuration
│   ├── ssh/
│   ├── firewall/
│   ├── vpn/
│   ├── dns/
│   └── apache/
└── tests/                   # Scripts de test
```

---

## 🚀 Installation

### Prérequis
- Serveur Fedora Linux
- Accès root ou sudo
- Connexion Internet

### Installation Rapide

```bash
# Cloner le projet
git clone https://github.com/votre-username/infrastructure-securisee.git
cd infrastructure-securisee

# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Lancer l'installation complète
sudo ./scripts/00-install-all.sh
```

### Installation Manuelle

```bash
# 1. Mise à jour système
sudo ./scripts/01-system-update.sh

# 2. Sécurisation (Hardening)
sudo ./scripts/02-hardening.sh

# 3. Création utilisateurs
sudo ./scripts/03-create-users.sh

# 4. Firewall
sudo ./scripts/04-setup-firewall.sh

# 5. VPN WireGuard
sudo ./scripts/05-setup-vpn.sh

# 6. DNS Bind9
sudo ./scripts/06-setup-dns.sh

# 7. Apache
sudo ./scripts/07-setup-apache.sh

# 8. Fail2Ban
sudo ./scripts/08-setup-fail2ban.sh
```

---

## 👥 Utilisateurs Créés

### Administrateurs
- **Groupe** : `adminDivas`
- **Exemple** : `angelica`
- **Accès** : SSH par clé, droits sudo complets

### Employés
- **Groupe** : `employDivas`
- **Exemple** : `bahia`
- **Accès** : Limité au home directory, SFTP uniquement

---

## 🔐 Sécurité Mise en Place

✅ **SSH** : Authentification par clé, désactivation root  
✅ **Firewall** : Ports 22, 80, 51820 ouverts uniquement  
✅ **Fail2Ban** : Protection anti-bruteforce (3 tentatives max)  
✅ **VPN** : Tunnel chiffré WireGuard  
✅ **Monitoring** : Logs et audit avec Lynis

---

## 🧪 Tests

```bash
# Tester SSH
ssh angelica@<IP_SERVEUR>

# Tester VPN
sudo wg show wg0

# Tester DNS
nslookup divas.local

# Tester Apache
curl http://<IP_SERVEUR>

# Tester Fail2Ban
sudo fail2ban-client status sshd
```

---

## 📚 Documentation

Documentation détaillée dans le dossier `/docs` :

- [Hardening](docs/02-hardening.md)
- [Gestion utilisateurs](docs/03-gestion-utilisateurs.md)
- [Firewall](docs/04-firewall.md)
- [VPN WireGuard](docs/05-vpn-wireguard.md)
- [DNS Bind9](docs/06-dns-bind9.md)
- [Serveur Web](docs/07-serveur-web.md)
- [Monitoring](docs/08-monitoring.md)

---

## 📊 Commandes Utiles

```bash
# Statut des services
sudo systemctl status sshd
sudo systemctl status wg-quick@wg0
sudo systemctl status named
sudo systemctl status httpd
sudo systemctl status fail2ban

# Logs
sudo journalctl -u sshd -f
sudo journalctl -u fail2ban -f

# Audit sécurité
sudo lynis audit system

# Pare-feu
sudo ufw status verbose              # UFW
sudo firewall-cmd --list-all         # Firewalld
```

---

## 🤝 Contribution

Projet réalisé en collaboration avec mon équipe de formation.

**Points clés du travail en équipe :**
- Répartition des tâches (SSH, VPN, DNS, Web)
- Documentation collaborative
- Tests croisés des configurations
- Résolution de problèmes en groupe

---

## 📝 Licence

Projet éducatif - Formation Cybersécurité 2025

---

## 🙏 Remerciements

- Mon formateur pour l'accompagnement
- L'équipe "Les Divas" pour la collaboration
- Ressources utilisées :
  - [IT-Connect](https://www.it-connect.fr/)
  - [Documentation Fedora](https://docs.fedoraproject.org/)
  - [WireGuard Docs](https://www.wireguard.com/)

---

