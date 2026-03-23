# DevOps Learning Journey 2026

Hands-on project to demonstrate DevOps skills by building, deploying, and fully automating a web portfolio — from a static HTML site to a production-ready automated pipeline.

## 🎯 Objective

Learn and demonstrate essential DevOps skills by building a real project from scratch, including:

- Containerization with Docker
- Cloud Computing (AWS EC2)
- Infrastructure as Code (Terraform)
- CI/CD Pipeline (GitHub Actions)
- Security hardening (Fail2ban, UFW, SSH keys)
- Automation and scripting

## 🏗️ Architecture

```
[GitHub] → [GitHub Actions] → [Docker Hub] → [AWS EC2]
    ↓               ↓                ↓             ↓
  Code        Build + Cache       Registry     Auto Deploy
              (~30s builds)    (SHA + latest)  via SSH
```

**Infrastructure detail:**
```
Terraform manages:
  └── Security Group (ports 22, 80, 443)
  └── EC2 Instance (Ubuntu 24.04, t3.micro)
  └── Elastic IP (fixed public IP, survives recreates)
       └── User Data script runs on first boot:
            ├── Docker, Nginx, Certbot, Fail2ban, UFW
            ├── Firewall configuration
            ├── GitHub repo clone
            ├── Docker image build
            └── Container deployment
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | HTML/CSS |
| **Web Server** | Nginx (reverse proxy → Docker container) |
| **Containerization** | Docker |
| **Cloud** | AWS (EC2, Elastic IP, Security Groups) |
| **IaC** | Terraform (8 .tf files) |
| **CI/CD** | GitHub Actions |
| **Registry** | Docker Hub |
| **Security** | Fail2ban, UFW, SSH key auth, IAM least-privilege |
| **SSL** | Let's Encrypt (Certbot) |
| **Version Control** | Git/GitHub |

## 📋 Project Phases

### ✅ Phase 1: Containerization (Week 1)
- Static site created (HTML/CSS, generated with Claude)
- Dockerfile written using `nginx:alpine` as base
- Container running and tested locally
- `.dockerignore` configured to keep images lean

### ✅ Phase 2: Manual Cloud Deploy (Week 2)
- AWS account configured with IAM user (no root credentials)
- EC2 instance provisioned manually
- Site deployed and publicly accessible via HTTP
- DNS configured (Namecheap → EC2 IP)
- SSL certificate generated with Certbot

### ✅ Phase 3: Infrastructure as Code (Week 3)
- Full infrastructure migrated from manual clicks to Terraform
- **8 Terraform files** covering: providers, variables, data sources, networking, compute, outputs
- **Elastic IP** implemented — fixed public IP that survives `terraform destroy` / `apply` cycles
- **User Data script** bootstraps the entire server automatically on first boot
- Infrastructure reproducible in ~5 minutes with a single command:
  ```bash
  terraform apply
  ```
- Solved region migration, AMI portability (data sources vs hardcoded IDs), and state management

### ✅ Phase 4: CI/CD Pipeline (Week 4)
- Full CI/CD pipeline via GitHub Actions
- **Build cache** implemented with Docker Buildx → 70% faster builds (2min → 30s)
- Images tagged with both `latest` and short SHA (`git sha | cut -c1-7`)
- Automated SSH deployment to EC2 on every push to `main`
- 5 secrets managed securely (Docker Hub token, EC2 host, SSH key, etc.)
- Idempotent deploy script (handles existing containers gracefully)
- **Result:** `git push` → site updated in ~2 minutes, zero manual steps

## 📊 Evolution Over 4 Weeks

| | Week 1-2 | Week 3 | Week 4 |
|-|----------|--------|--------|
| **Infrastructure** | Manual clicks | `terraform apply` | Same |
| **Deploy** | Manual SSH | Manual SSH | `git push` |
| **Time to deploy** | 1-2 hours | 15-20 min | **~2 min** ✅ |
| **Reproducibility** | Written docs | Executable code | Fully automated |

## 🔒 Security Practices

- IAM user (`terraform-admin`) for programmatic access — root account never used day-to-day
- MFA enabled on root account
- SSH key authentication only (no passwords)
- Fail2ban configured: IP banned after 3 failed SSH attempts
- UFW firewall: only ports 22, 80, 443 open
- Secrets stored in GitHub Actions secrets, never in code
- `.gitignore` prevents committing `.tfstate`, `.pem`, `.tfvars`

## 🔧 Key Problems Solved

- **Terraform region migration** — state file mismatch when changing AWS region; solved with clean state reset
- **AMI portability** — replaced hardcoded AMI IDs with `data "aws_ami"` source for any-region compatibility
- **SSH in CI/CD heredoc** — GitHub Actions secrets not expanding inside SSH; fixed by pre-assigning to shell vars
- **Container name conflicts on redeploy** — `docker rm -f container 2>/dev/null || true` pattern
- **Build cache invalidation** — understood layer caching behavior; Dockerfile changes correctly bust cache

## 🔗 Links

- 🌐 [Live Site](https://www.joaovitordev.site)
- 💼 [LinkedIn](https://www.linkedin.com/in/jo%C3%A3o-vitor-castro-silva-379972254/)

## 📖 Documentation

- [Manual Deploy Guide](docs/manual-deploy.md)
- [Terraform Guide](docs/terraform-guide.md)
- [CI/CD Pipeline](docs/cicd-pipeline.md)

## 📚 Study Resources

- [Docker Documentation](https://docs.docker.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [HashiCorp AWS Get Started](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)

---

**Status**: ✅ Phase 1-4 complete (January 2026)  
**Goal**: Job-ready for Junior DevOps position by July 2026  
**Total study time**: ~65 hours over 4 weeks
