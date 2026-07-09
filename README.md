<!-- このファイルは人間向けの入口。エージェント向けの正本は AGENTS.md。 -->

# Intelligent-system-core

AI コーディングエージェント(Claude Code を中心に Codex / Cursor / Gemini 互換)で
多様なシステムを構築するための、GitHub デフォルト設定テンプレートリポジトリです。
スパゲッティ化を防ぎ、効率的なエージェント駆動開発を出発点から可能にすることを狙いとします。

設計の考え方はひとことで言うと **「守らせたいルールは散文ではなく hooks / CI / linter で機械強制し、
文書は『なぜ』を説明する場に徹する」**。採否の根拠はすべて [`docs/governance/tech-radar.md`](docs/governance/tech-radar.md) に台帳化しています。

## 使い方(新規プロジェクト・3 ステップ)

1. このテンプレートからリポジトリを作成する

   ```bash
   gh repo create <your-project> --template tomoya72457/Intelligent-system-core --private --clone
   cd <your-project>
   ```

2. 初期設定スクリプトを実行する(プレースホルダ置換・プロファイル展開・GitHub 設定適用)

   ```bash
   ./tools/bootstrap.sh            # 対話形式
   # または: ./tools/bootstrap.sh --name "My App" --profile typescript --non-interactive
   ./tools/bootstrap.sh --dry-run  # 何が起きるか事前確認(変更なし)
   ```

   `bootstrap.sh` が行うこと: プロジェクト名・目的の置換、プロファイル(`typescript` / `python` / `docs`)展開、
   ブランチ保護 ruleset 適用、マージ設定(squash のみ・自動マージ・マージ後ブランチ削除)、
   Actions 権限の最小化、ラベル 5 種作成、githooks の有効化。

3. 開発を始める。変更のたびに `make check` で全ゲートを検証し、PR を出す。

   ```bash
   make check
   ```

## 既存リポジトリへ後付けする

既存プロジェクトに部品(hooks / CI / githooks / 構造チェッカー / AGENTS.md 雛形など)だけを取り込むには:

```bash
./tools/adopt.sh --list          # 取り込める部品をカテゴリ別に一覧
./tools/adopt.sh /path/to/repo   # 対話形式で選択して配置(既存ファイルは衝突回避でスキップ)
```

## 中身の地図

| ディレクトリ / ファイル | 役割 |
|---|---|
| `AGENTS.md` | エージェント向け正本ルール(全ツールがこれを読む) |
| `CLAUDE.md` / `.gemini/` / `.cursor/` | 各ツールから `AGENTS.md` へのポインタ |
| `.github/` | CI・ブランチ保護 ruleset・Issue/PR テンプレート・Dependabot |
| `.claude/` | 権限・hooks(危険操作/秘密/設定保護)・サブエージェント・スキル |
| `docs/` | ADR・ガバナンス(採否ルーブリックと台帳)・規約・手順書。入口は [`docs/README.md`](docs/README.md) |
| `tools/` | `check_structure.py`(構造・予算の機械強制)・`bootstrap.sh`・`adopt.sh`・githooks |
| `profiles/` | 言語プロファイル(TypeScript / Python / docs)。bootstrap 時に展開され削除される |
| `Makefile` | `make check` を入口とする標準ターゲット |

## 設計根拠

各構成要素は `adoption-judge` ルーブリック(5 軸加重採点)で採否を判定し、その結果を
[`docs/governance/tech-radar.md`](docs/governance/tech-radar.md) と `docs/governance/intake/` に記録しています。
判定の枠組み自体は [`docs/governance/rubric.md`](docs/governance/rubric.md) を参照してください。

## FAQ

**Q. private リポジトリでも動きますか?**
A. 動きますが、ブランチ保護 **ruleset は GitHub Free の private リポジトリでは利用できません**(Pro 以上、または public リポジトリが必要)。
`bootstrap.sh` は ruleset 適用に失敗しても警告を出して続行し、最後の doctor 表に `SKIP` / `FAIL` として表示します。
他の設定(マージ設定・ラベル・githooks・Actions 権限)は Free の private でも適用されます。

**Q. `make test` などが「プロファイル未導入」と言います。**
A. 素のテンプレートでは正常です。`bootstrap.sh` でプロファイルを導入すると `Makefile.profile` が置かれ、実体が有効化されます。

**Q. テンプレートの更新を後から取り込めますか?**
A. `.github/workflows/template-sync.yml` が週次で更新 PR を作成します(`template-sync` ラベル付き)。
プロジェクト固有ファイルは `.templatesyncignore` で上書き対象外にしています。
なお **workflow ファイル自体の更新は同期されません**(GITHUB_TOKEN は workflow を push できない GitHub の制約)。
テンプレート側の CI 改善も配送したい場合は、`workflow` スコープ付き PAT を secret に登録し
actions-template-sync の `source_gh_token` / `target_gh_token` に渡してください。

## ライセンス

MIT License([`LICENSE`](LICENSE))。
