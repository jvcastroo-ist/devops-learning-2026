# 🚀 Week 2 - Cloud and Manual Deployment

**Objective:** Deploy a website to the internet, for real, with professional infrastructure.

---

## 🎯 Achieved Results

✅ **Site live:** https://joaovitordev.site  
✅ **HTTPS configured** with free SSL certificate  
✅ **AWS Infrastructure** provisioned and configured  
✅ **Docker** running in production  
✅ **Security** implemented (Firewall, Fail2ban, Restricted SSH)  
✅ **DNS** configured with custom domain  

---

## 🏗️ Solution Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                             │
│                     (Global Users)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS/HTTP
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    AWS CLOUD (London)                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              SECURITY GROUP (Firewall)                │  │
│  │  • Port 22 (SSH) → My IP Only                         │  │
│  │  • Port 80 (HTTP) → 0.0.0.0/0                         │  │
│  │  • Port 443 (HTTPS) → 0.0.0.0/0                       │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          ↓                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          EC2 Instance (t3.micro)                      │  │
│  │          IP: 13.42.58.114                             │  │
│  │          OS: Ubuntu 24.04 LTS                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           UFW Firewall                          │  │  │
│  │  │  • Blocks everything by default                 │  │  │
│  │  │  • Allows: 22, 80, 443                          │  │  │
│  │  └─────────────────┬───────────────────────────────┘  │  │
│  │                    ↓                                   │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           Fail2ban                              │  │  │
│  │  │  • Bans IPs with 3+ failed attempts             │  │  │
│  │  │  • Ban duration: 1 hour                         │  │  │
│  │  └─────────────────┬───────────────────────────────┘  │  │
│  │                    ↓                                   │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Nginx (Reverse Proxy)                          │  │  │
│  │  │  • Port 80 → Redirects to HTTPS                 │  │  │
│  │  │  • Port 443 → SSL/TLS (Let's Encrypt)           │  │  │
│  │  │  • Proxy pass → Docker (port 8080)              │  │  │
│  │  └─────────────────┬───────────────────────────────┘  │  │
│  │                    ↓                                   │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Docker Container                               │  │  │
│  │  │  • Image: meu-portfolio                         │  │  │
│  │  │  • Port: 8080:80                                │  │  │
│  │  │  • Limits: 400MB RAM, 0.5 CPU                   │  │  │
│  │  │  • Restart: unless-stopped                      │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │     Application (Portfolio)               │  │  │  │
│  │  │  │     Nginx serving static files            │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         ↑
                         │
                   ┌─────┴─────┐
                   │    DNS    │
                   │  Namecheap│
                   │           │
                   │ A Record: │
                   │ @ → IP    │
                   │ www → IP  │
                   └───────────┘
```

---

## 📋 Day 1: AWS Initial Setup


1. **AWS Account Creation**
   - Free tier activated (6 months)
   - Selected region: EU (London) - eu-west-2

2. **Understanding Concepts**
   - EC2 (Elastic Compute Cloud)
   - AMI (Amazon Machine Image)
   - Instance Types (t2.micro vs t3.micro)
   - Security Groups (virtual firewall)
   - Key Pairs (SSH authentication)

### 💰 Costs and Free Tier

**Free Tier Limits:**
- EC2: 750 hours/month of t3.micro
- EBS: 30GB storage
- Data Transfer: First 100GB free

**Expected Monthly Costs:**
- EC2 Compute: $0.00 (free tier)
- EBS Storage (8GB): $0.00 (free tier)
- **Public IPv4: $3.60/month** ⚠️ (only unavoidable cost)
- Total: ~$3.60/month

---

## 📋 Day 2-3: Provisioning and Deployment

### 1. Key Pair Creation

```bash
# Created via AWS Console
# Name: devops-study-key
# Type: RSA
# Format: .pem

# Permission configuration
chmod 400 ~/.ssh/aws-keys/devops-study-key.pem
```

**Why permission 400?**
- `4` (owner) = read only
- `0` (group) = no permission
- `0` (others) = no permission
- SSH requires private keys to be restricted

---

### 2. Security Group Creation

**Name:** `devops-study-sg-v2`

**Inbound Rules:**

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | My IP | Restricted SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Public website |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Public SSL |

**Outbound Rules:**
- All traffic → 0.0.0.0/0 (default)

**Lessons Learned:**
- ✅ **Never** open SSH (port 22) to 0.0.0.0/0 in production
- ✅ Restricting to your IP dramatically increases security
- ✅ Security Group = first line of defense

---

### 3. EC2 Provisioning

**Specifications:**
```
Name: devops-study-v2
AMI: Ubuntu Server 24.04 LTS
Architecture: 64-bit (x86)
Instance Type: t3.micro (1 vCPU, 1GB RAM)
Storage: 8GB gp3
Key Pair: devops-study-key
Security Group: devops-study-sg-v2
Region: eu-west-2 (London)
```

---

### 4. SSH Connection with AWS server

```bash
# Base command
ssh -i ~/.ssh/aws-keys/devops-study-key.pem ubuntu@13.42.58.114
```

**Command Anatomy:**
- `ssh` - Secure Shell protocol
- `-i` - Identity file (private key)
- `ubuntu@` - Default user for Ubuntu AMI
- `IP` - Instance's public address

**Common Troubleshooting:**
- ❌ `Permission denied (publickey)` → Forgot to specify `ubuntu@` user
- ❌ `Connection timeout` → Security Group blocked or instance down
- ❌ `Permission denied` (file permission) → `chmod 400` on key

---

### 5. Docker Installation

```bash
# Quick method (official script)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker ubuntu
---

### 6. Repository Clone and Build

```bash
# Clone project
git clone https://github.com/jvcastroo-ist/portfolio-devops.git
cd portfolio-devops

# Build Docker image
docker build -t meu-portfolio .

# Verify created image
docker images
```

---

### 7. Container Deployment (with protections)

```bash
docker run -d \
  -p 8080:80 \
  --name meu-portfolio \
  --restart unless-stopped \
  --memory="400m" \
  --cpus="0.5" \
  meu-portfolio
```

**Flags Explained:**
- `-d` → Detached mode (background)
- `-p 8080:80` → Maps host port 8080 → container port 80
- `--name` → Friendly name for management
- `--restart unless-stopped` → Auto-restart (except if manually stopped)
- `--memory="400m"` → RAM limit (protects against memory leak)
- `--cpus="0.5"` → CPU limit (50% of 1 vCPU)

**Why port 8080?**
- Nginx will run on ports 80/443 (public)
- Docker runs internally on 8080
- Nginx proxies to Docker

---

## 📋 Day 4: Domain and HTTPS

### 1. Domain Purchase

**Provider:** Namecheap  
**Domain:** joaovitordev.site  
**Cost:** $1.98/year (.site extension)  
---

### 2. DNS Configuration

**Created Records (Namecheap → Advanced DNS):**

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A Record | @ | IP | Automatic |
| A Record | www | IP | Automatic |

**Propagation Time:**
- Minimum: 5-15 minutes
- Average: 1-2 hours
- Maximum: 24-48 hours (rare)

**Test Tools:**
```bash
# Verify DNS
nslookup joaovitordev.site
dig joaovitordev.site

# Online
https://www.whatsmydns.net
```

---

### 3. HTTPS Configuration with Let's Encrypt

#### 3.1. Certbot Installation

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

---

#### 3.2. SSL Certificate Generation

```bash
# Stop container (temporarily free port 80)
docker stop meu-portfolio

# Request certificate
sudo certbot certonly --standalone \
  -d joaovitordev.site \
  -d www.joaovitordev.site

# Answer:
# 1. Email: your@email.com
# 2. Terms: (A)gree
# 3. EFF: (N)o
```

**Certificates Generated at:**
```
/etc/letsencrypt/live/joaovitordev.site/fullchain.pem  (public)
/etc/letsencrypt/live/joaovitordev.site/privkey.pem    (private)
```

**Validity:** 90 days (automatic renewal configured)

---

#### 3.3. Nginx Installation

```bash
sudo apt install -y nginx
nginx -v
```

---

#### 3.4. Nginx Configuration

**File:** `/etc/nginx/sites-available/portfolio`

```nginx
# Redirects HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name joaovitordev.site www.joaovitordev.site;
    
    # Redirect everything to HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name joaovitordev.site www.joaovitordev.site;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/joaovitordev.site/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/joaovitordev.site/privkey.pem;

    # Recommended SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Proxy to Docker
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Activate Configuration:**
```bash
# Symbolic link
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/

# Remove default
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl restart nginx
```

---

#### 3.5. Adjust Docker Container

```bash
# Remove old container
docker rm meu-portfolio

# Create new on port 8080
docker run -d \
  -p 8080:80 \
  --name meu-portfolio \
  --restart unless-stopped \
  --memory="400m" \
  --cpus="0.5" \
  meu-portfolio
---

#### 3.6. Configure Automatic Renewal

**Initial Problem:** Certbot configured in `standalone` mode

**Solution:** Switch to `nginx` mode

```bash
# Edit configuration
sudo nvim /etc/letsencrypt/renewal/joaovitordev.site.conf

# Change:
# authenticator = standalone
# TO:
authenticator = nginx
installer = nginx

# Test renewal
sudo certbot renew --dry-run
```

**Expected Result:**
```
Congratulations, all simulated renewals succeeded!
```
---

### 4. SSL Security Tests

**SSL Labs Test:**
- URL: https://www.ssllabs.com/ssltest/
- Domain: joaovitordev.site
- **Result: A+** ✅
---

## 🛡️ Implemented Security

### 1. Fail2ban (Brute Force Protection)

**Installation:**
```bash
sudo apt install -y fail2ban
```

**Configuration:** `/etc/fail2ban/jail.local`

```ini
[DEFAULT]
bantime = 3600      # 1 hour ban
findtime = 600      # 10 minute window
maxretry = 3        # 3 attempts before ban

[sshd]
enabled = true
port = 22
```

**How it Works:**
1. Monitors logs: `/var/log/auth.log`
2. Detects pattern: "Failed password" (3x in 10 min)
3. Bans IP for 1 hour via iptables
---

### 2. UFW (Uncomplicated Firewall)

**Configuration:**
```bash
# Specific rules
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS

# Enable
sudo ufw --force enable

# Verify
sudo ufw status verbose
```

**Why UFW + Security Group?**
- **Security Group:** First line of defense (AWS)
- **UFW:** Second line (within instance)
- **Defense in Depth:** Multiple layers of protection

---

## 🔧 Troubleshooting (Problems Faced)

### Problem 1: Instance Crashed After 1 Minute Live

**Symptoms:**
- Site working initially
- After ~1 minute: no longer responds
- SSH won't connect
- Ping fails

**Probable Cause:**
- Bots/scanners attacking exposed server
- t3.micro (1GB RAM) couldn't handle it
- Memory leak or basic DDoS

**Solution:**
1. ✅ Terminate compromised instance
2. ✅ Create new with more restrictive Security Group
3. ✅ Implement Fail2ban
4. ✅ Add UFW firewall
5. ✅ Limit Docker container resources
6. ✅ SSH only from my IP

**Lesson Learned:**
- **Never** expose server without basic protections
- Implement security **BEFORE** going public
- t3.micro is sufficient **IF** well protected

---

### Problem 2: Public IP Changes on Instance Restart

**Symptoms:**
- Stop → Start instance = new IP
- DNS needs manual update
- SSH stops working (old IP)

**Cause:**
- Dynamic public IPs in EC2 (default)

**Temporary Solution:**
- Manually update DNS each change

**Definitive Solution (not implemented):**
- Use Elastic IP (fixed IP)
- ⚠️ **BUT** charges $3.60/month if instance stopped
- **Decision:** Accept dynamic IP for now

**Workaround:**
- Don't stop instance unnecessarily
- If stopped: note new IP and update DNS

---

### Problem 3: SSL Automatic Renewal Failing

**Symptoms:**
```bash
sudo certbot renew --dry-run
# Failed: Could not bind TCP port 80
```

**Cause:**
- Certbot configured in `standalone` mode
- Nginx running on port 80
- Port conflict

**Solution:**
```bash
# Edit configuration
sudo nvim /etc/letsencrypt/renewal/joaovitordev.site.conf

# Change:
authenticator = standalone
# TO:
authenticator = nginx
installer = nginx

# Save and test
sudo certbot renew --dry-run
# ✅ Success!
```

**Lesson Learned:**
- Certbot has specific plugins (nginx, apache, etc)
- Standalone mode = temporary server (not compatible with running Nginx)
- Nginx mode = perfect integration

---

### Problem 4: Container Stops After EC2 Reboot

**Symptoms:**
- After instance reboot
- Docker installed ✅
- Image exists ✅
- Container stopped ❌

**Cause:**
- Container not configured for automatic restart

**Solution:**
```bash
# Recreate container with --restart flag
docker run -d \
  --restart unless-stopped \
  ...
```

**Restart Policies:**
- `no` → Never restarts (default)
- `always` → Always restarts
- `unless-stopped` → Restarts except if manually stopped (best!)
- `on-failure` → Only restarts if crashes

---

## 📊 Useful Commands (Quick Reference)

### AWS/EC2

```bash
# SSH Connect
ssh -i ~/.ssh/aws-keys/devops-study-key.pem ubuntu@IP

# View available regions (AWS CLI)
aws ec2 describe-regions --output table
```

### Docker

```bash
# View running containers
docker ps

# View all (including stopped)
docker ps -a

# View images
docker images

# Container logs
docker logs meu-portfolio
docker logs -f meu-portfolio  # follow (real-time)

# Stop/Start/Restart
docker stop meu-portfolio
docker start meu-portfolio
docker restart meu-portfolio

# Remove container
docker rm meu-portfolio

# Remove image
docker rmi meu-portfolio

# Enter container (debug)
docker exec -it meu-portfolio sh

# Resource statistics
docker stats meu-portfolio

# Clean system (careful!)
docker system prune -a
```

### Nginx

```bash
# Test configuration
sudo nginx -t

# Reload (no downtime)
sudo nginx -s reload

# Restart
sudo systemctl restart nginx

# Status
sudo systemctl status nginx

# Logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View active configuration
cat /etc/nginx/sites-enabled/portfolio
```

### Certbot/SSL

```bash
# List certificates
sudo certbot certificates

# Renew manually
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run

# Force renewal (careful: rate limits!)
sudo certbot renew --force-renewal

# View renewal configuration
cat /etc/letsencrypt/renewal/joaovitordev.site.conf

# Logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Firewall/Security

```bash
# UFW
sudo ufw status verbose
sudo ufw enable
sudo ufw disable
sudo ufw allow 8080/tcp
sudo ufw deny from 123.45.67.89

# Fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip IP
sudo tail -f /var/log/fail2ban.log

# View active connections
sudo netstat -tulpn
sudo ss -tulpn
```

### System

```bash
# System resources
free -h           # Memory
df -h            # Disk
top              # Processes (press 'q' to exit)
htop             # Better than top (needs install)

# System logs
sudo journalctl -xe
sudo journalctl -u nginx
sudo journalctl -u docker
sudo journalctl -f  # Follow

# Restart services
sudo systemctl restart nginx
sudo systemctl restart docker

# View timers (SSL renewal, etc)
sudo systemctl list-timers
```

---

## 🎓 Knowledge Acquired

### Cloud Concepts

- ✅ **IaaS** (Infrastructure as a Service)
- ✅ **Regions and Availability Zones**
- ✅ **Security Groups** vs Traditional Firewalls
- ✅ **Elastic IPs** vs Dynamic IPs
- ✅ **Free Tier** and cost optimization

### Networking

- ✅ **DNS** (A records, propagation)
- ✅ **Ports** and mapping (80, 443, 8080)
- ✅ **Public vs Private IP**
- ✅ **Reverse Proxy** (Nginx → Docker)
- ✅ **SSL/TLS** and digital certificates

### Security

- ✅ **Key-based authentication** SSH
- ✅ **Layered Firewall** (SG + UFW)
- ✅ **Fail2ban** and intrusion detection
- ✅ **HTTPS** and encryption
- ✅ **HTTP Security Headers**
- ✅ **Principle of Least Privilege**

### Docker

- ✅ **Application containerization**
- ✅ **Port mapping** (-p flag)
- ✅ **Resource limits** (--memory, --cpus)
- ✅ **Restart policies**
- ✅ **Difference between image and container**
- ✅ **Logs and troubleshooting**

### DevOps Practices

- ✅ **Infrastructure as Code** (concepts)
- ✅ **Technical Documentation**
- ✅ **Systematic Troubleshooting**
- ✅ **Resource Monitoring**
- ✅ **Automation** (SSL renewal)

---
