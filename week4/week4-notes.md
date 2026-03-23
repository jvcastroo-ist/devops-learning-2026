# 🚀 Week 4 - CI/CD Pipeline (GitHub Actions)

**Objective:** Automate deployment on every commit — `git push` → site updated automatically.

**Date:** January 27-31, 2026

---

## 🎯 Results Achieved

✅ **Complete CI/CD pipeline** — commit → build → push → deploy (fully automated)  
✅ **GitHub Actions cache** — 70% faster builds (2min → 30s)  
✅ **SSH deployment** — manual approach for full control  
✅ **Secrets management** — 5 secrets configured securely  
✅ **End-to-end automation** — site updates in ~2 minutes  

---

## 🏗️ Pipeline Flow

```
git push → GitHub Actions:
  1. Build Docker image (with cache)
  2. Push to Docker Hub (latest + SHA tag)
  3. SSH to EC2
  4. Pull new image
  5. Restart container
  
Result: Site updated automatically in ~2min
```

---

## 📋 Week Summary

### **Day 1-2: GitHub Actions Basics**

**Learned:**
- Workflow structure: `name` → `on` → `jobs` → `steps`
- `uses:` for actions, `run:` for commands
- Secrets for sensitive data
- Built first automated Docker build

**Key workflow structure:**
```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t image .
```

---

### **Day 3: Docker Hub Integration**

**Setup:**
- Created Docker Hub Access Token
- Configured secrets: `DOCKER_USERNAME`, `DOCKERHUB_TOKEN`
- Implemented automated push with 2 tags: `latest` and `${{ github.sha }}`

**Result:** Images automatically pushed to Docker Hub on every commit.

---

### **Day 4: EC2 Deployment**

**Secrets added:**
- `EC2_HOST` (Elastic IP)
- `EC2_USER` (ubuntu)
- `EC2_SSH_KEY` (complete .pem file content)

**Deployment via SSH (manual approach):**
```yaml
- name: Deploy to EC2
  run: |
    ssh -i ~/.ssh/deploy_key user@host bash << EOF
      docker pull username/portfolio:latest
      docker rm -f portfolio
      docker run -d --name portfolio -p 8080:80 username/portfolio:latest
    EOF
```

**Why manual SSH?** Full control, transparent, easy to debug.

---

### **Day 5: Build Cache**

**Implemented GitHub Actions cache:**
```yaml
- run: docker buildx create --use --name mybuilder
- run: |
    docker buildx build \
      --cache-from type=gha \
      --cache-to type=gha,mode=max \
      --load .
```

**Results:**
- First build: ~2min (creates cache)
- Subsequent builds: ~30s (uses cache)
- **70% faster!**

---

## 🔧 Main Problems Solved

**1. Variables in SSH heredoc**
- **Problem:** `${{ secrets.VAR }}` didn't expand inside SSH
- **Solution:** Define vars before SSH: `VAR="${{ secrets.VAR }}"`, then use `$VAR` in heredoc

**2. SSH permissions**
- **Problem:** Permission denied
- **Solution:** `chmod 600 ~/.ssh/deploy_key` (SSH requires this)

**3. Container name conflicts**
- **Problem:** Second deploy failed (container exists)
- **Solution:** `docker rm -f portfolio 2>/dev/null || true` (idempotent)

**4. Cache invalidation**
- **Problem:** Dockerfile change → cache doesn't work
- **Explanation:** Expected behavior (any Dockerfile change invalidates all layers)

**5. Long SHA tags**
- **Problem:** 40-char tags hard to read
- **Solution:** `SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)`

---

## 🔑 Key Concepts

### **GitHub Actions Structure**
```yaml
name: Workflow Name
on: [push]                    # Trigger
jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: action@v4       # Pre-built action
      - run: command          # Shell command
```

### **Important Variables**
- `${{ github.sha }}` - commit hash (unique per commit)
- `${{ github.actor }}` - who triggered
- `${{ secrets.NAME }}` - encrypted secrets
- `${{ env.VAR }}` - environment variables

### **SSH in CI/CD**
```bash
# Setup
mkdir -p ~/.ssh
echo "${{ secrets.SSH_KEY }}" > ~/.ssh/key
chmod 600 ~/.ssh/key

# Execute remotely
ssh -i ~/.ssh/key user@host bash << EOF
  commands here
EOF
```

### **Docker Buildx Cache**
```bash
docker buildx build \
  --cache-from type=gha \      # Import cache
  --cache-to type=gha,mode=max \  # Export cache
  --push \                     # Push directly (faster than --load)
  .
```

### **Error Handling Patterns**
```bash
command 2>/dev/null           # Suppress errors
command || true               # Ignore failures
docker rm -f container        # Force (stops + removes)
```

---

## 📊 Performance Metrics

**Build times:**
- First build: 2min (creating cache)
- Code change: 30-45s (using cache) ✅
- Dockerfile change: 2min (cache invalidated)

**Full pipeline:** ~2min (checkout → build → push → deploy)

**Compared to manual:** Manual = 15-20min | Automated = 2min | **90% faster** 🚀

---

## 📈 Progress Summary

| Week | Infrastructure | Deployment | Time to Deploy |
|------|---------------|------------|----------------|
| 1-2 | Manual | Manual | 1-2 hours |
| 3 | Automated (Terraform) | Manual | 15-20 min |
| 4 | Automated (Terraform) | **Automated (CI/CD)** | **2 min** ✅ |

---

## 🎓 Skills Acquired

- GitHub Actions (workflows, jobs, secrets)
- Docker Buildx & layer caching
- SSH automation in CI/CD
- Secrets management
- CI/CD pipeline design
- Deployment automation
- Error handling in automation

---

## 📝 Final Deliverables

✅ Complete CI/CD pipeline (`.github/workflows/build.yml`)  
✅ Automated builds with cache (70% faster)  
✅ Automated deployments (SSH-based)  
✅ 5 secrets configured securely  
✅ Zero manual deployment steps  

**Lines of Code:** ~100 (YAML + Bash)  
**Study Time:** ~25 hours  
**Professional Level:** Junior/Mid DevOps Engineer  

---

## 💡 Key Insight

**Complete automation achieved:**
```
Week 3: terraform apply → Infrastructure ready
Week 4: git push → Site updated

Combined: Full DevOps automation 🎉
```

**Time to deploy a change:**
- Before: 1-2 hours (manual everything)
- After: 2 minutes (automated everything)

---

**Week 4 Complete! Full CI/CD pipeline from commit to production.** 🚀
