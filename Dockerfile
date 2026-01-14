# Usa a imagem oficial do Nginx como base
FROM nginx:alpine

# Remove o site padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia seu site para o diretório do Nginx
COPY site/ /usr/share/nginx/html/

# Expõe a porta 80
EXPOSE 80

# Comando para iniciar o Nginx
CMD ["nginx", "-g", "daemon off;"]
