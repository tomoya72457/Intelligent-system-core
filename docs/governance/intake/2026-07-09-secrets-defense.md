# intake 判定記録: シークレット防衛(gitleaks 二層+.env.example+deny)

このファイルは、秘密情報の漏洩を多層で防ぐ方針の較正記録である。

- **提案日**: 2026-07-09
- **slug**: secrets-defense
- **判定**: **Adopt**(W 4.60)
- **再審査日**: 2027-07-09

## 提案

(1)gitleaks を二層(ローカル `tools/githooks/pre-commit` の `gitleaks protect --staged`+CI の `.github/workflows/ci.yml`)で走らせ、(2)`.env.example` にダミー値の雛形を置き実値は `.env`(gitignore 済)へ誘導し、(3)`.claude/settings.json` の permissions.deny で `.env`・`secrets/**` の読み取りを禁止する。

## 適用可能性ゲート

制約あり(だが回避策あり)。GitHub の secret scanning は private リポジトリで無償提供されない。→ だからこそ OSS の gitleaks を自前で二層に組み込み、プラン非依存にする。

## 可逆性(two-way door)

**可逆**。gitleaks の呼び出し・deny リスト・`.env.example` はいずれもファイル/設定で撤去容易。ただし一度漏れた秘密は不可逆(だから予防に投資する)。

## 賛成論(3点以上)

1. **AI コミットは漏洩が約2倍**: AI エージェントのコミットは人間より約2倍の頻度で秘密を混入するとの報告(GitGuardian)。エージェント駆動では秘密防衛の優先度が上がる。
2. **private 無償スキャン不在の穴埋め**: GitHub Advanced Security の secret scanning は private 無償枠に無い。gitleaks 二層はこの穴を塞ぎ、public/private・プラン問わず機能する。
3. **読ませない+コミットさせないの両面**: deny リスト(`.claude/settings.json`)でエージェントに秘密を読ませず、gitleaks でコミットを止める。`.env.example` で「参照すべき雛形」を示し、誤って `.env` を触る動線を断つ。

## 反対論(3点以上)

1. **gitleaks の誤検知**: 正規のダミー値まで弾く恐れ。→ `.env.example` はダミーと明示し、必要なら allowlist で調整。二層のうちローカルは `protect --staged` で速く、CI が最終防衛。
2. **deny リストで正当な参照も不可**: 設定読み取りが必要な場面が困る。→ 秘密は `.env.example` を参照させ、実値の読み取りだけを禁止。運用に必要な情報は雛形側に置く。
3. **完全ではない**: gitleaks を擦り抜ける秘密形式もある。→ 多層防御の一部と位置づけ、履歴に入った秘密は失効(rotate)を前提とする運用を README で案内。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 5 | private 無償スキャン不在(公式ドキュメント)+AI 2倍リーク(GitGuardian)の実測 |
| G: 汎用性 | 5 | 全プロファイル・全リポジトリで有効 |
| A: エージェント効果 | 4 | エージェントの秘密混入を止める。検証ループの核ではないため4 |
| M: 維持コスト(逆) | 4 | gitleaks 設定は静的。allowlist を稀に調整 |
| C: 複雑性コスト(逆) | 5 | 普段は透過。`.env.example` を埋めるだけ |
| **W: 加重平均** | **4.60** | 拒否権抵触なし |

## 判定

**Adopt**。W4.60。適用可能性ゲートで GitHub 純正機能は弾かれるが、gitleaks 二層で回避し全プランで機能させる。

## 条件

—(Adopt のため無し)

## 根拠ソース

- https://docs.github.com/en/billing/concepts/product-billing/github-advanced-security : private の無償スキャン不在
- https://github.com/gitleaks/gitleaks : OSS の秘密スキャナ(二層で使用)
- https://www.helpnetsecurity.com/2026/04/14/gitguardian-ai-agents-credentials-leak/ : AI コミットの秘密混入は人間の約2倍
- https://code.claude.com/docs/en/settings : permissions.deny による読み取り禁止(公式)
