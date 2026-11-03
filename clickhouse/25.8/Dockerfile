# Base dorada corporativa de ClickHouse 25.8 LTS (Alpine): la imagen oficial con
# los parches de Alpine publicados después de su digest (OpenSSL libssl3 y
# libcrypto3, zlib y musl). Los escáneres analizan la base que declara el FROM
# tal cual se publica, así que el `apk upgrade` tiene que venir de fábrica y no
# en el Dockerfile de cada proyecto. No cambia nada más de la imagen oficial: ni
# el usuario, ni la configuración, ni el punto de entrada. La aserción final
# impide publicarla con algún paquete por debajo del mínimo corregido.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM clickhouse/clickhouse-server:25.8-alpine@sha256:87e0a5b72f5465b18eacca7c76850e7ff551c9795c50e451f5646299e5e24146

RUN set -eu \
 && apk upgrade --no-cache \
 && for req in libssl3=3.5.8-r0 libcrypto3=3.5.8-r0 zlib=1.3.2-r1 musl=1.2.6-r3 musl-utils=1.2.6-r3; do \
      pkg=${req%%=*}; min=${req#*=}; \
      v=$(apk list -I "$pkg" 2>/dev/null | sed -n "s/^$pkg-\([0-9][^ ]*\) .*/\1/p" | head -n 1); \
      [ -n "$v" ] || { echo "falta $pkg"; exit 1; }; \
      [ "$(apk version -t "$v" "$min")" != "<" ] || { echo "VULNERABLE: $pkg $v (mínimo $min)"; exit 1; }; \
      echo "$pkg $v (mínimo $min)"; \
    done \
 && clickhouse-server --version \
 && echo "asercion OK: parches de Alpine aplicados"
