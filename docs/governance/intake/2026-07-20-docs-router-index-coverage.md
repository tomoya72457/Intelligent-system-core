# intake 判定記録: docs ルータ/索引カバレッジ検証を構造チェックへ追加

- **提案日**: 2026-07-20
- **slug**: docs-router-index-coverage
- **判定**: 分割 — ADR↔INDEX 同期 = Adopt(W 4.60)/ ルータ網羅 = Trial(W 3.95)
- **再審査日**: Adopt 分 = 2027-07-20 / Trial 分 = 2026-10-18(90日TTL)

## 提案

tools/check_structure.py に「docs 文書のルータ/索引カバレッジ検証」を追加し既定ゲートに含める。
(1) docs/adr/ の各 ADR が INDEX.md に載っていること(check_adr_index_sync)、
(2) docs/ 配下の各文書がルータ docs/README.md から到達可能であること(check_router_coverage)。
docs-rules.md §2「新規文書はルータに1行追加」と docs/README.md:3「載っていない文書は原則存在しない」の
宣言に強制コードが無い欠落を埋める。既定変更であり日常の実装判断ではない。

## 過去記録との矛盾チェック

- 蒸し返しではない。本提案は 2026-07-14 ハンドオフ(docs/handoffs/2026-07-14-guard-gaps-from-rutirise-audit.md)
  の B-2 [G7]「check_adr_index_sync と check_router_coverage を追加、intake 経由」の初回正式判定。
- 親 Adopt(context-budget-enforcement / 生きた文書運用 / 3層知識構造)の直系拡張で競合なし。
- Reject「巨大 CLAUDE.md(網羅志向)」との緊張は見かけのみ: あれは常時読み込み文脈の網羅が遵守率を下げる話。
  本提案はオンデマンド索引(docs/README.md)の完全性保証で、段階開示の発見層を信頼できる状態に保つ側。
- docs-rules §3(追記型台帳・全文再生成禁止)と非衝突: ファイル単位列挙を intake 記録へ強制せず、
  全文再生成も要求しない(下記の階層設計で担保)。

## 適用可能性ゲート

制約なし。標準ライブラリのみで check_structure.py に関数追加。配線変更不要。checker は通常のエージェント
編集領域(保護対象の .claude/settings*・hooks・.github/workflows・tools/githooks ではない)。通過。

## 可逆性(two-way door)

高(可逆)。関数追加+テストのみ、撤去は関数削除。Trial 分は warn(非ブロッキング)で開始するため push を止めない。

## 賛成論(3点以上)

1. 観測済みドリフト(逸話でなく監査事実): 下流 rutirise で ADR-0016 の INDEX 欠落+現役文書13本のルータ未掲載を
   実測(ハンドオフ表 G7)。docs/README.md:3 の宣言を保証するコードが無い穴。「ミス2回で規約化・機械強制」の発動対象。
2. エージェントの発見経路そのものを守る: エージェントは docs をルータ/INDEX 経由でしか見つけない。
   索引の欠落=知識の不可視化=再作成・見落とし。索引完全性は一次的なコンテキスト経済の性質。
3. 全プロファイル共通の基盤: docs/README.md ルータと adr/INDEX は checker が既に存在検証している共通装備。
   docs プロファイル(profiles/docs/ の「役割フォルダごとにエントリ README」)とも思想的に整合。
4. ADR↔INDEX は決定的・低摩擦: NNNN-*.md の厳密命名で機械突合可能。ADR スキルは既に INDEX 追記を手順化済みで、
   新たな儀式を足さずスキップだけを捕捉。

## 反対論(3点以上)

1. 「到達」の定義が難しい: ナイーブな「全 docs/**/*.md を docs/README.md に逐語掲載」は現リポジトリで即座に
   約15件の偽陽性(intake 13件+ADR 0006/0007 は範囲記法の外)。intake はテーマ粒度で tech-radar から参照する
   追記型台帳(docs-rules §3)で、1ファイル1行強制は台帳運用と衝突。階層設計が必須。
2. 自動生成文書の摩擦: handoff/incident/intake/spec はスキルが日時付きで量産する。各生成で索引更新を強制すると
   記録作成のたびに赤化。ledger-dir 免除設計が要る。
3. 除外・命名規則の設計負担: TEMPLATE.md/INDEX.md 自身、未生成の specs/・incidents/ の扱いなど、
   除外ポリシー表という保守面を新設する(ROOT_ALLOWED 群と同種だが自動生成ディレクトリに触れる分エッジが鋭い)。
4. 形式的1行追加の儀式化: 誤設計すると「チェックを通すためだけの1行」を毎回強いる複雑性コストを生む。
   網羅志向 Reject と同じ罠に自ら落ちうる。

これらは ADR↔INDEX 同期(リスクに触れない決定的突合)とルータ網羅(リスクが集中する設計難所)を分離することで
解けるため、採点を2本に分ける。

## 採点(0〜5、重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

### サブ1: ADR ↔ INDEX.md 同期(check_adr_index_sync)

