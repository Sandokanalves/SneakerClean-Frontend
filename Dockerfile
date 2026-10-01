# Stage 1: Build da aplicação Vue 3 usando Node.js 22 Slim
FROM node:22-slim AS build
WORKDIR /app

# Copia os ficheiros de dependências
COPY package*.json ./

# Instala as dependências de forma limpa
RUN npm ci || npm install

# Copia o restante código-fonte
COPY . .

# Executa a compilação de produção
RUN npm run build

# Stage 2: Servidor Nginx para Servir os Ficheiros Estáticos
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]