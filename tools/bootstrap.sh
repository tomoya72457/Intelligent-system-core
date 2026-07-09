#!/usr/bin/env bash
# このスクリプトはテンプレートから作った新規リポジトリの初期設定を一括で行う:
# プレースホルダ置換 → プロファイル展開 → GitHub 設定(ruleset/マージ/Actions/ラベル)→ githooks。
# 冪等(再実行安全)。--dry-run で変更なしに計画のみ表示。使い方: ./tools/bootstrap.sh --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_REPO_DEFAULT="tomoya72457/Intelligent-system-core"

DRY_RUN=0; NON_INTERACTIVE=0
PROJECT_NAME=""; PROJECT_PURPOSE=""; PROFILE=""
DOCTOR_ROWS=""   # "項目|結果|補足" を改行区切りで蓄積(bash3.2 でも安全な文字列方式)

usage() {
  cat <<'USAGE'
使い方: tools/bootstrap.sh [オプション]
  --name <名前>       プロジェクト名({{PROJECT_NAME}} を置換)
  --purpose <目的>    プロジェクト目的({{PROJECT_PURPOSE}} を置換)
  --profile <名前>    展開するプロファイル(profiles/ 配下: typescript / python / docs)
  --non-interactive   対話しない(CI 用。必要な値は引数で渡す)
  --dry-run           変更を加えず計画のみ表示(gh 認証も不要)
  --help              このヘルプ
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)     PROJECT_NAME="${2:?--name に値が必要}"; shift 2 ;;
    --purpose)  PROJECT_PURPOSE="${2:?--purpose に値が必要}"; shift 2 ;;
    --profile)  PROFILE="${2:?--profile に値が必要}"; shift 2 ;;
    --non-interactive) NON_INTERACTIVE=1; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --help|-h)  usage; exit 0 ;;
    *) echo "ERROR: 不明なオプション: $1" >&2; usage >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }
doctor_add() { DOCTOR_ROWS="${DOCTOR_ROWS}$1|$2|$3"$'\n'; }
# 変更を伴うコマンドの実行ラッパ。dry-run では表示のみ。
run() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] $*"; return 0; fi
  "$@"
}

# ---------- (0) 前提確認 ----------
cd "$REPO_ROOT"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "git リポジトリ内で実行してください。"
command -v python3 >/dev/null 2>&1 || die "python3 が必要です(置換・マニフェスト解析に使用)。"

GH_READY=0; REPO_SLUG=""
if [ "$DRY_RUN" -eq 1 ]; then
  REPO_SLUG="{owner}/{repo}"   # dry-run では表示専用(API は呼ばない)
  log "dry-run: gh 認証チェックと GitHub API 呼び出しはスキップします。"
elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_READY=1
  REPO_SLUG="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
  [ -n "$REPO_SLUG" ] || { GH_READY=0; warn "gh からリポジトリを特定できません(remote 未設定?)。GitHub 設定はスキップします。"; }
else
  warn "gh が無い/未認証のため GitHub 設定(ruleset/マージ/Actions/ラベル)はスキップします。gh auth login 後に再実行で適用できます。"
fi

