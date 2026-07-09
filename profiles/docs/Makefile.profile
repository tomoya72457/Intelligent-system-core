# このファイルの目的: docsプロファイルの検証ターゲット実装。
# ルートの Makefile が `-include Makefile.profile` する。docsプロファイルは実行コードを
# 持たないため、検証ゲートは構造チェック(make structure)のみ。
# test / lint / typecheck / arch は「プロファイル未導入」と区別するための明示スタブ(成功扱い)。

.PHONY: test lint typecheck arch

test lint typecheck arch:
	@echo "docsプロファイル: '$@' は対象外(検証ゲートは make structure)"
