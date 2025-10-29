#!/bin/bash

###############################################################################
#                       INSTALLATION COMPLÈTE 

###############################################################################

echo "======================================"
echo "Installation Infrastructure Sécurisée"
echo "Diva's Company - 2024"
echo "======================================"
echo ""

# Vérifier qu'on est root
if [ "$(id -u)" -ne 0 ]; then
   echo "ERREUR: Ce script doit être lancé avec sudo"
   exit 1
fi

# Demander confirmation
echo "Cette installation va:"
echo "- Mettre à jour le système"
echo "- Sécuriser le serveur"
echo "- Créer les utilisateurs (angelica, bahia)"
echo "- Configurer le pare-feu"
echo "- Installer VPN WireGuard"
echo "- Installer DNS Bind9"
echo "- Installer Apache"
echo "- Installer Fail2Ban"
echo ""
read -p "Continuer ? (o/n) " reponse
if [ "$reponse" != "o" ]; then
    echo "Installation annulée"
    exit 0
fi

###############################################################################
# ETAPE 1 : MISE À JOUR SYSTÈME
###############################################################################

echo ""
echo "=== [1/8] Mise à jour système ==="
if command -v dnf > /dev/null; then
    dnf update -y
    dnf upgrade -y
else
    apt update
    apt upgrade -y
    apt autoremove -y
fi
echo "✓ Système mis à jour"

###############################################################################
# ETAPE 2 : SÉCURISATION (HARDENING)
###############################################################################

echo ""
echo "=== [2/8] Sécurisation système ==="

# Permissions fichiers
chmod 644 /etc/passwd
chmod 000 /etc/shadow
chmod 644 /etc/group
echo "✓ Permissions fichiers"

# Configuration réseau sécurisée
cat > /etc/sysctl.d/99-security.conf << EOF
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
kernel.randomize_va_space = 2
EOF
sysctl -p /etc/sysctl.d/99-security.conf > /dev/null
echo "✓ Configuration réseau"

# Désactiver services inutiles
systemctl stop bluetooth 2>/dev/null
systemctl disable bluetooth 2>/dev/null
systemctl stop cups 2>/dev/null
systemctl disable cups 2>/dev/null
echo "✓ Services inutiles désactivés"

# Permissions par défaut
echo "umask 027" >> /etc/profile
echo "umask 027" >> /etc/bashrc
echo "✓ Permissions par défaut"

# Timeout shell
echo "export TMOUT=300" >> /etc/profile
echo "✓ Timeout shell (5 min)"

# Bannière
cat > /etc/ssh/banner << EOF
╔════════════════════════════════════════╗
║     SYSTÈME PRIVÉ - DIVA'S COMPANY     ║
║   Accès réservé aux utilisateurs       ║
║         autorisés uniquement           ║
╚════════════════════════════════════════╝
EOF
echo "✓ Bannière créée"

# Installer Lynis
if command -v dnf > /dev/null; then
    dnf install -y lynis > /dev/null 2>&1
else
    apt install -y lynis > /dev/null 2>&1
fi
echo "✓ Lynis installé"

###############################################################################
# ETAPE 3 : CRÉATION UTILISATEURS
###############################################################################

echo ""
echo "=== [3/8] Création utilisateurs ==="

# Créer les groupes
groupadd adminDivas 2>/dev/null || true
groupadd employDivas 2>/dev/null || true
echo "✓ Groupes créés"

# Créer angelica (admin)
if ! id angelica > /dev/null 2>&1; then
    useradd -m -s /bin/bash -G adminDivas,wheel angelica
    echo "angelica:MotDePasse123!" | chpasswd
    echo "✓ Utilisateur angelica créé"
    echo "  Mot de passe temporaire: MotDePasse123!"
else
    echo "✓ angelica existe déjà"
fi

# Dossier SSH angelica
mkdir -p /home/angelica/.ssh
chmod 700 /home/angelica/.ssh
touch /home/angelica/.ssh/authorized_keys
chmod 600 /home/angelica/.ssh/authorized_keys
chown -R angelica:angelica /home/angelica/.ssh

