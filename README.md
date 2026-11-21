# Imágenes base corporativas de Aynitech («bases doradas»)

Imágenes base de contenedor **ya corregidas de fábrica**: parten de la imagen
oficial, aplican los parches del sistema publicados después de su digest y
retiran (o actualizan) los binarios vulnerables que la imagen oficial arrastra.
Los escáneres de seguridad (Trivy, AyniInspect, etc.) analizan la imagen base
que declara tu `FROM` **tal cual se publica** — por eso la corrección debe
venir de fábrica y no en un `RUN` de tu Dockerfile, que el escáner no ejecuta.

## Catálogo

**Todas las bases viven en UN solo paquete** (`ghcr.io/aynitech-group/dorada`),
una por *tag*. Así el paquete se hace público una única vez y **cada base nueva
nace pública automáticamente** (los tags heredan la visibilidad del paquete;
un paquete nuevo en ghcr siempre nace privado y exige un clic manual).

| Imagen (tag) | Línea `FROM` lista para copiar | Qué corrige | CVE restantes |
|---|---|---|---|
| **dorada:postgres-16** | `FROM ghcr.io/aynitech-group/dorada:postgres-16@sha256:271fd82b2cbac540e1f48211ac90ea851455687fcb233a75b2c5f5f761670b6f` | Parches de Alpine (zlib 1.3.2-r1…) y elimina `gosu`/`su-exec` (binario Go con ~60 CVE de stdlib congelada; innecesario si tu contenedor arranca como `postgres`, que es lo normal) | 0 al publicarse |
| **dorada:node-22** | `FROM ghcr.io/aynitech-group/dorada:node-22@sha256:fb12459014bab526ea84fea51e4983a4a19c054bae06ef8a4229900a03d3af71` | Parches de Alpine, npm actualizado a la última versión y cada copia vulnerable de sus dependencias internas sustituida por la corregida (brace-expansion, ip-address, http-cache-semantics, postcss-selector-parser, undici); retira corepack y yarn. Aserción de mínimos en la construcción | 0 al publicarse |

> Los nombres antiguos (`postgres-dorada:16`, `postgres-dorada:16-con-gosu`,
> `node-dorada:22`) siguen publicados y públicos con sus huellas intactas:
> ningún proyecto anclado se rompe. Lo nuevo se publica solo bajo `dorada`.

## Bases retiradas

Se retiraron el **21-nov-2026** porque ningún proyecto las usaba. Su receta ya no
está en el repositorio, así que la actualización nocturna **no las vuelve a
parchear**. Su última imagen sigue publicada y pública: un proyecto anclado a
ella no se rompe, pero debe pasar a la base indicada.

| Imagen (tag) | Última huella publicada | Usar en su lugar |
|---|---|---|
| **dorada:alpine-3.22** | `sha256:47d37bd063cb8f6807583876ad697d83821e0d9910c7a650bc641dd04be411d8` | `dorada:alpine-3.24` (el soporte de Alpine 3.22 termina el 1-may-2027) |
| **dorada:python-3.11** | `sha256:ae90f2b9eaf8ce6daf1b95c60dabecc8165573f918e6bdcf3751aef26863459d` | `dorada:python-3.12` |
| **dorada:postgres-16-con-gosu** | `sha256:25f6070fa167b7290a93cc8679e54d8a2d6509c0d8617926c1535dd328f57d32` | `dorada:postgres-16` (arranca como `postgres`; no necesita gosu) |

La receta de cada una sigue en el historial de git (commit anterior al de su
retirada), por si hiciera falta recuperarla.

## Bases añadidas en octubre de 2026

| Imagen (tag) | Línea `FROM` | Qué corrige |
|---|---|---|
| **dorada:python-3.12** | `FROM ghcr.io/aynitech-group/dorada:python-3.12@sha256:55db41fba7d81974af2705141912d524f91dfe21619e4c2bdb4dc03c11d29d25` | Python 3.12.16 sobre Alpine 3.24 con la receta oficial de docker-library (la imagen oficial aún traía 3.12.15) |
| **dorada:vllm-0.32** | La imprime el job `publicar` al fusionar | vLLM 0.32.0 oficial con las actualizaciones de seguridad de Ubuntu (OpenSSL 3.0.13-0ubuntu3.16; la oficial trae 3.0.13-0ubuntu3.6). Pesa ~23 GB |

