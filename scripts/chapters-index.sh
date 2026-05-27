#!/usr/bin/env bash
set -euo pipefail

dir="${1:?usage: chapters-index.sh <chapters-dir>}"

# Read thesis.tex to get chapter order and titles
thesis_tex=""
for candidate in thesis/thesis.tex ../thesis/thesis.tex; do
  if [ -f "$candidate" ]; then thesis_tex="$candidate"; break; fi
done

# Extract chapter list in order from thesis.tex
# Looks for \include{chapters/FooBar} or \input{chapters/FooBar}
ordered=()
if [ -n "$thesis_tex" ]; then
  while IFS= read -r ch; do
    ordered+=("$ch")
  done < <(grep -oP '\\(?:include|input)\{chapters/\K[^}]+' "$thesis_tex")
fi

# Build JSON array of {stem, title, url}
items=()
idx=1
for stem in "${ordered[@]}"; do
  pdf="chapter-${stem}.pdf"
  if [ -f "$dir/$pdf" ]; then
    # Extract \chapter{...} or \chapternotnumbered{...} title from .tex
    tex=""
    for candidate in "thesis/chapters/${stem}.tex" "../thesis/chapters/${stem}.tex"; do
      if [ -f "$candidate" ]; then tex="$candidate"; break; fi
    done
    title="$stem"
    if [ -n "$tex" ]; then
      t=$(grep -m1 -oP '\\chapter(?:notnumbered)?\{\K[^}]+' "$tex" 2>/dev/null || true)
      [ -n "$t" ] && title="$t"
    fi
    items+=("{\"stem\":\"$stem\",\"chapter\":$idx,\"title\":\"$title\",\"url\":\"./chapters/$pdf\"}")
    idx=$((idx + 1))
  fi
done

# Output JSON array
printf '['
for i in "${!items[@]}"; do
  if [ "$i" -gt 0 ]; then printf ','; fi
  printf '%s' "${items[$i]}"
done
printf ']\n'
