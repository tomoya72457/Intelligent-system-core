<!-- このファイルの目的: typescriptプロファイルの規約1ページ。bootstrap時に docs/conventions/stack-typescript.md として配置される。 -->

# スタック規約: TypeScript

このプロジェクトは Intelligent-system-core テンプレートの typescript プロファイルで初期化されている。
共通規約は `AGENTS.md` と `docs/conventions/` が正本。本ページはスタック固有の差分だけを定める。

## コマンド(make が正面玄関)

| make | 実体(package.json scripts) | 役割 |
|---|---|---|
| `make test` | `vitest run` | テスト |
| `make lint` | `biome check .` | リント+フォーマット検査 |
| `make format` | `biome format --write .` | フォーマット適用 |
| `make typecheck` | `tsc --noEmit` | 型チェック(strict) |
| `make arch` | `depcruise src --config` | 依存境界の検証 |

`make check` は上記すべて+構造チェックを一括実行する。CI もこれを回す。scripts を変えるときは `Makefile.profile` との対応を崩さないこと。

## 層構成(依存は下向き一方向のみ)

| 層 | 置くもの | 依存してよい先 |
|---|---|---|
| `src/app/` | 合成ルート。エントリポイント・副作用(CLI/HTTP/env) | features, core |
| `src/features/<name>/` | 機能単位のロジック。feature 同士は直接依存禁止 | core のみ |
| `src/core/` | 純粋なドメイン・共有基盤(`shared/` も同格) | なし(最下層) |

- 強制装置は `.dependency-cruiser.cjs`(循環禁止・上向き依存禁止・feature間直接依存禁止・orphan警告)。
- feature 間で共有したいコードは core へ降ろす。層の追加・変更はルール更新+ADR記録とセットで行う。
- 既存コードへ後付けする場合の freeze/baseline 手順は `.dependency-cruiser.cjs` 冒頭コメントに記載(`npm run arch:baseline` → `--ignore-known`)。

## テスト規約

- テストは実装ファイルの隣に `*.test.ts` を置く(vitest が `src/**/*.test.ts` を収集)。
- テストファイルは依存境界検査から除外済み(テストは層を跨いで検証してよい)。
- カバレッジ床は Trial(オプトイン)。有効化手順は `vitest.config.ts` のコメント参照。

## バージョン方針(2026-07時点)

- Node.js 24(アクティブLTS)以上。`package.json` の `engines` で宣言。
- TypeScript は 6.0 系(JS実装の最終安定系)に固定。ネイティブ移植の TypeScript 7.0 は 2026-07-08 GA 直後のため既定にしない。移行は adoption-judge の判定(`docs/governance/rubric.md`)を経てから行う。
- 依存更新は dependabot(cooldown 7日)に任せ、手動で先回りしない。

## 注意

- `package.json` の `name` は bootstrap がプロジェクト名で置換する。npm の命名規則(小文字・空白なし)に合わない場合は手で修正する(`private: true` なので公開要件はない)。
- release-please(リリース自動化)は Trial 判定。ライブラリ的プロジェクトの場合のみ検討し、導入は adoption-judge を経る(`docs/governance/tech-radar.md` 参照)。
