#!/bin/bash
# Publica o site da Fox On: gera as páginas, troca a versão do CSS/JS (evita cache velho),
# confere as traduções, envia para a Vercel (o que vai ao ar) e guarda no GitHub.
#   ./publicar.sh "descrição do que mudou"
set -e
cd "$(dirname "$0")"
MSG="${1:-Atualização do site}"

# 1. nova versão do CSS/JS nas páginas, para o navegador não usar a cópia antiga
NOVA="v=$(date +%Y%m%d%H%M)"
grep -rlE 'v=20[0-9]{6}[0-9a-z]*' --include='*.html' . | xargs sed -i '' -E "s/v=20[0-9]{6}[0-9a-z]*/$NOVA/g"

# 2. gera as páginas (17 idiomas, blog, sitemaps)
node .i18n/extrair.js > /dev/null
node .i18n/montar.js | tail -1

# 3. confere as traduções
for p in en es ar bn de fil fr hi id it ru sv th tr vi zh; do
  node .i18n/verificar.js $p | tail -1 | grep -v ' 0 erro' || true
done

# 4. publica na Vercel
vercel deploy --prod --yes --archive=tgz | grep -E 'Aliased|readyState'

# 5. guarda no GitHub
git add -A && git commit -qm "$MSG" && git push -q origin main || echo "(GitHub: nada novo ou envio falhou — o site já está no ar pela Vercel)"
echo "Publicado: https://foxonivesting.com.br"
