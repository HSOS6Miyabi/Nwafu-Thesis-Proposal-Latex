#!/usr/bin/env python3
r"""Validate nwafuthesis reference syntax and the rendered usage examples.

The class applies \labelformat to ordinary \ref commands. Consequently,
adding a manual object name repeats labels such as 图 and 表; eqref is
also unsuitable for the class's equation reference format.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import subprocess

# Inspect public documents and LaTeX usage examples, including Markdown snippets.
PREFIX_BEFORE_REF = re.compile(
    r"(?:公式|章节|图|表|式|节)"
    r"\s*(?:(?:~|\\[,;!]|\\quad|\\enspace)\s*)?"
    r"\\(?:ref|autoref|eqref)\s*\{",
    flags=re.MULTILINE,
)
EQREF = re.compile(r"\\eqref\s*\{")
# \autoref on a full figure or table doubles the label under nwafuthesis.
AUTOREF_TABLE = re.compile(r"\\autoref\s*\{\s*tab:")
LABEL_WITHOUT_PREFIX = re.compile(r"\\ref\s*\{\s*(?:fig|tab|eq):")

def check_source(root: Path) -> None:
    target_paths = sorted(root.glob("contents/*.tex"))
    target_paths += sorted(root.glob("examples/**/*.tex"))
    target_paths += [root / "README.md", root / "examples" / "README.md"]
    violations = []
    for path in target_paths:
        if not path.is_file():
            raise ValueError(f"Required source file is missing: {path}")
        data = path.read_text(encoding="utf-8")
        for regexp, hint in (
            (PREFIX_BEFORE_REF, "manually prefixed reference"),
            (EQREF, "equation uses eqref instead of ref"),
            (AUTOREF_TABLE, "table uses autoref instead of ref"),
        ):
            for match in regexp.finditer(data):
                line = data.count("\n", 0, match.start()) + 1
                violations.append(f"{path.relative_to(root)}:{line}: {hint}")
    # Ensure the usage sample still contains working ordinary references.
    figures = (root / "examples" / "contents" / "figures-tables.tex").read_text()
    formulas = (root / "examples" / "contents" / "math-citations.tex").read_text()
    if len(LABEL_WITHOUT_PREFIX.findall(figures)) < 3:
        violations.append("Usage examples need ordinary figure and table references")
    if r"\ref{eq:demo-pythagoras}" not in formulas:
        violations.append("Usage examples need equation reference")
    if r"\autoref{fig:demo-sub-a}" not in figures:
        violations.append("Usage examples need subfigure autoref")
    if violations:
        raise ValueError("Cross-reference checks failed:\n" + "\n".join(violations))
    print("PASS: no duplicated object names or malformed reference commands in public examples")

def check_pdf(pdf: Path) -> None:
    rendered = subprocess.run(
        ["pdftotext", "-layout", str(pdf), "-"],
        capture_output=True, text=True, check=True
    ).stdout
    compact = re.sub(r"\s+", "", rendered)
    invalid = [r"图图\d", r"表表\d", r"式式\(", r"\(式\("]
    for pattern in invalid:
        found = re.search(pattern, compact)
        if found:
            near = compact[max(0, found.start() - 50):found.end() + 50]
            raise ValueError(f"{pdf.name}: duplicated reference near {near!r}")
    required = {
        "图1-1是": "main figure reference",
        "引用图1-2a与图1-2b": "subfigure references",
        "整组图1-2": "group figure reference",
        "表1-1使用": "first table reference",
        "表1-2演示": "second table reference",
        "式(2-1)表示": "equation reference",
    }
    missing = [name for fragment, name in required.items() if fragment not in compact]
    if missing:
        raise ValueError(f"{pdf.name}: missing formatted references: {', '.join(missing)}")
    print("PASS: PDF displays correct figure, subfigure, table and equation references")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, help="repository root")
    parser.add_argument("--pdf", type=Path, help="compiled usage manual PDF")
    args = parser.parse_args()
    try:
        check_source(args.root)
        if args.pdf:
            check_pdf(args.pdf)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"{error}\n")
