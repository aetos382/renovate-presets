#!/usr/bin/env bash
# devcontainer / Codespaces の初期化。
set -euo pipefail

cd "$(dirname "$0")/.."

# .claude/settings.json に書かれている marketplace / plugin をプロジェクト スコープで
# インストールする。ローカル（Windows を含む）でも同じ処理を使うので、本体は PowerShell で書いてある。
pwsh -NoProfile -File .claude/install-plugins.ps1
