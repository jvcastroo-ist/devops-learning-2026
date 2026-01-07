# DevOps Learning Journey 2026

Projeto prático para demonstrar habilidades DevOps através da construção, deploy e automação de um portfolio web.

## 🎯 Objetivo

Aprender e demonstrar competências essenciais de DevOps construindo um projeto real do zero, incluindo:
- Containerização com Docker
- Infraestrutura como Código (Terraform)
- Cloud Computing (AWS)
- CI/CD (GitHub Actions)
- Automação e scripting

## 🏗️ Arquitetura
```
[GitHub] → [GitHub Actions] → [Docker Hub] → [AWS EC2]
    ↓           ↓                   ↓            ↓
  Código     Build/Test          Registry     Deploy
```

## 🛠️ Stack Tecnológico

- **Frontend**: HTML/CSS/JavaScript
- **Web Server**: Nginx
- **Containerização**: Docker
- **Cloud Provider**: AWS (EC2, VPC, Security Groups)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Controle de Versão**: Git/GitHub

## 📋 Progresso do Projeto

### ✅ Fase 1: Setup Inicial (Semana 1)
- [x] Repositório criado
- [x] Ambiente local configurado
- [ ] Site estático criado
- [ ] Dockerfile criado
- [ ] Container rodando localmente

### 🔄 Fase 2: Deploy Manual (Semana 2)
- [ ] Conta AWS configurada
- [ ] EC2 provisionada
- [ ] Deploy manual realizado
- [ ] Site acessível publicamente
- [ ] DNS configurado

### 📦 Fase 3: Infraestrutura como Código (Semana 3)
- [ ] Terraform instalado
- [ ] Infraestrutura codificada
- [ ] Deploy via Terraform funcionando

### 🚀 Fase 4: CI/CD (Semana 4)
- [ ] GitHub Actions configurado
- [ ] Pipeline de build automatizado
- [ ] Deploy automático funcionando

## 🚀 Como Rodar Localmente
```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/devops-learning-2026.git
cd devops-learning-2026

# Build da imagem Docker
docker build -t portfolio-devops .

# Rode o container
docker run -d -p 8080:80 portfolio-devops

# Acesse http://localhost:8080
```

## 📝 Aprendizados e Desafios

*(Você vai atualizando isso semanalmente)*

### Semana 1
- **Aprendi**: Como estruturar um Dockerfile eficiente
- **Desafio**: Entender as diferenças entre CMD e ENTRYPOINT
- **Solução**: ...

## 🔗 Links Úteis

- [Site em Produção](URL_quando_tiver)
- [LinkedIn](seu_linkedin)

## 📖 Documentação Adicional

- [Como fazer deploy manual](docs/manual-deploy.md)
- [Guia Terraform](docs/terraform-guide.md)
- [Pipeline CI/CD](docs/cicd-pipeline.md)

## 🎓 Recursos de Estudo

- [Documentação Docker](https://docs.docker.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

---

**Status**: 🔨 Em desenvolvimento ativo (Janeiro 2026)

**Meta**: Estar job-ready para vaga DevOps Junior em Julho 2026
