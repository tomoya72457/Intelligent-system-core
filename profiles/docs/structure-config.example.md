<!-- このファイルの目的: 役割フォルダのエントリREADMEを構造チェックで必須化する設定例。bootstrap時に docs/conventions/structure-config.example.md として配置される。 -->

# 構造チェック設定例: 役割フォルダのエントリREADME必須化

`tools/check_structure.py` は必須ルータREADMEの存在を機械強制する(既定は `docs/README.md`)。
docs プロファイルでは、自分で決めた**役割フォルダのエントリREADME**も同様に必須化して運用する。
本ページはそのための設定例(スクリプトへ追加する必須リストの値)。

## 手順

1. 役割フォルダ構成を決める(例: `topics/` `notes/` `archive/`。規約: `docs/conventions/stack-docs.md`)
2. `tools/check_structure.py` の設定セクション(`ROOT_ALLOWED` 等の定数群の並び)に、下記の必須READMEリスト定数を追加し、必須README検査(既定で `docs/README.md` を見ている箇所)から参照させる
3. 役割フォルダをルート許可リスト(`ROOT_ALLOWED`)にも追加する(ルート直下の想定外項目として誤検出されないため)
4. `make structure` を実行し、README 未作成のフォルダが検出されること(=強制が効いていること)を確認してから README を書く

## 追加する値の例

役割フォルダを `topics/` `notes/` `archive/` とした場合(パスはリポジトリルートからの相対):

```python
# 役割フォルダのエントリREADME(ルータ)。存在しなければ make structure を失敗させる。
REQUIRED_ROUTER_READMES = [
    "topics/README.md",
    "notes/README.md",
    "archive/README.md",
]
```

あわせて `ROOT_ALLOWED` に `"topics", "notes", "archive"` を追加する。

## 注意

- `tools/check_structure.py` の変更は通常の PR レビュー対象(エージェント設定ファイルとは異なり自己編集禁止ではないが、チェックを弱める方向の変更は ADR に理由を残す)。
- 役割フォルダを増やす・改名するときは、リスト更新と README 作成を同じ PR で行う(`make structure` が緑のままフォルダだけ増える状態を作らない)。
- 各トピックフォルダ(`topics/<slug>/README.md`)までは必須化しない。第一階層の役割フォルダだけを機械強制し、深い階層はレビューで守る(チェックの維持コストを一定に保つ)。