## Bases añadidas en noviembre de 2026

| Imagen (tag) | Línea `FROM` | Qué corrige |
|---|---|---|
| **dorada:clickhouse-25.8** | La imprime el job `publicar` al fusionar | ClickHouse 25.8 LTS oficial (Alpine) con los parches de Alpine posteriores a su digest: OpenSSL 3.5.9-r1 (libssl3 y libcrypto3), zlib 1.4-r0 y musl 1.2.6-r3. No cambia usuario, configuración ni punto de entrada. |
| **dorada:alpine-3.24** | La imprime el job `publicar` al fusionar | Alpine 3.24 oficial con todos los parches del sistema publicados tras su digest (OpenSSL 3.5.9-r1, zlib 1.4-r0, musl 1.2.6-r3). Base de las imágenes de análisis de AyniInspect y etapa final para imágenes multi-stage; aserción de mínimos |
| **dorada:postgres-16-pgvector** | La imprime el job `publicar` al fusionar | La receta de `postgres-16` (Alpine con parches, sin gosu ni su-exec, arranca como `postgres`) más pgvector 0.8.7 compilado desde su commit verificado y sin `-march=native`. Sustituye a `pgvector/pgvector:pg16` (Debian 12: ~117 CVE altas o críticas sin arreglo publicado). La prueba de la construcción arranca un PostgreSQL con ICU y calcula una distancia. **Al migrar desde Debian:** inicializar con `POSTGRES_INITDB_ARGS="--locale-provider=icu --icu-locale=en-US-u-ka-shifted"` (ignora la puntuación al ordenar, como el `en_US.utf8` de glibc) y pasar los datos con `pg_dump`/`pg_restore` (la ordenación de texto de glibc no es la de musl) |
| **dorada:tei-89-1.7** | La imprime el job `publicar` al fusionar | Text Embeddings Inference 1.7.4 oficial (GPU Ada/L40S) con todas las actualizaciones de Ubuntu 22.04. Ni TEI ni CUDA cambian: el repositorio de CUDA se desactiva antes del `upgrade` y la construcción comprueba que el binario de TEI sigue igual. Quedan solo CVE medias y bajas sin arreglo publicado |
| **dorada:socat-1.8** | La imprime el job `publicar` al fusionar | socat 1.8 sobre Alpine 3.24 con parches, sin privilegios (`nobody`) y con `socat` como punto de entrada. Sustituye a `alpine/socat` (Alpine 3.20, sin soporte) |

**dorada:node-22, 3-nov-2026:** npm 12.2.1 y, dentro del npm de la base, undici 6.29.1, glob 14.0.3 y minimatch 11.0.4, cada uno con sus dependencias. npm 12 ya no baja dependencias desde git salvo que se autorice: un proyecto que las tenga debe usar `npm ci --allow-git=all` (o `allow-git` en su `.npmrc`).

**dorada:python-3.12:** pip lleva dentro `pkg_resources` copiado de
setuptools 70.3.0 y lo declara en su SBOM (`pip/_vendor/bom.cdx.json`). Los
escáneres que leen ese SBOM (Trivy, por ejemplo) cuentan 3 CVE de setuptools
70.3.0 en la base. No tienen arreglo hasta que pip actualice esa copia;
cuando lo haga, la actualización nocturna recogerá el pip nuevo sola.

## Actualización nocturna

Cada noche (schedule de las 00:00 de Lima, `bin/actualizar-nocturno.sh`) se
reconstruye y publica una base si se da alguno de estos motivos:

1. **Upstream publicó un digest nuevo** para alguna imagen de sus `FROM`: la
   final y las de compilación (p. ej. el `golang` con el que se recompila gosu).
