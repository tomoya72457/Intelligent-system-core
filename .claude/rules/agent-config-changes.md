---
paths: [".claude/**", ".gemini/**", ".cursor/**", ".github/workflows/**", "tools/githooks/**"]
---

<!-- このファイルの目的: エージェント設定・CI定義に触れる際の取り扱いルール。
     これらのパスはセキュリティ境界であり、変更には人間のレビューと ADR を必須とする。 -->

# エージェント設定の変更ルール

このルールは `.claude/**`・`.gemini/**`・`.cursor/**`・`.github/workflows/**`・`tools/githooks/**` に関わる作業に適用される。

- **これらのファイルはセキュリティ境界**。エージェントの権限・遮断・CI ゲートを定義しており、ここへの注入は最重大の攻撃ベクター(GitInject)。
- **ガード設定の自己改変は禁止**: `.claude/settings*.json`・`.claude/hooks/**`・`.gemini/settings.json`・`.cursor/**`・`.github/workflows/**`・`tools/githooks/**` をエージェントが編集しない。Edit/Write 系は protect-agent-config.sh が、Bash 経由の代表的な書込(リダイレクト・tee・cp/mv/install・sed -i)は block-dangerous.sh が遮断する。**網羅ではない**(インタープリタ経由等の残余経路あり)ため、最終防衛は本ルールと人間レビュー。変更が必要な場合は、変更案を提示して人間がエディタで直接編集する。
- **変更はセキュリティレビュー対象**: これらのパスへの変更を含む PR は、人間が差分を1行ずつ確認する。特に「遮断条件の緩和」「permissions.deny の削除」「新しい外部コマンド実行」に注意。
- **ADR 必須**: 変更の理由・検討した代替案を `docs/adr/` に記録する(`adr` スキル参照)。記録のない設定変更はロールバック対象。
- skills/ と agents/ の**内容**の編集は通常の開発対象(遮断されない)が、新スキル・新エージェントの既定化は `intake` スキルの判定を経る。
