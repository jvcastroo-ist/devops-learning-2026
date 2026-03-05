#!/bin/bash

# ─────────────────────────────────────────────────────────────
# DevOps Learning V3 — Automated Setup Script
# Runs once automatically during EC2 instance boot (User Data)
# ─────────────────────────────────────────────────────────────

# Stop script immediately if any command fails
set -e

# Redirect all output (stdout + stderr) to a log file
# tee writes to the file AND keeps output in the terminal
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting setup $(date) ==="

# ─────────────────────────────────────────────────────────────
# 1. UPDATE SYSTEM
# Fetches the latest package list and upgrades installed packages
# Ensures the instance doesn't start with known vulnerabilities
# ─────────────────────────────────────────────────────────────
echo "=== Updating system ==="
apt-get update
apt-get upgrade -y

# ─────────────────────────────────────────────────────────────
# 2. INSTALL DOCKER
# Downloads and runs Docker's official install script
# Adds the ubuntu user to the docker group so it can run
# docker commands without sudo
# ─────────────────────────────────────────────────────────────
echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# ─────────────────────────────────────────────────────────────
# 3. INSTALL DEPENDENCIES
# git        — Clone the repository from GitHub
# nginx      — Reverse proxy (handles port 80/443, forwards to Docker)
# certbot    — Generates free SSL certificates (Let's Encrypt)
# python3-certbot-nginx — Certbot plugin that auto-configures Nginx for SSL
# fail2ban   — Monitors logs and auto-bans IPs on brute-force attempts
# ufw        — Uncomplicated Firewall (second layer of defense)
# ─────────────────────────────────────────────────────────────
echo "=== Installing dependencies ==="
apt-get install -y \
  git \
  nginx \
  certbot \
  python3-certbot-nginx \
  fail2ban \
  ufw

# ─────────────────────────────────────────────────────────────
# 4. CONFIGURE FIREWALL (UFW)
# Only opens the ports that need external access:
#   22  — SSH (manage the server)
#   80  — HTTP (Nginx, will redirect to HTTPS)
#   443 — HTTPS (Nginx, serves the site with SSL)
# Port 8080 (Docker) stays closed — it's internal only,
# accessed by Nginx via localhost, never exposed to the internet
# ─────────────────────────────────────────────────────────────
echo "=== Configuring UFW ==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
# --force skips the interactive confirmation prompt
# (required because this script runs without a user)
ufw --force enable

# ─────────────────────────────────────────────────────────────
# 5. CONFIGURE FAIL2BAN
# Protects SSH from brute-force attacks by monitoring auth logs
# and automatically banning IPs after repeated failed attempts
#   bantime  = 3600  — Ban duration: 1 hour (in seconds)
#   findtime = 600   — Detection window: 10 minutes (in seconds)
#   maxretry = 3     — Max failed attempts before ban
# ─────────────────────────────────────────────────────────────
echo "=== Configuring Fail2ban ==="
# Heredoc: writes everything between <<EOF and EOF directly into the file
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
EOF
# Restart to load the new configuration
systemctl restart fail2ban

# ─────────────────────────────────────────────────────────────
# 6. CLONE REPOSITORY
# Runs as the ubuntu user (not root) so that cloned files
# have the correct ownership. If cloned as root, the ubuntu
# user wouldn't have permission to read/edit them later.
# ─────────────────────────────────────────────────────────────
echo "=== Cloning repository ==="
cd /home/ubuntu
su - ubuntu -c "git clone https://github.com/jvcastroo-ist/devops-learning-2026.git"

# ─────────────────────────────────────────────────────────────
# 7. BUILD DOCKER IMAGE
# Reads the Dockerfile from the cloned repo and builds the image
# The image is saved locally on the instance
# && ensures docker build only runs if cd succeeds
# ─────────────────────────────────────────────────────────────
echo "=== Building Docker image ==="
su - ubuntu -c "cd /home/ubuntu/devops-learning-2026 && docker build -t portfolio ."

# ─────────────────────────────────────────────────────────────
# 8. CONFIGURE NGINX (Reverse Proxy)
# Sets up Nginx to receive requests on port 80 and forward
# them to the Docker container on port 8080 (proxy_pass)
#
# Key headers explained:
#   X-Real-IP          — Passes the actual client IP to the backend
#   X-Forwarded-For    — Maintains a chain of IPs through proxies
#   X-Forwarded-Proto  — Tells the backend if the client used http/https
#   Upgrade/Connection — Required for WebSocket support
#   Host               — Passes the original domain (not localhost)
#
# Note: <<'EOF' uses single quotes to prevent bash from
# interpreting Nginx variables (like $http_upgrade) as bash variables
#
# After SSL is set up with certbot, it will automatically modify
# this file to add port 443 and the HTTP → HTTPS redirect
# ─────────────────────────────────────────────────────────────
echo "=== Configuring Nginx ==="
cat > /etc/nginx/sites-available/portfolio <<'EOF'
server {
    listen 80;
    server_name joaovitordev.site www.joaovitordev.site;

    location / {
        # Forward all requests to the Docker container
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';

        # Pass original request information to the backend
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Create symlink so Nginx loads this config (only reads from sites-enabled)
ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
# Remove default config to avoid port conflicts
rm -f /etc/nginx/sites-enabled/default
# Test config first (-t), only restart if test passes (&&)
nginx -t && systemctl restart nginx

# ─────────────────────────────────────────────────────────────
# 9. RUN DOCKER CONTAINER
# Starts the portfolio application with resource limits:
#   --memory='400m'        — 400MB RAM cap (prevents memory leaks
#                            from crashing the whole instance)
#   --cpus='0.5'           — 50% of one vCPU (leaves resources
#                            for Nginx, Fail2ban, etc.)
#   --restart unless-stopped — Auto-restarts on crash or reboot,
#                              except if manually stopped
#   -p 8080:80             — Maps host port 8080 to container port 80
#                            (Nginx forwards requests here)
# ─────────────────────────────────────────────────────────────
echo "=== Starting Docker container ==="
su - ubuntu -c "docker run -d \
  --name portfolio \
  --restart unless-stopped \
  --memory='400m' \
  --cpus='0.5' \
  -p 8080:80 \
  portfolio"

# ─────────────────────────────────────────────────────────────
# SETUP COMPLETE
# What still needs to be done manually:
#   1. Point DNS (Namecheap A records) to this instance's IP
#   2. Wait for DNS propagation (5-30 min)
#   3. SSH in and run:
#        sudo certbot --nginx -d joaovitordev.site -d www.joaovitordev.site
# ─────────────────────────────────────────────────────────────
echo "=== Setup complete! $(date) ==="
