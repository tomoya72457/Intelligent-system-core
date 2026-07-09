<!-- このファイルの目的: typescriptプロファイルの説明と展開マニフェスト。bootstrap.shが「## manifest」節をパースしてファイルを配置する。 -->

# typescript プロファイル

TypeScript/Node.js アプリケーション(Webアプリ・API・CLI)向けの雛形一式。

## 含まれるもの

| 役割 | ファイル | 実装 |
|---|---|---|
| テスト | `vitest.config.ts` | vitest(`*.test.ts` を実装の隣に置く) |
| リント+フォーマット | `biome.json` | biome(`biome check .` / `biome format --write .`) |
| 型チェック | `tsconfig.json` | tsc `--noEmit`(strict) |
| 依存境界 | `.dependency-cruiser.cjs` | dependency-cruiser(`app → features → core` 一方向+循環禁止) |
| makeターゲット | `Makefile.profile` | ルートMakefileが `-include` し、test / lint / typecheck / arch を有効化 |
| 最小実例 | `src/` 4ファイル | 層境界を示すサンプルコード+テスト1本 |
| 規約 | `README-profile.md` → `docs/conventions/stack-typescript.md` | このプロファイルの規約1ページ |

## 前提

- Node.js 24 以上(2026-07時点のアクティブLTS)
- 展開後に `npm install` を実行して devDependencies を導入する

## 展開後の最初の一歩

1. `npm install` — devDependencies を導入する
2. `make check` — structure + test + lint + typecheck + arch が全て走ることを確認する

サンプルコード(`src/core/` `src/features/` `src/app/`)は層境界の実例。最初の実装に置き換えてよいが、層構成と `.dependency-cruiser.cjs` のルールは維持すること(変更するなら ADR に記録)。

## manifest

以下は `tools/bootstrap.sh` が機械的にパースする対応表(`リポジトリルートからのdest: このディレクトリからのsource`)。
書式の契約は `profiles/README.md` を参照。この節はファイル末尾に置き、このフェンス以外のコードフェンスを本ファイルに置かないこと。

```
Makefile.profile: Makefile.profile
package.json: package.json
tsconfig.json: tsconfig.json
biome.json: biome.json
vitest.config.ts: vitest.config.ts
.dependency-cruiser.cjs: .dependency-cruiser.cjs
src/core/money.ts: src/core/money.ts
src/features/pricing/discount.ts: src/features/pricing/discount.ts
src/features/pricing/discount.test.ts: src/features/pricing/discount.test.ts
src/app/main.ts: src/app/main.ts
docs/conventions/stack-typescript.md: README-profile.md
```
