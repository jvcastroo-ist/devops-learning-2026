# 📋 Notas do Projeto Portfolio DevOps

## 🌐 Website

Criei o website utilizando o Claude, que gerou os arquivos HTML e CSS.

---

## 🐳 Docker

### Dockerfile

Criação do Dockerfile para containerizar a aplicação:

```dockerfile
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY site/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

#### 📖 Explicação dos Comandos do Dockerfile

| Comando | Descrição |
|---------|-----------|
| `FROM` | Especifica a imagem base para uma nova etapa de build |
| `RUN` | Executa comandos durante o processo de build da imagem |
| `COPY` | Copia arquivos do contexto de build para a imagem |
| `CMD` | Define o comando que será executado quando o container iniciar |

---

### 🏗️ Build e Execução

#### Construir a imagem Docker

```bash
docker build -t portfolio-devops .
```

#### Executar o container

```bash
docker run -d -p 8080:80 --name meu-portfolio portfolio-devops
```

#### Verificar containers em execução

```bash
docker ps
```

---

### 🛠️ Comandos Úteis

#### Ver logs do container
```bash
docker logs meu-portfolio
```

#### Parar o container
```bash
docker stop meu-portfolio
```

#### Iniciar o container
```bash
sudo docker start meu-portfolio
```

#### Remover o container
```bash
docker rm meu-portfolio
```

#### Listar imagens disponíveis
```bash
docker images
```

#### Acessar o container (debug)
```bash
docker exec -it meu-portfolio sh
```

---

### 📝 Arquivo `.dockerignore`

Crie um arquivo `.dockerignore` para evitar copiar arquivos desnecessários para a imagem:

```dockerignore
.git
.gitignore
README.md
docs/
*.md
.vscode
.idea
```

---

## 📚 Recursos Adicionais

- [Documentação oficial do Docker](https://docs.docker.com/)
- [Nginx Docker Hub](https://hub.docker.com/_/nginx)
