<!-- このファイルの目的: pythonプロファイルの説明と展開マニフェスト。bootstrap.shが「## manifest」節をパースしてファイルを配置する。 -->

# python プロファイル

Python アプリケーション(バックエンド・自動化・データ処理)向けの雛形一式。パッケージ管理は uv 前提。

## 含まれるもの

| 役割 | ファイル | 実装 |
|---|---|---|
| プロジェクト定義 | `pyproject.toml` | uv(`uv_build` バックエンド、src レイアウト、dev 依存グループ) |
| テスト | 同上 `[tool.pytest.ini_options]` | pytest(`tests/` 配下) |
| リント+フォーマット | 同上 `[tool.ruff]` | ruff(E,F,I,UP,B / line-length 100) |
| 型チェック | 同上 `[tool.mypy]` | mypy(`disallow_untyped_defs` の strict 寄り) |
| 依存境界 | 同上 `[tool.importlinter]` | import-linter(`api → services → models` 一方向の layers 契約) |
| makeターゲット | `Makefile.profile` | ルートMakefileが `-include` し、test / lint / typecheck / arch を有効化 |
| 最小実例 | `src/app/` 4ファイル+`tests/` 1ファイル | 層境界を示すサンプルコード+テスト1本 |
| 規約 | `README-profile.md` → `docs/conventions/stack-python.md` | このプロファイルの規約1ページ |

## 前提

- uv がインストール済みであること(Python 本体は uv が解決する。`requires-python = ">=3.12"`)
- 展開後に `uv sync` を実行して仮想環境と dev 依存を導入する

## 展開後の最初の一歩

1. `uv sync` — .venv 作成+dev 依存(ruff / mypy / pytest / import-linter)導入+自パッケージを editable 導入
2. `make check` — structure + test + lint + typecheck + arch が全て走ることを確認する

サンプルコード(`src/app/`)は層境界の実例。最初の実装に置き換えてよいが、層構成と `[tool.importlinter]` の契約は維持すること(変更するなら ADR に記録)。
パッケージ名は既定で `app`(`src/app/`)。変更する場合は `pyproject.toml` の `module-name`・`[tool.importlinter]`・import 文を揃えて変更する。

## manifest

以下は `tools/bootstrap.sh` が機械的にパースする対応表(`リポジトリルートからのdest: このディレクトリからのsource`)。
書式の契約は `profiles/README.md` を参照。この節はファイル末尾に置き、このフェンス以外のコードフェンスを本ファイルに置かないこと。

```
Makefile.profile: Makefile.profile
pyproject.toml: pyproject.toml
src/app/__init__.py: src/app/__init__.py
src/app/models.py: src/app/models.py
src/app/services.py: src/app/services.py
src/app/api.py: src/app/api.py
tests/test_services.py: tests/test_services.py
docs/conventions/stack-python.md: README-profile.md
```
