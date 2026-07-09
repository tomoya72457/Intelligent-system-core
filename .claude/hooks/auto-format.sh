#!/usr/bin/env bash
# このファイルの目的: Edit / Write / MultiEdit の後に、編集ファイルを拡張子に応じて
# 自動整形する PostToolUse hook。フォーマッタ不在や整形失敗でも作業を止めない
# (常に exit 0)。-e は付けない。
set -uo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print((d.get("tool_input") or {}).get("file_path",""))' 2>/dev/null || true)"

# パスが取れない/実ファイルでないなら何もしない
[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    # biome が使える時のみ整形(未導入なら何もしない)
    if command -v biome >/dev/null 2>&1; then
      biome format --write "$file_path" >/dev/null 2>&1 || true
    elif command -v npx >/dev/null 2>&1 && npx --no-install biome --version >/dev/null 2>&1; then
      npx --no-install biome format --write "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
  *.py)
    # ruff が使える時のみ整形
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file_path" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
