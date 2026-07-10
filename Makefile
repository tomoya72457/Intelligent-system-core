# この Makefile は全プロジェクト共通の検証エントリポイント。
# `make check` 1 コマンドで全ゲートを実行する(テスト=検証ループの単一入口)。
# test / lint / typecheck / arch の実体は各プロファイルが Makefile.profile で提供する
# (bootstrap.sh が配置)。素のテンプレート(プロファイル未導入)では案内を表示する。

SHELL := /bin/bash

# Makefile.profile が存在すればそれが test/lint/typecheck/arch を定義する。
# 存在検出をフォールバック定義のガードに使う(二重定義による警告を避ける)。
PROFILE_MK := $(wildcard Makefile.profile)
-include Makefile.profile

.PHONY: help structure tools-lint test lint typecheck arch check

help:
	@echo "make check     - 全ゲート(structure + プロファイル提供分)を実行【必須ゲート】"
	@echo "make structure - 構造・ドキュメント予算チェック (tools/check_structure.py)"
	@echo "make tools-lint - tools/*.py の常時リント(テンプレート状態のみ有効・ADR-0007)"
	@echo "make test      - テスト(プロファイル提供)"
	@echo "make lint      - リント(プロファイル提供)"
	@echo "make typecheck - 型チェック(プロファイル提供)"
	@echo "make arch      - 依存境界チェック(プロファイル提供)"

structure:
	@python3 tools/check_structure.py

# tools/*.py はプロファイル非依存でルートに常設され、python プロファイル導入後は
# make lint(ruff check .)の走査対象に入る。素のテンプレートには ruff が無く、違反が
# 派生リポジトリで初めて発覚したため、テンプレート状態(profiles/ が残っている間)に
# 限り常時 lint する(ADR-0007)。ルールは profiles/python/pyproject.toml の [tool.ruff]
# と揃える。版は CI の zizmor/gitleaks と同じ明示ピン方針(更新は人間判断で bump)。
TOOLS_RUFF_VERSION := 0.15.21
TOOLS_RUFF_ARGS := check --no-cache --select E,F,I,UP,B --line-length 100 tools/

tools-lint:
	@if [ ! -d profiles ]; then \
		echo "[tools-lint] skip: テンプレート状態(profiles/ 併存時)のみ実行するゲートです。"; \
	elif command -v uvx >/dev/null 2>&1; then \
		uvx --from 'ruff==$(TOOLS_RUFF_VERSION)' ruff $(TOOLS_RUFF_ARGS); \
	elif command -v pipx >/dev/null 2>&1; then \
		pipx run --spec 'ruff==$(TOOLS_RUFF_VERSION)' ruff $(TOOLS_RUFF_ARGS); \
	else \
		echo "ERROR: [tools-lint] uvx / pipx が見つかりません(どちらかを導入して再実行)。" >&2; \
		exit 1; \
	fi

# ある物すべてを実行する。素の状態では structure / tools-lint 以外は no-op 案内。
check: structure tools-lint test lint typecheck arch
	@echo "make check: すべてのゲートを実行しました。"

ifeq ($(PROFILE_MK),)
# --- プロファイル未導入時のフォールバック(no-op + 案内) ---
test lint typecheck arch:
	@echo "[$@] プロファイル未導入です。tools/bootstrap.sh でプロファイルを導入すると有効化されます。"
endif
