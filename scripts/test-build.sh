#!/usr/bin/env bash
# Compile and validate all public example variants. Never consume private metadata.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out_dir="$root/dist"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

command -v latexmk >/dev/null
command -v pdftotext >/dev/null
command -v pdfinfo >/dev/null
command -v pdffonts >/dev/null
command -v python3 >/dev/null
python3 "$root/scripts/check-structure.py"

# Only generic public example metadata is allowed in downloadable PDFs.
example="$root/cover/information.example.tex"
grep -Fq '\newcommand{\ProposalStudent}{研究生姓名}' "$example"
grep -Fq '\newcommand{\ProposalStudentId}{学号}' "$example"

mkdir -p "$out_dir"

for variant in master-oneside master-twoside doctor-twoside; do
  work="$work_dir/$variant"
  mkdir -p "$work/cover" "$work/contents" "$work/bib" "$work/fonts"
  cp "$root/main.tex" "$root/latexmkrc" "$work/"
  cp "$root/cover/cover.tex" "$example" "$work/cover/"
  cp "$root/fonts/font-setup.tex" "$work/fonts/"
  cp "$root/contents/"*.tex "$work/contents/"
  cp "$root/bib/references.bib" "$work/bib/"

  case "$variant" in
    master-oneside)
      sed -i 's/type=master,twoside/type=master,oneside/' "$work/main.tex"
      degree='硕士研究生学位论文'
      toc_page=2
      ;;
    master-twoside)
      degree='硕士研究生学位论文'
      toc_page=3
      ;;
    doctor-twoside)
      sed -i 's/type=master,twoside/type=doctor,twoside/' "$work/main.tex"
      degree='博士研究生学位论文'
      toc_page=3
      ;;
  esac

  if ! (cd "$work" && latexmk -xelatex main.tex >build.log 2>&1); then
    echo "ERROR: LaTeX compilation failed for $variant" >&2
    tail -100 "$work/build.log" >&2
    exit 1
  fi

  pdf="$work/main.pdf"
  [[ -s "$pdf" ]] || { echo "ERROR: no PDF for $variant" >&2; exit 1; }
  page_count="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
  [[ "$page_count" =~ ^[0-9]+$ && "$page_count" -ge 4 ]] || {
    echo "ERROR: invalid PDF page count for $variant: $page_count" >&2
    exit 1
  }

  cover_text="$(pdftotext -f 1 -l 1 "$pdf" -)"
  grep -Fq "$degree" <<< "$cover_text" || {
    echo "ERROR: degree label on the cover is wrong: $variant" >&2
    exit 1
  }
  grep -Fq '开题报告' <<< "$cover_text" || {
    echo "ERROR: cover title is missing: $variant" >&2
    exit 1
  }
  grep -Fq '研究生姓名' <<< "$cover_text" || {
    echo "ERROR: the public example metadata was not used: $variant" >&2
    exit 1
  }

  if [[ "$variant" == *twoside ]]; then
    blank_text="$(pdftotext -f 2 -l 2 "$pdf" - | tr -d '[:space:]')"
    [[ -z "$blank_text" ]] || {
      echo "ERROR: expected blank second page for $variant" >&2
      exit 1
    }
  fi

  toc_text="$(pdftotext -f "$toc_page" -l "$toc_page" "$pdf" -)"
  grep -Eq '目[[:space:]]*录' <<< "$toc_text" || {
    echo "ERROR: expected table of contents on page $toc_page for $variant" >&2
    exit 1
  }
  grep -Fq '选题依据' <<< "$(pdftotext "$pdf" -)" || {
    echo "ERROR: body chapter missing for $variant" >&2
    exit 1
  }

  python3 "$root/scripts/check-cover-layout.py" "$pdf" "$work/build.log"
  python3 "$root/scripts/check-structure.py" "$work" "$work/main.toc"
  cp "$pdf" "$out_dir/$variant.pdf"
  echo "PASS: $variant ($page_count pages, TOC on page $toc_page) => $out_dir/$variant.pdf"
done
