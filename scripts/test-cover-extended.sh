#!/usr/bin/env bash
# Validate automatic English title compression without changing group spacing.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/cover" "$work/contents" "$work/bib" "$work/fonts"
cp "$root/main.tex" "$root/latexmkrc" "$work/"
cp "$root/cover/cover.tex" "$root/cover/information.example.tex" "$work/cover/"
cp "$root/fonts/font-setup.tex" "$work/fonts/"
cp "$root/contents/"*.tex "$work/contents/"
cp "$root/bib/references.bib" "$work/bib/"

# The extra English line exercises the constrained-space branch. The
# generated PDF stays in a temporary directory and is never published.
python3 - "$work/cover/information.example.tex" <<'PY'
from pathlib import Path
import sys

file = Path(sys.argv[1])
source = file.read_text(encoding="utf-8")
normal = r"English Title of the\\Research Proposal\\Goes Here"
extended = r"English Title of the\\Research Proposal\\Extended Example\\Goes Here"
if source.count(normal) != 1:
    raise SystemExit("Expected example title not found")
file.write_text(source.replace(normal, extended), encoding="utf-8")
PY

(cd "$work" && latexmk -xelatex main.tex >build.log 2>&1) || {
    tail -100 "$work/build.log" >&2
    exit 1
}
grep -Fq "Proposal English title line stretch: 1.2" "$work/build.log"
python3 "$root/scripts/check-cover-layout.py" "$work/main.pdf" "$work/build.log" 4
echo "PASS: extended English title preserves Chinese-English group spacing"