# Créer bahia (employé)
if ! id bahia > /dev/null 2>&1; then
    useradd -m -s /bin/bash -G employDivas bahia
    echo "bahia:MotDePasse456!" | chpasswd
    echo "✓ Utilisateur bahia créé"
    echo "  Mot de passe temporaire: MotDePasse456!"
else
    echo "✓ bahia existe déjà"
fi

# Configuration sudo
cat > /etc/sudoers.d/adminDivas << EOF
%adminDivas ALL=(ALL) ALL
EOF
chmod 440 /etc/sudoers.d/adminDivas
echo "✓ Sudo configuré"

# Configuration SSH
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup 2>/dev/null || true
cat >> /etc/ssh/sshd_config << EOF

# Configuration Diva's Company
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
Banner /etc/ssh/banner

# Restrictions employés
Match Group employDivas
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF
echo "✓ SSH configuré"

###############################################################################
# ETAPE 4 : PARE-FEU
###############################################################################

echo ""
echo "=== [4/8] Configuration pare-feu ==="

if command -v firewall-cmd > /dev/null; then
    # Firewalld (Fedora)
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-service=dns
    firewall-cmd --permanent --add-port=51820/udp
    firewall-cmd --permanent --add-masquerade
    firewall-cmd --reload
    echo "✓ Firewalld configuré"
else
    # UFW (Debian)
    if ! command -v ufw > /dev/null; then
        apt install -y ufw
    fi
    ufw --force disable
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 53
    ufw allow 51820/udp
    ufw allow from 10.0.0.0/24
    ufw limit 22/tcp
    ufw --force enable
    echo "✓ UFW configuré"
fi

###############################################################################
# ETAPE 5 : VPN WIREGUARD
###############################################################################

echo ""
echo "=== [5/8] Installation VPN WireGuard ==="

# Installer
if command -v dnf > /dev/null; then
    dnf install -y wireguard-tools
else
    apt install -y wireguard wireguard-tools
fi
echo "✓ WireGuard installé"

# Créer répertoire
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# Générer clés
cd /etc/wireguard
wg genkey | tee server_private.key | wg pubkey > server_public.key
chmod 600 server_private.key
echo "✓ Clés générées"

# Configuration
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat server_private.key)
SaveConfig = false

PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o $INTERFACE -j MASQUERADE
EOF
chmod 600 /etc/wireguard/wg0.conf

# Activer forwarding
cat > /etc/sysctl.d/99-wireguard.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-wireguard.conf > /dev/null

# Démarrer
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
echo "✓ VPN démarré"

# Config client exemple
mkdir -p /etc/wireguard/clients
cd /etc/wireguard/clients
wg genkey | tee client_private.key | wg pubkey > client_public.key
IP_PUBLIQUE=$(curl -s ifconfig.me)
cat > client-exemple.conf << EOF
[Interface]
PrivateKey = $(cat client_private.key)
Address = 10.0.0.2/32
DNS = 10.0.0.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $IP_PUBLIQUE:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
EOF
echo "✓ Config client créée"

###############################################################################
# ETAPE 6 : DNS BIND9
###############################################################################

echo ""
echo "=== [6/8] Installation DNS Bind9 ==="

# Installer
if command -v dnf > /dev/null; then
    dnf install -y bind bind-utils
else
    apt install -y bind9 bind9-utils bind9-doc
fi
echo "✓ Bind9 installé"

