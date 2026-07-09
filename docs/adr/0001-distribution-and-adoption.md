# ADR-0001: 配布形態は Template repo+bootstrap.sh+template-sync+adopt.sh

このファイルは、本テンプレートをどう配布・更新・後付けするかの確定判断(2026-07-09 壁打ち)を記録する。

- **日付**: 2026-07-09
- **状態**: 承認

## 文脈

コーディングエージェント駆動開発の出発点となる構成一式を、複数の新規プロジェクトへ配布したい。要件は4つ。
(1) 導入が軽い(ソロ開発者が数分で開始できる)
(2) GitHub の Template repo がリポジトリ「設定」(rulesets・マージ設定・ラベル)をコピーしない既知の欠落を埋められる
(3) テンプレート側の改善を派生リポジトリへ届ける更新経路がある
(4) 既存リポジトリにも部品単位で後付けできる

## 決定

次の4点セットを配布形態とする(案A)。

1. **GitHub Template repository** — `gh repo create --template` の1操作で開始
2. **`tools/bootstrap.sh`** — 生成直後に実行し、プレースホルダ置換・プロファイル展開・設定 API 適用(rulesets・リポジトリ設定・ラベル)を行う
3. **actions-template-sync**(`.github/workflows/template-sync.yml`)— テンプレート更新を pull 型の PR として派生リポジトリへ配送
4. **`tools/adopt.sh`** — 既存リポジトリへ部品(hooks・CI・チェッカ等)をカテゴリ選択で後付け

## 検討した代替案(必須)

- **案B: copier 等のスキャフォールディングエンジン** — 却下。(1) Python+専用ツールの習熟が配布の前提になり、GitHub UI/CLI の1操作に比べ導入摩擦が高い。(2) Jinja 構文がテンプレートファイルに混入し、「エージェントがそのまま読める素のリポジトリ」でなくなる(このテンプレート自体がエージェントの読解対象であることと矛盾)。(3) 重い追加構造はコストを増やして成果を改善しない傾向がトークン実測でも示唆される(OpenSpec と Spec-Kit の比較で重量側が約2倍のトークンを消費しつつ効率改善なし: https://medium.com/it-chronicles/is-your-safe-choice-burning-your-budget-1cfddf8782e4 — 類推根拠)。
- **案C: 専用インストーラ CLI(`npx create-xxx` 型)** — 却下。CLI 自体が新たな保守対象(配布・バージョニング・互換性テスト)になり、ソロ運用では本体より道具の維持に時間を奪われる。リポジトリ内のシェル1枚(`tools/bootstrap.sh`)で同じ結果を得られるため、独立配布物を持つ理由がない。
- **案D: 素のクローン+手動設定手順書** — 却下。rulesets 等の設定適用が手動だと必ず抜け、原則1(散文より機械強制)に反する。

## 結果

- 派生リポジトリは「Use this template → bootstrap.sh 実行」の2手で規約・防御・CI が揃った状態から始まる。
- Template repo が設定を運ばない欠落は bootstrap.sh の API 適用で埋まる(`docs/governance/intake/2026-07-09-rulesets-and-bootstrap.md`)。
- template-sync は W3.80(Trial 域)だが、配布形態の一部としてルーブリック外で採用した。同期対象外は `.templatesyncignore` で管理する。
- トレードオフ: bootstrap.sh は GitHub API 変更への追随が必要。doctor 出力(OK/SKIP/FAIL)で失敗を可視化して緩和する。

## Confirmation(実装後に追記)

本テンプレートのリポジトリ構成(`tools/bootstrap.sh`・`tools/adopt.sh`・`.github/workflows/template-sync.yml`・`.templatesyncignore`)として実装。構文検証(`bash -n`)と構造検証(`python3 tools/check_structure.py`)は CI が常時実施する。派生リポジトリでの初回 bootstrap 実行と初回 template-sync PR 受領は、発生時に本欄へ追記する。

## 信頼度と再検討トリガー

- **信頼度**: 中(構成要素は各公式機能で裏付けあり。エンドツーエンドの実運用実証はこれから)
- **再検討トリガー**: 派生リポジトリが増えて template-sync の PR 運用が回らなくなったら。Claude Code プラグイン配布(Assess、12ヶ月後再審査)が成熟したら。
