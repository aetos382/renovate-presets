# renovate-presets

aetos382 のリポジトリで共通して使う [Renovate](https://docs.renovatebot.com/) の preset。

## 使い方

リポジトリの `renovate.json` で preset を `extends` する。

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>aetos382/renovate-presets//presets/default",
    "github>aetos382/renovate-presets//presets/devcontainer"
  ]
}
```

preset はこのリポジトリのデフォルト ブランチから読み込まれる。preset を変更すると、参照しているすべてのリポジトリに次回の Renovate の実行から反映される。

## preset

各 preset の設定内容は、JSON ファイルの `description` を参照。

### `github>aetos382/renovate-presets//presets/default`（[presets/default.json](presets/default.json)）

すべてのリポジトリで使う基本の設定。

### `github>aetos382/renovate-presets//presets/devcontainer`（[presets/devcontainer.json](presets/devcontainer.json)）

dev container を持つリポジトリで使う設定。

Renovate は `devcontainer-lock.json` を更新できない（[renovatebot/renovate#43169](https://github.com/renovatebot/renovate/issues/43169)）ので、この preset では devcontainer の features の更新を無効にしている。この preset を使うリポジトリには、features を更新するための `.github/dependabot.yml` を置く。

```yaml
# 依存関係の更新は基本的に Renovate（renovate.json）で行う。
# devcontainer の features だけは、Renovate が devcontainer-lock.json を更新できないため Dependabot で更新する。
version: 2
updates:
  - package-ecosystem: devcontainers
    directory: /
    schedule:
      interval: weekly
      timezone: Asia/Tokyo
    cooldown:
      default-days: 3
```

`.devcontainer/*.sh` に書いたツールのバージョンを Renovate に更新させるには、`XXX_VERSION='...'` の直前の行に `# renovate:` コメントを書く。コメントには `datasource` と `depName` に続けて、必要に応じて `packageName`、`versioning`、`extractVersion` をこの順で書ける。

```bash
# renovate: datasource=github-releases depName=koalaman/shellcheck
SHELLCHECK_VERSION='v0.11.0'
```

### `github>aetos382/renovate-presets//presets/dotnet`（[presets/dotnet.json](presets/dotnet.json)）

.NET のリポジトリで使う設定。

`global.json` の SDK のバージョンと devcontainer の dotnet feature の `version` をそろえて更新する。ただし `version` が `10.0.100` のように 3 つの部分からなるバージョン番号でない場合（`lts` や `10.0` など）は対象外になる。

## リポジトリ固有のルールを足すときの注意

Renovate は、preset の `packageRules` の後にリポジトリ側の `packageRules` を並べる。後のルールが優先されるため、`presets/default.json` の「major は automerge しない」ルールは、リポジトリ側のルールで上書きされることがある。

リポジトリ側で automerge を有効にするルールには、必ず `matchUpdateTypes` を指定する。preset 同士でも、`extends` で後に書いた preset のルールが後に並ぶので、このリポジトリの preset に automerge のルールを足すときも同じようにする。

## 導入時に必要な作業

- Renovate の GitHub App をリポジトリにインストールする。
- Dependabot alerts を有効にする。

## このリポジトリの開発

コミット時に動く pre-commit フック（main への直接コミットの防止と、Renovate の設定の検証）は、Git 2.54 で導入された Config-based hooks として `.gitconfig` に定義している。devcontainer では `.devcontainer/on-create.sh` が `.git/config` に `include.path=../.gitconfig` を追加し、フックが有効になったことを確かめる。devcontainer の外では `git config set --append --local include.path ../.gitconfig` を手で実行する。

次の場合にはフックが動かない。コミット時に警告は出ない（devcontainer では、1 つめは `on-create.sh` が作成時に検出する）。

- Git 2.54 未満の Git では、フックの定義が無視される。
- `include.path` の参照先がない場合、Git はそれを無視する。そのため `.gitconfig` を含まないコミットをチェックアウトしている間は、フックが動かない。

フックが有効かどうかは `git hook list pre-commit` で確かめられる。

### linked worktree での注意

`.git/config` は worktree 間で共有されるので、フックの定義は linked worktree でもメインの worktree の `.gitconfig` から読まれる。一方、フックが実行するスクリプト（`.githooks/*.sh`）は、コミットする worktree のものが使われる。そのため、`.githooks` を含まないコミットを linked worktree でチェックアウトしていると、フックはスクリプトが見つからずに失敗し、コミットできない。
