#!/usr/bin/env python3
"""このスクリプトはテンプレート/生成プロジェクトの構造とドキュメント予算を機械強制する番人。
散文の規約を CI とローカル hook(tools/githooks/pre-commit)で守らせるための単一の入口で、
`make structure` が呼ぶ。標準ライブラリのみ・Python 3.9+ 互換。

チェック項目:
  1. AGENTS.md の行数(<=200 hard / >150 warn)とバイト数(<=24576)
  2. CLAUDE.md の 1 行目に @AGENTS.md があること・全体 <=800 バイト
  3. 必須ルータ README(docs/README.md、profiles があれば profiles/README.md)
  4. 陳腐化参照の検出(STALE_PATTERNS。物理再編したら追記。初期は空)
  5. ルート直下の想定外ファイル検出(許可リスト方式)
  6. docs/governance/tech-radar.md(採否の根拠台帳)の存在
"""

import argparse
import os
import sys
from pathlib import Path

# ==== 予算・定数(docs/conventions/docs-rules.md の人間向け正本と一致させる) ====

AGENTS_MD_HARD_LINES = 200
AGENTS_MD_SOFT_LINES = 150
AGENTS_MD_HARD_BYTES = 24576  # 24 KiB
CLAUDE_MD_HARD_BYTES = 800

# ルート直下に存在してよい正規の項目。
# これは master-spec §2 の確定ファイルツリーのルート項目と一致させる「許可リストの正」。
ROOT_ALLOWED = {
    # 正本ドキュメント / 標準設定ファイル
    "AGENTS.md", "CLAUDE.md", "README.md", "Makefile", "LICENSE",
    ".editorconfig", ".gitignore", ".gitmessage", ".env.example", ".templatesyncignore",
    # ディレクトリ(各ワークストリームの担当)
    ".github", ".claude", ".gemini", ".cursor", "docs", "tools", "profiles",
    # プロファイル導入後 / エージェントローカルの正当な存在
    "Makefile.profile", "CLAUDE.local.md",
}

# 追加で許容する「正当だが可変」な項目。VCS・秘密・生成物・言語プロファイルが
# ルートへ配置する既知の設定ファイル群。gitignore 済みか bootstrap 後に現れるもので、
# stray file 検出の対象外にする(誤検出を避ける)。
ROOT_IGNORED_NAMES = {
    # VCS / OS / エディタ
    ".git", ".DS_Store", "Thumbs.db", ".idea", ".vscode",
    # 秘密 / 一時領域
    ".env", "secrets", "scratch",
    # 依存・ビルド生成物
    "node_modules", "dist", "build", "coverage", "htmlcov",
    ".venv", "venv", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache",
    ".import_linter_cache", ".coverage",
    # プロファイル展開後のプロジェクトが持つソース/テストディレクトリ
    "src", "tests",
    # typescript プロファイルがルートに置く設定
    "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock",
    "tsconfig.json", "biome.json", "biome.jsonc",
    "vitest.config.ts", "vitest.config.js",
    ".dependency-cruiser.cjs", ".dependency-cruiser.js",
    ".dependency-cruiser-known-violations.json",  # arch:baseline(freeze方式)の生成物
    # python プロファイルがルートに置く設定
    "pyproject.toml", "uv.lock", "setup.cfg", "ruff.toml", "mypy.ini",
    "pytest.ini", "tox.ini", ".importlinter",
    # 言語バージョン固定
    ".nvmrc", ".node-version", ".python-version", ".tool-versions",
}

# 陳腐化参照の検出に使う旧パスパターン(部分一致)。物理再編したら追記する。初期は空。
STALE_PATTERNS = []

# rglob 走査時にスキップするディレクトリ名。
_SKIP_DIR_PARTS = {
    ".git", "node_modules", ".venv", "venv", "__pycache__",
    ".pytest_cache", ".mypy_cache", ".ruff_cache", ".import_linter_cache",
    "dist", "build", "scratch",
}


# ==== ユーティリティ ====

def _read_bytes(path):
    with open(path, "rb") as fh:
        return fh.read()


def _line_count(text):
    return len(text.splitlines())


def _root_ignored(name):
    """ルート直下の name が「正当だが可変」なら True。"""
    if name in ROOT_IGNORED_NAMES:
        return True
    if name.startswith(".env."):  # .env.local など秘密系
        return True
    if name.endswith(".egg-info"):
        return True
    return False


def _in_ignored_dir(path, root):
    rel = path.relative_to(root)
    return any(part in _SKIP_DIR_PARTS for part in rel.parts)


# ==== 個別チェック(各々 (severity, message) の list を返す。severity in {"error","warn"}) ====

