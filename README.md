# MultimediaS

Servicio de streaming desarrollado para una práctica de clase. La aplicación permite servir contenido **VOD** (vídeo bajo demanda) mediante HLS y emitir contenido **en directo** a través de RTMP convertido a HLS.

## Arquitectura

- **NGINX** como servidor HTTP y RTMP.
- **nginx-rtmp-module** compilado junto con NGINX para recibir emisiones RTMP.
- **HLS** como formato de distribución: playlists `.m3u8` y segmentos `.ts`.
- **Cliente web estático** en HTML y JavaScript.
- Dos reproductores en el navegador:
  - HTML5 Video con `hls.js`.
  - Video.js con soporte HTTP Streaming.
- **Docker Compose** para ejecutar el servicio de forma reproducible.

Flujo de vídeo en directo:

```text
OBS/FFmpeg ──RTMP:1935──> NGINX RTMP ──HLS──> /var/www/hls
                                                │
Navegador <──────────── HTTP:8080 ──────────────┘
```

El contenido VOD se sirve directamente desde `/var/www/vod`. El contenido HLS generado para las emisiones en directo se almacena en `/var/www/hls`.

## Estructura relevante

```text
.
├── Dockerfile              # Imagen NGINX compilada con soporte RTMP
├── docker-compose.yml      # Despliegue del servicio y volúmenes
├── nginx.conf              # Configuración HTTP, RTMP y HLS
├── web/
│   ├── index.html          # Interfaz principal y selector de reproductor
│   ├── videojs.html        # Reproductor Video.js para VOD adaptativo
│   └── live.html           # Reproductor HLS para emisiones en directo
├── vod/
│   ├── *.mp4               # Fuentes de vídeo VOD
│   └── hls/                # Playlists y segmentos HLS del VOD
└── Server/                 # Fuentes y módulo RTMP incluidos en el proyecto
```

## Requisitos

- Docker Engine.
- Docker Compose v2 (`docker compose`).
- Para emitir en directo, OBS Studio o FFmpeg.

## Puesta en marcha

Desde la raíz del repositorio:

```bash
docker compose up --build
```

La aplicación queda disponible en:

- Interfaz web: <http://localhost:8080>
- RTMP de entrada: `rtmp://localhost:1935/live`

Para detener el servicio:

```bash
docker compose down
```

El volumen `hls_data` conserva el directorio usado para los segmentos HLS generados durante la ejecución del contenedor.

## VOD y streaming adaptativo

El servidor expone:

- `/vod/`: archivos y playlists de vídeo bajo demanda.
- `/vod/hls/master.m3u8`: playlist maestra adaptativa.
- `/hls/`: playlists y segmentos HLS de emisiones en directo.
- `/live/`: ruta HTTP prevista para contenido HLS de directo.

La playlist maestra del VOD referencia varias representaciones con distintas resoluciones. El reproductor HTML5 utiliza `hls.js` para detectar los niveles disponibles y permite seleccionar automáticamente la calidad o fijar un nivel concreto. Video.js realiza una función equivalente mediante `@videojs/http-streaming`.

## Emisión en directo

Configure OBS con los siguientes parámetros:

- **Servidor:** `rtmp://localhost:1935/live`
- **Clave de emisión:** `STREAM_KEY`

La URL HLS resultante es:

```text
http://localhost:8080/hls/STREAM_KEY.m3u8
```

También puede utilizar FFmpeg, por ejemplo:

```bash
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -c:a aac \
  -f flv rtmp://localhost:1935/live/STREAM_KEY
```

La configuración RTMP genera fragmentos HLS de aproximadamente 3 segundos y una playlist de 10 segundos. Los segmentos antiguos se eliminan automáticamente (`hls_cleanup on`).

## Puertos y volúmenes

El servicio publica los siguientes puertos:

| Puerto | Uso |
|---|---|
| `8080` | HTTP para la web, VOD y HLS |
| `1935` | Entrada RTMP para emisiones en directo |

`docker-compose.yml` monta:

- `./web` en `/var/www/web` en modo solo lectura.
- `./vod` en `/var/www/vod` en modo solo lectura.
- El volumen `hls_data` en `/var/www/hls`.

## Notas técnicas

- El contenedor compila NGINX con `--with-http_ssl_module` y el módulo RTMP.
- La configuración actual permite publicar y reproducir RTMP sin autenticación (`allow publish all` y `allow play all`); está pensada para una demostración local, no para producción.
- HLS y el cliente web están configurados para trabajar en `localhost:8080`. Para desplegar en otro host hay que actualizar las URL utilizadas por los reproductores.
- La configuración HLS incluye cabeceras CORS en `/hls/` para permitir el acceso desde el cliente web.
- No se incluye HTTPS, control de usuarios, persistencia de catálogo ni monitorización.

## Tecnologías

- NGINX
- nginx-rtmp-module
- Docker / Docker Compose
- HLS, RTMP y MPEG-TS
- HTML5, JavaScript y CSS
- hls.js
- Video.js

## Contexto académico

Proyecto de clase sobre servicios multimedia: comparación de reproductores HTML5 y Video.js, distribución adaptativa de vídeo pregrabado y emisión de vídeo en directo desde un navegador.