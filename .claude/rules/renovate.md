---
paths:
  - renovate.json
  - presets/**
  - .github/dependabot.yml
  - .devcontainer/*.sh
  - .devcontainer/devcontainer.json
  - .githooks/validate-renovate-config.sh
---

# Renovate

- このリポジトリは Renovate の共有 preset を `presets/` に置いて提供する。`presets/xxx.json` は `github>aetos382/renovate-presets//presets/xxx` として参照される。リポジトリ名だけの `github>aetos382/renovate-presets` はリポジトリ直下の `default.json` を読むので使えない。`:presets/xxx` とコロンで書くと `presets.json` の中の `xxx` キーと解釈されるので、これも使えない。各リポジトリはデフォルト ブランチを参照するので、main にマージした変更は全リポジトリに即座に反映される。
- Renovate は preset の `packageRules` の後にリポジトリ側の `packageRules` を並べる。そのため `presets/default.json` の末尾にある「major は automerge しない」ルールは、リポジトリ側のルールで上書きされうる。リポジトリ側で automerge を有効にするルールには `matchUpdateTypes` を必ず指定する。preset 同士でも `extends` で後に書いたもののルールが後に並ぶので、このリポジトリの preset の automerge のルールにも `matchUpdateTypes` を必ず指定する。`default` の中のルールは末尾の major のルールより前にあるが、並び順に頼らないよう同じく指定する。
- このリポジトリ自身の依存関係も、自分の preset を使って Renovate（`renovate.json`）で更新する。ただし devcontainer の features だけは Dependabot（`.github/dependabot.yml`）で更新する。Renovate は `devcontainer-lock.json` を更新できないため（renovatebot/renovate#43169）。Renovate が対応したら、次の作業をして Renovate に一本化する。
  - `presets/devcontainer.json` から features を無効にするルールを削除する。
  - README.md の devcontainer preset の節から、Dependabot についての説明と `dependabot.yml` の例を削除する。
  - このリポジトリの `.github/dependabot.yml` を削除し、この項目の Dependabot についての記述も削除する。
  - devcontainer preset を使う各リポジトリの `.github/dependabot.yml` を削除する。
- `renovate.json` か `presets/` 以下の `*.json` をコミットすると、pre-commit フックがステージされた内容を `renovate-config-validator --strict --no-global` で検証する。手で実行するときは、リポジトリ直下で `CODESPACES=false renovate-config-validator --strict --no-global renovate.json presets/*.json < /dev/null` と実行する（`--no-global` がないと global config として検証される。Codespaces では `CODESPACES=false` がないとリポジトリ名の入力待ちで止まる）。
- `.devcontainer/*.sh` のツールのバージョンは `# renovate: datasource=... depName=...` コメントの直後の `XXX_VERSION='...'` で Renovate に追従させる。ShellCheck の `SHA256` は Renovate が更新しないので、Renovate の PR で手で書き換える。
