# この Makefile は全プロジェクト共通の検証エントリポイント。
# `make check` 1 コマンドで全ゲートを実行する(テスト=検証ループの単一入口)。
# test / lint / typecheck / arch の実体は各プロファイルが Makefile.profile で提供する
# (bootstrap.sh が配置)。素のテンプレート(プロファイル未導入)では案内を表示する。

SHELL := /bin/bash

# Makefile.profile が存在すればそれが test/lint/typecheck/arch を定義する。
# 存在検出をフォールバック定義のガードに使う(二重定義による警告を避ける)。
PROFILE_MK := $(wildcard Makefile.profile)
-include Makefile.profile

.PHONY: help structure test lint typecheck arch check

help:
	@echo "make check     - 全ゲート(structure + プロファイル提供分)を実行【必須ゲート】"
	@echo "make structure - 構造・ドキュメント予算チェック (tools/check_structure.py)"
	@echo "make test      - テスト(プロファイル提供)"
	@echo "make lint      - リント(プロファイル提供)"
	@echo "make typecheck - 型チェック(プロファイル提供)"
	@echo "make arch      - 依存境界チェック(プロファイル提供)"

structure:
	@python3 tools/check_structure.py

# ある物すべてを実行する。素の状態では structure 以外は no-op 案内。
check: structure test lint typecheck arch
	@echo "make check: すべてのゲートを実行しました。"

ifeq ($(PROFILE_MK),)
# --- プロファイル未導入時のフォールバック(no-op + 案内) ---
test lint typecheck arch:
	@echo "[$@] プロファイル未導入です。tools/bootstrap.sh でプロファイルを導入すると有効化されます。"
endif
