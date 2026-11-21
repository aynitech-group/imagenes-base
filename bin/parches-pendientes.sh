#!/bin/sh
# Se ejecuta DENTRO de una base dorada (la lanza actualizar-nocturno.sh por la entrada
# estándar: docker run -i --user 0 --entrypoint sh <imagen> -s < bin/parches-pendientes.sh).
# Imprime, una por línea, las actualizaciones que la imagen aún no tiene:
#   apk <paquete-versión> -> <versión nueva>        (Alpine)
#   apt <paquete> [<versión>] -> <versión nueva>    (Debian / Ubuntu)
#   pip <paquete> <versión> -> <versión nueva>      (solo pip, setuptools y wheel)
# MODO=seguridad: solo cuenta los paquetes del repositorio de seguridad y no mira pip
# (la receta de vLLM solo instala de ahí y no toca los paquetes de Python del fabricante).
# Sale con error si no puede consultar los repositorios: sin consulta no hay respuesta fiable.
# `apk -U upgrade --simulate` no sirve aquí: no guarda el índice y luego no lo puede leer, y
# en una imagen con un índice viejo en /var/cache/apk responde con ese índice.
set -u
MODO=${MODO:-normal}

if command -v apk >/dev/null 2>&1; then
  apk update -q >/dev/null 2>&1 || { echo "ERROR: apk update"; exit 1; }
  apk version -l '<' 2>/dev/null | awk 'NR > 1 && $2 == "<" { print "apk " $1 " -> " $3 }'
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1 || { echo "ERROR: apt-get update"; exit 1; }
  if [ "$MODO" = seguridad ]; then
    # La version MAS NUEVA DEL REPOSITORIO DE SEGURIDAD de cada paquete actualizable, si es mas
    # nueva que la instalada, aunque -updates traiga otra aun mas nueva (la receta de vLLM instala
    # esa, la de seguridad). Antes se miraba la candidata de `apt-get -s upgrade`, que es la de
    # -updates cuando es mayor, y el paquete no contaba: linux-libc-dev 6.8.0-149 de -security con
    # la 151 en -updates se quedo en la 147 (21-nov-2026).
    apt list --upgradable 2>/dev/null | awk -F/ 'NR > 1 { print $1 }' | while read -r p; do
      v=$(apt-cache madison "$p" | awk -F'|' '$3 ~ /-security\// { gsub(/ /, "", $2); print $2; exit }')
      i=$(dpkg-query -W -f='${Version}' "$p" 2>/dev/null || true)
      if [ -n "$v" ] && [ -n "$i" ] && dpkg --compare-versions "$v" gt "$i"; then
        echo "apt $p $i -> $v"
      fi
    done
  else
    apt-get -s upgrade 2>/dev/null | grep '^Inst ' > /tmp/pendientes-apt || true
    awk '{ v = $4; gsub(/[()]/, "", v); print "apt " $2 " " $3 " -> " v }' /tmp/pendientes-apt
    rm -f /tmp/pendientes-apt
  fi
else
  echo "ERROR: la imagen no tiene apk ni apt-get"
  exit 1
fi

if [ "$MODO" != seguridad ] && command -v python3 >/dev/null 2>&1 \
   && python3 -m pip --version >/dev/null 2>&1; then
  python3 -m pip list --outdated --disable-pip-version-check 2>/dev/null \
    | awk 'NR > 2 && ($1 == "pip" || $1 == "setuptools" || $1 == "wheel") { print "pip " $1 " " $2 " -> " $3 }'
fi
exit 0
