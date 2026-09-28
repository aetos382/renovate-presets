#!/usr/bin/env bash
# devcontainer / Codespaces の初期化のうち、ネットワークに依存しないもの。
# updateContentCommand（ツールのダウンロード）が失敗すると postCreateCommand は実行されないので、
# 失敗しても気付きにくい hook の有効化は、それより前に実行される onCreateCommand で行う。
set -euo pipefail

cd "$(dirname "$0")/.."

# Git 2.54 未満では hook.<name>.* が黙って無視され、hook が動かないままコミットできてしまう。
# 後で使う git hook list はイベントに hook が 1 つもないときにも失敗し、git config get も
# 古い Git にはないので、原因を取り違えないようバージョンは最初に確かめる。
git_version="$(git version)"
IFS=. read -r git_major git_minor _ <<<"${git_version#git version }"
if (( git_major < 2 || (git_major == 2 && git_minor < 54) )); then
  echo "on-create: Config-based hooks require Git 2.54 or later (${git_version})." >&2
  exit 1
fi

# pre-commit hook（Config-based hooks）の定義を .gitconfig から取り込む。取り込まないと hook が有効にならない。
# 何度実行しても値が重複しないよう、既に入っているかを確認する。
# grep へのパイプで確認すると、grep -q が先に終了して git config が SIGPIPE で落ち、
# pipefail のせいで「未設定」と誤判定されて重複追加されることがある。git config get 自身の
# 値フィルターで確認する。
# git config get は該当する値がないと 1 を返す。それ以外の失敗（.git/config や、取り込み済みの
# .gitconfig の構文エラーなど）は「未設定」と区別して止める。
include_status=0
git config get --local --all --fixed-value --value='../.gitconfig' 'include.path' >/dev/null || include_status=$?
case "$include_status" in
  0) ;;
  1) git config set --append --local 'include.path' '../.gitconfig' ;;
  *)
    echo "on-create: failed to read include.path (exit code ${include_status}). See the git error above." >&2
    exit 1
    ;;
esac

# .gitconfig に定義した hook がすべて git hook list に出てくることを確かめる。
# プロセス置換では git config list の失敗が set -e にも pipefail にも拾われず、
# 「hook が定義されていない」と取り違えるので、いったん変数に受けて終了コードを確かめる。
if ! hook_config="$(git config list --file .gitconfig)"; then
  echo 'on-create: failed to read .gitconfig.' >&2
  exit 1
fi
mapfile -t hook_events < <(sed -n 's/^hook\.\(.*\)\.event=\(.*\)$/\1 \2/p' <<<"$hook_config")
if [ "${#hook_events[@]}" -eq 0 ]; then
  echo 'on-create: no hooks found in .gitconfig.' >&2
  exit 1
fi
for hook_event in "${hook_events[@]}"; do
  name="${hook_event% *}"
  event="${hook_event##* }"
  if ! registered="$(git hook list "$event")"; then
    echo "on-create: no hooks are registered for '$event'. Check that include.path in .git/config points to ../.gitconfig." >&2
    exit 1
  fi
  if ! grep -qxF "$name" <<<"$registered"; then
    echo "on-create: hook '$name' is not registered for '$event'." >&2
    exit 1
  fi
done
