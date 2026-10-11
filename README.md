# Imágenes base corporativas de Aynitech («bases doradas»)

Imágenes base de contenedor **ya corregidas de fábrica**: parten de la imagen
oficial, aplican los parches del sistema publicados después de su digest y
retiran (o actualizan) los binarios vulnerables que la imagen oficial arrastra.
Los escáneres de seguridad (Trivy, AyniInspect, etc.) analizan la imagen base
que declara tu `FROM` **tal cual se publica** — por eso la corrección debe
venir de fábrica y no en un `RUN` de tu Dockerfile, que el escáner no ejecuta.

## Catálogo

| Imagen | Línea `FROM` lista para copiar | Qué corrige | CVE restantes |
|---|---|---|---|
| **postgres-dorada:16** | `FROM ghcr.io/aynitech-group/postgres-dorada:16@sha256:371e74ba9284b1972297726ddca0cdf07f78be6bb73559dc71dd794645aeb0ed` | Parches de Alpine (zlib 1.3.2-r1…) y elimina `gosu`/`su-exec` (binario Go con ~60 CVE de stdlib congelada; innecesario si tu contenedor arranca como `postgres`, que es lo normal) | 0 al publicarse |
| **postgres-dorada:16-con-gosu** | `FROM ghcr.io/aynitech-group/postgres-dorada:16-con-gosu@sha256:5e5335a79dade4002b614ad252ccb2ff540149ca0b0fe85d5718bfea5fb7384f` | Igual que la estándar, pero CON gosu — recompilado con Go 1.25.14 (el aviso exigía ≥1.25.7); su-exec enlaza al gosu nuevo | 0 al publicarse |
| **node-dorada:22** | `FROM ghcr.io/aynitech-group/node-dorada:22@sha256:f1d5d52260d4247d72ff65a9649635f638374f0e63e99c57b5ef3ed28a5ed394` | Parches de Alpine (zlib 1.3.2-r1…), npm actualizado a la última versión y **cada copia vulnerable** de sus dependencias internas sustituida por la corregida (brace-expansion, ip-address, http-cache-semantics, postcss-selector-parser, undici); retira corepack y yarn (superficie innecesaria). Una aserción en la construcción impide publicar si queda alguna copia por debajo del mínimo corregido | 0 al publicarse |

> ¿Necesitas `gosu`? Usa la variante `16-con-gosu` de la tabla: trae gosu
> recompilado con el toolchain de Go corregido (verifícalo: `docker run --rm
> --entrypoint gosu ghcr.io/aynitech-group/postgres-dorada:16-con-gosu --version`).

## Verifícala tú mismo

La receta de cada imagen está en su carpeta (p. ej. [`postgres/16/Dockerfile`](postgres/16/Dockerfile)).
Comprobaciones rápidas sobre la imagen publicada:

```bash
# No queda ningún binario compilado con Go (la construcción FALLA si quedara):
docker run --rm --entrypoint sh ghcr.io/aynitech-group/postgres-dorada:16 \
  -c 'grep -rls "go1\." /usr/local/bin /usr/bin /bin /sbin || echo SIN_GO_OK'

# Parches aplicados (ejemplo zlib):
docker run --rm --entrypoint sh ghcr.io/aynitech-group/postgres-dorada:16 \
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
