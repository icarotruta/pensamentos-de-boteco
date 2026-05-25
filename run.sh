#!/bin/bash

# Define o nome do tema e a pasta
THEME_NAME="paper"
THEMES_DIR="themes"

# 1. Garante que a pasta de temas exista e baixa o Hugo Paper se não estiver lá
if [ ! -d "$THEMES_DIR/$THEME_NAME" ]; then
    echo "📦 Baixando o tema Hugo Paper..."
    mkdir -p "$THEMES_DIR"
    git clone https://github.com/nanxiaobei/hugo-paper "$THEMES_DIR/$THEME_NAME"
else
    echo "✅ Tema Hugo Paper já está presente."
fi

# 2. Cria a pasta de posts se ela não existir para facilitar o uso
mkdir -p content/posts

# 3. Cria um post de exemplo caso a pasta esteja vazia
if [ -z "$(ls -A content/posts)" ]; then
    echo "📝 Criando um post de exemplo..."
    cat <<EOT > content/posts/meu-primeiro-post.md
---
title: "Meu Primeiro Post"
date: $(date +%Y-%m-%dT%H:%M:%S%z)
draft: false
---

Bem-vindo ao meu novo blog! Este é um espaço simples e minimalista focado em escrita.
EOT
fi

# 4. Sobe o ambiente usando Docker Compose
echo "🚀 Subindo o servidor do Hugo..."
docker compose up --build