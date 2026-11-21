# Base dorada corporativa de Alpine 3.22: la imagen oficial con TODOS los
# parches del sistema publicados después de su digest (p. ej. zlib 1.4-r0).
# Pensada como etapa final de imágenes multi-stage (el Core del Monitor la usa
# de runtime). La aserción impide publicarla con algún paquete por debajo del
# mínimo corregido.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Alpine tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apk upgrade` se vuelve a ejecutar.
ARG PARCHES

RUN set -eu \
 && apk upgrade --no-cache \
 && rm -rf /var/cache/apk/* \
 && for req in zlib=1.4-r0 libssl3=3.5.9-r0 libcrypto3=3.5.9-r0; do \
      pkg=${req%%=*}; min=${req#*=}; \
      v=$(apk list -I "$pkg" 2>/dev/null | sed -n "s/^$pkg-\([0-9][^ ]*\) .*/\1/p" | head -n 1); \
      [ -n "$v" ] || { echo "falta $pkg"; exit 1; }; \
      [ "$(apk version -t "$v" "$min")" != "<" ] || { echo "VULNERABLE: $pkg $v (mínimo $min)"; exit 1; }; \
      echo "$pkg $v (mínimo $min)"; \
    done \
 && echo "asercion OK: parches de Alpine aplicados ($(cat /etc/alpine-release))"
