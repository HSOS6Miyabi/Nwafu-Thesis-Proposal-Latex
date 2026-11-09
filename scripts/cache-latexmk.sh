#!/usr/bin/env bash
# Save or restore public LaTeX intermediate files, separated by configuration.
set -euo pipefail
action="${1:?restore or save}"
work="${2:?working directory}"
root="${3:?cache directory}"
variant="${4:?variant}"
case "$variant" in
  master-oneside|master-twoside|doctor-twoside|usage-examples) ;;
  *) echo "Unknown configuration: $variant" >&2; exit 2 ;;
esac
cache="$root/$variant"
if [[ "$action" == restore ]]; then
  mkdir -p "$work"
  if [[ -d "$cache" ]]; then
    rsync -a "$cache/" "$work/"
    echo "Restored $variant compilation cache"
  else
    echo "No cache for $variant"
  fi
elif [[ "$action" == save ]]; then
  mkdir -p "$cache"
  rsync -a --delete --prune-empty-dirs \
    --include='*/' \
    --include='*.aux' --include='*.bbl' --include='*.bcf' \
    --include='*.blg' --include='*.fdb_latexmk' --include='*.fls' \
    --include='*.log' --include='*.toc' --include='*.lof' \
    --include='*.lot' --include='*.out' --include='*.run.xml' \
    --include='*.xdv' --include='/main.pdf' \
    --exclude='*' "$work/" "$cache/"
  echo "Saved $variant compilation cache"
else
  echo "Unknown action: $action" >&2
  exit 2
fi
