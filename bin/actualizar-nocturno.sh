#!/bin/sh
# Actualización nocturna del catálogo (la lanza el schedule de medianoche).
#
# Para cada base: mira si upstream publicó un digest nuevo para la etiqueta de
# la que parte. Si no hay nada nuevo, termina en silencio. Si hay:
#   1. ancla el Dockerfile al digest nuevo,
#   2. reconstruye la base dorada y la publica en ghcr,
#   3. documenta: fila nueva en huellas.tsv, digests del README al día,
#   4. commit a main (el espejo lo replica solo a GitHub).
# Las huellas ya publicadas no se tocan: los proyectos anclados no se mueven.
set -eu

apk add --no-cache git >/dev/null 2>&1 || true
git config user.name "catalogo-bot"
git config user.email "itdev@aynitech.com"

echo "$GITHUB_TOKEN" | docker login ghcr.io -u aynitech-group --password-stdin

HOY=$(date +%Y-%m-%d)
CAMBIOS=0

for df in */*/Dockerfile; do
  [ -f "$df" ] || continue
  carpeta=$(dirname "$df")
  tecno=$(echo "$carpeta" | cut -d/ -f1)
  ver=$(echo "$carpeta" | cut -d/ -f2)
  [ "$tecno" = "PLANTILLA" ] && continue

  # La base upstream es el ULTIMO FROM del fichero (la etapa final en multi-stage).
  linea_from=$(grep -iE '^[[:space:]]*FROM[[:space:]]' "$df" | tail -1)
  ref=$(echo "$linea_from" | awk '{print $2}')
  etiqueta=$(echo "$ref" | cut -d@ -f1)
  fijado=$(echo "$ref" | grep -o 'sha256:[0-9a-f]*' || true)

  echo "== $carpeta: upstream $etiqueta"
  docker pull -q "$etiqueta" >/dev/null
  vivo=$(docker inspect --format '{{index .RepoDigests 0}}' "$etiqueta" | cut -d@ -f2)

  if [ -z "$fijado" ]; then
    echo "   (sin digest fijado: la PLANTILLA lo ancla en la primera publicacion)"
    fijado="(ninguno)"
  fi
  if [ "$vivo" = "$fijado" ]; then
    echo "   sin cambios ($vivo)"
    continue
  fi

  echo "   DIGEST NUEVO de upstream: $vivo (antes: $fijado)"
  if [ "$fijado" = "(ninguno)" ]; then
    sed -i "s|^\([[:space:]]*FROM[[:space:]]\+$etiqueta\)\([[:space:]]\|\$\)|\1@$vivo\2|i" "$df"
  else
    sed -i "s|$fijado|$vivo|g" "$df"
  fi

  img="ghcr.io/aynitech-group/$tecno-dorada:$ver"
  docker build -t "$img" "$carpeta"
  docker push "$img" | tail -1
  publicado=$(docker inspect --format '{{index .RepoDigests 0}}' "$img" | cut -d@ -f2)

  # Documentar: historial y README (los digests publicados completos del README
  # se reemplazan por los nuevos; el historial solo crece).
  viejo_pub=$(grep -F "	$tecno-dorada:$ver	" huellas.tsv | tail -1 | cut -f4 || true)
  printf '%s\t%s-dorada:%s\t%s@%s\t%s\n' "$HOY" "$tecno" "$ver" "$etiqueta" "$vivo" "$publicado" >> huellas.tsv
  if [ -n "$viejo_pub" ] && [ -f README.md ]; then
    sed -i "s|$viejo_pub|$publicado|g" README.md
  fi
  CAMBIOS=1
  echo "   publicado: $img@$publicado"
done

if [ "$CAMBIOS" = "0" ]; then
  echo "Catalogo al dia: upstream no publico nada nuevo."
  exit 0
fi

git add -A
git commit -m "Actualizacion nocturna: upstream publico digests nuevos (ver huellas.tsv)"
git push "http://oauth2:${TOKEN_CATALOGO}@${CI_SERVER_HOST}/ait/imagenes-base.git" "HEAD:main" -o ci.skip
echo "Catalogo actualizado y documentado."
