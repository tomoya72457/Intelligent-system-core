<!-- このファイルの目的: python venv を iCloud 外へ退避する判定記録。規約「ミスは2回目で機械強制化」の初適用例。 -->

# 判定: python venv の iCloud 外退避(UV_PROJECT_ENVIRONMENT)

- 日付: 2026-07-09 / 判定: **Adopt**(python プロファイル) / 再審査: 2027-07-09
- 可逆性: 可逆(Makefile.profile の 2 行。撤去すれば従来どおり)

## 提案
iCloud Drive 配下のリポジトリでは `.venv` が同期により破損する。`UV_PROJECT_ENVIRONMENT` を
`~/.venvs/<ディレクトリ名>` に設定し、venv をリポジトリ外(iCloud 外)へ置く。

## 賛成論
1. 実測: webcreate-engine で同日 2 回、site 処理レベルの破損(import 不能)が発生し、venv 再作成でのみ復旧した。
2. 検証ループ(make check)の信頼性に直結する。壊れる venv はテンプレートの中核価値を毀損する。
3. 維持コストほぼゼロ・利用者に透明(make 経由なら意識不要)。

## 反対論
1. `uv run` を make を経ずに直接使う場合は env 変数を自分で設定する必要がある(コメントで案内済み)。
2. エディタ(VS Code 等)の interpreter 自動検出が `.venv` を前提にしている場合、手動指定が要る。
3. エビデンスは自前実測+実践者報告レベル(E=3)で、査読級ではない。

## 採点
| E | G | A | M | C | W |
|---|---|---|---|---|---|
| 3 | 2.5 | 4 | 5 | 5 | 3.65 |

W=3.65 は単独では Trial 帯。ただし規約「**同じミスは 2 回目で機械強制化**」(AGENTS.md)の発動条件を
同日 2 回の実障害で満たしたため、規約駆動で Adopt とする(拒否権該当なし)。

## 実装
`profiles/python/Makefile.profile`(空白入りパス対応のため `$(shell basename "$(CURDIR)")` を使用。
`$(notdir $(CURDIR))` は空白で分割される罠がある)。事故記録: webcreate-engine
`docs/incidents/2026-07-09-icloud-venv-corruption.md`。
