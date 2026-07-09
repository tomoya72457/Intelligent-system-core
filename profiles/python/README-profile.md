<!-- このファイルの目的: pythonプロファイルの規約1ページ。bootstrap時に docs/conventions/stack-python.md として配置される。 -->

# スタック規約: Python

このプロジェクトは Intelligent-system-core テンプレートの python プロファイルで初期化されている。
共通規約は `AGENTS.md` と `docs/conventions/` が正本。本ページはスタック固有の差分だけを定める。

## コマンド(make が正面玄関)

| make | 実体(uv run 経由) | 役割 |
|---|---|---|
| `make test` | `pytest` | テスト(`tests/` 配下) |
| `make lint` | `ruff check .` | リント(E,F,I,UP,B / line-length 100) |
| `make format` | `ruff format .` | フォーマット適用 |
| `make typecheck` | `mypy` | 型チェック(`disallow_untyped_defs`) |
| `make arch` | `lint-imports` | 依存境界の検証(import-linter) |

`make check` は上記すべて+構造チェックを一括実行する。CI もこれを回す。
仮想環境の有効化は不要(`uv run` が `uv.lock` と `.venv` を自動整合させる)。依存追加は `uv add`(dev は `uv add --group dev`)。**依存の追加・更新は Ask first**(AGENTS.md、adoption-judge の判定を経る)。

## 層構成(依存は下向き一方向のみ)

| 層 | 置くもの | 依存してよい先 |
|---|---|---|
| `app.api` | 外部との境界(HTTPハンドラ・CLIエントリポイント・外部表現への変換) | services, models |
| `app.services` | ビジネスロジック | models のみ |
| `app.models` | データ構造(dataclass 等)。ロジックを持たない | なし(最下層) |

- 強制装置は `pyproject.toml` の `[tool.importlinter]` layers 契約。上向き import は `make arch` が失敗させる。
- 規模が育ったら各層をモジュール(`api.py`)からパッケージ(`api/`)へ昇格してよい(契約はそのまま効く)。
- 既存コードへ後付けする場合は、現存違反を契約の `ignore_imports` に明示列挙して凍結し、返済に合わせて列挙を縮める(freeze/baseline 方式。`pyproject.toml` のコメント参照)。

## テスト・型の規約

- テストは `tests/test_*.py`。`uv sync` が自パッケージを editable 導入するため `import app` がそのまま通る。
- mypy は `src` と `tests` の両方を見る。テスト関数にも `-> None` を付ける(型注釈なし関数は定義できない)。
- カバレッジ床は Trial(オプトイン)。有効化手順は `pyproject.toml` のコメント参照。床は現状実測値から始める。

## バージョン方針(2026-07時点)

- `requires-python = ">=3.12"`。Python 本体は uv が解決する(最新安定は 3.14 系)。
- dev 依存の下限は 2026-07 時点の安定版(ruff 0.15 / mypy 2.2 / pytest 9.1 / import-linter 2.13)。更新は dependabot(cooldown 7日)に任せ、手動で先回りしない。
- `uv.lock` は初回 `uv sync` で生成される。必ずコミットする(再現可能な環境が検証ループの前提)。

## 注意

- `pyproject.toml` の `name` は bootstrap がプロジェクト名で置換する。PEP 508 の命名規則(英数字と `-_.`)に合わない場合は手で修正する。パッケージ実体は `module-name = "app"` で分離済みのため、`name` を変えても import 文は変わらない。
- release-please(リリース自動化)は Trial 判定。ライブラリ的プロジェクトの場合のみ検討し、導入は adoption-judge を経る(`docs/governance/tech-radar.md` 参照)。
