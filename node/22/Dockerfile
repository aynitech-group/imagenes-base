# Base dorada corporativa de Node 22: node:22-alpine con las correcciones
# publicadas aplicadas. El npm que trae la base arrastra copias propias de
# paquetes con CVE ya corregidos en el registro (brace-expansion, ip-address,
# pacote, sigstore, picomatch, http-cache-semantics, postcss-selector-parser);
# aquí se sube npm a la última versión y se sustituye CADA copia restante por
# su versión corregida. corepack y yarn se retiran: ningún proyecto corporativo
# los usa y son superficie de ataque. La aserción final impide publicar una
# base con alguna copia por debajo del mínimo corregido.
# Catálogo y huellas: https://github.com/aynitech-group/imagenes-base
FROM node:22-alpine@sha256:fe4f6d74e20370acb04ad889077d14d0f64a9c8ea6a42bc60cddf1e844699914

RUN set -eu \
 && apk upgrade --no-cache \
 && npm install -g npm@latest --no-fund --no-audit \
 && cd /tmp \
 && for spec in brace-expansion@latest ip-address@latest http-cache-semantics@latest \
                postcss-selector-parser@latest undici@6.28.1; do \
      pkg=${spec%@*}; \
      tgz=$(npm pack "$spec" 2>/dev/null | tail -1); \
      find /usr/local/lib/node_modules -type d -name "$pkg" | while read -r d; do \
        { [ -f "$d/package.json" ] && grep -q "\"name\": \"$pkg\"" "$d/package.json"; } || continue; \
        rm -rf "$d" && mkdir -p "$d" && tar -xzf "/tmp/$tgz" -C "$d" --strip-components=1; \
      done; \
      rm -f "/tmp/$tgz"; \
    done \
 && rm -rf /usr/local/lib/node_modules/corepack /usr/local/bin/corepack \
           /usr/local/bin/yarn /usr/local/bin/yarnpkg /opt/yarn* \
 && npm cache clean --force \
 && node -e ' \
    const fs=require("fs"),path=require("path"); \
    const MIN={"brace-expansion":"5.0.12","ip-address":"10.7.1","http-cache-semantics":"4.3.0", \
               "postcss-selector-parser":"7.1.6","picomatch":"4.0.4","pacote":"21.5.1", \
               "sigstore":"4.1.1","@sigstore/core":"3.2.1","undici":"6.28.1"}; \
    const cmp=(a,b)=>{const x=String(a).split(".").map(n=>parseInt(n)||0),y=String(b).split(".").map(n=>parseInt(n)||0); \
      for(let i=0;i<3;i++){if(x[i]!==y[i])return x[i]-y[i]}return 0}; \
    let bad=[]; \
    (function walk(d){for(const e of fs.readdirSync(d,{withFileTypes:true})){const p=path.join(d,e.name); \
      if(e.isDirectory())walk(p); \
      else if(e.name==="package.json"){try{const j=JSON.parse(fs.readFileSync(p)); \
        if(MIN[j.name]&&j.version&&cmp(j.version,MIN[j.name])<0)bad.push(j.name+"@"+j.version+" en "+p)}catch(_){}}}})("/usr/local/lib/node_modules"); \
    if(bad.length){console.error("VULNERABLES:\n"+bad.join("\n"));process.exit(1)} \
    if(fs.existsSync("/usr/local/bin/yarn")||fs.existsSync("/usr/local/lib/node_modules/corepack")){console.error("corepack/yarn siguen presentes");process.exit(1)} \
    console.log("asercion OK: npm "+require("child_process").execSync("npm --version").toString().trim()+", sin copias vulnerables, sin corepack/yarn")'
