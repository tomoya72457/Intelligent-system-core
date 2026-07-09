# intake 判定記録: 依存境界 lint(適応度関数)

このファイルは、モジュール境界を dependency-cruiser(TS)/ import-linter(Py)で宣言し、CI ゲートとして機械強制する方針の較正記録である。詳細な運用は `docs/conventions/architecture.md`。

- **提案日**: 2026-07-09
- **slug**: architecture-fitness-functions
- **判定**: **Adopt**(W 4.10)
- **再審査日**: 2027-07-09

## 提案

レイヤ(層)を宣言し依存方向を一方通行に定め、dependency-cruiser / import-linter で違反を CI(`make arch` 経由)がブロックする。既存コードには freeze/baseline 方式で後付けできるようにする。定義例は `profiles/typescript/.dependency-cruiser.cjs` と `profiles/python/pyproject.toml`。

## 適用可能性ゲート

制約なし。両ツールとも OSS でローカル/CI で動く。

## 可逆性(two-way door)

**可逆**。ルールは設定ファイルで、外す/緩めるのは編集のみ。

## 賛成論(3点以上)

1. **境界は文書でなくコードで守る**: 情報隠蔽(Parnas 1972)の「モジュールが隠す決定」を境界として宣言し、逸脱を lint で止める。散文の規約は破られるが、適応度関数は破れない(原則5)。
2. **大規模実運用の実績**: Netflix は ArchUnit を 358 ルール×約5,000リポジトリへ展開。境界検査は現実に回る仕組みである。
3. **エージェントのスパゲッティ化抑止**: エージェントは局所最適で層を飛び越えがち。依存方向の一方通行を機械強制すれば、生成コードの構造崩壊を早期に止められる(A 軸が高い理由)。

## 反対論(3点以上)

1. **既存コードに一括導入は破綻**: いきなり全違反を赤にすると作業が止まる。→ freeze/baseline 方式。現状違反を凍結し、新規違反のみ止め、baseline を漸減する(Adidas 等の実運用パターン)。
2. **層設計が固すぎると邪魔**: 小規模プロジェクトに層は過剰。→ プロファイルの既定層は最小(TS: app→features→shared/core、Py: api→services→models)。素のテンプレートでは no-op。
3. **維持コスト**: 層を変えるたびに設定更新が要る。→ M=3 と評価。境界変更は本来低頻度であり、変更時は ADR(`docs/adr/`)で意図を残す。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 4 | Parnas 系の理論+Netflix/Adidas の大規模実運用。査読単発ではないが収斂 |
| G: 汎用性 | 4 | TS/Py に効く。docs プロファイルには境界概念が薄いため5でなく4 |
| A: エージェント効果 | 5 | 生成コードの構造崩壊を機械的に止める。決定性が高い |
| M: 維持コスト(逆) | 3 | 層変更時に設定更新。baseline の漸減も手間 |
| C: 複雑性コスト(逆) | 4 | 既定は透過的だが、違反時に層設計の理解を要する |
| **W: 加重平均** | **4.10** | 拒否権抵触なし |

## 判定

**Adopt**。W4.10。原則5(境界の適応度関数)の実装。freeze/baseline で後付け可能にすることが汎用性の鍵。

## 条件

—(Adopt のため無し)

## 根拠ソース

- https://dl.acm.org/doi/10.1145/361598.361623 : Parnas 1972(情報隠蔽・モジュール分割)
- https://netflixtechblog.com/scaling-archunit-with-nebula-archrules-b4642c464c5a : 358 ルール×約5,000リポの実運用
- https://github.com/sverweij/dependency-cruiser : TS 向け依存境界 lint
- https://import-linter.readthedocs.io/ : Python 向け層境界 contract
