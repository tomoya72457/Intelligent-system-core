// このファイルの目的: vitestの設定。テストは実装ファイルの隣に *.test.ts として置く。
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["src/**/*.test.ts"],
    // カバレッジ床(Trial判定・オプトイン。docs/governance/tech-radar.md 参照)。
    // 数値ゲーム化のリスクがあるため既定では無効。有効化するには
    // `npm i -D @vitest/coverage-v8` の上で以下のコメントを外し、床は現状実測値から始める。
    // coverage: {
    //   provider: "v8",
    //   thresholds: { lines: 70, functions: 70, branches: 70, statements: 70 },
    // },
  },
});
