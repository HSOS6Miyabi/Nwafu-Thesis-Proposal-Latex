#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

must_ignore=(
  main.aux main.bcf main.bbl main.blg main.run.xml
  main.fdb_latexmk main.fls main.log main.out main.toc main.lof main.lot
  main.synctex.gz 'main.synctex.gz(busy)' main.xdv
  contents/01-basis.aux examples/main.aux examples/main.log
  main.pdf examples/main.pdf dist/master-oneside.pdf build/main.pdf out/main.pdf
  _minted-main/highlight.pygtex examples/_minted-main/highlight.pygtex
  cover/information-private.tex cover/information.tex
  private/student.tex local/notes.tex
  .DS_Store .vscode/settings.json __pycache__/helper.pyc
)
must_keep=(
  main.tex examples/main.tex
  contents/01-basis.tex styles/proposal-header.tex
  cover/cover.tex cover/information.example.tex
  bib/references.bib examples/bib/references.bib
  examples/data/metrics.csv
  figures/diagram.pdf assets/chart.pdf images/plot.png
  README.md examples/README.md latexmkrc
  .github/workflows/latex-ci.yml
  references.lock
)

for path in "${must_ignore[@]}"; do
  if ! git check-ignore --quiet --no-index -- "$path"; then
    echo "Expected ignored file: $path" >&2
    exit 1
  fi
done
for path in "${must_keep[@]}"; do
  if git check-ignore --quiet --no-index -- "$path"; then
    echo "Source file unexpectedly ignored: $path" >&2
    exit 1
  fi
done

tracked_ignored="$(git ls-files -ci --exclude-standard)"
if [[ -n "$tracked_ignored" ]]; then
  echo "Tracked files match .gitignore:" >&2
  printf '%s\n' "$tracked_ignored" >&2
  exit 1
fi
printf 'PASS: %d generated/private paths ignored; %d source paths retained\n' \
  "${#must_ignore[@]}" "${#must_keep[@]}"
