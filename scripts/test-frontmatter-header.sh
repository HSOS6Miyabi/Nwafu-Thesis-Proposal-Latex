#!/usr/bin/env bash
# Verify proposal-specific running headers on multi-page tables of contents.
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
    cat > "$work/main.tex" <<TEX
\documentclass[type=$type,$sided]{nwafuthesis}
\input{fonts/font-setup.tex}
\nwafuset{style={auto-make-cover=false,font=none,cjk-font=none}}
\input{styles/proposal-header.tex}
\begin{document}
\begin{titlepage}
\thispagestyle{empty}
公开测试封面
\end{titlepage}
\makefront
\newcount\ProposalTestTocEntry
\ProposalTestTocEntry=0
\loop\ifnum\ProposalTestTocEntry<95
  \advance\ProposalTestTocEntry by 1
  \addcontentsline{toc}{section}{目录排版条目\the\ProposalTestTocEntry}
\repeat
\mainmatter
\ProposalApplyRunningHeader
\chapter{示例章节}
正文示例。
\end{document}
TEX
    for pass in 1 2; do
      if ! (cd "$work" && xelatex -interaction=nonstopmode -halt-on-error main.tex >"build-$pass.log" 2>&1); then
        tail -80 "$work/build-$pass.log" >&2
        exit 1
      fi
    done

    pdf="$work/main.pdf"
    [[ -s "$pdf" ]]
    pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
    if [[ "$type" == master ]]; then
      expected='西北农林科技大学硕士开题报告'
    else
      expected='西北农林科技大学博士开题报告'
    fi

    toc_pages=0
    checked_headers=0
    for ((p=1; p<=pages; p++)); do
      text="$(pdftotext -f "$p" -l "$p" -layout "$pdf" -)"
      if grep -Fq '目录排版条目' <<< "$text"; then
        ((toc_pages+=1))
        if grep -Fq '学位论文' <<< "$text"; then
          echo "Thesis heading found in contents page $p of $type-$sided" >&2
          exit 1
        fi
        if [[ "$sided" == oneside ]] || (( p % 2 == 0 )); then
          if ! grep -Fq "$expected" <<< "$text"; then
            echo "Incorrect header on contents page $p of $type-$sided" >&2
            exit 1
          fi
          ((checked_headers+=1))
        fi
      fi
    done
    if (( toc_pages < 2 || checked_headers < 1 )); then
      echo "Multi-page contents check incomplete for $type-$sided" >&2
      exit 1
    fi
    echo "PASS: $type-$sided, $toc_pages contents pages, $checked_headers proposal headers"
  done
done
