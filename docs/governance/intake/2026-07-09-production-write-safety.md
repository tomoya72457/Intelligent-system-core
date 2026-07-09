# intake 判定記録: 本番書込セーフティ(PRマージ=承認+concurrency+hash)

このファイルは、本番データへの書き込みを「PR マージ=承認」で人間ゲート化し、直列化と書込直前検証で守る方針の較正記録である。運用手順の正本は `docs/playbooks/production-writes.md`。

- **提案日**: 2026-07-09
- **slug**: production-write-safety
- **判定**: **Adopt**(W 4.55)
- **再審査日**: 2027-07-09

## 提案

エージェントが本番(データベース・外部サービス・公開設定)へ直接書き込むことを禁止し、(1)提案 workflow と適用 workflow を分離して「PR マージ」を承認行為にする、(2)適用は concurrency で直列化する、(3)書込直前に読んだ時点の hash/version を再確認する(ETag/If-Match の楽観ロック)、(4)ロールバック層(kill switch→リビジョン→PITR)を用意する。

## 適用可能性ゲート

制約なし。GitHub Actions の標準機能+HTTP 標準(RFC 9110)で構成。

## 可逆性(two-way door)

パターン自体は**可逆**(workflow 構成の変更)。ただし守る対象(本番データ)は**不可逆**であり、だからこそ Adopt には実証を求めた(kjseo の実運用実証+標準仕様が該当)。

## 賛成論(3点以上)

1. **実事故が型を示した**: Replit の AI ツールが本番 DB を消した事故(2025)は「エージェントと本番の間に人間ゲートが無い」構成の帰結。PR マージを承認にすれば、破壊的操作の前に必ず人間の目が入る。
2. **標準仕様に乗る**: 書込直前の条件付き更新(ETag/If-Match)は RFC 9110 の標準。読み取り時点から状態が変わっていたら中止する楽観ロックで、「古い認識に基づく上書き」を機械的に防ぐ。kjseo が実運用で実証済み。
3. **注入経路まで塞ぐ**: Clinejection(設定注入で約4,000台被害)が示す通り、エージェント経路は注入で乗っ取られうる。GitHub の agentic workflows も同じ設計(人間承認+最小権限)へ収斂している。concurrency 直列化は競合書き込みの取りこぼしを防ぐ。

## 反対論(3点以上)

1. **リードタイムが伸びる**: 全書き込みに PR は遅い。→ 対象は「本番への不可逆書き込み」のみ。開発環境・可逆操作は通常フローでよい(比例原則)。
2. **ソロには重い**: 自分しかいないのに承認ゲート? → マージは1クリックで、ソロでも「実行前に差分を見る」チェックポイントの価値は Replit 事故が証明済み。
3. **hash 再確認の実装コスト**: 対象システムごとに実装が要る。→ パターンとして playbook に記録し、実装はプロジェクト側。G=4 に留めた理由。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 5 | RFC 9110(標準)+kjseo 実証+Replit 事故・Clinejection の実被害 |
| G: 汎用性 | 4 | 本番書込を持つプロジェクトに効く(docs 系には対象が少ない) |
| A: エージェント効果 | 4 | エージェントの不可逆操作を構造で防ぐ |
| M: 維持コスト(逆) | 5 | パターンは静的な playbook。腐らない |
| C: 複雑性コスト(逆) | 5 | 本番書込時のみ意識。通常開発に儀式を足さない |
| **W: 加重平均** | **4.55** | 拒否権抵触なし |

## 判定

**Adopt**。W4.55。原則9(本番書込は「PR マージ=承認」)の実装。

## 関連判定

| 項目 | W | 判定 | 備考 |
|---|---|---|---|
| 並列 worktree 運用 | 3.40 | Trial | pulse/kjseo に実績はあるがソロの通常規模では過剰。`docs/playbooks/parallel-agents.md` として同梱。90日TTL |

並列運用も「書き込みの直列化」という同じ原則(単一 writer)に立つためここに記録。

## 条件

—(本項目は Adopt)。並列 worktree は Trial: 複数エージェント並列が実際に必要な規模の作業が発生し、playbook が機能すると実証できれば昇格。

## 根拠ソース

- https://www.rfc-editor.org/rfc/rfc9110.html : ETag/If-Match(条件付き書き込みの標準)
- https://fortune.com/2025/07/23/ai-coding-tool-replit-wiped-database-called-it-a-catastrophic-failure/ : Replit 本番 DB 消失事故
- https://adnanthekhan.com/posts/clinejection/ : Clinejection(実被害約4,000台)
- https://github.blog/ai-and-ml/generative-ai/under-the-hood-security-architecture-of-github-agentic-workflows/ : GitHub agentic workflows のセキュリティ設計
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency : concurrency 直列化(公式)
