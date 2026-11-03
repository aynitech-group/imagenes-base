# Base dorada corporativa de Node 22: node:22-alpine con las correcciones
# publicadas aplicadas. El npm que trae la base arrastra copias propias de
# paquetes con CVE ya corregidos en el registro (brace-expansion, ip-address,
# pacote, sigstore, picomatch, http-cache-semantics, postcss-selector-parser,
# undici, glob, minimatch); aquí se sube npm a la última versión y se sustituye
# CADA copia restante por su versión corregida. glob y minimatch solo tienen la
# corrección en su versión mayor nueva (14.0.2 y 11.0.1), que pide paquetes que
# el npm de la base no trae: cada versión nueva se copia con sus dependencias en
# su propio node_modules, y la prueba de abajo comprueba que npm sigue
# funcionando con ellas. corepack y yarn se retiran:
# ningún proyecto corporativo los usa y son superficie de ataque. La aserción
# final impide publicar una base con alguna copia por debajo del mínimo corregido.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM node:22-alpine@sha256:fe4f6d74e20370acb04ad889077d14d0f64a9c8ea6a42bc60cddf1e844699914

RUN set -eu \
 && apk upgrade --no-cache \
 && npm install -g npm@latest --no-fund --no-audit \
 && cd /tmp \
 && for spec in brace-expansion@latest ip-address@latest http-cache-semantics@latest \
                postcss-selector-parser@latest undici@6 glob@latest minimatch@latest; do \
      pkg=${spec%@*}; \
      rm -rf /tmp/pkg && mkdir -p /tmp/pkg; \
      ( cd /tmp/pkg && npm install --no-save --no-package-lock --ignore-scripts --no-audit --no-fund "$spec" >/dev/null ); \
      rm -f /tmp/pkg/node_modules/.package-lock.json; \
      for d in $(find /usr/local/lib/node_modules -type d -name "$pkg"); do \
        { [ -f "$d/package.json" ] && grep -q "\"name\": \"$pkg\"" "$d/package.json"; } || continue; \
        rm -rf "$d" && cp -a "/tmp/pkg/node_modules/$pkg" "$d"; \
        mkdir -p "$d/node_modules" && cp -a /tmp/pkg/node_modules/. "$d/node_modules/"; \
        rm -rf "$d/node_modules/$pkg"; \
        rmdir "$d/node_modules" 2>/dev/null || true; \
      done; \
    done \
 && rm -rf /tmp/pkg \
 && for d in $(find /usr/local/lib/node_modules -type d \( -name glob -o -name minimatch \)); do \
      [ -f "$d/package.json" ] || continue; \
      node -e 'require(process.argv[1])' "$d" || { echo "no carga con require: $d"; exit 1; }; \
    done \
 && rm -rf /usr/local/lib/node_modules/corepack /usr/local/bin/corepack \
           /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn* \
 && npm cache clean --force \
 && node -e ' \
    const fs=require("fs"),path=require("path"); \
    const MIN={"brace-expansion":"5.0.12","ip-address":"10.7.1","http-cache-semantics":"4.3.0", \
               "postcss-selector-parser":"7.1.6","picomatch":"4.0.4","pacote":"21.5.1", \
               "sigstore":"4.1.1","@sigstore/core":"3.2.1","undici":"6.29.1", \
               "glob":"14.0.2","minimatch":"11.0.1"}; \
    const cmp=(a,b)=>{const x=String(a).split(".").map(n=>parseInt(n)||0),y=String(b).split(".").map(n=>parseInt(n)||0); \
      for(let i=0;i<3;i++){if(x[i]!==y[i])return x[i]-y[i]}return 0}; \
    let bad=[]; \
    (function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name); \
      if(e.isDirectory())walk(p); \
      else if(e.name==="package.json"){try{const j=JSON.parse(fs.readFileSync(p)); \
        if(MIN[j.name]&&j.version&&cmp(j.version,MIN[j.name])<0)bad.push(j.name+"@"+j.version+" en "+p)}catch(_){}}}})("/usr/local/lib/node_modules"); \
    if(bad.length){console.error("VULNERABLES:\n"+bad.join("\n"));process.exit(1)} \
    if(fs.existsSync("/usr/local/bin/yarn")||fs.existsSync("/usr/local/lib/node_modules/corepack")){console.error("corepack/yarn siguen presentes");process.exit(1)} \
    console.log("asercion OK: npm "+require("child_process").execSync("npm --version").toString().trim()+", sin copias vulnerables, sin corepack/yarn")' \
 && mkdir -p /tmp/prueba-npm && cd /tmp/prueba-npm \
 && printf '{"name":"prueba","version":"1.0.0","files":["index.js"]}' > package.json \
 && echo 'module.exports = 1' > index.js \
 && npm pack --dry-run >/dev/null \
 && npm install --no-fund --no-audit --package-lock-only >/dev/null \
 && cd / && rm -rf /tmp/prueba-npm \
 && echo "prueba OK: npm empaqueta e instala con glob y minimatch nuevos"
