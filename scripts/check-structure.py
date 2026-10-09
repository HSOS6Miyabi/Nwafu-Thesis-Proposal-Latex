#!/usr/bin/env python3
"""Validate the proposal's public chapter hierarchy and compiled contents."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
STRUCTURE = {
    "01-basis": [
        ("chapter", "选题依据"),
        ("section", "选题背景及意义"),
        ("section", "理论与技术依据"),
        ("subsection", "理论依据"),
        ("subsection", "技术依据"),
        ("section", "国内外研究现状"),
        ("subsection", "研究方向一的研究进展"),
        ("subsection", "研究方向二的研究进展"),
        ("subsection", "研究方向三的研究进展"),
    ],
    "02-research": [
        ("chapter", "研究内容及拟解决的关键问题"),
        ("section", "研究内容"),
        ("subsection", "研究内容一"),
        ("subsection", "研究内容二"),
        ("subsection", "研究内容三"),
        ("section", "拟解决的关键问题"),
    ],
    "03-methodology": [
        ("chapter", "研究方法及研究路线"),
        ("section", "研究思路与方法"),
        ("subsection", "研究方法一"),
        ("subsection", "研究方法二"),
        ("subsection", "研究方法三"),
        ("subsection", "研究方法四"),
        ("section", "技术路线"),
    ],
    "04-outcomes": [
        ("chapter", "预期成果"),
        ("section", "预期成果"),
        ("section", "创新之处"),
        ("section", "预期社会效益"),
    ],
    "05-schedule": [
        ("chapter", "工作进度安排及经费预算"),
        ("section", "工作进展"),
        ("section", "所需设备"),
        ("section", "经费预算"),
    ],
    "06-achievements": [
        ("chapter", "已取得的阶段性成果"),
    ],
}
HEADING_RE = re.compile(r"^\s*\\(chapter|section|subsection)\{([^{}]+)\}", re.MULTILINE)
INCLUDE_RE = re.compile(r"\\include\{contents/([^{}]+)\}")


def check(root: Path, toc: Path | None = None) -> None:
    main = (root / "main.tex").read_text(encoding="utf-8")
    expected_names = list(STRUCTURE)
    included = INCLUDE_RE.findall(main)
    if included != expected_names:
        raise ValueError(f"Chapter inclusion order mismatch: {included!r}")

    actual_files = sorted(p.stem for p in (root / "contents").glob("*.tex"))
    if actual_files != sorted(expected_names):
        raise ValueError(f"Unexpected chapter files: {actual_files!r}")

    for filename, headings in STRUCTURE.items():
        data = (root / "contents" / f"{filename}.tex").read_text(encoding="utf-8")
        actual = HEADING_RE.findall(data)
        if actual != headings:
            raise ValueError(f"{filename}: expected {headings!r}, got {actual!r}")

    if r"\bibmatter*" not in main or r"\printbibliography" not in main:
        raise ValueError("Missing the bibliography section")

    if toc is not None:
        toc_lines = toc.read_text(encoding="utf-8").splitlines()
        position = -1
        for headings in STRUCTURE.values():
            for level, heading in headings:
                prefix = f"\\contentsline {{{level}}}"
                candidates = [
                    i for i, line in enumerate(toc_lines)
                    if i > position and line.startswith(prefix) and heading in line
                ]
                if not candidates:
                    raise ValueError(f"Table of contents is missing {level}: {heading}")
                position = candidates[0]
        if not any(
            line.startswith(r"\contentsline {chapter}") and "参考文献" in line
            for line in toc_lines[position + 1:]
        ):
            raise ValueError("Table of contents is missing the bibliography")

    print("PASS: six chapters, complete subsection hierarchy, bibliography")


if __name__ == "__main__":
    try:
        if len(sys.argv) == 1:
            check(ROOT)
        elif len(sys.argv) == 3:
            check(Path(sys.argv[1]), Path(sys.argv[2]))
        else:
            raise ValueError("Usage: check-structure.py [project-root main.toc]")
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error
