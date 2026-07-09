<!-- このファイルはリポジトリの正本ルール。全 AI エージェント(Claude Code / Codex / Cursor / Gemini)が最初に読む。CLAUDE.md・.gemini・.cursor は本ファイルを指すポインタで、規約を複製しない。 -->

# AGENTS.md

## プロジェクト概要

<!-- bootstrap.sh が {{PROJECT_NAME}} と {{PROJECT_PURPOSE}} を実値へ置換する。テンプレートのまま残さない。 -->

- 名称: {{PROJECT_NAME}}
- 目的: {{PROJECT_PURPOSE}}
- 開発形態: AI コーディングエージェント駆動。スパゲッティ化を防ぐため本ファイルの規範に従う。

## コマンド(まずこれを使う)

| 目的 | コマンド |
|---|---|
| 全ゲート検証(最重要) | `make check` |
| 構造・ドキュメント予算チェック | `make structure` |
| テスト | `make test` |
| リント | `make lint` |
| 型チェック | `make typecheck` |
| 依存境界チェック | `make arch` |

`make check` が緑になるまで作業は完了ではない。素のテンプレートでは test / lint / typecheck / arch は「プロファイル未導入」を表示する(`tools/bootstrap.sh` でプロファイルを導入すると有効化)。

## 絶対禁止(Never — 例外なく守る)

- `main` への直接 push。変更は必ず PR 経由。
- `.env` / `secrets/` の読み取り・出力・コミット。値の形が必要なら `cat .env.example` で見る(Read ツールはガードが遮断する)。
- エージェントのガード設定(`.claude/settings*`・`.claude/hooks/`・`.gemini/`・`.cursor/`・`.github/workflows/`・`tools/githooks/`)の自己編集。人間が変更し ADR に記録する(セキュリティ境界)。`.claude/skills/`・`.claude/agents/` の内容は通常の編集対象。
- パス無指定の一括ステージング(`git add -A` / `git add .` / `git commit -a`)。変更ファイルを明示する。
- 「完成」「完了」「動作確認済み」の宣言。完成の判断は人間のみ。エージェントは実行したコマンドと結果(事実)だけを報告する。

## 構造ルータ(どこに何があるか)

| 知りたいこと | 場所 |
|---|---|
| 何をどう読むかの道案内 | `docs/README.md` |
| 設計判断の記録(ADR) | `docs/adr/` |
| 採否の根拠台帳(なぜこの構成か) | `docs/governance/tech-radar.md` |
| コーディング / アーキテクチャ / 文書の規約 | `docs/conventions/` |
| 手順書(タスク分解・並列作業・本番書込) | `docs/playbooks/` |
| 再利用スキル(intake / adr / spec / handoff / incident) | `.claude/skills/` |
| 構造・予算を強制するルール本体 | `tools/check_structure.py` |
| 配布・初期設定・既存リポへの後付け | `tools/bootstrap.sh` / `tools/adopt.sh` |

## 常時適用の規範

- 小さな PR: 1 PR = 1 論理変更・目安 ±400 行以内。超過は CI が警告する。
- コミット: Conventional Commits(`feat` / `fix` / `chore` / `docs` / `refactor` / `test` / `ci`)。雛形は `.gitmessage`。本文・コメントは日本語、識別子とコミット type は英語。
- フェイルファスト: 異常は握り潰さず即座に失敗させる。未使用の「保険」分岐を足さない(YAGNI)。
- 推測で API を書かない: 未確認のライブラリ・関数・引数は、使う前に実在と仕様を確認する。
- 依頼範囲を守る: 頼まれていない変更・リファクタ・最適化を混ぜない。
- 書いたら動かす: 変更は実際に実行して確かめてから報告する(テストや `make check` を回す)。
- ミスは 2 回目で規約化: 同じ誤りを繰り返したら、該当する規約・hook・チェックに落として機械強制する。

## 境界: Always / Ask first

Always(常に行う):

- `make check` で検証してから結果を報告する。
- 変更は PR で提出する。アーキテクチャ判断を含むなら該当 ADR を参照・追記する(無ければ N/A と書く)。

Ask first(着手前に人間へ確認する):

- 依存の追加・更新(採否は `adoption-judge` の判定を経る)。
- 外部 API 契約・データスキーマの変更。
- 不可逆な操作(データ削除・履歴改変・本番設定の変更)。

## 自己管理(このファイルの維持)

- 予算: 150 行(ソフト警告)/ 200 行・24,576 バイト(ハード上限)。`tools/check_structure.py` が強制する。
- 詳細を本ファイルに足さない。増えたら `docs/` や `.claude/skills/` へ逃がす(常時コンテキスト最小・段階開示)。
- 本ファイルまたは `CLAUDE.md` を編集したら `make structure` を実行し、予算超過とポインタ形状を確認する。

## テンプレート利用者へ

新規プロジェクトは `tools/bootstrap.sh` を実行してプレースホルダ置換・プロファイル展開・GitHub 設定適用を行う(手順は `README.md`)。既存リポジトリへ部品を後付けするなら `tools/adopt.sh`。

## 最重要ルールの再掲(必読)

1. `main` への直 push 禁止 — 変更は必ず PR。
2. `.env` / 秘密の読み取り禁止 — 形が必要なら `.env.example`。
3. エージェント設定の自己編集禁止 — 人間が行い ADR に記録。
4. 「完成」宣言は人間のみ — エージェントは検証した事実だけを報告する。
