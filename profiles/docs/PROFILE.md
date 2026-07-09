<!-- このファイルの目的: docsプロファイルの説明と展開マニフェスト。bootstrap.shが「## manifest」節をパースしてファイルを配置する。 -->

# docs プロファイル

Markdown 中心のナレッジ/ドキュメントリポジトリ(personal-os 型の知識ベース、議事録アーカイブ等)向けの雛形一式。
実行コードを持たないため、追加ツールは導入しない。**検証ゲートは構造チェック(`make structure`)のみ**で、規約を機械強制する。

## 含まれるもの

| 役割 | ファイル | 実装 |
|---|---|---|
| makeターゲット | `Makefile.profile` | test / lint / typecheck / arch を「対象外」と表示する明示スタブ(ゲートは structure) |
| 運用規約 | `README-profile.md` → `docs/conventions/stack-docs.md` | ルータREADME規約強化版+1トピック=1フォルダ+cockpit README 運用 |
| 構造チェック設定例 | `structure-config.example.md` → `docs/conventions/structure-config.example.md` | 役割フォルダのエントリREADME必須リストを `tools/check_structure.py` に追加する例 |

## 前提

- 追加のランタイム・依存なし(`python3` があれば `make check` が動く)

## 展開後の最初の一歩

1. `docs/conventions/stack-docs.md` を読み、役割フォルダ(例: `notes/` `topics/` `archive/`)を自分の用途に合わせて決める
2. 決めた役割フォルダを `tools/check_structure.py` の必須READMEリストに追加する(`docs/conventions/structure-config.example.md` の例に従う)
3. `make check` — 構造チェックが通ることを確認する

## manifest

以下は `tools/bootstrap.sh` が機械的にパースする対応表(`リポジトリルートからのdest: このディレクトリからのsource`)。
書式の契約は `profiles/README.md` を参照。この節はファイル末尾に置き、このフェンス以外のコードフェンスを本ファイルに置かないこと。

```
Makefile.profile: Makefile.profile
docs/conventions/stack-docs.md: README-profile.md
docs/conventions/structure-config.example.md: structure-config.example.md
```
