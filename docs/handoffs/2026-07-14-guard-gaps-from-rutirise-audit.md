<!-- このファイルの目的: rutirise-manager 監査(2026-07-14)で確定したテンプレ由来ガードの穴と修正提案の引き継ぎ。 -->

# 引き継ぎ: ガードの残存穴(rutirise-manager 監査由来)と修正提案

この引き継ぎは作成から**2週間**で陳腐化しうる。以後はコードと最新の台帳を正とする。

## 1. 目的

下流プロジェクト rutirise-manager の全体監査(2026-07-14、make check 実測+5観点並列調査)で見つかったガードの穴が、すべて本テンプレ由来であることを ISC 現物で再現確認した。テンプレ側で塞いで将来の下流全プロジェクトへ波及させる。適用の分担 — 人間(エージェント編集禁止のガード領域)/エージェント(通常領域・intake 経由)— を明確にして引き継ぐ。

## 2. 現状

すべて読み取り調査の事実(本ハンドオフと docs/README.md の 1 行以外、ISC は未変更。main は origin と同期・クリーン)。

| # | 穴 | 場所(ISC 現物) | 事実 |
|---|---|---|---|
| G1 | force push 検知が AND 条件 | `.claude/hooks/block-dangerous.sh:66-73` | force フラグ AND 文字列に main/master。`git push -f`(refspec 無し)と `git push origin +main`(+refspec 形式)が素通し |
| G2 | 保護パス書込検知の経路不足 | 同 `:154-166` | リダイレクト/tee・cp・mv・install・rsync/sed -i のみ。python -c / dd / truncate / ln -sf は検知外 |
| G3 | 秘密読取検知が固定ホワイトリスト | `.claude/hooks/block-secret-read.sh:66` | cat/grep/awk 等のみ。python3 -c / node -e 等インタプリタ経由の読取が検知外 |
| G4 | ±400 警告が PR 限定 | `.github/workflows/ci.yml:101-103` | `if: github.event_name == 'pull_request'`。直接 push 既定(ADR-0006)では一度も発火しない |
| G5 | gitleaks 未導入時は無言スキップ | `tools/githooks/pre-commit:21-25` | `command -v` で括られ警告なし。ローカル秘密検出が黙って無効化(CI が事後バックストップ) |
| G6 | pre-push フック無し | `tools/githooks/` | 「make check 緑でのみ push」のローカル機械強制は無い |
| G7 | check_structure の未検証領域 | `tools/check_structure.py:149,201-211` | ADR INDEX 同期・docs/README ルータ網羅のチェック無し。下流で実際にドリフト発生(ADR-0016 の INDEX 欠落・現役文書 13 本のルータ未掲載) |
| G8 | template-sync 残滓 `TEMPLATE_REPO: "/"` | `tools/bootstrap.sh:328-339`(根本)/ 下流 workflow:24(症状) | 根本原因は §3。下流では週次で `source_repo_path: "/"` の同期を試行しうる(動作不全・セキュリティ問題ではない) |
| G9 | ruleset の admin 常時バイパス | `.github/rulesets/main.json` | bypass_actors: RepositoryRole=admin / bypass_mode: always。オーナー権限で動くエージェントにはサーバ側 non_fast_forward が効かず、G1 のローカルフックが実質唯一の force push ガード |
| G10 | ci.yml コメントと ruleset の齟齬 | `ci.yml:2,126` vs `.github/rulesets/main.json` | コメントは required_status_checks が集約ジョブ "ci" を参照する前提だが、実 ruleset に required_status_checks は無い。「緑で push」はサーバ側未強制 |

下流 rutirise-manager は同日、エージェント領域分のみ対応済み(docs 台帳同期 `df37df5` / AST 循環テスト+ADR-0017 `a3e96e6` / `_require_str` 集約 `9b8bcd0`)。hooks / CI / ruleset は本提案の適用待ち。

## 3. 決定事項

