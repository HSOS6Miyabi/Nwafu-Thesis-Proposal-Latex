#!/usr/bin/env bash
# Build a standalone, publicly shareable formatting manual.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${PROPOSAL_CI_CACHE_DIR:-}" ]]; then
  command -v rsync >/dev/null
  tmp="$root/.latexmk-ci-work/usage-examples"
  bash "$root/scripts/cache-latexmk.sh" restore "$tmp" "$PROPOSAL_CI_CACHE_DIR" usage-examples
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
fi
mkdir -p "$tmp/examples" "$tmp/fonts" "$root/dist"
find "$tmp/examples" -type f \( -name '*.tex' -o -name '*.bib' -o -name '*.csv' \) -delete
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
python3 "$root/scripts/check-references.py" "$root" --pdf "$pdf"
if [[ -n "${PROPOSAL_CI_CACHE_DIR:-}" ]]; then
  bash "$root/scripts/cache-latexmk.sh" save "$tmp" "$PROPOSAL_CI_CACHE_DIR" usage-examples
fi
cp "$pdf" "$root/dist/usage-examples.pdf"
echo "PASS: formatting examples => $root/dist/usage-examples.pdf"
