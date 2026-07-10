# ADR-0007: tools/*.py の常時 lint ゲート(make tools-lint)をテンプレート状態の make check へ追加

- **日付**: 2026-07-11
- **状態**: 承認

## 文脈

`tools/check_structure.py` / `tools/test_check_structure.py` はプロファイル非依存でルートに常設され、
python プロファイル導入後は `make lint`(`ruff check .`)の走査対象に入る。しかし素のテンプレートには
ruff 設定も実行環境も無く、この2ファイルは一度も lint されないまま配布されていた。実際に ruff 違反
(UP031 ×10・E501 ×1)が派生リポジトリ rutirise-manager の `make check` で初めて発覚し、
2026-07-11 に上流還元で修正した(コミット 3f326f8・bad152e)。「テンプレートでは検出不能、
下流で初めて赤くなる」という構造ギャップが原因であり、再発を機械強制で防ぐ必要がある。
制約: `.github/workflows/` はエージェント自己編集禁止のセキュリティ境界
(`.claude/rules/agent-config-changes.md`)。また `make check` を検証の単一入口とする設計
(Makefile 冒頭)を崩したくない。素の ubuntu-24.04 ランナーには uv/uvx は無く pipx 1.15.0 がある
(actions/runner-images のマニフェストで確認)。

## 決定

ルート Makefile に `tools-lint` ターゲットを追加し、`make check` の前提に組み込む。

- 実行条件: `profiles/` が存在する間(=テンプレート状態)のみ。派生リポジトリでは skip 案内を出す
  (python プロファイルでは既に `make lint` が tools/ を走査するため二重化しない)。
- 実行方法: `uvx`(ローカル)→ `pipx run`(CI ランナー)の順で探し、どちらも無ければ即失敗
  (フェイルファスト。黙って skip しない)。
- ルールは `profiles/python/pyproject.toml` の `[tool.ruff]`(E,F,I,UP,B / line-length 100)と揃え、
  版は `ruff==0.15.21` に明示ピン(CI の zizmor==1.26.1・gitleaks 8.30.1 と同じピン方針。
  更新は人間判断で bump)。

CI 側の変更は不要 — 既存の `make check` ジョブがこのゲートを自動的に実行する。

## 検討した代替案(必須)

- **案A: ci.yml に独立の lint ステップを追加** — `make check` 単一入口の設計を崩し、ローカル緑・CI 赤の
  非対称を生む。workflows はエージェント編集禁止領域のため人間の手作業も必要。却下。
- **案B: ルートに ruff.toml を常設して単一ソース化** — ruff の設定探索で派生リポジトリの
  pyproject.toml `[tool.ruff]` を ruff.toml が覆い隠し、派生側の設定変更が黙って無効化される。却下。
- **案C: バージョンを範囲指定(>=0.15.20)で追随** — 新版 ruff の新規則で無関係な push が突然赤になる
  非決定性を持ち込む。pipx の `--spec` は `==` 形式のみ公式例があることも確認。明示ピンを採用し却下。
- **案D: 何もしない(下流検出に依存)** — 今回の再発経路そのもの。却下。

## 結果

- テンプレートの tools/*.py 編集は push 前(`make check`)と CI の両方で ruff 検査される。
- 新規スタック採用は無し: ruff / uv は既に Adopt(tech-radar)。pipx はランナー同梱物を
  フォールバックとして使うだけで、依存として導入しない(intake 不要と判断)。
- 受け入れたトレードオフ: (1) ruff ルールのフラグが Makefile と profiles/python/pyproject.toml に
  重複する(コメントで相互参照)。(2) CI はキャッシュ無しで毎回 ruff を取得する(数秒・許容)。
  (3) ピン更新は手動(dependabot は Makefile を見ない)。
- Makefile は template-sync の除外対象ではないため、派生リポジトリにも配布されるが skip 分岐で無害。

## Confirmation(実装後に追記)

2026-07-11 ローカルで検証:

- 正常系(uvx 分岐): `make tools-lint` → `All checks passed!`
- 違反検出: UP031 違反を一時注入 → `make tools-lint` が Error 1 で失敗(検出後 revert)
- フェイルファスト: `PATH=/usr/bin:/bin make tools-lint` → ERROR 案内+exit 非0
- skip 分岐: profiles/ 無しの合成リポジトリで skip 案内を出し `make check` 完走
- 総合: テンプレート状態の `make check` 緑

CI(pipx 分岐)の実証: 2026-07-11、コミット 5319f8f の CI run 29120006361 が success。
make check ジョブのログに ruff の `All checks passed!` を確認。素の ubuntu-24.04 ランナーに
uvx は無い(runner-images マニフェスト確認済み)ため、実行経路は pipx 分岐である。

## 信頼度と再検討トリガー

- **信頼度**: 高(ローカル4分岐+CI の pipx 分岐まで全経路を実証済み)
- **再検討トリガー**: (1) ランナーイメージから pipx が外れたら(ci.yml への uv セットアップ常設化を
  人間が検討)。(2) profiles/python の ruff ルール・版を変更したら本ゲートのピンも同時に見直す。
  (3) tools/ 配下に .py 以外の実行資産が増え、lint 対象の定義を再設計する必要が出たら。
