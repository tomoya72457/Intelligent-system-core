# このファイルの目的: pythonプロファイルの検証ターゲット実装。
# ルートの Makefile が `-include Makefile.profile` して test / lint / typecheck / arch を有効化する。
# 実体の設定は pyproject.toml(単一の正本)。ここでは uv run に委譲するだけにする。

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