| 軸 | スコア | 根拠(なぜこの点か) |
|---|---|---|
| E: エビデンス強度 | 4 | 下流で ADR-0016 の INDEX 欠落を実測+索引/リンク検証は docs ツール群で確立した一般実務+親 Adopt 2件と整合。査読/3独立ソースの直接支持ではないため 4 |
| G: 汎用性 | 5 | adr/INDEX は全プロファイル共通のテンプレ基盤 |
| A: エージェント効果 | 5 | エージェントは ADR を INDEX 経由で一覧(README→INDEX→各ADR)。索引完全性=発見経路の完全性。決定的・検証可能 |
| M: 維持コスト(逆) | 5 | NNNN-*.md の突合は完全に静的。除外は INDEX/TEMPLATE の2固定のみ。腐らない |
| C: 複雑性コスト(逆) | 4 | ADR スキルが既に INDEX 追記を手順化 → 新儀式なし。利用者はスキップ時のみ赤 |
| **W: 加重平均** | **4.60** | 拒否権抵触なし → Adopt |

### サブ2: docs/README.md ルータ網羅(check_router_coverage・階層型)

| 軸 | スコア | 根拠(なぜこの点か) |
|---|---|---|
| E: エビデンス強度 | 4 | 同一監査で「現役13文書のルータ未掲載」を実測+宣言を保証するコード不在の穴。ただし「到達」定義と有効設計は未実証 |
| G: 汎用性 | 5 | docs/README ルータは全プロファイル必須(checker が既に存在検証) |
| A: エージェント効果 | 4 | ルータはエージェントの知識索引でコンテキスト経済に寄与。誤設計時の偽陽性がエージェント作業を阻害しうるため 4 |
| M: 維持コスト(逆) | 3 | 到達ポリシー表(ledger-dir 除外/index-managed/enumerated)を docs 構造の進化に合わせ更新する保守面 |
| C: 複雑性コスト(逆) | 3 | 階層設計なら日常摩擦は小。ただしポリシー設計・除外・「なぜ赤か」の説明コストが残る。naive 設計だと veto 域まで落ちる = Trial で設計を実証する理由 |
| **W: 加重平均** | **3.95** | 4.0 直下 → Trial |

## 判定

- サブ1(ADR↔INDEX 同期)= Adopt(W4.60)。決定的・観測済みドリフト・スキルが既に手順化。現リポジトリは
  INDEX が 0001-0007 と実ファイルで両方向一致しており今日から緑で有効化可能。
- サブ2(ルータ網羅)= Trial(W3.95、4.0 直下)。問題は実証済みだが「到達」の有効設計が未実証。Trial 中は
  warn(非ブロッキング、check_structure は warn のみなら return 0)で走らせ、設計を実運用で証明してから
  error 化=Adopt 昇格。
- 拒否権: いずれの軸も ≤1 に該当せず。読み取り専用の静的 checker で攻撃面を広げないためセキュリティ veto も不発。
- ADR 併記: サブ1 を make check の新規ハードゲートとして常時装備する決定は、ADR-0007(tools-lint ゲート追加)の
  先例に倣い ADR-0008 に記録する。サブ2 は Trial 中 warn のため昇格時の ADR 化で足りる。

## 条件(検証仕様と Trial 昇格条件)

到達の定義(階層3ポリシー):

1. INDEX_MANAGED = docs/adr/: `NNNN-*.md` は INDEX.md にファイル名で載ること(error/Adopt)。
   INDEX リンク先の実在は相対リンク実在検証(docs-link-existence-check)が担保(双方向)。
2. LEDGER_DIR = docs/governance/intake/・docs/handoffs/・docs/specs/・docs/incidents/: 個別ファイルの
   ルータ逐語掲載を免除(テーマ粒度・自動生成の日時付き文書)。要件はディレクトリのパスがルータに現れること。
   specs/・incidents/ はスキル初回生成物のためあらかじめ登録し初回赤化を防ぐ。
3. ROUTER_ENUMERATED(その他の既定: conventions/ playbooks/ governance 直下): 各ファイルのパス or
   ファイル名がルータに現れること。「現役文書のルータ未掲載」を捕捉する本体。
   除外: docs/README.md 自身・INDEX.md・TEMPLATE.md(構造ファイル)・_SKIP_DIR_PARTS。

severity: サブ1 = error。サブ2 = Trial 中 warn、昇格時 error。

Trial 昇格条件(TTL 2026-10-18): warn 運用のまま doc 追加サイクルを1周し、ledger-dir 偽陽性ゼロを確認 —
(a) 新規 ADR(INDEX 未追記時のみ警告)/(b) 新規 intake 記録(免除で警告しないこと)/
(c) スキル生成の handoff or incident(免除で警告しないこと)/(d) enumerated への新規文書
(ルート前は警告、追記で解消)。満たしたら error 化して Adopt 再ファイル。TTL までに未達なら Assess へ降格。

現リポジトリでの実測: 上記ポリシーで error/warn ともゼロ通過(全 docs サブディレクトリがルータにルートされ、
adr は INDEX と 0001-0007 で両方向一致)。ナイーブ設計なら偽陽性約15件 → 階層設計の必要性と有効性を同時に裏づけ。

## 根拠ソース

- docs/handoffs/2026-07-14-guard-gaps-from-rutirise-audit.md : G7/B-2 = 本提案の出所・下流ドリフトの実測
- docs/governance/intake/2026-07-09-context-budget-enforcement.md : 親 Adopt(checker 機械強制・3層知識構造)
- docs/conventions/docs-rules.md §2・§3 : ルータ1行追加規約と追記型台帳(リスクの制約源)
- docs/README.md:3 : 「載っていない文書は原則存在しない」宣言(保証対象)
- docs/adr/0007-tools-lint-gate.md : make check への新規ゲート追加を ADR 化した先例
