# Base dorada corporativa de Alpine 3.22: la imagen oficial con TODOS los
# parches del sistema publicados después de su digest (p. ej. zlib 1.3.2-r1,
# CVE-2026-85091). Pensada como etapa final de imágenes multi-stage (el Core
# del Monitor la usa de runtime). La aserción impide publicar si zlib quedara
# por debajo de la versión corregida.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM alpine:3.22@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f

RUN set -eu \
 && apk upgrade --no-cache \
 && v=$(apk list --installed 2>/dev/null | grep -oE '^zlib-[0-9][0-9a-z.r-]*' | head -1) \
 && test -n "$v" \
 && case "$v" in zlib-1.3.2-r0|zlib-1.3.1*|zlib-1.2*) echo "zlib sin parchear: $v"; exit 1;; esac \
 && echo "asercion OK: $v"
