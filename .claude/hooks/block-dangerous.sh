#!/usr/bin/env bash
# このファイルの目的: Bashツール実行前にstdin JSONのcommandを検査し、破壊的・
# 危険なコマンド(rm -rf 危険パス / sudo / chmod 777 / curl|bash / force push 等)を
# exit 2 で遮断する PreToolUse hook。プロジェクト内相対パスは許可し誤遮断を避ける。
set -euo pipefail

# --- stdin JSON から command を抽出 (jq非依存: python3) ---
cmd="$(python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    sys.exit(0)
print((d.get("tool_input") or {}).get("command",""))' 2>/dev/null || true)"

# command が空(Bash以外や解析不能)なら判定不要 → 許可
[ -z "$cmd" ] && exit 0

# 遮断ヘルパ: 理由と代替手段を stderr に出し exit 2(この stderr が Claude に渡る)
block() {
  # $1=理由, $2=代替手段
  printf 'ブロック: %s\n代替: %s\n' "$1" "$2" >&2
  exit 2
}

# リダイレクト(> file, 2>&1, < file 等)を除去した文字列。
# 「rm -rf build > /dev/null」の /dev/null を rm 対象と誤認しないための正規化。
stripped="$(printf '%s' "$cmd" \
  | sed -E -e 's/[0-9]*>>?[[:space:]]*[^[:space:]]*//g' \
           -e 's/[0-9]*>&[0-9]*//g' \
           -e 's/[0-9]*<[[:space:]]*[^[:space:]]*//g')"

# ============================================================
# 1) sudo: 権限昇格。エージェント作業で sudo が要る=設計の誤り。
#    根拠: hooks二層強制(§5)。昇格した破壊は復旧不能になりうる。
#    先頭/空白/区切り直後の sudo のみ(/usr/bin/sudo 等の言及は誤遮断しない)。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])sudo([[:space:]]|$)'; then
  block "sudo による権限昇格は禁止です" \
        "昇格が必要な操作は人間がターミナルで実行してください"
fi

# ============================================================
# 2) chmod 777 / 0777: 全ユーザに読み書き実行を許可。秘密漏洩・改ざんの温床。
#    根拠: セキュリティを能動的に悪化させる操作(§4 拒否権相当)。
#    末尾境界で「777.txt」等のファイル名は誤遮断しない。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])chmod[[:space:]]' \
   && printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])0?777([[:space:]]|$|/)'; then
  block "chmod 777 は全ユーザに書込を許可し危険です" \
        "必要最小の権限(例 644 / 755)を指定してください"
fi

# ============================================================
# 3) curl|bash / wget|sh: 未検証スクリプトの直接実行。サプライチェーン注入。
#    根拠: Clinejection 実被害・パイプ実行はレビュー不能。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(curl|wget)[^|]*\|[[:space:]]*[^|]*(bash|sh|zsh|python[0-9.]*|node|ruby|perl)([[:space:]]|$)'; then
  block "ネットワーク取得物のパイプ実行(curl|bash 系)は禁止です" \
        "スクリプトを一旦保存し内容を確認してから実行してください"
fi

# ============================================================
# 4) git push --force / -f を main・master 宛に: 履歴破壊・他者作業の消失。
#    根拠: 二層強制+本番保護。作業ブランチの通常 push は許可。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+push\b'; then
  # main/master は refspec 形式(HEAD:main)でも検出するため区切りに : を含める
  if printf '%s' "$cmd" | grep -Eq '(--force|[[:space:]]-[a-zA-Z]*f([[:space:]]|$))' \
     && printf '%s' "$cmd" | grep -Eq '(^|[[:space:]]|:)(main|master)([[:space:]]|$)'; then
    block "main/master への force push は履歴を破壊します" \
          "作業ブランチへ push するか、通常の push を使ってください"
  fi
fi

# ============================================================
# 5) git add -A / . / --all, git commit -a: 無差別ステージング。
#    根拠: シークレット防衛(§5)。秘密や無関係変更を巻き込む。パス指定を促す。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+add\b'; then
  if printf '%s' "$cmd" | grep -Eq '[[:space:]]-[a-zA-Z]*A[a-zA-Z]*([[:space:]]|$)|[[:space:]]--all([[:space:]]|$)|[[:space:]]\.([[:space:]]|$)|[[:space:]]:/'; then
    block "git add の一括ステージング指定(-A / . / :/)は禁止です" \
          "変更したファイルをパス指定でステージしてください(例 git add path/to/file)"
  fi
fi
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+commit\b'; then
  # 短フラグ束の中の a(-a / -am 等)または --all のみ遮断。--amend は許可。
  if printf '%s' "$cmd" | grep -Eq '[[:space:]]-[a-zA-Z]*a[a-zA-Z]*([[:space:]]|$)|[[:space:]]--all([[:space:]]|$)'; then
    block "git commit -a による全変更の自動コミットは禁止です" \
          "git add でパス指定後に git commit してください"
  fi
fi

