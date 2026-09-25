#!/usr/bin/env bash
# Renovate の設定（renovate.json と presets/ 以下の preset）がコミットに含まれるとき、
# renovate-config-validator で検証する。
set -euo pipefail

mapfile -t files < <(git diff --cached --name-only --diff-filter=ACMR -- renovate.json ':(glob)presets/**/*.json')
if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

# 作業ツリーではなくステージされた内容を検証する。
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
for file in "${files[@]}"; do
  mkdir -p "$tmp_dir/$(dirname "$file")"
  git show ":$file" > "$tmp_dir/$file"
done

# devcontainer では update-content.sh でグローバルに入れてある。ない環境では npx で取得する。
if command -v renovate-config-validator >/dev/null 2>&1; then
  validator=(renovate-config-validator)
else
  validator=(npx --yes --package renovate -- renovate-config-validator)
fi

# ファイル名を渡すと既定では global config として検証されるので、--no-global を付けて
# repo config（preset も同じ形式）として検証させる。
# Codespaces（CODESPACES=true）では Renovate がリポジトリ名を stdin で尋ねて止まるので、
# その処理を無効にしたうえで、念のため stdin も閉じる。
(cd "$tmp_dir" && CODESPACES=false "${validator[@]}" --strict --no-global "${files[@]}" < /dev/null)
