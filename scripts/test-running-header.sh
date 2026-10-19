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
    test "$pages" -eq 4
    if [[ "$type" == master ]]; then
      expected="西北农林科技大学硕士开题报告"
    else
      expected="西北农林科技大学博士开题报告"
    fi
    if [[ "$sided" == twoside ]]; then
      check_pages="2 4"
    else
      check_pages="1 2 3 4"
    fi
    for p in $check_pages; do
      page="$(pdftotext -f "$p" -l "$p" -layout "$pdf" -)"
      grep -Fq "$expected" <<< "$page" || {
        echo "Wrong running header on page $p of $type-$sided" >&2
        exit 1
      }
      if grep -Fq '学位论文' <<< "$page"; then
        echo "Unexpected thesis header on page $p of $type-$sided" >&2
        exit 1
      fi
    done
    if [[ "$sided" == twoside ]]; then
      first="$(pdftotext -f 1 -l 1 -layout "$pdf" - | head -n 1)"
      grep -Fq '章节标题' <<< "$first"
    fi
    echo "PASS: $type-$sided, pages 1–4 and reference section"
  done
done
