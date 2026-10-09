#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for variant in master-oneside master-twoside doctor-twoside; do
  mkdir -p "$tmp/$variant"
  cp -R "$root/main.tex" "$root/latexmkrc" "$root/cover" "$root/contents" "$root/bib" "$tmp/$variant/"
  case "$variant" in
    master-oneside) sed -i 's/type=master,twoside/type=master,oneside/' "$tmp/$variant/main.tex" ;;
    doctor-twoside) sed -i 's/type=master,twoside/type=doctor,twoside/' "$tmp/$variant/main.tex" ;;
  esac
  (cd "$tmp/$variant" && latexmk -xelatex main.tex > build.log 2>&1) || {
    tail -80 "$tmp/$variant/build.log"
    exit 1
  }
  pdf="$tmp/$variant/main.pdf"
  test -s "$pdf"
  text="$(pdftotext -f 1 -l 1 "$pdf" -)"
  if [[ "$variant" == doctor-* ]]; then
    grep -q "博士研究生学位论文" <<< "$text"
  else
    grep -q "硕士研究生学位论文" <<< "$text"
  fi
  if [[ "$variant" == *twoside ]]; then
    test -z "$(pdftotext -f 2 -l 2 "$pdf" - | tr -d "[:space:]")"
    grep -Eq "目[[:space:]]*录" <<< "$(pdftotext -f 3 -l 3 "$pdf" -)"
  else
    grep -Eq "目[[:space:]]*录" <<< "$(pdftotext -f 2 -l 2 "$pdf" -)"
  fi
  pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
  echo "$variant: $pages pages; compiled successfully"
done
