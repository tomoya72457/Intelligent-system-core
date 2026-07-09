# このファイルの目的: typescriptプロファイルの検証ターゲット実装。
# ルートの Makefile が `-include Makefile.profile` して test / lint / typecheck / arch を有効化する。
# 実体は package.json の scripts(単一の正本)。ここでは npm run に委譲するだけにする。

.PHONY: test lint typecheck arch format

test:
	npm run test

lint:
	npm run lint

typecheck:
	npm run typecheck

arch:
	npm run arch

format:
	npm run format
