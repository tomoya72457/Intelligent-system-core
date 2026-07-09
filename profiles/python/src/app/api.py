"""層境界サンプル(最上層 api)。外部との境界。services を呼び出し、外部向けの形に変換する。

HTTP ハンドラや CLI エントリポイントはこの層に置く。ロジックは services へ、データ構造は models へ。
"""

from __future__ import annotations

from app.models import Task
from app.services import complete_task


def complete_task_endpoint(title: str) -> dict[str, object]:
    """タスク完了APIの入口に相当する関数。外部表現(dict)への変換だけを担う。"""
    task = complete_task(Task(title=title))
    return {"title": task.title, "done": task.done}