2. **La dorada publicada tiene parches pendientes** (`bin/parches-pendientes.sh`):
   paquetes de apk o apt con versión nueva en los repositorios de su
   distribución, o pip, setuptools o wheel con versión nueva. Los parches salen
   en los repositorios semanas antes que la imagen oficial nueva. Hasta el
   20-nov-2026 solo existía el motivo 1, y 6 de las 7 bases tenían CVE ya
   corregidas en su distribución. La base de vLLM solo cuenta los paquetes del
   repositorio de seguridad de Ubuntu, que son los únicos que instala.

Para el motivo 2, el `ARG PARCHES` de cada receta recibe una marca nueva: la
caché se invalida justo antes del `apk upgrade` / `apt-get upgrade` y los
parches se vuelven a aplicar sin recompilar lo anterior (Python, por ejemplo).
Si la imagen reconstruida sigue con los mismos pendientes, **no se publica**:
la reconstrucción no corregiría nada y solo cambiaría la huella. Un fallo en
una base no detiene las demás, y el job termina en error si hubo alguno.

Prueba sin publicar nada: `SIMULAR=1 sh bin/actualizar-nocturno.sh` (no inicia
sesión, no cambia ficheros, no construye ni publica; solo informa).
`BASES="alpine/3.24 node/22"` limita las carpetas.

## Verifícala tú mismo

La receta de cada imagen está en su carpeta (p. ej. [`postgres/16/Dockerfile`](postgres/16/Dockerfile)).
Comprobaciones rápidas sobre la imagen publicada:

```bash
# No queda ningún binario compilado con Go (la construcción FALLA si quedara):
docker run --rm --entrypoint sh ghcr.io/aynitech-group/dorada:postgres-16 \
  -c 'grep -rls "go1\." /usr/local/bin /usr/bin /bin /sbin || echo SIN_GO_OK'

# Parches aplicados (ejemplo zlib):
docker run --rm --entrypoint sh ghcr.io/aynitech-group/dorada:postgres-16 \
  -c 'apk list --installed 2>/dev/null | grep ^zlib'
```

## Historial de huellas

| Fecha | Imagen | Huella upstream de la que parte | Huella publicada |
|---|---|---|---|
| 2026-10-11 | postgres-dorada:16 | `postgres:16-alpine@sha256:721873c3…a6080ea` (17-sep-2026) | `sha256:371e74ba9284…45aeb0ed` |
| 2026-10-11 | postgres-dorada:16-con-gosu | `postgres:16-alpine@sha256:721873c3…a6080ea` + gosu 1.19 recompilado (go1.25.14) | `sha256:5e5335a79dad…5fb7384f` |
| 2026-10-11 | node-dorada:22 | `node:22-alpine@sha256:0a7108bf…2bc2e402 (oct-2026)` + npm@latest y dependencias internas corregidas | `sha256:f1d5d52260d4…8a5ed394` |

Las huellas publicadas son **inmutables**: tu proyecto, anclado por huella, no
cambia hasta que tú cambies el pin. Cuando upstream publique una base nueva,
aquí aparecerá la fila nueva con su huella; actualizar es un commit de una
línea en tu proyecto.

## ¿Te falta una base o una versión específica?

1. **Con cuenta en el GitLab corporativo:** busca el proyecto `imagenes-base`,
   copia la carpeta `PLANTILLA/` siguiendo su README y abre un Merge Request.
   Al aprobarse, la publicación aquí (GitHub/ghcr) es automática y el pipeline
   te entrega la línea `FROM` lista.
2. **Sin cuenta:** escribe al equipo de soporte de Aynitech indicando la imagen
   y versión que necesitas (p. ej. `redis:7.2-alpine`) y los CVE que te reporta
   tu análisis; ellos la publican y te responden con la línea `FROM`.

## Qué va a git y qué no

En este repositorio solo viven **recetas y documentación** (Dockerfile, README,
historial). Las imágenes construidas van al registry (`ghcr.io/aynitech-group`),
y las credenciales van en variables protegidas de CI — nunca en el código.
