#!/bin/bash

SRC_DIR="novos-posts"
export CURRENT_USER="$(id -u):$(id -g)"

# 1. Verifica se a pasta de novos posts existe e tem conteúdo
if [ ! -d "$SRC_DIR" ] || [ -z "$(ls -A "$SRC_DIR")" ]; then
    echo "📂 A pasta '$SRC_DIR' está vazia. Crie uma subpasta com um 'texto.txt' dentro."
    exit 0
fi

# 2. Varre as subpastas de novos-posts
for POST_DIR in "$SRC_DIR"/*/; do
    # Remove a barra no final do caminho para pegar o nome da pasta
    DIR_NAME=$(basename "$POST_DIR")
    TXT_FILE="$POST_DIR/texto.txt"

    # Se não tiver o arquivo de texto, pula para a próxima pasta
    if [ ! -f "$TXT_FILE" ]; then
        ls -la
        echo "⚠️  Pasta '$DIR_NAME' ignorada (falta o arquivo texto.txt)."
        continue
    fi

    # 3. Extrai o título e gera o nome limpo (Slug)
    TITULO=$(head -n 1 "$TXT_FILE")
    SLUG=$(echo "$TITULO" | iconv -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//')
    
    TARGET_DIR="content/posts/$SLUG"

    if [ -d "$TARGET_DIR" ]; then
        echo "⚠️  O post '$SLUG' já existe no Hugo. Pulando..."
        continue
    fi

    echo "📝 Processando post: '$TITULO'..."

    # 4. Cria a estrutura de Page Bundle usando o Hugo no Docker
    # O Hugo criará a pasta content/posts/slug/index.md
    docker compose run --rm --no-deps hugo new "posts/$SLUG/index.md"

    TARGET_MD="$TARGET_DIR/index.md"

    # 5. Verifica se existe uma imagem na pasta temporária
    IMAGE_FILE=$(find "$POST_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | head -n 1)
    
    if [ ! -z "$IMAGE_FILE" ]; then
        IMG_NAME=$(basename "$IMAGE_FILE")
        echo "📸 Imagem encontrada: $IMG_NAME. Configurando como capa..."
        
        # Copia a imagem para a pasta final do post no Hugo
        cp "$IMAGE_FILE" "$TARGET_DIR/$IMG_NAME"
        
        # Injeta a imagem no parâmetro 'image' do frontmatter do tema Ink
        # Usamos o sed para colocar a linha da imagem logo abaixo do título no .md
        sed -i "/title:/a image: \"$IMG_NAME\"" "$TARGET_MD"
    fi

    # 6. Injeta o corpo do texto (pulando a primeira linha que é o título)
    tail -n +2 "$TXT_FILE" >> "$TARGET_MD"

    echo "✨ Post '$TITULO' criado com sucesso!"

    # 7. Limpa a pasta do rascunho para não reprocessar na próxima execução
    rm -rf "$POST_DIR"
done