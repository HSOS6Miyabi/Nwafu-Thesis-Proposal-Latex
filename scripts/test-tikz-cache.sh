#!/usr/bin/env bash
# Exercise optional TikZ caching on a public, isolated copy of the template.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/cover" "$tmp/contents" "$tmp/bib" "$tmp/fonts" "$tmp/styles" "$tmp/scripts"
cp "$root/main.tex" "$root/latexmkrc" "$tmp/"
cp "$root/cover/cover.tex" "$root/cover/information.example.tex" "$tmp/cover/"
cp "$root/contents/"*.tex "$tmp/contents/"
cp "$root/bib/references.bib" "$tmp/bib/"
cp "$root/fonts/font-setup.tex" "$tmp/fonts/"
cp "$root/styles/proposal-header.tex" "$tmp/styles/"
cp "$root/scripts/build-fast.sh" "$tmp/scripts/"
cat >> "$tmp/contents/01-basis.tex" <<'TEX'

\begin{figure}[htbp]
  \centering
  \begin{tikzpicture}
    \draw (0,0) rectangle (2,1);
    \node at (1,.5) {Cache test};
  \end{tikzpicture}
  \caption{TikZ 缓存示例}
\end{figure}
TEX
(cd "$tmp" && bash scripts/build-fast.sh >first-build.log 2>&1) || {
  tail -100 "$tmp/first-build.log" >&2
  exit 1
}
test -s "$tmp/main.pdf"
test ! -e "$tmp/tikz-cache/enable.tex"
picture="$(find "$tmp/tikz-cache" -type f -name '*.pdf' -print -quit)"
if [[ -z "$picture" ]]; then
  echo "TikZ externalization produced no cached pictures" >&2
  exit 1
fi
before="$(stat -c '%Y' "$picture")"
sleep 1
(cd "$tmp" && bash scripts/build-fast.sh >second-build.log 2>&1) || {
  tail -100 "$tmp/second-build.log" >&2
  exit 1
}
after="$(stat -c '%Y' "$picture")"
if [[ "$before" != "$after" ]]; then
  echo "Unchanged TikZ picture was unnecessarily recompiled" >&2
  exit 1
fi
test ! -e "$tmp/tikz-cache/enable.tex"
echo "PASS: optional TikZ caching and cover compilation"
