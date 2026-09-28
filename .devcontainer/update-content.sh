#!/usr/bin/env bash
# 開発ツールの導入。
# - ShellCheck: シェル スクリプトの静的解析に使う。
# - Renovate: pre-commit hook で Renovate の設定と preset を renovate-config-validator で検証するのに使う。
# postCreateCommand ではなく updateContentCommand で入れるのは、Codespaces の
# prebuild にこの結果を含めるため。
set -euo pipefail

# shellcheck source=versions.sh
source "$(dirname "$0")/versions.sh"

bash "$(dirname "$0")/install-shellcheck.sh"

npm install -g "renovate@${RENOVATE_VERSION}"
renovate --version
# pre-commit hook が使うのは renovate-config-validator なので、それが見つかることも作成時に確かめる。
if ! command -v renovate-config-validator >/dev/null 2>&1; then
  echo "update-content: renovate-config-validator not found after installing renovate@${RENOVATE_VERSION}." >&2
  exit 1
fi
