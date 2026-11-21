# =============================================================================
#  Base dorada: postgres 16 CON gosu actualizado
#  ghcr.io/aynitech-group/dorada:postgres-16-con-gosu
# =============================================================================
#  Para contenedores que SI necesitan gosu (arrancan como root y bajan de
#  privilegios). La imagen oficial trae gosu compilado con una stdlib de Go
#  congelada que acumulaba ~60 CVE y que upstream no ha recompilado.
#  Aqui se aplica la correccion que el aviso pide y upstream no entrega:
#  gosu se RECOMPILA con el toolchain de Go vigente (parcheado) y con sus
#  dependencias de Go al dia, y sustituye al binario de fabrica. El resto,
#  igual que la variante estandar.
#  La etapa de compilacion va anclada por digest: la actualizacion nocturna
#  sigue tambien este FROM, y cuando golang publica un parche de Go mueve el
#  ancla y recompila gosu.
FROM golang:1.27-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS gosu-actualizado
# El go.mod de gosu fija golang.org/x/sys y github.com/moby/sys/user en
# versiones con CVE (v0.1.0): se suben a la ultima antes de compilar.
# CGO_ENABLED=0: binario estatico como el original de upstream.
RUN set -eux; \
    dir=$(go mod download -json github.com/tianon/gosu@latest | grep '"Dir"' | cut -d'"' -f4); \
    test -n "$dir"; \
    mkdir -p /src && cp -a "$dir/." /src/ && chmod -R u+w /src; \
    cd /src; \
    go get golang.org/x/sys@latest github.com/moby/sys/user@latest; \
    go mod tidy; \
    CGO_ENABLED=0 go build -trimpath -o /go/bin/gosu .; \
    /go/bin/gosu --version; \
    go version -m /go/bin/gosu

FROM postgres:16-alpine@sha256:1d5b02d3a9941fbd52437db4107f8c52d6297dac553ca1e5c299ebb3756b4857

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine oficial + parches apk, con gosu RECOMPILADO con el toolchain de Go corregido. Base corporativa Aynitech." \
      org.opencontainers.image.licenses="PostgreSQL"

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de
# Alpine tiene parches que esta imagen aún no lleva: invalida la caché desde
# este punto y el `apk upgrade` se vuelve a ejecutar.
ARG PARCHES

RUN apk upgrade --no-cache && rm -rf /var/cache/apk/* \
    && rm -f /usr/local/bin/gosu /usr/local/bin/su-exec
COPY --from=gosu-actualizado /go/bin/gosu /usr/local/bin/gosu
# su-exec vuelve a ser el enlace que trae la base, ahora hacia el gosu nuevo.
# La prueba baja de root a postgres con el gosu nuevo, como hace el arranque.
RUN ln -s gosu /usr/local/bin/su-exec && gosu --version \
    && test "$(gosu postgres id -un)" = postgres
