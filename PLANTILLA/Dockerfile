# =============================================================================
#  PLANTILLA de base dorada — copia esta carpeta como <tecnologia>/<version>/
#  (ej.: redis/7.2/) y rellena los 3 huecos. El pipeline hace el resto:
#  construye, escanea con Trivy y, al aprobarse tu Merge Request, publica la
#  imagen y te imprime la linea FROM lista para copiar en tu proyecto.
# =============================================================================

# ── Hueco 1: tu imagen de partida ─────────────────────────────────────────────
# Pon la imagen oficial que ibas a usar en tu FROM, con su etiqueta de version.
# No hace falta digest: el pipeline la ancla y documenta la huella por ti.
FROM redis:7.2-alpine

# Enlaza el paquete publicado con este repositorio (no lo cambies).
LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# ── Hueco 2: parches del sistema ──────────────────────────────────────────────
# Deja SOLO la linea de tu familia y borra la otra.
RUN apk upgrade --no-cache
# RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# ── Hueco 3 (opcional): limpieza ──────────────────────────────────────────────
# Binarios o herramientas que tu servicio NO usa en ejecucion y que arrastran
# avisos del escaner (compiladores, gestores de paquetes, utilidades de build).
# Ejemplo real: la base de postgres elimina gosu porque el contenedor ya
# arranca con el usuario final. Si no necesitas quitar nada, borra el bloque.
# RUN rm -f /usr/local/bin/<binario-que-no-usas>
