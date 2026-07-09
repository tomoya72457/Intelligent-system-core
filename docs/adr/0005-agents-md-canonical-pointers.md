# ADR-0005: AGENTS.md 正本+全ツールポインタ統合

このファイルは、エージェント指示ファイルの正本を `AGENTS.md` に一本化する確定判断(2026-07-09 壁打ち)を記録する。判定の採点詳細は `docs/governance/intake/2026-07-09-agents-md-canonical.md`(Adopt, W4.85)。

- **日付**: 2026-07-09
- **状態**: 承認

## 文脈

Claude Code(CLAUDE.md)・Codex(AGENTS.md)・Gemini(settings 指定)・Cursor(rules)・Copilot(copilot-instructions.md)は、それぞれ別のファイルから指示を読む。同じ規範を複数ファイルに書くと必ず片方が古くなり(複製の腐敗)、コンテキスト予算(原則2)も管理不能になる。一方、`AGENTS.md` は Linux Foundation 傘下の中立フォーマットとして7つ以上のツールが読む事実上の標準に収斂した。

## 決定

- **正本**: `AGENTS.md`(リポジトリルート)。規範・コマンド・境界はここにだけ書く。
- **ポインタ**: `CLAUDE.md` は `@AGENTS.md` 参照+数行(800バイト以内)。`.gemini/settings.json` は context.fileName で AGENTS.md を指定。`.cursor/rules/main.mdc` と `.github/copilot-instructions.md` は「正本は AGENTS.md、複製しない」の数行。
- **強制**: 予算とポインタ形状は `tools/check_structure.py` が機械検証する。

## 検討した代替案(必須)

- **案B: ツールごとに個別ファイルを完全に書き分ける** — 却下。N ファイルの同期維持は必ず破れ、どれが正か分からなくなる。予算管理も N 倍になる。
- **案C: CLAUDE.md を正本にする** — 却下。単一ベンダーのファイル名を正本にすると他ツールからの参照が不自然になる。AGENTS.md は LF 管轄の中立規格で、将来のツール追加にも耐える。
- **案D: シンボリックリンクで物理的に同一化** — 却下。Windows・一部ツール・GitHub 表示でのリンク解釈が不安定で、ポインタ1行の方が決定的。
- **案E: 生成ツールで各ファイルへ自動複製** — 却下。生成コンテキストファイルは成功率を改善せずコストを 20-23% 増やすとの実証(ETH)。生成レイヤ自体も保守対象になる。

## 結果

- 規範の変更は AGENTS.md の1箇所で完結し、全ツールへ同時に効く。
- 予算(ソフト150行/ハード200行・24,576バイト)が単一ファイルに集中するため、`tools/check_structure.py` で機械強制できる。
- トレードオフ: ツール固有機能(hooks 等)は各設定ファイルに残る。それらは「規範」でなく「配線」であり、正本一本化の対象外とする。

## Confirmation(実装後に追記)

`AGENTS.md`・`CLAUDE.md`・`.gemini/settings.json`・`.cursor/rules/main.mdc`・`.github/copilot-instructions.md` が本構成で実装され、`python3 tools/check_structure.py` が CLAUDE.md の `@AGENTS.md` 行と予算を常時検証する。

## 信頼度と再検討トリガー

- **信頼度**: 高(7+ツール収斂+LF 管轄+2,500リポ分析。詳細は intake 記録)
- **再検討トリガー**: 主要ツールが AGENTS.md 読み取りを廃止したら。ポインタ方式で指示が効いていない実例を観測したら。
