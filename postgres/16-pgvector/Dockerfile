# =============================================================================
#  Base dorada: PostgreSQL 16 (Alpine) con pgvector
#  ghcr.io/aynitech-group/dorada:postgres-16-pgvector
# =============================================================================
#  La misma receta que dorada:postgres-16 (imagen oficial postgres:16-alpine con
#  los parches de Alpine, sin gosu ni su-exec, arranca como postgres) MAS la
#  extension pgvector compilada desde su codigo fuente, con el commit verificado.
#  Sustituye a pgvector/pgvector:pg16 (Debian 12): sus CVE altas y criticas sin
#  correccion publicada no tienen arreglo dentro de Debian 12.
#  - pgvector se compila sin -march=native (OPTFLAGS=""): la imagen funciona en
#    cualquier CPU x86-64, no solo en la que la construyo. Sin bitcode de LLVM
#    (with_llvm=no): la extension no usa el JIT.
#  - La prueba final arranca un PostgreSQL temporal con ICU, crea la extension y
#    calcula una distancia: la construccion FALLA si pgvector no carga.
#  MIGRAR DESDE UNA IMAGEN DEBIAN: la ordenacion de texto de glibc (en_US.utf8)
#  no es la de musl. Inicializar con ICU (POSTGRES_INITDB_ARGS="--locale-provider=icu
#  --icu-locale=en-US-u-ka-shifted": ignora la puntuacion al ordenar, como glibc) y
#  pasar los datos con pg_dump/pg_restore, nunca copiando el volumen de datos. El
#  indice HNSW en paralelo necesita memoria compartida (shm) del tamano de
#  maintenance_work_mem.
#  Catalogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM postgres:16-alpine@sha256:1d5b02d3a9941fbd52437db4107f8c52d6297dac553ca1e5c299ebb3756b4857 AS pgvector
ARG PGVECTOR_VERSION=0.8.7
ARG PGVECTOR_COMMIT=f37c13f68b57d2c3472b2214fbcff699d6d34876
RUN set -eux; \
    apk add --no-cache --virtual .compilar build-base git; \
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v${PGVECTOR_VERSION}" \
        https://github.com/pgvector/pgvector.git /src; \
    test "$(git -C /src rev-parse HEAD)" = "$PGVECTOR_COMMIT"; \
    make -C /src OPTFLAGS="" with_llvm=no; \
    make -C /src install with_llvm=no DESTDIR=/out; \
    test -f /out/usr/local/lib/postgresql/vector.so

FROM postgres:16-alpine@sha256:1d5b02d3a9941fbd52437db4107f8c52d6297dac553ca1e5c299ebb3756b4857

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine oficial + parches apk + pgvector (sin gosu/su-exec). Base corporativa Aynitech." \
      org.opencontainers.image.licenses="PostgreSQL"

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Alpine tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apk upgrade` se vuelve a ejecutar.
ARG PARCHES

RUN apk upgrade --no-cache && rm -rf /var/cache/apk/* \
    && rm -f /usr/local/bin/gosu /usr/local/bin/su-exec \
    && ! grep -rqs "go1\." /usr/local/bin /usr/bin /bin /sbin

COPY --from=pgvector /out/usr/local/ /usr/local/

USER postgres

# Prueba: PostgreSQL temporal con ICU, la extension carga y calcula (y se borra).
RUN set -eu; d=$(mktemp -d); \
    initdb -D "$d" --auth=trust -E UTF8 --locale-provider=icu --icu-locale=en-US-u-ka-shifted >/dev/null; \
    pg_ctl -D "$d" -o "-c listen_addresses='' -k /tmp" -w start >/dev/null; \
    r=$(psql -h /tmp -d postgres -qAt -c "CREATE EXTENSION vector" \
          -c "SELECT extversion || ' ' || ('[1,2,3]'::vector <-> '[3,2,1]'::vector)::numeric(6,4) FROM pg_extension WHERE extname = 'vector'"); \
    pg_ctl -D "$d" -m fast -w stop >/dev/null; rm -rf "$d"; \
    test "$r" = "0.8.7 2.8284"; echo "asercion OK: pgvector $r"
