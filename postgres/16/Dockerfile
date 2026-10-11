# =============================================================================
#  Base dorada: postgres 16 (Alpine) — ghcr.io/aynitech-group/postgres-dorada:16
# =============================================================================
#  La imagen oficial, con tres correcciones aplicadas DE FABRICA (los escaneres
#  analizan la imagen base tal cual se publica, no las ordenes de quien la usa):
#    1. `apk upgrade`: instala los parches de Alpine publicados tras el digest.
#    2. Se elimina gosu y su enlace su-exec: solo sirven para bajar de root al
#       arrancar, y los contenedores que parten de esta base ya arrancan como
#       postgres. Ese binario (Go stdlib congelada) concentraba ~60 CVE.
#    3. Asercion: la construccion FALLA si quedara algun binario compilado con
#       Go en los directorios de ejecutables. La limpieza queda demostrada en
#       el propio build, no prometida en un comentario.
#  Quien necesite gosu debe usar la variante `postgres-dorada:16-con-gosu`
#  (gosu recompilado con el toolchain de Go corregido), no esta.
FROM postgres:16-alpine@sha256:721873c34ceb9f8d8fc265984940dc982404c105f19ad51be9fdc5970a6080ea

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine oficial + parches apk, sin gosu/su-exec (0 binarios Go). Base corporativa Aynitech." \
      org.opencontainers.image.licenses="PostgreSQL"

RUN apk upgrade --no-cache \
    && rm -f /usr/local/bin/gosu /usr/local/bin/su-exec \
    && ! grep -rqs "go1\." /usr/local/bin /usr/bin /bin /sbin

USER postgres
