# Base dorada corporativa de Alpine 3.24: la imagen oficial con TODOS los
# parches del sistema publicados después de su digest (OpenSSL libssl3 y
# libcrypto3 3.5.9-r1, zlib 1.4-r0…). Pensada como base de imágenes de
# herramientas (las de análisis de AyniInspect parten de ella) y como etapa
# final (runtime) de imágenes multi-stage. La aserción impide publicarla con
# algún paquete por debajo del mínimo corregido.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Alpine tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apk upgrade` se vuelve a ejecutar.
ARG PARCHES

RUN set -eu \
 && apk upgrade --no-cache \
 && rm -rf /var/cache/apk/* \
 && for req in libssl3=3.5.9-r1 libcrypto3=3.5.9-r1 zlib=1.4-r0 musl=1.2.6-r3; do \
      pkg=${req%%=*}; min=${req#*=}; \
      v=$(apk list -I "$pkg" 2>/dev/null | sed -n "s/^$pkg-\([0-9][^ ]*\) .*/\1/p" | head -n 1); \
      [ -n "$v" ] || { echo "falta $pkg"; exit 1; }; \
      [ "$(apk version -t "$v" "$min")" != "<" ] || { echo "VULNERABLE: $pkg $v (mínimo $min)"; exit 1; }; \
      echo "$pkg $v (mínimo $min)"; \
    done \
 && echo "asercion OK: parches de Alpine aplicados ($(cat /etc/alpine-release))"
