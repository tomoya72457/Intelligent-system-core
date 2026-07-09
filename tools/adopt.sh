#!/usr/bin/env bash
# このスクリプトはテンプレートの部品(hooks / CI / githooks / 構造チェッカー / AGENTS.md 雛形)を
# 既存リポジトリへカテゴリ単位で後付けする。既存ファイルとの衝突はスキップして一覧報告する。
# 使い方: <テンプレート>/tools/adopt.sh [オプション] [対象リポジトリパス(省略時: カレントの git ルート)]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

LIST_ONLY=0; ASSUME_YES=0; DRY_RUN=0; TARGET=""

usage() {
  cat <<'USAGE'
使い方: tools/adopt.sh [オプション] [対象リポジトリパス]
  --list      カテゴリと対象ファイルの一覧を表示して終了
  --yes       全カテゴリを確認なしで選択(既定は対話でカテゴリごとに y/N)
  --dry-run   コピーを行わず、行われる操作のみ表示
  --help      このヘルプ
対象パス省略時はカレントディレクトリの git ルートに適用する(テンプレート自身には適用不可)。
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --list)    LIST_ONLY=1; shift ;;
    --yes)     ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    -*) echo "ERROR: 不明なオプション: $1" >&2; usage >&2; exit 1 ;;
    *)  TARGET="$1"; shift ;;
  esac
done

log()  { printf '\033[1m[adopt]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# ---- カテゴリ定義(名前 / 説明 / 対象パス。パスはテンプレートルートからの相対、ディレクトリは再帰) ----
CATEGORIES="structure agents-md claude ci githooks"
category_desc() {
  case "$1" in
    structure) echo "構造チェッカー(check_structure.py + テスト + Makefile)" ;;
    agents-md) echo "AGENTS.md 雛形とポインタ・基本設定(CLAUDE.md / .gitmessage / .editorconfig / .env.example)" ;;
    claude)    echo "エージェント設定一式(.claude/ hooks・agents・skills、.gemini / .cursor ポインタ)" ;;
    ci)        echo "GitHub CI・ruleset・Issue/PR テンプレート・Dependabot(.github/)" ;;
    githooks)  echo "ローカル pre-commit フック(tools/githooks/)" ;;
  esac
}
category_paths() {
  case "$1" in
    structure) echo "tools/check_structure.py tools/test_check_structure.py Makefile" ;;
    agents-md) echo "AGENTS.md CLAUDE.md .gitmessage .editorconfig .env.example" ;;
    claude)    echo ".claude .gemini .cursor" ;;
    ci)        echo ".github/workflows/ci.yml .github/rulesets .github/ISSUE_TEMPLATE .github/pull_request_template.md .github/dependabot.yml .github/copilot-instructions.md .github/SECURITY.md" ;;  # template-sync.yml はテンプレート派生リポジトリ専用のため除外
    githooks)  echo "tools/githooks" ;;
  esac
}

# ---- --list ----
if [ "$LIST_ONLY" -eq 1 ]; then
  echo "取り込み可能なカテゴリ(テンプレート: ${TEMPLATE_ROOT}):"
  for c in $CATEGORIES; do
    echo ""
    echo "  [${c}] $(category_desc "$c")"
    for p in $(category_paths "$c"); do
      if [ -e "${TEMPLATE_ROOT}/${p}" ]; then echo "    - ${p}"
      else echo "    - ${p} (テンプレート側に未生成)"; fi
    done
  done
  exit 0
fi

# ---- 対象リポジトリの決定と検証 ----
if [ -z "$TARGET" ]; then
  TARGET="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$TARGET" ] || die "対象が不明です。git リポジトリ内で実行するか、対象パスを引数で渡してください。"
fi
TARGET="$(cd "$TARGET" && pwd)" || die "対象パスに移動できません: $TARGET"
[ -d "$TARGET/.git" ] || git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "対象が git リポジトリではありません: $TARGET"
[ "$TARGET" != "$TEMPLATE_ROOT" ] || die "テンプレート自身には適用できません。対象リポジトリのパスを渡してください。"

log "テンプレート: ${TEMPLATE_ROOT}"
log "適用先      : ${TARGET}"
[ "$DRY_RUN" -eq 1 ] && log "dry-run: ファイルは変更しません。"

# ---- コピー処理(既存ファイルはスキップ) ----
COPIED=""; SKIPPED=""; MISSING=""
copy_one() { # $1=テンプレートからの相対ファイルパス
  local rel="$1" src="${TEMPLATE_ROOT}/$1" dst="${TARGET}/$1"
  if [ -e "$dst" ]; then SKIPPED="${SKIPPED}${rel}"$'\n'; return 0; fi
  if [ "$DRY_RUN" -eq 1 ]; then echo "  [dry-run] 配置: ${rel}"
  else mkdir -p "$(dirname "$dst")"; cp -p "$src" "$dst"; fi
  COPIED="${COPIED}${rel}"$'\n'
}
copy_path() { # $1=相対パス(ファイル or ディレクトリ)
  local p="$1" f
  if [ ! -e "${TEMPLATE_ROOT}/${p}" ]; then MISSING="${MISSING}${p}"$'\n'; return 0; fi
  if [ -d "${TEMPLATE_ROOT}/${p}" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] && copy_one "${f#"${TEMPLATE_ROOT}"/}"
    done <<EOF
$(find "${TEMPLATE_ROOT}/${p}" -type f | sort)
EOF
  else
    copy_one "$p"
  fi
}

ask() { # $1=カテゴリ名 → 採用するなら 0
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf '[%s] %s を取り込みますか? [y/N]: ' "$1" "$(category_desc "$1")"
  local a=""; read -r a
  case "$a" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

SELECTED=0
for c in $CATEGORIES; do
  if ask "$c"; then
    SELECTED=$((SELECTED + 1))
    log "カテゴリ [${c}] を取り込み中..."
    for p in $(category_paths "$c"); do copy_path "$p"; done
  else
    log "カテゴリ [${c}] は見送り。"
  fi
done
[ "$SELECTED" -gt 0 ] || { log "何も選択されませんでした。終了します。"; exit 0; }

# ---- 結果報告 ----
report_list() { # $1=見出し $2=改行区切りリスト
  [ -n "$2" ] || return 0
  echo ""; echo "$1"
  printf '%s' "$2" | while IFS= read -r line; do [ -n "$line" ] && echo "  - $line"; done
}
echo ""
log "===== 結果 ====="
report_list "配置したファイル:" "$COPIED"
report_list "衝突のためスキップ(既存を保持。差分は手動で確認):" "$SKIPPED"
report_list "テンプレート側に存在せずスキップ:" "$MISSING"

cat <<'NEXT'

後続の手順(必要なもののみ):
  1. githooks を取り込んだ場合: 対象リポジトリで `git config core.hooksPath tools/githooks`
  2. structure を取り込んだ場合: check_structure は docs/README.md と docs/governance/tech-radar.md を必須とする。
     無ければ最小の雛形(1行ずつでよい)を先に作ってから `make structure` を実行
  3. ci を取り込んだ場合: ruleset は自動適用されません。`gh api --method POST repos/<owner>/<repo>/rulesets --input .github/rulesets/main.json`
  4. AGENTS.md 雛形の {{PROJECT_NAME}} / {{PROJECT_PURPOSE}} を実値へ置換(または tools/bootstrap.sh を利用)
NEXT
log "adopt 完了(適用の最終判断とコミットは人間が行ってください)。"
