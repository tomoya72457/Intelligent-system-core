# docs/ ルータ

このファイルは docs/ 配下の道案内である。ファイル一覧ではなく「何をしたいか」から引く。ここに載っていない文書は原則存在しないので、文書を追加したら本表にも1行足すこと(規約は `docs/conventions/docs-rules.md`)。

## したいこと → 読むファイル

| したいこと | 読むファイル |
|---|---|
| なぜこの構成なのか(採用・却下の全根拠)を知りたい | `docs/governance/tech-radar.md` |
| 「原則N」の中身(設計原則10ヶ条)を知りたい | `docs/governance/principles.md` |
| 新しいツール・手法を既定に入れるべきか判定したい | `docs/governance/rubric.md`(実行は `.claude/skills/intake/SKILL.md`) |
| 過去の判定の詳細(両論・採点・ソース)を確認したい | `docs/governance/intake/` の該当記録 |
| 判定記録を新しく書きたい | `docs/governance/intake/TEMPLATE.md` |
| 設計判断(ADR)を記録したい | `docs/adr/TEMPLATE.md`(手順は `.claude/skills/adr/SKILL.md`) |
| 過去の設計判断を一覧したい | `docs/adr/INDEX.md` |
| 配布・言語・プロファイル等の基本方針の経緯を知りたい | `docs/adr/0001-distribution-and-adoption.md` 〜 `0005-agents-md-canonical-pointers.md` |
| モジュール境界・レイヤ・依存lintの規約を知りたい | `docs/conventions/architecture.md` |
| 命名・コメント・エージェント向けコーディング規約を知りたい | `docs/conventions/coding.md` |
| AGENTS.md の予算やドキュメント構造のルールを知りたい | `docs/conventions/docs-rules.md` |
| 大きな要望を小タスク(Issue)に分解したい | `docs/playbooks/task-decomposition.md` |
| 複数エージェントを並列で走らせたい(Trial) | `docs/playbooks/parallel-agents.md` |
| 本番データへの書き込みを安全に行いたい | `docs/playbooks/production-writes.md` |
| ガードの残存穴(下流監査由来)と修正提案の引き継ぎを読みたい | `docs/handoffs/2026-07-14-guard-gaps-from-rutirise-audit.md` |
| 追跡監査由来の新規穴(G11〜G13)と優先度更新を読みたい | `docs/handoffs/2026-07-22-guard-gaps-followup-from-rutirise-audit.md` |

## docs/ の外にあるもの

| したいこと | 場所 |
|---|---|
| 常時適用の規範・コマンド・境界(正本) | `AGENTS.md`(リポジトリルート) |
| 作業手順スキル(intake / adr / spec / handoff / incident) | `.claude/skills/` |
| 構造・予算チェックの実体 | `tools/check_structure.py`(`make structure`) |
| プロファイル(typescript / python / docs)の中身 | `profiles/README.md` |

## このディレクトリの構造

- `adr/` — 設計判断の記録(番号順、索引は INDEX.md)
- `governance/` — 設計原則(principles)・既定変更の判定基準(rubric)・台帳(tech-radar)・個別記録(intake/)
- `conventions/` — アーキテクチャ・コーディング・ドキュメントの規約(機械強制の「なぜ」)
- `playbooks/` — 状況別の手順書
- 実行時に増えるもの: `specs/`(/spec スキル)・`handoffs/`(/handoff スキル)・`incidents/`(/incident スキル)が、それぞれのスキル初回実行時に作られる