- **G8 の根本原因は bootstrap.sh:335 の検証グロブに確定**(実測済み): 対象リポが GitHub 上のテンプレ親を持たないと `gh repo view --json templateRepository` が null を返し、jq 式 `.templateRepository.owner.login + "/" + .templateRepository.name` が文字列 `/` に潰れる(jq は null を `+` の単位元として扱う)。検証 `case "$src_repo" in */*)` は `/` を受理してしまうため既定値フォールバックが発火せず、`/` が workflow に一括置換で書き込まれた(下流 3 行目コメントの `/` 残滓が証跡)。
- **services 内のモジュールレベル循環検知は import-linter 契約ではなく AST テストで行う**(rutirise ADR-0017): grimp は関数内遅延 import とモジュールレベル import を区別できず、管理された遅延 import が偽陽性になるため。テンプレ標準搭載の採否は未決(B-3)。
- 本ハンドオフは提案の束であり、ISC 側の採否はまだ決定していない(適用は人間レビュー+ADR が前提)。

## 4. 未決

- required_status_checks を ruleset に足すか — 直接 push 運用(ADR-0006)と両立しない。G10 は「コメント修正」で解くか「required 化(=運用変更)」で解くかの決定待ち。
- G9 admin バイパスを外すか — 外しても通常 push は通る(non_fast_forward は force のみ拒否)。意図的な force push 時に ruleset 一時無効化が要る程度の摩擦。
- hooks 強化(A-1〜A-3)の適用範囲 — パターン追加は誤検知面も広げる(下流で `rm -f ... && git push` の force 誤検知実績あり)。静的検査の網羅は原理的に不可能で、目的は既知経路の封鎖。
- B-2 / B-3 の採否(intake 未実施)。
- A-6(gitleaks 未導入警告)/ A-7(pre-push make check、push 毎+十数秒)の採否。

## 5. 次の一手

**最初にやること**: 人間が A 群を 1 件ずつレビュー → 採用分を手動適用(1 論理変更=1 コミット)→ ADR に記録(次番号は 0008〜)。その後 B-1 をエージェントへ指示(即適用可)、B-2/B-3 は intake から。

### A 群 — 人間適用(エージェント編集禁止領域)

- **A-1 [G1]** `block-dangerous.sh:68-69`: force 検出(L68)へ `+refspec` 形式(`[[:space:]]\+[^[:space:]]`)を追加し、対象判定(L69)を「main/master 明示 **or** refspec 無し(現在ブランチ push)」へ拡張。直接 push 既定では refspec 無し force ≒ main への force のため。
- **A-2 [G2]** `block-dangerous.sh:154-166`: 9b のコマンド群へ `|dd|truncate|ln` を追加。9d として「`python3? -c` / `node -e` と PROTECTED_RE の共起」を追加。
- **A-3 [G3]** `block-secret-read.sh:66`: ホワイトリストへ `|python|python3|node|ruby|perl|deno|bun|php` を追加(インタプリタはコマンド行に秘密パスが共起した時点で遮断)。
- **A-4 [G4]** `ci.yml:101-127`: pr-size の `if:` を外し、push 時は `github.event.before...github.sha` で差分行数を算出(初回 push / force 後の `before=0000...` はスキップ分岐)。集約 `ci` には含めない(advisory 維持、L127 の設計どおり)。
- **A-5 [G9/G10]** `.github/rulesets/main.json`: bypass_actors を削除 or `bypass_mode: "pull_request"` へ。required_status_checks は §4 決定後。ファイル編集自体は通常領域だが、サーバ適用(`gh api` での ruleset 更新)と方針決定は人間。適用済みの下流(rutirise 等)は各リポで再適用が必要。
- **A-6 [G5]** `tools/githooks/pre-commit:21-25`: `command -v gitleaks` の else へ注意表示 1 行(例: `echo "[pre-commit] gitleaks 未導入のためローカル秘密スキャンはスキップ(CI が事後検出)" >&2`)。exit 0 は維持。
- **A-7 [G6]**(採用時)`tools/githooks/pre-push` を新設し `make check` 赤で push 中止。
- **A-8 [G8 症状側]** `template-sync.yml:39-46` の guard 拡張(下流 rutirise の同ファイルにも同修正):

  変更前:
  ```bash
  case "$TEMPLATE_REPO" in
    *"{{"*)
      echo "生成元テンプレート未設定のためスキップします(bootstrap.sh 未実行)。"
      echo "run=false" >> "$GITHUB_OUTPUT"
      exit 0
      ;;
  esac
  ```
  変更後:
  ```bash
  case "$TEMPLATE_REPO" in
    *"{{"* | "" | /* | */)
      echo "生成元テンプレート未設定/不正('$TEMPLATE_REPO')のためスキップします。"
      echo "run=false" >> "$GITHUB_OUTPUT"
      exit 0
      ;;
  esac
  ```
