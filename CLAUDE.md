# CLAUDE.md

aetos382 のリポジトリで共通して使う Renovate の preset を提供するリポジトリ。preset 本体は `presets/*.json`。Renovate 固有の注意点は `.claude/rules/renovate.md` にある。

## ソース管理

`main` ブランチにはコミットしない。トピック ブランチを作ってからコミットする。

## 検証

- シェル スクリプトを変更したら `shellcheck .devcontainer/*.sh .githooks/*.sh` を実行する。
- `.github/workflows/renovate-config.yml` は他のリポジトリの CI が `@main` で呼ぶ再利用可能ワークフローである。入力や挙動を変えると、マージした時点で全リポジトリの CI に効く。入力を消す・名前を変えるときは、呼び出し元を先に直す。
