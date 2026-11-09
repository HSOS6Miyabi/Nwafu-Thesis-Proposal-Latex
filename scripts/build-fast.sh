#!/usr/bin/env bash
# Optional local TikZ externalization; execute only with trusted input files.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
mkdir -p tikz-cache
marker="tikz-cache/enable.tex"
if [[ -e "$marker" ]]; then
  echo "TikZ externalization is already enabled: $marker" >&2
  exit 1
fi
trap 'rm -f "$marker"' EXIT
: > "$marker"
PROPOSAL_TIKZ_CACHE=1 latexmk -xelatex main.tex "$@"