# ============================================================
# 6) git stash(パス/安全サブコマンド無し): 追跡中の変更を退避し見失いやすい。
#    根拠: 作業消失防止。list/pop/apply 等の参照系と -- によるパス指定は許可。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+stash([[:space:]]|$)'; then
  if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+stash[[:space:]]+(list|show|pop|apply|drop|clear|branch)([[:space:]]|$)'; then
    :  # 参照/復元系は許可
  elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+stash[[:space:]]+.*--([[:space:]]|$)'; then
    :  # -- によるパス指定ありは許可
  else
    block "パス指定のない git stash は変更を見失う恐れがあります" \
          "退避が必要なら対象を明示(例 git stash push -- <path>)、または通常コミットしてください"
  fi
fi

# ============================================================
# 7) git reset --hard: ワークツリーの未コミット変更を破棄。復元困難。
#    根拠: 作業消失(未コミット分は reflog に残らず消える)。
# ============================================================
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])git[[:space:]]+reset\b[^;&|]*--hard([[:space:]]|$)'; then
  block "git reset --hard は未コミットの変更を破棄します" \
        "変更を残すなら git stash push -- <path> や git commit を検討し、破棄が確実に必要な場合のみ人間が実行してください"
fi

# ============================================================
# 8) rm 再帰 + 危険ターゲット(絶対 / ホーム / 上位相対 / 変数展開)。
#    根拠: pulse-propagate 実事故 d4c793bb(誤削除)。
#    プロジェクト内相対パス(node_modules, ./build 等)は許可。
#    「cd /etc && rm -rf x」の /etc を rm 対象と誤認しないよう区切りで分割し個別判定。
# ============================================================
segments="$(printf '%s' "$stripped" | awk '{gsub(/[;|&]+/, "\n"); print}')"
while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  # このセグメントが再帰 rm(-r / -R / -rf / -fr / --recursive)か?
  printf '%s' "$seg" | grep -Eiq '(^|[[:space:]/])rm[[:space:]]+(-[a-z]*r|--recursive)' || continue
  danger=""
  # 8a. 絶対パス: 引数が / で始まる(rm -rf /  rm -rf /etc)。./build は space+. なので不一致。
  if printf '%s' "$seg" | grep -Eq '(^|[[:space:]])/'; then danger="絶対パス"; fi
  # 8b. ホーム: ~ もしくは ~/...(rm -rf ~  rm -rf ~/Documents)
  if printf '%s' "$seg" | grep -Eq '(^|[[:space:]])~'; then danger="ホームディレクトリ"; fi
  # 8c. 上位相対: .. 単体 / ../ 始まり / 途中の /.. (親ディレクトリ脱出)
  if printf '%s' "$seg" | grep -Eq '(^|[[:space:]])\.\.(/|[[:space:]]|$)|/\.\.(/|[[:space:]]|$)'; then danger="上位相対パス(..)"; fi
  # 8d. 変数展開・コマンド置換: $VAR ${VAR} $(...) は書込時に値不明で危険
  if printf '%s' "$seg" | grep -Eq '\$[A-Za-z_{(]'; then danger="変数展開/コマンド置換"; fi
  # 8e. xargs 経由: 削除対象が stdin 由来でこの hook から検査できない(echo x | xargs rm -rf)
  if printf '%s' "$seg" | grep -Eq '(^|[[:space:];&|(])xargs([[:space:]]|$)'; then danger="xargs 経由(対象が検査不能)"; fi
  if [ -n "$danger" ]; then
    block "rm -rf で危険なターゲット($danger)を指定しています" \
          "削除対象はプロジェクト内の相対パスに限定してください(例 rm -rf node_modules ./build)"
  fi
done <<EOF
$segments
EOF

# ============================================================
# 9) 保護パス(エージェントのガード設定)への Bash 経由の書込。
#    根拠: 原則8(GitInject 対策)。Edit/Write 系は protect-agent-config.sh が
#    遮断するが、リダイレクト・tee・cp/mv/install・sed -i という代表的な
#    書込経路もここで遮断する。網羅ではない(残余経路はレビューと ADR が最終防衛)。
#    読取(cat / ls / grep 等)は許可。
# ============================================================
PROTECTED_RE='(\.claude/(settings[^[:space:]'\''\"]*\.json|hooks)|\.gemini/|\.cursor/|tools/githooks|\.github/workflows)'
prot_hit=""
# 9a. リダイレクト(> / >>)の書込先が保護パス
if printf '%s' "$cmd" | grep -Eq ">>?[[:space:]]*[\"']?[^[:space:];&|]*${PROTECTED_RE}"; then prot_hit="リダイレクト"; fi
# 9b. tee / cp / mv / install / rsync の引数に保護パス
if printf '%s' "$cmd" | grep -Eq "(^|[[:space:];&|(])(tee|cp|mv|install|rsync)[[:space:]][^;&|]*${PROTECTED_RE}"; then prot_hit="ファイル操作コマンド"; fi
# 9c. sed -i がコマンド内にあり、かつ保護パスに言及
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|(])sed[[:space:]][^;&|]*-i' \
   && printf '%s' "$cmd" | grep -Eq "${PROTECTED_RE}"; then prot_hit="sed -i"; fi
if [ -n "$prot_hit" ]; then
  block "エージェントのガード設定(settings/hooks/workflows/githooks)への書込(${prot_hit})は禁止です" \
        "これらはセキュリティ境界です。変更案を提示し、人間がエディタで編集して ADR に記録してください"
fi

# どのルールにも該当しなければ許可
exit 0
