#!/usr/bin/env python3
"""このファイルは check_structure.py の自己テスト。
tmp に合成リポジトリを作り、各チェックの「検出(fault injection)」と「通過」を検証する。
実行: python3 tools/test_check_structure.py  (標準ライブラリ unittest のみ)。"""

import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_structure as cs  # noqa: E402


def write(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def make_valid_repo(root):
    """全チェックを通過する最小の合成リポジトリを作る(profiles/ は無し)。"""
    root = Path(root)
    write(root / "AGENTS.md", "# AGENTS\n\n最小の正本。\n")
    write(root / "CLAUDE.md", "@AGENTS.md\n\nポインタのみ。\n")
    write(root / "docs" / "README.md", "# docs ルータ\n")
    write(root / "docs" / "governance" / "tech-radar.md", "# tech radar\n")
    return root


class CheckStructureTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.root = make_valid_repo(self.tmp)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def errors(self, problems):
        return [m for (s, m) in problems if s == "error"]

    def warns(self, problems):
        return [m for (s, m) in problems if s == "warn"]

    # --- 通過 ---
    def test_valid_repo_passes(self):
        problems = cs.check_repo(self.root)
        self.assertEqual(self.errors(problems), [], msg=str(problems))
        self.assertEqual(self.warns(problems), [], msg=str(problems))

    # --- AGENTS.md ---
    def test_agents_md_missing(self):
        (self.root / "AGENTS.md").unlink()
        self.assertTrue(any("AGENTS.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_agents_md_too_many_lines(self):
        write(self.root / "AGENTS.md", "x\n" * 201)
        self.assertTrue(any("行" in m for m in self.errors(cs.check_repo(self.root))))

    def test_agents_md_soft_warn_only(self):
        write(self.root / "AGENTS.md", "x\n" * 160)  # >150 soft, <200 hard, 小バイト
        problems = cs.check_repo(self.root)
        self.assertEqual(self.errors(problems), [], msg=str(problems))
        self.assertGreaterEqual(len(self.warns(problems)), 1)

    def test_agents_md_too_many_bytes(self):
        write(self.root / "AGENTS.md", "x" * 25000 + "\n")  # 1 行だがバイト超過
        self.assertTrue(any("バイト" in m for m in self.errors(cs.check_repo(self.root))))

    # --- CLAUDE.md ---
    def test_claude_md_missing(self):
        (self.root / "CLAUDE.md").unlink()
        self.assertTrue(any("CLAUDE.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_claude_md_missing_pointer(self):
        write(self.root / "CLAUDE.md", "ポインタが無い\n")
        self.assertTrue(any("@AGENTS.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_claude_md_too_big(self):
        write(self.root / "CLAUDE.md", "@AGENTS.md\n" + "x" * 900)
        self.assertTrue(any("バイト" in m for m in self.errors(cs.check_repo(self.root))))

    # --- ルータ README / tech-radar ---
    def test_docs_readme_missing(self):
        (self.root / "docs" / "README.md").unlink()
        self.assertTrue(any("docs/README.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_tech_radar_missing(self):
        (self.root / "docs" / "governance" / "tech-radar.md").unlink()
        self.assertTrue(any("tech-radar.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_profiles_without_readme(self):
        (self.root / "profiles").mkdir()
        self.assertTrue(
            any("profiles/README.md" in m for m in self.errors(cs.check_repo(self.root))))

    def test_profiles_with_readme_passes(self):
        write(self.root / "profiles" / "README.md", "# profiles\n")
        self.assertEqual(self.errors(cs.check_repo(self.root)), [])

    # --- ルート許可リスト ---
    def test_root_stray_file_flagged(self):
        write(self.root / "notes.txt", "stray\n")
        self.assertTrue(any("notes.txt" in m for m in self.errors(cs.check_repo(self.root))))

    def test_root_ignored_artifacts_ok(self):
        (self.root / "node_modules").mkdir()
        (self.root / ".import_linter_cache").mkdir()  # make arch(import-linter)が生成
        (self.root / "src").mkdir()    # プロファイル展開後のソース/テストも許可
        (self.root / "tests").mkdir()
        write(self.root / "package.json", "{}\n")
        write(self.root / ".env.local", "SECRET=x\n")
        self.assertEqual(self.errors(cs.check_repo(self.root)), [])

    def test_root_allowed_makefile_profile_ok(self):
        write(self.root / "Makefile.profile", "test:\n\t@echo hi\n")
        self.assertEqual(self.errors(cs.check_repo(self.root)), [])

    # --- 陳腐化参照 ---
    def test_stale_pattern_detected(self):
        write(self.root / "docs" / "old.md", "参照: src/legacy/foo を見よ\n")
        problems = cs.check_stale_refs(self.root, patterns=["src/legacy/"])
        self.assertTrue(any("陳腐化" in m for (s, m) in problems))

    def test_stale_empty_patterns_noop(self):
        write(self.root / "docs" / "old.md", "参照: src/legacy/foo\n")
        self.assertEqual(cs.check_stale_refs(self.root, patterns=[]), [])

    def test_stale_skips_ignored_dirs(self):
        write(self.root / "node_modules" / "pkg" / "readme.md", "src/legacy/foo\n")
        problems = cs.check_stale_refs(self.root, patterns=["src/legacy/"])
        self.assertEqual(problems, [])

    # --- CLI 終了コード ---
    def test_main_returns_zero_on_valid(self):
        self.assertEqual(cs.main(["--root", str(self.root), "--quiet"]), 0)

    def test_main_returns_one_on_error(self):
        (self.root / "AGENTS.md").unlink()
        self.assertEqual(cs.main(["--root", str(self.root), "--quiet"]), 1)


if __name__ == "__main__":
    unittest.main()
