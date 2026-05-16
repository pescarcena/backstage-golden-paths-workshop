FROM nginx:alpine

# Limpiar contenido default de nginx
RUN rm -rf /usr/share/nginx/html/*

# Copiar archivos de tu proyecto
COPY src/ /usr/share/nginx/html

# Exponer puerto
EXPOSE 80

# Ejecutar nginx
CMD ["nginx", "-g", "daemon off;"]
