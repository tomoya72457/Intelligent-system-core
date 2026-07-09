# このファイルの目的: pythonプロファイルの検証ターゲット実装。
# ルートの Makefile が `-include Makefile.profile` して test / lint / typecheck / arch を有効化する。
# 実体の設定は pyproject.toml(単一の正本)。ここでは uv run に委譲するだけにする。

# venv は iCloud 配下に置くと同期で破損する(2026-07-09 に同日2回実測: site処理が壊れ import 不能に)。
# UV_PROJECT_ENVIRONMENT でホーム側へ退避する。make を経由しない素の uv 実行時は
# `export UV_PROJECT_ENVIRONMENT="$HOME/.venvs/<プロジェクト名>"` を同様に設定すること。
export UV_PROJECT_ENVIRONMENT ?= $(HOME)/.venvs/$(shell basename "$(CURDIR)")

.PHONY: test lint typecheck arch format

test:
	uv run pytest

lint:
	uv run ruff check .

typecheck:
	uv run mypy

arch:
	uv run lint-imports

format:
	uv run ruff format .
