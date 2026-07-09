# intake 判定記録: Issue Forms 構造化タスク+軽量ADR

このファイルは、タスク起票を Issue Forms で構造化する方針と、設計判断を軽量 ADR で記録する方針の較正記録である(いずれも「判断・仕様の記録」テーマ)。

- **提案日**: 2026-07-09
- **slug**: issue-forms-and-adr
- **判定**: **Adopt**(Issue Forms W 4.45 / 軽量ADR W 4.05)
- **再審査日**: 2027-07-09

## 提案

(1)タスク起票は `.github/ISSUE_TEMPLATE/task.yml` の Issue Form で行い、受け入れ基準(検証可能な形式)を必須フィールドにする。(2)アーキテクチャ判断は `docs/adr/TEMPLATE.md` の軽量 ADR(Nygard/MADR minimal 折衷+Confirmation 欄)で記録する。

## 適用可能性ゲート

制約あり(明記して許容)。Issue Forms の `validations.required` は public リポジトリでのみ強制される(GitHub 仕様)。本テンプレートは public 前提。private 利用時は必須が効かない旨を `task.yml` 冒頭コメントに明記。

## 可逆性(two-way door)

**可逆**。Form は YAML、ADR は Markdown。撤去容易。既存の記録は残る(それが目的)。

## 賛成論(3点以上)

1. **スコープ明確な Issue はマージ率が高い**: エージェント PR の大規模分析で、スコープの明確な Issue ほどマージされやすい(AUC 72%、arxiv 2512.21426)。受け入れ基準の必須化は成功率への直接投資。
2. **ベンダーの推奨と一致**: GitHub Copilot coding agent のベストプラクティスも「明確で範囲の定まったタスク」を求める。Issue Forms はそれを構造で担保する(自由記述の Issue テンプレートより欠落が起きない)。
3. **ADR は「なぜ」の耐久記録**: 設計判断の背景は消えやすい。軽量 ADR(Nygard 由来+MADR minimal)は Thoughtworks Radar でも定番であり、Confirmation 欄(実装後にどう検証されたか)で「書きっぱなし rot」を抑える。

## 反対論(3点以上)

1. **フォームは摩擦**: 起票が重くなる。→ フィールドは5つに絞り(目的/背景/受け入れ基準/スコープ外/参照)、必須は2つのみ。blank Issue を無効化しても直接 URL では作成可能(GitHub 仕様)なので逃げ道はある。
2. **ADR は書かれなくなる**: 重い様式は放置される。→ 重量 ADR/RFC の全件適用は Reject(比例原則違反)。軽量テンプレート+「アーキテクチャ判断を含む PR のみ」の閾値で、書く量を最小化。`.claude/skills/adr/SKILL.md` が作成を補助。
3. **記録が腐る**: 古い ADR が現状と乖離。→ 状態(承認/廃止/置換)と信頼度・再検討トリガー欄を持たせ、`docs/adr/INDEX.md` で棚卸し可能にする。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

Issue Forms 構造化タスク:

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 4 | GitHub 公式+arxiv 2512.21426 の大規模分析 |
| G: 汎用性 | 5 | 全プロファイルのタスク運用に共通 |
| A: エージェント効果 | 5 | 受け入れ基準=エージェントの検証目標。成功率に直結 |
| M: 維持コスト(逆) | 4 | YAML は静的 |
| C: 複雑性コスト(逆) | 4 | 起票時に軽い記入コスト |
| **W: 加重平均** | **4.45** | 拒否権抵触なし |

軽量 ADR(minimal+Confirmation 欄):

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 4 | Nygard/MADR/Radar の定番+rot 対策の実践知 |
| G: 汎用性 | 5 | 全プロジェクトの判断記録に共通 |
| A: エージェント効果 | 4 | 過去判断の grep 可能な記録はエージェントの文脈になる |
| M: 維持コスト(逆) | 3 | 書く習慣の維持が必要。閾値と skill で緩和 |
| C: 複雑性コスト(逆) | 4 | 該当 PR のみ。軽量様式 |
| **W: 加重平均** | **4.05** | 拒否権抵触なし |

## 判定

**両方 Adopt**。受け入れ基準の必須化と判断記録は、エージェント駆動開発の「仕様不備・検証不足」(MAST の失敗79%)への直接対策。

## 関連判定

- **Reject(詳細は 2026-07-09-rejected-practices.md)**: 重量 ADR/RFC の全件適用(比例原則違反。軽量+閾値が正)。

## 条件

—(Adopt のため無し)

## 根拠ソース

- https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms : Issue Forms 公式(validations.required の仕様含む)
- https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks : 明確で範囲の定まったタスクの推奨
- https://arxiv.org/abs/2512.21426 : スコープ明確な Issue ほどマージ率高(AUC 72%)
- https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions : Nygard ADR 原典
- https://adr.github.io/madr/ : MADR(minimal 様式の参照元)
- https://www.thoughtworks.com/radar/techniques/lightweight-approach-to-rfcs : 軽量アプローチの Radar 評価
