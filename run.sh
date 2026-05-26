#!/bin/bash
set -e

THEME_DIR="themes/ink"
THEME_REPO="https://github.com/vinooganesh/hugo-ink.git"
CONFIG_FILE="hugo.toml"
SEARCH_FILE="content/search.md"
SEARCH_JS="$THEME_DIR/assets/js/search.js"

mkdir -p content/posts
mkdir -p static/images
mkdir -p themes

if [ ! -d "$THEME_DIR" ]; then
  echo "📦 Instalando tema Ink..."
  git clone "$THEME_REPO" "$THEME_DIR"
else
  echo "✅ Tema Ink já presente."
fi

ensure_search_page() {
  if [ ! -f "$SEARCH_FILE" ]; then
    cat > "$SEARCH_FILE" <<'EOT'
---
title: "Buscar"
layout: "search"
searchHidden: true
---
EOT
    echo "✅ Criado $SEARCH_FILE"
  fi
}

patch_search_js() {
  if [ -f "$SEARCH_JS" ] && ! grep -q 'let seen = new Set()' "$SEARCH_JS"; then
    python3 - "$SEARCH_JS" <<'PY'
import pathlib
path = pathlib.Path(sys.argv[1])
text = path.read_text()
needle = '    let results = fuse.search(term, { limit: 10 });\n    if (results.length === 0) {\n'
replacement = '''    let results = fuse.search(term, { limit: 20 });
    let seen = new Set();
    let uniqueResults = [];

    results.forEach(function (r) {
      if (!seen.has(r.item.permalink)) {
        seen.add(r.item.permalink);
        uniqueResults.push(r);
      }
    });

    results = uniqueResults.slice(0, 10);

    if (results.length === 0) {\n'''
if needle in text:
    text = text.replace(needle, replacement)
    path.write_text(text)
    print('patched')
else:
    raise SystemExit('pattern not found')
PY
    echo "✅ Corrigido $SEARCH_JS para remover resultados duplicados"
  fi
}

ensure_search_page
patch_search_js

if [ -f "$CONFIG_FILE" ]; then
  if ! grep -Eq '^\s*theme\s*=\s*"' "$CONFIG_FILE"; then
    echo 'theme = "ink"' >> "$CONFIG_FILE"
    echo "✅ Adicionado theme = \"ink\" em $CONFIG_FILE"
  else
    if ! grep -Eq '^\s*theme\s*=\s*"ink"' "$CONFIG_FILE"; then
      sed -i 's/^\s*theme\s*=\s*\".*\"/theme = "ink"/' "$CONFIG_FILE"
      echo "✅ Configurado theme = \"ink\" no $CONFIG_FILE"
    fi
  fi
else
  cat > "$CONFIG_FILE" <<'TOML'
baseURL = 'http://localhost:1313/'
languageCode = 'pt-br'
title = 'Pensamentos de Boteco'
theme = 'ink'

[params]
  author = 'Icarotruta'
  description = 'Escrevendo sobre crônicas, pensamentos e o cotidiano.'
  homeTitle = 'Pensamentos de Boteco'
  homeSubtitle = 'Crônicas e pensamentos do cotidiano'
  homeBio = 'Textos breves, pensamentos e histórias de boteco.'
  homeImage = '/images/avatar.png'
  recentPostsCount = 5

  [[params.socialLinks]]
    name = 'Blog'
    url = '/posts/'
    external = false

[menu]
  [[menu.main]]
    name = 'Blog'
    url = '/posts/'
    weight = 1

[outputs]
  home = ['HTML', 'RSS', 'llmstxt', 'JSON']

[outputFormats.llmstxt]
  mediaType = 'text/plain'
  baseName = 'llms'
  isPlainText = true
  notAlternative = true
TOML
  echo "✅ Criado $CONFIG_FILE mínimo com theme Ink."
fi

echo "🚀 Subindo o servidor do Hugo via Docker Compose..."
CURRENT_USER="$(id -u):$(id -g)" docker compose up --build
