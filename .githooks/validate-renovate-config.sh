#!/usr/bin/env bash
# Renovate の設定（renovate.json と presets/ 以下の preset）がコミットに含まれるとき、
# renovate-config-validator で検証する。
set -euo pipefail

# プロセス置換（< <(...)）では git diff の失敗が set -e にも pipefail にも拾われず、
# 対象なしとして検証を飛ばしてしまうので、いったん変数に受けて終了コードを確かめる。
if ! staged="$(git diff --cached --name-only --diff-filter=ACMR -- renovate.json ':(glob)presets/**/*.json')"; then
  echo 'validate-renovate-config: failed to list staged files.' >&2
  exit 1
fi
if [ -z "$staged" ]; then
  exit 0
fi
mapfile -t files <<<"$staged"

# 作業ツリーではなくステージされた内容を検証する。
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
for file in "${files[@]}"; do
  mkdir -p "$tmp_dir/$(dirname "$file")"
  git show ":$file" > "$tmp_dir/$file"
done

# devcontainer では update-content.sh でグローバルに入れてある。ない環境では npx で取得する。
# devcontainer（containerEnv で RENOVATE_CONFIG_VALIDATOR_REQUIRED=true）で見つからないのは
# update-content.sh が失敗したか実行されていないということなので、npx で取得せずに失敗させる。
if command -v renovate-config-validator >/dev/null 2>&1; then
  validator=(renovate-config-validator)
elif [ "${RENOVATE_CONFIG_VALIDATOR_REQUIRED:-}" = 'true' ]; then
  echo 'validate-renovate-config: renovate-config-validator not found. Run .devcontainer/update-content.sh.' >&2
  exit 1
elif ! command -v npx >/dev/null 2>&1; then
  echo 'validate-renovate-config: neither renovate-config-validator nor npx found. Install Node.js or Renovate.' >&2
  exit 1
else
  # devcontainer と同じバージョンで検証する。hook はリポジトリのルートで実行される。
  # shellcheck source=../.devcontainer/versions.sh
  source .devcontainer/versions.sh
  echo "validate-renovate-config: renovate-config-validator not found; falling back to npx (renovate@${RENOVATE_VERSION})." >&2
  validator=(npx --yes --package "renovate@${RENOVATE_VERSION}" -- renovate-config-validator)
fi

# ファイル名を渡すと既定では global config として検証されるので、--no-global を付けて
# repo config（preset も同じ形式）として検証させる。
# Codespaces（CODESPACES=true）では Renovate がリポジトリ名を stdin で尋ねて止まるので、
# その処理を無効にしたうえで、念のため stdin も閉じる。
(cd "$tmp_dir" && CODESPACES=false "${validator[@]}" --strict --no-global "${files[@]}" < /dev/null)
