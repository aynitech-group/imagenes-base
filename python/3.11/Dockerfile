# Base dorada corporativa de Python 3.11 sobre Debian 13 (trixie) slim: Python
# compilado con la MISMA receta de la imagen oficial (docker-library/python,
# 3.11/slim-trixie), verificando la firma GPG y el SHA256 del código fuente.
# Existe porque la imagen oficial python:3.11-slim tardaba en publicar la 3.11.18
# (correcciones de seguridad de octubre de 2026). Cuando la oficial la traiga,
# esta receta puede pasar a la forma de la PLANTILLA (FROM python:3.11-slim).
# La aserción final impide publicar si Python no es la versión esperada o si
# ssl/sqlite3 no cargan.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
#

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

LABEL org.opencontainers.image.source="https://github.com/aynitech-group/imagenes-base"

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# cannot remove LANG even though https://bugs.python.org/issue19846 is fixed
# - embedded interpreters (uWSGI, mod_wsgi, etc) skip locale coercion and UTF-8 mode before Python 3.15, so they fall back to ASCII
# - musl (alpine) never gets LC_CTYPE set, so anything that reads locale environment variables (babel) finds none
# last attempted removal of LANG broke many users:
# https://github.com/docker-library/python/pull/570
# embedded interpreter reproducer (fails with UnicodeEncodeError without LANG on 3.14 and earlier, needs a non-slim Debian variant for gcc):
# docker run --rm --env LANG= python:3.11 sh -c 'printf "#include <Python.h>\nint main(){Py_Initialize();PyRun_SimpleString(\"print(chr(252),flush=True)\");}" | gcc -x c - $(python3-config --embed --cflags --ldflags) && ./a.out'
ENV LANG C.UTF-8

# runtime dependencies
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		netbase \
		tzdata \
	; \
	apt-get dist-clean

ENV GPG_KEY A035C8C19219BA821ECEA86B64E628F8D684696D
ENV PYTHON_VERSION 3.11.18
ENV PYTHON_SHA256 9120e0a653868f6e3698d36cdd99e5a58903ec9469e448f21d98f7b16d8fa290

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		dpkg-dev \
		g++ \
		gcc \
		gnupg \
		libbluetooth-dev \
		libbz2-dev \
		libc6-dev \
		libdb-dev \
		libffi-dev \
		libgdbm-dev \
		liblzma-dev \
		libncursesw5-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		tk-dev \
		uuid-dev \
		wget \
		xz-utils \
		zlib1g-dev \
	; \
	\
	wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz"; \
	echo "$PYTHON_SHA256 *python.tar.xz" | sha256sum -c -; \
	wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc"; \
	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY"; \
	gpg --batch --verify python.tar.xz.asc python.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" python.tar.xz.asc; \
	mkdir -p /usr/src/python; \
	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz; \
	rm python.tar.xz; \
	\
	cd /usr/src/python; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		$(test "${gnuArch%%-*}" != 'riscv64' && echo '--with-lto') \
		--with-ensurepip \
	; \
	nproc="$(nproc)"; \
	EXTRA_CFLAGS="$(dpkg-buildflags --get CFLAGS)"; \
	LDFLAGS="$(dpkg-buildflags --get LDFLAGS)"; \
	LDFLAGS="${LDFLAGS:-} -Wl,--strip-all"; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:-}" \
	; \
# https://github.com/docker-library/python/issues/784
# prevent accidental usage of a system installed libpython of the same version
	rm python; \
	make -j "$nproc" \
		"EXTRA_CFLAGS=${EXTRA_CFLAGS:-}" \
		"LDFLAGS=${LDFLAGS:-} -Wl,-rpath='\$\$ORIGIN/../lib'" \
		python \
	; \
	make install; \
	\
	cd /; \
	rm -rf /usr/src/python; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
		\) -exec rm -rf '{}' + \
	; \
	\
	ldconfig; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
		| sort -u \
		| xargs -rt dpkg-query --search \
# https://manpages.debian.org/bookworm/dpkg/dpkg-query.1.en.html#S (we ignore diversions and it'll be really unusual for more than one package to provide any given .so file)
		| awk 'sub(":$", "", $1) { print $1 }' \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	apt-get dist-clean; \
	\
	export PYTHONDONTWRITEBYTECODE=1; \
	python3 --version; \
	\
	pip3 install \
		--disable-pip-version-check \
		--no-cache-dir \
		--no-compile \
		'setuptools==79.0.1' \
		'wheel==0.46.3' \
	; \
	pip3 --version

# make some useful symlinks that are expected to exist ("/usr/local/bin/python" and friends)
RUN set -eux; \
	for src in idle3 pip3 pydoc3 python3 python3-config; do \
		dst="$(echo "$src" | tr -d 3)"; \
		[ -s "/usr/local/bin/$src" ]; \
		[ ! -e "/usr/local/bin/$dst" ]; \
		ln -svT "$src" "/usr/local/bin/$dst"; \
	done

# La actualización nocturna pasa aquí una marca nueva cuando el repositorio de Debian
# o pip tienen parches que esta imagen aún no lleva: invalida la caché desde este punto
# y se vuelven a aplicar sin recompilar Python.
ARG PARCHES

# Parches del sistema publicados después del digest de Debian, pip/setuptools/wheel al
# día y aserción de publicación. El pip que trae Python 3.11 (24.0) y el setuptools de la
# receta oficial (79.0.1, con wheel y jaraco.context viejos dentro de setuptools/_vendor)
# arrastran CVE ya corregidos; la aserción impide publicar la base con alguno por debajo
# del mínimo, o con zlib1g sin el parche de seguridad de Debian.
RUN set -eu \
 && apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/* \
 && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' zlib1g)" ge '1:1.3.dfsg+really1.3.1-1+deb13u1' \
 && PIP_ROOT_USER_ACTION=ignore python3 -m pip install --disable-pip-version-check --no-cache-dir --no-compile \
      --upgrade 'pip>=26.2' 'setuptools>=84.1.0' 'wheel>=0.46.2' \
 && test "$(python3 -c 'import platform;print(platform.python_version())')" = "$PYTHON_VERSION" \
 && python3 -c 'import ssl, sqlite3, hashlib, zlib, ctypes; print("asercion OK: Python", __import__("sys").version.split()[0], "|", ssl.OPENSSL_VERSION)' \
 && python3 -c 'import sys; from importlib.metadata import version as v; \
      n = lambda s: tuple(int(x) for x in s.split(".")[:3]); \
      m = {"pip": "26.2", "setuptools": "84.1.0", "wheel": "0.46.2"}; \
      mal = [f"{p} {v(p)} (minimo {x})" for p, x in m.items() if n(v(p)) < n(x)]; \
      print("asercion OK:" if not mal else "VULNERABLE:", ", ".join(mal or [f"{p} {v(p)}" for p in m])); \
      sys.exit(1 if mal else 0)'

CMD ["python3"]
