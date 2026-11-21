# Base dorada corporativa de vLLM 0.32 (servidor compatible con OpenAI): la imagen
# oficial con las actualizaciones de SEGURIDAD de Ubuntu 24.04 publicadas después de
# su digest (p. ej. OpenSSL 3.0.13-0ubuntu3.16; la oficial trae 3.0.13-0ubuntu3.6).
# Solo se instalan paquetes del repositorio de seguridad de Ubuntu: CUDA, PyTorch y
# vLLM quedan exactamente como los publica el fabricante.
# Parte de la etiqueta de versión v0.32.0, no de latest, para que la actualización
# nocturna solo recoja reconstrucciones de esta versión y nunca salte de versión de vLLM.
# La aserción impide publicar si OpenSSL quedara sin parchear o si vLLM no carga.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM vllm/vllm-openai:v0.32.0@sha256:befccf0e7e4089aa23926bb6f887a85c0d46c2a99e6de5c5ffdf5cb7957c5b34

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# De cada paquete actualizable se instala la version MAS NUEVA DEL REPOSITORIO DE SEGURIDAD (paquete=version),
# aunque -updates traiga otra aun mas nueva: antes se miraba solo la candidata, que es la de -updates cuando es
# mayor, y esos paquetes se quedaban sin su parche (linux-libc-dev 6.8.0-149 de -security con la 151 en -updates
# siguio en la 147, 21-nov-2026). La asercion de despues impide publicar si queda alguno.
RUN set -eu \
 && seguridad() { apt list --upgradable 2>/dev/null | awk -F/ 'NR > 1 { print $1 }' | while read -r p; do \
      v=$(apt-cache madison "$p" | awk -F'|' '$3 ~ /-security\// { gsub(/ /, "", $2); print $2; exit }'); \
      i=$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null || true); \
      if [ -n "$v" ] && [ -n "$i" ] && dpkg --compare-versions "$v" gt "$i"; then echo "$p=$v"; fi; \
    done; } \
 && apt-get update \
 && pendientes=$(seguridad) \
 && if [ -n "$pendientes" ]; then apt-get install -y --only-upgrade --no-install-recommends $pendientes; fi \
 && quedan=$(seguridad) \
 && { [ -z "$quedan" ] || { echo "Parches de seguridad sin instalar: $quedan"; exit 1; }; } \
 && rm -rf /var/lib/apt/lists/* \
 && v=$(dpkg-query -W -f='${Version}' libssl3t64) \
 && dpkg --compare-versions "$v" ge 3.0.13-0ubuntu3.16 || { echo "OpenSSL sin parchear: $v"; exit 1; } \
 && python3 -c 'import ssl, vllm; print("asercion OK: vLLM", vllm.__version__, "|", ssl.OPENSSL_VERSION)'
