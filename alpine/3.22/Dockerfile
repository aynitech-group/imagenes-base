# Base dorada corporativa de Alpine 3.22: la imagen oficial con TODOS los
# parches del sistema publicados después de su digest (p. ej. zlib 1.3.2-r1,
# CVE-2026-85091). Pensada como etapa final de imágenes multi-stage (el Core
# del Monitor la usa de runtime). La aserción impide publicar si zlib quedara
# por debajo de la versión corregida.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM alpine:3.22@sha256:822614ea121e1d40a33655081af10ef85f0aa2ab9e61f649ceaf0c651822433c

RUN set -eu \
 && apk upgrade --no-cache \
 && v=$(apk list --installed 2>/dev/null | grep -oE '^zlib-[0-9][0-9a-z.r-]*' | head -1) \
 && test -n "$v" \
 && case "$v" in zlib-1.3.2-r0|zlib-1.3.1*|zlib-1.2*) echo "zlib sin parchear: $v"; exit 1;; esac \
 && echo "asercion OK: $v"
