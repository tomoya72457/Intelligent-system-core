# Tech Radar(判定台帳)

このファイルは、本テンプレートに何を入れ・何を入れなかったかの根拠台帳である。各行は `docs/governance/rubric.md` のルーブリックを適用した判定結果で、対応する詳細記録が `docs/governance/intake/` にある。新しい既定変更の提案は adoption-judge が判定し、ここに1行追加する。

- **表記**: E/G/A/M/C = ルーブリック5軸のスコア、W = 加重平均。
- **TTL**: Adopt 項目の再審査期限 = **2027-07-09**(12ヶ月)。Trial 項目の期限 = **2026-10-07**(90日)。期限までに実運用実証がなければ Trial は降格する。
- **較正**: 2026-07-09 の構築時、全項目で期待整合を確認済み(`docs/governance/rubric.md` の較正記録を参照)。

## Adopt(本テンプレートに実装)

| 項目 | E | G | A | M | C | W | 主根拠 | 記録 |
|---|---|---|---|---|---|---|---|---|
| AGENTS.md 正本+全ツールポインタ統合 | 5 | 5 | 5 | 4 | 5 | 4.85 | 7つ以上のエコシステム収斂・Linux Foundation 管轄化 | agents-md-canonical |
| 常時コンテキスト予算+構造リンター機械強制 | 5 | 5 | 5 | 4 | 4 | 4.75 | 査読3研究+Codex 32KiB 実測+実運用収斂 | context-budget-enforcement |
| 1コマンド検証(make check)+CI 必須チェック | 5 | 5 | 5 | 4 | 5 | 4.85 | SWE-bench 系+DORA+全ベンダー | single-command-verification |
| 小PR規律(規範+CI警告400行) | 5 | 5 | 4 | 5 | 4 | 4.65 | DORA 24/25+Google+MSR2026 | small-batch-discipline |
| 依存境界 lint(d-cruiser / import-linter, freeze方式) | 4 | 4 | 5 | 3 | 4 | 4.10 | Parnas 系+Netflix 実績+Adidas | architecture-fitness-functions |
| hooks 二層強制(危険遮断+秘密遮断+設定保護) | 4 | 5 | 5 | 3 | 4 | 4.30 | 日本7ソース+公式+GitInject | hooks-enforcement-layer |
| シークレット防衛(gitleaks 二層+.env.example+deny) | 5 | 5 | 4 | 4 | 5 | 4.60 | private 無償スキャン不在+AI 2倍リーク | secrets-defense |
| python venv の iCloud 外退避(UV_PROJECT_ENVIRONMENT) | 3 | 2.5 | 4 | 5 | 5 | 3.65 | 同日2回の実障害+規約「2回目で機械強制化」発動 | venv-outside-icloud |
| Rulesets JSON+bootstrap 適用(force-push/削除保護。PR必須は 2026-07-09 オーナー決定で撤回=ADR-0006) | 4 | 5 | 4 | 4 | 5 | 4.30 | GitHub 公式検証済+テンプレ非コピー問題 | rulesets-and-bootstrap |
| Conventional Commits+.gitmessage(lintゲート無し) | 4 | 5 | 4 | 5 | 5 | 4.45 | 公式 spec+ソロ実践報告 | small-batch-discipline |
| 軽量ADR(minimal+Confirmation欄) | 4 | 5 | 4 | 3 | 4 | 4.05 | Radar Adopt+rot 対策込み | issue-forms-and-adr |
| Issue Forms 構造化タスク(受け入れ基準必須) | 4 | 5 | 5 | 4 | 4 | 4.45 | GitHub 公式+小タスク実証 | issue-forms-and-adr |
| AIレビュー助言+決定的チェックブロック | 5 | 5 | 4 | 4 | 5 | 4.60 | JudgeDeceiver+ベンダー設計 | ai-review-advisory |
| 3層知識構造(常時規約 / skills / docs)+スキル採用基準 | 4 | 5 | 5 | 3 | 4 | 4.30 | 5エコシステム収斂 | context-budget-enforcement |
| 本番書込セーフティ(PRマージ=承認+concurrency+hash) | 5 | 4 | 4 | 5 | 5 | 4.55 | RFC9110+kjseo 実証+Replit 事故 | production-write-safety |
| SHA固定 Action+zizmor | 4 | 5 | 3 | 4 | 4 | 3.95→4.0 | 公式+Clinejection 実被害(セキュリティ加点) | hooks-enforcement-layer |
| dependabot(cooldown 7日+patch/minor 群) | 4 | 5 | 3 | 4 | 4 | 3.95→4.0 | 公式+Axios 事件141自動マージ(同上) | hooks-enforcement-layer |
| template-sync(pull型更新PR) | 4 | 5 | 3 | 3 | 4 | 3.80 | 壁打ち確定判断(ADR-0001)。判定外の採用 | rulesets-and-bootstrap |
| 生きた文書運用(ミス2回で追記・削除テスト・月次棚卸) | 4 | 5 | 4 | 3 | 4 | 4.05 | 日本4〜5ソース+ACE curation | context-budget-enforcement |
| adoption-judge 自体(本ルーブリック+記録+TTL) | 4 | 5 | 4 | 4 | 4 | 4.20 | Radar 運用+先行事例多数(自己適用) | ai-review-advisory |
| reviewer 分離(fresh-context 批判レビュー) | 4 | 5 | 4 | 4 | 4 | 4.20 | Cognition+日本5ソース | ai-review-advisory |
| 相対リンク実在検証(check_structure 拡張・error) | 4 | 5 | 4 | 4 | 4 | 4.20 | docsリンク検査5+ツール収斂+リポ内no-op/CI不在実測+全23リンク実在確認 | docs-link-existence-check |
| docs ADR↔INDEX 同期チェック(check_adr_index_sync・error) | 4 | 5 | 5 | 5 | 4 | 4.60 | 下流 rutirise で ADR-0016 の INDEX 欠落を実測+ADRスキルが既にINDEX追記を手順化 | docs-router-index-coverage |

