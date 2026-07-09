"""層境界サンプル(中間層 services)。models にのみ依存できる。

api への import は pyproject.toml の layers 契約違反となり、make arch が遮断する。
"""

from __future__ import annotations

from app.models import Task


def complete_task(task: Task) -> Task:
    """タスクを完了状態にした新しい Task を返す。

    完了済みタスクの再完了はフェイルファストで拒否する(黙って握り潰さない)。
    """
    if task.done:
        raise ValueError(f"完了済みタスクは再完了できない: {task.title}")
    return Task(title=task.title, done=True)
