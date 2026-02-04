# 📜 User Data Script — Detailed Explanation

## DevOps Learning V3 — Automated Infrastructure

---

## What is User Data?

When you create an EC2 instance via Terraform (or through the console), AWS allows you to pass an **initialization script**. This script runs **only once**, right after the instance is created, still during the boot process.

In Terraform, you pass this script like this:

```hcl
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = file("user-data.sh")  # ← Passes the script
}
```

AWS takes this script and executes it as `root` automatically. So you don't technically need `sudo` for everything — but it's good practice to keep it to make things explicit.

---

## Full Script

```bash
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting setup $(date) ==="

# ─── 1. Update system ────────────────────────────────
apt-get update
apt-get upgrade -y

# ─── 2. Install Docker ───────────────────────────────
echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# ─── 3. Install dependencies ─────────────────────────
echo "=== Installing dependencies ==="
apt-get install -y \
  git \
  nginx \
  certbot \
  python3-certbot-nginx \
  fail2ban \
  ufw

# ─── 4. Configure Firewall (UFW) ─────────────────────
echo "=== Configuring UFW ==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ─── 5. Configure Fail2ban ───────────────────────────
echo "=== Configuring Fail2ban ==="
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
EOF
systemctl restart fail2ban

# ─── 6. Clone repository ─────────────────────────────
echo "=== Cloning repository ==="
cd /home/ubuntu
su - ubuntu -c "git clone https://github.com/jvcastroo-ist/devops-learning-2026.git"

# ─── 7. Build Docker image ───────────────────────────
echo "=== Building Docker image ==="
su - ubuntu -c "docker build -t my-portfolio ."

# ─── 8. Configure Nginx ──────────────────────────────
echo "=== Configuring Nginx ==="
cat > /etc/nginx/sites-available/portfolio <<'EOF'
server {
    listen 80;
    server_name joaovitordev.site www.joaovitordev.site;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# ─── 9. Run Docker container ─────────────────────────
echo "=== Starting Docker container ==="
su - ubuntu -c "docker run -d \
  --name my-portfolio \
  --restart unless-stopped \
  --memory='400m' \
  --cpus='0.5' \
  -p 8080:80 \
  my-portfolio"

echo "=== Setup complete! $(date) ==="
```

---

## Breakdown — Part by Part

---

### Part 1 — Header and Logging

```bash
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log)
exec 2>&1
```

**`#!/bin/bash`** — Shebang. Tells the operating system that this file is a bash script. Without this line, the system doesn't know how to interpret the script.

**`set -e`** — Makes the script **stop immediately** if any command fails. Without it, the script would keep running even after errors, and you could end up with a partially configured environment without knowing. For example: if the Docker installation fails, without `set -e` the script would continue trying to build the Docker image and fail at an even more confusing point.

**`exec > >(tee /var/log/user-data.log)`** — Redirects all standard output (stdout) to a log file. `tee` writes to the file AND still keeps the output in the terminal. This is essential because User Data runs without an interactive terminal — without this log, you'd have no way to see what happened during initialization.

**`exec 2>&1`** — Redirects errors (stderr) to standard output (stdout). This way, errors also go to the log file. Without it, only success messages would appear in the log and errors would be lost.

**How to check afterwards:**
```bash
# SSH into the instance and view the log
sudo cat /var/log/user-data.log

# Or follow it in real time while it runs
sudo tail -f /var/log/user-data.log
```

---

### Part 2 — Update System

```bash
apt-get update
apt-get upgrade -y
```

**`apt-get update`** — Updates the list of available packages. It doesn't install anything — it only downloads the most recent list from the repositories. Without it, the system doesn't know what package versions exist.

**`apt-get upgrade -y`** — Updates all already-installed packages to their most recent versions. The `-y` automatically answers "yes" to all confirmations, because the script runs without human interaction.

**Why is this important?**
The Ubuntu AMI you use may have been published days or weeks ago. During that time, security patches may have been released. Updating at the start ensures the instance doesn't launch with known vulnerabilities.

---