def check_agents_md(root):
    problems = []
    path = root / "AGENTS.md"
    if not path.is_file():
        return [("error", "AGENTS.md がルートに存在しません(正本ルールの本体)。")]
    data = _read_bytes(path)
    text = data.decode("utf-8", errors="replace")
    n_lines = _line_count(text)
    n_bytes = len(data)
    if n_lines > AGENTS_MD_HARD_LINES:
        problems.append(("error",
            "AGENTS.md が %d 行(ハード上限 %d 行)。詳細を docs/ か .claude/skills/ へ逃がす。"
            % (n_lines, AGENTS_MD_HARD_LINES)))
    elif n_lines > AGENTS_MD_SOFT_LINES:
        problems.append(("warn",
            "AGENTS.md が %d 行(ソフト目安 %d 行)。段階開示で外部化を検討。"
            % (n_lines, AGENTS_MD_SOFT_LINES)))
    if n_bytes > AGENTS_MD_HARD_BYTES:
        problems.append(("error",
            "AGENTS.md が %d バイト(ハード上限 %d バイト)。" % (n_bytes, AGENTS_MD_HARD_BYTES)))
    return problems


def check_claude_md(root):
    problems = []
    path = root / "CLAUDE.md"
    if not path.is_file():
        return [("error", "CLAUDE.md がルートに存在しません(AGENTS.md へのポインタ)。")]
    data = _read_bytes(path)
    text = data.decode("utf-8", errors="replace")
    n_bytes = len(data)
    lines = text.splitlines()
    first_line = lines[0] if lines else ""
    if "@AGENTS.md" not in first_line:
        problems.append(("error",
            "CLAUDE.md の 1 行目に @AGENTS.md がありません(現在: %r)。" % first_line))
    if n_bytes > CLAUDE_MD_HARD_BYTES:
        problems.append(("error",
            "CLAUDE.md が %d バイト(上限 %d バイト)。ポインタに徹する。"
            % (n_bytes, CLAUDE_MD_HARD_BYTES)))
    return problems


def check_router_readmes(root):
    problems = []
    if not (root / "docs" / "README.md").is_file():
        problems.append(("error", "docs/README.md(ルータ)が存在しません。"))
    # profiles/ が残っている状態(テンプレート = bootstrap 前)では profiles/README.md も必須。
    # bootstrap 後は profiles/ ごと削除されるため、存在時のみ要求する。
    if (root / "profiles").is_dir():
        if not (root / "profiles" / "README.md").is_file():
            problems.append(("error", "profiles/README.md(プロファイル説明)が存在しません。"))
    return problems


def check_tech_radar(root):
    if not (root / "docs" / "governance" / "tech-radar.md").is_file():
        return [("error", "docs/governance/tech-radar.md(採否の根拠台帳)が存在しません。")]
    return []


def check_stale_refs(root, patterns=None):
    if patterns is None:
        patterns = STALE_PATTERNS
    problems = []
    if not patterns:
        return problems
    for md in sorted(root.rglob("*.md")):
        if _in_ignored_dir(md, root):
            continue
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        rel = md.relative_to(root)
        for pat in patterns:
            if pat in text:
                problems.append(("error",
                    "陳腐化参照: %s に旧パターン %r が残っています。" % (rel, pat)))
    return problems


def check_root_allowlist(root):
    problems = []
    for entry in sorted(os.listdir(root)):
        if entry in ROOT_ALLOWED:
            continue
        if _root_ignored(entry):
            continue
        problems.append(("error",
            "ルート直下に想定外の項目: %s(許可リスト外)。"
            "設置場所を見直すか、正当なら check_structure.py の許可リストを更新。" % entry))
    return problems


def check_repo(root):
    """リポジトリルートに全チェックを適用し (severity, message) の list を返す。"""
    root = Path(root)
    problems = []
    problems += check_agents_md(root)
    problems += check_claude_md(root)
    problems += check_router_readmes(root)
    problems += check_tech_radar(root)
    problems += check_stale_refs(root)
    problems += check_root_allowlist(root)
    return problems


# ==== CLI ====

def _default_root():
    # tools/check_structure.py の 1 つ上の階層がリポジトリルート。
    return Path(__file__).resolve().parent.parent


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="構造・ドキュメント予算の機械強制チェック(make structure が呼ぶ)")
    parser.add_argument("--root", default=None,
        help="検査するリポジトリルート(既定: このスクリプトの 1 つ上)")
    parser.add_argument("--quiet", action="store_true",
        help="警告と成功メッセージを抑制し、エラーのみ表示する")
    args = parser.parse_args(argv)

    root = Path(args.root).resolve() if args.root else _default_root()
    if not root.is_dir():
        print("ERROR: 検査対象が見つかりません: %s" % root, file=sys.stderr)
        return 1

    problems = check_repo(root)
    errors = [m for (s, m) in problems if s == "error"]
    warns = [m for (s, m) in problems if s == "warn"]

    for m in errors:
        print("ERROR: " + m, file=sys.stderr)
    if not args.quiet:
        for m in warns:
            print("WARN : " + m, file=sys.stderr)

    if errors:
        if not args.quiet:
            print("check_structure: %d 件のエラー。修正が必要です。" % len(errors),
                  file=sys.stderr)
        return 1
    if not args.quiet:
        msg = "check_structure: OK"
        if warns:
            msg += "(警告 %d 件)" % len(warns)
        print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