# ---------- (1) 対話(不足値のみ聞く) ----------
has_placeholder() { grep -rIl --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=scratch --exclude=bootstrap.sh -e "$1" . >/dev/null 2>&1; }
prompt_value() { # $1=変数名 $2=プロンプト
  local v=""
  while [ -z "$v" ]; do
    printf '%s: ' "$2"
    read -r v || die "入力を読めません(非対話環境では --non-interactive と引数を使ってください)。"
  done
  eval "$1=\$v"
}
list_profiles() { # profiles/ 配下で PROFILE.md を持つディレクトリ名を列挙
  [ -d profiles ] || return 0
  local d; for d in profiles/*/; do [ -f "${d}PROFILE.md" ] && basename "$d"; done
}

if has_placeholder '{{PROJECT_NAME}}' && [ -z "$PROJECT_NAME" ]; then
  if [ "$NON_INTERACTIVE" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    [ "$DRY_RUN" -eq 1 ] || die "--non-interactive では --name が必要です。"
  else prompt_value PROJECT_NAME "プロジェクト名"; fi
fi
if has_placeholder '{{PROJECT_PURPOSE}}' && [ -z "$PROJECT_PURPOSE" ]; then
  if [ "$NON_INTERACTIVE" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    [ "$DRY_RUN" -eq 1 ] || die "--non-interactive では --purpose が必要です。"
  else prompt_value PROJECT_PURPOSE "プロジェクトの目的(1行)"; fi
fi
if [ -d profiles ] && [ -z "$PROFILE" ]; then
  AVAILABLE="$(list_profiles | tr '\n' ' ')"
  if [ "$NON_INTERACTIVE" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    [ "$DRY_RUN" -eq 1 ] || die "--non-interactive では --profile が必要です(候補: ${AVAILABLE})。"
  else
    echo "利用可能なプロファイル: ${AVAILABLE}"
    prompt_value PROFILE "プロファイル名"
  fi
fi
if [ -n "$PROFILE" ] && [ -d profiles ] && [ ! -f "profiles/${PROFILE}/PROFILE.md" ]; then
  die "プロファイル '${PROFILE}' が見つかりません(候補: $(list_profiles | tr '\n' ' '))。"
fi

# パッケージ名スラッグ({{PROJECT_SLUG}}): uv / npm が受理する形へ正規化する。
# 表示名 {{PROJECT_NAME}} は自由(日本語・空白可)、パッケージ名は機械可読、と二役を分離する。
slugify() {
  printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sed -E 's/[^a-z0-9._-]+/-/g; s/^[^a-z0-9]+//; s/[-._]+$//'
}
PROJECT_SLUG="$(slugify "${PROJECT_NAME:-}")"
[ -z "$PROJECT_SLUG" ] && PROJECT_SLUG="$(slugify "$(basename "$PWD")")"
[ -z "$PROJECT_SLUG" ] && PROJECT_SLUG="my-app"

# ---------- (2) プレースホルダ置換 ----------
replace_placeholder() { # $1=プレースホルダ $2=値 → 置換ファイル数を出力
  PH="$1" VAL="$2" python3 - <<'PY'
import os, pathlib
ph, val = os.environ["PH"], os.environ["VAL"]
skip_dirs = {".git", "node_modules", ".venv", "venv", "__pycache__", "scratch"}
changed = 0
for p in pathlib.Path(".").rglob("*"):
    if not p.is_file() or set(p.parts) & skip_dirs or str(p) == "tools/bootstrap.sh":
        continue
    try:
        text = p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    if ph in text:
        p.write_text(text.replace(ph, val), encoding="utf-8")
        changed += 1
print(changed)
PY
}
step_placeholders() {
  if ! has_placeholder '{{PROJECT_NAME}}' && ! has_placeholder '{{PROJECT_PURPOSE}}' && ! has_placeholder '{{PROJECT_SLUG}}'; then
    doctor_add "プレースホルダ置換" "SKIP" "置換対象なし(適用済み)"; return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] {{PROJECT_NAME}} → '${PROJECT_NAME:-<対話で入力>}' / {{PROJECT_PURPOSE}} → '${PROJECT_PURPOSE:-<対話で入力>}' / {{PROJECT_SLUG}} → '${PROJECT_SLUG}' に置換"
    doctor_add "プレースホルダ置換" "SKIP" "dry-run"; return 0
  fi
  local n1 n2 n3
  n1="$(replace_placeholder '{{PROJECT_NAME}}' "$PROJECT_NAME")"
  n2="$(replace_placeholder '{{PROJECT_PURPOSE}}' "$PROJECT_PURPOSE")"
  n3="$(replace_placeholder '{{PROJECT_SLUG}}' "$PROJECT_SLUG")"
  if [ "$PROJECT_SLUG" != "$PROJECT_NAME" ] && [ "$n3" != "0" ]; then
    echo "  パッケージ名には '${PROJECT_SLUG}' を使用します(表示名 '${PROJECT_NAME}' から自動導出。uv/npm の名前制約対応)"
  fi
  doctor_add "プレースホルダ置換" "OK" "NAME:${n1} PURPOSE:${n2} SLUG:${n3}ファイル"
}
log "(2) プレースホルダ置換"; step_placeholders

# ---------- (3) プロファイル展開 ----------
# 契約(profiles/README.md): PROFILE.md の「## manifest」節にあるコードフェンス1個の中身のみを
# 「dest_path: source_path」(1行1ファイル)としてパースする。フェンス外の散文は無視。
parse_manifest() { # $1=PROFILE.md → "dest<TAB>source" 行を出力
  MF="$1" python3 - <<'PY'
import os, re, sys
lines = open(os.environ["MF"], encoding="utf-8").read().splitlines()
in_sec = in_fence = closed = False
for line in lines:
    s = line.strip()
    if not in_sec:
        if re.match(r"^##\s+manifest\s*$", s, re.IGNORECASE):
            in_sec = True
        continue
    if in_fence:
        if s.startswith("```"):
            closed = True
            break
        if not s or s.startswith("#"):   # 空行とコメントは無視してよい(契約)
            continue
        m = re.match(r"^(\S+)\s*:\s*(\S+)$", s)
        if not m:
            print("MANIFEST-ERROR: 解釈できない行: %r" % s, file=sys.stderr)
            sys.exit(1)
        print("%s\t%s" % (m.group(1), m.group(2)))
        continue
    if re.match(r"^##\s", line):         # フェンスが現れる前に次の節が来た
        break
    if s.startswith("```"):
        in_fence = True
if not (in_sec and closed):
    print("MANIFEST-ERROR: '## manifest' 節に閉じたコードフェンスが見つかりません", file=sys.stderr)
    sys.exit(1)
PY
}
step_profile() {
  if [ ! -d profiles ]; then doctor_add "プロファイル展開" "SKIP" "profiles/ なし(展開済み)"; return 0; fi
  if [ -z "$PROFILE" ]; then doctor_add "プロファイル展開" "SKIP" "dry-run(--profile 未指定)"; return 0; fi
  local src_root="profiles/${PROFILE}" manifest placed=0 skipped=0 dest src
  manifest="$(parse_manifest "${src_root}/PROFILE.md")"   # 解析失敗は set -e で即停止
  while IFS="$(printf '\t')" read -r dest src; do
    [ -n "$dest" ] || continue
    if [ ! -f "${src_root}/${src}" ]; then die "マニフェスト参照切れ: ${src_root}/${src}"; fi
    if [ -e "$dest" ]; then
      warn "既存のためスキップ: ${dest}"; skipped=$((skipped + 1)); continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] 配置: ${src_root}/${src} → ${dest}"
    else mkdir -p "$(dirname "$dest")"; cp "${src_root}/${src}" "$dest"; fi
    placed=$((placed + 1))
  done <<EOF
${manifest}
EOF
  run rm -rf profiles
  if [ "$DRY_RUN" -eq 1 ]; then doctor_add "プロファイル展開" "SKIP" "dry-run(${PROFILE}: ${placed}ファイル予定)"
  else doctor_add "プロファイル展開" "OK" "${PROFILE}: 配置${placed} スキップ${skipped}・profiles/ 削除"; fi
}
log "(3) プロファイル展開"; step_profile

# ---------- (3b) Dependabot にプロファイルのエコシステムを追記 ----------
# テンプレートの dependabot.yml は github-actions のみ(マニフェスト不在の npm/pip 設定は
# Dependabot 実行が failure になるため——2026-07-09 実測)。展開後はルートにマニフェストが
# 置かれるので、ここで該当エコシステムのブロックを追記する(冪等)。
append_dependabot_ecosystem() { # $1=ecosystem名
  local f=".github/dependabot.yml"
  [ -f "$f" ] || { doctor_add "Dependabot 追記" "SKIP" "${f} なし"; return 0; }
  if grep -q "package-ecosystem: \"$1\"" "$f"; then
    doctor_add "Dependabot 追記" "SKIP" "$1 は設定済み"; return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] ${f} に ${1} ブロックを追記"
    doctor_add "Dependabot 追記" "SKIP" "dry-run"; return 0
  fi
  cat >> "$f" <<DEPEOF

  - package-ecosystem: "$1"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    cooldown:
      default-days: 7
    open-pull-requests-limit: 5
    groups:
      $1-minor-patch:
        applies-to: version-updates
        update-types: ["minor", "patch"]
        patterns: ["*"]
DEPEOF
  doctor_add "Dependabot 追記" "OK" "$1 を監視対象に追加"
}
step_dependabot() {
  case "${PROFILE:-}" in
    typescript) append_dependabot_ecosystem "npm" ;;
    python)     append_dependabot_ecosystem "pip" ;;
    "")         doctor_add "Dependabot 追記" "SKIP" "プロファイル未指定" ;;
    *)          doctor_add "Dependabot 追記" "SKIP" "${PROFILE} は追加エコシステムなし" ;;
  esac
}
log "(3b) Dependabot エコシステム追記"; step_dependabot

# ---------- (4)-(7) GitHub 設定(gh 必要。失敗は警告して続行) ----------
gh_step() { # $1=doctor項目名 $2=失敗時補足 以降=コマンド
  local label="$1" hint="$2"; shift 2
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] $*"; doctor_add "$label" "SKIP" "dry-run"; return 0; fi
  if [ "$GH_READY" -ne 1 ]; then doctor_add "$label" "SKIP" "gh 未認証"; return 0; fi
  if "$@" >/dev/null 2>&1; then doctor_add "$label" "OK" ""
  else warn "${label} に失敗(続行): ${hint}"; doctor_add "$label" "FAIL" "$hint"; fi
}

step_ruleset() {
  local file=".github/rulesets/main.json" name=""
  if [ ! -f "$file" ]; then doctor_add "ruleset 適用" "SKIP" "${file} なし"; return 0; fi
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] gh api POST /repos/{slug}/rulesets --input ${file}"; doctor_add "ruleset 適用" "SKIP" "dry-run"; return 0; fi
  if [ "$GH_READY" -ne 1 ]; then doctor_add "ruleset 適用" "SKIP" "gh 未認証"; return 0; fi
  name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("name",""))' "$file")"
  if gh api "repos/${REPO_SLUG}/rulesets" -q '.[].name' 2>/dev/null | grep -qxF "$name"; then
    doctor_add "ruleset 適用" "SKIP" "同名 ruleset '${name}' が適用済み"; return 0
  fi
  if gh api --method POST "repos/${REPO_SLUG}/rulesets" --input "$file" >/dev/null 2>&1; then
    doctor_add "ruleset 適用" "OK" "$name"
  else
    warn "ruleset 適用に失敗(Free プランの private リポジトリでは利用不可。public 化か Pro で再実行)。"
    doctor_add "ruleset 適用" "FAIL" "Free+private では不可(README の FAQ 参照)"
  fi
}
log "(4) ブランチ保護 ruleset"; step_ruleset

log "(5) マージ設定(squash のみ・auto-merge・ブランチ自動削除)"
gh_step "マージ設定" "gh api PATCH /repos が失敗" \
  gh api --method PATCH "repos/${REPO_SLUG}" \
    -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
    -F allow_auto_merge=true -F delete_branch_on_merge=true -F allow_update_branch=true \
    -F has_wiki=false -F has_projects=false -F has_discussions=false

log "(6) Actions 権限の最小化"
gh_step "Actions 既定権限 read" "workflow permissions API が失敗" \
  gh api --method PUT "repos/${REPO_SLUG}/actions/permissions/workflow" \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
gh_step "fork PR 承認要求" "fork-pr-contributor-approval API が失敗(未対応環境)" \
  gh api --method PUT "repos/${REPO_SLUG}/actions/permissions/fork-pr-contributor-approval" \
    -f approval_policy=all_external_contributors

log "(7) ラベル作成(5 種)"
step_labels() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] gh label create × 5(agent:ready / needs-spec / human-review / blocked / template-sync)"; doctor_add "ラベル作成" "SKIP" "dry-run"; return 0; fi
  if [ "$GH_READY" -ne 1 ]; then doctor_add "ラベル作成" "SKIP" "gh 未認証"; return 0; fi
  local ok=0 name color desc
  while IFS='|' read -r name color desc; do
    if gh label create "$name" --color "$color" --description "$desc" --force >/dev/null 2>&1; then
      ok=$((ok + 1))
    else warn "ラベル作成失敗: ${name}"; fi
  done <<'EOF'
agent:ready|0E8A16|受け入れ基準まで揃いエージェントが着手可能
needs-spec|FBCA04|仕様化(受け入れ基準の明確化)が先
human-review|D93F0B|人間の判断・レビュー待ち
blocked|B60205|他の作業・決定によりブロック中
template-sync|0075CA|テンプレート更新の同期 PR
EOF
  if [ "$ok" -eq 5 ]; then doctor_add "ラベル作成" "OK" "5/5"
  else doctor_add "ラベル作成" "FAIL" "${ok}/5 作成"; fi
}
step_labels

# ---------- (8) ローカル githooks ----------
log "(8) githooks(pre-commit)有効化"
if [ -d tools/githooks ]; then
  run git config core.hooksPath tools/githooks
  [ "$DRY_RUN" -eq 1 ] && doctor_add "githooks 設定" "SKIP" "dry-run" || doctor_add "githooks 設定" "OK" "core.hooksPath=tools/githooks"
else
  doctor_add "githooks 設定" "SKIP" "tools/githooks なし"
fi

# ---------- (9) template-sync の参照先置換 ----------
log "(9) template-sync 設定"
step_template_sync() {
  local f=".github/workflows/template-sync.yml" src_repo=""
  if [ ! -f "$f" ]; then doctor_add "template-sync 設定" "SKIP" "${f} なし"; return 0; fi
  if ! grep -q '{{TEMPLATE_REPO}}' "$f"; then doctor_add "template-sync 設定" "SKIP" "置換済み"; return 0; fi
  if [ "$GH_READY" -eq 1 ]; then
    src_repo="$(gh repo view --json templateRepository -q '.templateRepository.owner.login + "/" + .templateRepository.name' 2>/dev/null || true)"
  fi
  case "$src_repo" in */*) : ;; *) src_repo="$TEMPLATE_REPO_DEFAULT" ;; esac
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] ${f}: {{TEMPLATE_REPO}} → ${src_repo}"; doctor_add "template-sync 設定" "SKIP" "dry-run"; return 0; fi
  F="$f" V="$src_repo" python3 -c 'import os; p=os.environ["F"]; s=open(p,encoding="utf-8").read(); open(p,"w",encoding="utf-8").write(s.replace("{{TEMPLATE_REPO}}", os.environ["V"]))'
  doctor_add "template-sync 設定" "OK" "$src_repo"
}
step_template_sync

# ---------- (10) doctor: 適用結果 ----------
echo
log "(10) 適用結果"
printf '%s\n' "----------------------------------------------------------------------"
printf '%-28s | %-4s | %s\n' "項目" "結果" "補足"
printf '%s\n' "----------------------------------------------------------------------"
printf '%s' "$DOCTOR_ROWS" | while IFS='|' read -r item result note; do
  [ -n "$item" ] && printf '%-28s | %-4s | %s\n' "$item" "$result" "$note"
done
printf '%s\n' "----------------------------------------------------------------------"

# ---------- (11) 次の一歩 ----------
cat <<'NEXT'

次の一歩:
  1. make check           # 全ゲートが通ることを確認
  2. git add <ファイル> && git commit   # 変更を確認してコミット(Conventional Commits)
  3. 以後の変更は必ずブランチ + PR で(main 直 push は ruleset が拒否)
  FAIL / SKIP がある場合は、原因解消後に本スクリプトを再実行すれば該当箇所のみ適用されます(冪等)。
NEXT
log "bootstrap 完了。"
