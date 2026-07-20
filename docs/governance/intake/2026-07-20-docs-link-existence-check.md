# intake 判定記録: Markdown 相対リンクの実在検証を構造チェックへ追加

- **提案日**: 2026-07-20
- **slug**: docs-link-existence-check
- **判定**: Adopt(W 4.20)
- **再審査日**: 2027-07-20

## 提案

tools/check_structure.py に「Markdown 相対リンク(`[text](path)`)の実在検証」を1関数として追加し、
check_repo に登録して既定ゲート(make structure → make check / pre-commit / CI)に含める。
docs-rules.md §4「文書内パス参照は実在を指す」規約に対応する機械強制が現状 no-op(STALE_PATTERNS=[])
である欠落を埋める。既定変更(新規約の機械強制化)であり日常の実装判断ではない。

## 適用可能性ゲート

制約なし。標準ライブラリのみで実装でき、外部サービス・アカウント機能に依存しない。通過。

## 可逆性(two-way door)

可逆。変更は check_structure.py(関数追加+check_repo 登録1行)と test_check_structure.py の2ファイルのみ。
撤去は関数・登録行の削除。外部依存・設定・hooks・CI・データ・履歴に波及しない。

## 賛成論(3点以上)

1. 規約-強制ギャップの実測解消: docs-rules.md §4 は規約化済みだが、関連コード check_stale_refs は
   STALE_PATTERNS=[] で no-op(check_structure.py:67/171-172 実測)、CI にもリンクチェッカ不在(ci.yml 実測)。
   docs-rules.md:3 が自らを「機械強制の『なぜ』」と定義する以上、強制欠落は設計上の穴。AGENTS.md
   「ミスは2回目で規約化…機械強制」「フェイルファスト」に直結。
2. エージェント・ナビゲーションの信頼性: docs-rules.md:28「エージェントは文書内のパスをそのまま辿る。
   壊れた参照は人間より高い確率で誤動作(存在しないファイルの新規作成等)」。内部パス解決のみ=ネットワーク
   非依存でゲートは hermetic(決定性を損なわない)。
3. エコシステム収斂+ゼロ配線・ゼロ依存: docs リンク検査は lychee/markdown-link-check/linkcheckmd/
   mkdocs strict/Sphinx linkcheck と独立5+ツールで収斂。本提案は外部依存を持ち込まず stdlib で最小自作し、
   既存配線(Makefile:48,25 / pre-commit:16 / ci.yml:57)にそのまま乗る。
4. 今日グリーンの実証: リポ内 markdown リンク約23件はすべて実在に解決(profiles/README.md の
   ./{typescript,python,docs}/PROFILE.md、README/coding/architecture/INDEX の相対リンク、LICENSE・
   .claude/hooks/auto-format.sh・.claude/agents/reviewer.md・ADR 0001-0007 まで全確認)。外部URL・アンカー・
   プレースホルダの markdown リンクは現時点0件。error 即導入でも既存を赤にしない。

## 反対論(3点以上)

1. 誤検知設計が正しさの前提: アンカー・外部URL/mailto・コードフェンス内パス風文字列・プレースホルダ・
   path#fragment・画像リンクの分岐を誤ると、将来 docs に最初の外部リンク/アンカーが入った瞬間に make check
   が赤化し、docs 無関係の作業まで止める。docs プロファイルでは外部リンク・アンカーが常態。
2. テンプレ特有の post-bootstrap パス問題: profiles/ 配下文書は bootstrap 展開後にのみ現れるパスへ言及しうる。
   現状は実在に解決し無害だが、将来 markdown リンク構文で post-bootstrap パスを指すと偽陽性。走査範囲を明示決定。
3. error 即導入と比例原則の緊張: 壊れたリンク1件は秘密漏洩や AGENTS.md 欠落より低重大度。pre-commit は毎コミット
   whole-repo を検査(staged-diff 非対応)するため、無関係ファイルのリンク誤字がコミット全体をブロックしうる。
