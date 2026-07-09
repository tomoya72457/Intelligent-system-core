# intake 判定記録: 小PR規律(+Conventional Commits)

このファイルは、1PR=1論理変更・目安400行以下の小バッチ規律と、Conventional Commits による変更ラベリングの較正記録である。

- **提案日**: 2026-07-09
- **slug**: small-batch-discipline
- **判定**: **Adopt**(W 4.65)
- **再審査日**: 2027-07-09

## 提案

1PR=1論理変更・目安400行以下を規範とし、超過は CI が `::warning` で警告(ブロックしない、`.github/workflows/ci.yml`)。あわせてコミットは Conventional Commits 形式(feat/fix/chore/docs/refactor/test/ci)とし、`.gitmessage` テンプレートで案内する(lint ゲートは設けない)。

## 適用可能性ゲート

制約なし。CI の diff 計測と `.gitmessage` のみ。

## 可逆性(two-way door)

**可逆**。警告閾値は CI ステップの定数、`.gitmessage` はテンプレート。撤去容易。

## 賛成論(3点以上)

1. **AI 時代に小バッチが増幅条件**: Google の2025 AI 支援開発レポートは、小バッチを AI の効果を増幅する7条件の1つに挙げる。逆に AI 採用は安定性を平均7.2%下げうる(DORA 2024)ため、規律で相殺する必要がある。
2. **レビュー可能性**: 小さな変更はレビューが速く正確(Google eng-practices の small CLs)。エージェント生成 PR の大規模分析(arxiv 2601.17581、24,014件)でも、スコープの締まった変更ほど扱いやすい。
3. **ブロックせず警告で足る**: 400行は絶対禁止ではなく設計判断。CI 警告は摩擦を最小化しつつ気付きを与える。Conventional Commits は履歴を機械可読にし、将来の release-please 等と接続できる。

## 反対論(3点以上)

1. **400行は恣意的**: 生成ファイルやリファクタで容易に超える。→ だからブロックせず警告。閾値は目安であり、正当な超過は PR 説明で理由を書けばよい(`.github/pull_request_template.md` のチェック欄)。
2. **コミット規約は儀式**: 形式を強制すると摩擦。→ lint ゲートは設けず `.gitmessage` の案内に留める(C を高く保つ)。強制はしないが、型が揃うと後工程が楽になる。
3. **ソロには過剰では**: レビュアーが自分なら小PRの意味が薄い。→ 主目的は「次に読むエージェント/未来の自分」の認知負荷削減であり、ソロでも有効(生きた文書運用と同じ論理)。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 5 | DORA 24/25+Google+MSR2026(24,014 PR)が収斂 |
| G: 汎用性 | 5 | 全プロファイル・全プロジェクトに効く規律 |
| A: エージェント効果 | 4 | スコープ限定はエージェントの成功率に寄与。決定性そのものではないので4 |
| M: 維持コスト(逆) | 5 | 規範+警告閾値は静的。腐らない |
| C: 複雑性コスト(逆) | 4 | 警告は軽微な摩擦。ブロックしないので低コスト |
| **W: 加重平均** | **4.65** | 拒否権抵触なし |

## 判定

**Adopt**。W4.65。原則4(小バッチ)の実装。

## 関連判定

| 項目 | E | G | A | M | C | W | 判定 |
|---|---|---|---|---|---|---|---|
| Conventional Commits+.gitmessage(lintゲート無し) | 4 | 5 | 4 | 5 | 5 | 4.45 | Adopt |
| スペック駆動フロー(/spec スキル) | — | — | — | — | — | 3.15 | Trial |

- **Conventional Commits**: 公式 spec+ソロ実践報告が支持。lint ゲートは設けず摩擦を避ける。
- **スペック駆動フロー(Trial)**: 全独立レビュアーが「タスクサイズ閾値必須」で一致。常時適用は過剰(`docs/governance/intake/2026-07-09-rejected-practices.md` の spec-driven 常時=Reject 相当)。非自明機能(目安3ファイル超 or 新規サブシステム or 外部API契約変更)のみ発火するゲート付きで `.claude/skills/spec/SKILL.md` に同梱。90日TTL、実運用で発火頻度と有効性を確認できれば昇格。

## 条件

—(本項目は Adopt)。/spec は Trial: ゲートの発火基準が過剰/過小でないかを実運用で確認し、90日以内に実証できなければ降格。

## 根拠ソース

- https://dora.dev/research/2024/dora-report/ : AI 採用で安定性 -7.2%(規律で相殺する根拠)
- https://services.google.com/fh/files/misc/2025_state_of_ai_assisted_software_development.pdf : 小バッチが AI 増幅7条件の1つ
- https://google.github.io/eng-practices/review/developer/small-cls.html : 小さい変更のレビュー可能性
- https://arxiv.org/abs/2601.17581 : 24,014 エージェント PR 分析
