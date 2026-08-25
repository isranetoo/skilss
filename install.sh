#!/usr/bin/env bash
# Instala skills deste repositório em ~/.claude/skills ou no .claude/skills de um projeto.
#
#   ./install.sh --global
#   ./install.sh --global fastapi-endpoints commit-helper
#   ./install.sh --target /caminho/do/projeto
#   ./install.sh --list
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills_dir="$repo_dir/skills"
[ -d "$skills_dir" ] || { echo "Pasta 'skills/' não encontrada em $repo_dir" >&2; exit 1; }

list_available() {
  find "$skills_dir" -mindepth 2 -maxdepth 2 -name SKILL.md -exec dirname {} \; | sort
}

dest=""
force=0
declare -a wanted=()

while [ $# -gt 0 ]; do
  case "$1" in
    --global)  dest="$HOME/.claude/skills"; shift ;;
    --target)  dest="${2:?--target requer um caminho}/.claude/skills"; shift 2 ;;
    --force)   force=1; shift ;;
    --list)
      while read -r d; do
        [ -n "$d" ] || continue
        desc=$(sed -n 's/^description:[[:space:]]*//p' "$d/SKILL.md" | head -1)
        printf '%-30s %s\n' "$(basename "$d")" "$desc"
      done < <(list_available)
      exit 0 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *)         wanted+=("$1"); shift ;;
  esac
done

[ -n "$dest" ] || { echo "Informe --global, --target <pasta> ou --list" >&2; exit 1; }
mkdir -p "$dest"

installed=0
while read -r src; do
  [ -n "$src" ] || continue
  name="$(basename "$src")"
  if [ ${#wanted[@]} -gt 0 ]; then
    match=0
    for w in "${wanted[@]}"; do [ "$w" = "$name" ] && match=1; done
    [ $match -eq 1 ] || continue
  fi
  out="$dest/$name"
  if [ -e "$out" ] && [ $force -eq 0 ]; then
    echo "SKIP  $name (já existe; use --force)"
    continue
  fi
  rm -rf "$out"
  cp -R "$src" "$out"
  echo "OK    $name -> $out"
  installed=$((installed + 1))
done < <(list_available)

echo
echo "$installed skill(s) instalada(s) em: $dest"
echo "Reinicie o Claude Code (ou rode /skills) para carregar."