4. check_stale_refs との役割重複: 新チェック(存在検証)は既存 check_stale_refs(旧パス blocklist=空)の
   「存在するか」用途をほぼ上位互換で置換。放置すると死んだ no-op と類似機能が併存し認知負荷。

## 採点(0〜5、重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠(なぜこの点か) |
|---|---|---|
| E: エビデンス強度 | 4 | docs リンク検査は独立5+ツールで収斂+リポ内 no-op・CI 不在は実測。ただし agent 誤動作の機序は推論(査読・計測なし)、本体は最小自作の再実装のため 5 は付けず 4 |
| G: 汎用性 | 5 | プレーンMarkdown・言語非依存で3プロファイル全てに効き docs に特に恩恵。リンク無いリポではゼロコスト |
| A: エージェント効果 | 4 | 文書横断ナビゲーションの検証可能性・決定性(内部解決=hermetic)・コンテキスト経済に直接寄与。基盤級でなく増分ガードのため 4 |
| M: 維持コスト(逆) | 4 | FS から真偽を導く自己維持型で check_stale_refs より腐りにくい。除外ロジック維持の小コストで 4 |
| C: 複雑性コスト(逆) | 4 | 既存 make の内側で無自覚に恩恵・新コマンド/依存なし。誤爆時に全ゲートを止める摩擦と error/warn 設計判断が残るため 4 |
| **W: 加重平均** | **4.20** | 0.30·4+0.20·5+0.25·4+0.15·4+0.10·4 = 4.20 |

## 判定

Adopt。W4.20 が閾値4.0を上回る。全軸4点で拒否権(≤1)抵触なし。セキュリティは read-only 静的解析・stdlib・
ネットワーク不使用・新規外部コマンドなしで攻撃面を広げず、むしろ壊れた参照由来の誤動作を減らすため Reject veto 非該当。
保守的採点(G を4へ落としても W=4.00)でも Adopt 域に留まり knife-edge でない。

## 条件(導入の HOW)

- Severity は error(今日グリーン+fail-fast 家風+局所自明な修正)。厳格な前提として、同一変更で除外規則
  (スキーム http/https/mailto/tel/ftp・`//` 始まり・純アンカー `#`・プレースホルダ `{{`・フェンス/インラインコード、
  `#fragment` 除去、画像リンクも解決)を実装し、test_check_structure.py に検出/非検出の fault-injection テストを同梱。
  この前提を同一変更で満たせない場合に限り warn で暫定導入し、除外+テスト完了後に error 昇格。
- 走査範囲は現行 rglob("*.md")+_in_ignored_dir を踏襲、各 .md の親基準で相対解決。profiles/ の post-bootstrap パスは
  インラインコード化 or 個別 skip で偽陽性予防。
- check_stale_refs は限定用途(改名後の旧パス逆戻り検出)で存置。新チェックが存在検証を主担当する旨を
  docs-rules.md §4 に反映(規約と実装の同期)。
- Adopt の12ヶ月再審査 = 2027-07-20。

## 根拠ソース

- tools/check_structure.py:67,167-185 : STALE_PATTERNS=[] による check_stale_refs の no-op(実測)
- .github/workflows/ci.yml : リンクチェッカ不在(実測)
- Makefile:48,25 / tools/githooks/pre-commit:16 : make structure が make check/pre-commit/CI から呼ばれる既存配線(実測)
- docs/conventions/docs-rules.md:3,25-28 : 「文書内パス参照は実在を指す」規約と、チェッカを機械強制の正本と定義
- docs/governance/intake/2026-07-09-agents-md-canonical.md : 自動生成コンテキストに依存しない方針(本提案の設計整合)
- https://github.com/lycheeverse/lychee : 高速リンクチェッカ(エコシステム収斂)
- https://github.com/tcort/markdown-link-check : markdown 用リンクチェッカ(同)
- https://www.mkdocs.org/ : MkDocs は内部リンクを既定検証、strict でビルド失敗化(内部リンク検査の収斂例)
