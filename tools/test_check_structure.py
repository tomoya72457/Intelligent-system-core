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
    write(root / "docs" / "README.md",
          "# docs ルータ\n\n| したいこと | 読むファイル |\n|---|---|\n"
          "| 採否の台帳を見たい | `docs/governance/tech-radar.md` |\n")
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

    # --- Markdown リンク実在検証(ADR-0008) ---
    def test_md_link_broken_detected(self):
        write(self.root / "docs" / "x.md", "[参照](missing.md)\n")
        self.assertTrue(any("リンク切れ" in m for m in self.errors(cs.check_repo(self.root))))

    def test_md_link_valid_passes(self):
        write(self.root / "docs" / "y.md", "# 本文\n")
        write(self.root / "docs" / "x.md", "[参照](y.md)\n")
        errors = [m for m in self.errors(cs.check_repo(self.root)) if "リンク切れ" in m]
        self.assertEqual(errors, [])

    def test_md_link_external_anchor_placeholder_skipped(self):
        write(self.root / "docs" / "x.md",
              "[a](https://example.com/p.md) [b](#sec) [c](mailto:x@y.z)\n"
              "[d]({{VAR}}/x.md) [e](tel:0312345678)\n")
        errors = [m for m in self.errors(cs.check_repo(self.root)) if "リンク切れ" in m]
        self.assertEqual(errors, [])

    def test_md_link_inside_code_skipped(self):
        write(self.root / "docs" / "x.md",
              "```\n[a](missing.md)\n```\n本文 `[b](missing2.md)` の例\n")
        errors = [m for m in self.errors(cs.check_repo(self.root)) if "リンク切れ" in m]
        self.assertEqual(errors, [])

    def test_md_link_fragment_stripped(self):
        write(self.root / "docs" / "y.md", "# 見出し\n")
        write(self.root / "docs" / "x.md", "[参照](y.md#見出し)\n")
        errors = [m for m in self.errors(cs.check_repo(self.root)) if "リンク切れ" in m]
        self.assertEqual(errors, [])

    def test_md_link_absolute_path_flagged(self):
        write(self.root / "docs" / "x.md", "[a](/etc/hosts)\n")
        self.assertTrue(any("絶対パス" in m for m in self.errors(cs.check_repo(self.root))))

    # --- ADR ↔ INDEX 同期(ADR-0008) ---
    def test_adr_missing_from_index_flagged(self):
        write(self.root / "docs" / "adr" / "INDEX.md", "# ADR 一覧\n")
        write(self.root / "docs" / "adr" / "0001-first.md", "# ADR-0001\n")
        self.assertTrue(any("索引漏れ" in m for m in self.errors(cs.check_repo(self.root))))

    def test_adr_in_index_passes(self):
        write(self.root / "docs" / "adr" / "INDEX.md", "# ADR 一覧\n[0001](0001-first.md)\n")
        write(self.root / "docs" / "adr" / "0001-first.md", "# ADR-0001\n")
        errors = [m for m in self.errors(cs.check_repo(self.root)) if "索引漏れ" in m]
        self.assertEqual(errors, [])

    def test_adr_without_index_file_flagged(self):
        write(self.root / "docs" / "adr" / "0001-first.md", "# ADR-0001\n")
        self.assertTrue(
            any("INDEX.md" in m for m in self.errors(cs.check_repo(self.root))))

    # --- ルータ到達可能性(ADR-0008、Trial: warn) ---
    def test_router_uncovered_doc_warns_not_errors(self):
        write(self.root / "docs" / "playbooks" / "foo.md", "# foo\n")
        problems = cs.check_repo(self.root)
        self.assertTrue(any("ルータ未掲載" in m for m in self.warns(problems)))
        self.assertEqual([m for m in self.errors(problems) if "ルータ未掲載" in m], [])

    def test_router_covered_doc_passes(self):
        write(self.root / "docs" / "README.md",
              "# docs ルータ\n`docs/governance/tech-radar.md`\n`docs/playbooks/foo.md`\n")
        write(self.root / "docs" / "playbooks" / "foo.md", "# foo\n")
        warns = [m for m in self.warns(cs.check_repo(self.root)) if "ルータ未掲載" in m]
        self.assertEqual(warns, [])

    def test_router_ledger_dir_exempts_files(self):
        write(self.root / "docs" / "README.md",
              "# docs ルータ\n`docs/governance/tech-radar.md`\n`docs/governance/intake/`\n")
        write(self.root / "docs" / "governance" / "intake" / "2026-01-01-x.md", "# x\n")
        warns = [m for m in self.warns(cs.check_repo(self.root)) if "ルータ未掲載" in m]
        self.assertEqual(warns, [])

    def test_router_unrouted_ledger_dir_warns(self):
        write(self.root / "docs" / "governance" / "intake" / "2026-01-01-x.md", "# x\n")
        self.assertTrue(
            any("governance/intake" in m for m in self.warns(cs.check_repo(self.root))))

    def test_router_structure_files_skipped(self):
        write(self.root / "docs" / "conventions" / "TEMPLATE.md", "# 雛形\n")
        warns = [m for m in self.warns(cs.check_repo(self.root)) if "ルータ未掲載" in m]
        self.assertEqual(warns, [])

    # --- CLI 終了コード ---
    def test_main_returns_zero_on_valid(self):
        self.assertEqual(cs.main(["--root", str(self.root), "--quiet"]), 0)

    def test_main_returns_one_on_error(self):
        (self.root / "AGENTS.md").unlink()
        self.assertEqual(cs.main(["--root", str(self.root), "--quiet"]), 1)


if __name__ == "__main__":
    unittest.main()
