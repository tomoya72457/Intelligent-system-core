#!/usr/bin/env bash
# このファイルの目的: Edit / Write / MultiEdit 実行前に、エージェント設定ファイル
# (.claude/settings*.json, .claude/hooks/**, .gemini/settings.json, .cursor/**,
#  .github/workflows/**, tools/githooks/**)
# への書き込みを exit 2 で遮断する PreToolUse hook。GitInject 対策(設定注入の防止)。
# skills/ や agents/ は通常の編集対象なので遮断しない。
set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
print((d.get("tool_input") or {}).get("file_path",""))' 2>/dev/null || true)"

# ファイルパスが取れなければ判定不要 → 許可
[ -z "$file_path" ] && exit 0

# 絶対パス・相対パスどちらでもマッチするよう末尾の相対部分で判定する
case "$file_path" in
  .claude/settings.json|*/.claude/settings.json)             match=1 ;;
  .claude/settings.local.json|*/.claude/settings.local.json) match=1 ;;
  .claude/hooks/*|*/.claude/hooks/*)                         match=1 ;;
  .gemini/settings.json|*/.gemini/settings.json)             match=1 ;;
  tools/githooks/*|*/tools/githooks/*)                       match=1 ;;
  .cursor/*|*/.cursor/*)                                     match=1 ;;
  .github/workflows/*|*/.github/workflows/*)                 match=1 ;;
  *)                                                         match=0 ;;
esac

if [ "$match" = "1" ]; then
  printf 'ブロック: エージェント設定ファイル(%s)はセキュリティ境界です。\n代替: これらのファイルはエージェントによる自己改変を禁止しています。人間がエディタで直接編集し、変更理由を ADR(docs/adr/)に記録してください。\n' "$file_path" >&2
  exit 2
fi

# 保護対象外(skills/ agents/ 等)は許可
exit 0
