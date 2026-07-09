"""層境界サンプル(最下層 models)。他層に依存しないデータ構造だけを置く。

最初の実装に置き換えてよいが、「models は api / services に依存しない」契約は維持する。
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Task:
    """1件のタスク。不変(frozen)にして状態遷移を関数の戻り値で表す。"""

    title: str
    done: bool = False