SHA固定 Action と dependabot は素点 3.95 だが、原則6・原則8のセキュリティ加点(サプライチェーン注入・自動マージ事故の直接防御)により 4.0 として Adopt。template-sync は W3.80 で本来 Trial 域だが、配布形態そのものを決める壁打ちの確定判断(`docs/adr/0001-distribution-and-adoption.md`)であり、ルーブリック外の採用として扱う。

## Trial(同梱するがオプトイン・TTL 2026-10-07)

| 項目 | W | 条件・理由 | 記録 |
|---|---|---|---|
| スペック駆動フロー(/spec スキル) | 3.15 | 全独立レビュアーが「タスクサイズ閾値必須」で一致。非自明機能のみ発火するゲート付きで同梱 | small-batch-discipline |
| devcontainer 隔離 | 3.75 | 公式推奨だが導入コスト中。無人実行(--dangerously-skip-permissions)時の前提条件として文書化 | hooks-enforcement-layer |
| 並列 worktree 運用 | 3.40 | pulse/kjseo に実績はあるがソロの通常規模では過剰。playbook として同梱 | production-write-safety |
| カバレッジ床 | 3.20 | テスト品質シグナルとして有効だがゲーム化リスク。profiles 内でコメントアウト提供 | single-command-verification |
| release-please | 3.05 | ライブラリ的プロジェクトのみ価値。profiles 内でオプション文書化 | rulesets-and-bootstrap |
| docs ルータ網羅チェック(check_router_coverage・階層型) | 3.95 | 到達定義が要設計。Trial 中は warn(非ブロッキング)。ledger-dir 偽陽性ゼロを doc 追加サイクルで実証後に error 化して Adopt 昇格。TTL 2026-10-18 | docs-router-index-coverage |

## Assess(記録のみ・同梱しない)

| 項目 | 理由 | 記録 |
|---|---|---|
| mutation testing | M/C(維持・複雑性)が高い。品質シグナルとしては魅力だが常時装備には重い | single-command-verification |
| judge 定期自動巡回 | エージェント入りCIのセキュリティ設計が先。無人巡回は攻撃面を増やす | ai-review-advisory |
| Claude Code プラグイン化配布 | Trial 相当だが配布形態は Template repo 方式で決定済み(ADR-0001)。12ヶ月後に再審査 | agents-md-canonical |
| 中央CI用 reusable workflows リポジトリ | 個人アカウント唯一のネイティブCI同期チャネルだが、Makefile 集約で薄い caller 相当を達成済み+リポジトリ間結合が増える。管理リポジトリ5超で再評価 | single-command-verification |
| アカウントレベル `.github` リポジトリ | public 必須+クローンに現れずエージェントから不可視のため配布骨格に不適。汎用 SECURITY 等の薄い化粧層としてのみ将来検討 | rulesets-and-bootstrap |

## Reject(判定記録に残す — 蒸し返し防止)

| 項目 | 主理由 |
|---|---|
| llms.txt | 採用されても無視される実測(0.1%アクセス)+Google 公式が否定 |
| ベンダーメモリ機能依存(Cursor Memories 等) | スコープ漏れ+無告知消失の実績。git 管理ファイルのみが耐久層 |
| merge queue | 個人アカウントで使用不可(適用可能性ゲート)+ソロで解く問題が無い |
| semantic-release | チェックポイント無しの自動公開はソロ不適。release-please が上位互換 |
| AIレビューのブロッキングゲート化 | 判定操作攻撃 89-99% 成功+ベンダー自身が非対応を明言 |
| 役割分解マルチエージェントの既定化 | MAST: 失敗の79%が仕様不備・検証不足。単一エージェント+良い道具が既定 |
| 署名コミット必須化 | 実採用6%+bot/エージェント直 push を複雑化。本人の SSH 署名は任意 |
| CODEOWNERS 自己レビュー必須化 | ソロではセルフデッドロック(GitHub 仕様) |
| 重量ADR/RFC の全件適用 | 比例原則違反。軽量+閾値が正 |
| .cursorrules / AGENT.md(単数形) | 両方とも公式に廃止・敗北済み |
| 巨大 CLAUDE.md(網羅志向) | 命令20個で遵守率半減の実験+IFScale |

Reject 全11項目の詳細(理由・根拠ソース)は `docs/governance/intake/2026-07-09-rejected-practices.md` にまとめてある。

## 参照

- 判定基準: `docs/governance/rubric.md`
- 詳細記録: `docs/governance/intake/2026-07-09-*.md`
- 判定を実行するサブエージェント: `.claude/agents/adoption-judge.md`
