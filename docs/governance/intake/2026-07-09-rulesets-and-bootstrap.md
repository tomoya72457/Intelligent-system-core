# intake 判定記録: Rulesets JSON+bootstrap 適用

このファイルは、ブランチ保護を Rulesets の JSON で定義し bootstrap で適用する方針の較正記録である。同じ「配布・同期」テーマの template-sync と release-please もここにまとめる。

- **提案日**: 2026-07-09
- **slug**: rulesets-and-bootstrap
- **判定**: **Adopt**(W 4.30)
- **再審査日**: 2027-07-09

## 提案

`main` の保護を `.github/rulesets/main.json` に宣言(PR 必須・承認0・必須ステータスチェック ci・force push 禁止・削除禁止・管理者 bypass)し、`tools/bootstrap.sh` が GitHub REST API で適用する。Template repo はリポジトリ設定を運ばないため、ファイル同梱+適用スクリプトで穴を塞ぐ。

## 適用可能性ゲート

制約あり(明記して回避)。Rulesets の required_status_checks 等は Free プランの private リポジトリで一部制約される。→ 本テンプレートは public 配布前提。bootstrap は適用失敗時(Free の private 等)に警告して続行し、制約を README に明記する。

## 可逆性(two-way door)

**可逆**。ruleset は API/UI で削除でき、JSON はファイル。撤去容易。

## 賛成論(3点以上)

1. **テンプレートは設定を運ばない**: Template repo からの生成ではブランチ保護等の設定はコピーされない(GitHub コミュニティで既知)。設定を JSON ファイルとして同梱し bootstrap で適用すれば、この欠落を確実に埋められる。
2. **承認0+本人 bypass がソロに最適**: ソロ開発では自己承認が要求されるとデッドロックする。承認0で PR 必須・ステータスチェック必須にすれば、CODEOWNERS 自己レビュー(Reject 済み)のデッドロックを避けつつゲートを効かせられる。user bypass は公式サポート済み。
3. **宣言的で再現可能**: JSON は REST の `POST /repos/{o}/{r}/rulesets` にそのまま渡せる。設定が版管理され、監査・再適用ができる。

## 反対論(3点以上)

1. **Free private で効かない**: 一部機能がプラン制約。→ 適用可能性ゲートで明示し、bootstrap は失敗を握りつぶさず警告+続行。README で Pro 必要な点を案内。
2. **API 適用が壊れやすい**: GitHub API 変更で bootstrap が古くなる。→ M=4。doctor 表示(OK/SKIP/FAIL)で失敗を可視化し、手動フォールバックを案内。
3. **本人 bypass は保護を骨抜きにしないか**: bypass できるなら意味が薄いのでは。→ 目的は「うっかり main 直 push」の防止であり、悪意ある本人は想定しない。ソロの現実的な安全弁。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 4 | GitHub 公式仕様+テンプレ非コピー問題の既知報告 |
| G: 汎用性 | 5 | 全プロファイルのリポジトリ保護に共通 |
| A: エージェント効果 | 4 | main 直 push を止め PR 経由を強制。エージェントの暴走を構造で防ぐ |
| M: 維持コスト(逆) | 4 | JSON は静的。API 変更時のみ追随 |
| C: 複雑性コスト(逆) | 5 | bootstrap が自動適用。利用者は意識不要 |
| **W: 加重平均** | **4.30** | 拒否権抵触なし |

## 判定

**Adopt**。W4.30。原則9(PR マージ=承認)の土台。適用可能性の制約は回避策込みで許容。

## 関連判定

| 項目 | E | G | A | M | C | W | 判定 |
|---|---|---|---|---|---|---|---|
| template-sync(pull型更新PR) | 4 | 5 | 3 | 3 | 4 | 3.80 | 採用(ADR-0001 の確定判断) |
| release-please | — | — | — | — | — | 3.05 | Trial |
| アカウントレベル `.github` リポジトリ | — | — | — | — | — | — | Assess |

- **template-sync**: `.github/workflows/template-sync.yml` が AndreasAugustin/actions-template-sync で更新 PR を作る pull 型同期。W3.80 で本来 Trial 域だが、配布形態を決める壁打ちの確定判断(`docs/adr/0001-distribution-and-adoption.md`)としてルーブリック外で採用。
- **release-please(Trial)**: ライブラリ的プロジェクトのみ価値。semantic-release(Reject)の上位互換で、profiles 内にオプション文書化。90日TTL。
- **アカウントレベル `.github` リポジトリ(Assess)**: public 必須+クローンに現れずエージェントから不可視のため配布骨格には不適。将来、汎用 SECURITY 等の薄い層としてのみ再検討。

## 条件

—(本項目は Adopt)。release-please は Trial: ライブラリ配布の実需が出て有用と確認できれば昇格。

## 根拠ソース

- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets : Rulesets 公式
- https://github.blog/changelog/2026-05-07-repository-rulesets-user-bypass-and-branch-renaming/ : user bypass の公式サポート
- https://github.com/orgs/community/discussions/55200 : テンプレートは設定を運ばない(既知問題)
- https://cli.github.com/manual/gh_repo_edit : bootstrap が使うリポジトリ設定 API/CLI
