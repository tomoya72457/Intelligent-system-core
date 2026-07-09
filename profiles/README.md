<!-- このファイルの目的: profiles/ の仕組み(展開とマニフェスト契約)を説明するルータ文書。各プロファイルの比較表を提供する。 -->

# profiles/ — プロファイルの仕組み

`profiles/` は、このテンプレートを新規プロジェクトへ適用するときに選ぶ「スタック別の雛形一式」を置く場所。
`tools/bootstrap.sh` が選択されたプロファイル1つを展開してリポジトリルートへ配置し、**展開後に `profiles/` ディレクトリ自体を削除する**。
最終的なプロジェクトのリポジトリに `profiles/` は残らない。

## 展開の流れ

1. `bootstrap.sh` がプロジェクト名・目的・プロファイル(`typescript` / `python` / `docs`)を確定する
2. `{{PROJECT_NAME}}` `{{PROJECT_PURPOSE}}` プレースホルダを実値へ置換する
3. `profiles/<選択したプロファイル>/PROFILE.md` の `## manifest` 節を読み、記載された全ファイルをリポジトリルートへコピーする
4. `profiles/` ディレクトリを削除する

そのため **profiles/ 配下のファイルは、このテンプレートリポジトリ自体の `make check` 対象外**。
生成時点でのJSON/TOML/YAML構文検証と、サンプルコードの構文チェックのみを行っている(§7品質基準)。

## manifest 契約(bootstrap.sh との結合点)

各 `profiles/<name>/PROFILE.md` は `## manifest` という見出しを持ち、その直後に1つのコードフェンス(\`\`\`)を置く。
`bootstrap.sh` はこのコードフェンスの中身だけを機械的にパースする。書式は以下に**厳密に**従うこと。

- 1行1ファイル。`<dest_path>: <source_path>` の形式(コロン1つ+半角スペース1つで区切る)
- `dest_path` … リポジトリルートからの相対パス(先頭に `/` や `./` を付けない)
- `source_path` … その `profiles/<name>/` ディレクトリからの相対パス(同上)
- ディレクトリ丸ごとやglobは書かない。ファイル単位で列挙する
- コードフェンス内にコメントや空行以外の余計な行を混ぜない(空行は無視してよい)
- `## manifest` 節のコードフェンスはその1個のみ(2個目以降があると未定義動作)

例:

```
docs/conventions/stack-typescript.md: README-profile.md
src/core/money.ts: src/core/money.ts
```

## プロファイル比較

| プロファイル | 対象 | 主要ツール | レイヤ契約 | 適用シーン例 |
|---|---|---|---|---|
| [`typescript/`](./typescript/PROFILE.md) | TypeScript/Node.jsアプリケーション | biome / vitest / tsc / dependency-cruiser | `app → features → core`(一方向) | SEOダッシュボード等のWebアプリ・API |
| [`python/`](./python/PROFILE.md) | Pythonアプリケーション・CLI・自動化 | uv / ruff / mypy / pytest / import-linter | `api → services → models`(一方向) | バックエンドサービス、自動化スクリプト、議事録ツールの処理系 |
| [`docs/`](./docs/PROFILE.md) | Markdown中心のナレッジ/ドキュメントリポジトリ | (追加ツールなし。構造規約のみ) | ルータREADME必須構造 | personal-os型の知識ベース、議事録アーカイブ |

いずれのプロファイルも以下を共通して行う:

- リポジトリルートに `Makefile.profile` を配置する。ルートの `Makefile` が `-include Makefile.profile` するため、`make test` / `make lint` / `make typecheck` / `make arch` が有効になる(プロファイルは4ターゲット全てを定義するのが契約。ルート側の「未導入」案内は Makefile.profile が無い時のみ働く)
- プロファイル固有の規約文書を `docs/conventions/stack-<name>.md` として配置する(正本はテンプレート同梱時点では `profiles/<name>/README-profile.md`)

## 制約・注意

- **1回のbootstrap実行で選べるプロファイルは1つ**。`Makefile.profile` はルート直下の単一ファイルとして展開されるため、複数プロファイルを同時展開すると衝突する。複数スタックを1リポジトリで扱う場合は、展開後に手動で `Makefile.profile` の内容をマージすること
- プレースホルダは `{{PROJECT_NAME}}` `{{PROJECT_PURPOSE}}` の2種類のみ(マスター仕様書§3)。プロファイル側で新しいプレースホルダを増やさない
- 新規プロファイルを追加する場合は、既存3プロファイルと同じ構成(`PROFILE.md` + `## manifest` + `Makefile.profile` + `README-profile.md`)に揃え、`docs/governance/tech-radar.md` に採用根拠を残すこと(原則10: 判定を経ない既定変更禁止)
