#!/usr/bin/env bash
# このファイルの目的: Read / Bash 実行前に、.env・secrets/ 等の秘密ファイルへの
# 読み取り(Read や cat/grep/less 等)を exit 2 で遮断する PreToolUse hook。
# .env.example などの安全なテンプレートは許可し、参照先として案内する。
set -euo pipefail

# stdin を一度だけ読み込み、以降は変数から再利用する(stdinは一度しか読めない)
input="$(cat)"

# tool_name を取得(jq非依存: python3)
tool_name="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print(d.get("tool_name",""))' 2>/dev/null || true)"

# 秘密ファイルアクセスを遮断して終了
block_secret() {
  printf 'ブロック: 秘密ファイル(.env・secrets/ 等)の読み取りは禁止です。\n代替: 変数名や形式を知りたい場合は .env.example を参照してください。実値が必要な処理は環境変数経由で扱ってください。\n' >&2
  exit 2
}

# パスが秘密ファイルにあたるか(case グロブで移植性高く判定)
secret_path() {
  case "$1" in
    # 安全な雛形は除外(先に返す)
    *.env.example|*.env.sample|*.env.template|*.env.dist) return 1 ;;
  esac
  case "$1" in
    .env|*/.env|*.env) return 0 ;;                       # .env 本体
    .env.*|*/.env.*) return 0 ;;                          # .env.local, .env.production 等
    secret/*|*/secret/*|secrets/*|*/secrets/*) return 0 ;; # secrets ディレクトリ配下
    *.pem|*.key|*id_rsa*|*id_ed25519*|*.p12|*.pfx) return 0 ;; # 鍵・証明書
    *) return 1 ;;
  esac
}

if [ "$tool_name" = "Read" ]; then
  file_path="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print((d.get("tool_input") or {}).get("file_path",""))' 2>/dev/null || true)"
  [ -z "$file_path" ] && exit 0
  if secret_path "$file_path"; then block_secret; fi

elif [ "$tool_name" = "Grep" ]; then
  # Grep ツール: 検索対象(path / glob)が秘密ファイル・ディレクトリを指す場合は遮断
  gpaths="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
ti=d.get("tool_input") or {}
print(str(ti.get("path",""))); print(str(ti.get("glob","")))' 2>/dev/null || true)"
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if secret_path "$p"; then block_secret; fi
  done <<GREOF
$gpaths
GREOF

elif [ "$tool_name" = "Bash" ]; then
  command="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print((d.get("tool_input") or {}).get("command",""))' 2>/dev/null || true)"
  [ -z "$command" ] && exit 0
  # 読み取り系コマンド(cat/grep/less/source 等)を使っているか?
  if printf '%s' "$command" | grep -Eq '(^|[[:space:];&|(])(cat|tac|nl|less|more|head|tail|grep|egrep|fgrep|rg|ag|xxd|od|hexdump|strings|bat|view|cut|sort|uniq|awk|sed|dd|source|\.)([[:space:]]|$)'; then
    # .env.example 等の安全参照を判定から除外してから秘密参照を探す
    scrubbed="$(printf '%s' "$command" | sed -E 's/\.env\.(example|sample|template|dist)//g')"
    if printf '%s' "$scrubbed" | grep -Eq '(^|[[:space:]/=<])\.env($|[^A-Za-z0-9])' \
       || printf '%s' "$scrubbed" | grep -Eq '(^|[[:space:]/=<])\.env\.[A-Za-z0-9_]' \
       || printf '%s' "$scrubbed" | grep -Eq '(^|[[:space:]/=<])secrets?/'; then
      block_secret
    fi
  fi
fi

# 秘密アクセスでなければ許可
exit 0
