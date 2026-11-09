#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/work/contents" "$tmp/restored"
printf 'before\n' >"$tmp/work/main.aux"
printf 'nested\n' >"$tmp/work/contents/01-basis.aux"
printf 'database\n' >"$tmp/work/main.fdb_latexmk"
printf 'PDF\n' >"$tmp/work/main.pdf"
printf 'LaTeX source\n' >"$tmp/work/main.tex"
printf 'PRIVATE TEST SENTINEL\n' >"$tmp/work/information-private.tex"
bash "$root/scripts/cache-latexmk.sh" save "$tmp/work" "$tmp/cache" master-oneside
bash "$root/scripts/cache-latexmk.sh" restore "$tmp/restored" "$tmp/cache" master-oneside
test -f "$tmp/restored/main.aux"
test -f "$tmp/restored/contents/01-basis.aux"
test -f "$tmp/restored/main.fdb_latexmk"
test -f "$tmp/restored/main.pdf"
test ! -f "$tmp/restored/main.tex"
test ! -f "$tmp/restored/information-private.tex"
! grep -R -Fq "PRIVATE TEST SENTINEL" "$tmp/cache"
printf 'after\n' >"$tmp/work/main.aux"
rm "$tmp/work/contents/01-basis.aux"
bash "$root/scripts/cache-latexmk.sh" save "$tmp/work" "$tmp/cache" master-oneside
grep -Fq 'after' "$tmp/cache/master-oneside/main.aux"
test ! -e "$tmp/cache/master-oneside/contents/01-basis.aux"
mkdir -p "$tmp/other"
bash "$root/scripts/cache-latexmk.sh" restore "$tmp/other" "$tmp/cache" doctor-twoside
test ! -f "$tmp/other/main.aux"
# Prove latexmk skips unchanged inputs and rebuilds after a source edit.
mkdir -p "$tmp/incremental"
cat > "$tmp/incremental/main.tex" <<'TEX'
\documentclass{article}
\begin{document}
First version
\end{document}
TEX
(cd "$tmp/incremental" && latexmk -xelatex main.tex >first.log 2>&1)
(cd "$tmp/incremental" && latexmk -xelatex main.tex >second.log 2>&1)
grep -Fq "Nothing to do" "$tmp/incremental/second.log"
sed -i 's/First version/Second version/' "$tmp/incremental/main.tex"
(cd "$tmp/incremental" && latexmk -xelatex main.tex >third.log 2>&1)
pdftotext "$tmp/incremental/main.pdf" - | grep -Fq "Second version"
echo "PASS: cache content filtering, update, privacy and configuration isolation"
