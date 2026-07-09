"""テストの置き方サンプル。tests/ 配下に test_*.py として置く(pytest が収集する)。

mypy の対象でもあるため、テスト関数にも型注釈(-> None)を付ける。
"""

from __future__ import annotations

import pytest

from app.models import Task
from app.services import complete_task


def test_complete_task_marks_done() -> None:
    task = complete_task(Task(title="仕様書を読む"))
    assert task.done is True
    assert task.title == "仕様書を読む"


def test_complete_task_rejects_already_done() -> None:
    done_task = Task(title="完了済み", done=True)
    with pytest.raises(ValueError):
        complete_task(done_task)
