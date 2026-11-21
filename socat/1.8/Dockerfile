# Base dorada corporativa de socat 1.8 sobre Alpine 3.24: el socat de los
# repositorios de Alpine en una imagen con todos los parches del sistema.
# Sustituye a alpine/socat (Alpine 3.20, sin soporte desde 2026: sus parches de
# OpenSSL, musl, zlib y busybox ya no llegan). Mismo uso: el punto de entrada es
# socat y los argumentos van en `command`. Corre sin privilegios (nobody): para
# reenviar puertos altos no hace falta root.
# La asercion impide publicarla con algun paquete por debajo del minimo corregido.
# Catalogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Alpine tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apk upgrade` se vuelve a ejecutar.
ARG PARCHES

RUN set -eu \
 && apk upgrade --no-cache \
 && apk add --no-cache socat \
 && rm -rf /var/cache/apk/* \
 && for req in libssl3=3.5.9-r1 libcrypto3=3.5.9-r1 zlib=1.4-r0 musl=1.2.6-r3; do \
      pkg=${req%%=*}; min=${req#*=}; \
      v=$(apk list -I "$pkg" 2>/dev/null | sed -n "s/^$pkg-\([0-9][^ ]*\) .*/\1/p" | head -n 1); \
      [ -n "$v" ] || { echo "falta $pkg"; exit 1; }; \
      [ "$(apk version -t "$v" "$min")" != "<" ] || { echo "VULNERABLE: $pkg $v (mínimo $min)"; exit 1; }; \
      echo "$pkg $v (mínimo $min)"; \
    done \
 && socat -V | grep -q 'socat version 1\.8' \
 && echo "asercion OK: $(socat -V | grep 'socat version')"

USER nobody
ENTRYPOINT ["socat"]
