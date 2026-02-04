# 🚀 Week 3 - Infrastructure as Code (Terraform)

**Objective:** Automate Week 2 infrastructure using Terraform — reproducible with a single command.

**Date:** January 20-24, 2026

---

## 🎯 Results Achieved

✅ **Terraform fundamentals** learned (providers, resources, data sources, variables, outputs)  
✅ **IAM User** created for secure API access  
✅ **AWS CLI** configured  
✅ **First EC2** created via Terraform  
✅ **Complete infrastructure** coded (8 .tf files)  
✅ **User Data script** for automated setup  
✅ **Elastic IP** implemented (fixed public IP)  
✅ **Full automation** — server ready in ~5 minutes  

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────┐
│  TERRAFORM FILES (Infrastructure as Code)   │
│  • providers.tf  → AWS config               │
│  • variables.tf  → Input variables          │
│  • data.tf       → AMI lookup               │
│  • network.tf    → Security Group           │
│  • compute.tf    → EC2 + Elastic IP         │
│  • outputs.tf    → Display info             │
│  • user-data.sh  → Setup script             │
└──────────────────────────────────────────────┘
                   ↓
         terraform apply (1 command)
                   ↓
┌──────────────────────────────────────────────┐
│  AWS INFRASTRUCTURE                          │
│  • Security Group (ports 22, 80, 443)        │
│  • Elastic IP (fixed, survives recreates)    │
│  • EC2 Instance (Ubuntu 24.04, t3.micro)     │
│    └─ User Data runs automatically:          │
│       1. Install Docker, Nginx, Certbot      │
│       2. Configure firewall (UFW)            │
│       3. Configure Fail2ban                  │
│       4. Clone GitHub repo                   │
│       5. Build Docker image                  │
│       6. Configure Nginx reverse proxy       │
│       7. Run Docker container                │
└──────────────────────────────────────────────┘
```

---

## 📋 Day-by-Day Summary

### **Day 1-2: Learning Phase**

**Resources studied:**
- Terraform in 100 Seconds (Fireship)
- Official HashiCorp AWS Get Started Tutorial
- TechWorld with Nana tutorials

**Key concepts:**
- **Infrastructure as Code** — infrastructure defined in files, not manual clicks
- **Declarative** — describe desired state, Terraform figures out how
- **State file** — Terraform's memory of current infrastructure
- **Workflow:** `init` → `plan` → `apply` → `destroy`

**IAM User Setup:**
- Created `terraform-admin` user (best practice — never use root)
- Generated Access Keys for programmatic access
- Enabled MFA on root account
- Configured AWS CLI: `aws configure`

**First Terraform code:**
```hcl
provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  tags = {
    Name = "learn-terraform"
  }
}
```

Commands:
```bash
terraform init    # Download provider plugins
terraform plan    # Preview changes
terraform apply   # Create infrastructure
```

✅ **Result:** First EC2 instance created via code!

---

### **Day 3-4: Full Infrastructure**

**Challenge:** Convert all Week 2 infrastructure to Terraform.

**Created files:**
- `providers.tf` — AWS provider configuration
- `variables.tf` — All configurable values (instance type, domain, etc)
- `data.tf` — AMI lookup (auto-finds latest Ubuntu for any region)
- `network.tf` — Security Group with ports 22, 80, 443
- `compute.tf` — EC2 instance + Elastic IP + User Data
- `outputs.tf` — Useful info (IP, SSH command, DNS settings)
- `user-data.sh` — Bootstrap script (runs on first boot)
- `.gitignore` — Prevent committing secrets

**Key additions:**

**Elastic IP (fixed public IP):**
```hcl
resource "aws_eip" "portfolio_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "portfolio_eip_assoc" {
  instance_id   = aws_instance.portfolio_server.id
  allocation_id = aws_eip.portfolio_eip.id
}
```

**User Data with variable injection:**
```hcl
user_data = templatefile("user-data.sh", {
  github_repo     = var.github_repo,
  domain          = var.domain,
  docker_image    = var.docker_image_name,
  # ... more variables
})
```

**User Data script automated:**
- System updates
- Docker installation
- Nginx, Certbot, Fail2ban, UFW installation
- Firewall configuration
- Repository clone
- Docker image build
- Nginx reverse proxy setup
- Container deployment with resource limits

✅ **Result:** Complete infrastructure reproducible with `terraform apply`!

---

### **Day 5: Documentation & Testing**

- Created comprehensive documentation (English + Portuguese)
- Tested destroy → recreate cycle
- Verified Elastic IP persistence
- Documented all commands and troubleshooting

---

## 🔧 Problems Solved

### **Problem 1: Region Migration**

**Issue:** Changed region from `us-west-2` to `eu-west-2`, but `terraform destroy` said "No changes."

**Cause:** State file tracked instance in old region. Terraform looked in new region, found nothing.

**Solution:** 
```bash
# Clean slate approach
rm -f terraform.tfstate terraform.tfstate.backup
terraform apply
```

**Lesson:** Terraform doesn't "move" resources between regions — it destroys in one and creates in another.

---

### **Problem 2: AMI IDs are Region-Specific**

**Issue:** Hardcoded AMI ID didn't exist in new region.

**Solution:** Use data source (auto-finds correct AMI for any region):
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*"]
  }
}
```

