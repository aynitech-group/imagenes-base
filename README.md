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
| **dorada:postgres-16** | `FROM ghcr.io/aynitech-group/dorada:postgres-16@sha256:eb3f48172c7713eaccd71b174367730bb8d9043b5f506901a582aaabe60d0c20` | Parches de Alpine (zlib 1.3.2-r1…) y elimina `gosu`/`su-exec` (binario Go con ~60 CVE de stdlib congelada; innecesario si tu contenedor arranca como `postgres`, que es lo normal) | 0 al publicarse |
| **dorada:postgres-16-con-gosu** | `FROM ghcr.io/aynitech-group/dorada:postgres-16-con-gosu@sha256:85217b0cd47e9b67845b05b399a496a549618e5c78d132131ddd2487676f6776` | Igual que la estándar, pero CON gosu — recompilado con Go 1.25.14 (el aviso exigía ≥1.25.7); su-exec enlaza al gosu nuevo | 0 al publicarse |
| **dorada:node-22** | `FROM ghcr.io/aynitech-group/dorada:node-22@sha256:b0d72496cea6f24444013209d8dda7ec775dcf95757dc844f7f02c841cd56dac` | Parches de Alpine, npm actualizado a la última versión y cada copia vulnerable de sus dependencias internas sustituida por la corregida (brace-expansion, ip-address, http-cache-semantics, postcss-selector-parser, undici); retira corepack y yarn. Aserción de mínimos en la construcción | 0 al publicarse |
| **dorada:alpine-3.22** | `FROM ghcr.io/aynitech-group/dorada:alpine-3.22@sha256:d7f9bff80deaef36455ed6841cc7137d267495dcc05cb9c19d054da45825728c` | Todos los parches del sistema publicados tras el digest oficial (zlib 1.3.2-r1…). Pensada como etapa final (runtime) de imágenes multi-stage; aserción de zlib | 0 al publicarse |

> Los nombres antiguos (`postgres-dorada:16`, `postgres-dorada:16-con-gosu`,
> `node-dorada:22`) siguen publicados y públicos con sus huellas intactas:
> ningún proyecto anclado se rompe. Lo nuevo se publica solo bajo `dorada`.

> ¿Necesitas `gosu`? Usa la variante `16-con-gosu` de la tabla: trae gosu
> recompilado con el toolchain de Go corregido (verifícalo: `docker run --rm
> --entrypoint gosu ghcr.io/aynitech-group/dorada:postgres-16-con-gosu --version`).

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
