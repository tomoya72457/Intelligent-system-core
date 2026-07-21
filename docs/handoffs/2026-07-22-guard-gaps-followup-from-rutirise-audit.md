# 引き継ぎ: 追跡監査(2026-07-21 rutirise)由来の新規穴 G11〜G13 と優先度更新

## 1. 目的

`2026-07-14-guard-gaps-from-rutirise-audit.md`(G1〜G10)の追跡。2026-07-21 に下流
rutirise-manager で実施した全体監査(5観点並列+hooks への実入力テスト+gh API 実査)で
見つかった**台帳に無い新規穴 3 件**の登録と、実測により優先度が変わった既存項目の更新。
本ハンドオフは台帳追記であり、採否は 07-14 版と同じく人間レビュー+ADR が前提。

## 2. 新規穴(G11〜G13)

| # | 穴 | 場所(現物) | 事実 |
|---|---|---|---|
| G11 | 定期ワークフローの main 直 push が CI 非経由 | 下流 rutirise の `daily-ops.yml` / `weekly-audit.yml`(テンプレ本体は未同梱だが、CI 設計の盲点はテンプレ側) | GITHUB_TOKEN による push は workflow を再帰起動しない(GitHub 仕様)。contents:write の cron ワークフローが `HEAD:main` へ push すると **make check / gitleaks を一度も通らず正本に着地**する。rutirise で bot コミット複数(437fec2 等)に対応する ci.yml の run が存在しないことを実測。G10(required checks 無し)と重なると完全な無検査経路になる |
| G12 | スキルの intake 迂回を機械検出できない | `tools/check_structure.py`(ADR-0008 の docs 整合検査 3 種の守備範囲外) | rutirise で `publish-wave` スキルが intake 記録・台帳掲載なしで既定入りしていたのを 07-21 監査が検出(遡及起票で是正済み)。防波堤が人間規律のみ |
| G13 | リポジトリ引っ越しの安全手順が無い | `docs/playbooks/`(該当手順書なし) | rutirise で `.git` 丸ごとコピーの引っ越し(iCloud→~/dev)により、**linked worktree 2 つの登録を新旧両リポジトリが同時に主張**する状態が発生(worktree 側 gitdir 逆ポインタは旧側のまま)。旧コピーでセッションが起動し、同名ブランチ上で真の分岐を作りかける事故形 |

## 3. 既存項目の優先度更新(2026-07-21 実測由来)

- **A-8 / A-9 [G8 症状] → 最上位へ**。「週次で試行しうる」から**毎週実際に failure**へ悪化
  (rutirise の schedule 実行が `https://github.com//` not found / exit 128 で失敗継続)。
  さらに実害が拡大: テンプレ側で修正済みの G7(docs 整合検査 3 種 `6816e2c`)と
  G8 根本(bootstrap `01d1557`)が、**配布経路自体の死により下流へ届かない**。
  07-21 の rutirise 文書ドリフト 4 件は、新 check_structure が届いていれば機械検出できた。
- **A-4 [G4] に実証データ**: rutirise の 07-14〜07-21 は 99 コミット・PR 0 件で、
  pr-size は一度も発火せず。コード 400 行超 7 件が全て未警告で通過。
- **A-1〜A-3 [G1-G3] を実入力で再確認**: 3 バイパスとも素通り
  (`python3 -c` の秘密読取 exit 0 / `python3 -c` のガード設定書込 exit 0 /
  `git push -f origin HEAD` の main 非明示 force exit 0)。同時に、守備範囲内は
  現役で遮断する実弾証拠も取得(監査エージェント自身の Bash が rule 9a で遮断された)。
  パターン追加の費用対効果は正と判断できる段階。

## 4. 決定事項

- なし(台帳追記のみ。適用判断は人間+ADR)。

## 5. 未決

- **G11 の手当て形**: (a) 規約化「main へ push する workflow は同一ジョブ内で
  make check を前置」+ zizmor 隣接の自前 lint(`HEAD:main` push の前段に check
  ステップが無ければ CI で警告)/ (b) PAT・GitHub App token で push して CI を
  起動させる / (c) required checks(G10 未決と同一論点)。(a) が 0 円で最小。
- **G12 の手当て形**: check_structure へ「`.claude/skills/` の各スキル(同梱既定を
  除く)に `docs/governance/intake/` の対応記録があること」の突合を追加
  (ADR-0008 の整合検査の第 4 種として自然)。同梱既定リストの定義が必要。
- **G13 の手当て形**: playbook 1 枚(引っ越しは clone または `git worktree repair`・
  `.git` 丸コピー禁止・旧位置に墓標 README を置く)。gitdir 逆ポインタ整合の
  機械検査まで要るかは発生頻度次第。
- 弱い候補: handoff スキルへ「終了時に spec の tasks.md チェックボックスを実態へ
  同期」の 1 行(rutirise で実装済み spec 6 本が全て未チェックのまま腐っていた)。

## 6. 次の一手

1. 人間: **A-9**(rutirise の `TEMPLATE_REPO: "/"` → `tomoya72457/Intelligent-system-core`)
   と **A-8**(guard の不正値 skip 拡張)を最優先適用 → 配布経路復旧 → G7/G8 根本の
   修正が template-sync で下流に流れる。
2. テンプレ側エージェント: G12 の check_structure 拡張は intake から。G13 playbook は
   通常 docs 作業として起票可。
3. 下流 rutirise: 07-21 監査のエージェント可分は同日〜翌日対応済み(docs 台帳同期
   `288b450` / prose_terms 集約 `bb32530` / articles 分割 spec+ADR-0020 `489d2ae` ほか)。
   hooks / CI / ruleset は本台帳の適用待ち。

## 7. 検証コマンド

- G11: rutirise で `gh run list --workflow=ci.yml --branch main` と
  `git log origin/main --format='%h %an %s'` を突合(rutirise-ops コミットに対応する
  push イベントの CI run が無い)。
- G8 実障害: rutirise で `gh run list --workflow=template-sync.yml --limit 3`。
- G13: 旧コピー側で `git worktree list` を実行し、各 worktree ディレクトリの `.git`
  ファイル(gitdir 逆ポインタ)がどちらの `.git` を指すか比較。

## 8. 参照

- 07-14 台帳: `docs/handoffs/2026-07-14-guard-gaps-from-rutirise-audit.md`(G1〜G10・A/B/C 群)
- テンプレ側の適用済み: `6816e2c`(G7 / ADR-0008)・`01d1557`(G8 根本)
- rutirise 側の監査対応コミット: `c826c11` / `288b450` / `489d2ae` / `bb32530`(2026-07-21〜22)