**Lesson:** Never hardcode AMI IDs — use data sources for portability.

---

### **Problem 3: When to Run `terraform init`?**

**Must run when:**
- First time in project
- Added/changed provider
- Changed provider version
- Added modules
- Deleted `.terraform/` folder

**Don't need when:**
- Changed resources
- Changed variables/outputs
- Changed resource attributes

**Lesson:** `init` sets up environment (downloads plugins). It's idempotent (safe to run multiple times).

---

## 🔑 Key Learnings

### **Terraform Workflow**
```
Write .tf files
    ↓
terraform init (download plugins)
    ↓
terraform plan (preview changes)
    ↓
terraform apply (execute changes)
    ↓
Infrastructure created!
```

### **State File**
- Terraform's "memory" of current infrastructure
- **Never commit to Git** (contains sensitive data)
- In production: use Remote State (S3 + DynamoDB)
- Local state is OK for learning

### **Data Sources vs Resources**
- **Data Source** — query existing things (e.g., find AMI)
- **Resource** — create/manage things (e.g., create EC2)

### **Variables**
```hcl
variable "instance_type" {
  default = "t3.micro"
}

resource "aws_instance" "web" {
  instance_type = var.instance_type  # Use variable
}
```

### **Outputs**
```hcl
output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
```

After apply, shows useful info without digging through console.

---

## 🎓 IAM Best Practices

**Never use Root User for daily work:**
- ❌ Root = full account control (billing, account closure, everything)
- ✅ IAM User = specific permissions, can be limited

**IAM User created:**
- Name: `terraform-admin`
- Permissions: AdministratorAccess (for learning)
- Access Type: Programmatic (Access Key + Secret Key)
- MFA enabled on root account

**AWS CLI configuration:**
```bash
aws configure
# Stores credentials in ~/.aws/credentials
# Terraform automatically uses these
```

---

## 📦 Git + Terraform

### **What to commit:**
✅ `*.tf` files  
✅ `user-data.sh`  
✅ `.gitignore`  
✅ `README.md`  

### **Never commit:**
❌ `.terraform/` (plugins, regenerated)  
❌ `*.tfstate` (sensitive data)  
❌ `*.tfvars` (may contain secrets)  
❌ `*.pem` (SSH keys)  

### **.gitignore:**
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
*.pem
.aws/
```

---

## 🚀 User Data Script Highlights

**What it does:**
```bash
#!/bin/bash
set -e  # Exit on any error
exec > >(tee /var/log/user-data.log)  # Log everything

# 1. Update system
apt-get update && apt-get upgrade -y

# 2. Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu

# 3. Install dependencies (Nginx, Certbot, Fail2ban, UFW)
apt-get install -y git nginx certbot python3-certbot-nginx fail2ban ufw

# 4. Configure firewall
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw --force enable

# 5. Configure Fail2ban (ban after 3 SSH failures)
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
maxretry = 3
[sshd]
enabled = true
EOF

# 6. Clone repo, build Docker image
git clone ${github_repo}
docker build -t ${docker_image_name} .

# 7. Configure Nginx (reverse proxy 80 → 8080)
cat > /etc/nginx/sites-available/portfolio <<'EOF'
server {
    listen 80;
    server_name ${domain};
    location / {
        proxy_pass http://localhost:8080;
        # ... proxy headers
    }
}
EOF

# 8. Run Docker container with resource limits
docker run -d \
  --name ${docker_container_name} \
  --restart unless-stopped \
  --memory='400m' \
  --cpus='0.5' \
  -p 8080:80 \
  ${docker_image_name}
