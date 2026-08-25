#!/usr/bin/env bash
# Instalador remoto: baixa skills de github.com/isranetoo/skilss sem clonar o repo.
#
#   curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash -s -- grill-me
#   curl -fsSL https://raw.githubusercontent.com/isranetoo/skilss/main/get.sh | bash -s -- --list
#
# Env: SKILLS_TARGET=<projeto>  SKILLS_REF=<branch>  SKILLS_FORCE=1
set -euo pipefail

repo="isranetoo/skilss"
ref="${SKILLS_REF:-main}"
force="${SKILLS_FORCE:-0}"
do_list=0
wanted=()

while [ $# -gt 0 ]; do
  case "$1" in
    --list)   do_list=1; shift ;;
    --force)  force=1; shift ;;
    --ref)    ref="${2:?--ref requer um valor}"; shift 2 ;;
    --target) SKILLS_TARGET="${2:?--target requer um caminho}"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *)        wanted+=("$1"); shift ;;
  esac
done

if [ -n "${SKILLS_TARGET:-}" ]; then
  [ -d "$SKILLS_TARGET" ] || { echo "Destino nao existe: $SKILLS_TARGET" >&2; exit 1; }
  dest="$SKILLS_TARGET/.claude/skills"
else
  dest="$HOME/.claude/skills"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Baixando $repo@$ref ..."
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$ref" | tar -xz -C "$tmp"

skills_dir="$(find "$tmp" -mindepth 2 -maxdepth 2 -type d -name skills | head -1)"
[ -n "$skills_dir" ] || { echo "O repo nao contem 'skills/' no ref '$ref'." >&2; exit 1; }

list_available() {
  find "$skills_dir" -mindepth 2 -maxdepth 2 -name SKILL.md -exec dirname {} \; | sort
}

if [ $do_list -eq 1 ]; then
  while read -r d; do
    [ -n "$d" ] || continue
    printf '%-20s %s\n' "$(basename "$d")" \
      "$(sed -n 's/^description:[[:space:]]*//p' "$d/SKILL.md" | head -1)"
  done < <(list_available)
  exit 0
fi

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
  if [ -e "$out" ] && [ "$force" != "1" ]; then
    echo "SKIP  $name (ja existe; use --force)"
    continue
  fi
  rm -rf "$out"
  cp -R "$src" "$out"
  echo "OK    $name"
  installed=$((installed + 1))
done < <(list_available)

echo
echo "$installed skill(s) em: $dest"
echo "Reinicie o Claude Code para carregar."
