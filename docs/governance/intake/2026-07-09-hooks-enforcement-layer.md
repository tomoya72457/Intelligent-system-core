# intake 判定記録: hooks 二層強制+CI サプライチェーン硬化

このファイルは、ローカル hooks と CI を二層で強制する防御レイヤの較正記録である。hooks(危険遮断・秘密遮断・設定保護)を主とし、同じ「注入・供給網攻撃への機械的防御」テーマの SHA固定 Action+zizmor、dependabot もここにまとめる。

- **提案日**: 2026-07-09
- **slug**: hooks-enforcement-layer
- **判定**: **Adopt**(W 4.30)
- **再審査日**: 2027-07-09

## 提案

`.claude/hooks/`(block-dangerous.sh / block-secret-read.sh / protect-agent-config.sh / auto-format.sh)でエージェント操作を PreToolUse/PostToolUse で遮断・整形し、CI(`.github/workflows/ci.yml`)がバックストップになる二層強制。ローカルのみだと再クローンで消えるため、CI 側の必須チェックで裏打ちする(原則6)。

## 適用可能性ゲート

制約なし。Claude Code 公式の hooks 機構+shell スクリプト。

## 可逆性(two-way door)

**可逆**。hooks は settings.json の配線とスクリプトで、無効化は編集のみ。ただし hooks 自体の自己改変は `protect-agent-config.sh` で禁止(セキュリティ境界)。

## 賛成論(3点以上)

1. **設定ファイル注入が最重大ベクター**: GitInject 研究は、エージェント設定ファイルへの注入が最も重大な攻撃経路と示す。`protect-agent-config.sh` で `.claude/settings.json`・hooks・`tools/githooks/**` の自己編集を止めることは直接の対策(原則8)。
2. **実事故に基づく遮断ルール**: 危険コマンド(`rm -rf`・`sudo`・`curl|bash`・main への force push・一括 `git add`)の遮断は、日本語圏7ソースの実践知と実事故に裏打ちされる。散文の注意書きより hooks が確実(原則1)。
3. **二層でローカル消失に耐える**: ローカル githooks だけでは再クローンで消える。CI バックストップと組み合わせて初めて「消えない強制」になる。

## 反対論(3点以上)

1. **誤遮断で作業が止まる**: 正規表現が粗いと正当な操作まで止める。→ 精密な正規表現+exit 2 で日本語の理由と代替手段を提示。誤遮断は M(維持)に響くため精度に投資。
2. **hooks 自体が攻撃対象**: 注入で hooks を書き換えられたら無力。→ だからこそ自己改変を hooks で禁止し、変更は人間がエディタで直接+ADR 記録に限定。
3. **維持コスト**: 遮断ルールは環境変化で腐りうる(M=3)。→ 各ルールにコメントで根拠(例: 実事故のコミットハッシュ)を残し、棚卸し可能にする。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 4 | 日本7ソース+Claude Code 公式+GitInject の査読。収斂している |
| G: 汎用性 | 5 | 全プロファイルで同じ危険操作を防ぐ |
| A: エージェント効果 | 5 | エージェントの破壊的操作を実行前に止める。決定性が高い |
| M: 維持コスト(逆) | 3 | 遮断ルールは環境変化で調整が要る |
| C: 複雑性コスト(逆) | 4 | 普段は透過。遮断時のみ利用者が代替手段を要する |
| **W: 加重平均** | **4.30** | 拒否権抵触なし |

## 判定

**Adopt**。W4.30。原則6(二層強制)・原則8(設定=セキュリティ対象)の中核。

## 関連判定

| 項目 | E | G | A | M | C | W | 判定 |
|---|---|---|---|---|---|---|---|
| SHA固定 Action+zizmor | 4 | 5 | 3 | 4 | 4 | 3.95→4.0 | Adopt(セキュリティ加点) |
| dependabot(cooldown 7日+patch/minor 群) | 4 | 5 | 3 | 4 | 4 | 3.95→4.0 | Adopt(セキュリティ加点) |
| devcontainer 隔離 | — | — | — | — | — | 3.75 | Trial |

- **SHA固定 Action+zizmor**: 全 GitHub Action を SHA 固定+バージョンコメント、zizmor で workflow を lint。Clinejection の実被害(設定/action 経由の注入)への直接防御。素点3.95だが原則8のセキュリティ加点で 4.0=Adopt。
- **dependabot**: cooldown 7日+patch/minor グループ化、major は個別 PR。Axios 事件(141件の自動マージ)に見る「無警戒な自動マージ」への抑制。同じく加点で 4.0=Adopt。
- **devcontainer 隔離(Trial)**: 公式推奨だが導入コスト中。無人実行(`--dangerously-skip-permissions`)する時の隔離前提として文書化。90日TTL。

## 条件

—(本項目は Adopt)。devcontainer は Trial: 無人実行を実際に行う場面が生じ、隔離が有用と実証できれば昇格。

## 根拠ソース

- https://code.claude.com/docs/en/hooks : Claude Code hooks 公式
- https://zenn.dev/kazuph/articles/483d6cf5f3798c : hooks 実践知(日本語圏)
- https://digirise.ai/chaen-ai-lab/claude-md-design-guide/ : 設計ガイド(日本語圏)
- https://note.com/mizupe/n/n0cda0117ada3 : 運用知見(日本語圏)
- https://arxiv.org/html/2606.09935v1 : GitInject。設定ファイル注入が最重大ベクター


## 既知の限界(2026-07-09 独立レビューでの実測)

- hooks は**防御の一層**であり網羅ではない。実測で確認済みの残余経路: インタープリタ経由の読み書き(`python3 -c 'open(...)'` 等)は正規表現検査を通過する。
- 対策済みの経路(同レビュー起点): Grep ツールの秘密パス検索(matcher へ Grep 追加)、保護パスへのリダイレクト・tee・cp/mv/install・sed -i、`/bin/rm` 形、`xargs rm`、`git add :/`。
- 残余リスクの最終防衛は、`.claude/rules/agent-config-changes.md`(変更は人間+ADR)と PR レビュー。「hooks があるから安全」とは扱わないこと。
