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

### `github>aetos382/renovate-presets//presets/default`（[presets/default.json](presets/default.json)）

すべてのリポジトリで使う基本の設定。

- `config:best-practices`、`helpers:pinGitHubActionDigestsToSemver`、`security:openssf-scorecard` を継承する。
- タイムゾーンは `Asia/Tokyo`。リリースから 3 日経つまで更新しない（`minimumReleaseAge`）。
- PR に `dependencies` ラベルを付ける。脆弱性の修正には `security` ラベルも付け、`minimumReleaseAge` を待たずに automerge する。
- OSV の脆弱性情報を使い、Dependency Dashboard に一覧を表示する。
- 次の更新を automerge する。
  - 信頼できる GitHub Actions（`actions/`、`github/`、`microsoft/`、`advanced-security/`）の major 以外の更新
  - npm の `devDependencies` の minor/patch
  - pin と digest の pin（`minimumReleaseAge` を待たない）
- rollback と replacement は automerge せず、コミット メッセージに `[cautionable]` を付ける。
- major は automerge しない。

### `github>aetos382/renovate-presets//presets/devcontainer`（[presets/devcontainer.json](presets/devcontainer.json)）

dev container を持つリポジトリで使う設定。

- devcontainer の features の更新を無効にする。Renovate は `devcontainer-lock.json` を更新できないため（[renovatebot/renovate#43169](https://github.com/renovatebot/renovate/issues/43169)）、features は Dependabot で更新する（後述）。
- `.devcontainer/*.sh` の中の、`# renovate:` コメントの直後にある `XXX_VERSION='...'` を更新する。

  ```bash
  # renovate: datasource=github-releases depName=koalaman/shellcheck
  SHELLCHECK_VERSION='v0.11.0'
  ```

  コメントには `datasource` と `depName` に続けて、必要に応じて `packageName`、`versioning`、`extractVersion` をこの順で書ける。
- ShellCheck の更新 PR に、`.devcontainer/install-shellcheck.sh` の `SHA256` を手で更新するよう注記を付ける。

この preset を使うリポジトリには、features を更新するための `.github/dependabot.yml` を置く。

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

### `github>aetos382/renovate-presets//presets/dotnet`（[presets/dotnet.json](presets/dotnet.json)）

.NET のリポジトリで使う設定。

- NuGet パッケージの minor/patch を automerge する。`global.json` の `msbuild-sdks` や `dotnet-tools.json` のツールも対象になる。
- 開発が完了しているだけで放棄されてはいないパッケージ（`Microsoft.NETFramework.ReferenceAssemblies`、`System.Memory`、`System.Threading.Tasks.Extensions`）について、abandonment の警告を出さない。
- `global.json` の SDK のバージョンと、devcontainer の dotnet feature（`ghcr.io/devcontainers/features/dotnet`）の `version` を 1 つの PR でそろえて更新する。feature の major バージョンは問わない。`version` が `lts` のようにバージョン番号でない場合は対象外になる。
- `mcr.microsoft.com/dotnet/**` の Docker イメージの更新を 1 つの PR にまとめる（`group:dotNetCore`）。

## リポジトリ固有のルールを足すときの注意

Renovate は、preset の `packageRules` の後にリポジトリ側の `packageRules` を並べる。後のルールが優先されるため、`presets/default.json` の「major は automerge しない」ルールは、リポジトリ側のルールで上書きされることがある。

リポジトリ側で automerge を有効にするルールには、必ず `matchUpdateTypes` を指定する。preset 同士でも、`extends` で後に書いた preset のルールが後に並ぶので、このリポジトリの preset に automerge のルールを足すときも同じようにする。

```json
{
  "matchDatasources": ["nuget"],
  "matchUpdateTypes": ["minor", "patch"],
  "automerge": true
}
```

## 導入時に必要な作業

- Renovate の GitHub App をリポジトリにインストールする。
- Dependabot alerts を有効にする。
