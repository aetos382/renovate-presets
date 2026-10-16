# shellcheck shell=bash
# update-content.sh、pre-commit hook、CI で共有するツールのバージョン。source して使う。
# shellcheck disable=SC2034

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION='44.155.2'

# gh の拡張機能 gh-actions-lock。renovate.json の constraints.ghActionsLock と同じ値にする。
# Renovate が actions.lock を作り直すときのバージョンを、手元や CI と揃えるため。
# renovate: datasource=github-releases depName=github/gh-actions-lock
GH_ACTIONS_LOCK_VERSION='v0.2.0'
