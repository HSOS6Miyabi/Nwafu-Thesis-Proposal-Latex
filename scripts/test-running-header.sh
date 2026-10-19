#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for type in master doctor; do
  for sided in oneside twoside; do
    work="$tmp/$type-$sided"
    mkdir -p "$work/styles" "$work/fonts"
    cp "$root/styles/proposal-header.tex" "$work/styles/"
    cp "$root/fonts/font-setup.tex" "$work/fonts/"
    cat >"$work/main.tex" <<TEX
\documentclass[type=$type,$sided]{nwafuthesis}
\input{fonts/font-setup.tex}
\nwafuset{style={auto-make-cover=false,font=none,cjk-font=none}}
\input{styles/proposal-header.tex}
\begin{document}
\mainmatter
\ProposalApplyRunningHeader
\chapter{测试章节}
第一页正文。
\newpage
第二页正文。
\bibmatter*
\ProposalApplyRunningHeader
\chapter*{参考文献}
参考文献第一页。
\newpage
参考文献第二页。
\end{document}
TEX
    (cd "$work" && xelatex -interaction=nonstopmode -halt-on-error main.tex >build.log 2>&1) || {
      tail -100 "$work/build.log" >&2
      exit 1
    }
    pdf="$work/main.pdf"
    test -s "$pdf"
    pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
    if [[ ! "$pages" =~ ^[0-9]+$ ]] || (( pages < 4 )); then
      echo "Expected at least four pages for $type-$sided, got $pages" >&2
      exit 1
    fi
    if [[ "$type" == master ]]; then
      expected="西北农林科技大学硕士开题报告"
    else
      expected="西北农林科技大学博士开题报告"
    fi
    # The body must contain a second page with the proposal-specific header.
    body_page="$(pdftotext -f 2 -l 2 -layout "$pdf" -)"
    if ! grep -Fq '第二页正文' <<< "$body_page" ||
       ! grep -Fq "$expected" <<< "$body_page" ||
       grep -Fq '学位论文' <<< "$body_page"; then
      echo "Incorrect second body page header for $type-$sided" >&2
      printf '%s\n' "$body_page" >&2
      exit 1
    fi

    if [[ "$sided" == oneside ]]; then
      first_page="$(pdftotext -f 1 -l 1 -layout "$pdf" -)"
      grep -Fq "$expected" <<< "$first_page" || {
        echo "Incorrect one-sided first-page header for $type" >&2
        exit 1
      }
    else
      first_page="$(pdftotext -f 1 -l 1 -layout "$pdf" -)"
      if ! grep -Fq '章节标题' <<< "$first_page"; then
        echo "Missing first chapter for $type" >&2
        exit 1
      fi
    fi

    # Bibliography may start on different physical pages across class versions.
    bibliography_checked=0
    for ((p=3; p<=pages; p++)); do
      page="$(pdftotext -f "$p" -l "$p" -layout "$pdf" -)"
      if grep -Fq '参考文献第二页' <<< "$page"; then
        if ! grep -Fq "$expected" <<< "$page" ||
           grep -Fq '学位论文' <<< "$page"; then
          echo "Incorrect bibliography header for $type-$sided on page $p" >&2
          exit 1
        fi
        bibliography_checked=1
      fi
    done
    if [[ "$bibliography_checked" -ne 1 ]]; then
      echo "Cannot identify bibliography continuation for $type-$sided" >&2
      exit 1
    fi
    echo "PASS: $type-$sided, pages 1–4 and reference section"
  done
done