- **A-9 [G8 下流の値]** rutirise-manager の `.github/workflows/template-sync.yml:24`: `TEMPLATE_REPO: "/"` → `"tomoya72457/Intelligent-system-core"`(3 行目コメントの `/` 残滓も文言復元)。

### B 群 — エージェント適用可(通常領域)

- **B-1 [G8 根本]** `bootstrap.sh:335` の slug 検証強化(最小 diff・即適用可):
  変更前: `case "$src_repo" in */*) : ;; *) src_repo="$TEMPLATE_REPO_DEFAULT" ;; esac`
  変更後: `case "$src_repo" in ?*/?*) : ;; *) src_repo="$TEMPLATE_REPO_DEFAULT" ;; esac`
  (`?*` = 1 文字以上。`/`・`owner/`・`/repo`・空は既定値へフォールバックし、正当な `owner/repo` のみ通過)
- **B-2 [G7]**(intake 経由)`check_structure.py` へ `check_adr_index_sync`(docs/adr/*.md ↔ INDEX.md 突合)と `check_router_coverage`(docs/**/*.md が docs/README.md に掲載)を追加。挿入点は `check_repo()`(L201-211)、テストは `tools/test_check_structure.py`。
- **B-3 [ADR-0017 移植]**(intake 経由)python プロファイルへ AST 循環テスト雛形を追加(rutirise の `tests/test_architecture.py`: モジュールレベル import 非循環+既知辺の positive assertion)。

### C 群 — 環境(リポ外・0 円)

- **C-1** 開発機へ gitleaks 導入: `brew install gitleaks`(pre-commit が自動で拾う設計済み。2026-07-14 時点で未導入を実測)。

## 6. 検証コマンド

- `make check`(プロファイル未導入でも structure + tools-lint が走る)
- hooks 変更後: `bash -n .claude/hooks/block-dangerous.sh .claude/hooks/block-secret-read.sh`
- A-8 guard 単体: `TEMPLATE_REPO="/" sh -c 'case "$TEMPLATE_REPO" in *"{{"*|""|/*|*/) echo skip;; *) echo run;; esac'` → `skip`(`owner/repo` では `run`)
- ruleset 適用確認: `gh api "repos/{owner}/{repo}/rulesets"`
- hooks の期待挙動表(実行方法は各フック冒頭の stdin パース実装に合わせる): 遮断すべき=`git push -f` / `git push origin +main` / `python3 -c "open('.env').read()"` / `truncate -s0 .claude/settings.json`。通過すべき=`git push origin main` / `rm -f tmp.txt`(単独)/ `cat .env.example`。誤検知回帰=`rm -f x && git push origin main` が force 誤検知されないこと(下流で誤検知の実績があるパターン)。

## 7. 参照

- rutirise-manager: 対応コミット `df37df5`(docs 台帳同期)・`a3e96e6`(AST 循環テスト)・`9b8bcd0`(`_require_str` 集約)、`docs/adr/0017-services-module-level-acyclicity-test.md`、`.github/workflows/template-sync.yml:24`(残滓現物)
- ISC 現物: `.claude/hooks/block-dangerous.sh:66-73,154-166` / `.claude/hooks/block-secret-read.sh:66` / `.github/workflows/ci.yml:101-131` / `.github/rulesets/main.json` / `tools/githooks/pre-commit:21-25` / `tools/check_structure.py:149,201-211` / `tools/bootstrap.sh:328-339` / `docs/adr/0006-direct-push-workflow.md`
- jq 潰れの再現: `printf '{"templateRepository": null}' | jq -r '.templateRepository.owner.login + "/" + .templateRepository.name'` → `/`(exit 0)
