# =============================================================================
#  Base dorada: postgres 16 CON gosu actualizado
#  ghcr.io/aynitech-group/postgres-dorada:16-con-gosu
# =============================================================================
#  Para contenedores que SI necesitan gosu (arrancan como root y bajan de
#  privilegios). La imagen oficial trae gosu compilado con una stdlib de Go
#  congelada (v1.24.6) que acumulaba ~60 CVE y que upstream no ha recompilado.
#  Aqui se aplica la correccion que el aviso pide y upstream no entrega:
#  gosu se RECOMPILA con el toolchain de Go vigente (parcheado) y sustituye
#  al binario de fabrica. El resto, igual que la variante estandar.
FROM golang:1.25-alpine AS gosu-actualizado
# CGO_ENABLED=0: binario estatico como el original de upstream.
RUN CGO_ENABLED=0 go install github.com/tianon/gosu@latest \
    && /go/bin/gosu --version

FROM postgres:16-alpine@sha256:721873c34ceb9f8d8fc265984940dc982404c105f19ad51be9fdc5970a6080ea

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base" \
      org.opencontainers.image.description="PostgreSQL 16 Alpine oficial + parches apk, con gosu RECOMPILADO con el toolchain de Go corregido. Base corporativa Aynitech." \
      org.opencontainers.image.licenses="PostgreSQL"

RUN apk upgrade --no-cache && rm -f /usr/local/bin/gosu /usr/local/bin/su-exec
COPY --from=gosu-actualizado /go/bin/gosu /usr/local/bin/gosu
# su-exec vuelve a ser el enlace que trae la base, ahora hacia el gosu nuevo.
RUN ln -s gosu /usr/local/bin/su-exec && gosu --version
