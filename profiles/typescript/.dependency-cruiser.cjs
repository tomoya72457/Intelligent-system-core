// このファイルの目的: 依存境界の適応度関数(dependency-cruiser)。
// 層契約「app → features → core の一方向+循環禁止」を機械強制する。
// 実行: `npm run arch`(= depcruise src --config)。CI では make arch 経由でブロッキング。
//
// ── 層の意味 ─────────────────────────────────────────────
//   src/app/      合成ルート。副作用・エントリポイント。何にでも依存してよい
//   src/features/ 機能単位のロジック。core にのみ依存できる(app・他featureへの依存は禁止)
//   src/core/     純粋なドメイン・共有基盤。上位層に依存しない(shared という名前でも同じ扱い)
// 層を変更・追加する場合は本ファイルのルールを更新し、ADR に記録すること。
//
// ── freeze / baseline 方式(既存コードへの後付け) ────────────
// 違反が既にあるコードベースに導入する場合、現状の違反を「既知」として凍結し、
// 新規違反だけをブロックできる:
//   1. `npm run arch:baseline`
//      → 現在の全違反を .dependency-cruiser-known-violations.json に記録(コミットする)
//   2. package.json の "arch" スクリプトに `--ignore-known` を追記
//      → 既知の違反は無視され、新しい違反のみ fail する
//   3. 返済したら baseline を再生成して縮める(増やす方向の再生成は禁止)
// 参考: dependency-cruiser 公式 doc/cli.md の --ignore-known / --output-type baseline。

/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      comment: "循環依存の禁止。循環は変更影響の予測を不可能にする(全層共通)",
      from: {},
      to: { circular: true },
    },
    {
      name: "features-not-to-app",
      severity: "error",
      comment: "features は app(合成ルート)に依存できない。依存方向は app → features の一方向",
      from: { path: "^src/features" },
      to: { path: "^src/app" },
    },
    {
      name: "no-cross-feature",
      severity: "error",
      comment:
        "feature 同士は直接依存できない。共有したいコードは core へ降ろす(feature間の暗黙結合防止)",
      from: { path: "^src/features/([^/]+)/" },
      to: { path: "^src/features/([^/]+)/", pathNot: "^src/features/$1/" },
    },
    {
      name: "core-stays-pure",
      severity: "error",
      comment: "core / shared は最下層。上位層(app・features)に依存してはならない",
      from: { path: "^src/(core|shared)" },
      to: { path: "^src/(app|features)" },
    },
    {
      name: "no-orphans",
      severity: "warn",
      comment: "どこからも参照されないモジュールの検出(消し忘れ・デッドコードの疑い)。警告のみ",
      from: {
        orphan: true,
        pathNot: ["\\.d\\.ts$", "\\.test\\.ts$", "(^|/)\\.", "^src/app/main\\.ts$"],  // main.ts はエントリポイント(参照元なしが正常)
      },
      to: {},
    },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsConfig: { fileName: "tsconfig.json" },
    tsPreCompilationDeps: true,
    exclude: { path: "\\.test\\.ts$" },
  },
};
