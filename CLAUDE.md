# CLAUDE.md

aetos382 のリポジトリで共通して使う Renovate の preset を提供するリポジトリ。preset 本体は `presets/*.json`。Renovate 固有の注意点は `.claude/rules/renovate.md` にある。

## 検証

- シェル スクリプトを変更したら `shellcheck .devcontainer/*.sh .githooks/*.sh` を実行する。
