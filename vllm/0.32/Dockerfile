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

RUN set -eu \
 && apt-get update \
 && seguridad=$(apt list --upgradable 2>/dev/null | awk -F/ '/-security/ {print $1}') \
 && if [ -n "$seguridad" ]; then apt-get install -y --only-upgrade --no-install-recommends $seguridad; fi \
 && rm -rf /var/lib/apt/lists/* \
 && v=$(dpkg-query -W -f='${Version}' libssl3t64) \
 && dpkg --compare-versions "$v" ge 3.0.13-0ubuntu3.16 || { echo "OpenSSL sin parchear: $v"; exit 1; } \
 && python3 -c 'import ssl, vllm; print("asercion OK: vLLM", vllm.__version__, "|", ssl.OPENSSL_VERSION)'