# Configuration
IP_SERVEUR=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
cat > /etc/named.conf << EOF
options {
    listen-on port 53 { 127.0.0.1; $IP_SERVEUR; 10.0.0.1; };
    directory "/var/named";
    allow-query { localhost; 10.0.0.0/24; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    recursion yes;
    dnssec-validation yes;
};

zone "divas.local" IN {
    type master;
    file "/var/named/divas.local.zone";
    allow-update { none; };
};
EOF

# Zone DNS
cat > /var/named/divas.local.zone << EOF
\$TTL 86400
@   IN  SOA     ns1.divas.local. admin.divas.local. (
                2024051901 3600 1800 604800 86400 )
    IN  NS      ns1.divas.local.
ns1         IN  A       $IP_SERVEUR
divas       IN  A       $IP_SERVEUR
www         IN  CNAME   divas
EOF
chmod 644 /var/named/divas.local.zone
chown named:named /var/named/divas.local.zone

# Démarrer
systemctl enable named
systemctl restart named
echo "✓ DNS configuré"

###############################################################################
# ETAPE 7 : APACHE
###############################################################################

echo ""
echo "=== [7/8] Installation Apache ==="

# Installer
if command -v dnf > /dev/null; then
    dnf install -y httpd
else
    apt install -y apache2
fi
echo "✓ Apache installé"

# Page web
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Diva's Company</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 50px;
            border-radius: 20px;
        }
        h1 { font-size: 3em; margin: 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Diva's Company</h1>
        <p>Infrastructure Sécurisée</p>
        <p>✅ Serveur Actif</p>
    </div>
</body>
</html>
EOF
echo "✓ Page web créée"

# Configuration
if command -v dnf > /dev/null; then
    cat > /etc/httpd/conf.d/divas.conf << EOF
<VirtualHost *:80>
    ServerName divas.local
    DocumentRoot /var/www/html
    <Directory "/var/www/html">
        Require ip 10.0.0.0/24
        Require ip 127.0.0.1
    </Directory>
</VirtualHost>
EOF
    systemctl enable httpd
    systemctl restart httpd
else
    cat > /etc/apache2/sites-available/divas.conf << EOF
<VirtualHost *:80>
    ServerName divas.local
    DocumentRoot /var/www/html
    <Directory "/var/www/html">
        Require ip 10.0.0.0/24
        Require ip 127.0.0.1
    </Directory>
</VirtualHost>
EOF
    a2ensite divas.conf
    a2dissite 000-default.conf
    systemctl enable apache2
    systemctl restart apache2
fi
echo "✓ Apache configuré"

###############################################################################
# ETAPE 8 : FAIL2BAN
###############################################################################

echo ""
echo "=== [8/8] Installation Fail2Ban ==="

# Installer
if command -v dnf > /dev/null; then
    dnf install -y fail2ban
else
    apt install -y fail2ban
fi
echo "✓ Fail2Ban installé"

# Configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = 22
logpath = /var/log/secure
maxretry = 3
EOF

# Démarrer
systemctl enable fail2ban
systemctl restart fail2ban
echo "✓ Fail2Ban actif"

###############################################################################
# RÉSUMÉ FINAL
###############################################################################

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   INSTALLATION TERMINÉE AVEC SUCCÈS    ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Services installés:"
echo "✓ Système sécurisé (hardening)"
echo "✓ Utilisateurs: angelica (admin), bahia (employé)"
echo "✓ Pare-feu configuré"
echo "✓ VPN WireGuard (port 51820)"
echo "✓ DNS Bind9 (divas.local)"
echo "✓ Apache (http://divas.local)"
echo "✓ Fail2Ban actif"
echo ""
echo "Mots de passe temporaires:"
echo "- angelica: MotDePasse123!"
echo "- bahia: MotDePasse456!"
echo "⚠ CHANGEZ CES MOTS DE PASSE !"
echo ""
echo "Fichiers importants:"
echo "- Config VPN: /etc/wireguard/wg0.conf"
echo "- Config client VPN: /etc/wireguard/clients/client-exemple.conf"
echo "- Clé publique VPN: /etc/wireguard/server_public.key"
echo ""
echo "Commandes utiles:"
echo "- VPN: wg show wg0"
echo "- DNS: nslookup divas.local localhost"
echo "- Fail2Ban: fail2ban-client status sshd"
echo ""
echo "IMPORTANT: Redémarrez le serveur"
echo "Commande: sudo reboot"
echo ""
