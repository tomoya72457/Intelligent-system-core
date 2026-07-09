<!-- このファイルの目的: PR 必須ワークフロー撤回というオーナー決定の記録。将来のエージェントが PR 必須を「復元」しないための正本。 -->

# ADR-0006: PR 必須を撤回し、直接 push を既定にする

- 日付: 2026-07-09 / 状態: 承認(オーナー決定)
- 信頼度と再検討トリガー: 高。チーム開発・外部コントリビュータの受け入れ・公開協働が始まったら再検討する(ruleset JSON に PR 必須ルールを戻すだけで復元可能)。

## 文脈

初版はエビデンス(必須チェックはエージェントが迂回できない唯一のマージゲート)に基づき「main 直 push 禁止・PR 必須・required checks」を既定にした。しかしソロ運用の実地で、単純なドキュメント追加ですら PR 作成 → CI 待ち → auto-merge という手続きが挟まり、GitHub ランナー渋滞時には数分〜のブロックが発生した。オーナーが「PR を作るシステムは不要。普通に push する運用にする」と明示的に決定した。

## 決定

1. ruleset から `pull_request` と `required_status_checks` を撤去する。**`non_fast_forward`(force push 拒否)と `deletion`(ブランチ削除拒否)は残す**(push の邪魔をせず履歴だけ守る)。
2. AGENTS.md の規範を「PR 必須」から「**push は `make check` 緑が前提**」へ置き換える。PR は任意(大きな変更・レビューが欲しい時に使う)。
3. `.claude/settings.json` の `git push` 確認(ask)を撤去する。
4. CI は push 時に走り続ける(ブロックではなく**シグナル**として。赤になったら直す)。

## 検討した代替案

- **PR 必須を維持**: エビデンス上は最強のゲートだが、ソロでは承認者が自分しかおらず、手続きコストが利得を上回るとオーナーが判断。却下。
- **required checks だけ残して直 push 許可**: ruleset の required checks は PR 経由でしか評価されないため直 push 運用とは両立しない。却下。

## 結果

- 品質ゲートの実体はローカル二層(pre-commit の構造+秘密検査、hooks)と push 後 CI シグナルに移る。「緑でない状態で push しない」は規範(AGENTS.md Never)であり機械強制ではない点は自覚的に受け入れる。
- 本テンプレート・派生リポジトリ(webcreate-engine)・グローバルスキル isc-setup へ同日適用。

## Confirmation

- 2026-07-09: 両リポジトリの ruleset を API 更新(rules=non_fast_forward+deletion)し、直接 push の成功を実測(ISC 73aa8a6 / webcreate-engine dfd4717)。force push 拒否は ruleset ルールに依拠(未実測)。auto-merge 待ちだった webcreate-engine PR #1 は ruleset 緩和と同時に自動マージされ、未処理 PR はゼロ。
