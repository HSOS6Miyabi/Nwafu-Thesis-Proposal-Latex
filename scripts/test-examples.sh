#!/usr/bin/env bash
# Build a standalone, publicly shareable formatting manual.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/examples" "$tmp/fonts" "$root/dist"
cp -R "$root/examples/." "$tmp/examples/"
cp "$root/fonts/font-setup.tex" "$tmp/fonts/"
cp "$root/latexmkrc" "$tmp/"
(cd "$tmp" && latexmk -xelatex examples/main.tex > build.log 2>&1) || {
  tail -100 "$tmp/build.log" >&2
  exit 1
}
pdf="$tmp/main.pdf"
[[ -s "$pdf" ]]
pdftotext "$pdf" - | grep -q '插图与表格'
pdftotext "$pdf" - | grep -q '数学公式'
pdftotext "$pdf" - | grep -q '参考文献'
cp "$pdf" "$root/dist/usage-examples.pdf"
echo "PASS: formatting examples => $root/dist/usage-examples.pdf"
