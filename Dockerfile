FROM ubuntu:latest

# Actualización e instalación de paquetes base
RUN apt update && apt install -y \
    build-essential \
    libpcre3 libpcre3-dev \
    libssl-dev zlib1g-dev \
    wget git

# Descarga de NGINX
WORKDIR /opt
RUN wget http://nginx.org/download/nginx-1.26.1.tar.gz && \
    tar -xzvf nginx-1.26.1.tar.gz

# Descarga del módulo RTMP
RUN git clone https://github.com/arut/nginx-rtmp-module.git

# Configurar, compilar e instalar NGINX con RTMP
WORKDIR /opt/nginx-1.26.1
RUN ./configure \
    --with-http_ssl_module \
    --add-module=../nginx-rtmp-module && \
    make && \
    make install

# Crear directorios para VOD y Live
RUN mkdir -p /var/www/web
RUN mkdir -p /var/www/vod
RUN mkdir -p /var/www/hls

# Copiar configuración personalizada de NGINX
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

# Copiar contenido web (Video.js + index.html)
COPY web/ /var/www/web/

# Copiar vídeos HLS
COPY vod/ /var/www/vod/

# Permisos de lectura para nginx
RUN chmod -R 755 /var/www

# Exponer puertos
EXPOSE 80 1935

# Ejecutar NGINX en foreground
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