### Part 3 — Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
```

**`curl -fsSL https://get.docker.com -o get-docker.sh`** — Downloads Docker's official installation script. The flags mean:
- `-f` — Fail silently on HTTP errors (doesn't show error page)
- `-s` — Silent mode (doesn't show progress bar)
- `-S` — Shows error even with `-s`
- `-L` — Follows redirects (important because the URL redirects)
- `-o` — Saves to a file with the specified name

**`sh get-docker.sh`** — Runs the installation script. Docker's script already knows how to detect the Linux distro and install the correct package versions.

**`usermod -aG docker ubuntu`** — Adds the `ubuntu` user to the `docker` group. Without this, you'd need to use `sudo` before every Docker command. The `-a` means "append" (don't replace other groups) and `-G` specifies the group.

**Why not just use `sudo docker` every time?**
It's possible, but in the real world nobody does that. Adding to the group is the standard and cleaner approach.

---

### Part 4 — Install Dependencies

```bash
apt-get install -y \
  git \
  nginx \
  certbot \
  python3-certbot-nginx \
  fail2ban \
  ufw
```

Installs all necessary programs at once. The `\` at the end of each line is just a line break in the script — to bash it's the same as a single command.

**`git`** — Version control system. Necessary to clone the GitHub repository where the portfolio code lives.

**`nginx`** — Web server that will function as a **reverse proxy**. It won't serve the application directly — it will receive requests on port 80/443 and forward them to the Docker container on port 8080. It's also the one that will handle SSL/HTTPS.

**`certbot`** — The official Let's Encrypt tool for generating free SSL certificates. Without it, there's no way to have HTTPS.

**`python3-certbot-nginx`** — Certbot plugin specific to Nginx. It allows Certbot to configure Nginx automatically when you generate the SSL certificate. Without this plugin, you'd have to configure SSL in Nginx manually.

**`fail2ban`** — Monitors system logs and **automatically bans** IPs that attempt brute-force attacks (many failed login attempts). You saw this in practice during week 2 when the instance crashed.

**`ufw`** — Uncomplicated Firewall. An additional firewall layer inside the instance. The AWS Security Group already blocks ports, but UFW adds a second layer of protection ("defense in depth").

---

### Part 5 — Configure Firewall (UFW)

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
```

**`ufw allow 22/tcp`** — Allows SSH traffic on port 22. Without this, you wouldn't be able to connect via SSH after creation.

**`ufw allow 80/tcp`** — Allows HTTP traffic on port 80. Nginx will listen on this port and redirect to HTTPS.

**`ufw allow 443/tcp`** — Allows HTTPS traffic on port 443. This is the port that will serve the site with SSL.

**`ufw --force enable`** — Activates the firewall. The `--force` flag is necessary because normally UFW asks for interactive confirmation ("this may disrupt current ssh connections"), and since the script runs without a user, we need to skip that confirmation.

**Why 22, 80, and 443 and not 8080?**
Port 8080 is internal — that's where Docker listens. But it doesn't need to be open to the outside world. The flow is: user accesses port 443 → Nginx → port 8080 (internal) → Docker. Port 8080 is never exposed directly.

---

### Part 6 — Configure Fail2ban

```bash
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
EOF
systemctl restart fail2ban
```

**`cat > /etc/fail2ban/jail.local <<EOF ... EOF`** — This is a **heredoc**. Everything between `<<EOF` and `EOF` is written directly to the file `/etc/fail2ban/jail.local`. It's like typing the content in nano, but automatically.

**`bantime = 3600`** — Ban duration in seconds. 3600 seconds = 1 hour. After 1 hour, the IP is automatically released.

**`findtime = 600`** — Time window that Fail2ban analyzes. 600 seconds = 10 minutes. It means: "if there are 3 failed attempts within 10 minutes, ban."

**`maxretry = 3`** — Maximum number of failed attempts before banning. Three attempts is a good balance — it doesn't ban for casual human error, but blocks automated attacks quickly.

**`[sshd] enabled = true`** — Activates protection specifically for the SSH service. Fail2ban analyzes the SSH logs (`/var/log/auth.log`) and applies the rules above.

**`systemctl restart fail2ban`** — Restarts the service to apply the new configurations. Without this, the configurations stay in the file but aren't loaded.

---

### Part 7 — Clone Repository

```bash
cd /home/ubuntu
su - ubuntu -c "git clone https://github.com/jvcastroo-ist/devops-learning-2026.git"
```

**`cd /home/ubuntu`** — Changes to the ubuntu user's home directory.

**`su - ubuntu -c "..."`** — Executes the command as the `ubuntu` user instead of `root`. This is important because:
- The home directory belongs to the `ubuntu` user
- The cloned files will have the correct ownership
- Docker will later be used by the `ubuntu` user

If you cloned as root, the files would have `root:root` ownership and the `ubuntu` user wouldn't have permission to edit them.

**`git clone https://...`** — Clones the full repository from GitHub. This brings the application code, the Dockerfile, and everything needed to do the build.

---

### Part 8 — Build Docker Image

```bash
su - ubuntu -c "docker build -t my-portfolio ."
```

**`cd /home/ubuntu/portfolio-devops`** — Enters the cloned repository folder.

**`&&`** — Runs the next command **only if the previous one succeeded**. If `cd` fails (directory doesn't exist), `docker build` won't run.

**`docker build -t my-portfolio .`** — Builds the Docker image:
- `docker build` — The build command
- `-t my-portfolio` — The `-t` stands for "tag". Sets the image name to `my-portfolio`
- `.` — Says that the build context is the current directory (where the Dockerfile is)

Docker will read the `Dockerfile` from the repository and create the image with all layers defined in it. This image is saved locally on the instance.

**Why not use `docker pull` instead of `build`?**
Because the image isn't published on any public registry. The code is on GitHub and the Dockerfile defines how to build it. If you eventually publish the image to Docker Hub or ECR, then you could use `pull`.

---

### Part 9 — Configure Nginx

```bash
cat > /etc/nginx/sites-available/portfolio <<'EOF'
server {
    listen 80;
    server_name joaovitordev.site www.joaovitordev.site;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
```

This block configures Nginx as a **reverse proxy**. Let's break down each part:

---

**`<<'EOF'` (with single quotes)**

Notice the single quotes around `'EOF'`. This prevents bash from interpreting variables inside the heredoc. Without the quotes, `$http_upgrade` would be treated as a bash variable and would probably end up empty. With the quotes, everything stays as literal text — and the variables belong to Nginx, not bash.

---

**`listen 80;`** — Nginx will listen on port 80 (HTTP). Later, when you run Certbot, it will modify this file automatically to add port 443 and the HTTP → HTTPS redirect.

---

**`server_name joaovitordev.site www.joaovitordev.site;`** — Defines which domains this configuration applies to. When a request comes in for `joaovitordev.site` or `www.joaovitordev.site`, this `server` block is used.

---

**`location / { ... }`** — Defines what happens with requests that arrive at the root (`/`). Since there's no more specific condition, this captures **all** requests.

---

**`proxy_pass http://localhost:8080;`** — This is the most important line. It forwards all requests to the Docker container running on port 8080. The user accesses port 80 → Nginx → port 8080 → Docker.

---

**`proxy_http_version 1.1;`** — Uses HTTP/1.1 for communication between Nginx and the backend. HTTP/1.1 supports persistent connections (keep-alive), which is more efficient than creating a new connection for each request.

---

**Headers:**

**`proxy_set_header Upgrade $http_upgrade;`** and **`proxy_set_header Connection 'upgrade';`** — Necessary for WebSockets. If your application uses WebSockets (real-time connections), these headers allow the protocol to be "upgraded" from HTTP to WebSocket through the proxy. Even if you don't use WebSockets right now, it's good practice to keep them.

**`proxy_set_header Host $host;`** — Passes the original domain of the request to the backend. Without this, the backend would see `localhost` instead of `joaovitordev.site`.

**`proxy_set_header X-Real-IP $remote_addr;`** — Passes the real IP of the user. Without this, the backend would see Nginx's IP (127.0.0.1) as if it were the client. Important for logs and security.

**`proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`** — Similar to the previous one, but maintains a chain of IPs. If there are multiple proxies, each one adds its IP to the list.

**`proxy_set_header X-Forwarded-Proto $scheme;`** — Tells the backend which protocol the user originally used (http or https). This is important because the backend only "sees" HTTP (port 8080), but the user may be accessing via HTTPS.

---

**`ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/`** — Creates a symbolic link (shortcut) from the `sites-enabled` folder pointing to the file in `sites-available`. Nginx only loads configurations that are in `sites-enabled`. Using a symbolic link instead of copying allows you to disable/enable sites without deleting the configuration.

**`rm -f /etc/nginx/sites-enabled/default`** — Removes Nginx's default configuration. If it stays active alongside yours, it can cause port conflicts.

**`nginx -t`** — Tests the configuration without restarting the service. If there's a syntax error, the command fails and (because of `&&`) the `systemctl restart` won't run, preventing Nginx from stopping with a broken configuration.

**`systemctl restart nginx`** — Restarts Nginx to load the new configuration.

---

### Part 10 — Run Docker Container

```bash
su - ubuntu -c "docker run -d \
  --name my-portfolio \
  --restart unless-stopped \
  --memory='400m' \
  --cpus='0.5' \
  -p 8080:80 \
  my-portfolio"
```

**`docker run`** — Creates and starts a container from the image that was built.

**`-d`** — Detached mode. The container runs in the background. Without this, the script would get stuck waiting for the container to finish and would never continue.

**`--name my-portfolio`** — Sets a name for the container. Without it, Docker would assign a random name. With a defined name, you can manage the container more easily: `docker stop my-portfolio`, `docker logs my-portfolio`, etc.

**`--restart unless-stopped`** — Automatic restart policy. The container will restart automatically if:
- It crashes due to an error
- The EC2 instance is rebooted

The exception is if you **manually** stop the container with `docker stop`. The other policies are:
- `no` — never restarts (default)
- `always` — always restarts, even if you manually stop it
- `on-failure` — only restarts if the container exits with an error code

**`--memory='400m'`** — RAM memory limit: 400 megabytes. Without a limit, a memory leak in the application could consume all the instance's RAM and bring down the entire system (like what happened in week 2). With the limit, if the container exceeds 400MB, Docker kills the process before it compromises the system.

**`--cpus='0.5'`** — CPU limit: 50% of one vCPU. Ensures the container doesn't consume all the processing capacity of the instance, leaving resources for Nginx, Fail2ban, and other services.

**`-p 8080:80`** — Port mapping: `host_port:container_port`. Port 8080 on the instance is mapped to port 80 inside the container. This means that when something accesses `localhost:8080` on the instance, it arrives at port 80 inside the container, which is where the application's web server is running.

**`my-portfolio`** — Name of the image that was built in part 8.

---

## Full Request Flow

```
User accesses https://joaovitordev.site
        ↓
    DNS resolves to the EC2 IP
        ↓
    Port 443 (HTTPS) — Security Group allows
        ↓
    UFW allows port 443
        ↓
    Nginx receives the request (port 443)
        ↓
    Nginx decrypts SSL (Let's Encrypt certificate)
        ↓
    Nginx forwards to localhost:8080 (proxy_pass)
        ↓
    Docker container receives on port 80 (internal)
        ↓
    Application returns the response
        ↓
    Nginx encrypts with SSL and returns to the user
```

---

## What this script does NOT do (manual steps)

After the script finishes, you still need to do two things manually:

**1. Point the DNS** — On Namecheap, create/update the A records pointing to the new instance's IP. If you use Elastic IP in Terraform, this only needs to be done once.

**2. Generate the SSL certificate** — Via SSH into the instance:
```bash
sudo certbot --nginx -d joaovitordev.site -d www.joaovitordev.site
```

This needs to be manual because Certbot needs the DNS to already be pointing to the instance before it can verify the domain's identity. If you try to generate the certificate before DNS is ready, Let's Encrypt will reject the request.

---

## How to Verify Everything Worked

```bash
# 1. View the full setup log
sudo cat /var/log/user-data.log

# 2. Check if Docker is running
docker ps

# 3. Check if Nginx is active
sudo systemctl status nginx

# 4. Test the application locally (without SSL yet)
curl http://localhost:8080

# 5. Test via domain (after DNS + SSL)
curl https://joaovitordev.site
```
