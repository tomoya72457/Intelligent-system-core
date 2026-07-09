# intake 判定記録: Reject 済みプラクティス一覧(蒸し返し防止)

このファイルは、テンプレート構築時に検討して **Reject** と判定した11項目の理由と根拠をまとめた較正記録である。同じ提案が再浮上したら、まずここを確認する(状況が変わった場合のみ再判定する)。

- **提案日**: 2026-07-09
- **slug**: rejected-practices
- **判定**: **全項目 Reject**
- **再審査日**: —(Reject に TTL は無い。前提が変わった時のみ個別に再 intake)

## 判定の共通枠

各項目は `docs/governance/rubric.md` のプロセスを適用した。適用可能性ゲートで落ちたもの(環境制約)、拒否権(セキュリティ悪化)で落ちたもの、W<2.0 で落ちたものが混在する。個別の賛成論は「一般に言われる利点」として検討済みであり、以下では却下理由(反対論の決定打)と根拠を記録する。

## 1. llms.txt

- **却下理由**: 実測で採用サイトへの AI クローラーアクセスの 0.1% しか llms.txt を読まず(otterly.ai の実験)、Google も「純粋に憶測」と公式に否定。書いても読まれないファイルは維持コストだけが残る。
- **根拠**: https://www.searchenginejournal.com/google-says-llms-txt-is-purely-speculative-for-now/577576/ / https://otterly.ai/blog/the-llms-txt-experiment/

## 2. ベンダーメモリ機能依存(Cursor Memories 等)

- **却下理由**: スコープ漏れ(別プロジェクトの記憶が混入)と無告知消失の実績があり、耐久層にならない。git 管理されたファイル(AGENTS.md / docs/)だけが監査可能で永続する知識層。
- **根拠**: ベンダーメモリの信頼性問題の実践報告群+本テンプレートの原則2(git 管理ファイルへの段階開示)

## 3. merge queue

- **却下理由**: 適用可能性ゲートで即落ち — 個人アカウントでは使用不可(organization 限定)。加えてソロ開発では並行マージの競合という「解く問題」自体が無い。
- **根拠**: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue

## 4. semantic-release

- **却下理由**: コミットが即リリースになるチェックポイント無しの自動公開は、ソロ+エージェント駆動では誤公開リスクが高い。release-please(リリース PR を挟む方式)が「PR マージ=承認」原則とも整合する上位互換(release-please 自体は Trial、`docs/governance/intake/2026-07-09-rulesets-and-bootstrap.md`)。
- **根拠**: https://www.hamzak.xyz/blog-posts/release-please-vs-semantic-release

## 5. AIレビューのブロッキングゲート化

- **却下理由**: 拒否権(セキュリティ)発動。LLM 判定はプロンプト注入で 89-99% 操作可能(JudgeDeceiver)で、ベンダー自身が注入非対応を明言。門番権限を与えると攻撃標的になる。助言としての採用は Adopt 済み(`docs/governance/intake/2026-07-09-ai-review-advisory.md`)。
- **根拠**: https://arxiv.org/abs/2403.17710 / https://github.com/anthropics/claude-code-security-review

## 6. 役割分解マルチエージェントの既定化

- **却下理由**: MAST(マルチエージェント失敗分類)によれば失敗の79%が仕様不備・検証不足であり、役割を増やしても解決しない。既定は「単一エージェント+良い道具(検証ループ・境界lint)」。並列化は worktree 分離の playbook として Trial に限定(`docs/playbooks/parallel-agents.md`)。
- **根拠**: https://arxiv.org/abs/2503.13657

## 7. 署名コミット必須化

- **却下理由**: 実採用6%(arxiv 2604.14014)で、bot/エージェントのコミット・CI からの push を複雑化させる割に、ソロ開発の脅威モデルで得るものが少ない。本人の SSH 署名は任意で使えばよい(禁止はしない)。
- **根拠**: https://arxiv.org/abs/2604.14014

## 8. CODEOWNERS 自己レビュー必須化

- **却下理由**: 適用可能性ゲートで即落ち — GitHub は PR 作成者自身の承認を認めないため、ソロで CODEOWNERS レビューを必須にすると自分の PR を誰も承認できないセルフデッドロックになる。承認0の Rulesets が正解(`docs/governance/intake/2026-07-09-rulesets-and-bootstrap.md`)。
- **根拠**: https://github.com/orgs/community/discussions/14866

## 9. 重量 ADR/RFC の全件適用

- **却下理由**: 比例原則違反。全変更に重い様式を課すと書かれなくなり、記録文化自体が死ぬ。軽量テンプレート+閾値(アーキテクチャ判断を含む変更のみ)が正(`docs/adr/TEMPLATE.md`、Adopt 済み)。
- **根拠**: https://www.thoughtworks.com/radar/techniques/lightweight-approach-to-rfcs

## 10. .cursorrules / AGENT.md(単数形)

- **却下理由**: 両方とも公式に廃止・敗北済み。`.cursorrules` は Cursor が `.cursor/rules/` へ移行、`AGENT.md` 単数形は業界が `AGENTS.md` 複数形へ収斂(Amp 自身が移行を表明)。死んだ規格に投資しない。
- **根拠**: https://ampcode.com/news/AGENT.md / https://agents.md/

## 11. 巨大 CLAUDE.md(網羅志向)

- **却下理由**: ルールを20個並べると遵守率が半減する実験結果+命令数スケーリングの劣化(IFScale)。網羅は遵守の敵。本テンプレートは予算強制(`tools/check_structure.py`)+段階開示で逆を行く(`docs/governance/intake/2026-07-09-context-budget-enforcement.md`)。
- **根拠**: https://zenn.dev/hoppii007/articles/claude-md-anti-patterns / https://arxiv.org/abs/2507.11538

## 補遺: spec-driven 開発の「常時適用」

Reject 表には載せていないが、spec-driven 開発を全タスクに常時適用する案も却下した。Thoughtworks Radar は Assess 判定に留め、Fowler 系の分析もツール成熟度の途上を指摘する。サイズ閾値ゲート付きの /spec スキルとして Trial 同梱が本テンプレートの結論(`docs/governance/intake/2026-07-09-small-batch-discipline.md`)。

- **根拠**: https://www.thoughtworks.com/en-us/radar/techniques/spec-driven-development / https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html

## 運用メモ

- これらを再提案する場合は、**何が変わったか**(プラン制約の解消・新しい実証データ等)を新しい intake 記録に明示すること。変化の無い再提案は本記録の参照のみで棄却してよい。
