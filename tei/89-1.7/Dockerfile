# Base dorada corporativa de Text Embeddings Inference 1.7 (Hugging Face) para
# GPU Ada Lovelace / L40S (compute 8.9): la imagen oficial 89-1.7 (TEI 1.7.4,
# Ubuntu 22.04) con las actualizaciones de Ubuntu publicadas despues de su
# digest (OpenSSL, glibc, systemd, gnupg, curl...). TEI, CUDA y el modelo quedan
# exactamente como los publica el fabricante:
#  - el repositorio de CUDA de la imagen se desactiva (cuda-*.list): el upgrade
#    solo toca paquetes de Ubuntu y no mueve las librerias de CUDA con las que se
#    compilo TEI. Asi tambien la actualizacion nocturna solo mira Ubuntu.
#  - parte de la etiqueta 89-1.7, no de latest: la actualizacion nocturna nunca
#    salta de version de TEI.
# La asercion impide publicar si queda algun paquete de Ubuntu por actualizar o si el
# upgrade tocara el binario de TEI (la 1.7.4 de la imagen oficial: se compara su huella
# antes y despues). TEI no se puede ejecutar al construir: necesita el driver de la GPU.
# Catalogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM ghcr.io/huggingface/text-embeddings-inference:89-1.7@sha256:8350eef88360fd746de01cd951adef9584a35ad957a7d02fa3309c2b6e962323

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Ubuntu tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apt-get upgrade` se vuelve a ejecutar.
ARG PARCHES

# La imagen excluye las páginas de manual (dpkg path-exclude=/usr/share/man/*), pero la
# actualización de bash registra la de bash-builtins con update-alternatives y falla si no
# está: se deja pasar esa sola página (el fichero zz-* se lee después de «excludes»).
RUN set -eu \
 && for f in /etc/apt/sources.list.d/cuda*.list; do \
      if [ -e "$f" ]; then mv "$f" "$f.desactivado"; fi; \
    done \
 && echo 'path-include=/usr/share/man/man7/bash-builtins.7.gz' > /etc/dpkg/dpkg.cfg.d/zz-bash-builtins-man \
 && tei=$(command -v text-embeddings-router) && antes=$(sha256sum "$tei") \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --with-new-pkgs --no-install-recommends \
 && pendientes=$(apt-get -s upgrade --with-new-pkgs | grep -c '^Inst ' || true) \
 && rm -rf /var/lib/apt/lists/* \
 && { [ "$pendientes" = 0 ] || { echo "quedan $pendientes paquetes por actualizar"; exit 1; }; } \
 && { [ "$(sha256sum "$tei")" = "$antes" ] || { echo "el binario de TEI cambio"; exit 1; }; } \
 && echo "asercion OK: TEI intacta ($antes) con Ubuntu al dia (libssl3 $(dpkg-query -W -f='${Version}' libssl3))"
