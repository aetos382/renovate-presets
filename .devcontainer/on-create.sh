#!/usr/bin/env bash
# devcontainer / Codespaces の初期化のうち、ネットワークに依存しないもの。
# updateContentCommand（ツールのダウンロード）が失敗すると postCreateCommand は実行されないので、
# 失敗しても気付きにくい hook の有効化は、それより前に実行される onCreateCommand で行う。
set -euo pipefail

cd "$(dirname "$0")/.."

# pre-commit hook（Config-based hooks）の定義を .gitconfig から取り込む。取り込まないと hook が有効にならない。
# 何度実行しても値が重複しないよう、既に入っているかを確認する。
# grep へのパイプで確認すると、grep -q が先に終了して git config が SIGPIPE で落ち、
# pipefail のせいで「未設定」と誤判定されて重複追加されることがある。git config get 自身の
# 値フィルターで確認する。
if ! git config get --local --all --fixed-value --value='../.gitconfig' 'include.path' >/dev/null 2>&1; then
  git config set --append --local 'include.path' '../.gitconfig'
fi

# Git 2.54 未満では hook.<name>.* が黙って無視され、hook が動かないままコミットできてしまう。
# .gitconfig に定義した hook がすべて git hook list に出てくることを確かめる。
mapfile -t hook_events < <(git config list --file .gitconfig | sed -n 's/^hook\.\(.*\)\.event=\(.*\)$/\1 \2/p')
if [ "${#hook_events[@]}" -eq 0 ]; then
  echo 'on-create: no hooks found in .gitconfig.' >&2
  exit 1
fi
for hook_event in "${hook_events[@]}"; do
  name="${hook_event% *}"
  event="${hook_event##* }"
  if ! registered="$(git hook list "$event")"; then
    echo "on-create: 'git hook list $event' failed. Config-based hooks require Git 2.54 or later ($(git --version))." >&2
    exit 1
  fi
  if ! grep -qxF "$name" <<<"$registered"; then
    echo "on-create: hook '$name' is not registered for '$event'." >&2
    exit 1
  fi
done
