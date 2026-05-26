#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT_DIR="$ROOT_DIR/content/posts"
BACKUP_DIR="$ROOT_DIR/backup"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

usage() {
  cat <<EOF
Usage:
  $0           # backup posts to $BACKUP_DIR
  $0 --restore # restore posts from the latest backup in $BACKUP_DIR
EOF
}

if [ "$#" -gt 1 ]; then
  usage
  exit 1
fi

if [ "$#" -eq 1 ] && [ "$1" != "--restore" ]; then
  usage
  exit 1
fi

backup_posts() {
  if [ ! -d "$CONTENT_DIR" ]; then
    echo "Erro: diretório de posts não existe: $CONTENT_DIR"
    exit 1
  fi

  mkdir -p "$BACKUP_DIR"
  ARCHIVE_NAME="posts-$TIMESTAMP.tar.gz"
  ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

  tar -czf "$ARCHIVE_PATH" -C "$ROOT_DIR/content" posts
  echo "✅ Backup concluído: $ARCHIVE_PATH"
}

restore_posts() {
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "Erro: diretório de backup não existe: $BACKUP_DIR"
    exit 1
  fi

  LATEST_ARCHIVE=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'posts-*.tar.gz' | sort -r | head -n 1)

  if [ -z "$LATEST_ARCHIVE" ]; then
    echo "Erro: nenhum backup encontrado em $BACKUP_DIR"
    exit 1
  fi

  TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TEMP_DIR"' EXIT

  mkdir -p "$ROOT_DIR/content"
  tar -xzf "$LATEST_ARCHIVE" -C "$TEMP_DIR"

  if [ -d "$TEMP_DIR/content/posts" ]; then
    EXTRACTED_POSTS_DIR="$TEMP_DIR/content/posts"
  elif [ -d "$TEMP_DIR/posts" ]; then
    EXTRACTED_POSTS_DIR="$TEMP_DIR/posts"
  else
    echo "Erro: backup inválido, caminho content/posts ou posts não encontrado no arquivo."
    exit 1
  fi

  mkdir -p "$CONTENT_DIR"
  restored_count=0

  while IFS= read -r -d '' src_path; do
    rel_path="${src_path#$EXTRACTED_POSTS_DIR/}"
    dest_path="$CONTENT_DIR/$rel_path"
    if [ ! -e "$dest_path" ]; then
      mkdir -p "$(dirname "$dest_path")"
      cp -a "$src_path" "$dest_path"
      restored_count=$((restored_count + 1))
      echo "✅ Restaurado: $rel_path"
    fi
  done < <(find "$EXTRACTED_POSTS_DIR" -type f -print0)

  if [ "$restored_count" -eq 0 ]; then
    echo "⚠️  Nenhum post faltante encontrado para restaurar."
  else
    echo "✅ Restauração concluída: $restored_count post(s) restaurado(s)."
  fi
}

if [ "$#" -eq 0 ]; then
  backup_posts
else
  restore_posts
fi
