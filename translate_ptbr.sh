#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
I18N_DIR="$ROOT_DIR/i18n"
LAYOUTS_DIR="$ROOT_DIR/layouts/partials"
CONFIG_FILE="$ROOT_DIR/hugo.toml"

mkdir -p "$I18N_DIR"
mkdir -p "$LAYOUTS_DIR"

cat > "$I18N_DIR/pt-br.yaml" <<'YAML'
prev: "← Anterior"
next: "Próxima →"
min_read:
  one: "1 min de leitura"
  other: "{{ .Count }} min de leitura"
page_not_found: "Página não encontrada"
back_home: "Voltar para a página inicial"
toggle_theme: "Alternar tema"
search: "Buscar"
search_placeholder: "Digite para buscar..."
search_no_results: "Nenhum resultado encontrado."
search_unavailable: "Índice de busca indisponível."
search_requires_js: "A busca requer JavaScript habilitado."
recent: "Recentes"
view_all: "Ver todos"
scroll_to_top: "Ir ao topo"
copy: "copiar"
copied: "Copiado!"
ask_ai_label: "Perguntar à IA sobre este site"
toc_title: "Sumário"
related_posts: "Posts relacionados"
series: "Série"
YAML

echo "✅ Tradução criada em $I18N_DIR/pt-br.yaml"

if [ -f "$CONFIG_FILE" ]; then
  if grep -Eq '^\s*theme\s*=\s*"' "$CONFIG_FILE"; then
    sed -i 's/^\s*theme\s*=\s*".*"/theme = "ink"/' "$CONFIG_FILE"
  else
    printf '\ntheme = "ink"\n' >> "$CONFIG_FILE"
  fi
  if grep -Eq '^\s*languageCode\s*=\s*' "$CONFIG_FILE"; then
    sed -i 's/^\s*languageCode\s*=\s*.*/languageCode = "pt-br"/' "$CONFIG_FILE"
    echo "✅ Atualizado languageCode para pt-br em $CONFIG_FILE"
  else
    printf '\nlanguageCode = "pt-br"\n' >> "$CONFIG_FILE"
    echo "✅ Adicionado languageCode = \"pt-br\" em $CONFIG_FILE"
  fi
else
  echo "⚠️  Arquivo $CONFIG_FILE não encontrado. Crie um hugo.toml válido na raiz do projeto."
fi

cat > "$LAYOUTS_DIR/date-ptbr.html" <<'HTML'
{{- $date := .Date -}}
{{- $months := dict
  "January" "janeiro"
  "February" "fevereiro"
  "March" "março"
  "April" "abril"
  "May" "maio"
  "June" "junho"
  "July" "julho"
  "August" "agosto"
  "September" "setembro"
  "October" "outubro"
  "November" "novembro"
  "December" "dezembro"
-}}
{{- $month := index $months ($date.Format "January") -}}
{{- printf "%s de %s de %s" ($date.Format "2") $month ($date.Format "2006") -}}
HTML

cat > "$LAYOUTS_DIR/post_meta.html" <<'HTML'
<span class="post-meta">
  {{- if not .Date.IsZero }}
  <span><time datetime="{{ .Date.Format "2006-01-02" }}">{{ partial "date-ptbr.html" . }}</time></span>
  {{- end }}
  {{- if gt .ReadingTime 0 }}
  <span>{{ i18n "min_read" .ReadingTime | default (printf "%d min read" .ReadingTime) }}</span>
  {{- end }}
</span>
HTML

cat > "$LAYOUTS_DIR/related.html" <<'HTML'
{{- $related := .Site.RegularPages.Related . | first 3 }} {{- with $related }}
<section class="related-posts">
    <h2>{{ i18n "related_posts" | default "Related Posts" }}</h2>
    <div class="related-grid">
        {{- range . }}
        <a href="{{ .Permalink }}" class="related-entry">
            <h3>{{ .Title }}</h3>
            <span class="post-meta"><span>{{ partial "date-ptbr.html" . }}</span></span>
        </a>
        {{- end }}
    </div>
</section>
{{- end }}
HTML

echo "✅ Layouts de data traduzida criados em $LAYOUTS_DIR"
