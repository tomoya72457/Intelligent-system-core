# intake 判定記録: 1コマンド検証(make check)+CI 必須チェック

このファイルは、全ゲートを `make check` の1コマンドに集約し、それを CI のブロッキング必須チェックにする方針の較正記録である。

- **提案日**: 2026-07-09
- **slug**: single-command-verification
- **判定**: **Adopt**(W 4.85)
- **再審査日**: 2027-07-09

## 提案

structure / test / lint / typecheck / arch の全ゲートを `make check` 1コマンドに束ね(`Makefile`)、CI(`.github/workflows/ci.yml`)で必須チェック化する。エージェントも人間も「検証は `make check`」だけ覚えればよい状態にする。

## 適用可能性ゲート

制約なし。Makefile と GitHub Actions のみ。プロファイル依存の実体は各 `Makefile.profile` が吸収する。

## 可逆性(two-way door)

**可逆**。ターゲット構成は Makefile の編集で変更可能。

## 賛成論(3点以上)

1. **エージェントの検証ループが決まる**: 検証コマンドが1つに固定されると、エージェントは「作ったら `make check`」を確実に回せる(原則3)。SWE-agent/ACI の研究は、エージェント向けインターフェースの設計が性能を左右すると示す。
2. **自己修復はフィードバック品質律速**: 自己修復の効果はフィードバックの質で決まる(arxiv 2306.09896)。曖昧なテストより、決定的で単一のゲートが良いフィードバックを与える。
3. **業界標準の合流点**: SWE-bench Verified はパッチが検証を通るかで評価し、Claude Code のベストプラクティスも「検証コマンドを教えよ」と一致。CI 必須チェック化で「緑でないとマージ不可」を担保できる。

## 反対論(3点以上)

1. **素のテンプレートでは中身が空**: プロファイル未導入だと test/lint 等が無い。→ 素の状態では structure のみ実行し、他は no-op でメッセージ表示。プロファイル導入で有効化される設計にする。
2. **1コマンドが遅くなる**: ゲートが増えると `make check` が重くなる。→ CI ではキャッシュとジョブ並列で緩和。ローカルは pre-commit で structure と gitleaks の軽量チェックのみに絞る(`tools/githooks/pre-commit`)。
3. **必須チェックが個人リポで設定困難**: Rulesets の required_status_checks は Free プランの private で制約。→ 配布は public 前提+bootstrap で適用し、制約は README に明記(`docs/governance/intake/2026-07-09-rulesets-and-bootstrap.md`)。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 5 | SWE-bench 系+DORA+全ベンダーが検証ループを重視 |
| G: 汎用性 | 5 | 全プロファイルが同じ `make check` 契約に乗る |
| A: エージェント効果 | 5 | 検証可能性・決定性に直接寄与。検証ループの核 |
| M: 維持コスト(逆) | 4 | Makefile は静的。ターゲット追加のみ稀 |
| C: 複雑性コスト(逆) | 5 | 利用者は `make check` 1つを覚えればよい |
| **W: 加重平均** | **4.85** | 拒否権抵触なし |

## 判定

**Adopt**。W4.85。原則3(テスト=検証ループ)の中核であり、CI 必須チェック化で決定的ゲートになる。

## 関連判定

| 項目 | W | 判定 | 備考 |
|---|---|---|---|
| カバレッジ床 | 3.20 | Trial | 品質シグナルだがゲーム化リスク。profiles 内でコメントアウト提供。90日TTL |
| mutation testing | — | Assess | M/C が高く常時装備には重い。記録のみ |
| 中央CI用 reusable workflows リポジトリ | — | Assess | Makefile 集約で薄い caller 相当を達成済み。管理リポジトリ5超で再評価 |

## 条件

—(本項目は Adopt。関連 Trial のカバレッジ床は「profiles 内でコメントアウト、実運用で有用性を確認できれば有効化」が昇格条件)

## 根拠ソース

- https://openai.com/index/introducing-swe-bench-verified/ : 検証を通るかで評価する枠組み
- https://arxiv.org/abs/2405.15793 : SWE-agent/ACI。エージェント向けインターフェース設計が性能を左右
- https://code.claude.com/docs/en/best-practices : 検証コマンドを教える(ベンダー公式)
- https://arxiv.org/abs/2306.09896 : 自己修復はフィードバック品質律速(決定的ゲートの価値)
