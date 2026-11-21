#!/bin/sh
# Actualización nocturna del catálogo (la lanza el schedule de medianoche).
#
# Para cada base reconstruye y publica si se da alguno de estos motivos:
#   a) upstream publicó un digest nuevo para alguna imagen de sus FROM: la final y
#      las de compilación (p. ej. el golang con el que se recompila gosu);
#   b) la dorada publicada tiene parches pendientes (bin/parches-pendientes.sh):
#      paquetes de apk/apt con versión nueva en los repositorios de su distribución, o
#      pip/setuptools/wheel con versión nueva. Si la receta solo instala del
#      repositorio de seguridad (vLLM), solo cuentan esos. Los parches salen en los
#      repositorios semanas antes que la imagen oficial nueva: sin este motivo, las
#      doradas se quedaban con CVE ya corregidas (20-nov-2026: 6 de 7 bases).
# Si hay motivo:
#   1. ancla los FROM a los digests nuevos (motivo a);
#   2. reconstruye con --pull y --build-arg PARCHES=<marca>: el ARG PARCHES de la
#      receta invalida la caché justo antes del apk/apt upgrade, así que se vuelven a
#      aplicar los parches sin recompilar lo anterior (Python, por ejemplo). Si la
#      receta no declara ARG PARCHES, en el motivo b) se construye sin caché;
#   3. motivo b): si la imagen nueva sigue con los mismos pendientes, NO se publica
#      (la reconstrucción no corrige nada y solo cambiaría la huella);
#   4. publica en ghcr y documenta: fila nueva en huellas.tsv, digests del README;
#   5. commit a main (el espejo lo replica solo a GitHub).
# Las huellas ya publicadas no se tocan: los proyectos anclados no se mueven.
# Un fallo en una base no detiene las demás; el job termina en error si hubo alguno.
#
# Prueba sin publicar: SIMULAR=1 sh bin/actualizar-nocturno.sh
#   No inicia sesión en ghcr, no cambia ficheros, no construye, no publica ni hace
#   commit: solo informa de qué reconstruiría y por qué.
#   BASES="alpine/3.24 node/22" limita las carpetas; RED=<red de docker> se usa en
#   los docker run/build si la red por defecto de ese Docker no sale a internet.
set -eu

SIMULAR=${SIMULAR:-0}
BASES=${BASES:-}
RED=${RED:-}
HOY=$(date +%Y-%m-%d)
MARCA=$(date +%Y%m%d%H%M%S)
CAMBIOS=0
FALLOS=0
RESUMEN=""
red_opt=""
[ -z "$RED" ] || red_opt="--network $RED"

if [ "$SIMULAR" != "1" ]; then
  apk add --no-cache git >/dev/null 2>&1 || true
  git config user.name "catalogo-bot"
  git config user.email "itdev@aynitech.com"
  echo "$GITHUB_TOKEN" | docker login ghcr.io -u aynitech-group --password-stdin
fi

# Digest con el que el registro sirve la imagen local $1 en el repositorio $2.
digest_de() {
  docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$1" \
    | grep "^$2@" | head -n 1 | cut -d@ -f2
}

# Actualizaciones pendientes dentro de la imagen local $1 ($2 = normal | seguridad).
parches_pendientes() {
  # shellcheck disable=SC2086
  docker run -i --rm --pull never $red_opt --user 0 --entrypoint sh -e MODO="$2" "$1" -s \
    < bin/parches-pendientes.sh
}

# Procesa una base. Devuelve 1 si algo falla (el llamador lo cuenta y sigue).
# Se llama dentro de un `if`, donde `set -e` no actúa: cada paso comprueba su error.
procesar() {
  df=$1; carpeta=$2; tecno=$3; ver=$4
  img="ghcr.io/aynitech-group/dorada:$tecno-$ver"
  modo=normal
  if grep -q -e '-security' "$df"; then modo=seguridad; fi
  motivo=""

  # a) digests de upstream de todos los FROM (ni los alias de etapa ni scratch)
  etapas=$(grep -iE '^[[:space:]]*FROM[[:space:]].*[[:space:]]AS[[:space:]]+[^[:space:]]+' "$df" \
           | awk '{ print tolower($NF) }' | tr '\n' ' ')
  for ref in $(grep -iE '^[[:space:]]*FROM[[:space:]]' "$df" | awk '{ print $2 }'); do
    etiqueta=${ref%%@*}
    minus=$(echo "$etiqueta" | tr 'A-Z' 'a-z')
    case " $etapas scratch " in *" $minus "*) continue ;; esac
    fijado=$(echo "$ref" | grep -o 'sha256:[0-9a-f]*' || true)
    if ! docker pull -q "$etiqueta" >/dev/null; then
      echo "   ERROR: no se pudo bajar $etiqueta"; return 1
    fi
    vivo=$(digest_de "$etiqueta" "${etiqueta%:*}")
    if [ -z "$vivo" ]; then echo "   ERROR: sin digest para $etiqueta"; return 1; fi
    if [ "$vivo" = "$fijado" ]; then
      echo "   upstream $etiqueta sin cambios"
      continue
    fi
    echo "   DIGEST NUEVO de $etiqueta: $vivo (antes: ${fijado:-ninguno})"
    motivo="${motivo:+$motivo, }upstream $etiqueta"
    [ "$SIMULAR" = "1" ] && continue
    if [ -z "$fijado" ]; then
      sed -i "s|^\([[:space:]]*FROM[[:space:]]\+$etiqueta\)\([[:space:]]\|\$\)|\1@$vivo\2|i" "$df" || return 1
    else
      sed -i "s|$fijado|$vivo|g" "$df" || return 1
    fi
  done

  # b) parches pendientes en la dorada publicada
  pend_pub=""
  if [ -z "$motivo" ]; then
    if ! docker pull -q "$img" >/dev/null 2>&1; then
      echo "   (aún no está publicada: la publica el job publicar al fusionar la receta)"
      return 0
    fi
    if ! pend_pub=$(parches_pendientes "$img" "$modo"); then
      echo "   ERROR: no se pudieron consultar los parches de $img"
      echo "$pend_pub" | sed 's/^/      /'
      return 1
    fi
    if [ -z "$pend_pub" ]; then
      echo "   sin parches pendientes"
      return 0
    fi
    echo "   PARCHES PENDIENTES en la dorada publicada ($modo):"
    echo "$pend_pub" | sed 's/^/      /'
    motivo="parches pendientes"
  fi

  if [ "$SIMULAR" = "1" ]; then
    echo "   SIMULAR: se reconstruiría y publicaría ($motivo)"
    RESUMEN="$RESUMEN
