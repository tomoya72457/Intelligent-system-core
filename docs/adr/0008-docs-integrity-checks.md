# ADR-0008: docs 整合検査(リンク実在・ADR↔INDEX・ルータ網羅)を構造ゲートへ追加

- **日付**: 2026-07-20
- **状態**: 承認

## 文脈

docs-rules.md は「パス参照は実在ファイルを指す」(§4)「新規文書はルータに1行追加」(§2)を規約として
定めるが、強制コードが無かった(check_stale_refs は STALE_PATTERNS=[] で実質 no-op、CI にもリンク
チェッカ無し)。下流リポジトリの監査(2026-07-14 handoff の G7)では ADR の INDEX 欠落・現役文書の
ルータ未掲載というドリフトが実測されており、「規約はあるが強制が無い」穴が実害として確認済み。
外部ドキュメント(Obsidian 型 docs ワークフロー)の検討では frontmatter `depends_on` や依存図の
CI 自動生成が代替候補に挙がったが、本リポジトリの方針(コンテキストファイル自動生成に依存しない・
追記型台帳・段階開示ルータ)とは衝突するため、既存規約の機械強制で同じ狙いを達成する。
採否は intake 判定(docs-link-existence-check / docs-router-index-coverage)を経ている。

## 決定

`tools/check_structure.py` に docs 整合検査 3 つを追加し、既定ゲート(`make structure` →
`make check`・pre-commit・CI)に含める。ADR-0007(tools-lint ゲート)に続くゲート意味論の拡張。

1. `check_md_links`(error): 全 *.md の Markdown 相対リンクの実在検証。外部 URL・アンカー・
   プレースホルダ・コードブロック内は除外、#fragment は除去、絶対パスは不可。
2. `check_adr_index_sync`(error): `docs/adr/NNNN-*.md` が INDEX.md に載っていること。
   逆方向(INDEX リンク先の実在)は 1 が担保。
3. `check_router_coverage`(warn・Trial): docs/ 文書のルータ到達可能性。階層ポリシー
   (ADR=INDEX 管理 / 台帳ディレクトリ=ディレクトリ行で免除 / その他=パス掲載必須)。
   TTL 2026-10-18 で偽陽性ゼロを実証後に error 昇格を判断。

## 検討した代替案(必須)

- **案A: 外部リンクチェッカ(lychee / markdown-link-check)導入** — 機能は上位だが外部依存・
  版管理・CI 配線が増える。必要な検証は stdlib 数十行で足り、既存の番人に乗る方が維持コストが低い。
- **案B: frontmatter `depends_on` で依存をメタデータ化** — 強制手段のないメタデータは陳腐化する。
  ルータ+実在検証の方が「AI が関連文書を辿れる」という同じ目的を、追加記述ゼロで満たす。
- **案C: バッククォート内パスも検証対象にする** — dry-run で 304 候補中 34 件の偽陽性
  (file:line 表記・別リポジトリ参照・bootstrap 後パス・owner/repo スラッグ)。除外設計が
  複雑化するため対象外とし、散文パスは §4 の運用規約に留める。
- **案D: 現状維持(散文規約のみ)** — 下流で実害(INDEX 欠落・ルータ未掲載)が実測済み。
  「ミスは2回目で規約化・機械強制」の原則に反する。

## 結果

- 文書層の整合(リンク・索引・ルータ)がコードと同様に機械検証され、リンク切れ・索引漏れは
  コミット時点で止まる。変更は tools/check_structure.py と同テストのみ(ガード境界に非接触)。
- 受け入れたトレードオフ: バッククォート散文パスは非検証(偽陽性回避を優先)。ルータ網羅の
  到達ポリシー表(DOCS_LEDGER_DIRS 等)という小さな保守面が増える。

## Confirmation(実装後に追記)

- 2026-07-20 実装。`python3 tools/test_check_structure.py` 34 件成功(fault-injection:
  リンク切れ検出/除外規則/索引漏れ検出/台帳免除/warn 非ブロッキングを含む)。
- 実リポジトリで `make check` 緑(check_structure OK・error/warn ゼロ・ruff 通過)。
  導入前 dry-run で全 23 リンク実在・ADR 0001-0007 と INDEX の両方向一致を確認済み。

## 信頼度と再検討トリガー

- **信頼度**: 高(1・2)/ 中(3 は到達定義の実運用実証が未了のため Trial)
- **再検討トリガー**: check_router_coverage は TTL 2026-10-18 までに doc 追加サイクルで
  ledger-dir 偽陽性ゼロを確認したら error 昇格(Adopt 再ファイル)、未達なら Assess へ降格。
  リンク検証で偽陽性が 2 回観測されたら除外規則を規約化して追記する。