```

**Check log:** `ssh ubuntu@IP 'sudo cat /var/log/user-data.log'`

---

## 📊 Useful Commands

### **Terraform**
```bash
terraform init              # Download plugins
terraform plan              # Preview changes
terraform apply             # Execute changes
terraform destroy           # Destroy all resources
terraform show              # Show current state
terraform output            # Show outputs
terraform output -raw ip    # Get output value (no quotes)
terraform console           # Interactive testing
```

### **AWS CLI**
```bash
aws sts get-caller-identity  # Verify credentials
aws ec2 describe-instances --region eu-west-2
aws ec2 describe-images --owners 099720109477  # Find AMIs
```

### **SSH**
```bash
ssh -i key.pem ubuntu@$(terraform output -raw elastic_ip)
ssh ubuntu@IP 'sudo tail -f /var/log/user-data.log'  # Watch setup
```

---

## 🎯 What Still Requires Manual Steps

After `terraform apply` completes:

**1. Point DNS to Elastic IP**
- Namecheap → Advanced DNS
- A Record: `@` → Elastic IP
- A Record: `www` → Elastic IP

**2. Generate SSL Certificate**
```bash
ssh ubuntu@ELASTIC_IP
sudo certbot --nginx -d joaovitordev.site -d www.joaovitordev.site
```

**Why manual:**
- Certbot needs DNS already pointing to instance
- Let's Encrypt verifies domain ownership
- Has rate limits (can't retry infinitely)

**Total time:** ~10 minutes (5 min User Data + 5 min DNS + SSL)

---

## 📈 Progress: Week 2 vs Week 3

| Aspect | Week 2 | Week 3 |
|--------|--------|--------|
| **Infrastructure** | Manual clicks | Single command |
| **Time to recreate** | 2-3 hours | 5 minutes |
| **Reproducibility** | Written docs | Executable code |
| **Server setup** | Manual SSH | Automated script |
| **IP changes** | Update DNS every time | Elastic IP (once) |

---

## 🎓 Skills Acquired

**Terraform:**
- Infrastructure as Code principles
- Providers, resources, data sources
- Variables and outputs
- State management
- `templatefile()` for dynamic content

**AWS:**
- IAM users vs root
- AWS CLI configuration
- Elastic IP (static public IP)
- User Data scripts

**DevOps:**
- Automation over manual work
- Infrastructure reproducibility
- Separation of code and secrets
- Git best practices for IaC

**Security:**
- Never use root credentials
- SSH keys vs passwords
- Multi-factor authentication
- Secrets management

---

## 💡 Key Insights

**Infrastructure as Code is a mindset shift:**
- From "how do I make this work?"
- To "how do I make this reproducible?"

**Automation saves time (eventually):**
- First time: slower than manual
- Second time: break-even
- Third+ times: massive time savings

**State management is critical:**
- Terraform's "memory" of infrastructure
- Must be protected (never commit)
- In production: remote state is essential

---

## 🚀 Next Steps (Week 4: CI/CD Pipeline)

**Objective:** Automatic deployment on every commit — full automation from code to production.

**Plan:**

**Day 1-2: GitHub Actions Basics**
- [ ] Study GitHub Actions fundamentals
- [ ] Create first workflow that builds Docker image
- [ ] Test workflow triggers on push

**Day 3-4: Complete CI/CD Pipeline**
- [ ] Expand workflow to push image to Docker Hub
- [ ] Connect to EC2 via SSH in workflow
- [ ] Pull new image and restart container automatically
- [ ] Handle secrets securely (Docker Hub credentials, SSH keys)

**Day 5: Testing & Documentation**
- [ ] Test complete pipeline: commit → build → deploy
- [ ] Document CI/CD flow with diagrams
- [ ] Verify zero-downtime deployment
- [ ] 🎉 Celebrate: End-to-end automation complete!

**Week 4 Deliverable:** Working CI/CD pipeline (GitHub Actions → Docker Hub → EC2)

**Current limitations (will be solved Week 4):**
- ❌ Manual `docker build` after code changes
- ❌ Manual SSH to pull new images
- ❌ Manual container restarts
- ✅ After Week 4: `git push` = automatic production deployment

---

## 📝 Final Deliverables

✅ 8 Terraform files  
✅ User Data automation script  
✅ Complete documentation (EN + PT)  
✅ .gitignore configuration  
✅ Working infrastructure (destroy → recreate in 5 min)  

**Lines of Code:** ~400 (Terraform + Bash)  
**Study Time:** ~20 hours  
**Professional Level:** Mid-level DevOps  

---

**Week 3 Complete! From manual deployment to fully automated Infrastructure as Code.** 🎉