- dorada:$tecno-$ver: $motivo"
    return 0
  fi

  # Reconstruir
  sin_cache=""
  if [ "$motivo" = "parches pendientes" ] \
     && ! grep -qE '^[[:space:]]*ARG[[:space:]]+PARCHES([[:space:]=]|$)' "$df"; then
    sin_cache="--no-cache"
  fi
  nuevo="catalogo-nocturno/$tecno:$ver"
  # shellcheck disable=SC2086
  if ! docker build --pull $sin_cache $red_opt --build-arg "PARCHES=$MARCA" -t "$nuevo" "$carpeta"; then
    echo "   ERROR: falló la construcción de $carpeta"; return 1
  fi

  if [ "$motivo" = "parches pendientes" ]; then
    if ! pend_nuevo=$(parches_pendientes "$nuevo" "$modo"); then
      echo "   ERROR: no se pudieron consultar los parches de la imagen nueva"
      docker rmi "$nuevo" >/dev/null 2>&1 || true
      return 1
    fi
    if [ "$pend_nuevo" = "$pend_pub" ]; then
      echo "   La reconstrucción no corrige ningún pendiente: NO se publica (avisar a quien mantiene la receta)."
      docker rmi "$nuevo" >/dev/null 2>&1 || true
      return 0
    fi
    if [ -n "$pend_nuevo" ]; then
      echo "   Siguen pendientes tras reconstruir (se publica igual: corrige otros):"
      echo "$pend_nuevo" | sed 's/^/      /'
    fi
  fi

  # Publicar
  docker tag "$nuevo" "$img" || return 1
  if ! docker push "$img" > /tmp/push.log 2>&1; then
    tail -n 5 /tmp/push.log; echo "   ERROR: falló la publicación de $img"; return 1
  fi
  tail -n 1 /tmp/push.log
  docker rmi "$nuevo" >/dev/null 2>&1 || true
  publicado=$(digest_de "$img" "ghcr.io/aynitech-group/dorada")
  if [ -z "$publicado" ]; then echo "   ERROR: sin digest publicado para $img"; return 1; fi

  # Documentar: historial y README (los digests publicados completos del README se
  # reemplazan por los nuevos; el historial solo crece).
  ultimo_from=$(grep -iE '^[[:space:]]*FROM[[:space:]]' "$df" | tail -n 1 | awk '{ print $2 }')
  viejo_pub=$(grep -F "	dorada:$tecno-$ver	" huellas.tsv | tail -n 1 | cut -f4 || true)
  printf '%s\tdorada:%s-%s\t%s\t%s\n' "$HOY" "$tecno" "$ver" "$ultimo_from" "$publicado" >> huellas.tsv
  if [ -n "$viejo_pub" ] && [ -f README.md ]; then
    sed -i "s|$viejo_pub|$publicado|g" README.md
  fi
  CAMBIOS=1
  RESUMEN="$RESUMEN
- dorada:$tecno-$ver: $motivo"
  echo "   publicado: $img@$publicado"
  return 0
}

for df in */*/Dockerfile; do
  [ -f "$df" ] || continue
  carpeta=$(dirname "$df")
  tecno=${carpeta%%/*}
  ver=${carpeta#*/}
  [ "$tecno" = "PLANTILLA" ] && continue
  if [ -n "$BASES" ]; then
    case " $BASES " in *" $carpeta "*) ;; *) continue ;; esac
  fi
  echo "== $carpeta"
  if ! procesar "$df" "$carpeta" "$tecno" "$ver"; then
    FALLOS=$((FALLOS + 1))
    RESUMEN="$RESUMEN
- dorada:$tecno-$ver: ERROR (ver el log del job)"
  fi
done

echo ""
if [ -n "$RESUMEN" ]; then echo "Resumen:$RESUMEN"; fi

if [ "$SIMULAR" = "1" ]; then
  echo "SIMULAR: no se cambió ni publicó nada."
elif [ "$CAMBIOS" = "1" ]; then
  git add -A
  git commit -q -m "Actualizacion nocturna: bases reconstruidas (ver huellas.tsv)" -m "${RESUMEN#?}"
  git push "http://oauth2:${TOKEN_CATALOGO}@${CI_SERVER_HOST}/ait/imagenes-base.git" "HEAD:main" -o ci.skip
  echo "Catalogo actualizado y documentado."
else
  echo "Catalogo al dia: ni upstream ni los repositorios tienen nada nuevo."
fi

if [ "$FALLOS" != "0" ]; then
  echo "$FALLOS base(s) con error: revisa el log de arriba."
  exit 1
fi
exit 0
