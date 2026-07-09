# intake 判定記録: AGENTS.md 正本+全ツールポインタ統合

このファイルは、エージェント指示の「正本」を `AGENTS.md` に一本化し、各ツール固有ファイルはそこを指すポインタに徹する方針の較正記録である。テンプレート構築時(2026-07-09)にルーブリックを適用した実記録。

- **提案日**: 2026-07-09
- **slug**: agents-md-canonical
- **判定**: **Adopt**(W 4.85)
- **再審査日**: 2027-07-09

## 提案

エージェント指示の唯一の正本を `AGENTS.md` とし、`CLAUDE.md` / `.gemini/settings.json` / `.cursor/rules/main.mdc` / `.github/copilot-instructions.md` は本文を複製せず `AGENTS.md` を参照するだけのポインタにする。関連する採用判断: `docs/adr/0005-agents-md-canonical-pointers.md`。

## 適用可能性ゲート

制約なし。プレーンな Markdown と各ツールの参照設定のみで実現でき、いずれのベンダーにもロックインされない。

## 可逆性(two-way door)

**可逆**。正本を別ファイルに移す・ポインタを外すのは数ファイルの編集で済む。外部契約やデータには波及しない。

## 賛成論(3点以上)

1. **エコシステムの収斂**: `AGENTS.md` は7つ以上の主要ツールが読む事実上の標準となり、Linux Foundation 傘下の Agentic AI Foundation が管轄する中立フォーマットになった(agents.md / LF プレスリリース)。単一ベンダー仕様ではないため耐久性が高い。
2. **複製の腐敗を防ぐ**: 同じルールを複数ファイルに書くと必ず片方が古くなる。正本1つ+ポインタなら、コンテキスト予算(`docs/governance/intake/2026-07-09-context-budget-enforcement.md`)の一元管理とも整合する。
3. **大規模実証**: GitHub Copilot の2,500超リポジトリ分析で、簡潔で構造化された AGENTS.md がエージェントの成功に寄与すると報告されている。単数形 `AGENT.md` は業界が複数形へ移行し敗北した(ampcode の顛末)。

## 反対論(3点以上)

1. **自動生成の誘惑**: コンテキストファイルを自動生成するツールがあるが、ETH の研究(arxiv 2602.11988)は、生成されたコンテキストファイルは成功率を改善せずコストを 20-23% 増やすと報告。→ 対策として本テンプレートは AGENTS.md を**手書き・最小**に保ち、自動生成に依存しない。
2. **ベンダー固有機能の取りこぼし**: ポインタ方式だと各ツール固有の高度な設定を使い切れない可能性。→ ツール固有の必要設定(hooks 等)は各設定ファイルに残し、共有すべき規範のみ AGENTS.md に集約することで両立。
3. **配布時にコピーされない問題**: Template repo は設定を運ばない場合がある。→ `AGENTS.md` 自体はファイルなのでクローンに含まれ、この問題は Rulesets 側(`docs/governance/intake/2026-07-09-rulesets-and-bootstrap.md`)で扱う。

## 採点(重み E0.30 / G0.20 / A0.25 / M0.15 / C0.10)

| 軸 | スコア | 根拠 |
|---|---|---|
| E: エビデンス強度 | 5 | 7+ツール収斂・LF 管轄・2,500リポ分析・ETH の反証込みで方向性が固い |
| G: 汎用性 | 5 | 3プロファイル全てで有効。プレーンMarkdownで言語非依存 |
| A: エージェント効果 | 5 | 起動時に必ず読まれる層のコンテキスト経済に直接寄与 |
| M: 維持コスト(逆) | 4 | 手書きだが最小・低頻度更新。自動生成を避けるため腐りにくい |
| C: 複雑性コスト(逆) | 5 | 利用者は AGENTS.md 1枚を読めばよい |
| **W: 加重平均** | **4.85** | 拒否権抵触なし |

## 判定

**Adopt**。W4.85 で閾値を大きく超える。全軸2点以上で拒否権抵触なし。

## 関連判定

- **Reject(詳細は 2026-07-09-rejected-practices.md)**: `AGENT.md` 単数形 / `.cursorrules`(公式に廃止・敗北)、ベンダーメモリ機能依存(スコープ漏れ・無告知消失)。いずれも本方針の却下された代替案。
- **Assess**: Claude Code プラグイン化配布。配布形態は Template repo 方式で決定済み(`docs/adr/0001-distribution-and-adoption.md`)のため見送り、12ヶ月後に再審査。

## 条件

—(Adopt のため無し)

## 根拠ソース

- https://agents.md/ : AGENTS.md フォーマットの正本サイト
- https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation : LF 管轄化(中立性・耐久性)
- https://ampcode.com/news/AGENT.md : 単数形 AGENT.md から複数形への移行の顛末
- https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/ : 2,500超リポジトリ分析(簡潔・構造化が有効)
- https://arxiv.org/abs/2602.11988 : ETH。生成コンテキストファイルは成功率を改善せずコスト+20-23%(自動生成を避ける根拠)
